import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { BookingPaymentService } from '../payment/booking-payment.service';
import {
  RealtimeGateway,
  SocketEvents,
  BookingStatusPayload,
  NewJobPayload,
} from '../gateway/realtime.gateway';
import {
  EstimateDto,
  CreateBookingDto,
  CancelBookingDto,
  ReviewBookingDto,
  BookingQueryDto,
} from './dto/bookings.dto';

@Injectable()
export class BookingsService {
  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
    private realtimeGateway: RealtimeGateway,
    private bookingPaymentService: BookingPaymentService,
  ) {}

  // POST /bookings/estimate
  async estimateBooking(dto: EstimateDto) {
    const service = await this.prisma.service.findUnique({
      where: { id: dto.serviceId },
    });

    if (!service) {
      throw new NotFoundException('Service not found');
    }

    // Find nearest provider
    let provider = null;
    if (dto.latitude && dto.longitude) {
      provider = await this.findNearestProvider(
        dto.serviceId,
        dto.latitude,
        dto.longitude,
      );
    }

    const basePrice = Number(service.basePrice);
    const platformFee = basePrice * 0.1; // 10% platform fee
    const totalAmount = basePrice + platformFee;

    return {
      serviceId: dto.serviceId,
      serviceName: service.name,
      basePrice: basePrice.toString(),
      platformFee: platformFee.toString(),
      totalAmount: totalAmount.toString(),
      estimatedDuration: service.durationMinutes,
      provider: provider
        ? {
            id: (provider as any).user_id.toString(),
            displayName: (provider as any).display_name,
            ratingAvg: (provider as any).rating_avg?.toString() || '0',
          }
        : null,
    };
  }

  // POST /bookings
  async createBooking(customerId: bigint, dto: CreateBookingDto) {
    return await this.prisma.$transaction(async (tx) => {
      // Get service
      const service = await tx.service.findUnique({
        where: { id: dto.serviceId },
      });

      if (!service) {
        throw new NotFoundException('Service not found');
      }

      // 1. Create Booking
      // If providerId is specified, this is a Direct Booking (assigned to specific provider)
      // Otherwise, it's a General Booking (providers in that category will see it)
      const code = `BK${Date.now()}`;
      const isDirectBooking = dto.providerId != null;

      // If direct booking without selectedItems → price = 0 (will be quoted by provider)
      // If direct booking with selectedItems → price calculated from items
      // If general booking → use service basePrice as estimate
      const hasSelectedItems =
        dto.selectedItems && dto.selectedItems.length > 0;
      const basePrice =
        isDirectBooking && !hasSelectedItems
          ? 0 // Let provider quote
          : Number(service.basePrice); // Initial estimate

      // Debug logging
      console.log('[createBooking] DTO received:', {
        serviceId: dto.serviceId,
        providerId: dto.providerId,
        isDirectBooking,
        addressText: dto.addressText,
        latitude: dto.latitude,
        longitude: dto.longitude,
      });

      // VALIDATION 1: Prevent self-booking (provider cannot book their own service)
      if (isDirectBooking && BigInt(dto.providerId!) === customerId) {
        throw new BadRequestException(
          'Bạn không thể đặt dịch vụ của chính mình',
        );
      }

      // Also check if customer is the owner of the service they're trying to book
      const serviceProvider = await tx.providerService.findFirst({
        where: {
          serviceId: dto.serviceId,
          providerUserId: customerId,
          isActive: true,
        },
      });
      if (serviceProvider) {
        throw new BadRequestException(
          'Bạn không thể đặt dịch vụ của chính mình',
        );
      }

      // VALIDATION 2: Prevent duplicate booking
      // Rule 1: Cannot book same service with same provider again (any time)
      // Rule 2: Cannot book different service with same provider at same time (within 2 hours)
      const scheduledTime = new Date(dto.scheduledAt);
      const twoHoursBefore = new Date(
        scheduledTime.getTime() - 2 * 60 * 60 * 1000,
      );
      const twoHoursAfter = new Date(
        scheduledTime.getTime() + 2 * 60 * 60 * 1000,
      );

      // Rule 1: Check if same service + same provider already exists
      if (isDirectBooking) {
        const sameServiceBooking = await tx.booking.findFirst({
          where: {
            customerId: customerId,
            serviceId: dto.serviceId,
            providerId: BigInt(dto.providerId!),
            status: { in: ['pending', 'accepted', 'in_progress'] },
          },
        });

        if (sameServiceBooking) {
          throw new BadRequestException(
            'Bạn đã đặt dịch vụ này với provider này rồi. Vui lòng chọn dịch vụ khác hoặc provider khác.',
          );
        }

        // Rule 2: Check if different service but same provider + same time
        const sameTimeBooking = await tx.booking.findFirst({
          where: {
            customerId: customerId,
            providerId: BigInt(dto.providerId!),
            status: { in: ['pending', 'accepted', 'in_progress'] },
            scheduledAt: {
              gte: twoHoursBefore,
              lte: twoHoursAfter,
            },
          },
        });

        if (sameTimeBooking) {
          throw new BadRequestException(
            'Bạn đã có lịch đặt với provider này trong khoảng thời gian này. Vui lòng chọn thời gian khác.',
          );
        }
      } else {
        // General booking: just check same service + same time
        const existingBooking = await tx.booking.findFirst({
          where: {
            customerId: customerId,
            serviceId: dto.serviceId,
            status: { in: ['pending', 'accepted', 'in_progress'] },
            scheduledAt: {
              gte: twoHoursBefore,
              lte: twoHoursAfter,
            },
          },
        });

        if (existingBooking) {
          throw new BadRequestException(
            'Bạn đã có lịch đặt dịch vụ này trong khoảng thời gian tương tự. Vui lòng chọn thời gian khác.',
          );
        }
      }

      // Validate provider exists and is active if direct booking
      if (isDirectBooking) {
        console.log(
          '[createBooking] Direct booking - checking provider:',
          dto.providerId,
        );
        const providerExists = await tx.providerProfile.findUnique({
          where: { userId: BigInt(dto.providerId!) },
        });
        console.log('[createBooking] Provider exists:', !!providerExists);
        if (!providerExists) {
          throw new NotFoundException('Selected provider not found');
        }
      }

      const bookingIdResult = await tx.$queryRawUnsafe<any[]>(
        `
        INSERT INTO bookings (
          code, customer_id, service_id, provider_id,
          status, scheduled_at, address_text, location, notes,
          estimated_price, created_at, updated_at
        ) VALUES (
          $1, $2, $3, $4,
          'pending', $5, $6, ST_SetSRID(ST_MakePoint($7, $8), 4326), $9,
          $10, NOW(), NOW()
        ) RETURNING id, code, status, scheduled_at, estimated_price, provider_id
      `,
        code,
        customerId,
        dto.serviceId,
        isDirectBooking ? BigInt(dto.providerId!) : null, // provider_id for direct booking
        new Date(dto.scheduledAt),
        dto.addressText,
        dto.longitude,
        dto.latitude,
        dto.notes || null,
        basePrice,
      );

      const booking = bookingIdResult[0];
      const bookingId = booking.id;

      // 2. Save selected items if provided
      let totalFromItems = 0;
      if (
        dto.selectedItems &&
        dto.selectedItems.length > 0 &&
        isDirectBooking
      ) {
        console.log(
          '[createBooking] Processing selectedItems:',
          dto.selectedItems,
        );

        // Get item prices from provider_service_items
        const itemIds = dto.selectedItems.map((i) => BigInt(i.itemId));
        const items = await tx.providerServiceItem.findMany({
          where: {
            id: { in: itemIds },
            providerUserId: BigInt(dto.providerId!),
            serviceId: dto.serviceId,
            isActive: true,
          },
        });

        // Create BookingSelectedItem records
        for (const selectedItem of dto.selectedItems) {
          const itemData = items.find(
            (i) => i.id.toString() === selectedItem.itemId,
          );
          if (itemData) {
            const quantity = selectedItem.quantity || 1;
            const unitPrice = Number(itemData.price);
            const totalPrice = unitPrice * quantity;
            totalFromItems += totalPrice;

            await tx.bookingSelectedItem.create({
              data: {
                bookingId,
                providerServiceItemId: BigInt(selectedItem.itemId),
                quantity,
                unitPrice,
                totalPrice,
              },
            });
          }
        }

        // Update booking with total from selected items
        if (totalFromItems > 0) {
          await tx.booking.update({
            where: { id: bookingId },
            data: { estimatedPrice: totalFromItems },
          });
        }

        console.log(
          '[createBooking] Saved selectedItems, total:',
          totalFromItems,
        );
      }

      // 3. Determine which providers to notify
      let providerIdsToNotify: string[] = [];

      if (isDirectBooking) {
        // Direct booking: Only notify the chosen provider
        providerIdsToNotify = [dto.providerId!.toString()];

        // Get customer profile for display name
        const customerProfile = await tx.userProfile.findUnique({
          where: { userId: customerId },
        });

        // Emit socket event for real-time notification to the selected provider
        this.realtimeGateway.emitBookingStatusChange(
          customerId.toString(),
          dto.providerId!.toString(),
          {
            bookingId: booking.id.toString(),
            status: 'pending',
            providerId: dto.providerId!.toString(),
            message: `Bạn có một yêu cầu đặt lịch mới từ ${customerProfile?.fullName || 'Khách hàng'}!`,
            customerName: customerProfile?.fullName || 'Khách hàng',
            estimatedPrice: basePrice.toString(),
            serviceName: service.name,
            scheduledAt: new Date(dto.scheduledAt).toISOString(),
            addressText: dto.addressText,
            latitude: dto.latitude,
            longitude: dto.longitude,
            actorId: customerId.toString(),
          },
        );
      } else {
        // General booking: Find nearby providers by category
        const providers = await this.findNearbyProviders(
          dto.serviceId,
          dto.latitude,
          dto.longitude,
          tx,
        );
        providerIdsToNotify = providers.map((p) =>
          (p as any).user_id.toString(),
        );

        // Emit new_job_available to job market for providers
        this.realtimeGateway.emitNewJob(service.categoryId || 0, {
          bookingId: booking.id.toString(),
          serviceId: dto.serviceId,
          serviceName: service.name,
          categoryId: service.categoryId || 0,
          categoryName: '', // Will be enriched on client
          customerName: undefined,
          addressText: dto.addressText,
          latitude: dto.latitude,
          longitude: dto.longitude,
          scheduledAt: new Date(dto.scheduledAt).toISOString(),
          estimatedPrice: booking.estimated_price
            ? Number(booking.estimated_price)
            : undefined,
        });
      }

      // 4. Return booking info with provider IDs for notification
      return {
        id: booking.id.toString(),
        code: booking.code,
        status: booking.status,
        scheduledAt: booking.scheduled_at,
        estimatedPrice:
          totalFromItems > 0
            ? totalFromItems.toString()
            : booking.estimated_price?.toString(),
        providerId: booking.provider_id?.toString() || null,
        isDirectBooking,
        nearbyProviderIds: providerIdsToNotify,
        hasSelectedItems: dto.selectedItems && dto.selectedItems.length > 0,
      };
    });
  }

  // Helper: Find nearby providers (multiple) based on their registered service radius
  private async findNearbyProviders(
    serviceId: number,
    latitude: number,
    longitude: number,
    tx?: any,
  ) {
    const prisma = tx || this.prisma;

    // Use each provider's own service_radius_m for filtering
    return await prisma.$queryRawUnsafe(
      `
      SELECT 
        pp.user_id,
        pp.display_name,
        pp.service_radius_m,
        ST_Distance(
          pp.location::geography,
          ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography
        ) as distance
      FROM provider_profiles pp
      INNER JOIN provider_services ps ON pp.user_id = ps.provider_user_id
      WHERE ps.service_id = $3
        AND ps.is_active = true
        AND ps.deleted_at IS NULL
        AND pp.is_available = true
        AND pp.location IS NOT NULL
        AND ST_DWithin(
          pp.location::geography,
          ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
          COALESCE(pp.service_radius_m, 5000)
        )
      ORDER BY distance ASC
      LIMIT 10
    `,
      longitude,
      latitude,
      serviceId,
    );
  }

  async acceptBookingRequest(providerId: bigint, bookingId: bigint) {
    // Check if booking exists and is pending
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) throw new NotFoundException('Booking not found');
    if (booking.status !== 'pending')
      throw new BadRequestException('Booking is not pending');

    // Check if provider offers this service
    let providerService = await this.prisma.providerService.findUnique({
      where: {
        providerUserId_serviceId: {
          providerUserId: providerId,
          serviceId: booking.serviceId,
        },
      },
      include: {
        provider: true,
      },
    });

    // If provider hasn't registered this exact service yet, check if they work in this CATEGORY
    if (!providerService) {
      console.log(
        `[acceptBookingRequest] Provider ${providerId} doesn't offer service ${booking.serviceId}. Checking category competence...`,
      );

      // Get service and its category
      const targetService = await this.prisma.service.findUnique({
        where: { id: booking.serviceId },
      });

      if (!targetService) {
        throw new NotFoundException('Service not found');
      }

      // Check if provider has ANY service in this category
      const hasCategoryCompetence = await this.prisma.providerService.findFirst(
        {
          where: {
            providerUserId: providerId,
            service: { categoryId: targetService.categoryId },
          },
        },
      );

      if (!hasCategoryCompetence) {
        throw new ForbiddenException(
          'Bạn không có chuyên môn trong danh mục dịch vụ này. Vui lòng cập nhật hồ sơ thợ trước.',
        );
      }

      // Auto-register sub-service since they already do this category
      const offerPrice = booking.estimatedPrice || targetService.basePrice || 0;

      providerService = (await this.prisma.providerService.create({
        data: {
          providerUserId: providerId,
          serviceId: booking.serviceId,
          price: offerPrice,
          isActive: true,
        },
        include: {
          provider: true,
        },
      })) as any;
    }

    // At this point, providerService should exist (either originally or auto-created)
    if (!providerService) {
      throw new ForbiddenException(
        'Không thể xác định dịch vụ của thợ. Vui lòng thử lại.',
      );
    }

    // DIRECT BOOKING: If this booking was specifically assigned to this provider
    // Accept it directly (no offer needed), update status to 'accepted'
    if (booking.providerId === providerId) {
      console.log('[acceptBookingRequest] Direct booking - auto accepting');

      const updated = await this.prisma.booking.update({
        where: { id: bookingId },
        data: {
          status: 'accepted',
          actualPrice: providerService.price,
        },
      });

      // Create booking event
      await this.prisma.bookingEvent.create({
        data: {
          bookingId,
          previousStatus: 'pending',
          newStatus: 'accepted',
          actorUserId: providerId,
          note: 'Provider accepted direct booking',
        },
      });

      return {
        message: 'Đã chấp nhận đặt lịch',
        bookingId: bookingId.toString(),
        status: 'accepted',
        isDirectBooking: true,
      };
    }

    // GENERAL BOOKING: Create offer for customer to choose
    console.log('[acceptBookingRequest] General booking - creating offer');

    // Check if offer already exists to avoid unique constraint error
    const existingOffer = await this.prisma.bookingOffer.findUnique({
      where: {
        bookingId_providerId: {
          bookingId,
          providerId,
        },
      },
    });

    if (existingOffer) {
      return {
        message: 'Bạn đã gửi báo giá cho đơn này rồi',
        offerId: existingOffer.id.toString(),
        bookingId: bookingId.toString(),
        isExisting: true,
      };
    }

    const offerResult = await this.prisma.$queryRawUnsafe<any[]>(
      `
      INSERT INTO booking_offers (booking_id, provider_id, price, status, created_at, updated_at)
      VALUES ($1, $2, $3, 'PENDING', NOW(), NOW())
      RETURNING id
    `,
      bookingId,
      providerId,
      Number(providerService.price),
    );

    // Notify Customer
    const providerName = providerService.provider.displayName || 'Thợ';
    const priceFormatted = Number(providerService.price).toLocaleString(
      'vi-VN',
    );

    // Emit unified socket event for real-time notification
    this.realtimeGateway.emitBookingStatusChange(
      booking.customerId.toString(),
      providerId.toString(),
      {
        bookingId: booking.id.toString(),
        status: 'OFFER_RECEIVED',
        message: `${providerName} vừa gửi báo giá ${priceFormatted}đ cho đơn đặt lịch của bạn.`,
        actorId: providerId.toString(),
        payload: {
          offerId: offerResult[0].id.toString(),
          type: 'booking_offer',
        },
      },
    );

    await this.notificationsService.create(
      booking.customerId,
      'OFFER_RECEIVED',
      'Đã nhận được báo giá mới',
      `${providerName} vừa gửi báo giá ${priceFormatted}đ cho đơn đặt lịch của bạn. Xem ngay!`,
      {
        bookingId: booking.id.toString(),
        offerId: offerResult[0].id.toString(),
        type: 'booking_offer',
      },
    );

    return {
      message: 'Đã gửi báo giá thành công',
      offerId: offerResult[0].id.toString(),
      bookingId: bookingId.toString(),
      customerId: booking.customerId.toString(),
      isDirectBooking: false,
    };
  }

  async selectProvider(
    customerId: bigint,
    bookingId: bigint,
    providerId: bigint,
  ) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) throw new NotFoundException('Booking not found');
    if (booking.customerId !== customerId)
      throw new ForbiddenException('Not your booking');

    // Verify offer exists using raw SQL
    const offers = await this.prisma.$queryRawUnsafe<any[]>(
      `
      SELECT id, price FROM booking_offers 
      WHERE booking_id = $1 AND provider_id = $2
    `,
      bookingId,
      providerId,
    );

    if (!offers || offers.length === 0)
      throw new NotFoundException('Provider offer not found');

    const offer = offers[0];

    // Update Booking and Offers
    return await this.prisma.$transaction(async (tx) => {
      // Update Booking
      const updatedBooking = await tx.booking.update({
        where: { id: bookingId },
        data: {
          providerId,
          providerServicePrice: offer.price,
          status: 'accepted',
          estimatedPrice: offer.price,
        },
        include: {
          customer: {
            include: { profile: true },
          },
        },
      });

      // Update Offers using raw SQL
      await tx.$executeRawUnsafe(
        `
        UPDATE booking_offers SET status = 'ACCEPTED', updated_at = NOW() WHERE id = $1
      `,
        offer.id,
      );

      await tx.$executeRawUnsafe(
        `
        UPDATE booking_offers SET status = 'REJECTED', updated_at = NOW() 
        WHERE booking_id = $1 AND id != $2
      `,
        bookingId,
        offer.id,
      );

      // Query coordinates securely
      const locations = await tx.$queryRawUnsafe<any[]>(
        `SELECT ST_X(location::geometry) as longitude, ST_Y(location::geometry) as latitude FROM bookings WHERE id = $1`,
        bookingId,
      );
      const loc = locations[0];

      // Get service category for emission
      const bookingDetails = await tx.booking.findUnique({
        where: { id: bookingId },
        include: { service: true },
      });

      // Emit job_taken to job market to remove from other providers' lists
      if (bookingDetails?.service?.categoryId) {
        this.realtimeGateway.emitJobTaken(
          bookingDetails.service.categoryId,
          bookingId.toString(),
          providerId.toString(),
        );
      }

      const result = {
        message: 'Đã chọn thợ thành công',
        bookingId: updatedBooking.id.toString(),
        providerId: providerId.toString(),
        latitude: loc?.latitude,
        longitude: loc?.longitude,
        addressText: updatedBooking.addressText,
        customerName: updatedBooking.customer.profile?.fullName,
      };

      // Create persistent notification for provider
      await this.notificationsService.create(
        providerId,
        'BOOKING_ACCEPTED',
        'Chúc mừng! Bạn đã được nhận việc',
        `Khách hàng ${updatedBooking.customer.profile?.fullName || ''} đã chọn bạn cho dịch vụ ${bookingDetails?.service?.name || ''}.`,
        {
          type: 'booking_accepted',
          ...result,
        },
      );

      // Emit real-time socket event to provider for immediate UI update
      this.realtimeGateway.emitBookingStatusChange(
        customerId.toString(),
        providerId.toString(),
        {
          bookingId: updatedBooking.id.toString(),
          status: 'accepted',
          message: `Chúc mừng! Khách hàng ${updatedBooking.customer.profile?.fullName || ''} đã chọn bạn cho dịch vụ ${bookingDetails?.service?.name || ''}.`,
          actorId: customerId.toString(),
          customerName: updatedBooking.customer.profile?.fullName ?? undefined,
          providerId: providerId.toString(),
          serviceName: bookingDetails?.service?.name,
          latitude: loc?.latitude,
          longitude: loc?.longitude,
          addressText: updatedBooking.addressText,
        },
      );

      return result;
    });
  }

  // GET /bookings/:id/offers
  async getBookingOffers(userId: bigint, bookingId: bigint) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) throw new NotFoundException('Booking not found');
    if (booking.customerId !== userId)
      throw new ForbiddenException('Not your booking');

    console.log(
      '[getBookingOffers] Loading offers for bookingId:',
      bookingId.toString(),
    );

    // Get offers using raw SQL with distance calculation
    // Use LEFT JOIN to include offers even if provider doesn't have a profile
    const offers = await this.prisma.$queryRawUnsafe<any[]>(
      `
      SELECT 
        bo.id,
        bo.booking_id,
        bo.provider_id,
        bo.price,
        bo.status,
        COALESCE(pp.display_name, up.full_name, 'Thợ') as provider_name,
        pp.rating_avg,
        pp.address as provider_address,
        pp.latitude as provider_lat,
        pp.longitude as provider_lng,
        CASE 
          WHEN b.location IS NOT NULL AND pp.location IS NOT NULL 
          THEN ST_Distance(b.location::geography, pp.location::geography)
          ELSE NULL 
        END as distance
      FROM booking_offers bo
      LEFT JOIN provider_profiles pp ON bo.provider_id = pp.user_id
      LEFT JOIN user_profiles up ON bo.provider_id = up.user_id
      JOIN bookings b ON bo.booking_id = b.id
      WHERE bo.booking_id = $1
      ORDER BY bo.created_at DESC
    `,
      bookingId,
    );

    console.log('[getBookingOffers] Found', offers.length, 'offers');
    if (offers.length > 0) {
      console.log('[getBookingOffers] First offer:', offers[0]);
    }

    return {
      offers: offers.map((o) => ({
        id: o.id.toString(),
        bookingId: o.booking_id.toString(),
        providerId: o.provider_id.toString(),
        providerName: o.provider_name || 'Thợ',
        providerAddress: o.provider_address,
        rating: o.rating_avg?.toString(),
        price: o.price.toString(),
        status: o.status,
        distance: o.distance ? Math.round(o.distance) : null, // distance in meters
        latitude: o.provider_lat,
        longitude: o.provider_lng,
      })),
    };
  }

  // GET /provider/bookings/requests
  // Returns pending bookings that match provider's service categories
  // Handles both: Direct Booking (provider_id = this provider) AND General Booking (category match)
  async getProviderRequests(providerId: bigint) {
    const requests = await this.prisma.$queryRawUnsafe<any[]>(
      `
      SELECT 
        b.id,
        b.code,
        b.status,
        b.scheduled_at,
        b.address_text,
        b.estimated_price,
        b.created_at,
        b.provider_id,
        s.name as service_name,
        sc.name as category_name,
        up.full_name as customer_name,
        CASE 
          WHEN b.location IS NOT NULL AND pp.location IS NOT NULL 
          THEN ST_Distance(b.location::geography, pp.location::geography)
          ELSE NULL 
        END as distance,
        ST_X(b.location::geometry) as longitude,
        ST_Y(b.location::geometry) as latitude,
        CASE 
          WHEN b.provider_id = $1 THEN 'DIRECT'
          ELSE 'GENERAL'
        END as booking_type,
        CASE WHEN b.provider_id = $1 THEN 0 ELSE 1 END as sort_priority
      FROM bookings b
      JOIN services s ON b.service_id = s.id
      LEFT JOIN service_categories sc ON s.category_id = sc.id
      JOIN user_profiles up ON b.customer_id = up.user_id
      CROSS JOIN provider_profiles pp
      WHERE pp.user_id = $1
        AND b.status = 'pending'
        AND (
          -- Include if within radius OR if location data is missing (be flexible)
          b.location IS NULL 
          OR pp.location IS NULL
          OR ST_DWithin(
            b.location::geography,
            pp.location::geography,
            COALESCE(pp.service_radius_m, 5000)
          )
        )
        AND (
          -- Case 1: Direct booking - provider was specifically chosen
          b.provider_id = $1
          
          -- Case 2: General booking - match by category 
          OR (
            b.provider_id IS NULL
            AND EXISTS (
              SELECT 1 FROM provider_services ps
              JOIN services ps_svc ON ps.service_id = ps_svc.id
              WHERE ps.provider_user_id = $1
                AND ps.is_active = true
                AND ps.deleted_at IS NULL
                AND ps_svc.category_id = s.category_id
            )
          )
        )
        -- Haven't already submitted an offer for this booking
        AND NOT EXISTS (
          SELECT 1 FROM booking_offers bo 
          WHERE bo.booking_id = b.id AND bo.provider_id = $1
        )
      ORDER BY sort_priority, b.created_at DESC
      LIMIT 20
    `,
      providerId,
    );

    console.log('[getProviderRequests] providerId:', providerId.toString());
    console.log(
      '[getProviderRequests] Found',
      requests.length,
      'requests within radius',
    );
    if (requests.length > 0) {
      requests.forEach((r) => {
        console.log(
          `[getProviderRequests] Booking ${r.code}: distance=${r.distance}m, radius=${r.service_radius_m || 5000}m`,
        );
      });
    }

    return {
      requests: requests.map((r) => ({
        id: r.id.toString(),
        code: r.code,
        status: r.status,
        scheduledAt: r.scheduled_at,
        addressText: r.address_text,
        estimatedPrice: r.estimated_price?.toString(),
        serviceName: r.service_name,
        categoryName: r.category_name,
        customerName: r.customer_name,
        distance: r.distance != null ? Math.round(r.distance) : null,
        longitude: r.longitude,
        latitude: r.latitude,
        bookingType: r.booking_type, // 'DIRECT' or 'GENERAL'
        isDirectBooking: r.provider_id != null,
      })),
    };
  }

  // GET /provider/bookings/global - Bookings matching search or category competence
  async getGlobalRequests(
    providerId: bigint,
    serviceId?: number,
    categoryId?: number,
    onlyFar?: boolean,
  ) {
    const requests = await this.prisma.$queryRawUnsafe<any[]>(
      `
      SELECT DISTINCT
        b.id,
        b.code,
        b.status,
        b.scheduled_at,
        b.address_text,
        b.estimated_price,
        s.name as service_name,
        up.full_name as customer_name,
        ST_Distance(
          b.location::geography,
          pp.location::geography
        ) as distance,
        ST_X(b.location::geometry) as longitude,
        ST_Y(b.location::geometry) as latitude,
        pp.service_radius_m
      FROM bookings b
      JOIN services s ON b.service_id = s.id
      JOIN user_profiles up ON b.customer_id = up.user_id
      JOIN provider_profiles pp ON pp.user_id = $1
      LEFT JOIN booking_offers bo ON bo.booking_id = b.id AND bo.provider_id = $1
      WHERE b.status = 'pending'
        AND bo.id IS NULL
        -- Distance filter if onlyFar is true
        AND (
          NOT $4::boolean OR (
            b.location IS NOT NULL 
            AND pp.location IS NOT NULL 
            AND ST_Distance(b.location::geography, pp.location::geography) > COALESCE(pp.service_radius_m, 5000)
          )
        )
        AND (
          -- My far direct bookings
          b.provider_id = $1
          -- General bookings matching my categories
          OR (
            b.provider_id IS NULL
            AND (
              -- Filter by specific selected Service or Category
              ($2::int IS NOT NULL AND b.service_id = $2::int)
              OR ($3::int IS NOT NULL AND $2::int IS NULL AND s.category_id = $3::int)
              -- DEFAULT: Show jobs in any category for GLOBAL exploration, 
              -- but if we want strictly "work" category competency, we keep this:
              OR ($2::int IS NULL AND $3::int IS NULL AND EXISTS (
                SELECT 1 FROM provider_services ps2
                JOIN services s2 ON ps2.service_id = s2.id
                WHERE ps2.provider_user_id = $1
                  AND s2.category_id = s.category_id
                  AND ps2.is_active = true
                  AND ps2.deleted_at IS NULL
              ))
            )
          )
        )
      ORDER BY ST_Distance(b.location::geography, pp.location::geography) ASC
      LIMIT 50
    `,
      providerId,
      serviceId || null,
      categoryId || null,
      onlyFar || false,
    );

    console.log(
      `[getGlobalRequests] providerId: ${providerId}, onlyFar: ${onlyFar}, serviceId: ${serviceId}, categoryId: ${categoryId}`,
    );
    console.log(
      `[getGlobalRequests] Found ${requests.length} total results from SQL`,
    );

    if (requests.length > 0) {
      requests.forEach((r) => {
        console.log(
          `[getGlobalRequests] Booking ${r.code}: distance=${r.distance}m, provider_radius=${r.service_radius_m || 5000}m, isOutside=${r.distance > (r.service_radius_m || 5000)}`,
        );
      });
    }

    return {
      requests: requests.map((r) => ({
        id: r.id.toString(),
        code: r.code,
        status: r.status,
        scheduledAt: r.scheduled_at,
        addressText: r.address_text,
        estimatedPrice: r.estimated_price?.toString(),
        serviceName: r.service_name,
        customerName: r.customer_name,
        distance: r.distance != null ? Math.round(r.distance) : null,
        longitude: r.longitude,
        latitude: r.latitude,
        isOutsideRadius:
          r.distance != null && r.distance > (r.service_radius_m || 5000),
      })),
    };
  }

  // GET /bookings
  async getBookings(userId: bigint, query: BookingQueryDto) {
    const where: any = {
      OR: [{ customerId: userId }, { providerId: userId }],
    };

    if (query.status) {
      where.status = query.status;
    }

    const page = query.page || 1;
    const limit = query.limit || 20;

    const [bookings, total] = await Promise.all([
      this.prisma.booking.findMany({
        where,
        include: {
          service: true,
          customer: {
            select: {
              id: true,
              profile: {
                select: { fullName: true, avatarUrl: true },
              },
            },
          },
          providerUser: {
            select: {
              id: true,
              profile: {
                select: { fullName: true, avatarUrl: true },
              },
              providerProfile: {
                select: {
                  address: true,
                  latitude: true,
                  longitude: true,
                },
              },
            },
          },
          review: {
            select: {
              id: true,
              rating: true,
              comment: true,
              createdAt: true,
            },
          },
          selectedItems: {
            include: {
              providerServiceItem: {
                select: { id: true, name: true, price: true },
              },
            },
          },
          bookingPayment: {
            select: {
              id: true,
              paymentMethod: true,
              status: true,
            },
          },
          _count: {
            select: { bookingOffers: true },
          },
        },
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.booking.count({ where }),
    ]);

    // Query raw SQL to get lat/lng from PostGIS location (Prisma can't handle geography type)
    const bookingIds = bookings.map((b) => b.id);
    let locationMap: Map<string, { latitude: number; longitude: number }> =
      new Map();

    if (bookingIds.length > 0) {
      const locations = await this.prisma.$queryRawUnsafe<
        { id: bigint; latitude: number; longitude: number }[]
      >(
        `
        SELECT 
          id,
          ST_Y(location::geometry) as latitude,
          ST_X(location::geometry) as longitude
        FROM bookings 
        WHERE id = ANY($1::bigint[]) AND location IS NOT NULL
      `,
        bookingIds,
      );

      for (const loc of locations) {
        locationMap.set(loc.id.toString(), {
          latitude: loc.latitude,
          longitude: loc.longitude,
        });
      }
    }

    return {
      bookings: bookings.map((b: any) => {
        const loc = locationMap.get(b.id.toString());
        return {
          id: b.id.toString(),
          code: b.code,
          status: b.status,
          scheduledAt: b.scheduledAt,
          addressText: b.addressText,
          latitude: loc?.latitude ?? null,
          longitude: loc?.longitude ?? null,
          estimatedPrice: b.estimatedPrice?.toString(),
          actualPrice: b.actualPrice?.toString(),
          serviceId: b.serviceId,
          providerId: b.providerId ? b.providerId.toString() : null,
          service: {
            id: b.service.id,
            name: b.service.name,
          },
          customer: {
            id: b.customer.id.toString(),
            fullName: b.customer.profile?.fullName,
            avatarUrl: b.customer.profile?.avatarUrl,
          },
          provider: b.providerUser
            ? {
                id: b.providerUser.id.toString(),
                fullName: b.providerUser.profile?.fullName,
                avatarUrl: b.providerUser.profile?.avatarUrl,
                address: b.providerUser.providerProfile?.address || null,
              }
            : null,
          // Calculate distance between provider and booking location
          distance: (() => {
            const providerLat = b.providerUser?.providerProfile?.latitude;
            const providerLng = b.providerUser?.providerProfile?.longitude;
            if (!providerLat || !providerLng || !loc) return null;

            // Haversine formula to calculate distance in meters
            const R = 6371000; // Earth radius in meters
            const dLat = ((loc.latitude - providerLat) * Math.PI) / 180;
            const dLon = ((loc.longitude - providerLng) * Math.PI) / 180;
            const a =
              Math.sin(dLat / 2) * Math.sin(dLat / 2) +
              Math.cos((providerLat * Math.PI) / 180) *
                Math.cos((loc.latitude * Math.PI) / 180) *
                Math.sin(dLon / 2) *
                Math.sin(dLon / 2);
            const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
            return Math.round(R * c);
          })(),
          offersCount: b._count?.bookingOffers || 0,
          // Payment info
          paymentMethod: b.bookingPayment?.paymentMethod?.toUpperCase() || null,
          paymentStatus: b.bookingPayment?.status || null,
          bookingPaymentId: b.bookingPayment?.id?.toString() || null,
          // Customer pre-selected items for quote
          selectedItems:
            b.selectedItems?.map((item: any) => ({
              id: item.providerServiceItemId?.toString(),
              name: item.providerServiceItem?.name || 'Item',
              price: parseFloat(item.unitPrice?.toString() || '0'),
              quantity: item.quantity || 1,
            })) || [],
        };
      }),
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  // GET /bookings/:id
  async getBookingById(userId: bigint, bookingId: bigint) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: {
        service: true,
        customer: {
          select: {
            id: true,
            phone: true,
            profile: {
              select: { fullName: true, avatarUrl: true },
            },
          },
        },
        providerUser: {
          select: {
            id: true,
            phone: true,
            profile: {
              select: { fullName: true, avatarUrl: true },
            },
          },
        },
        bookingEvents: {
          orderBy: { createdAt: 'desc' },
        },
        review: true,
        _count: {
          select: { bookingOffers: true },
        },
      },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    // Check access
    if (booking.customerId !== userId && booking.providerId !== userId) {
      throw new ForbiddenException('Access denied');
    }

    // Cast to any to handle relations
    const b = booking as any;

    return {
      id: b.id.toString(),
      code: b.code,
      status: b.status,
      scheduledAt: b.scheduledAt,
      addressText: b.addressText,
      latitude: b.location ? (b.location as any).y : null,
      longitude: b.location ? (b.location as any).x : null,
      notes: b.notes,
      estimatedPrice: b.estimatedPrice?.toString(),
      actualPrice: b.actualPrice?.toString(),
      platformFee: b.platformFee.toString(),
      providerEarning: b.providerEarning.toString(),
      createdAt: b.createdAt,
      completedAt: b.completedAt,
      cancelledAt: b.cancelledAt,
      service: {
        id: b.service.id,
        name: b.service.name,
        description: b.service.description,
      },
      customer: {
        id: b.customer.id.toString(),
        phone: b.customer.phone,
        fullName: b.customer.profile?.fullName,
        avatarUrl: b.customer.profile?.avatarUrl,
      },
      provider: b.providerUser
        ? {
            id: b.providerUser.id.toString(),
            phone: b.providerUser.phone,
            fullName: b.providerUser.profile?.fullName,
            avatarUrl: b.providerUser.profile?.avatarUrl,
          }
        : null,
      timeline: b.bookingEvents.map((e: any) => ({
        status: e.newStatus,
        note: e.note,
        createdAt: e.createdAt,
        actor: e.actorUserId ? `User #${e.actorUserId}` : 'System',
      })),
      review: b.review
        ? {
            rating: b.review.rating,
            comment: b.review.comment,
            createdAt: b.review.createdAt,
          }
        : null,
      offersCount: b._count?.bookingOffers || 0,
    };
  }

  // PATCH /bookings/:id/cancel
  async cancelBooking(
    userId: bigint,
    bookingId: bigint,
    dto: CancelBookingDto,
  ) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    const isCustomer = booking.customerId === userId;
    const isAssignedProvider = booking.providerId === userId;

    if (!isCustomer && !isAssignedProvider) {
      throw new ForbiddenException('Not your booking');
    }

    if (!['pending', 'accepted'].includes(booking.status)) {
      throw new BadRequestException('Cannot cancel booking in current status');
    }

    return await this.prisma.$transaction(async (tx) => {
      const updated = await tx.booking.update({
        where: { id: bookingId },
        data: {
          status: 'cancelled',
          cancelledAt: new Date(),
        },
      });

      await tx.bookingEvent.create({
        data: {
          bookingId,
          previousStatus: booking.status,
          newStatus: 'cancelled',
          actorUserId: userId,
          note: dto.reason,
        },
      });

      // Notify the other party
      const targetUserId = isCustomer ? booking.providerId : booking.customerId;
      if (targetUserId) {
        const message = isCustomer
          ? 'Khách hàng đã hủy đơn đặt lịch'
          : 'Thợ đã từ chối yêu cầu đặt lịch';

        this.realtimeGateway.emitBookingStatusChange(
          booking.customerId.toString(),
          booking.providerId ? booking.providerId.toString() : null,
          {
            bookingId: bookingId.toString(),
            status: 'cancelled',
            previousStatus: booking.status,
            message: message,
            actorId: userId.toString(),
          },
        );

        // Persistent notification
        await this.notificationsService.create(
          targetUserId,
          'BOOKING_CANCELLED',
          'Đơn hàng đã bị hủy',
          `${message}: ${dto.reason || 'Không có lý do'}`,
          { bookingId: bookingId.toString(), status: 'cancelled' },
        );
      }

      return {
        id: updated.id.toString(),
        status: updated.status,
        message: 'Booking cancelled successfully',
      };
    });
  }

  // PATCH /provider/bookings/:id/accept
  async acceptBooking(providerId: bigint, bookingId: bigint) {
    console.log(
      `[acceptBooking] START - providerId: ${providerId} (type: ${typeof providerId}), bookingId: ${bookingId} (type: ${typeof bookingId})`,
    );

    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) {
      console.error(`[acceptBooking] ERROR: Booking ${bookingId} not found`);
      throw new NotFoundException('Booking not found');
    }

    console.log(`[acceptBooking] Booking details:`, {
      id: booking.id.toString(),
      status: booking.status,
      assignedProviderId: booking.providerId?.toString(),
      customerId: booking.customerId.toString(),
    });

    // BUSINESS RULE: Only the specifically assigned provider can directly 'accept'
    if (booking.providerId === null) {
      console.warn(
        `[acceptBooking] WARNING: Booking ${bookingId} is a general booking, cannot accept legacy.`,
      );
      throw new ForbiddenException(
        'Đơn hàng này cần báo giá trước, không thể nhận trực tiếp.',
      );
    }

    if (booking.providerId !== providerId) {
      console.error(
        `[acceptBooking] ID Mismatch: booking.providerId(${booking.providerId}) !== providerId(${providerId})`,
      );
      throw new ForbiddenException(
        'Bạn không phải là thợ được chỉ định cho đơn hàng này.',
      );
    }

    if (booking.status !== 'pending') {
      // Idempotency: If already accepted by this provider, return success
      if (booking.status === 'accepted' && booking.providerId === providerId) {
        console.log(
          `[acceptBooking] Idempotency: Booking ${bookingId} already accepted by provider ${providerId}`,
        );
        return {
          id: booking.id.toString(),
          status: booking.status,
          message: 'Booking accepted',
          customerId: booking.customerId.toString(),
        };
      }
      console.warn(
        `[acceptBooking] WARNING: Booking ${bookingId} is in status '${booking.status}', expected 'pending'`,
      );
      throw new BadRequestException(
        `Đơn hàng không ở trạng thái chờ (Hiện tại: ${booking.status}).`,
      );
    }

    // Get provider's price for this service
    const providerService = await this.prisma.providerService.findUnique({
      where: {
        providerUserId_serviceId: {
          providerUserId: providerId,
          serviceId: booking.serviceId,
        },
      },
    });

    const actualPrice = providerService?.price || booking.estimatedPrice || 0;

    return await this.prisma.$transaction(async (tx) => {
      const updated = await tx.booking.update({
        where: { id: bookingId },
        data: {
          status: 'accepted',
          actualPrice: actualPrice,
        },
      });

      await tx.bookingEvent.create({
        data: {
          bookingId,
          previousStatus: 'pending',
          newStatus: 'accepted',
          actorUserId: providerId,
          note: 'Provider accepted direct booking',
        },
      });

      // Emit socket event for real-time notification
      this.realtimeGateway.emitBookingStatusChange(
        booking.customerId.toString(),
        providerId.toString(),
        {
          bookingId: bookingId.toString(),
          status: 'accepted',
          previousStatus: 'pending',
          message: 'Thợ đã nhận đơn đặt lịch của bạn',
          actorId: providerId.toString(),
        },
      );

      // Persistent notification for customer
      await this.notificationsService.create(
        booking.customerId,
        'BOOKING_ACCEPTED',
        'Thợ đã nhận đơn',
        'Chúc mừng! Thợ đã chấp nhận yêu cầu dịch vụ của bạn.',
        { bookingId: bookingId.toString(), status: 'accepted' },
      );

      return {
        id: updated.id.toString(),
        status: updated.status,
        message: 'Booking accepted',
        customerId: booking.customerId.toString(),
      };
    });
  }

  // PATCH /provider/bookings/:id/start
  async startBooking(providerId: bigint, bookingId: bigint) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    if (booking.providerId !== providerId) {
      throw new ForbiddenException('Not your booking');
    }

    if (booking.status !== 'accepted') {
      throw new BadRequestException('Booking must be accepted first');
    }

    return await this.prisma.$transaction(async (tx) => {
      const updated = await tx.booking.update({
        where: { id: bookingId },
        data: { status: 'in_progress' },
      });

      await tx.bookingEvent.create({
        data: {
          bookingId,
          previousStatus: 'accepted',
          newStatus: 'in_progress',
          actorUserId: providerId,
          note: 'Provider started service',
        },
      });

      // Emit socket event for real-time notification
      this.realtimeGateway.emitBookingStatusChange(
        booking.customerId.toString(),
        providerId.toString(),
        {
          bookingId: bookingId.toString(),
          status: 'in_progress',
          previousStatus: 'accepted',
          message: 'Thợ đã bắt đầu làm việc',
          actorId: providerId.toString(),
        },
      );

      // Persistent notification for customer
      await this.notificationsService.create(
        booking.customerId,
        'BOOKING_STARTED',
        'Dịch vụ đang thực hiện',
        'Thợ đã bắt đầu thực hiện dịch vụ tại địa điểm của bạn.',
        { bookingId: bookingId.toString(), status: 'in_progress' },
      );

      return {
        id: updated.id.toString(),
        status: updated.status,
        message: 'Service started',
        customerId: booking.customerId.toString(),
      };
    });
  }

  // PATCH /provider/bookings/:id/complete
  // Provider marks service as complete, waits for customer confirmation
  async completeBooking(providerId: bigint, bookingId: bigint) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    if (booking.providerId !== providerId) {
      throw new ForbiddenException('Not your booking');
    }

    if (booking.status !== 'in_progress') {
      throw new BadRequestException('Booking must be in progress');
    }

    return await this.prisma.$transaction(async (tx) => {
      const actualPrice =
        booking.estimatedPrice || booking.providerServicePrice || 0;
      const platformFee = Math.round(Number(actualPrice) * 0.1);
      const providerEarning = Number(actualPrice) - platformFee;

      const updated = await tx.booking.update({
        where: { id: bookingId },
        data: {
          status: 'pending_payment' as any,
          actualPrice,
          platformFee,
          providerEarning,
          completedAt: new Date(),
        },
      });

      await tx.bookingEvent.create({
        data: {
          bookingId,
          previousStatus: booking.status,
          newStatus: 'pending_payment' as any,
          actorUserId: providerId,
          note: 'Dịch vụ hoàn thành (legacy call), chờ thanh toán',
        },
      });

      // Emit socket event for real-time notification
      this.realtimeGateway.emitBookingStatusChange(
        booking.customerId.toString(),
        providerId.toString(),
        {
          bookingId: bookingId.toString(),
          status: 'pending_completion',
          previousStatus: 'in_progress',
          message: 'Thợ đã hoàn thành công việc. Vui lòng xác nhận.',
          actorId: providerId.toString(),
        },
      );

      // Persistent notification for customer
      await this.notificationsService.create(
        booking.customerId,
        'BOOKING_COMPLETED',
        'Hoàn thành dịch vụ',
        'Thợ đã đánh dấu hoàn thành công việc. Vui lòng kiểm tra và xác nhận.',
        { bookingId: bookingId.toString(), status: 'pending_completion' },
      );

      return {
        id: updated.id.toString(),
        status: updated.status,
        message: 'Đã đánh dấu hoàn thành. Đang chờ khách hàng xác nhận.',
        customerId: booking.customerId.toString(),
      };
    });
  }

  // PATCH /bookings/:id/confirm-completion
  // Customer confirms the service is completed
  async confirmCompletion(customerId: bigint, bookingId: bigint) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: { service: true },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    if (booking.customerId !== customerId) {
      throw new ForbiddenException('Not your booking');
    }

    if (
      booking.status !== 'pending_completion' &&
      !(booking.status === 'completed' && booking.paymentStatus === 'held')
    ) {
      throw new BadRequestException(
        `Đơn hàng không ở trạng thái chờ hoàn tất (Hiện tại: ${booking.status}, Payment: ${booking.paymentStatus})`,
      );
    }

    return await this.prisma.$transaction(async (tx) => {
      // If it has escrow payment, release it
      if (booking.paymentStatus === 'held') {
        await this.bookingPaymentService.releaseEscrow(bookingId, customerId);
      }

      const updated = await tx.booking.update({
        where: { id: bookingId },
        data: {
          status: 'completed',
          paymentStatus: 'paid', // Mark as fully paid/released
          completedAt: new Date(),
        },
      });

      await tx.bookingEvent.create({
        data: {
          bookingId,
          previousStatus: 'pending_completion',
          newStatus: 'completed',
          actorUserId: customerId,
          note: 'Customer confirmed service completion',
        },
      });

      // Emit socket event for real-time notification to provider
      if (booking.providerId) {
        this.realtimeGateway.emitBookingStatusChange(
          customerId.toString(),
          booking.providerId.toString(),
          {
            bookingId: bookingId.toString(),
            status: 'completed',
            previousStatus: 'pending_completion',
            actorId: customerId.toString(),
          },
        );

        // Persistent notification for provider
        await this.notificationsService.create(
          booking.providerId,
          'BOOKING_COMPLETED',
          'Khách hàng đã xác nhận',
          'Tuyệt vời! Khách hàng đã xác nhận hoàn thành dịch vụ. Tiền đã được cộng vào tài khoản của bạn.',
          { bookingId: bookingId.toString(), status: 'completed' },
        );
      }

      return {
        id: updated.id.toString(),
        status: updated.status,
        message: 'Công việc đã hoàn thành. Vui lòng đánh giá dịch vụ.',
        canReview: true,
        providerId: booking.providerId ? booking.providerId.toString() : null,
      };
    });
  }

  // PATCH /bookings/:id/dispute
  // Customer disputes the service completion
  async disputeBooking(customerId: bigint, bookingId: bigint, reason?: string) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    if (booking.customerId !== customerId) {
      throw new ForbiddenException('Not your booking');
    }

    if (booking.status !== 'pending_completion') {
      throw new BadRequestException('Booking is not pending completion');
    }

    return await this.prisma.$transaction(async (tx) => {
      const updated = await tx.booking.update({
        where: { id: bookingId },
        data: {
          status: 'disputed',
        },
      });

      await tx.bookingEvent.create({
        data: {
          bookingId,
          previousStatus: 'pending_completion',
          newStatus: 'disputed',
          actorUserId: customerId,
          note: reason || 'Customer disputed service completion',
        },
      });

      // Emit socket event for real-time notification to provider
      if (booking.providerId) {
        this.realtimeGateway.emitBookingStatusChange(
          customerId.toString(),
          booking.providerId.toString(),
          {
            bookingId: bookingId.toString(),
            status: 'disputed',
            previousStatus: 'pending_completion',
            message: 'Khách hàng khiếu nại về công việc. Hệ thống sẽ xử lý.',
            actorId: customerId.toString(),
          },
        );
      }

      return {
        id: updated.id.toString(),
        status: updated.status,
        message: 'Đã gửi khiếu nại. Chúng tôi sẽ liên hệ với bạn sớm.',
      };
    });
  }

  // POST /bookings/:id/review
  async reviewBooking(
    userId: bigint,
    bookingId: bigint,
    dto: ReviewBookingDto,
  ) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: { review: true },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    if (booking.customerId !== userId) {
      throw new ForbiddenException('Not your booking');
    }

    if (booking.status !== 'completed') {
      throw new BadRequestException('Can only review completed bookings');
    }

    if (booking.review) {
      throw new BadRequestException('Booking already reviewed');
    }

    return await this.prisma.$transaction(async (tx) => {
      // Create review
      const review = await tx.review.create({
        data: {
          bookingId,
          reviewerId: userId,
          revieweeId: booking.providerId!,
          rating: dto.rating,
          comment: dto.comment,
        },
      });

      // Update provider rating
      const providerStats = await tx.review.aggregate({
        where: { revieweeId: booking.providerId! },
        _avg: { rating: true },
        _count: { rating: true },
      });

      // Get provider user info for displayName
      const providerUser = await tx.user.findUnique({
        where: { id: booking.providerId! },
        include: { profile: true },
      });

      await tx.providerProfile.update({
        where: { userId: booking.providerId! },
        data: {
          ratingAvg: providerStats._avg.rating || 0,
          ratingCount: providerStats._count.rating || 0,
        },
      });

      return {
        id: review.id.toString(),
        rating: review.rating,
        comment: review.comment,
        message: 'Review submitted successfully',
      };
    });
  }

  // Helper: Find nearest provider
  private async findNearestProvider(
    serviceId: number,
    latitude: number,
    longitude: number,
    tx?: any,
  ) {
    const prisma = tx || this.prisma;

    // Use queryRawUnsafe for dynamic params
    // Cast geography to text to avoid Prisma deserialization error
    const providers = await prisma.$queryRawUnsafe(
      `
      SELECT 
        pp.user_id,
        pp.display_name,
        pp.bio,
        pp.rating_avg,
        pp.rating_count,
        pp.is_available,
        pp.service_radius_m,
        ST_AsText(pp.location) as location_text,
        ST_Distance(
          pp.location::geography,
          ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography
        ) as distance
      FROM provider_profiles pp
      INNER JOIN provider_services ps ON pp.user_id = ps.provider_user_id
      WHERE ps.service_id = $3
        AND ps.is_active = true
        AND ps.deleted_at IS NULL
        AND pp.is_available = true
        AND ST_DWithin(
          pp.location::geography,
          ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
          pp.service_radius_m
        )
      ORDER BY distance ASC
      LIMIT 1
    `,
      longitude,
      latitude,
      serviceId,
    );

    return Array.isArray(providers) && providers.length > 0
      ? providers[0]
      : null;
  }
}
