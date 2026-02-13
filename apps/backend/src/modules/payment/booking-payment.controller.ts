import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  IsNotEmpty,
  IsNumber,
  IsString,
  IsOptional,
} from 'class-validator';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { BookingPaymentService } from './booking-payment.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

class UpdateFinalPriceDto {
  @ApiProperty({ example: 100000 })
  @IsNotEmpty()
  @IsNumber()
  actualPrice: number;

  @ApiPropertyOptional({ example: 10000 })
  @IsOptional()
  @IsNumber()
  additionalCosts?: number;

  @ApiPropertyOptional({ example: 'Vật tư phát sinh' })
  @IsOptional()
  @IsString()
  additionalNotes?: string;
}

@ApiTags('Booking Payment')
@Controller('booking-payments') // Changed from 'bookings' to avoid conflict with BookingsController
export class BookingPaymentController {
  constructor(private bookingPaymentService: BookingPaymentService) {}

  /**
   * Provider updates final price after service
   */
  @Post(':id/update-price')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Provider updates final price' })
  async updateFinalPrice(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() dto: UpdateFinalPriceDto,
  ) {
    return this.bookingPaymentService.updateFinalPrice(
      BigInt(id),
      BigInt(user.userId),
      dto,
    );
  }

  /**
   * Provider marks service as complete (pending_payment)
   */
  @Post(':id/mark-complete')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Provider marks service complete' })
  async markServiceComplete(@Param('id') id: string, @CurrentUser() user: any) {
    return this.bookingPaymentService.markServiceComplete(
      BigInt(id),
      BigInt(user.userId),
    );
  }

  /**
   * Get invoice for booking (customer or provider)
   */
  @Get(':id/invoice')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get booking invoice' })
  async getInvoice(@Param('id') id: string, @CurrentUser() user: any) {
    return this.bookingPaymentService.getInvoice(
      BigInt(id),
      BigInt(user.userId),
    );
  }

  /**
   * Provider confirms COD payment received
   */
  @Post(':id/confirm-cod')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Provider confirms COD payment' })
  async confirmCodPayment(@Param('id') id: string, @CurrentUser() user: any) {
    return this.bookingPaymentService.confirmCodPayment(
      BigInt(id),
      BigInt(user.userId),
    );
  }

  /**
   * Customer initiates MoMo payment
   */
  @Post(':id/pay-momo')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Customer pays via MoMo' })
  async initiateMomoPayment(@Param('id') id: string, @CurrentUser() user: any) {
    return this.bookingPaymentService.initiateMomoPayment(
      BigInt(id),
      BigInt(user.userId),
    );
  }

  /**
   * TEST endpoint - check if basic GET works
   */
  @Get('test-endpoint')
  async testEndpoint(@Query('orderId') orderId: string) {
    console.log('[TEST] Endpoint called with orderId:', orderId);
    return {
      success: true,
      orderId,
      message: 'Test endpoint works!',
    };
  }

  /**
   * Check booking payment status (polling fallback for MoMo)
   */
  @Get('check-payment-status')
  // @UseGuards(JwtAuthGuard)  // TODO: Re-enable after testing
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Check booking payment status via MoMo query' })
  async checkPaymentStatus(
    @CurrentUser() user: any,
    @Query('orderId') orderId: string,
  ) {
    console.log('[checkPaymentStatus] Method called!', { orderId });

    // Temp: Use hardcoded userId for testing
    const userId = user?.userId ? BigInt(user.userId) : BigInt(1);

    return this.bookingPaymentService.checkAndProcessPayment(userId, orderId);
  }

  /**
   * MoMo IPN callback
   */
  @Post('momo-callback')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'MoMo IPN callback' })
  async momoCallback(@Body() data: any) {
    console.log('[BookingPaymentController] MoMo callback:', data);
    await this.bookingPaymentService.handleMomoCallback(data);
  }
}
