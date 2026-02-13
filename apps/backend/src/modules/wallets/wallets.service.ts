import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Inject,
  forwardRef,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { DepositDto, WithdrawDto } from './dto';
import { Decimal } from '@prisma/client/runtime/library';
import { MomoService } from '../payment/momo.service';

@Injectable()
export class WalletsService {
  constructor(
    private prisma: PrismaService,
    @Inject(forwardRef(() => MomoService))
    private momoService: MomoService,
  ) {}

  /**
   * Get wallet balance for a user
   */
  async getBalance(userId: bigint) {
    const wallet = await this.prisma.wallet.findUnique({
      where: { userId },
      include: {
        _count: {
          select: { transactions: true },
        },
      },
    });

    if (!wallet) {
      throw new NotFoundException('Wallet not found');
    }

    const availableBalance = wallet.balance.minus(wallet.lockedBalance);

    return {
      balance: wallet.balance.toString(),
      lockedBalance: wallet.lockedBalance.toString(),
      availableBalance: availableBalance.toString(),
      minimumBalance: wallet.minimumBalance.toString(),
      currency: wallet.currency,
      totalTransactions: wallet._count.transactions,
      createdAt: wallet.createdAt,
    };
  }

  /**
   * Check if provider has minimum balance for COD
   * @param userId Provider user ID
   * @param requiredAmount Amount that needs to be locked (usually platform fee)
   * @returns true if provider can accept COD
   */
  async checkMinimumBalance(
    userId: bigint,
    requiredAmount: number,
  ): Promise<{
    canAcceptCOD: boolean;
    availableBalance: number;
    requiredAmount: number;
    shortfall: number;
  }> {
    const wallet = await this.prisma.wallet.findUnique({
      where: { userId },
    });

    if (!wallet) {
      return {
        canAcceptCOD: false,
        availableBalance: 0,
        requiredAmount,
        shortfall: requiredAmount,
      };
    }

    const availableBalance = wallet.balance.minus(wallet.lockedBalance);
    const canAcceptCOD = availableBalance.greaterThanOrEqualTo(
      new Decimal(requiredAmount),
    );
    const shortfall = canAcceptCOD
      ? 0
      : new Decimal(requiredAmount).minus(availableBalance).toNumber();

    return {
      canAcceptCOD,
      availableBalance: availableBalance.toNumber(),
      requiredAmount,
      shortfall,
    };
  }

  /**
   * Lock balance for COD payment (platform fee)
   * @param userId Provider user ID
   * @param amount Amount to lock
   * @param bookingId Related booking ID for tracking
   */
  async lockBalance(userId: bigint, amount: number, bookingId: bigint) {
    const wallet = await this.prisma.wallet.findUnique({
      where: { userId },
    });

    if (!wallet) {
      throw new NotFoundException('Wallet not found');
    }

    const availableBalance = wallet.balance.minus(wallet.lockedBalance);
    if (availableBalance.lessThan(new Decimal(amount))) {
      throw new BadRequestException(
        `Không đủ số dư khả dụng. Cần: ${amount} VND, Khả dụng: ${availableBalance} VND`,
      );
    }

    const updatedWallet = await this.prisma.wallet.update({
      where: { userId },
      data: {
        lockedBalance: { increment: amount },
        lockedBy: `booking_${bookingId}`,
      },
    });

    console.log(
      `[WalletsService] Locked ${amount} VND for booking ${bookingId}, provider ${userId}`,
    );

    return {
      lockedAmount: amount,
      newLockedBalance: updatedWallet.lockedBalance.toString(),
      availableBalance: updatedWallet.balance
        .minus(updatedWallet.lockedBalance)
        .toString(),
    };
  }

  /**
   * Unlock balance (when COD is cancelled or refunded)
   * @param userId Provider user ID
   * @param amount Amount to unlock
   * @param bookingId Related booking ID
   */
  async unlockBalance(userId: bigint, amount: number, bookingId: bigint) {
    const wallet = await this.prisma.wallet.findUnique({
      where: { userId },
    });

    if (!wallet) {
      throw new NotFoundException('Wallet not found');
    }

    // Don't unlock more than locked
    const unlockAmount = Math.min(amount, wallet.lockedBalance.toNumber());

    const updatedWallet = await this.prisma.wallet.update({
      where: { userId },
      data: {
        lockedBalance: { decrement: unlockAmount },
        lockedBy: null,
      },
    });

    console.log(
      `[WalletsService] Unlocked ${unlockAmount} VND for booking ${bookingId}, provider ${userId}`,
    );

    return {
      unlockedAmount: unlockAmount,
      newLockedBalance: updatedWallet.lockedBalance.toString(),
      availableBalance: updatedWallet.balance
        .minus(updatedWallet.lockedBalance)
        .toString(),
    };
  }

