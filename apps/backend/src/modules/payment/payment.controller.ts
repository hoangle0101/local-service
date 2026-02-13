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
import { ApiTags, ApiOperation, ApiBearerAuth, ApiProperty } from '@nestjs/swagger';
import { PaymentService } from './payment.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Public } from 'src/common/decorators/public.decorator';

import {
  IsNotEmpty,
  IsString,
  IsNumber,
  IsEnum,
} from 'class-validator';

class CreatePaymentDto {
  @ApiProperty({ example: '1' })
  @IsNotEmpty()
  @IsString()
  bookingId: string;

  @ApiProperty({ example: 100000 })
  @IsNotEmpty()
  @IsNumber()
  amount: number;

  @ApiProperty({ enum: ['COD', 'MOMO', 'cod', 'momo'] })
  @IsNotEmpty()
  @IsEnum(['COD', 'MOMO', 'cod', 'momo'])
  paymentMethod: 'COD' | 'MOMO' | 'cod' | 'momo';
}

class ConfirmCodDto {
  @ApiProperty({ example: '1' })
  @IsNotEmpty()
  @IsString()
  bookingPaymentId: string;
}

@ApiTags('Payment')
@Controller('payments')
export class PaymentController {
  constructor(private paymentService: PaymentService) {}

  /**
   * Create payment for booking
   */
  @Post('create')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create booking payment (COD or MoMo)' })
  async createPayment(@CurrentUser() user: any, @Body() dto: CreatePaymentDto) {
    return this.paymentService.createBookingPayment({
      bookingId: BigInt(dto.bookingId),
      amount: dto.amount,
      paymentMethod: dto.paymentMethod.toUpperCase() as 'COD' | 'MOMO',
    });
  }

  /**
   * MoMo IPN callback endpoint
   */
  @Post('momo/callback')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'MoMo IPN callback' })
  async momoCallback(@Body() data: any) {
    console.log('[PaymentController] MoMo callback:', data);
    await this.paymentService.handleMomoCallback(data);
  }

  /**
   * MoMo redirect callback (user returns to app)
   */
  @Get('momo/return')
  @ApiOperation({ summary: 'MoMo redirect callback' })
  async momoReturn(@Query() query: any) {
    console.log('[PaymentController] MoMo return:', query);
    // This is where user is redirected after payment
    // In mobile app, this would redirect to a deep link
    return {
      message: 'Payment processed',
      resultCode: query.resultCode,
      orderId: query.orderId,
    };
  }

  /**
   * Provider confirms COD payment collected
   */
  @Post('cod/confirm')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Provider confirms COD payment collected' })
  async confirmCod(@CurrentUser() user: any, @Body() dto: ConfirmCodDto) {
    return this.paymentService.confirmCodPayment(
      BigInt(dto.bookingPaymentId),
      BigInt(user.userId),
    );
  }

  /**
   * Release payment to provider (admin or after auto-confirm)
   */
  @Post(':id/release')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Release payment to provider' })
  async releasePayment(@Param('id') id: string) {
    return this.paymentService.releasePayment(BigInt(id));
  }

  @Get('check-status')
  @Public()
  @ApiOperation({ summary: 'Manually check MoMo payment status' })
  async checkStatus(@Query('orderId') orderId: string) {
    return this.paymentService.checkPaymentStatus(orderId);
  }

  @Get('test-status')
  async testStatus() {
    return {
      status: 'ok',
      message: 'Payment controller is reachable',
      timestamp: new Date().toISOString(),
    };
  }

  /**
   * Get provider's payments
   */
  @Get('provider/me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current provider payments' })
  async getMyPayments(
    @CurrentUser() user: any,
    @Query('status') status?: string,
  ) {
    return this.paymentService.getProviderPayments(BigInt(user.userId), status);
  }

  /**
   * Get payment by ID
   */
  @Get(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get booking payment by ID' })
  async getPayment(@Param('id') id: string) {
    return this.paymentService.getBookingPayment(BigInt(id));
  }

  /**
   * Refund payment to customer
   */
  @Post(':id/refund')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Refund payment to customer' })
  async refundPayment(@Param('id') id: string, @Body('reason') reason: string) {
    return this.paymentService.refundPayment(BigInt(id), reason);
  }
}
