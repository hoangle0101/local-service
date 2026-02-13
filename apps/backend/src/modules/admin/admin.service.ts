import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import {
  ResolveDisputeDto,
  AdminDashboardQueryDto,
  AdminDisputesQueryDto,
  AdminWithdrawalsQueryDto,
  ApproveWithdrawalDto,
  RejectWithdrawalDto,
  AdminUsersQueryDto,
  AdminProvidersQueryDto,
  BanUserDto,
  VerifyUserDto,
  VerifyProviderDto,
  AdminBookingsQueryDto,
  AdminPaymentsQueryDto,
  AdminRevenueReportQueryDto,
  AdminServicesReportQueryDto,
  AdminUsersReportQueryDto,
  CreateAnnouncementDto,
  AdminAnnouncementsQueryDto,
} from './dto/admin.dto';
import { Decimal } from '@prisma/client/runtime/library';

@Injectable()
export class AdminService {
  constructor(private prisma: PrismaService) {}

  /**
   * Resolve dispute - handles escrow release/refund
   */
  async resolveDispute(
    disputeId: bigint,
    adminId: bigint,
    dto: ResolveDisputeDto,
  ) {
    const dispute = await this.prisma.dispute.findUnique({
      where: { id: disputeId },
      include: {
        booking: {
          include: {
            customer: { include: { wallet: true } },
            providerUser: { include: { wallet: true } },
          },
        },
      },
    });

    if (!dispute) {
      throw new NotFoundException('Dispute not found');
    }

    // Find related BookingPayment
    const bookingPayment = await this.prisma.bookingPayment.findUnique({
      where: { bookingId: dispute.bookingId },
    });

    return this.prisma.$transaction(async (tx) => {
      // Update dispute
      await tx.dispute.update({
        where: { id: disputeId },
        data: {
          status: 'resolved',
          resolution: dto.resolution,
          resolvedByAdminId: adminId,
          resolvedAt: new Date(),
        },
      });

      const refundAmt = dto.refundAmount || 0;
      const now = new Date();

      // Handle escrow based on resolution
      if (
        dto.resolution === 'full_refund_to_customer' ||
        dto.resolution === 'partial_refund_to_customer'
      ) {
        // REFUND: Customer wins
        if (refundAmt > 0) {
          const refundAmount = new Decimal(refundAmt);

          // Create refund transaction
          await tx.walletTransaction.create({
            data: {
              walletUserId: dispute.booking.customerId,
              type: 'refund',
              amount: refundAmount,
              balanceAfter: dispute.booking.customer.wallet
                ? dispute.booking.customer.wallet.balance.plus(refundAmount)
                : refundAmount,
              status: 'completed',
              metadata: {
                description: `Dispute refund for booking #${dispute.bookingId}`,
                disputeId: disputeId.toString(),
                resolution: dto.resolution,
              },
            },
          });

          // Update customer wallet balance
          await tx.wallet.upsert({
            where: { userId: dispute.booking.customerId },
            create: {
              userId: dispute.booking.customerId,
              balance: refundAmount,
            },
            update: {
              balance: { increment: refundAmount },
            },
          });
        }

        // Update BookingPayment status to refunded
        if (bookingPayment) {
          await tx.bookingPayment.update({
            where: { id: bookingPayment.id },
            data: {
              status: 'refunded',
              refundedAt: now,
              refundAmount: refundAmt,
              refundReason: dto.notes || `Dispute resolved: ${dto.resolution}`,
            },
          });
        }

        console.log(
          `[Admin] Dispute ${disputeId} resolved: Refunded ${refundAmt} to customer`,
        );
      } else if (dto.resolution === 'full_payment_to_provider') {
        // RELEASE: Provider wins - release escrow to provider
        if (bookingPayment && dispute.booking.providerId) {
          const providerAmount = Number(bookingPayment.providerAmount);

          // Add earnings to provider wallet
          const updatedWallet = await tx.wallet.upsert({
            where: { userId: dispute.booking.providerId },
            create: {
              userId: dispute.booking.providerId,
              balance: providerAmount,
            },
            update: {
              balance: { increment: providerAmount },
            },
          });

          // Create wallet transaction
          await tx.walletTransaction.create({
            data: {
              walletUserId: dispute.booking.providerId,
              type: 'earning',
              amount: providerAmount,
              balanceAfter: updatedWallet.balance,
              status: 'completed',
              metadata: {
                bookingPaymentId: bookingPayment.id.toString(),
                bookingId: dispute.bookingId.toString(),
                source: 'dispute_resolution',
                disputeId: disputeId.toString(),
              },
            },
          });

          // Update BookingPayment status to released
          await tx.bookingPayment.update({
            where: { id: bookingPayment.id },
            data: {
              status: 'released',
              releasedAt: now,
            },
          });

          console.log(
            `[Admin] Dispute ${disputeId} resolved: Released ${providerAmount} to provider`,
          );
        }
      } else if (dto.resolution === 'mutual_cancellation') {
        // MUTUAL: Both parties agree to cancel
        // Refund customer minus a small processing fee (5%)
        if (bookingPayment) {
          const totalAmount = Number(bookingPayment.amount);
          const processingFee = Math.round(totalAmount * 0.05);
          const refundToCustomer = totalAmount - processingFee;

          if (refundToCustomer > 0) {
            await tx.wallet.upsert({
              where: { userId: dispute.booking.customerId },
              create: {
                userId: dispute.booking.customerId,
                balance: refundToCustomer,
              },
              update: {
                balance: { increment: refundToCustomer },
              },
            });

            await tx.walletTransaction.create({
              data: {
                walletUserId: dispute.booking.customerId,
                type: 'refund',
                amount: refundToCustomer,
                balanceAfter: (
                  dispute.booking.customer.wallet?.balance || new Decimal(0)
                ).plus(refundToCustomer),
                status: 'completed',
                metadata: {
                  description: `Mutual cancellation refund (minus 5% fee)`,
                  disputeId: disputeId.toString(),
                  processingFee,
                },
              },
            });
          }

          await tx.bookingPayment.update({
            where: { id: bookingPayment.id },
            data: {
              status: 'refunded',
              refundedAt: now,
              refundAmount: refundToCustomer,
              refundReason: `Mutual cancellation (processing fee: ${processingFee})`,
            },
          });

          console.log(
            `[Admin] Dispute ${disputeId} resolved: Mutual cancellation, refunded ${refundToCustomer}`,
          );
        }
      }

      // Restore booking status to completed (dispute is resolved)
      await tx.booking.update({
        where: { id: dispute.bookingId },
        data: { status: 'completed' },
      });

      // Create audit log
      await tx.auditLog.create({
        data: {
          actorUserId: adminId,
          action: 'dispute_resolved',
          objectType: 'dispute',
          objectId: disputeId,
          detail: {
            disputeId: disputeId.toString(),
            resolution: dto.resolution,
            refundAmount: dto.refundAmount,
            notes: dto.notes,
            bookingPaymentStatus: bookingPayment
              ? dto.resolution.includes('refund')
                ? 'refunded'
                : 'released'
              : null,
          },
        },
      });

      return {
        message: 'Dispute resolved successfully',
        resolution: dto.resolution,
      };
    });
  }

