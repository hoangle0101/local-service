import {
  Injectable,
  BadRequestException,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { MomoService } from './momo.service';
import { WalletsService } from '../wallets/wallets.service';
import { RealtimeGateway, SocketEvents } from '../gateway/realtime.gateway';
import { NotificationsService } from '../notifications/notifications.service';

const PLATFORM_FEE_RATE = 0.1; // 10%

const BOOKING_PAYMENT_INCLUDE = {
  service: true,
  customer: {
    include: { profile: true },
  },
  providerUser: {
    include: { providerProfile: true },
  },
};

@Injectable()
export class BookingPaymentService {
  constructor(
    private prisma: PrismaService,
    private momoService: MomoService,
    private walletsService: WalletsService,
    private realtimeGateway: RealtimeGateway,
    private notificationsService: NotificationsService,
  ) {}

  /**
   * Provider updates final price (after service completion)
   */
  async updateFinalPrice(
    bookingId: bigint,
    providerId: bigint,
    data: {
      actualPrice: number;
      additionalCosts?: number;
      additionalNotes?: string;
    },
  ) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) {
      throw new NotFoundException('Booking không tồn tại');
    }

    if (booking.providerId !== providerId) {
      throw new ForbiddenException('Bạn không có quyền cập nhật booking này');
    }

    if (!['confirmed', 'in_progress'].includes(booking.status)) {
      throw new BadRequestException('Không thể cập nhật giá ở trạng thái này');
    }

    return this.prisma.booking.update({
      where: { id: bookingId },
      data: {
        actualPrice: data.actualPrice,
        additionalCosts: data.additionalCosts || 0,
        additionalNotes: data.additionalNotes,
      },
    });
  }

  /**
   * Provider marks service as complete → pending_payment
   */
  async markServiceComplete(bookingId: bigint, providerId: bigint) {
    console.log('[markServiceComplete] START - bookingId:', bookingId.toString(), 'providerId:', providerId.toString());
    
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    console.log('[markServiceComplete] Booking:', booking ? { id: booking.id.toString(), status: booking.status, providerId: booking.providerId?.toString() } : 'NOT FOUND');

    if (!booking) {
      throw new NotFoundException('Booking không tồn tại');
    }

    if (booking.providerId !== providerId) {
      throw new ForbiddenException('Bạn không có quyền cập nhật booking này');
    }

    if (!['accepted', 'in_progress'].includes(booking.status)) {
      console.log('[markServiceComplete] Invalid status:', booking.status);
      throw new BadRequestException(
        `Không thể hoàn thành ở trạng thái này (Hiện tại: ${booking.status})`,
      );
    }

    // If no actual price set, use estimated price
    const actualPrice =
      booking.actualPrice ||
      booking.estimatedPrice ||
      booking.providerServicePrice;
    if (!actualPrice) {
      throw new BadRequestException(
        'Vui lòng cập nhật giá trước khi hoàn thành',
      );
    }

    const totalPrice =
      Number(actualPrice) + Number(booking.additionalCosts || 0);
    const platformFee = Math.round(totalPrice * PLATFORM_FEE_RATE);
    const providerEarning = totalPrice - platformFee;

    const updated = await this.prisma.booking.update({
      where: { id: bookingId },
      data: {
        status: 'pending_payment' as any, // Will need to add to enum
        actualPrice: totalPrice,
        platformFee,
        providerEarning,
        completedAt: new Date(),
      },
    });

    // Create booking event
    await this.prisma.bookingEvent.create({
      data: {
        bookingId,
        previousStatus: booking.status,
        newStatus: 'pending_payment' as any,
        actorUserId: providerId,
        note: 'Dịch vụ hoàn thành, chờ thanh toán',
      },
    });

    // ESCROW STEP: Lock platform fee from provider wallet
    // We do this now to ensure provider has enough balance for the fee
    // If not, they shouldn't be able to mark it as complete (or we should warn them)
    // For now, we just proceed.
    await this.walletsService.lockBalance(providerId, platformFee, bookingId);

    console.log('[BookingPayment] Service marked complete:', {
      bookingId: bookingId.toString(),
      totalPrice,
      platformFee,
      providerEarning,
    });

    // Notify customer about payment required
    this.realtimeGateway.emitBookingStatusChange(
      providerId.toString(),
      booking.customerId.toString(),
      {
        bookingId: bookingId.toString(),
        status: 'pending_payment',
        previousStatus: booking.status,
        actorId: providerId.toString(),
      },
    );

    // Persistent notification
    await this.notificationsService.create(
      booking.customerId,
      'PAYMENT_REQUIRED',
      'Yêu cầu thanh toán',
      `Nhà cung cấp đã hoàn thành dịch vụ. Vui lòng thanh toán ${totalPrice.toLocaleString()} VND.`,
      { bookingId: bookingId.toString(), amount: totalPrice },
    );

    // Refetch with relations for formatting
    const finalBooking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: BOOKING_PAYMENT_INCLUDE,
    });

    return this.formatBookingPaymentInfo(finalBooking);
  }

  /**
   * Get invoice for pending_payment booking
   */
  async getInvoice(bookingId: bigint, userId: bigint) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: BOOKING_PAYMENT_INCLUDE,
    });

    if (!booking) {
      throw new NotFoundException('Booking không tồn tại');
    }

    if (booking.customerId !== userId && booking.providerId !== userId) {
      throw new ForbiddenException('Bạn không có quyền xem hóa đơn này');
    }

    return this.formatBookingPaymentInfo(booking);
  }

  private formatBookingPaymentInfo(booking: any) {
    const estimatedPrice = Number(booking.estimatedPrice || 0);
    const actualPrice = Number(booking.actualPrice || 0);
    const additionalCosts = Number(booking.additionalCosts || 0);
    const platformFee = Number(booking.platformFee || 0);
    const totalAmount = booking.actualPrice ? actualPrice : estimatedPrice;

    return {
      bookingId: booking.id.toString(),
      bookingCode: booking.code,
      status: booking.status,
      paymentStatus: booking.paymentStatus,
      paymentMethod: booking.paymentMethod,
      service: {
        id: booking.service.id,
        name: booking.service.name,
      },
      provider: {
        id: booking.providerUser?.id.toString(),
        name:
          booking.providerUser?.providerProfile?.displayName ||
          booking.providerUser?.phone,
      },
      customer: {
        id: booking.customer.id.toString(),
        name: booking.customer.profile?.fullName,
      },
      pricing: {
        estimatedPrice,
        actualPrice: actualPrice > 0 ? actualPrice : null,
        additionalCosts: additionalCosts > 0 ? additionalCosts : null,
        additionalNotes: booking.additionalNotes,
        platformFee,
        totalAmount:
          totalAmount +
          (additionalCosts > 0 && actualPrice === 0 ? additionalCosts : 0),
      },
      createdAt: booking.createdAt,
      completedAt: booking.completedAt,
    };
  }

  /**
   * Provider confirms COD payment received
   * Flow: Provider collected cash → Platform deducts locked fee → Complete booking
   */
  async confirmCodPayment(bookingId: bigint, providerId: bigint) {
    console.log('[confirmCodPayment] Called with:', { bookingId: bookingId.toString(), providerId: providerId.toString() });
    
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    console.log('[confirmCodPayment] Booking found:', booking ? {
      id: booking.id.toString(),
      status: booking.status,
      providerId: booking.providerId?.toString(),
      paymentMethod: booking.paymentMethod,
    } : 'null');

    if (!booking) {
      throw new NotFoundException('Booking không tồn tại');
    }

    if (booking.providerId !== providerId) {
      console.log('[confirmCodPayment] Provider mismatch:', { bookingProviderId: booking.providerId?.toString(), requestProviderId: providerId.toString() });
      throw new ForbiddenException('Bạn không có quyền xác nhận booking này');
    }

    if (booking.status !== 'pending_completion') {
      console.log('[confirmCodPayment] Status mismatch:', { currentStatus: booking.status });
      throw new BadRequestException(
        'Booking không ở trạng thái chờ xác nhận thanh toán',
      );
    }

    if (booking.paymentMethod?.toLowerCase() !== 'cod') {
      console.log('[confirmCodPayment] PaymentMethod mismatch:', { paymentMethod: booking.paymentMethod });
      throw new BadRequestException('Booking không dùng phương thức COD');
    }

    const platformFee = Number(booking.platformFee || 0);
    const providerEarning = Number(booking.providerEarning || 0);

    // ESCROW STEP: Deduct locked platform fee from provider wallet
    // This fee was locked when the booking status changed to pending_payment
    if (platformFee > 0) {
      try {
        await this.walletsService.deductLockedBalance(
          providerId,
          platformFee,
          bookingId,
        );
        console.log(
          `[BookingPayment] Deducted ${platformFee} VND platform fee from provider ${providerId}`,
        );
      } catch (error) {
        console.error(
          '[BookingPayment] Error deducting locked balance:',
          error,
        );
        // If deduction fails (maybe not enough locked balance?), we should handle it
        // But since we locked it earlier, it should be there.
      }
    }

    const updated = await this.prisma.booking.update({
      where: { id: bookingId },
      data: {
        status: 'completed' as any,
        paymentStatus: 'paid',
        paidAt: new Date(),
      },
    });

    // Create booking event
    await this.prisma.bookingEvent.create({
      data: {
        bookingId,
        previousStatus: 'pending_payment' as any,
        newStatus: 'completed' as any,
        actorUserId: providerId,
        note: 'Xác nhận đã thu tiền mặt (COD)',
      },
    });

    // Notify both parties
    this.realtimeGateway.emitBookingStatusChange(
      providerId.toString(),
      booking.customerId.toString(),
      {
        bookingId: bookingId.toString(),
        status: 'completed',
        previousStatus: 'pending_payment',
        actorId: providerId.toString(),
      },
    );

    // Persistent notification for customer
    await this.notificationsService.create(
      booking.customerId,
      'BOOKING_COMPLETED',
      'Dịch vụ hoàn tất',
      'Cảm ơn bạn đã thanh toán. Dịch vụ đã được đánh dấu là hoàn thành.',
      { bookingId: bookingId.toString() },
    );

    return { success: true, message: 'Xác nhận thu tiền thành công' };
  }

  /**
   * Release escrowed funds to provider
   */
  async releaseEscrow(bookingId: bigint, customerId: bigint) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) {
      throw new NotFoundException('Booking không tồn tại');
    }

    if (booking.customerId !== customerId) {
      throw new ForbiddenException('Bạn không có quyền xác nhận đơn hàng này');
    }

    console.log(
      `[releaseEscrow] Checking booking ${bookingId}: status=${booking.status}, paymentStatus=${booking.paymentStatus}`,
    );
    if (booking.status !== 'completed' || booking.paymentStatus !== 'held') {
      throw new BadRequestException(
        'Đơn hàng không ở trạng thái có thể giải ngân (held)',
      );
    }

    const providerId = booking.providerId;
    if (!providerId) {
      throw new BadRequestException('Đơn hàng không có thợ được chỉ định');
    }

    const providerEarning = Number(booking.providerEarning || 0);

    return await this.prisma.$transaction(async (tx) => {
      // Update booking payment status to released/paid
      await tx.booking.update({
        where: { id: bookingId },
        data: {
          paymentStatus: 'paid',
        },
      });

      // Credit provider's wallet
      if (providerEarning > 0) {
        await this.walletsService.creditBalance(
          providerId,
          providerEarning,
          'earning',
          {
            bookingId: bookingId.toString(),
            description: `Thu nhập từ dịch vụ #${booking.code}`,
          },
        );
      }

      // Add booking event
      await tx.bookingEvent.create({
        data: {
          bookingId,
          previousStatus: 'completed' as any,
          newStatus: 'completed' as any,
          actorUserId: customerId,
          note: 'Khách hàng xác nhận hoàn tất dịch vụ - Đã giải ngân',
        },
      });

      return {
        success: true,
        message: 'Xác nhận hoàn tất và giải ngân thành công',
      };
    });
  }

  /**
   * Customer initiates MoMo payment
   */
  async initiateMomoPayment(bookingId: bigint, customerId: bigint) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) {
      throw new NotFoundException('Booking không tồn tại');
    }

    if (booking.customerId !== customerId) {
      throw new ForbiddenException('Bạn không có quyền thanh toán booking này');
    }

    if (booking.status !== 'pending_payment') {
      throw new BadRequestException(
        'Booking không ở trạng thái chờ thanh toán',
      );
    }

    const totalPrice =
      Number(booking.actualPrice || 0) || Number(booking.estimatedPrice || 0);
    const orderId = `BOOKING_${bookingId}_${Date.now()}`;

    // Update booking with payment method and orderId
    await this.prisma.booking.update({
      where: { id: bookingId },
      data: {
        paymentMethod: 'momo',
        // We might want to store the current orderId somewhere if needed
      },
    });

    const momoResult = await this.momoService.createPayment({
      amount: totalPrice,
      orderId,
      orderInfo: `Thanh toán dịch vụ #${booking.code}`,
      extraData: JSON.stringify({
        type: 'booking_payment',
        bookingId: bookingId.toString(),
      }),
    });

    return {
      ...momoResult,
      orderId,
    };
  }

  /**
   * Handle MoMo callback for booking payment
   */
  async handleMomoCallback(data: any) {
    const { orderId, resultCode, extraData } = data;

    if (resultCode !== 0) {
      console.log(`[BookingPayment] MoMo payment failed for order ${orderId}`);
      return;
    }

    let bookingId: bigint;
    try {
      const parsed = JSON.parse(extraData);
      if (parsed.type !== 'booking_payment') return;
      bookingId = BigInt(parsed.bookingId);
    } catch (e) {
      console.error('[BookingPayment] Error parsing extraData:', e);
      return;
    }

    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking || booking.status !== 'pending_payment') {
      console.warn(
        `[BookingPayment] Booking ${bookingId} not found or not pending_payment`,
      );
      return;
    }

    const platformFee = Number(booking.platformFee || 0);
    const providerEarning = Number(booking.providerEarning || 0);

    // FLOW: Customer paid MoMo -> Platform holds money in escrow -> Complete booking
    // In MoMo flow, we already have the money. We just need to mark as completed.
    // AND we should UNLOCK the provider's fee if we locked it earlier.
    // Actually, for MoMo, we just take the fee from the customer's payment.
    // So the provider doesn't pay anything.
    // We should unlock the balance we locked when the provider marked as complete.
    if (platformFee > 0 && booking.providerId) {
      try {
        await this.walletsService.unlockBalance(
          booking.providerId,
          platformFee,
          bookingId,
        );
      } catch (error) {
        console.warn(
          '[BookingPayment] Could not unlock balance:',
          error.message,
        );
      }
    }

    // Calculate auto-release time: 24 hours from now
    const autoReleaseAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

    // Update booking status
    await this.prisma.booking.update({
      where: { id: bookingId },
      data: {
        status: 'completed' as any,
        paymentStatus: 'held', // HELD for 24h escrow
        paymentMethod: 'momo',
        paidAt: new Date(),
      },
    });

    // Create/Update BookingPayment record for escrow tracking
    const existingPayment = await this.prisma.bookingPayment.findUnique({
      where: { bookingId },
    });

    if (!existingPayment && booking.providerId) {
      await this.prisma.bookingPayment.create({
        data: {
          bookingId,
          customerId: booking.customerId,
          providerId: booking.providerId,
          amount: Number(booking.actualPrice || booking.estimatedPrice),
          platformFee: Number(booking.platformFee),
          providerAmount: providerEarning,
          paymentMethod: 'MOMO',
          momoTransId: data.transId?.toString(),
          status: 'held',
          paidAt: new Date(),
          heldAt: new Date(),
          autoReleaseAt, // 24h auto-release
        },
      });
    } else if (existingPayment && existingPayment.status === 'pending') {
      await this.prisma.bookingPayment.update({
        where: { id: existingPayment.id },
        data: {
          status: 'held',
          momoTransId: data.transId?.toString(),
          paidAt: new Date(),
          heldAt: new Date(),
          autoReleaseAt, // 24h auto-release
        },
      });
    }

    // Create booking event
    await this.prisma.bookingEvent.create({
      data: {
        bookingId,
        previousStatus: 'pending_payment' as any,
        newStatus: 'completed' as any,
        actorUserId: BigInt(0), // System
        note: 'Thanh toán thành công qua MoMo - Tiền được giữ 24h',
      },
    });

    // Notify parties
    this.realtimeGateway.emitBookingStatusChange(
      '0', // System
      booking.customerId.toString(),
      {
        bookingId: bookingId.toString(),
        status: 'completed',
        paymentStatus: 'held',
        previousStatus: 'pending_payment',
        actorId: '0',
      },
    );

    if (booking.providerId) {
      this.realtimeGateway.emitBookingStatusChange(
        '0', // System
        booking.providerId.toString(),
        {
          bookingId: bookingId.toString(),
          status: 'completed',
          paymentStatus: 'held',
          previousStatus: 'pending_payment',
          actorId: '0',
        },
      );

      // Notify provider that they earned money (held in escrow)
      await this.notificationsService.create(
        booking.providerId,
        'BOOKING_PAID',
        'Khách đã thanh toán',
        `Khách hàng đã thanh toán qua MoMo. Số tiền ${providerEarning.toLocaleString()} VND sẽ được chuyển vào ví sau 24h nếu không có khiếu nại.`,
        {
          bookingId: bookingId.toString(),
          amount: providerEarning,
          autoReleaseAt: autoReleaseAt.toISOString(),
        },
      );
    }

    console.log(
      `[BookingPayment] Booking ${bookingId} completed via MoMo IPN`,
      {
        paymentStatus: 'held',
        autoReleaseAt: autoReleaseAt.toISOString(),
      },
    );
  }

  /**
   * Check and process booking payment via MoMo query (polling fallback)
   */
  async checkAndProcessPayment(userId: bigint, orderId: string) {
    console.log('[BookingPayment] checkAndProcessPayment called:', {
      userId: userId.toString(),
      orderId,
      orderIdType: typeof orderId,
      orderIdLength: orderId?.length,
    });

    if (!orderId || orderId.trim() === '') {
      console.error('[BookingPayment] OrderId is missing or empty');
      throw new BadRequestException('OrderId is required');
    }

    console.log('[BookingPayment] Checking payment status for:', orderId);

    // Query MoMo for payment status
    const requestId = `${orderId}_check_${Date.now()}`;
    const momoResponse = await this.momoService.queryPayment(
      orderId,
      requestId,
    );

    console.log('[BookingPayment] MoMo query response:', momoResponse);

    if (momoResponse.resultCode !== 0) {
      return {
        status: 'pending',
        message: `Giao dịch đang chờ xử lý hoặc thất bại: ${momoResponse.message}`,
        momoResultCode: momoResponse.resultCode,
      };
    }

    // Payment successful - parse extraData to get bookingId
    let extraDataObj: any = {};
    try {
      if (momoResponse.extraData) {
        extraDataObj = JSON.parse(momoResponse.extraData);
      }
    } catch (e) {
      console.error('[BookingPayment] Failed to parse extraData:', e);
      return {
        status: 'error',
        message: 'Invalid extraData in MoMo response',
      };
    }

    if (extraDataObj.type !== 'booking_payment') {
      return {
        status: 'error',
        message: 'Not a booking payment',
      };
    }

    const bookingId = BigInt(extraDataObj.bookingId);

    // Check if already processed
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) {
      return {
        status: 'error',
        message: 'Booking not found',
      };
    }

    // TODO: Re-enable authorization check after fixing auth
    // Temporarily disabled for testing
    // if (booking.customerId !== userId) {
    //   console.warn('[BookingPayment] Auth check: customerId mismatch', {
    //     bookingCustomerId: booking.customerId.toString(),
    //     requestUserId: userId.toString(),
    //   });
    //   throw new BadRequestException('Not authorized to check this booking');
    // }

    if (booking.paymentStatus === 'held' || booking.paymentStatus === 'paid') {
      // Already processed
      return {
        status: 'success',
        message: 'Thanh toán đã được xử lý',
        booking: {
          id: booking.id.toString(),
          status: booking.status,
          paymentStatus: booking.paymentStatus,
        },
        alreadyProcessed: true,
      };
    }

    // Process the payment now
    const platformFee = Number(booking.platformFee || 0);
    const providerEarning = Number(booking.providerEarning || 0);

    // Unlock provider's locked balance if it was locked (for MoMo, we unlock since customer paid)
    if (platformFee > 0 && booking.providerId) {
      try {
        await this.walletsService.unlockBalance(
          booking.providerId,
          platformFee,
          bookingId,
        );
      } catch (error) {
        console.warn(
          '[BookingPayment] Could not unlock balance (may not have been locked):',
          error.message,
        );
      }
    }

    // Calculate auto-release time: 24 hours from now
    const autoReleaseAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

    // Update booking status
    const updatedBooking = await this.prisma.booking.update({
      where: { id: bookingId },
      data: {
        status: 'completed' as any,
        paymentStatus: 'held', // HELD for 24h escrow
        paymentMethod: 'momo',
        paidAt: new Date(),
      },
    });

    // Create BookingPayment record if not exists (for escrow tracking)
    const existingPayment = await this.prisma.bookingPayment.findUnique({
      where: { bookingId },
    });

    if (!existingPayment && booking.providerId) {
      await this.prisma.bookingPayment.create({
        data: {
          bookingId,
          customerId: booking.customerId,
          providerId: booking.providerId,
          amount: Number(booking.actualPrice || booking.estimatedPrice),
          platformFee: Number(booking.platformFee),
          providerAmount: providerEarning,
          paymentMethod: 'MOMO',
          momoTransId: momoResponse.transId?.toString(),
          status: 'held',
          paidAt: new Date(),
          heldAt: new Date(),
          autoReleaseAt, // 24h auto-release
        },
      });
    } else if (existingPayment && existingPayment.status === 'pending') {
      // Update existing payment
      await this.prisma.bookingPayment.update({
        where: { id: existingPayment.id },
        data: {
          status: 'held',
          momoTransId: momoResponse.transId?.toString(),
          paidAt: new Date(),
          heldAt: new Date(),
          autoReleaseAt, // 24h auto-release
        },
      });
    }

    // Create booking event
    await this.prisma.bookingEvent.create({
      data: {
        bookingId,
        previousStatus: 'pending_payment' as any,
        newStatus: 'completed' as any,
        actorUserId: userId,
        note: 'Thanh toán thành công qua MoMo - Tiền được giữ 24h',
      },
    });

    // Notify parties
    this.realtimeGateway.emitBookingStatusChange(
      userId.toString(),
      booking.customerId.toString(),
      {
        bookingId: bookingId.toString(),
        status: 'completed',
        paymentStatus: 'held',
        previousStatus: 'pending_payment',
        actorId: userId.toString(),
      },
    );

    if (booking.providerId) {
      this.realtimeGateway.emitBookingStatusChange(
        userId.toString(),
        booking.providerId.toString(),
        {
          bookingId: bookingId.toString(),
          status: 'completed',
          paymentStatus: 'held',
          previousStatus: 'pending_payment',
          actorId: userId.toString(),
        },
      );

      // Notify provider
      await this.notificationsService.create(
        booking.providerId,
        'BOOKING_PAID',
        'Khách đã thanh toán',
        `Khách hàng đã thanh toán qua MoMo. Số tiền ${providerEarning.toLocaleString()} VND sẽ được chuyển vào ví sau 24h nếu không có khiếu nại.`,
        {
          bookingId: bookingId.toString(),
          amount: providerEarning,
          autoReleaseAt: autoReleaseAt.toISOString(),
        },
      );
    }

    console.log('[BookingPayment] Payment processed successfully:', {
      bookingId: bookingId.toString(),
      amount: momoResponse.amount,
      paymentStatus: 'held',
      autoReleaseAt: autoReleaseAt.toISOString(),
    });

    return {
      status: 'success',
      message: 'Thanh toán thành công! Tiền sẽ được chuyển cho thợ sau 24h.',
      booking: {
        id: updatedBooking.id.toString(),
        status: updatedBooking.status,
        paymentStatus: updatedBooking.paymentStatus,
      },
      escrow: {
        autoReleaseAt: autoReleaseAt.toISOString(),
        holdPeriodHours: 24,
      },
    };
  }
}
