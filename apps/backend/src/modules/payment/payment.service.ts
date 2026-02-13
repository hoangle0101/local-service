import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../../prisma/prisma.service';
import { MomoService, MomoCallbackData } from './momo.service';
import { RealtimeGateway } from '../gateway/realtime.gateway';

const PLATFORM_FEE_PERCENT = 0.1; // 10% commission

export interface CreatePaymentDto {
  bookingId: bigint;
  amount: number;
  paymentMethod: 'COD' | 'MOMO';
}

export interface ReleasePaymentDto {
  bookingPaymentId: bigint;
}

@Injectable()
export class PaymentService {
  constructor(
    private prisma: PrismaService,
    private momoService: MomoService,
    private realtimeGateway: RealtimeGateway,
  ) {}

  /**
   * Calculate platform fee and provider amount
   */
  calculateFees(totalAmount: number): {
    platformFee: number;
    providerAmount: number;
  } {
    const platformFee = Math.round(totalAmount * PLATFORM_FEE_PERCENT);
    const providerAmount = totalAmount - platformFee;
    return { platformFee, providerAmount };
  }

  /**
   * CRON JOB: Auto-release escrow payments every 5 minutes
   * Releases payments where:
   * - status = 'held'
   * - autoReleaseAt <= now
   * - disputeId is null (not disputed)
   */
  @Cron(CronExpression.EVERY_5_MINUTES)
  async processAutoReleaseEscrow() {
    const now = new Date();

    // Find all payments ready for auto-release
    const paymentsToRelease = await this.prisma.bookingPayment.findMany({
      where: {
        status: 'held',
        autoReleaseAt: {
          lte: now,
        },
        disputeId: null, // Not disputed
      },
      include: {
        booking: true,
        provider: true,
      },
    });

    if (paymentsToRelease.length === 0) {
      return;
    }

    console.log(
      `[Payment] Auto-releasing ${paymentsToRelease.length} escrow payments...`,
    );

    for (const payment of paymentsToRelease) {
      try {
        await this.releasePaymentInternal(payment);
        console.log(
          `[Payment] Auto-released payment ${payment.id} for booking ${payment.bookingId}`,
        );
      } catch (error) {
        console.error(
          `[Payment] Failed to auto-release payment ${payment.id}:`,
          error.message,
        );
      }
    }
  }

  /**
   * Internal release payment logic (shared between manual and auto-release)
   */
  private async releasePaymentInternal(payment: any) {
    // Update payment status
    await this.prisma.bookingPayment.update({
      where: { id: payment.id },
      data: {
        status: 'released',
        releasedAt: new Date(),
      },
    });

    // Add provider earnings to wallet
    const updatedWallet = await this.prisma.wallet.upsert({
      where: { userId: payment.providerId },
      create: {
        userId: payment.providerId,
        balance: payment.providerAmount,
      },
      update: {
        balance: { increment: payment.providerAmount },
      },
    });

    // Create wallet transaction
    await this.prisma.walletTransaction.create({
      data: {
        walletUserId: payment.providerId,
        type: 'earning',
        amount: payment.providerAmount,
        balanceAfter: updatedWallet.balance,
        status: 'completed',
        metadata: {
          bookingPaymentId: payment.id.toString(),
          bookingId: payment.bookingId.toString(),
          source: 'escrow_release',
        },
      },
    });

    // Create booking event
    await this.prisma.bookingEvent.create({
      data: {
        bookingId: payment.bookingId,
        newStatus: 'completed' as any,
        note: `Tiền đã được chuyển cho thợ: ${Number(payment.providerAmount).toLocaleString()}đ`,
      },
    });
  }