  /**
   * Deduct locked balance (platform fee collected from COD)
   * @param userId Provider user ID
   * @param amount Amount to deduct
   * @param bookingId Related booking ID
   */
  async deductLockedBalance(userId: bigint, amount: number, bookingId: bigint) {
    const wallet = await this.prisma.wallet.findUnique({
      where: { userId },
    });

    if (!wallet) {
      throw new NotFoundException('Wallet not found');
    }

    const deductAmount = Math.min(amount, wallet.lockedBalance.toNumber());

    return this.prisma.$transaction(async (tx) => {
      // Deduct from both balance and lockedBalance
      const updatedWallet = await tx.wallet.update({
        where: { userId },
        data: {
          balance: { decrement: deductAmount },
          lockedBalance: { decrement: deductAmount },
          lockedBy: null,
        },
      });

      // Create transaction record for platform fee
      await tx.walletTransaction.create({
        data: {
          walletUserId: userId,
          type: 'fee',
          amount: new Decimal(-deductAmount), // Negative for deduction
          balanceAfter: updatedWallet.balance,
          status: 'completed',
          metadata: {
            bookingId: bookingId.toString(),
            description: 'Phí nền tảng từ thanh toán COD',
          },
        },
      });

      console.log(
        `[WalletsService] Deducted ${deductAmount} VND platform fee for booking ${bookingId}`,
      );

      return {
        deductedAmount: deductAmount,
        newBalance: updatedWallet.balance.toString(),
        newLockedBalance: updatedWallet.lockedBalance.toString(),
      };
    });
  }

  /**
   * Credit balance to a user (e.g. for earnings or refunds)
   * @param userId User ID
   * @param amount Amount to credit
   * @param type Transaction type (earning, refund, etc)
   * @param metadata Optional metadata
   */
  async creditBalance(
    userId: bigint,
    amount: number,
    type: 'earning' | 'refund' | 'deposit',
    metadata?: any,
  ) {
    return this.prisma.$transaction(async (tx) => {
      const updatedWallet = await tx.wallet.upsert({
        where: { userId },
        create: {
          userId,
          balance: new Decimal(amount),
          currency: 'VND',
        },
        update: {
          balance: { increment: amount },
        },
      });

      await tx.walletTransaction.create({
        data: {
          walletUserId: userId,
          type: type as any,
          amount: new Decimal(amount),
          balanceAfter: updatedWallet.balance,
          status: 'completed',
          metadata,
        },
      });

      return {
        newBalance: updatedWallet.balance.toString(),
        creditedAmount: amount,
      };
    });
  }

