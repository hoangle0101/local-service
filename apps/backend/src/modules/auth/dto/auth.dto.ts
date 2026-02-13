import {
  IsEmail,
  IsNotEmpty,
  IsOptional,
  IsString,
  MinLength,
  IsEnum,
  IsPhoneNumber,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export enum OtpPurpose {
  LOGIN = 'login',
  RESET_PASSWORD = 'reset_password',
  VERIFY_PHONE = 'verify_phone',
}

export class RegisterDto {
  @ApiProperty({ example: '+84987654321' })
  @IsNotEmpty()
  @IsPhoneNumber('VN')
  phone: string;

  @ApiProperty({ example: 'password123' })
  @IsNotEmpty()
  @MinLength(6)
  password: string;

  @ApiProperty({ example: 'John Doe' })
  @IsNotEmpty()
  fullName: string;

  @ApiProperty({
    example: 'customer',
    enum: ['customer', 'provider'],
    required: false,
  })
  @IsOptional()
  @IsString()
  role?: 'customer' | 'provider';
}

export class LoginDto {
  @ApiProperty({ example: '+84987654321' })
  @IsNotEmpty()
  phone: string;

  @ApiProperty({ example: 'password123' })
  @IsNotEmpty()
  password: string;
}

export class LoginWithOtpDto {
  @ApiProperty({ example: '+84987654321' })
  @IsNotEmpty()
  @IsPhoneNumber('VN')
  phone: string;

  @ApiProperty({ example: '123456' })
  @IsNotEmpty()
  code: string;
}

export class RefreshTokenDto {
  @ApiProperty()
  @IsNotEmpty()
  refreshToken: string;
}

export class SendOtpDto {
  @ApiProperty({ example: '+84987654321' })
  @IsNotEmpty()
  @IsPhoneNumber('VN')
  phone: string;

  @ApiProperty({ enum: OtpPurpose })
  @IsEnum(OtpPurpose)
  purpose: OtpPurpose;
}

export class VerifyOtpDto {
  @ApiProperty({ example: '+84987654321' })
  @IsNotEmpty()
  @IsPhoneNumber('VN')
  phone: string;

  @ApiProperty({ example: '123456' })
  @IsNotEmpty()
  code: string;

  @ApiProperty({ enum: OtpPurpose })
  @IsEnum(OtpPurpose)
  purpose: OtpPurpose;
}

export class ForgotPasswordDto {
  @ApiProperty({ example: '+84987654321' })
  @IsNotEmpty()
  @IsPhoneNumber('VN')
  phone: string;
}

export class ResetPasswordDto {
  @ApiProperty({ example: '+84987654321' })
  @IsNotEmpty()
  @IsPhoneNumber('VN')
  phone: string;

  @ApiProperty({ example: '123456' })
  @IsNotEmpty()
  otp: string;

  @ApiProperty({ example: 'newpassword123' })
  @IsNotEmpty()
  @MinLength(6)
  newPassword: string;
}
