import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsNumber, IsOptional, IsString } from 'class-validator';

export class CheckoutDto {
  @ApiProperty({ example: 1 })
  @IsNotEmpty()
  @IsNumber()
  bookingId: number;

  @ApiProperty({ enum: ['wallet', 'momo', 'stripe', 'bank_transfer'] })
  @IsEnum(['wallet', 'momo', 'stripe', 'bank_transfer'])
  paymentMethod: string;
}

export class WebhookDto {
  @ApiProperty()
  @IsOptional()
  @IsString()
  orderId?: string;

  @ApiProperty()
  @IsOptional()
  @IsNumber()
  resultCode?: number;

  @ApiProperty()
  @IsOptional()
  @IsNumber()
  amount?: number;
  
  // Stripe specific
  @ApiProperty()
  @IsOptional()
  data?: any;
  
  @ApiProperty()
  @IsOptional()
  type?: string;
}