  /**
   * Get admin dashboard overview
   * Returns key metrics: total revenue, active bookings, disputes, etc.
   */
  async getDashboard(query: AdminDashboardQueryDto) {
    const startDate = query.startDate
      ? new Date(query.startDate)
      : new Date(new Date().setDate(new Date().getDate() - 90));
    const endDate = query.endDate ? new Date(query.endDate) : new Date();

    // Use Promise.all for parallel queries
    const [
      totalUsers,
      activeProviders,
      totalBookings,
      completedBookings,
      totalDisputes,
      openDisputes,
      totalRevenue,
      recentActivity,
    ] = await Promise.all([
      // Total users count - Get ALL users
      this.prisma.user.count(),
      // Active providers
      this.prisma.providerProfile.count({
        where: {
          verificationStatus: 'verified',
          user: { status: 'active' },
        },
      }),
      // Total bookings in period
      this.prisma.booking.count({
        where: {
          createdAt: { gte: startDate, lte: endDate },
        },
      }),
      // Completed bookings in period
      this.prisma.booking.count({
        where: {
          status: 'completed',
          createdAt: { gte: startDate, lte: endDate },
        },
      }),
      // Total disputes
      this.prisma.dispute.count(),
      // Open disputes
      this.prisma.dispute.count({
        where: { status: 'open' },
      }),
      // Total revenue from completed bookings (sum of actual prices)
      this.prisma.booking.aggregate({
        where: {
          status: 'completed',
          createdAt: { gte: startDate, lte: endDate },
        },
        _sum: { actualPrice: true },
      }),
      // Recent bookings (last 10)
      this.prisma.booking.findMany({
        where: {
          createdAt: { gte: startDate, lte: endDate },
        },
        include: {
          customer: { select: { id: true, phone: true } },
          providerUser: { select: { id: true } },
          service: { select: { name: true } },
        },
        orderBy: { createdAt: 'desc' },
        take: 10,
      }),
    ]);

    // Calculate completion rate
    const completionRate =
      totalBookings > 0
        ? Math.round((completedBookings / totalBookings) * 100)
        : 0;

    // Calculate average booking value
    const totalRevenueResult = totalRevenue as unknown as {
      _sum: { actualPrice: Decimal | null };
    };
    const totalRevenueAmount =
      totalRevenueResult._sum.actualPrice || new Decimal(0);
    const avgBookingValue =
      completedBookings > 0
        ? totalRevenueAmount.div(completedBookings).toNumber()
        : 0;

    return {
      overview: {
        totalUsers,
        activeProviders,
        totalBookings,
        completedBookings,
        completionRate: `${completionRate}%`,
        totalDisputes,
        openDisputes,
        disputeResolutionRate:
          totalDisputes > 0
            ? `${Math.round(((totalDisputes - openDisputes) / totalDisputes) * 100)}%`
            : 'N/A',
      },
      financials: {
        totalRevenue: totalRevenueAmount.toNumber(),
        avgBookingValue: parseFloat(avgBookingValue.toFixed(2)),
        currency: 'VND',
      },
      period: {
        startDate,
        endDate,
        daysIncluded: Math.ceil(
          (endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24),
        ),
      },
      ...(String(query.detailed) === 'true' && {
        recentActivity: recentActivity.map((booking) => ({
          id: booking.id.toString(),
          customerId: booking.customerId.toString(),
          providerId: booking.providerUser?.id.toString(),
          service: booking.service.name,
          status: booking.status,
          price: booking.actualPrice?.toNumber() || 0,
          createdAt: booking.createdAt,
        })),
        charts: {
          revenue: await (async () => {
            const days = 30;
            const start = new Date(endDate);
            start.setDate(start.getDate() - days);

            const chartBookings = await this.prisma.booking.findMany({
              where: {
                status: 'completed',
                createdAt: { gte: start, lte: endDate },
              },
              select: { actualPrice: true, createdAt: true },
            });

            const group: Record<
              string,
              { date: string; revenue: number; bookings: number }
            > = {};
            for (let i = 0; i <= days; i++) {
              const d = new Date(start);
              d.setDate(d.getDate() + i);
              const ds = d.toISOString().split('T')[0];
              group[ds] = { date: ds, revenue: 0, bookings: 0 };
            }

            chartBookings.forEach((b) => {
              const ds = b.createdAt.toISOString().split('T')[0];
              if (group[ds]) {
                group[ds].revenue += b.actualPrice?.toNumber() || 0;
                group[ds].bookings += 1;
              }
            });
            return Object.values(group).sort((a, b) =>
              a.date.localeCompare(b.date),
            );
          })(),
          users: await (async () => {
            const days = 30;
            const start = new Date(endDate);
            start.setDate(start.getDate() - days);

            const chartUsers = await this.prisma.user.findMany({
              where: { createdAt: { gte: start, lte: endDate } },
              select: { createdAt: true },
            });

            const group: Record<string, { date: string; newUsers: number }> =
              {};
            for (let i = 0; i <= days; i++) {
              const d = new Date(start);
              d.setDate(d.getDate() + i);
              const ds = d.toISOString().split('T')[0];
              group[ds] = { date: ds, newUsers: 0 };
            }

            chartUsers.forEach((u) => {
              const ds = u.createdAt.toISOString().split('T')[0];
              if (group[ds]) {
                group[ds].newUsers += 1;
              }
            });
            return Object.values(group).sort((a, b) =>
              a.date.localeCompare(b.date),
            );
          })(),
        },
      }),
    };
  }

