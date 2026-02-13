import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import {
  LoginDto,
  LoginWithOtpDto,
  OtpPurpose,
  RegisterDto,
  ResetPasswordDto,
  SendOtpDto,
  VerifyOtpDto,
} from './dto/auth.dto';
import { UserStatus } from '@prisma/client';
import { normalizePhoneNumber } from '../../common/utils/phone.util';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  async register(dto: RegisterDto) {
    const normalizedPhone = normalizePhoneNumber(dto.phone);
    const existingUser = await this.prisma.user.findUnique({
      where: { phone: normalizedPhone },
    });
    if (existingUser) {
      throw new BadRequestException(
        'User with this phone number already exists',
      );
    }

    const salt = await bcrypt.genSalt();
    const passwordHash = await bcrypt.hash(dto.password, salt);

    const user = await this.prisma.$transaction(async (tx) => {
      // Get the appropriate role (provider or customer)
      const roleName = dto.role || 'customer';
      const userRole = await tx.role.findUnique({
        where: { name: roleName },
      });

      if (!userRole) {
        throw new Error(
          `${roleName} role not found. Please run database seed.`,
        );
      }

      const newUser = await tx.user.create({
        data: {
          phone: normalizedPhone,
          passwordHash,
          status: UserStatus.inactive,
          wallet: {
            create: {
              balance: 0,
              currency: 'VND',
            },
          },
          profile: {
            create: {
              fullName: dto.fullName,
            },
          },
          userRoles: {
            create: {
              roleId: userRole.id,
            },
          },
        },
        include: {
          wallet: true,
          profile: true,
          userRoles: {
            include: {
              role: true,
            },
          },
        },
      });
      return newUser;
    });

    // Send OTP for phone verification
    await this.sendOtp({
      phone: normalizedPhone,
      purpose: OtpPurpose.VERIFY_PHONE,
    });

    return {
      message:
        'Registration successful. Please verify OTP to activate your account.',
    };
  }

  async login(dto: LoginDto) {
    const normalizedPhone = normalizePhoneNumber(dto.phone);
    const user = await this.prisma.user.findUnique({
      where: { phone: normalizedPhone },
    });

    if (!user || !user.passwordHash) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const isMatch = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isMatch) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Check if user is verified (must verify OTP first)
    if (user.status === UserStatus.inactive) {
      throw new UnauthorizedException(
        'Account not verified. Please verify OTP sent to your phone first.',
      );
    }

    if (user.status === UserStatus.banned) {
      throw new UnauthorizedException('Account has been banned');
    }

    // Update last login time
    await this.prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    return this.generateTokens(user.id, user.phone);
  }

  async generateTokens(userId: bigint, phone: string) {
    const payload = { sub: userId.toString(), phone };

    const accessToken = this.jwtService.sign(payload, {
      secret: this.configService.get<string>('jwt.accessSecret'),
      expiresIn: this.configService.get<string>('jwt.accessExpiresIn') as any,
    });

    const refreshToken = this.jwtService.sign(payload, {
      secret: this.configService.get<string>('jwt.refreshSecret'),
      expiresIn: this.configService.get<string>('jwt.refreshExpiresIn') as any,
    });

    // Hash refresh token before storing (security best practice)
    const salt = await bcrypt.genSalt(10);
    const refreshTokenHash = await bcrypt.hash(refreshToken, salt);

    await this.prisma.session.create({
      data: {
        userId,
        refreshTokenHash,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      },
    });

    return {
      accessToken,
      refreshToken,
    };
  }

  async sendOtp(dto: SendOtpDto) {
    // Generate random 6-digit code
    const code = Math.floor(100000 + Math.random() * 900000).toString();

    // Hash the code for security
    const salt = await bcrypt.genSalt();
    const codeHash = await bcrypt.hash(code, salt);

    await this.prisma.otpCode.create({
      data: {
        phone: normalizePhoneNumber(dto.phone),
        codeHash,
        purpose: dto.purpose,
        expiresAt: new Date(Date.now() + 5 * 60 * 1000),
        attemptCount: 0,
      },
    });

    // TODO: Send SMS via provider (Twilio, AWS SNS, etc.)
    console.log(`[OTP] Phone: ${dto.phone}, Code: ${code}`);

    // Return code only in development
    return {
      message: 'OTP sent successfully',
      ...(process.env.NODE_ENV === 'development' && { code }),
    };
  }

  async verifyOtp(dto: VerifyOtpDto) {
    const normalizedPhone = normalizePhoneNumber(dto.phone);
    // Get all valid OTPs for this phone and purpose
    const otps = await this.prisma.otpCode.findMany({
      where: {
        phone: normalizedPhone,
        purpose: dto.purpose,
        used: false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (otps.length === 0) {
      throw new BadRequestException('No valid OTP found');
    }

    // Try to verify with each OTP (in case of multiple attempts)
    for (const otp of otps) {
      // Check max attempts
      if (otp.attemptCount >= 5) {
        continue;
      }

      // Verify code using bcrypt
      const isValid = await bcrypt.compare(dto.code, otp.codeHash);

      if (isValid) {
        // Mark as used
        await this.prisma.otpCode.update({
          where: { id: otp.id },
          data: { used: true },
        });

        // Activate user if purpose is VERIFY_PHONE
        if (dto.purpose === OtpPurpose.VERIFY_PHONE) {
          await this.prisma.user.update({
            where: { phone: normalizedPhone },
            data: {
              status: UserStatus.active,
              isVerified: true,
            },
          });
        }

        return {
          message: 'OTP verified successfully',
          ...(dto.purpose === OtpPurpose.VERIFY_PHONE && {
            note: 'Account activated. You can now login with your password.',
          }),
        };
      }

      // Increment attempt count
      await this.prisma.otpCode.update({
        where: { id: otp.id },
        data: {
          attemptCount: otp.attemptCount + 1,
          lastAttemptAt: new Date(),
        },
      });
    }

    throw new BadRequestException('Invalid OTP code');
  }

  async resetPassword(dto: ResetPasswordDto) {
    const normalizedPhone = normalizePhoneNumber(dto.phone);
    await this.verifyOtp({
      phone: normalizedPhone,
      code: dto.otp,
      purpose: OtpPurpose.RESET_PASSWORD,
    });

    const salt = await bcrypt.genSalt();
    const passwordHash = await bcrypt.hash(dto.newPassword, salt);

    await this.prisma.user.update({
      where: { phone: normalizedPhone },
      data: { passwordHash },
    });

    return { message: 'Password reset successfully' };
  }

  async refreshToken(token: string) {
    try {
      const payload = this.jwtService.verify(token, {
        secret: this.configService.get<string>('jwt.refreshSecret'),
      });

      // Get all non-revoked sessions for this user
      const sessions = await this.prisma.session.findMany({
        where: {
          userId: BigInt(payload.sub),
          revoked: false,
          expiresAt: { gt: new Date() },
        },
      });

      if (sessions.length === 0) {
        throw new UnauthorizedException('No valid session found');
      }

      // Find matching session by comparing hashed token
      let validSession: (typeof sessions)[0] | null = null;
      for (const session of sessions) {
        const isMatch = await bcrypt.compare(token, session.refreshTokenHash);
        if (isMatch) {
          validSession = session;
          break;
        }
      }

      if (!validSession) {
        throw new UnauthorizedException('Session not found or revoked');
      }

      const newPayload = { sub: payload.sub, phone: payload.phone };
      const accessToken = this.jwtService.sign(newPayload, {
        secret: this.configService.get<string>('jwt.accessSecret'),
        expiresIn: this.configService.get<string>('jwt.accessExpiresIn') as any,
      });

      return { accessToken };
    } catch (e) {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  async loginWithOtp(dto: LoginWithOtpDto) {
    const normalizedPhone = normalizePhoneNumber(dto.phone);

    // Find user
    const user = await this.prisma.user.findUnique({
      where: { phone: normalizedPhone },
    });

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Check if user is banned
    if (user.status === UserStatus.banned) {
      throw new UnauthorizedException('Account has been banned');
    }

    // Verify OTP
    const otps = await this.prisma.otpCode.findMany({
      where: {
        phone: normalizedPhone,
        purpose: OtpPurpose.LOGIN,
        used: false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (otps.length === 0) {
      throw new BadRequestException(
        'No valid OTP found. Please request a new one.',
      );
    }

    let otpVerified = false;

    for (const otp of otps) {
      if (otp.attemptCount >= 5) {
        continue;
      }

      const isValid = await bcrypt.compare(dto.code, otp.codeHash);

      if (isValid) {
        // Mark as used
        await this.prisma.otpCode.update({
          where: { id: otp.id },
          data: { used: true },
        });

        // Activate user if inactive (first time login with OTP)
        if (user.status === UserStatus.inactive) {
          await this.prisma.user.update({
            where: { id: user.id },
            data: {
              status: UserStatus.active,
              isVerified: true,
              lastLoginAt: new Date(),
            },
          });
        } else {
          // Update last login
          await this.prisma.user.update({
            where: { id: user.id },
            data: { lastLoginAt: new Date() },
          });
        }

        otpVerified = true;
        break;
      }

      // Increment attempt count
      await this.prisma.otpCode.update({
        where: { id: otp.id },
        data: {
          attemptCount: otp.attemptCount + 1,
          lastAttemptAt: new Date(),
        },
      });
    }

    if (!otpVerified) {
      throw new BadRequestException('Invalid OTP code');
    }

    return this.generateTokens(user.id, user.phone);
  }

  async logout(refreshToken: string) {
    try {
      // Verify token first
      const payload = this.jwtService.verify(refreshToken, {
        secret: this.configService.get<string>('jwt.refreshSecret'),
      });

      // Get all non-revoked sessions for this user
      const sessions = await this.prisma.session.findMany({
        where: {
          userId: BigInt(payload.sub),
          revoked: false,
        },
      });

      // Find and revoke matching session
      for (const session of sessions) {
        const isMatch = await bcrypt.compare(
          refreshToken,
          session.refreshTokenHash,
        );
        if (isMatch) {
          await this.prisma.session.update({
            where: { id: session.id },
            data: { revoked: true, revokedAt: new Date() },
          });
          break;
        }
      }

      return { message: 'Logged out successfully' };
    } catch (e) {
      // Still return success even if token invalid (logout is idempotent)
      return { message: 'Logged out successfully' };
    }
  }
}
