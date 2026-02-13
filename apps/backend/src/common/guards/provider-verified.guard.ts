import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class ProviderVerifiedGuard implements CanActivate {
  constructor(private prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const { user } = context.switchToHttp().getRequest();

    if (!user || !user.userId) {
      return false;
    }

    const providerProfile = await this.prisma.providerProfile.findUnique({
      where: { userId: BigInt(user.userId) },
      select: { verificationStatus: true },
    });

    if (!providerProfile) {
      throw new ForbiddenException('Provider profile not found');
    }

    if (providerProfile.verificationStatus !== 'verified') {
      throw new ForbiddenException('Provider account is not yet verified by admin');
    }

    return true;
  }
}
