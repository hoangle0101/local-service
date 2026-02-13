import { IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class PresignedUrlDto {
  @ApiProperty({ example: 'avatar.jpg' })
  @IsNotEmpty()
  @IsString()
  filename: string;

  @ApiProperty({ example: 'image/jpeg' })
  @IsNotEmpty()
  @IsString()
  contentType: string;
}

export class UploadResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  url: string;

  @ApiProperty()
  category: string | null;

  @ApiProperty()
  size: number | null;
}

export class UpsertSettingDto {
  @ApiProperty({ example: 'platform_fee_percent' })
  @IsNotEmpty()
  @IsString()
  key: string;

  @ApiProperty({ 
    example: { value: 15, type: 'percent' },
    description: 'Value as JSON object'
  })
  @IsNotEmpty()
  value: any;

  @ApiPropertyOptional({ example: 'Platform fee percentage' })
  @IsOptional()
  @IsString()
  description?: string;
}