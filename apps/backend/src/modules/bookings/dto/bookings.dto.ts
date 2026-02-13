import {
  IsNotEmpty,
  IsNumber,
  IsString,
  IsDateString,
  IsOptional,
  IsEnum,
  IsArray,
  ValidateNested,
  Min,
  Max,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';

export class EstimateDto {
  @ApiProperty({ example: 1 })
  @IsNotEmpty()
  @IsNumber()
  serviceId: number;

  @ApiProperty({ example: '2025-12-01T10:00:00Z' })
  @IsNotEmpty()
  @IsDateString()
  scheduledAt: string;

  @ApiPropertyOptional({ example: 10.762622 })
  @IsOptional()
  @IsNumber()
  latitude?: number;

  @ApiPropertyOptional({ example: 106.660172 })
  @IsOptional()
  @IsNumber()
  longitude?: number;
}

// DTO for selected service items during booking
export class SelectedItemDto {
  @ApiProperty({ example: '1', description: 'Provider service item ID' })
  @IsNotEmpty()
  @IsString()
  itemId: string;

  @ApiPropertyOptional({ example: 1, default: 1 })
  @IsOptional()
  @IsNumber()
  @Min(1)
  quantity?: number = 1;
}

export class CreateBookingDto {
  @ApiProperty({ example: 1 })
  @IsNotEmpty()
  @IsNumber()
  serviceId: number;

  @ApiProperty({ example: '2025-12-01T10:00:00Z' })
  @IsNotEmpty()
  @IsDateString()
  scheduledAt: string;

  @ApiProperty({ example: '123 Le Loi, District 1, HCMC' })
  @IsNotEmpty()
  @IsString()
  addressText: string;

  @ApiProperty({ example: 10.762622 })
  @IsNotEmpty()
  @IsNumber()
  latitude: number;

  @ApiProperty({ example: 106.660172 })
  @IsNotEmpty()
  @IsNumber()
  longitude: number;

  @ApiPropertyOptional({ example: 'Please bring your own tools' })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiPropertyOptional({
    example: 1,
    description:
      'Provider ID for direct booking. If provided, the booking will be assigned directly to this provider.',
  })
  @IsOptional()
  @IsNumber()
  providerId?: number;

  @ApiPropertyOptional({
    type: [SelectedItemDto],
    description:
      'Pre-selected service items. If empty, provider will quote later.',
    example: [{ itemId: '1', quantity: 1 }],
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SelectedItemDto)
  selectedItems?: SelectedItemDto[];
}

export class CancelBookingDto {
  @ApiProperty({ example: 'Changed my mind' })
  @IsNotEmpty()
  @IsString()
  reason: string;
}

export class ReviewBookingDto {
  @ApiProperty({ example: 5 })
  @IsNotEmpty()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  @Max(5)
  rating: number;

  @ApiPropertyOptional({ example: 'Great service!' })
  @IsOptional()
  @IsString()
  comment?: string;
}

export class BookingQueryDto {
  @ApiPropertyOptional({
    enum: [
      'pending',
      'accepted',
      'in_progress',
      'pending_completion',
      'completed',
      'disputed',
      'cancelled',
    ],
  })
  @IsOptional()
  @IsEnum([
    'pending',
    'accepted',
    'in_progress',
    'pending_completion',
    'completed',
    'disputed',
    'cancelled',
  ])
  status?: string;

  @ApiPropertyOptional({ example: 1, default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  page?: number = 1;

  @ApiPropertyOptional({ example: 20, default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  limit?: number = 20;
}
