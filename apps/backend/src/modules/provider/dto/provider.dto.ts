import {
  IsNotEmpty,
  IsOptional,
  IsString,
  IsNumber,
  Min,
  IsBoolean,
  IsArray,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';

export class OnboardingDto {
  @ApiProperty({ example: "John's Cleaning Service" })
  @IsNotEmpty()
  @IsString()
  displayName: string;

  @ApiPropertyOptional({
    example: 'Professional cleaner with 5 years experience',
  })
  @IsOptional()
  @IsString()
  bio?: string;

  @ApiPropertyOptional({
    example: ['cleaning', 'deep-cleaning', 'sanitization'],
  })
  @IsOptional()
  @IsArray()
  skills?: string[];

  @ApiPropertyOptional({ example: 10000, default: 5000 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  serviceRadiusM?: number;
}

export class UpdateProviderProfileDto {
  @ApiPropertyOptional({ example: "John's Cleaning Service" })
  @IsOptional()
  @IsString()
  displayName?: string;

  @ApiPropertyOptional({ example: 'Professional cleaner' })
  @IsOptional()
  @IsString()
  bio?: string;

  @ApiPropertyOptional({ example: ['cleaning', 'deep-cleaning'] })
  @IsOptional()
  @IsArray()
  skills?: string[];

  @ApiPropertyOptional({ example: 10000 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  serviceRadiusM?: number;

  @ApiPropertyOptional({ example: '123 Nguyễn Huệ, Quận 1, TP.HCM' })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional({ example: 10.762622 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  latitude?: number;

  @ApiPropertyOptional({ example: 106.660172 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  longitude?: number;
}

export class UpdateAvailabilityDto {
  @ApiProperty({ example: true })
  @IsNotEmpty()
  @IsBoolean()
  isAvailable: boolean;
}

export class AddServiceDto {
  @ApiProperty({ example: 1 })
  @IsNotEmpty()
  @Type(() => Number)
  @IsNumber()
  serviceId: number;

  @ApiProperty({ example: 200000 })
  @IsNotEmpty()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  price: number;

  @ApiPropertyOptional({ example: 'VND', default: 'VND' })
  @IsOptional()
  @IsString()
  currency?: string;
}

export class UpdateProviderServiceDto {
  @ApiPropertyOptional({ example: 250000 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  price?: number;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class UpdateLocationDto {
  @ApiProperty({ example: 10.762622, description: 'Latitude coordinate' })
  @IsNotEmpty()
  @Type(() => Number)
  @IsNumber()
  latitude: number;

  @ApiProperty({ example: 106.660172, description: 'Longitude coordinate' })
  @IsNotEmpty()
  @Type(() => Number)
  @IsNumber()
  longitude: number;

  @ApiPropertyOptional({ example: '123 Nguyễn Huệ, Quận 1, TP.HCM' })
  @IsOptional()
  @IsString()
  addressText?: string;
}
