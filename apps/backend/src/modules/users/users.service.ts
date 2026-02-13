import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import {
  AddressDto,
  ChangePasswordDto,
  DeviceDto,
  FavoriteDto,
  UpdateProfileDto,
} from './dto/user.dto';
import * as bcrypt from 'bcrypt';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async getProfile(userId: bigint) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        profile: true,
        providerProfile: true,
        wallet: true,
      },
    });
    if (!user) throw new NotFoundException('User not found');

    // Format response for frontend (convert BigInt to string, structure properly)
    return {
      id: user.id.toString(),
      phone: user.phone,
      email: user.email,
      status: user.status,
      isVerified: user.isVerified,
      lastLoginAt: user.lastLoginAt,
      profile: user.profile
        ? {
            userId: user.profile.userId.toString(),
            fullName: user.profile.fullName,
            avatarUrl: user.profile.avatarUrl,
            bio: user.profile.bio,
            gender: user.profile.gender,
            birthDate: user.profile.birthDate,
          }
        : null,
      providerProfile: user.providerProfile
        ? {
            userId: user.providerProfile.userId.toString(),
            displayName: user.providerProfile.displayName,
            bio: user.providerProfile.bio,
            skills: user.providerProfile.skills,
            serviceRadiusM: user.providerProfile.serviceRadiusM,
            verificationStatus: user.providerProfile.verificationStatus,
            isAvailable: user.providerProfile.isAvailable,
            address: (user.providerProfile as any).address,
            latitude: (user.providerProfile as any).latitude,
            longitude: (user.providerProfile as any).longitude,
            ratingAvg: user.providerProfile.ratingAvg?.toString() || '0',
            ratingCount: user.providerProfile.ratingCount,
          }
        : null,
      wallet: user.wallet
        ? {
            balance: user.wallet.balance?.toString() ?? '0',
          }
        : null,
    };
  }

  async updateProfile(userId: bigint, dto: UpdateProfileDto) {
    // Check if profile exists, create if not
    const existingProfile = await this.prisma.userProfile.findUnique({
      where: { userId },
    });

    // Convert birthDate string to Date if provided
    const data: any = { ...dto };
    if (dto.birthDate) {
      data.birthDate = new Date(dto.birthDate);
    }

    if (!existingProfile) {
      // Create profile if doesn't exist
      const newProfile = await this.prisma.userProfile.create({
        data: {
          userId,
          fullName: dto.fullName || 'User',
          ...data,
        },
      });

      return {
        userId: newProfile.userId.toString(),
        fullName: newProfile.fullName,
        avatarUrl: newProfile.avatarUrl,
        birthDate: newProfile.birthDate,
        gender: newProfile.gender,
        bio: newProfile.bio,
      };
    }

    // Update existing profile
    const updated = await this.prisma.userProfile.update({
      where: { userId },
      data,
    });

    return {
      userId: updated.userId.toString(),
      fullName: updated.fullName,
      avatarUrl: updated.avatarUrl,
      birthDate: updated.birthDate,
      gender: updated.gender,
      bio: updated.bio,
    };
  }

  async changePassword(userId: bigint, dto: ChangePasswordDto) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user || !user.passwordHash)
      throw new BadRequestException('User not found');

    const isMatch = await bcrypt.compare(dto.oldPassword, user.passwordHash);
    if (!isMatch) throw new BadRequestException('Incorrect old password');

    const salt = await bcrypt.genSalt();
    const newPasswordHash = await bcrypt.hash(dto.newPassword, salt);

    await this.prisma.user.update({
      where: { id: userId },
      data: { passwordHash: newPasswordHash },
    });

    return { message: 'Password updated successfully' };
  }

  async getAddresses(userId: bigint) {
    return this.prisma.address.findMany({ where: { userId } });
  }

  async addAddress(userId: bigint, dto: AddressDto) {
    const isDefault = dto.isDefault || false;

    if (isDefault) {
      await this.prisma.address.updateMany({
        where: { userId },
        data: { isDefault: false },
      });
    }

    // Use Prisma.sql for raw SQL with PostGIS
    await this.prisma.$executeRaw`
      INSERT INTO addresses (user_id, label, address_text, location, is_default, created_at, updated_at)
      VALUES (${userId}, ${dto.label || ''}, ${dto.addressText}, ST_SetSRID(ST_MakePoint(0, 0), 4326)::geography, ${isDefault}, NOW(), NOW())
    `;

    return { message: 'Address added successfully' };
  }

  async updateAddress(userId: bigint, addressId: bigint, dto: AddressDto) {
    await this.prisma.address.update({
      where: { id: addressId, userId },
      data: {
        label: dto.label,
        addressText: dto.addressText,
        isDefault: dto.isDefault,
      },
    });
    return { message: 'Address updated' };
  }

  async deleteAddress(userId: bigint, addressId: bigint) {
    await this.prisma.address.delete({
      where: { id: addressId, userId },
    });
    return { message: 'Address deleted' };
  }

  async getFavorites(userId: bigint) {
    const favorites = await this.prisma.favorite.findMany({
      where: { userId, targetType: 'provider_service' },
      orderBy: { createdAt: 'desc' },
    });

    // Get full details for each favorite
    const enrichedFavorites = await Promise.all(
      favorites.map(async (fav) => {
        try {
          // targetId is the Virtual ID (packed providerUserId and serviceId)
          const virtualId = BigInt(fav.targetId);
          const providerUserId = virtualId >> 32n;
          const serviceId = Number(virtualId & 0xffffffffn);

          const providerService = await this.prisma.providerService.findFirst({
            where: {
              providerUserId: providerUserId,
              serviceId: serviceId,
              deletedAt: null,
            },
            include: {
              service: {
                include: {
                  category: true,
                },
              },
              provider: {
                include: {
                  user: {
                    select: {
                      profile: {
                        select: {
                          avatarUrl: true,
                        },
                      },
                    },
                  },
                },
              },
            },
          });

          if (!providerService) return null;

          return {
            serviceId: providerService.serviceId,
            targetId: fav.targetId.toString(),
            createdAt: fav.createdAt,
            service: {
              id: providerService.service.id,
              name: providerService.service.name,
              description: providerService.service.description,
              category: providerService.service.category?.name,
            },
            provider: {
              userId: providerService.provider.userId.toString(),
              displayName: providerService.provider.displayName,
              avatarUrl: providerService.provider.user?.profile?.avatarUrl,
              ratingAvg: Number(providerService.provider.ratingAvg) || 0,
              ratingCount: providerService.provider.ratingCount,
              isVerified:
                providerService.provider.verificationStatus === 'verified',
            },
            price: Number(providerService.price),
            currency: providerService.currency,
          };
        } catch (e) {
          return null;
        }
      }),
    );

    return enrichedFavorites.filter((f) => f !== null);
  }

  async addFavorite(userId: bigint, dto: FavoriteDto) {
    // Basic existence check to avoid unique constraint error
    const existing = await this.prisma.favorite.findUnique({
      where: {
        userId_targetType_targetId: {
          userId,
          targetType: dto.targetType,
          targetId: BigInt(dto.targetId),
        },
      },
    });

    if (existing) return existing;

    return this.prisma.favorite.create({
      data: {
        userId,
        targetType: dto.targetType,
        targetId: BigInt(dto.targetId),
      },
    });
  }

  async removeFavoriteComposite(
    userId: bigint,
    targetId: bigint,
    targetType: string,
  ) {
    await this.prisma.favorite.delete({
      where: {
        userId_targetType_targetId: {
          userId,
          targetId,
          targetType,
        },
      },
    });
    return { message: 'Favorite removed' };
  }

  async registerDevice(userId: bigint, dto: DeviceDto) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    let metadata: any = user.metadata || {};

    let devices = metadata.devices || [];
    if (!devices.includes(dto.fcmToken)) {
      devices.push(dto.fcmToken);
    }

    metadata.devices = devices;

    await this.prisma.user.update({
      where: { id: userId },
      data: { metadata },
    });

    return { message: 'Device registered' };
  }

  async getNotifications(userId: bigint) {
    return this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async readAllNotifications(userId: bigint) {
    await this.prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });
    return { message: 'All notifications marked as read' };
  }
}