  /**
   * Get list of disputes from admin perspective
   * Admin can see all disputes with filtering and sorting
   */
  async getDisputesForAdmin(query: AdminDisputesQueryDto) {
    const page = query.page || 1;
    const limit = Math.min(query.limit || 20, 100);
    const skip = (page - 1) * limit;
    const sortBy = query.sortBy === 'asc' ? 'asc' : 'desc';

    // Build where clause with filters
    const where: any = {};

    if (query.status) {
      where.status = query.status;
    }

    if (query.category) {
      where.category = query.category;
    }

    if (query.resolutionStatus) {
      if (query.resolutionStatus === 'pending') {
        where.status = { in: ['open', 'under_review', 'awaiting_response'] };
      } else if (query.resolutionStatus === 'resolved') {
        where.status = { in: ['resolved', 'closed'] };
      } else if (query.resolutionStatus === 'appealed') {
        where.appealCount = { gt: 0 };
      }
    }

    // Parallel queries: get disputes and total count
    const [disputes, total] = await Promise.all([
      this.prisma.dispute.findMany({
        where,
        include: {
          booking: {
            select: {
              id: true,
              customerId: true,
              providerId: true,
              actualPrice: true,
              status: true,
              customer: {
                select: {
                  phone: true,
                  profile: { select: { fullName: true } },
                },
              },
              providerUser: {
                select: {
                  phone: true,
                  profile: { select: { fullName: true } },
                },
              },
              service: { select: { name: true } },
            },
          },
          raiser: {
            select: {
              phone: true,
              profile: { select: { fullName: true, avatarUrl: true } },
            },
          },
          _count: {
            select: { evidence: true, timeline: true },
          },
        },
        skip,
        take: limit,
        orderBy: { createdAt: sortBy },
      }),
      this.prisma.dispute.count({ where }),
    ]);

    return {
      data: disputes.map((dispute) => ({
        id: dispute.id,
        bookingId: dispute.bookingId,
        raisedBy: dispute.raisedBy,
        category: dispute.category,
        status: dispute.status,
        reason: dispute.reason,
        resolutionType: dispute.resolutionType,
        resolution: dispute.resolution,
        resolvedByAdminId: dispute.resolvedByAdminId,
        resolvedAt: dispute.resolvedAt,
        createdAt: dispute.createdAt,
        appealCount: dispute.appealCount,
        raiser: dispute.raiser,
        _count: dispute._count,
        booking: dispute.booking
          ? {
              id: dispute.booking.id,
              customerId: dispute.booking.customerId,
              providerId: dispute.booking.providerId,
              actualPrice: dispute.booking.actualPrice,
              status: dispute.booking.status,
              customerPhone: dispute.booking.customer.phone,
              providerPhone: dispute.booking.providerUser?.phone || null,
              serviceName: dispute.booking.service.name,
              service: { name: dispute.booking.service.name },
              customer: dispute.booking.customer,
              providerUser: dispute.booking.providerUser,
            }
          : null,
      })),
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
        hasNextPage: page < Math.ceil(total / limit),
      },
    };
  }

  /**
   * Get single dispute detail for admin
   */
  async getDisputeDetailForAdmin(
    disputeId: bigint,
    includeTimeline: boolean = false,
    includeEvidence: boolean = false,
  ) {
    const include: any = {
      booking: {
        select: {
          id: true,
          customerId: true,
          providerId: true,
          actualPrice: true,
          status: true,
          scheduledAt: true,
          customer: {
            select: {
              phone: true,
              profile: { select: { fullName: true, avatarUrl: true } },
            },
          },
          providerUser: {
            select: {
              phone: true,
              profile: { select: { fullName: true, avatarUrl: true } },
            },
          },
          service: { select: { name: true, description: true } },
        },
      },
      raiser: {
        select: {
          id: true,
          phone: true,
          profile: { select: { fullName: true, avatarUrl: true } },
        },
      },
      resolvedBy: {
        select: {
          id: true,
          profile: { select: { fullName: true } },
        },
      },
      _count: {
        select: { evidence: true, timeline: true },
      },
    };

    if (includeTimeline) {
      include.timeline = {
        orderBy: { createdAt: 'desc' },
        include: {
          actor: {
            select: {
              id: true,
              profile: { select: { fullName: true, avatarUrl: true } },
            },
          },
        },
      };
    }

    if (includeEvidence) {
      include.evidence = {
        orderBy: { createdAt: 'desc' },
        include: {
          uploader: {
            select: { id: true, profile: { select: { fullName: true } } },
          },
        },
      };
    }

    const dispute = await this.prisma.dispute.findUnique({
      where: { id: disputeId },
      include,
    });

    if (!dispute) {
      throw new NotFoundException('Dispute not found');
    }

    return { data: dispute };
  }

  /**
   * Escalate a dispute to higher priority
   */
  async escalateDispute(disputeId: bigint, adminId: bigint, reason: string) {
    const dispute = await this.prisma.dispute.findUnique({
      where: { id: disputeId },
    });

    if (!dispute) {
      throw new NotFoundException('Dispute not found');
    }

    if (
      dispute.status === 'resolved' ||
      dispute.status === 'closed' ||
      dispute.status === 'cancelled'
    ) {
      throw new BadRequestException('Cannot escalate a closed dispute');
    }

    const [updatedDispute] = await this.prisma.$transaction([
      this.prisma.dispute.update({
        where: { id: disputeId },
        data: {
          status: 'escalated',
          escalatedAt: new Date(),
        },
      }),
      this.prisma.disputeTimeline.create({
        data: {
          disputeId,
          actorUserId: adminId,
          action: 'escalated',
          description: reason,
        },
      }),
    ]);

    return { data: updatedDispute, message: 'Dispute escalated successfully' };
  }

  /**
   * Request response from customer or provider
   */
  async requestDisputeResponse(
    disputeId: bigint,
    adminId: bigint,
    dto: {
      targetParty: 'customer' | 'provider';
      message?: string;
      deadlineHours?: number;
    },
  ) {
    const dispute = await this.prisma.dispute.findUnique({
      where: { id: disputeId },
      include: {
        booking: {
          select: { customerId: true, providerId: true },
        },
      },
    });

    if (!dispute) {
      throw new NotFoundException('Dispute not found');
    }

    if (dispute.status === 'resolved' || dispute.status === 'closed') {
      throw new BadRequestException(
        'Cannot request response for a closed dispute',
      );
    }

    const targetUserId =
      dto.targetParty === 'customer'
        ? dispute.booking.customerId
        : dispute.booking.providerId;

    if (!targetUserId) {
      throw new BadRequestException(
        `${dto.targetParty} not found for this booking`,
      );
    }

    const deadline = dto.deadlineHours || 48;
    const description =
      dto.message ||
      `Response requested from ${dto.targetParty}. Deadline: ${deadline} hours.`;

    const [updatedDispute] = await this.prisma.$transaction([
      this.prisma.dispute.update({
        where: { id: disputeId },
        data: {
          status: 'awaiting_response',
        },
      }),
      this.prisma.disputeTimeline.create({
        data: {
          disputeId,
          actorUserId: adminId,
          action: 'response_requested',
          description,
          metadata: {
            targetParty: dto.targetParty,
            targetUserId: targetUserId.toString(),
            deadlineHours: deadline,
          },
        },
      }),
    ]);

    // TODO: Send notification to target user

    return { data: updatedDispute, message: 'Response requested successfully' };
  }

  /**
   * Get list of withdrawal requests from admin perspective
   * Display pending, approved, rejected withdrawals
   */
  async getWithdrawalsForAdmin(query: AdminWithdrawalsQueryDto) {
    const page = query.page || 1;
    const limit = Math.min(query.limit || 20, 100);
    const skip = (page - 1) * limit;
    const sortBy = query.sortBy === 'asc' ? 'asc' : 'desc';

    // Build where clause
    const where: any = {
      type: 'withdrawal',
    };

    if (query.status) {
      where.status = query.status;
    }

    if (query.startDate || query.endDate) {
      where.createdAt = {};
      if (query.startDate) {
        where.createdAt.gte = new Date(query.startDate);
      }
      if (query.endDate) {
        where.createdAt.lte = new Date(query.endDate);
      }
    }

    // Parallel queries - use walletUserId directly instead of wallet relation
    const [withdrawals, total] = await Promise.all([
      this.prisma.walletTransaction.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: sortBy },
      }),
      this.prisma.walletTransaction.count({ where }),
    ]);

    // Fetch user data separately for better type safety
    const userIds = [...new Set(withdrawals.map((w) => w.walletUserId))];
    const users = await this.prisma.user.findMany({
      where: { id: { in: userIds } },
      select: {
        id: true,
        phone: true,
        profile: { select: { fullName: true } },
      },
    });

    const userMap = new Map(users.map((u) => [u.id, u]));

    return {
      data: withdrawals.map((withdrawal) => {
        const user = userMap.get(withdrawal.walletUserId);
        return {
          id: withdrawal.id.toString(),
          walletUserId: withdrawal.walletUserId.toString(),
          amount: withdrawal.amount.toNumber(),
          status: withdrawal.status,
          createdAt: withdrawal.createdAt,
          user: user
            ? {
                userId: user.id,
                phone: user.phone,
                fullName: user.profile?.fullName || 'Unknown',
              }
            : null,
          metadata: (withdrawal.metadata as any) || {},
        };
      }),
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
        hasNextPage: page < Math.ceil(total / limit),
      },
    };
  }

  /**
   * Approve withdrawal request
   * Validates request and processes payment
   */
  async approveWithdrawal(
    transactionId: bigint,
    adminId: bigint,
    dto: ApproveWithdrawalDto,
  ) {
    const withdrawal = await this.prisma.walletTransaction.findUnique({
      where: { id: transactionId },
    });

    if (!withdrawal) {
      throw new NotFoundException('Withdrawal request not found');
    }

    // Validation checks
    if (withdrawal.type !== 'withdrawal') {
      throw new BadRequestException('Transaction is not a withdrawal request');
    }

    if (withdrawal.status !== 'pending') {
      throw new BadRequestException(
        `Cannot approve withdrawal with status: ${withdrawal.status}`,
      );
    }

    // Verify sufficient balance
    const wallet = await this.prisma.wallet.findUnique({
      where: { userId: withdrawal.walletUserId },
    });

    if (!wallet || wallet.balance.lessThan(withdrawal.amount)) {
      throw new BadRequestException(
        'Insufficient wallet balance to process withdrawal',
      );
    }

    // Process approval in transaction
    return this.prisma.$transaction(async (tx) => {
      // Update withdrawal status
      const updatedWithdrawal = await tx.walletTransaction.update({
        where: { id: transactionId },
        data: {
          status: 'completed',
          metadata: {
            ...(withdrawal.metadata as any),
            approvalNotes: dto.approvalNotes,
            externalTransactionId: dto.externalTransactionId,
            paymentMethod: dto.paymentMethod,
            approvedAt: new Date().toISOString(),
            approvedByAdminId: adminId.toString(),
          },
        },
      });

      // Deduct from wallet balance
      await tx.wallet.update({
        where: { userId: withdrawal.walletUserId },
        data: { balance: { decrement: withdrawal.amount } },
      });

      // Create audit log
      await tx.auditLog.create({
        data: {
          actorUserId: adminId,
          action: 'withdrawal_approved',
          objectType: 'wallet_transaction',
          objectId: transactionId,
          detail: {
            withdrawalId: transactionId.toString(),
            userId: withdrawal.walletUserId.toString(),
            amount: withdrawal.amount.toString(),
            approvalNotes: dto.approvalNotes,
            externalTransactionId: dto.externalTransactionId,
          },
        },
      });

      return {
        message: 'Withdrawal approved successfully',
        withdrawal: updatedWithdrawal,
      };
    });
  }

  /**
   * Reject withdrawal request
   * Optionally refund amount to wallet
   */
  async rejectWithdrawal(
    transactionId: bigint,
    adminId: bigint,
    dto: RejectWithdrawalDto,
  ) {
    const withdrawal = await this.prisma.walletTransaction.findUnique({
      where: { id: transactionId },
    });

    if (!withdrawal) {
      throw new NotFoundException('Withdrawal request not found');
    }

    // Validation checks
    if (withdrawal.type !== 'withdrawal') {
      throw new BadRequestException('Transaction is not a withdrawal request');
    }

    if (withdrawal.status !== 'pending') {
      throw new BadRequestException(
        `Cannot reject withdrawal with status: ${withdrawal.status}`,
      );
    }

    // Process rejection in transaction
    return this.prisma.$transaction(async (tx) => {
      // Update withdrawal status
      const updatedWithdrawal = await tx.walletTransaction.update({
        where: { id: transactionId },
        data: {
          status: 'failed',
          metadata: {
            ...(withdrawal.metadata as any),
            rejectionReason: dto.rejectionReason,
            adminNotes: dto.adminNotes,
            rejectedAt: new Date().toISOString(),
            rejectedByAdminId: adminId.toString(),
          },
        },
      });

      // Optionally refund to wallet
      if (dto.refundToWallet) {
        await tx.wallet.update({
          where: { userId: withdrawal.walletUserId },
          data: { balance: { increment: withdrawal.amount } },
        });
      }

      // Create audit log
      await tx.auditLog.create({
        data: {
          actorUserId: adminId,
          action: 'withdrawal_rejected',
          objectType: 'wallet_transaction',
          objectId: transactionId,
          detail: {
            withdrawalId: transactionId.toString(),
            userId: withdrawal.walletUserId.toString(),
            amount: withdrawal.amount.toString(),
            rejectionReason: dto.rejectionReason,
            adminNotes: dto.adminNotes,
            refundedToWallet: dto.refundToWallet,
          },
        },
      });

      return {
        message: 'Withdrawal rejected successfully',
        withdrawal: updatedWithdrawal,
        refunded: dto.refundToWallet,
      };
    });
  }

  /**
   * Get list of users from admin perspective
   * Admin can see all users with filtering, searching, and pagination
   */
  async getUsers(query: AdminUsersQueryDto) {
    const page = query.page || 1;
    const limit = Math.min(query.limit || 20, 100);
    const skip = (page - 1) * limit;

    // Build where clause with all filters
    const where: any = {};

    // Filter by status
    if (query.status) {
      where.status = query.status;
    }

    // Filter by role
    if (query.role) {
      where.userRoles = {
        some: {
          role: { name: query.role },
        },
      };
    }

    // Search by email
    if (query.email) {
      where.email = { contains: query.email, mode: 'insensitive' };
    }

    // Search by phone
    if (query.phone) {
      where.phone = { contains: query.phone, mode: 'insensitive' };
    }

    // Search by full name
    if (query.search) {
      where.profile = {
        fullName: { contains: query.search, mode: 'insensitive' },
      };
    }

    // Determine sort order
    const sortOrder = query.sortOrder === 'asc' ? 'asc' : 'desc';
    const sortBy = query.sortBy || 'createdAt';

    const orderBy: any = {};
    orderBy[sortBy] = sortOrder;

    // Execute parallel queries
    const [users, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip,
        take: limit,
        select: {
          id: true,
          phone: true,
          email: true,
          status: true,
          isVerified: true,
          lastLoginAt: true,
          createdAt: true,
          updatedAt: true,
          profile: {
            select: {
              fullName: true,
              avatarUrl: true,
            },
          },
          userRoles: {
            select: {
              role: { select: { name: true } },
            },
          },
          _count: {
            select: { bookingsCustomer: true, bookingsProvider: true },
          },
        },
        orderBy,
      }),
      this.prisma.user.count({ where }),
    ]);

    return {
      data: users.map((user) => ({
        id: user.id.toString(),
        phone: user.phone,
        email: user.email,
        fullName: user.profile?.fullName || 'Unknown',
        avatarUrl: user.profile?.avatarUrl,
        status: user.status,
        isVerified: user.isVerified,
        roles: user.userRoles.map((ur) => ur.role.name),
        bookingsAsCustomer: user._count.bookingsCustomer,
        bookingsAsProvider: user._count.bookingsProvider,
        lastLoginAt: user.lastLoginAt,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
      })),
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
        hasNextPage: page < Math.ceil(total / limit),
      },
    };
  }

  /**
   * Get detailed user information for admin
   * Returns complete user profile with wallet, addresses, and booking history
   */
  async getUserDetail(userId: bigint) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        profile: true,
        userRoles: {
          include: {
            role: { select: { name: true } },
          },
        },
        wallet: true,
        addresses: {
          orderBy: { isDefault: 'desc' },
        },
        bookingsCustomer: {
          take: 10,
          orderBy: { createdAt: 'desc' },
          include: {
            service: { select: { name: true } },
          },
        },
        providerProfile: {
          select: {
            displayName: true,
            verificationStatus: true,
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return {
      id: user.id.toString(),
      phone: user.phone,
      email: user.email,
      status: user.status,
      isVerified: user.isVerified,
      lastLoginAt: user.lastLoginAt,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      roles: user.userRoles.map((ur) => ur.role.name),
      profile: user.profile
        ? {
            fullName: user.profile.fullName,
            avatarUrl: user.profile.avatarUrl,
            dateOfBirth: user.profile.birthDate,
            gender: user.profile.gender,
            address: user.profile.addressText,
          }
        : null,
      wallet: user.wallet
        ? {
            balance: user.wallet.balance.toString(),
            lockedBalance: '0',
            totalDeposits: '0',
            totalWithdrawals: '0',
          }
        : null,
      addresses: user.addresses.map((addr) => ({
        id: addr.id.toString(),
        label: addr.label,
        addressLine: addr.addressText,
        district: null,
        city: null,
        latitude: null,
        longitude: null,
        isDefault: addr.isDefault,
      })),
      bookingsAsCustomer: user.bookingsCustomer.map((booking) => ({
        id: booking.id.toString(),
        status: booking.status,
        totalAmount: booking.actualPrice?.toString() || '0',
        createdAt: booking.createdAt,
        service: booking.service ? { name: booking.service.name } : null,
      })),
      provider: user.providerProfile
        ? {
            displayName: user.providerProfile.displayName,
            verificationStatus: user.providerProfile.verificationStatus,
          }
        : null,
    };
  }

  /**
   * Get detailed provider information for admin
   * Returns complete provider profile with services, stats, and user info
   */
  async getProviderDetail(userId: bigint) {
    const provider = await this.prisma.providerProfile.findUnique({
      where: { userId },
      include: {
        user: {
          include: {
            profile: true,
            wallet: true,
          },
        },
        providerServices: {
          include: {
            service: {
              include: {
                category: { select: { name: true } },
              },
            },
            items: {
              where: { isActive: true },
              orderBy: { sortOrder: 'asc' },
            },
          },
        },
      },
    });

    if (!provider) {
      throw new NotFoundException('Provider not found');
    }

    // Get booking statistics
    const bookingStats = await this.prisma.booking.aggregate({
      where: { providerId: userId },
      _count: true,
      _sum: { providerEarning: true },
    });

    // Get recent bookings
    const recentBookings = await this.prisma.booking.findMany({
      where: { providerId: userId },
      take: 10,
      orderBy: { createdAt: 'desc' },
      include: {
        service: { select: { name: true } },
        customer: { select: { phone: true } },
      },
    });

    return {
      id: provider.userId.toString(),
      userId: provider.userId.toString(),
      displayName: provider.displayName,
      bio: provider.bio,
      avatarUrl: provider.user.profile?.avatarUrl || null,
      coverImageUrl: null,
      verificationStatus: provider.verificationStatus,
      availabilityStatus: provider.isAvailable ? 'available' : 'offline',
      rating: {
        average: provider.ratingAvg.toNumber(),
        count: provider.ratingCount,
      },
      totalReviews: provider.ratingCount,
      responseTime: null,
      completionRate: '0%',
      createdAt: provider.createdAt,
      updatedAt: provider.updatedAt,
      user: {
        id: provider.user.id.toString(),
        phone: provider.user.phone,
        email: provider.user.email,
        status: provider.user.status,
        isVerified: provider.user.isVerified,
        profile: provider.user.profile
          ? {
              fullName: provider.user.profile.fullName,
              avatarUrl: provider.user.profile.avatarUrl,
              dateOfBirth: provider.user.profile.birthDate,
              gender: provider.user.profile.gender,
            }
          : null,
      },
      wallet: provider.user.wallet
        ? {
            balance: provider.user.wallet.balance.toString(),
            lockedBalance: '0',
            totalEarnings: '0',
          }
        : null,
      services: provider.providerServices.map((ps) => ({
        id: `${ps.providerUserId}-${ps.serviceId}`,
        serviceId: ps.serviceId,
        basePrice: ps.price.toString(),
        description: null,
        isActive: ps.isActive,
        service: {
          id: ps.service.id,
          name: ps.service.name,
          category: ps.service.category?.name || 'Unknown',
        },
      })),
      expertiseCategories: [],
      stats: {
        totalBookings: bookingStats._count,
        totalEarnings: bookingStats._sum.providerEarning?.toNumber() || 0,
      },
      recentBookings: recentBookings.map((booking) => ({
        id: booking.id.toString(),
        status: booking.status,
        totalAmount: booking.actualPrice?.toString() || '0',
        createdAt: booking.createdAt,
        service: booking.service ? { name: booking.service.name } : null,
        customer: { phone: booking.customer.phone },
      })),
    };
  }

  /**
   * Get list of providers from admin perspective
   * Admin can see all providers with stats and filtering
   */
  async getProviders(query: AdminProvidersQueryDto) {
    const page = query.page || 1;
    const limit = Math.min(query.limit || 20, 100);
    const skip = (page - 1) * limit;

    // Build where clause
    const where: any = {};

    // Filter by verification status
    if (query.verificationStatus) {
      where.verificationStatus = query.verificationStatus;
    }

    // Filter by minimum rating
    if (query.minRating !== undefined) {
      where.ratingAvg = { gte: new Decimal(query.minRating) };
    }

    // Filter by availability
    if (query.isAvailable !== undefined) {
      where.isAvailable = query.isAvailable;
    }

    // Search by display name or user phone
    if (query.search) {
      where.OR = [
        { displayName: { contains: query.search, mode: 'insensitive' } },
        { user: { phone: { contains: query.search, mode: 'insensitive' } } },
      ];
    }

    // Determine sort order
    const sortOrder = query.sortOrder === 'asc' ? 'asc' : 'desc';
    const sortBy = query.sortBy || 'ratingAvg';

    const orderBy: any = {};
    orderBy[sortBy] = sortOrder;

    // Execute parallel queries
    const [providers, total] = await Promise.all([
      this.prisma.providerProfile.findMany({
        where,
        skip,
        take: limit,
        include: {
          user: {
            select: {
              id: true,
              phone: true,
              email: true,
              status: true,
              isVerified: true,
              profile: {
                select: {
                  fullName: true,
                  avatarUrl: true,
                },
              },
            },
          },
          providerServices: true,
        },
        orderBy,
      }),
      this.prisma.providerProfile.count({ where }),
    ]);

    // Fetch booking statistics for providers
    const providerIds = providers.map((p) => p.userId);
    const bookingStats = await this.prisma.booking.groupBy({
      by: ['providerId'],
      where: { providerId: { in: providerIds } },
      _count: true,
      _sum: { providerEarning: true },
    });

    const statsMap = new Map(
      bookingStats.map((stat) => [
        stat.providerId?.toString(),
        {
          totalBookings: stat._count,
          totalEarnings: stat._sum.providerEarning,
        },
      ]),
    );

    return {
      data: providers.map((provider) => {
        const stats = statsMap.get(provider.userId.toString()) || {
          totalBookings: 0,
          totalEarnings: 0,
        };
        const earnings =
          stats.totalEarnings instanceof Decimal
            ? stats.totalEarnings.toNumber()
            : typeof stats.totalEarnings === 'number'
              ? stats.totalEarnings
              : 0;

        return {
          id: provider.userId.toString(),
          userId: provider.userId.toString(),
          displayName: provider.displayName,
          bio: provider.bio,
          rating: {
            average: provider.ratingAvg.toNumber(),
            count: provider.ratingCount,
          },
          isAvailable: provider.isAvailable,
          verificationStatus: provider.verificationStatus,
          totalServices: provider.providerServices.length,
          totalBookings: stats.totalBookings,
          totalEarnings: earnings,
          user: {
            id: provider.user.id.toString(),
            phone: provider.user.phone,
            email: provider.user.email,
            status: provider.user.status,
            isVerified: provider.user.isVerified,
            profile: provider.user.profile
              ? {
                  fullName: provider.user.profile.fullName,
                  avatarUrl: provider.user.profile.avatarUrl,
                }
              : null,
          },
          createdAt: provider.createdAt,
        };
      }),
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
        hasNextPage: page < Math.ceil(total / limit),
      },
    };
  }

  /**
   * Ban or unban a user
   * Validates user exists and updates status
   */
  async banUser(userId: bigint, adminId: bigint, dto: BanUserDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Check if trying to ban an already banned user
    if (dto.action === 'ban' && user.status === 'banned') {
      throw new BadRequestException('User is already banned');
    }

    // Check if trying to unban an active user
    if (dto.action === 'unban' && user.status === 'active') {
      throw new BadRequestException('User is already active');
    }

    return this.prisma.$transaction(async (tx) => {
      // Update user status
      const newStatus = dto.action === 'ban' ? 'banned' : 'active';
      const updatedUser = await tx.user.update({
        where: { id: userId },
        data: { status: newStatus },
      });

      // Create audit log
      await tx.auditLog.create({
        data: {
          actorUserId: adminId,
          action: `user_${dto.action}`,
          objectType: 'user',
          objectId: userId,
          detail: {
            userId: userId.toString(),
            action: dto.action,
            reason: dto.reason,
            adminNotes: dto.adminNotes,
            durationDays: dto.durationDays,
          },
        },
      });

      // Create notification for user
      const action = dto.action === 'ban' ? 'banned' : 'unbanned';
      const message =
        dto.action === 'ban'
          ? `Your account has been banned. Reason: ${dto.reason}`
          : 'Your account has been unbanned and is now active';

      await tx.notification.create({
        data: {
          userId: userId,
          title: `Account ${action}`,
          body: message,
          type: 'system',
          payload: {
            action: dto.action,
            reason: dto.reason,
          },
          isRead: false,
        },
      });

      return {
        message: `User ${action} successfully`,
        userId: userId.toString(),
        status: newStatus,
        reason: dto.reason,
      };
    });
  }

  /**
   * Manually verify or unverify a user account
   */
  async verifyUser(userId: bigint, adminId: bigint, dto: VerifyUserDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return this.prisma.$transaction(async (tx) => {
      const updatedUser = await tx.user.update({
        where: { id: userId },
        data: {
          isVerified: dto.isVerified,
        },
      });

      // Create audit log
      await tx.auditLog.create({
        data: {
          actorUserId: adminId,
          action: dto.isVerified ? 'user_verified' : 'user_unverified',
          objectType: 'user',
          objectId: userId,
          detail: {
            userId: userId.toString(),
            isVerified: dto.isVerified,
            adminNotes: dto.adminNotes,
          },
        },
      });

      return {
        message: `User ${dto.isVerified ? 'verified' : 'unverified'} successfully`,
        userId: userId.toString(),
        isVerified: dto.isVerified,
      };
    });
  }

  /**
   * Verify or reject a provider
   * Updates provider verification status
   */
  async verifyProvider(
    userId: bigint,
    adminId: bigint,
    dto: VerifyProviderDto,
  ) {
    const provider = await this.prisma.providerProfile.findUnique({
      where: { userId },
      include: { user: true },
    });

    if (!provider) {
      throw new NotFoundException('Provider profile not found');
    }

    // Validate rejection reason is provided if rejecting
    if (dto.action === 'rejected' && !dto.rejectionReason) {
      throw new BadRequestException(
        'Rejection reason is required when rejecting provider',
      );
    }

    return this.prisma.$transaction(async (tx) => {
      // Update provider verification status
      const updatedProvider = await tx.providerProfile.update({
        where: { userId },
        data: {
          verificationStatus: dto.action,
        },
      });

      // Create audit log
      await tx.auditLog.create({
        data: {
          actorUserId: adminId,
          action: `provider_${dto.action}`,
          objectType: 'provider_profile',
          objectId: userId,
          detail: {
            userId: userId.toString(),
            action: dto.action,
            adminNotes: dto.adminNotes,
            rejectionReason: dto.rejectionReason,
          },
        },
      });

      // Create notification for provider
      const title =
        dto.action === 'verified'
          ? 'Provider Account Verified'
          : 'Provider Application Rejected';

      const body =
        dto.action === 'verified'
          ? `Congratulations! Your provider account has been verified. You can now accept bookings.`
          : `Your provider application has been rejected. Reason: ${dto.rejectionReason}`;

      await tx.notification.create({
        data: {
          userId: userId,
          title,
          body,
          type: 'system',
          payload: {
            action: dto.action,
            adminNotes: dto.adminNotes,
            rejectionReason: dto.rejectionReason,
          },
          isRead: false,
        },
      });

      return {
        message: `Provider ${dto.action} successfully`,
        userId: userId.toString(),
        verificationStatus: dto.action,
        adminNotes: dto.adminNotes,
      };
    });
  }

  /**
   * Get list of bookings from admin perspective
   * Admin can see all bookings with filtering, searching, and pagination
   */
  async getBookings(query: AdminBookingsQueryDto) {
    const page = query.page || 1;
    const limit = Math.min(query.limit || 20, 100);
    const skip = (page - 1) * limit;

    // Build where clause with all filters
    const where: any = {};

    // Filter by status
    if (query.status) {
      where.status = query.status;
    }

    // Filter by date range
    if (query.startDate || query.endDate) {
      where.scheduledAt = {};
      if (query.startDate) {
        where.scheduledAt.gte = new Date(query.startDate);
      }
      if (query.endDate) {
        const endDate = new Date(query.endDate);
        endDate.setHours(23, 59, 59, 999);
        where.scheduledAt.lte = endDate;
      }
    }

    // Search by customer (phone or email)
    if (query.customerSearch) {
      where.customer = {
        OR: [
          { phone: { contains: query.customerSearch, mode: 'insensitive' } },
          { email: { contains: query.customerSearch, mode: 'insensitive' } },
        ],
      };
    }

    // Search by provider (phone or email)
    if (query.providerSearch) {
      where.providerUser = {
        OR: [
          { phone: { contains: query.providerSearch, mode: 'insensitive' } },
          { email: { contains: query.providerSearch, mode: 'insensitive' } },
        ],
      };
    }

    // Determine sort order
    const sortOrder = query.sortOrder === 'asc' ? 'asc' : 'desc';
    const sortBy = query.sortBy || 'createdAt';

    const orderBy: any = {};
    orderBy[sortBy] = sortOrder;

    // Execute parallel queries
    const [bookings, total] = await Promise.all([
      this.prisma.booking.findMany({
        where,
        skip,
        take: limit,
        include: {
          customer: {
            select: {
              id: true,
              phone: true,
              email: true,
              profile: { select: { fullName: true } },
            },
          },
          providerUser: {
            select: {
              id: true,
              phone: true,
              email: true,
              profile: { select: { fullName: true } },
            },
          },
          service: { select: { id: true, name: true } },
          payments: {
            select: { id: true, status: true, amount: true },
          },
          _count: {
            select: { payments: true },
          },
        },
        orderBy,
      }),
      this.prisma.booking.count({ where }),
    ]);

    return {
      data: bookings.map((booking) => ({
        id: booking.id.toString(),
        code: booking.code,
        customerId: booking.customerId.toString(),
        customerName: booking.customer.profile?.fullName || 'Unknown',
        customerPhone: booking.customer.phone,
        customerEmail: booking.customer.email,
        providerId: booking.providerId?.toString(),
        providerName: booking.providerUser?.profile?.fullName || 'Unassigned',
        providerPhone: booking.providerUser?.phone,
        providerEmail: booking.providerUser?.email,
        serviceId: booking.serviceId,
        serviceName: booking.service.name,
        status: booking.status,
        scheduledAt: booking.scheduledAt,
        estimatedPrice: booking.estimatedPrice?.toNumber(),
        actualPrice: booking.actualPrice?.toNumber(),
        platformFee: booking.platformFee?.toNumber(),
        providerEarning: booking.providerEarning?.toNumber(),
        paymentStatus:
          booking.payments.length > 0 ? booking.payments[0].status : 'unpaid',
        totalPayments: booking._count.payments,
        createdAt: booking.createdAt,
        completedAt: booking.completedAt,
        cancelledAt: booking.cancelledAt,
      })),
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
        hasNextPage: page < Math.ceil(total / limit),
      },
    };
  }

  /**
   * Get single booking detail from admin perspective
   * Admin can see all booking details including payments, timeline, etc.
   */
  async getBookingDetail(bookingId: bigint) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: {
        customer: {
          select: {
            id: true,
            phone: true,
            email: true,
            profile: { select: { fullName: true } },
            wallet: { select: { balance: true } },
          },
        },
        providerUser: {
          select: {
            id: true,
            phone: true,
            email: true,
            profile: { select: { fullName: true } },
            wallet: { select: { balance: true } },
          },
        },
        service: { select: { id: true, name: true, basePrice: true } },
        payments: {
          select: {
            id: true,
            amount: true,
            currency: true,
            method: true,
            gateway: true,
            status: true,
            createdAt: true,
          },
        },
        dispute: {
          select: {
            id: true,
            status: true,
            reason: true,
          },
        },
      },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    return {
      id: booking.id.toString(),
      code: booking.code,
      customer: {
        id: booking.customer.id.toString(),
        fullName: booking.customer.profile?.fullName,
        phone: booking.customer.phone,
        email: booking.customer.email,
        walletBalance: booking.customer.wallet?.balance.toNumber(),
      },
      provider: booking.providerUser
        ? {
            id: booking.providerUser.id.toString(),
            fullName: booking.providerUser.profile?.fullName,
            phone: booking.providerUser.phone,
            email: booking.providerUser.email,
            walletBalance: booking.providerUser.wallet?.balance.toNumber(),
          }
        : null,
      service: {
        id: booking.service.id,
        name: booking.service.name,
        basePrice: booking.service.basePrice.toNumber(),
      },
      status: booking.status,
      scheduledAt: booking.scheduledAt,
      estimatedDurationMinutes: booking.estimatedDurationMinutes,
      estimatedPrice: booking.estimatedPrice?.toNumber(),
      actualPrice: booking.actualPrice?.toNumber(),
      platformFee: booking.platformFee?.toNumber(),
      providerEarning: booking.providerEarning?.toNumber(),
      addressText: booking.addressText,
      notes: booking.notes,
      payments: booking.payments.map((p) => ({
        id: p.id.toString(),
        amount: p.amount.toNumber(),
        currency: p.currency,
        method: p.method,
        gateway: p.gateway,
        status: p.status,
        createdAt: p.createdAt,
      })),
      dispute: booking.dispute
        ? {
            id: booking.dispute.id.toString(),
            status: booking.dispute.status,
            reason: booking.dispute.reason,
          }
        : null,
      createdAt: booking.createdAt,
      completedAt: booking.completedAt,
      cancelledAt: booking.cancelledAt,
    };
  }

  /**
   * Get list of payments from admin perspective
   * Admin can see all payments with filtering and statistics
   */
  async getPayments(query: AdminPaymentsQueryDto) {
    const page = query.page || 1;
    const limit = Math.min(query.limit || 20, 100);
    const skip = (page - 1) * limit;

    // Build where clause
    const where: any = {};

    // Filter by status
    if (query.status) {
      where.status = query.status;
    }

    // Filter by gateway
    if (query.gateway) {
      where.gateway = query.gateway;
    }

    // Filter by date range
    if (query.startDate || query.endDate) {
      where.createdAt = {};
      if (query.startDate) {
        where.createdAt.gte = new Date(query.startDate);
      }
      if (query.endDate) {
        const endDate = new Date(query.endDate);
        endDate.setHours(23, 59, 59, 999);
        where.createdAt.lte = endDate;
      }
    }

    // Filter by amount range
    if (query.minAmount !== undefined || query.maxAmount !== undefined) {
      where.amount = {};
      if (query.minAmount !== undefined) {
        where.amount.gte = new Decimal(query.minAmount);
      }
      if (query.maxAmount !== undefined) {
        where.amount.lte = new Decimal(query.maxAmount);
      }
    }

    // Determine sort order
    const sortOrder = query.sortOrder === 'asc' ? 'asc' : 'desc';
    const sortBy = query.sortBy || 'createdAt';

    const orderBy: any = {};
    orderBy[sortBy] = sortOrder;

    // Execute parallel queries
    const [payments, total, stats] = await Promise.all([
      this.prisma.payment.findMany({
        where,
        skip,
        take: limit,
        include: {
          booking: {
            select: {
              id: true,
              code: true,
              customerId: true,
              customer: { select: { phone: true, email: true } },
            },
          },
        },
        orderBy,
      }),
      this.prisma.payment.count({ where }),
      this.prisma.payment.aggregate({
        where,
        _sum: { amount: true },
        _count: true,
      }),
    ]);

    return {
      data: payments.map((payment) => ({
        id: payment.id.toString(),
        bookingId: payment.booking?.id.toString(),
        bookingCode: payment.booking?.code,
        customerId: payment.booking?.customerId.toString(),
        customerPhone: payment.booking?.customer?.phone,
        customerEmail: payment.booking?.customer?.email,
        amount: payment.amount.toNumber(),
        currency: payment.currency,
        method: payment.method,
        gateway: payment.gateway,
        gatewayTxId: payment.gatewayTxId,
        status: payment.status,
        environment: payment.environment,
        reconciled: payment.reconciled,
        createdAt: payment.createdAt,
        updatedAt: payment.updatedAt,
      })),
      statistics: {
        totalCount: stats._count,
        totalAmount: stats._sum.amount?.toNumber() || 0,
        successCount: payments.filter((p) => p.status === 'succeeded').length,
        failedCount: payments.filter((p) => p.status === 'failed').length,
        initiatedCount: payments.filter((p) => p.status === 'initiated').length,
      },
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
        hasNextPage: page < Math.ceil(total / limit),
      },
    };
  }

  /**
   * Get user's wallet details from admin perspective
   * Admin can see wallet balance and recent transactions
   */
  async getWallet(userId: bigint, page: number = 1, limit: number = 20) {
    const wallet = await this.prisma.wallet.findUnique({
      where: { userId },
      include: {
        user: {
          select: {
            id: true,
            phone: true,
            email: true,
            profile: { select: { fullName: true } },
            userRoles: {
              select: { role: { select: { name: true } } },
            },
          },
        },
      },
    });

    if (!wallet) {
      throw new NotFoundException('Wallet not found');
    }

    // Get transaction history with pagination
    const skip = (page - 1) * limit;
    const cleanLimit = Math.min(limit, 100);

    const [transactions, transactionCount] = await Promise.all([
      this.prisma.walletTransaction.findMany({
        where: { walletUserId: userId },
        skip,
        take: cleanLimit,
        include: {
          payment: {
            select: {
              id: true,
              booking: { select: { id: true, code: true } },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.walletTransaction.count({
        where: { walletUserId: userId },
      }),
    ]);

    return {
      wallet: {
        userId: wallet.userId.toString(),
        fullName: wallet.user.profile?.fullName,
        phone: wallet.user.phone,
        email: wallet.user.email,
        roles: wallet.user.userRoles.map((ur) => ur.role.name),
        balance: wallet.balance.toNumber(),
        currency: wallet.currency,
        isLocked: wallet.lockedUntil ? wallet.lockedUntil > new Date() : false,
        createdAt: wallet.createdAt,
        updatedAt: wallet.updatedAt,
      },
      transactions: transactions.map((tx) => ({
        id: tx.id.toString(),
        type: tx.type,
        amount: tx.amount.toNumber(),
        balanceAfter: tx.balanceAfter.toNumber(),
        status: tx.status,
        bookingId: tx.payment?.booking?.id.toString(),
        bookingCode: tx.payment?.booking?.code,
        paymentId: tx.payment?.id.toString(),
        createdAt: tx.createdAt,
        metadata: tx.metadata,
      })),
      pagination: {
        total: transactionCount,
        page,
        limit: cleanLimit,
        totalPages: Math.ceil(transactionCount / cleanLimit),
        hasNextPage: page < Math.ceil(transactionCount / cleanLimit),
      },
    };
  }

  /**
   * Get revenue analytics report
   */
  async getRevenueReport(query: AdminRevenueReportQueryDto) {
    const startDate = query.startDate
      ? new Date(query.startDate)
      : new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const endDate = query.endDate ? new Date(query.endDate) : new Date();

    const [bookings, totalBookingsCount] = await Promise.all([
      this.prisma.booking.findMany({
        where: {
          status: 'completed',
          createdAt: { gte: startDate, lte: endDate },
        },
        select: {
          id: true,
          actualPrice: true,
          platformFee: true,
          providerEarning: true,
          createdAt: true,
        },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.booking.count({
        where: {
          status: 'completed',
          createdAt: { gte: startDate, lte: endDate },
        },
      }),
    ]);

    const totalRevenue = bookings.reduce(
      (sum, b) => sum + (b.actualPrice?.toNumber() || 0),
      0,
    );
    const totalFee = bookings.reduce(
      (sum, b) => sum + (b.platformFee?.toNumber() || 0),
      0,
    );
    const totalProviderEarning = bookings.reduce(
      (sum, b) => sum + (b.providerEarning?.toNumber() || 0),
      0,
    );

    // Group by date for time series
    const timeSeriesGroup: Record<
      string,
      { date: string; revenue: number; bookings: number; commission: number }
    > = {};
    const daysToInclude =
      Math.ceil(
        (endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24),
      ) + 1;

    for (let i = 0; i < daysToInclude; i++) {
      const date = new Date(startDate);
      date.setDate(date.getDate() + i);
      const dateStr = date.toISOString().split('T')[0];
      timeSeriesGroup[dateStr] = {
        date: dateStr,
        revenue: 0,
        bookings: 0,
        commission: 0,
      };
    }

    bookings.forEach((b) => {
      const dateStr = b.createdAt.toISOString().split('T')[0];
      if (timeSeriesGroup[dateStr]) {
        timeSeriesGroup[dateStr].revenue += b.actualPrice?.toNumber() || 0;
        timeSeriesGroup[dateStr].bookings += 1;
        timeSeriesGroup[dateStr].commission += b.platformFee?.toNumber() || 0;
      }
    });

    const timeSeriesData = Object.values(timeSeriesGroup).sort((a, b) =>
      a.date.localeCompare(b.date),
    );

    return {
      summary: {
        startDate,
        endDate,
        groupBy: query.groupBy,
        totalRevenue,
        totalPlatformFee: totalFee,
        totalProviderEarning: totalProviderEarning,
        totalTransactions: totalBookingsCount,
        averageTransactionValue:
          totalBookingsCount > 0 ? totalRevenue / totalBookingsCount : 0,
      },
      timeSeriesData,
      data: bookings.map((b) => ({
        bookingId: b.id.toString(),
        amount: b.actualPrice?.toNumber() || 0,
        status: 'completed',
        platformFee: b.platformFee?.toNumber() || 0,
        providerEarning: b.providerEarning?.toNumber() || 0,
        createdAt: b.createdAt,
      })),
    };
  }

  /**
   * Get services analytics report
   */
  async getServicesReport(query: AdminServicesReportQueryDto) {
    const startDate = query.startDate
      ? new Date(query.startDate)
      : new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const endDate = query.endDate ? new Date(query.endDate) : new Date();

    const services = await this.prisma.service.findMany({
      where: query.categoryId ? { categoryId: query.categoryId } : {},
      select: {
        id: true,
        name: true,
        basePrice: true,
      },
      orderBy: { name: 'asc' },
    });

    const servicesWithStats = await Promise.all(
      services.map(async (service) => {
        const bookings = await this.prisma.booking.findMany({
          where: {
            serviceId: service.id,
            createdAt: { gte: startDate, lte: endDate },
          },
          select: { actualPrice: true, review: { select: { rating: true } } },
        });

        const revenue = bookings.reduce(
          (sum, b) => sum + (b.actualPrice?.toNumber() || 0),
          0,
        );
        const ratings = bookings
          .filter((b) => b.review)
          .map((b) => b.review?.rating || 0);
        const avgRating =
          ratings.length > 0
            ? ratings.reduce((a, b) => a + b, 0) / ratings.length
            : 0;

        return {
          serviceId: service.id,
          serviceName: service.name,
          bookingCount: bookings.length,
          revenue,
          averagePrice: bookings.length > 0 ? revenue / bookings.length : 0,
          averageRating: avgRating,
          ratingCount: ratings.length,
        };
      }),
    );

    const sorted = servicesWithStats
      .sort((a, b) => {
        const multiplier = query.sortOrder === 'desc' ? -1 : 1;
        switch (query.sortBy) {
          case 'revenue':
            return (b.revenue - a.revenue) * multiplier;
          case 'rating':
            return (b.averageRating - a.averageRating) * multiplier;
          default:
            return (b.bookingCount - a.bookingCount) * multiplier;
        }
      })
      .slice(0, query.limit);

    return {
      summary: {
        startDate,
        endDate,
        totalServices: services.length,
        totalBookings: servicesWithStats.reduce(
          (sum, s) => sum + s.bookingCount,
          0,
        ),
        totalRevenue: servicesWithStats.reduce((sum, s) => sum + s.revenue, 0),
      },
      data: sorted,
    };
  }

  /**
   * Get users analytics report
   */
  async getUsersReport(query: AdminUsersReportQueryDto) {
    const startDate = query.startDate
      ? new Date(query.startDate)
      : new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const endDate = query.endDate ? new Date(query.endDate) : new Date();

    const [totalUsers, newUsers, activeUsers] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.user.count({
        where: { createdAt: { gte: startDate, lte: endDate } },
      }),
      this.prisma.booking
        .findMany({
          where: { createdAt: { gte: startDate, lte: endDate } },
          distinct: ['customerId'],
          select: { customerId: true },
        })
        .then((bookings) => new Set(bookings.map((b) => b.customerId)).size),
    ]);

    const walletStats = await this.prisma.wallet.aggregate({
      _sum: { balance: true },
      _avg: { balance: true },
    });

    // Group by date for time series
    const periodUsers = await this.prisma.user.findMany({
      where: { createdAt: { gte: startDate, lte: endDate } },
      select: { createdAt: true },
    });

    const timeSeriesGroup: Record<
      string,
      { date: string; newUsers: number; activeUsers: number; bookings: number }
    > = {};
    const daysToInclude =
      Math.ceil(
        (endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24),
      ) + 1;

    for (let i = 0; i < daysToInclude; i++) {
      const date = new Date(startDate);
      date.setDate(date.getDate() + i);
      const dateStr = date.toISOString().split('T')[0];
      timeSeriesGroup[dateStr] = {
        date: dateStr,
        newUsers: 0,
        activeUsers: 0,
        bookings: 0,
      };
    }

    periodUsers.forEach((u) => {
      const dateStr = u.createdAt.toISOString().split('T')[0];
      if (timeSeriesGroup[dateStr]) {
        timeSeriesGroup[dateStr].newUsers += 1;
      }
    });

    const timeSeriesData = Object.values(timeSeriesGroup).sort((a, b) =>
      a.date.localeCompare(b.date),
    );

    return {
      summary: {
        startDate,
        endDate,
        groupBy: query.groupBy,
        totalUsers,
        newUsers,
        activeUsers,
        totalWalletValue: walletStats._sum.balance?.toNumber() || 0,
        averageWalletBalance: walletStats._avg.balance?.toNumber() || 0,
        userRole: query.userRole,
      },
      timeSeriesData,
      data: [],
    };
  }

  /**
   * Create system announcement
   */
  async createAnnouncement(adminId: bigint, dto: CreateAnnouncementDto) {
    const scheduledAt = dto.scheduledAt
      ? new Date(dto.scheduledAt)
      : new Date();

    return this.prisma.$transaction(async (tx) => {
      const announcement = await tx.notification.create({
        data: {
          userId: adminId,
          type: `announcement_${dto.type}`,
          title: dto.title,
          body: dto.body,
          payload: {
            type: dto.type,
            targetRole: dto.targetRole,
            isAnnouncement: true,
            createdBy: adminId.toString(),
          },
          isRead: false,
          sentAt: dto.sendNotification ? scheduledAt : null,
        },
      });

      if (dto.sendNotification) {
        const targetUsers = await tx.user.findMany({
          select: { id: true },
          take: 1000,
        });

        await Promise.all(
          targetUsers.map((user) =>
            tx.notification.create({
              data: {
                userId: user.id,
                type: `announcement_${dto.type}`,
                title: dto.title,
                body: dto.body,
                payload: {
                  type: dto.type,
                  targetRole: dto.targetRole,
                  isAnnouncement: true,
                  announcementId: announcement.id.toString(),
                },
                isRead: false,
                sentAt: new Date(),
              },
            }),
          ),
        );
      }

      await tx.auditLog.create({
        data: {
          actorUserId: adminId,
          action: 'announcement_created',
          objectType: 'announcement',
          objectId: announcement.id,
          detail: {
            title: dto.title,
            type: dto.type,
            targetRole: dto.targetRole,
          },
        },
      });

      return {
        id: announcement.id.toString(),
        title: announcement.title,
        body: announcement.body,
        type: dto.type,
        targetRole: dto.targetRole,
        status: 'active',
        createdAt: announcement.createdAt,
        sentAt: announcement.sentAt,
      };
    });
  }

  /**
   * Get system announcements
   */
  async getAnnouncements(query: AdminAnnouncementsQueryDto) {
    const page = Math.max(1, query.page || 1);
    const limit = Math.min(100, query.limit || 20);
    const skip = (page - 1) * limit;

    const where: any = { type: { startsWith: 'announcement_' } };

    if (query.type) {
      where.type = `announcement_${query.type}`;
    }

    const [announcements, total] = await Promise.all([
      this.prisma.notification.findMany({
        where,
        skip,
        take: limit,
        orderBy:
          query.sortBy === 'title'
            ? { title: query.sortOrder as any }
            : { createdAt: query.sortOrder as any },
        select: {
          id: true,
          title: true,
          body: true,
          type: true,
          payload: true,
          isRead: true,
          createdAt: true,
          sentAt: true,
        },
      }),
      this.prisma.notification.count({ where }),
    ]);

    return {
      announcements: announcements.map((a) => ({
        id: a.id.toString(),
        title: a.title,
        body: a.body,
        type: (a.payload as any)?.type || 'general',
        targetRole: (a.payload as any)?.targetRole || 'all',
        status: a.sentAt ? 'active' : 'scheduled',
        createdAt: a.createdAt,
        sentAt: a.sentAt,
      })),
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
        hasNextPage: page < Math.ceil(total / limit),
      },
    };
  }
}
