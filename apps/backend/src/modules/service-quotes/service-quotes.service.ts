import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import {
  CreateServiceQuoteDto,
  AcceptQuoteDto,
  RejectQuoteDto,
} from './dto/service-quote.dto';
import { QuoteStatus, BookingStatus } from '@prisma/client';

import { ChatGateway } from '../conversations/chat.gateway';

@Injectable()
export class ServiceQuotesService {
  constructor(
    private prisma: PrismaService,
    private chatGateway: ChatGateway,
  ) {}

  // Platform fee percentage
  private readonly PLATFORM_FEE_RATE = 0.1; // 10%

  /**
   * Provider creates a quote for a booking after inspection
   */
  async createQuote(
    bookingId: bigint,
    providerId: bigint,
    dto: CreateServiceQuoteDto,
  ) {
    // Verify booking exists and belongs to this provider
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: {
        customer: {
          include: { profile: true },
        },
        service: true,
        selectedItems: true, // Get customer's pre-selected items
      },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    if (booking.providerId !== providerId) {
      throw new ForbiddenException('You are not the provider for this booking');
    }

    // Only allow quotes for accepted or in_progress bookings
    if (!['accepted', 'in_progress'].includes(booking.status)) {
      throw new BadRequestException(
        `Cannot create quote for booking with status: ${booking.status}`,
      );
    }

    // Check if quote differs from customer selection
    const customerSelectedIds =
      booking.selectedItems?.map((i) => i.providerServiceItemId.toString()) ||
      [];
    const quoteItemIds = dto.items
      .filter((i) => i.serviceItemId)
      .map((i) => i.serviceItemId);

    // Detect changes: provider added items not in customer selection or removed customer items
    const hasChangesFromCustomer =
      customerSelectedIds.length > 0 &&
      (dto.items.some(
        (i) => !customerSelectedIds.includes(i.serviceItemId || ''),
      ) ||
        customerSelectedIds.some((id) => !quoteItemIds.includes(id)));

    // Calculate costs
    const partsCost = dto.items.reduce(
      (sum, item) => sum + item.price * item.quantity,
      0,
    );
    const surcharge = dto.surcharge || 0;
    const totalCost = partsCost + dto.laborCost + surcharge;
    const platformFee = Math.round(totalCost * this.PLATFORM_FEE_RATE);
    const finalPrice = totalCost + platformFee;

    // Create quote with 24h expiry
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

    const quote = await this.prisma.serviceQuote.create({
      data: {
        bookingId,
        providerId,
        diagnosis: dto.diagnosis,
        items: dto.items as any, // Legacy JSON field
        laborCost: dto.laborCost,
        partsCost,
        surcharge,
        totalCost,
        platformFee,
        finalPrice,
        warranty: dto.warranty,
        estimatedTime: dto.estimatedTime,
        images: dto.images || [],
        notes: dto.notes,
        providerNotes: dto.providerNotes,
        hasChangesFromCustomer,
        status: QuoteStatus.pending,
        expiresAt,
        // Create structured quote items
        quoteItems: {
          create: dto.items.map((item) => ({
            serviceItemId: item.serviceItemId
              ? BigInt(item.serviceItemId)
              : null,
            name: item.name,
            description: item.description,
            unitPrice: item.price,
            quantity: item.quantity,
            totalPrice: item.price * item.quantity,
            isCustom: item.isCustom || !item.serviceItemId,
            isFromCustomerSelection: item.isFromCustomerSelection || false,
          })),
        },
      },
      include: {
        provider: {
          select: {
            id: true,
            phone: true,
            profile: { select: { fullName: true, avatarUrl: true } },
          },
        },
        quoteItems: true,
      },
    });

    // Send notification to customer about new quote
    this.chatGateway.notifyUser(
      booking.customerId.toString(),
      'booking.quote_received',
      {
        bookingId: booking.id.toString(),
        quoteId: quote.id.toString(),
        serviceName: booking.service?.name,
        finalPrice: finalPrice,
        providerName: quote.provider?.profile?.fullName,
      },
    );

    // Notify admin if provider changed from customer selection
    if (hasChangesFromCustomer) {
      console.log(
        `[Quote] Provider ${providerId} changed quote from customer selection for booking ${bookingId}`,
      );
      // TODO: Send notification to admin via admin notification channel
      this.chatGateway.notifyUser(
        'admin', // Admin channel
        'booking.quote_changed',
        {
          bookingId: booking.id.toString(),
          quoteId: quote.id.toString(),
          providerNotes: dto.providerNotes,
          customerSelectedCount: customerSelectedIds.length,
          quoteItemsCount: dto.items.length,
        },
      );
    }

    return {
      ...this.serializeQuote(quote),
      hasChangesFromCustomer,
      message: 'Báo giá đã được gửi cho khách hàng',
    };
  }

