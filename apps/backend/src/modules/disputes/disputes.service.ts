import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import {
  CreateDisputeDto,
  GetDisputesDto,
  GetDisputeDetailDto,
  UpdateDisputeAppealDto,
  SubmitDisputeResponseDto,
  AddDisputeEvidenceDto,
  CancelDisputeDto,
} from './dto/dispute.dto';
import { DisputeCategory, EvidenceType } from '@prisma/client';

@Injectable()
export class DisputesService {
  constructor(private prisma: PrismaService) {}

  /**
   * Create dispute - can be created by customer or provider
   */
  async createDispute(userId: bigint, dto: CreateDisputeDto) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: BigInt(dto.bookingId) },
      include: { customer: true, providerUser: true },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    // Check if user is customer or provider of this booking
    const isCustomer = booking.customerId === userId;
    const isProvider = booking.providerId === userId;

    if (!isCustomer && !isProvider) {
      throw new ForbiddenException('You are not part of this booking');
    }

    // Can only dispute completed or in_progress bookings
    const allowedStatuses = ['completed', 'in_progress'];
    if (!allowedStatuses.includes(booking.status)) {
      throw new BadRequestException(
        `Can only dispute bookings with status: ${allowedStatuses.join(', ')}`,
      );
    }

    // Check if already disputed
    const existing = await this.prisma.dispute.findFirst({
      where: { bookingId: BigInt(dto.bookingId) },
    });

    if (existing) {
      throw new BadRequestException('Dispute already exists for this booking');
    }

    return this.prisma.$transaction(async (tx) => {
      // Build reason with description if provided
      const fullReason = dto.description
        ? `${dto.reason}\n\nDetails: ${dto.description}`
        : dto.reason;

      // Create dispute
      const dispute = await tx.dispute.create({
        data: {
          bookingId: BigInt(dto.bookingId),
          raisedBy: userId,
          category: dto.category as DisputeCategory,
          reason: fullReason,
          status: 'open',
        },
      });

      // Update booking status
      await tx.booking.update({
        where: { id: booking.id },
        data: { status: 'disputed' },
      });

      // ESCROW: Update BookingPayment to block auto-release
      const bookingPayment = await tx.bookingPayment.findUnique({
        where: { bookingId: booking.id },
      });

      if (bookingPayment && bookingPayment.status === 'held') {
        await tx.bookingPayment.update({
          where: { id: bookingPayment.id },
          data: {
            status: 'disputed',
            disputeId: dispute.id,
          },
        });
        console.log(
          `[Dispute] Blocked escrow release for booking ${booking.id}, payment ${bookingPayment.id}`,
        );
      }

      // Create timeline entry
      await tx.disputeTimeline.create({
        data: {
          disputeId: dispute.id,
          action: 'created',
          description: `Dispute created by ${isCustomer ? 'customer' : 'provider'}`,
          actorUserId: userId,
          metadata: {
            category: dto.category,
            raiserRole: isCustomer ? 'customer' : 'provider',
          },
        },
      });

      // Add evidence if provided
      if (dto.evidence && dto.evidence.length > 0) {
        await tx.disputeEvidence.createMany({
          data: dto.evidence.map((url) => ({
            disputeId: dispute.id,
            uploaderId: userId,
            type: 'image' as EvidenceType, // Default to image, could be improved
            url,
          })),
        });
      }

      return dispute;
    });
  }

  /**
   * Get list of disputes for current user
   */
  async getDisputesList(userId: bigint, query: GetDisputesDto) {
    const page = query.page || 1;
    const limit = query.limit || 10;
    const skip = (page - 1) * limit;
    const sortBy = query.sortBy === 'asc' ? 'asc' : 'desc';

    // Build filter
    const where: any = {
      OR: [
        { raisedBy: userId },
        {
          booking: {
            OR: [{ customerId: userId }, { providerId: userId }],
          },
        },
      ],
    };

    if (query.status) {
      where.status = query.status;
    }

    if (query.category) {
      where.category = query.category;
    }

    const [disputes, total] = await Promise.all([
      this.prisma.dispute.findMany({
        where,
        include: {
          booking: {
            select: {
              id: true,
              customerId: true,
              providerId: true,
              serviceId: true,
              status: true,
              actualPrice: true,
              service: { select: { name: true } },
            },
          },
          raiser: {
            select: {
              id: true,
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
      data: disputes,
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
   * Get detail of a single dispute
   */
  async getDisputeDetail(
    userId: bigint,
    disputeId: bigint,
    query: GetDisputeDetailDto,
  ) {
    const where: any = {
      id: disputeId,
      OR: [
        { raisedBy: userId },
        {
          booking: {
            OR: [{ customerId: userId }, { providerId: userId }],
          },
        },
      ],
    };

    const include: any = {
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
    };

    if (query.includeRelations !== false) {
      include.booking = {
        select: {
          id: true,
          customerId: true,
          providerId: true,
          serviceId: true,
          status: true,
          actualPrice: true,
          scheduledDate: true,
          service: { select: { name: true, description: true } },
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
        },
      };
    }

    if (query.includeTimeline) {
      include.timeline = {
        orderBy: { createdAt: 'desc' },
        include: {
          actor: {
            select: {
              id: true,
              profile: { select: { fullName: true } },
            },
          },
        },
      };
    }

    if (query.includeEvidence) {
      include.evidence = {
        orderBy: { createdAt: 'desc' },
        include: {
          uploader: {
            select: {
              id: true,
              profile: { select: { fullName: true } },
            },
          },
        },
      };
    }

    const dispute = await this.prisma.dispute.findFirst({
      where,
      include,
    });

    if (!dispute) {
      throw new NotFoundException('Dispute not found');
    }

    return dispute;
  }

  /**
   * Submit response to dispute (for the other party)
   */
  async submitResponse(
    userId: bigint,
    disputeId: bigint,
    dto: SubmitDisputeResponseDto,
  ) {
    const dispute = await this.prisma.dispute.findUnique({
      where: { id: disputeId },
      include: { booking: true },
    });

    if (!dispute) {
      throw new NotFoundException('Dispute not found');
    }

    // Check if user is part of the booking but not the raiser
    const isCustomer = dispute.booking.customerId === userId;
    const isProvider = dispute.booking.providerId === userId;
    const isRaiser = dispute.raisedBy === userId;

    if (!isCustomer && !isProvider) {
      throw new ForbiddenException('You are not part of this booking');
    }

    if (isRaiser) {
      throw new BadRequestException('You cannot respond to your own dispute');
    }

    // Can only respond to awaiting_response status
    if (dispute.status !== 'awaiting_response') {
      throw new BadRequestException('This dispute is not awaiting a response');
    }

    return this.prisma.$transaction(async (tx) => {
      // Update dispute status
      const updatedDispute = await tx.dispute.update({
        where: { id: disputeId },
        data: {
          status: 'under_review',
          respondedAt: new Date(),
        },
      });

      // Add timeline entry
      await tx.disputeTimeline.create({
        data: {
          disputeId,
          action: 'response_submitted',
          description: `Response submitted: ${dto.response}`,
          actorUserId: userId,
          metadata: {
            responderRole: isCustomer ? 'customer' : 'provider',
          },
        },
      });

      // Add evidence if provided
      if (dto.evidence && dto.evidence.length > 0) {
        await tx.disputeEvidence.createMany({
          data: dto.evidence.map((url) => ({
            disputeId,
            uploaderId: userId,
            type: 'image' as EvidenceType,
            url,
          })),
        });
      }

      return updatedDispute;
    });
  }

  /**
   * Add evidence to dispute
   */
  async addEvidence(
    userId: bigint,
    disputeId: bigint,
    dto: AddDisputeEvidenceDto,
  ) {
    const dispute = await this.prisma.dispute.findUnique({
      where: { id: disputeId },
      include: { booking: true },
    });

    if (!dispute) {
      throw new NotFoundException('Dispute not found');
    }

    // Check if user is part of the dispute
    const isParty =
      dispute.raisedBy === userId ||
      dispute.booking.customerId === userId ||
      dispute.booking.providerId === userId;

    if (!isParty) {
      throw new ForbiddenException('You are not part of this dispute');
    }

    // Cannot add evidence to closed/cancelled disputes
    if (['closed', 'cancelled', 'resolved'].includes(dispute.status)) {
      throw new BadRequestException('Cannot add evidence to a closed dispute');
    }

    return this.prisma.$transaction(async (tx) => {
      const evidence = await tx.disputeEvidence.create({
        data: {
          disputeId,
          uploaderId: userId,
          type: dto.type as EvidenceType,
          url: dto.url,
          description: dto.description,
        },
      });

      // Add timeline entry
      await tx.disputeTimeline.create({
        data: {
          disputeId,
          action: 'evidence_added',
          description: `Evidence added: ${dto.type}`,
          actorUserId: userId,
          metadata: {
            evidenceId: evidence.id.toString(),
            evidenceType: dto.type,
          },
        },
      });

      return evidence;
    });
  }

  /**
   * Cancel dispute (only by raiser, only if still open)
   */
  async cancelDispute(
    userId: bigint,
    disputeId: bigint,
    dto: CancelDisputeDto,
  ) {
    const dispute = await this.prisma.dispute.findUnique({
      where: { id: disputeId },
      include: { booking: true },
    });

    if (!dispute) {
      throw new NotFoundException('Dispute not found');
    }

    if (dispute.raisedBy !== userId) {
      throw new ForbiddenException('Only the dispute raiser can cancel it');
    }

    if (dispute.status !== 'open') {
      throw new BadRequestException('Can only cancel open disputes');
    }

    return this.prisma.$transaction(async (tx) => {
      const updatedDispute = await tx.dispute.update({
        where: { id: disputeId },
        data: { status: 'cancelled' },
      });

      // Restore booking status
      await tx.booking.update({
        where: { id: dispute.bookingId },
        data: { status: 'completed' },
      });

      // Add timeline entry
      await tx.disputeTimeline.create({
        data: {
          disputeId,
          action: 'cancelled',
          description: dto.reason || 'Dispute cancelled by raiser',
          actorUserId: userId,
        },
      });

      return updatedDispute;
    });
  }

  /**
   * Appeal a dispute decision
   */
  async appealDispute(
    userId: bigint,
    disputeId: bigint,
    dto: UpdateDisputeAppealDto,
  ) {
    const dispute = await this.prisma.dispute.findUnique({
      where: { id: disputeId },
    });

    if (!dispute) {
      throw new NotFoundException('Dispute not found');
    }

    if (dispute.raisedBy !== userId) {
      throw new ForbiddenException('Only the dispute raiser can appeal');
    }

    if (dispute.status !== 'resolved') {
      throw new BadRequestException('Can only appeal resolved disputes');
    }

    // Max 2 appeals
    if (dispute.appealCount >= 2) {
      throw new BadRequestException('Maximum appeal limit reached');
    }

    return this.prisma.$transaction(async (tx) => {
      const updatedDispute = await tx.dispute.update({
        where: { id: disputeId },
        data: {
          status: 'under_review',
          appealCount: { increment: 1 },
          lastAppealAt: new Date(),
        },
      });

      // Add timeline entry
      await tx.disputeTimeline.create({
        data: {
          disputeId,
          action: 'appealed',
          description: `Appeal #${dispute.appealCount + 1}: ${dto.appealReason}`,
          actorUserId: userId,
        },
      });

      // Add new evidence if provided
      if (dto.newEvidence && dto.newEvidence.length > 0) {
        await tx.disputeEvidence.createMany({
          data: dto.newEvidence.map((url) => ({
            disputeId,
            uploaderId: userId,
            type: 'image' as EvidenceType,
            url,
            description: 'Appeal evidence',
          })),
        });
      }

      return updatedDispute;
    });
  }

  /**
   * Get dispute timeline
   */
  async getDisputeTimeline(userId: bigint, disputeId: bigint) {
    const dispute = await this.prisma.dispute.findFirst({
      where: {
        id: disputeId,
        OR: [
          { raisedBy: userId },
          {
            booking: {
              OR: [{ customerId: userId }, { providerId: userId }],
            },
          },
        ],
      },
    });

    if (!dispute) {
      throw new NotFoundException('Dispute not found');
    }

    return this.prisma.disputeTimeline.findMany({
      where: { disputeId },
      orderBy: { createdAt: 'desc' },
      include: {
        actor: {
          select: {
            id: true,
            profile: { select: { fullName: true, avatarUrl: true } },
          },
        },
      },
    });
  }
}