  /**
   * Create booking payment (COD or MoMo)
   */
  async createBookingPayment(dto: CreatePaymentDto) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: dto.bookingId },
      include: { customer: true, providerUser: true },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    if (!booking.providerId) {
      throw new BadRequestException('Booking has no provider assigned');
    }

    // Check if payment already exists
    const existingPayment = await this.prisma.bookingPayment.findUnique({
      where: { bookingId: dto.bookingId },
    });

    if (existingPayment) {
      // COD selected - need to change status to pending_completion
      if (dto.paymentMethod.toUpperCase() === 'COD' && booking.status === 'pending_payment') {
        // Update booking payment method if different
        if (existingPayment.paymentMethod !== 'cod') {
          await this.prisma.bookingPayment.update({
            where: { id: existingPayment.id },
            data: { paymentMethod: 'cod' as any },
          });
          console.log('[Payment] Updated existing payment method to: COD');
        }
        
        // Update booking status to pending_completion
        await this.prisma.booking.update({
          where: { id: dto.bookingId },
          data: { 
            paymentMethod: 'cod' as any,
            status: 'pending_completion' as any,
          },
        });
        
        // Create booking event
        await this.prisma.bookingEvent.create({
          data: {
            bookingId: dto.bookingId,
            previousStatus: 'pending_payment' as any,
            newStatus: 'pending_completion' as any,
            actorUserId: booking.customerId,
            note: 'Khách hàng chọn thanh toán tiền mặt (COD)',
          },
        });
        
        // Notify provider
        if (booking.providerId) {
          this.realtimeGateway.emitBookingStatusChange(
            booking.providerId.toString(),
            booking.customerId.toString(),
            {
              bookingId: dto.bookingId.toString(),
              status: 'pending_completion',
              previousStatus: 'pending_payment',
              message: 'Khách đã chọn thanh toán tiền mặt - Chờ xác nhận thu tiền',
            },
          );
        }
        
        console.log('[Payment] Changed booking status to pending_completion');
        return {
          bookingPayment: this.formatBookingPayment(existingPayment),
          message: 'Đã chọn thanh toán tiền mặt - Chờ thợ xác nhận thu tiền',
        };
      }
      
      // For other cases (e.g., MoMo or already in pending_completion), just return existing
      console.log('[Payment] Returning existing payment:', existingPayment.id.toString());
      return {
        bookingPayment: this.formatBookingPayment(existingPayment),
        message: 'Payment đã tồn tại',
      };
    }

    // Calculate fees
    const { platformFee, providerAmount } = this.calculateFees(dto.amount);

    // Create booking payment record
    const bookingPayment = await this.prisma.bookingPayment.create({
      data: {
        bookingId: dto.bookingId,
        customerId: booking.customerId,
        providerId: booking.providerId,
        amount: dto.amount,
        platformFee,
        providerAmount,
        paymentMethod: dto.paymentMethod,
        status: 'pending',
      },
    });

    console.log('[Payment] Created booking payment:', {
      id: bookingPayment.id.toString(),
      amount: dto.amount,
      platformFee,
      providerAmount,
      method: dto.paymentMethod,
    });

    // If MoMo, create payment request
    if (dto.paymentMethod === 'MOMO') {
      const orderId = `LSP_${bookingPayment.id}_${Date.now()}`;
      const momoResponse = await this.momoService.createPayment({
        orderId,
        amount: dto.amount,
        orderInfo: `Thanh toán dịch vụ #${booking.code || booking.id}`,
        extraData: Buffer.from(
          JSON.stringify({
            bookingPaymentId: bookingPayment.id.toString(),
            bookingId: dto.bookingId.toString(),
          }),
        ).toString('base64'),
      });

      return {
        bookingPayment: this.formatBookingPayment(bookingPayment),
        momo: {
          payUrl: momoResponse.payUrl,
          qrCodeUrl: momoResponse.qrCodeUrl,
          deeplink: momoResponse.deeplink,
        },
      };
    }

    // COD - Update booking status to pending_completion and notify provider
    if (dto.paymentMethod === 'COD' && booking.providerId) {
      // Update booking paymentMethod and status to pending_completion
      await this.prisma.booking.update({
        where: { id: dto.bookingId },
        data: { 
          paymentMethod: 'cod' as any,
          status: 'pending_completion' as any,
        },
      });
      
      // Create booking event
      await this.prisma.bookingEvent.create({
        data: {
          bookingId: dto.bookingId,
          previousStatus: 'pending_payment' as any,
          newStatus: 'pending_completion' as any,
          actorUserId: booking.customerId,
          note: 'Khách hàng chọn thanh toán tiền mặt (COD)',
        },
      });
      
      // Notify provider that customer selected COD - waiting for confirmation
      this.realtimeGateway.emitBookingStatusChange(
        booking.providerId.toString(),
        booking.customerId.toString(),
        {
          bookingId: dto.bookingId.toString(),
          status: 'pending_completion',
          previousStatus: 'pending_payment',
          message: 'Khách đã chọn thanh toán tiền mặt - Chờ xác nhận thu tiền',
        },
      );
    }
    
    return {
      bookingPayment: this.formatBookingPayment(bookingPayment),
      message: 'Đã chọn thanh toán tiền mặt - Chờ thợ xác nhận thu tiền',
    };
  }

  /**
   * Handle MoMo IPN callback - supports both booking payments and wallet deposits
   */
  async handleMomoCallback(data: MomoCallbackData) {
    console.log('[Payment] MoMo callback received:', data);

    // Verify signature
    if (!this.momoService.verifySignature(data)) {
      console.error('[Payment] Invalid MoMo signature');
      throw new BadRequestException('Invalid signature');
    }

    // Parse extraData
    let extraData: any = {};
    try {
      extraData = JSON.parse(Buffer.from(data.extraData, 'base64').toString());
    } catch (e) {
      console.error('[Payment] Failed to parse extraData:', e);
    }

    const isSuccess = this.momoService.isPaymentSuccessful(data.resultCode);

    console.log('[Payment] Callback identified as:', {
      type: extraData.type,
      isSuccess,
      orderId: data.orderId,
    });

    // Handle wallet deposits
    if (extraData.type === 'wallet_deposit') {
      return this.handleWalletDepositCallback(data, extraData, isSuccess);
    }

    // Handle booking payments (existing logic)
    const bookingPaymentId = extraData.bookingPaymentId
      ? BigInt(extraData.bookingPaymentId)
      : null;

    if (!bookingPaymentId) {
      console.error('[Payment] No bookingPaymentId in extraData');
      return { success: false, message: 'Missing bookingPaymentId' };
    }

    const bookingPayment = await this.prisma.bookingPayment.findUnique({
      where: { id: bookingPaymentId },
    });

    if (!bookingPayment) {
      console.error(
        '[Payment] BookingPayment not found:',
        bookingPaymentId.toString(),
      );
      return { success: false, message: 'Payment not found' };
    }

    // Check result
    if (isSuccess) {
      // Payment successful - move to HELD (escrow)
      await this.prisma.bookingPayment.update({
        where: { id: bookingPaymentId },
        data: {
          status: 'held',
          momoTransId: data.transId.toString(),
          paidAt: new Date(),
          heldAt: new Date(),
        },
      });

      console.log(
        '[Payment] Payment held in escrow:',
        bookingPaymentId.toString(),
      );
      return { success: true, message: 'Payment held in escrow' };
    } else {
      // Payment failed
      console.log('[Payment] Payment failed:', data.message);
      return { success: false, message: data.message };
    }
  }

  /**
   * Handle wallet deposit MoMo callback
   */
  private async handleWalletDepositCallback(
    data: MomoCallbackData,
    extraData: any,
    isSuccess: boolean,
  ) {
    const walletTransactionId = extraData.walletTransactionId
      ? BigInt(extraData.walletTransactionId)
      : null;
    const userId = extraData.userId ? BigInt(extraData.userId) : null;

    if (!walletTransactionId || !userId) {
      console.error('[Payment] Missing wallet deposit data in extraData:', {
        extraData,
        walletTransactionId: extraData.walletTransactionId,
        userId: extraData.userId,
      });
      return { success: false, message: 'Missing transaction data' };
    }

    const transaction = await this.prisma.walletTransaction.findUnique({
      where: { id: walletTransactionId },
    });

    if (!transaction) {
      console.error(
        '[Payment] Wallet transaction not found:',
        walletTransactionId.toString(),
      );
      return { success: false, message: 'Transaction not found' };
    }

    if (isSuccess) {
      // Deposit successful - credit user wallet
      const updatedWallet = await this.prisma.wallet.upsert({
        where: { userId },
        create: {
          userId,
          balance: data.amount,
        },
        update: {
          balance: { increment: data.amount },
        },
      });

      // Update transaction status
      await this.prisma.walletTransaction.update({
        where: { id: walletTransactionId },
        data: {
          status: 'completed',
          balanceAfter: updatedWallet.balance,
          metadata: {
            ...(transaction.metadata as any),
            momoTransId: data.transId.toString(),
            completedAt: new Date().toISOString(),
          },
        },
      });

      // Update payment record
      if (extraData.paymentId) {
        await this.prisma.payment.update({
          where: { id: BigInt(extraData.paymentId) },
          data: {
            status: 'succeeded',
            gatewayTxId: data.transId.toString(),
          },
        });
      }

      console.log('[Payment] Wallet deposit successful:', {
        userId: userId.toString(),
        amount: data.amount,
        newBalance: updatedWallet.balance.toString(),
      });

      // Notify user via socket
      this.realtimeGateway.emitWalletUpdate(
        userId.toString(),
        updatedWallet.balance.toNumber(),
      );

      return { success: true, message: 'Deposit completed' };
    } else {
      // Deposit failed
      await this.prisma.walletTransaction.update({
        where: { id: walletTransactionId },
        data: { status: 'failed' },
      });

      console.log('[Payment] Wallet deposit failed:', data.message);
      return { success: false, message: data.message };
    }
  }

  /**
   * Confirm COD payment (provider collected cash)
   */
  async confirmCodPayment(bookingPaymentId: bigint, providerId: bigint) {
    const payment = await this.prisma.bookingPayment.findUnique({
      where: { id: bookingPaymentId },
    });

    if (!payment) {
      throw new NotFoundException('Payment not found');
    }

    if (payment.providerId !== providerId) {
      throw new BadRequestException('Not authorized');
    }

    if (payment.paymentMethod !== 'COD') {
      throw new BadRequestException('Not a COD payment');
    }

    if (payment.status !== 'pending') {
      throw new BadRequestException('Payment already processed');
    }

    // For COD, move directly to HELD status
    const updated = await this.prisma.bookingPayment.update({
      where: { id: bookingPaymentId },
      data: {
        status: 'held',
        paidAt: new Date(),
        heldAt: new Date(),
      },
    });

    console.log(
      '[Payment] COD payment confirmed:',
      bookingPaymentId.toString(),
    );

    // Notify status change
    this.realtimeGateway.emitBookingStatusChange(
      payment.customerId.toString(),
      payment.providerId.toString(),
      {
        bookingId: payment.bookingId.toString(),
        status: 'held',
        message:
          'Thợ đã xác nhận thu tiền mặt. Tiền đang được giữ bởi hệ thống.',
        actorId: providerId.toString(),
      },
    );

    return this.formatBookingPayment(updated);
  }

  /**
   * Release payment to provider (after service completed)
   */
  async releasePayment(bookingPaymentId: bigint) {
    const payment = await this.prisma.bookingPayment.findUnique({
      where: { id: bookingPaymentId },
      include: { provider: { include: { wallet: true } } },
    });

    if (!payment) {
      throw new NotFoundException('Payment not found');
    }

    if (payment.status !== 'held') {
      throw new BadRequestException(
        `Cannot release payment in ${payment.status} status`,
      );
    }

    // Update payment status
    const updated = await this.prisma.bookingPayment.update({
      where: { id: bookingPaymentId },
      data: {
        status: 'released',
        releasedAt: new Date(),
      },
    });

    // Add provider earnings to wallet
    await this.prisma.wallet.upsert({
      where: { userId: payment.providerId },
      create: {
        userId: payment.providerId,
        balance: payment.providerAmount,
      },
      update: {
        balance: { increment: payment.providerAmount },
      },
    });

    // Create wallet transaction
    const wallet = await this.prisma.wallet.findUnique({
      where: { userId: payment.providerId },
    });

    await this.prisma.walletTransaction.create({
      data: {
        walletUserId: payment.providerId,
        type: 'earning',
        amount: payment.providerAmount,
        balanceAfter: wallet?.balance || payment.providerAmount,
        status: 'completed',
        metadata: {
          bookingPaymentId: bookingPaymentId.toString(),
          bookingId: payment.bookingId.toString(),
        },
      },
    });

    console.log('[Payment] Payment released:', {
      paymentId: bookingPaymentId.toString(),
      providerAmount: payment.providerAmount.toString(),
    });

    // Notify provider of wallet update
    if (wallet) {
      this.realtimeGateway.emitWalletUpdate(
        payment.providerId.toString(),
        wallet.balance.toNumber(),
      );
    }

    return this.formatBookingPayment(updated);
  }

  /**
   * Refund payment to customer
   */
  async refundPayment(bookingPaymentId: bigint, reason: string) {
    const payment = await this.prisma.bookingPayment.findUnique({
      where: { id: bookingPaymentId },
    });

    if (!payment) {
      throw new NotFoundException('Payment not found');
    }

    if (payment.status !== 'held' && payment.status !== 'pending') {
      throw new BadRequestException(
        `Cannot refund payment in ${payment.status} status`,
      );
    }

    // Update payment status
    const updated = await this.prisma.bookingPayment.update({
      where: { id: bookingPaymentId },
      data: {
        status: 'refunded',
        refundedAt: new Date(),
      },
    });

    // TODO: If MoMo payment, initiate refund via MoMo API
    // For now, manual refund is required

    console.log('[Payment] Payment refunded:', {
      paymentId: bookingPaymentId.toString(),
      reason,
    });

    return this.formatBookingPayment(updated);
  }

  /**
   * Get booking payment by ID
   */
  async getBookingPayment(id: bigint) {
    const payment = await this.prisma.bookingPayment.findUnique({
      where: { id },
      include: {
        booking: true,
        customer: { include: { profile: true } },
        provider: { include: { profile: true } },
      },
    });

    if (!payment) {
      throw new NotFoundException('Payment not found');
    }

    return this.formatBookingPayment(payment);
  }

  /**
   * Manually check payment status from MoMo (Polling fallback)
   */
  async checkPaymentStatus(orderId: string) {
    if (!orderId) {
      throw new BadRequestException('OrderId is required');
    }

    console.log('[Payment] Checking status for order:', orderId);

    // 1. Query MoMo API
    // RequestId for query should be different from original request
    const requestId = `${orderId}_query_${Date.now()}`;
    const momoResponse = await this.momoService.queryPayment(
      orderId,
      requestId,
    );

    console.log('[Payment] MoMo Query Response:', momoResponse);

    if (momoResponse.resultCode !== 0) {
      return {
        status: 'pending',
        message: `Payment still pending or failed: ${momoResponse.message}`,
        momoResult: momoResponse,
      };
    }

    // 2. If Successful, Trigger Callback Logic manually
    // We need to reconstruct the callback data structure
    // NOTE: queryPayment response might not have 'extraData' populated fully if not passed back by MoMo query API.
    // However, for 'wallet_deposit', we usually encode IDs in extraData.
    // If MoMo Query response doesn't return full extraData, we might strictly rely on our DB state
    // BUT we need the mapping.
    // Let's check `extraData` in response.

    let extraDataObj: any = {};
    try {
      if (momoResponse.extraData) {
        extraDataObj = JSON.parse(
          Buffer.from(momoResponse.extraData, 'base64').toString(),
        );
      }
    } catch (e) {
      console.error('[Payment] Failed to parse extraData from Query:', e);
    }

    // Use the existing handling logic
    const callbackData: MomoCallbackData = {
      partnerCode: momoResponse.partnerCode,
      orderId: momoResponse.orderId,
      requestId: momoResponse.requestId,
      amount: momoResponse.amount,
      transId: momoResponse.transId,
      resultCode: momoResponse.resultCode,
      message: momoResponse.message,
      responseTime: momoResponse.responseTime,
      extraData: momoResponse.extraData,
      signature: '', // Signature not needed for internal query verification
    };

    // We should bypass signature check in handleWalletDepositCallback if called internally?
    // Actually handleWalletDepositCallback is private and doesn't verify signature.
    // handleMomoCallback verifies signature.

    // We will call handleWalletDepositCallback directly if it's a wallet deposit
    if (extraDataObj.type === 'wallet_deposit') {
      const result = await this.handleWalletDepositCallback(
        callbackData,
        extraDataObj,
        true,
      );
      return {
        status: 'success',
        data: result,
        momoResult: momoResponse,
      };
    }

    // Handle generic Booking Payment if needed (logic similar to handleMomoCallback)
    // For now, focusing on Wallet Deposit as per user urgency.

    return {
      status: 'processed',
      message: 'Payment status checked',
      momoResult: momoResponse,
    };
  }

  /**
   * Get payments by provider
   */
  async getProviderPayments(providerId: bigint, status?: string) {
    const where: any = { providerId };
    if (status) {
      where.status = status;
    }

    const payments = await this.prisma.bookingPayment.findMany({
      where,
      include: {
        booking: true,
        customer: { include: { profile: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    return payments.map((p) => this.formatBookingPayment(p));
  }

  /**
   * Format booking payment for response
   */
  private formatBookingPayment(payment: any) {
    return {
      id: payment.id.toString(),
      bookingId: payment.bookingId.toString(),
      customerId: payment.customerId.toString(),
      providerId: payment.providerId.toString(),
      amount: Number(payment.amount),
      platformFee: Number(payment.platformFee),
      providerAmount: Number(payment.providerAmount),
      paymentMethod: payment.paymentMethod,
      momoTransId: payment.momoTransId,
      status: payment.status,
      paidAt: payment.paidAt,
      heldAt: payment.heldAt,
      releasedAt: payment.releasedAt,
      refundedAt: payment.refundedAt,
      createdAt: payment.createdAt,
      booking: payment.booking
        ? {
            id: payment.booking.id.toString(),
            code: payment.booking.code,
            status: payment.booking.status,
          }
        : undefined,
      customer: payment.customer?.profile
        ? {
            id: payment.customer.id.toString(),
            fullName: payment.customer.profile.fullName,
            phone: payment.customer.phone,
          }
        : undefined,
      provider: payment.provider?.profile
        ? {
            id: payment.provider.id.toString(),
            fullName: payment.provider.profile.fullName,
          }
        : undefined,
    };
  }
}