  /**
   * Get quotes for a booking
   */
  async getQuotesForBooking(bookingId: bigint, userId: bigint) {
    console.log(
      `[Quote] getQuotesForBooking: bookingId=${bookingId}, userId=${userId}`,
    );

    // Verify user has access to this booking
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) {
      console.log(`[Quote] Booking not found: ${bookingId}`);
      throw new NotFoundException('Booking not found');
    }

    console.log(
      `[Quote] Booking found: customerId=${booking.customerId}, providerId=${booking.providerId}`,
    );

    if (booking.customerId !== userId && booking.providerId !== userId) {
      console.log(`[Quote] Access denied for user ${userId}`);
      throw new ForbiddenException('You do not have access to this booking');
    }

    const quotes = await this.prisma.serviceQuote.findMany({
      where: { bookingId },
      include: {
        provider: {
          select: {
            id: true,
            phone: true,
            profile: { select: { fullName: true, avatarUrl: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    console.log(
      `[Quote] Found ${quotes.length} quotes for booking ${bookingId}`,
    );

    return quotes.map(this.serializeQuote);
  }

  /**
   * Customer accepts a quote
   */
  async acceptQuote(quoteId: bigint, customerId: bigint, dto?: AcceptQuoteDto) {
    const quote = await this.prisma.serviceQuote.findUnique({
      where: { id: quoteId },
      include: {
        booking: {
          include: { service: true },
        },
        provider: {
          select: { id: true, profile: { select: { fullName: true } } },
        },
      },
    });

    if (!quote) {
      throw new NotFoundException('Quote not found');
    }

    if (quote.booking.customerId !== customerId) {
      throw new ForbiddenException('Only the customer can accept this quote');
    }

    if (quote.status !== QuoteStatus.pending) {
      throw new BadRequestException(`Quote is already ${quote.status}`);
    }

    if (new Date() > quote.expiresAt) {
      throw new BadRequestException('Quote has expired');
    }

    // Update quote status and booking with actual price from quote
    const [updatedQuote] = await this.prisma.$transaction([
      this.prisma.serviceQuote.update({
        where: { id: quoteId },
        data: {
          status: QuoteStatus.accepted,
          acceptedAt: new Date(),
        },
      }),
      this.prisma.booking.update({
        where: { id: quote.bookingId },
        data: {
          status: BookingStatus.in_progress,
          estimatedPrice: quote.finalPrice,
          actualPrice: quote.finalPrice, // Set actual price from accepted quote
          additionalNotes: dto?.customerNote
            ? `Khách hàng: ${dto.customerNote}`
            : undefined,
        },
      }),
      // Reject other pending quotes for this booking
      this.prisma.serviceQuote.updateMany({
        where: {
          bookingId: quote.bookingId,
          id: { not: quoteId },
          status: QuoteStatus.pending,
        },
        data: { status: QuoteStatus.rejected },
      }),
    ]);

    // Notify provider that quote was accepted
    this.chatGateway.notifyUser(
      quote.providerId.toString(),
      'booking.quote_accepted',
      {
        bookingId: quote.bookingId.toString(),
        quoteId: quoteId.toString(),
        serviceName: quote.booking.service?.name,
        finalPrice: quote.finalPrice.toString(),
        message:
          'Khách hàng đã chấp nhận báo giá. Bạn có thể thực hiện dịch vụ.',
      },
    );

    console.log(
      `[Quote] Customer ${customerId} accepted quote ${quoteId}, price: ${quote.finalPrice}`,
    );

    return {
      ...this.serializeQuote(updatedQuote),
      message: 'Đã chấp nhận báo giá. Thợ sẽ tiến hành thực hiện dịch vụ.',
    };
  }

  /**
   * Customer rejects a quote
   */
  async rejectQuote(quoteId: bigint, customerId: bigint, dto: RejectQuoteDto) {
    const quote = await this.prisma.serviceQuote.findUnique({
      where: { id: quoteId },
      include: {
        booking: {
          include: { service: true },
        },
      },
    });

    if (!quote) {
      throw new NotFoundException('Quote not found');
    }

    if (quote.booking.customerId !== customerId) {
      throw new ForbiddenException('Only the customer can reject this quote');
    }

    if (quote.status !== QuoteStatus.pending) {
      throw new BadRequestException(`Quote is already ${quote.status}`);
    }

    // Update quote and booking status
    const [updatedQuote] = await this.prisma.$transaction([
      this.prisma.serviceQuote.update({
        where: { id: quoteId },
        data: {
          status: QuoteStatus.rejected,
          notes: quote.notes
            ? `${quote.notes}\n---\nLý do từ chối: ${dto.reason}`
            : `Lý do từ chối: ${dto.reason}`,
        },
      }),
      // Change booking status to disputed/quote_rejected
      this.prisma.booking.update({
        where: { id: quote.bookingId },
        data: {
          status: 'disputed', // Using disputed as quote_rejected state
          additionalNotes: `Báo giá bị từ chối: ${dto.reason}`,
        },
      }),
    ]);

    // Notify provider about rejection
    this.chatGateway.notifyUser(
      quote.providerId.toString(),
      'booking.quote_rejected',
      {
        bookingId: quote.bookingId.toString(),
        quoteId: quoteId.toString(),
        serviceName: quote.booking.service?.name,
        reason: dto.reason,
        message:
          'Khách hàng đã từ chối báo giá. Vui lòng xem xét hoặc đồng ý hủy.',
      },
    );

    // Notify admin for dispute resolution
    this.chatGateway.notifyUser('admin', 'booking.quote_disputed', {
      bookingId: quote.bookingId.toString(),
      quoteId: quoteId.toString(),
      providerId: quote.providerId.toString(),
      customerId: customerId.toString(),
      reason: dto.reason,
      message: 'Khách hàng từ chối báo giá, cần xem xét.',
    });

    console.log(
      `[Quote] Customer ${customerId} rejected quote ${quoteId}, reason: ${dto.reason}`,
    );

    return {
      ...this.serializeQuote(updatedQuote),
      message:
        'Đã từ chối báo giá. Admin sẽ xem xét hoặc thợ có thể đồng ý hủy.',
    };
  }

  /**
   * Provider agrees to customer rejection - cancels the booking
   */
  async providerAgreeReject(quoteId: bigint, providerId: bigint) {
    const quote = await this.prisma.serviceQuote.findUnique({
      where: { id: quoteId },
      include: {
        booking: {
          include: { service: true },
        },
      },
    });

    if (!quote) {
      throw new NotFoundException('Quote not found');
    }

    if (quote.providerId !== providerId) {
      throw new ForbiddenException('Only the provider can agree to rejection');
    }

    if (quote.status !== QuoteStatus.rejected) {
      throw new BadRequestException('Quote is not rejected');
    }

    // Cancel the booking
    await this.prisma.booking.update({
      where: { id: quote.bookingId },
      data: {
        status: BookingStatus.cancelled,
        additionalNotes: 'Thợ đồng ý hủy sau khi báo giá bị từ chối',
      },
    });

    // Notify customer
    this.chatGateway.notifyUser(
      quote.booking.customerId.toString(),
      'booking.cancelled',
      {
        bookingId: quote.bookingId.toString(),
        serviceName: quote.booking.service?.name,
        message: 'Đơn hàng đã được hủy do thợ đồng ý với từ chối báo giá.',
      },
    );

    console.log(
      `[Quote] Provider ${providerId} agreed to reject quote ${quoteId}, booking cancelled`,
    );

    return {
      message: 'Đã đồng ý hủy. Đơn hàng đã được hủy bỏ.',
      bookingId: quote.bookingId.toString(),
    };
  }

  /**
   * Get quote by ID
   */
  async getQuoteById(quoteId: bigint, userId: bigint) {
    const quote = await this.prisma.serviceQuote.findUnique({
      where: { id: quoteId },
      include: {
        booking: {
          include: {
            customer: {
              select: {
                id: true,
                phone: true,
                profile: { select: { fullName: true } },
              },
            },
            service: { select: { id: true, name: true } },
          },
        },
        provider: {
          select: {
            id: true,
            phone: true,
            profile: { select: { fullName: true, avatarUrl: true } },
          },
        },
      },
    });

    if (!quote) {
      throw new NotFoundException('Quote not found');
    }

    // Check access
    if (quote.booking.customerId !== userId && quote.providerId !== userId) {
      throw new ForbiddenException('You do not have access to this quote');
    }

    return this.serializeQuote(quote);
  }

  /**
   * Serialize quote for API response
   */
  private serializeQuote(quote: any) {
    return {
      id: quote.id.toString(),
      bookingId: quote.bookingId.toString(),
      providerId: quote.providerId.toString(),
      diagnosis: quote.diagnosis,
      items: quote.items,
      laborCost: Number(quote.laborCost),
      partsCost: Number(quote.partsCost),
      totalCost: Number(quote.totalCost),
      platformFee: Number(quote.platformFee),
      finalPrice: Number(quote.finalPrice),
      warranty: quote.warranty,
      estimatedTime: quote.estimatedTime,
      images: quote.images,
      notes: quote.notes,
      status: quote.status,
      createdAt: quote.createdAt,
      expiresAt: quote.expiresAt,
      acceptedAt: quote.acceptedAt,
      provider: quote.provider
        ? {
            id: quote.provider.id.toString(),
            phone: quote.provider.phone,
            fullName: quote.provider.profile?.fullName,
            avatarUrl: quote.provider.profile?.avatarUrl,
          }
        : undefined,
      booking: quote.booking
        ? {
            id: quote.booking.id.toString(),
            customerName: quote.booking.customer?.profile?.fullName,
            serviceName: quote.booking.service?.name,
          }
        : undefined,
    };
  }
}
