import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsString,
  IsNumber,
  IsArray,
  IsOptional,
  ValidateNested,
  Min,
  IsInt,
  IsBoolean,
} from 'class-validator';
import { Type } from 'class-transformer';

// Enhanced QuoteItem with structured linking to service items
export class QuoteItemDto {
  @ApiPropertyOptional({
    example: '1',
    description: 'Provider service item ID if from price list',
  })
  @IsOptional()
  @IsString()
  serviceItemId?: string;

  @ApiProperty({ example: 'Thay gas máy lạnh' })
  @IsNotEmpty()
  @IsString()
  name: string;

  @ApiPropertyOptional({ example: 'Gas R32 chính hãng' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ example: 350000 })
  @IsNotEmpty()
  @IsNumber()
  @Min(0)
  price: number;

  @ApiProperty({ example: 1 })
  @IsNotEmpty()
  @IsInt()
  @Min(1)
  quantity: number;

  @ApiPropertyOptional({
    example: false,
    description: 'Custom item not in price list',
  })
  @IsOptional()
  @IsBoolean()
  isCustom?: boolean;

  @ApiPropertyOptional({
    example: true,
    description: 'Was selected by customer during booking',
  })
  @IsOptional()
  @IsBoolean()
  isFromCustomerSelection?: boolean;
}

export class CreateServiceQuoteDto {
  @ApiProperty({
    example:
      'Máy lạnh không lạnh, gas yếu, cần bổ sung gas và vệ sinh dàn lạnh',
  })
  @IsNotEmpty()
  @IsString()
  diagnosis: string;

  @ApiProperty({
    type: [QuoteItemDto],
    example: [
      { name: 'Bơm gas R32', price: 400000, quantity: 1, serviceItemId: '1' },
    ],
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => QuoteItemDto)
  items: QuoteItemDto[];

  @ApiProperty({ example: 150000, description: 'Công sửa chữa' })
  @IsNotEmpty()
  @IsNumber()
  @Min(0)
  laborCost: number;

  @ApiPropertyOptional({
    example: 50000,
    description: 'Phụ phí (di chuyển, ngoài giờ...)',
  })
  @IsOptional()
  @IsNumber()
  @Min(0)
  surcharge?: number;

  @ApiPropertyOptional({ example: '3 tháng bảo hành gas' })
  @IsOptional()
  @IsString()
  warranty?: string;

  @ApiPropertyOptional({
    example: 60,
    description: 'Thời gian ước tính (phút)',
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  estimatedTime?: number;

  @ApiPropertyOptional({ example: ['https://storage.com/image1.jpg'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  images?: string[];

  @ApiPropertyOptional({
    example: 'Khách hàng cần xác nhận trước khi thay thế linh kiện',
  })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiPropertyOptional({
    example:
      'Khách chọn thay gas nhưng sau khi kiểm tra cần thêm vệ sinh dàn lạnh',
    description: 'Ghi chú nếu có thay đổi so với customer chọn',
  })
  @IsOptional()
  @IsString()
  providerNotes?: string;
}

export class AcceptQuoteDto {
  @ApiPropertyOptional({ example: 'Đồng ý với báo giá' })
  @IsOptional()
  @IsString()
  customerNote?: string;
}

export class RejectQuoteDto {
  @ApiProperty({ example: 'Giá quá cao, tôi sẽ tìm thợ khác' })
  @IsNotEmpty()
  @IsString()
  reason: string;
}
