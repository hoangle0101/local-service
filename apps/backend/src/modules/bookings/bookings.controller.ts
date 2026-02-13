import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
  ParseIntPipe,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiParam,
} from '@nestjs/swagger';
import { BookingsService } from './bookings.service';
import {
  EstimateDto,
  CreateBookingDto,
  CancelBookingDto,
  ReviewBookingDto,
  BookingQueryDto,
} from './dto/bookings.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { RealtimeGateway } from '../gateway/realtime.gateway';

@ApiTags('Bookings')
@Controller('bookings')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class BookingsController {
  constructor(
    private bookingsService: BookingsService,
    private realtimeGateway: RealtimeGateway,
  ) {}

  @Post('estimate')
  @ApiOperation({ summary: 'Estimate booking price' })
  async estimateBooking(@Body() dto: EstimateDto) {
    return this.bookingsService.estimateBooking(dto);
  }

  @Post()
  @ApiOperation({ summary: 'Create new booking' })
  async createBooking(@CurrentUser() user: any, @Body() dto: CreateBookingDto) {
    const result = await this.bookingsService.createBooking(
      BigInt(user.userId),
      dto,
    );

    return result;
  }

  @Get()
  @ApiOperation({ summary: 'List my bookings' })
  async getBookings(@CurrentUser() user: any, @Query() query: BookingQueryDto) {
    return this.bookingsService.getBookings(BigInt(user.userId), query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get booking details' })
  @ApiParam({ name: 'id', example: 1 })
  async getBookingById(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.bookingsService.getBookingById(BigInt(user.userId), BigInt(id));
  }

  @Get(':id/offers')
  @ApiOperation({ summary: 'Get offers for a booking' })
  @ApiParam({ name: 'id', example: 1 })
  async getBookingOffers(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.bookingsService.getBookingOffers(
      BigInt(user.userId),
      BigInt(id),
    );
  }

  @Patch(':id/cancel')
  @ApiOperation({ summary: 'Cancel booking (Customer)' })
  @ApiParam({ name: 'id', example: 1 })
  async cancelBooking(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: CancelBookingDto,
  ) {
    return this.bookingsService.cancelBooking(
      BigInt(user.userId),
      BigInt(id),
      dto,
    );
  }

  @Post(':id/review')
  @ApiOperation({ summary: 'Review booking (Customer)' })
  @ApiParam({ name: 'id', example: 1 })
  async reviewBooking(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ReviewBookingDto,
  ) {
    return this.bookingsService.reviewBooking(
      BigInt(user.userId),
      BigInt(id),
      dto,
    );
  }

  @Post(':id/select-provider/:providerId')
  @ApiOperation({ summary: 'Select provider for booking (Customer)' })
  @ApiParam({ name: 'id', example: 1 })
  @ApiParam({ name: 'providerId', example: 1 })
  async selectProvider(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: number,
    @Param('providerId', ParseIntPipe) providerId: number,
  ) {
    const result = await this.bookingsService.selectProvider(
      BigInt(user.userId),
      BigInt(id),
      BigInt(providerId),
    );

    return result;
  }

  @Patch(':id/confirm-completion')
  @ApiOperation({ summary: 'Customer confirms service completion' })
  @ApiParam({ name: 'id', example: 1 })
  async confirmCompletion(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: number,
  ) {
    // NOTE: booking_status_changed event is already emitted by service
    // No need to emit booking.confirmed separately
    return this.bookingsService.confirmCompletion(
      BigInt(user.userId),
      BigInt(id),
    );
  }

  @Patch(':id/dispute')
  @ApiOperation({ summary: 'Customer disputes service completion' })
  @ApiParam({ name: 'id', example: 1 })
  async disputeBooking(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: number,
    @Body('reason') reason?: string,
  ) {
    return this.bookingsService.disputeBooking(
      BigInt(user.userId),
      BigInt(id),
      reason,
    );
  }
}

@ApiTags('Provider Bookings')
@Controller('provider/bookings')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('provider')
@ApiBearerAuth()
export class ProviderBookingsController {
  constructor(
    private bookingsService: BookingsService,
    private realtimeGateway: RealtimeGateway,
  ) {}

  @Get('requests')
  @ApiOperation({
    summary: 'Get pending booking requests near provider (within radius)',
  })
  async getProviderRequests(@CurrentUser() user: any) {
    return this.bookingsService.getProviderRequests(BigInt(user.userId));
  }

  @Get('global')
  @ApiOperation({ summary: 'Get all pending booking requests' })
  async getGlobalRequests(
    @CurrentUser() user: any,
    @Query('serviceId') serviceId?: string,
    @Query('categoryId') categoryId?: string,
    @Query('onlyFar') onlyFar?: string,
  ) {
    return this.bookingsService.getGlobalRequests(
      BigInt(user.userId),
      serviceId ? parseInt(serviceId) : undefined,
      categoryId ? parseInt(categoryId) : undefined,
      onlyFar === 'true',
    );
  }

  @Post(':id/offer')
  @ApiOperation({ summary: 'Send booking offer (Provider)' })
  @ApiParam({ name: 'id', example: 1 })
  async acceptBookingRequest(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: number,
  ) {
    const result = await this.bookingsService.acceptBookingRequest(
      BigInt(user.userId),
      BigInt(id),
    );

    if (result.customerId) {
      this.realtimeGateway.notifyUser(
        result.customerId,
        'booking.new_offer',
        result,
      );
    }

    return result;
  }

  @Patch(':id/accept')
  @ApiOperation({ summary: 'Accept booking (Provider) - Legacy' })
  @ApiParam({ name: 'id', example: 1 })
  async acceptBooking(
    @CurrentUser() user: any,
    @Param('id') id: string, // Change to string to see raw value
  ) {
    console.log(
      `[ProviderBookingsController] acceptBooking called with id: ${id} (raw string)`,
    );
    const result = await this.bookingsService.acceptBooking(
      BigInt(user.userId),
      BigInt(id),
    );

    return result;
  }

  @Patch(':id/start')
  @ApiOperation({ summary: 'Start service (Provider)' })
  @ApiParam({ name: 'id', example: 1 })
  async startBooking(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: number,
  ) {
    // NOTE: booking_status_changed event is already emitted by service
    return this.bookingsService.startBooking(BigInt(user.userId), BigInt(id));
  }

  @Patch(':id/complete')
  @ApiOperation({ summary: 'Complete service (Provider)' })
  @ApiParam({ name: 'id', example: 1 })
  async completeBooking(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: number,
  ) {
    // NOTE: booking_status_changed event is already emitted by service
    const result = await this.bookingsService.completeBooking(
      BigInt(user.userId),
      BigInt(id),
    );

    if (result.customerId) {
      this.realtimeGateway.notifyUser(
        result.customerId,
        'booking.completed',
        result,
      );
    }

    return result;
  }
}
