import { IsNotEmpty, IsOptional, IsString, MinLength, IsEnum, IsBoolean, IsNumber, IsDateString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateProfileDto {
  @ApiPropertyOptional({ example: 'John Doe' })
  @IsOptional()
  @IsString()
  fullName?: string;

  @ApiPropertyOptional({ example: 'https://example.com/avatar.jpg' })
  @IsOptional()
  @IsString()
  avatarUrl?: string;

  @ApiPropertyOptional({ example: 'I am a software engineer' })
  @IsOptional()
  @IsString()
  bio?: string;

  @ApiPropertyOptional({ example: 'Male' })
  @IsOptional()
  @IsString()
  gender?: string;

  @ApiPropertyOptional({ example: '1990-01-01' })
  @IsOptional()
  @IsDateString()
  birthDate?: string;
}

export class ChangePasswordDto {
  @ApiProperty({ example: 'oldpassword123' })
  @IsNotEmpty()
  oldPassword: string;

  @ApiProperty({ example: 'newpassword123' })
  @IsNotEmpty()
  @MinLength(6)
  newPassword: string;
}

export class AddressDto {
  @ApiProperty({ example: 'Home' })
  @IsOptional()
  @IsString()
  label?: string;

  @ApiProperty({ example: '123 Main St, City' })
  @IsNotEmpty()
  @IsString()
  addressText: string;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  isDefault?: boolean;
}

export class DeviceDto {
  @ApiProperty({ example: 'fcm_token_string' })
  @IsNotEmpty()
  @IsString()
  fcmToken: string;
}

export class FavoriteDto {
    @ApiProperty({ example: 'provider' })
    @IsNotEmpty()
    @IsString()
    targetType: string;

    @ApiProperty({ example: 1 })
    @IsNotEmpty()
    @IsNumber()
    targetId: number;
}