  /**
   * Get transaction history
   */
  async getTransactions(userId: bigint, page: number = 1, limit: number = 20) {
    const wallet = await this.prisma.wallet.findUnique({
      where: { userId },
    });

    if (!wallet) {
      throw new NotFoundException('Wallet not found');
    }

    const skip = (page - 1) * limit;

    const [transactions, total] = await Promise.all([
      this.prisma.walletTransaction.findMany({
        where: { walletUserId: userId },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.walletTransaction.count({
        where: { walletUserId: userId },
      }),
    ]);

    return {
      data: transactions.map((tx) => ({
        ...tx,
        amount: tx.amount.toString(),
        balanceAfter: tx.balanceAfter.toString(),
      })),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Deposit money to wallet using MoMo
   */
  async deposit(userId: bigint, dto: DepositDto) {
    // Ensure wallet exists
    let wallet = await this.prisma.wallet.findUnique({
      where: { userId },
    });

    if (!wallet) {
      // Create wallet if not exists
      wallet = await this.prisma.wallet.create({
        data: {
          userId,
          balance: new Decimal(0),
          lockedBalance: new Decimal(0),
          minimumBalance: new Decimal(0),
          currency: 'VND',
        },
      });
    }

    return this.prisma.$transaction(async (tx) => {
      // Create wallet transaction (pending)
      const transaction = await tx.walletTransaction.create({
        data: {
          walletUserId: userId,
          type: 'deposit',
          amount: new Decimal(dto.amount),
          balanceAfter: wallet.balance,
          status: 'pending',
          metadata: {
            gateway: dto.gateway,
            initiatedAt: new Date().toISOString(),
          },
        },
      });

      // Create payment record
      const payment = await tx.payment.create({
        data: {
          amount: new Decimal(dto.amount),
          currency: 'VND',
          method:
            dto.gateway === 'momo'
              ? 'momo'
              : dto.gateway === 'bank_transfer'
                ? 'bank_transfer'
                : 'card',
          gateway: dto.gateway,
          gatewayTxId: `pending_${transaction.id}_${Date.now()}`,
          environment:
            process.env.NODE_ENV === 'production'
              ? 'production'
              : 'development',
          status: 'initiated',
          payload: {
            walletTransactionId: transaction.id.toString(),
            userId: userId.toString(),
            type: 'wallet_deposit',
          },
        },
      });

      // Link payment to transaction
      await tx.walletTransaction.update({
        where: { id: transaction.id },
        data: { relatedPaymentId: payment.id },
      });

      // Generate MoMo payment if gateway is momo
      if (dto.gateway === 'momo') {
        try {
          const orderId = `DEPOSIT_${transaction.id}_${Date.now()}`;
          const momoResponse = await this.momoService.createPayment({
            orderId,
            amount: dto.amount,
            orderInfo: `Nạp tiền vào ví: ${dto.amount.toLocaleString()}đ`,
            extraData: Buffer.from(
              JSON.stringify({
                walletTransactionId: transaction.id.toString(),
                paymentId: payment.id.toString(),
                userId: userId.toString(),
                type: 'wallet_deposit',
              }),
            ).toString('base64'),
          });

          // Update payment with MoMo info
          await tx.payment.update({
            where: { id: payment.id },
            data: {
              gatewayTxId: momoResponse.orderId,
              status: 'initiated',
            },
          });

          return {
            transactionId: transaction.id.toString(),
            paymentId: payment.id.toString(),
            orderId: momoResponse.orderId,
            payUrl: momoResponse.payUrl,
            qrCodeUrl: momoResponse.qrCodeUrl,
            deeplink: momoResponse.deeplink,
            amount: dto.amount,
            gateway: dto.gateway,
            status: 'pending',
            message: 'Vui lòng thanh toán qua MoMo',
          };
        } catch (error) {
          console.error('[WalletsService] MoMo deposit error:', error.message);
          throw new BadRequestException(
            `Không thể tạo thanh toán MoMo: ${error.message}`,
          );
        }
      }

      // For other gateways, return mock payment URL
      const paymentUrl = this.generatePaymentUrl(
        payment.id,
        dto.gateway,
        dto.amount,
      );

      return {
        transactionId: transaction.id.toString(),
        paymentId: payment.id.toString(),
        paymentUrl,
        amount: dto.amount,
        gateway: dto.gateway,
        status: 'pending',
        message: 'Please complete payment at the provided URL',
      };
    });
  }

  /**
   * Withdraw money from wallet
   */
  async withdraw(userId: bigint, dto: WithdrawDto) {
    const wallet = await this.prisma.wallet.findUnique({
      where: { userId },
    });

    if (!wallet) {
      throw new NotFoundException('Wallet not found');
    }

    // Check balance
    if (wallet.balance.lessThan(new Decimal(dto.amount))) {
      throw new BadRequestException(
        `Insufficient balance. Available: ${wallet.balance} VND`,
      );
    }

    // Check daily withdrawal limit
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const todayWithdrawals = await this.prisma.walletTransaction.aggregate({
      where: {
        walletUserId: userId,
        type: 'withdrawal',
        status: { in: ['pending', 'completed'] },
        createdAt: { gte: today },
      },
      _sum: { amount: true },
    });

    const dailyLimit = 10000000; // 10M VND
    const totalToday = todayWithdrawals._sum.amount || new Decimal(0);

    if (totalToday.plus(dto.amount).greaterThan(new Decimal(dailyLimit))) {
      throw new BadRequestException(
        `Daily withdrawal limit exceeded. Limit: ${dailyLimit} VND, Used today: ${totalToday} VND`,
      );
    }

    return this.prisma.$transaction(async (tx) => {
      // Deduct balance immediately
      const updatedWallet = await tx.wallet.update({
        where: { userId: wallet.userId },
        data: { balance: { decrement: dto.amount } },
      });

      // Create withdrawal transaction
      const transaction = await tx.walletTransaction.create({
        data: {
          walletUserId: userId,
          type: 'withdrawal',
          amount: new Decimal(dto.amount),
          balanceAfter: updatedWallet.balance,
          status: 'pending', // Pending admin approval
          metadata: {
            bankAccount: dto.bankAccount,
            bankName: dto.bankName,
            requestedAt: new Date().toISOString(),
          },
        },
      });

      // Auto-approve if < 1M VND
      if (dto.amount < 1000000) {
        await tx.walletTransaction.update({
          where: { id: transaction.id },
          data: { status: 'completed' },
        });

        // Create payout payment record
        const payment = await tx.payment.create({
          data: {
            amount: new Decimal(dto.amount),
            currency: 'VND',
            method: 'bank_transfer',
            gateway: 'bank_transfer',
            gatewayTxId: `withdraw_${transaction.id}_${Date.now()}`,
            environment:
              process.env.NODE_ENV === 'production'
                ? 'production'
                : 'development',
            status: 'succeeded',
            payload: {
              userId: userId.toString(),
              type: 'withdrawal',
              walletTransactionId: transaction.id.toString(),
              bankAccount: dto.bankAccount,
              bankName: dto.bankName,
            },
          },
        });

        // Link payment to transaction
        await tx.walletTransaction.update({
          where: { id: transaction.id },
          data: { relatedPaymentId: payment.id },
        });

        return {
          message: 'Withdrawal processed successfully',
          transactionId: transaction.id.toString(),
          amount: dto.amount,
          status: 'completed',
          bankAccount: dto.bankAccount,
          bankName: dto.bankName,
        };
      }

      // Require admin approval for >= 1M
      return {
        message: 'Withdrawal request submitted for approval',
        transactionId: transaction.id.toString(),
        amount: dto.amount,
        status: 'pending',
        note: 'Large withdrawals require admin approval (1-2 business days)',
      };
    });
  }

  /**
   * Check and process deposit by querying MoMo directly
   * This is a fallback for unreliable IPN callbacks
   */
  async checkAndProcessDeposit(userId: bigint, orderId: string) {
    if (!orderId) {
      throw new BadRequestException('OrderId is required');
    }

    console.log('[WalletsService] Checking deposit status for:', orderId);

    // Query MoMo for payment status
    const requestId = `${orderId}_check_${Date.now()}`;
    const momoResponse = await this.momoService.queryPayment(
      orderId,
      requestId,
    );

    console.log('[WalletsService] MoMo query response:', momoResponse);

    if (momoResponse.resultCode !== 0) {
      return {
        status: 'pending',
        message: `Giao dịch đang chờ xử lý hoặc thất bại: ${momoResponse.message}`,
        momoResultCode: momoResponse.resultCode,
      };
    }

    // Payment successful - find and process the transaction
    // Extract transaction ID from orderId (format: DEPOSIT_{transactionId}_{timestamp})
    const parts = orderId.split('_');
    if (parts.length < 2) {
      return {
        status: 'error',
        message: 'Invalid orderId format',
      };
    }

    const transactionId = BigInt(parts[1]);

    // Check if already processed
    const existingTransaction = await this.prisma.walletTransaction.findUnique({
      where: { id: transactionId },
    });

    if (!existingTransaction) {
      return {
        status: 'error',
        message: 'Transaction not found',
      };
    }

    if (existingTransaction.status === 'completed') {
      // Already processed, just return success
      const wallet = await this.prisma.wallet.findUnique({
        where: { userId },
      });

      return {
        status: 'success',
        message: 'Giao dịch đã được xử lý trước đó',
        newBalance: wallet?.balance.toString() || '0',
        alreadyProcessed: true,
      };
    }

    // Process the deposit
    const amount = momoResponse.amount;

    const updatedWallet = await this.prisma.wallet.upsert({
      where: { userId },
      create: {
        userId,
        balance: new Decimal(amount),
        lockedBalance: new Decimal(0),
        minimumBalance: new Decimal(0),
        currency: 'VND',
      },
      update: {
        balance: { increment: amount },
      },
    });

    // Update transaction status
    await this.prisma.walletTransaction.update({
      where: { id: transactionId },
      data: {
        status: 'completed',
        balanceAfter: updatedWallet.balance,
        metadata: {
          ...(existingTransaction.metadata as any),
          momoTransId: momoResponse.transId?.toString(),
          completedAt: new Date().toISOString(),
          processedViaPolling: true,
        },
      },
    });

    // Update payment record if exists
    if (existingTransaction.relatedPaymentId) {
      await this.prisma.payment.update({
        where: { id: existingTransaction.relatedPaymentId },
        data: {
          status: 'succeeded',
          gatewayTxId: momoResponse.transId?.toString(),
        },
      });
    }

    console.log('[WalletsService] Deposit processed successfully:', {
      userId: userId.toString(),
      amount,
      newBalance: updatedWallet.balance.toString(),
    });

    return {
      status: 'success',
      message: 'Nạp tiền thành công!',
      amount,
      newBalance: updatedWallet.balance.toString(),
      transactionId: transactionId.toString(),
    };
  }

  /**
   * Generate payment URL (mock implementation)
   * In production: integrate with real payment gateway APIs
   */
  private generatePaymentUrl(
    paymentId: bigint,
    gateway: string,
    amount: number,
  ): string {
    const baseUrl = process.env.APP_URL || 'http://localhost:3000';

    // Mock payment URLs - in production, call gateway API
    switch (gateway) {
      case 'momo':
        return `https://test-payment.momo.vn/v2/gateway/pay?partnerCode=MOCK&orderId=${paymentId}&amount=${amount}&returnUrl=${baseUrl}/api/v1/payments/callback`;
      case 'stripe':
        return `https://checkout.stripe.com/pay/cs_test_${paymentId}`;
      case 'bank_transfer':
        return `${baseUrl}/api/v1/payments/bank-transfer-info/${paymentId}`;
      default:
        return `${baseUrl}/api/v1/payments/checkout/${paymentId}`;
    }
  }
}
