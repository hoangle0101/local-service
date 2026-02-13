import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsArray,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsEnum,
  Min,
  Max,
  IsBoolean,
} from 'class-validator';
import { Type } from 'class-transformer';
import { DisputeCategory, DisputeStatus } from '@prisma/client';

// Dispute Categories as string enum for DTO
export const DISPUTE_CATEGORIES = [
  'service_not_completed',
  'poor_quality',
  'price_disagreement',
  'no_show_provider',
  'no_show_customer',
  'damage_caused',
  'unprofessional_behavior',
  'payment_issue',
  'other',
] as const;

// Dispute Statuses
export const DISPUTE_STATUSES = [
  'open',
  'under_review',
  'awaiting_response',
  'escalated',
  'resolved',
  'closed',
  'cancelled',
] as const;

// Resolution Types
export const RESOLUTION_TYPES = [
  'full_refund_to_customer',
  'partial_refund_to_customer',
  'full_payment_to_provider',
  'mutual_cancellation',
  'no_action',
] as const;

export class GetDisputesDto {
  @ApiPropertyOptional({ example: 1, description: 'Page number' })
  @IsOptional()
  @Type(() => Number)
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ example: 10, description: 'Items per page' })
  @IsOptional()
  @Type(() => Number)
  @Min(1)
  @Max(100)
  limit?: number = 10;

  @ApiPropertyOptional({
    description: 'Filter by status',
    enum: DISPUTE_STATUSES,
  })
  @IsOptional()
  @IsEnum(DISPUTE_STATUSES)
  status?: string;

  @ApiPropertyOptional({
    description: 'Filter by category',
    enum: DISPUTE_CATEGORIES,
  })
  @IsOptional()
  @IsEnum(DISPUTE_CATEGORIES)
  category?: string;

  @ApiPropertyOptional({
    example: 'desc',
    description: 'Sort order',
    enum: ['asc', 'desc'],
  })
  @IsOptional()
  @IsEnum(['asc', 'desc'])
  sortBy?: 'asc' | 'desc' = 'desc';
}

export class CreateDisputeDto {
  @ApiProperty({ example: 1, description: 'Booking ID' })
  @IsNotEmpty()
  @IsNumber()
  bookingId: number;

  @ApiProperty({ description: 'Dispute category', enum: DISPUTE_CATEGORIES })
  @IsNotEmpty()
  @IsEnum(DISPUTE_CATEGORIES)
  category: string;

  @ApiProperty({
    example: 'Service not as described',
    description: 'Dispute reason',
  })
  @IsNotEmpty()
  @IsString()
  reason: string;

  @ApiPropertyOptional({
    example: 'The provider did not clean the kitchen properly.',
    description: 'Detailed description',
  })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ type: [String], description: 'Evidence URLs' })
  @IsOptional()
  @IsArray()
  evidence?: string[];
}

export class GetDisputeDetailDto {
  @ApiPropertyOptional({
    example: true,
    description: 'Include related booking and service data',
  })
  @IsOptional()
  @Type(() => Boolean)
  includeRelations?: boolean = true;

  @ApiPropertyOptional({
    example: true,
    description: 'Include dispute timeline',
  })
  @IsOptional()
  @Type(() => Boolean)
  includeTimeline?: boolean = false;

  @ApiPropertyOptional({ example: true, description: 'Include evidence' })
  @IsOptional()
  @Type(() => Boolean)
  includeEvidence?: boolean = false;
}

export class UpdateDisputeAppealDto {
  @ApiProperty({
    example: 'I disagree with this resolution. Here is why...',
    description: 'Appeal reason',
  })
  @IsNotEmpty()
  @IsString()
  appealReason: string;

  @ApiPropertyOptional({
    type: [String],
    example: ['evidence_url_1', 'evidence_url_2'],
    description: 'New evidence URLs',
  })
  @IsOptional()
  @IsArray()
  newEvidence?: string[];
}

export class SubmitDisputeResponseDto {
  @ApiProperty({
    example: 'My response to this dispute...',
    description: 'Response text',
  })
  @IsNotEmpty()
  @IsString()
  response: string;

  @ApiPropertyOptional({
    type: [String],
    description: 'Evidence URLs supporting the response',
  })
  @IsOptional()
  @IsArray()
  evidence?: string[];
}

export class AddDisputeEvidenceDto {
  @ApiProperty({
    description: 'Evidence type',
    enum: ['image', 'video', 'audio', 'document', 'screenshot'],
  })
  @IsNotEmpty()
  @IsEnum(['image', 'video', 'audio', 'document', 'screenshot'])
  type: string;

  @ApiProperty({
    example: 'https://storage.example.com/evidence/123.jpg',
    description: 'Evidence URL',
  })
  @IsNotEmpty()
  @IsString()
  url: string;

  @ApiPropertyOptional({
    example: 'Photo of damaged item',
    description: 'Evidence description',
  })
  @IsOptional()
  @IsString()
  description?: string;
}

export class CancelDisputeDto {
  @ApiPropertyOptional({
    example: 'Issue resolved with provider directly',
    description: 'Reason for cancellation',
  })
  @IsOptional()
  @IsString()
  reason?: string;
}
