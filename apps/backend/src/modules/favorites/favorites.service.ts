import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class FavoritesService {
    constructor(private prisma: PrismaService) { }

    // POST /favorites/provider/:providerId - Add provider to favorites
    async addFavoriteProvider(userId: bigint, providerId: bigint) {
        console.log('[FavoritesService] addFavoriteProvider called');
        console.log('[FavoritesService] userId:', userId);
        console.log('[FavoritesService] providerId:', providerId);

        // Check if provider exists
        const provider = await this.prisma.providerProfile.findUnique({
            where: { userId: providerId },
        });

        if (!provider) {
            throw new NotFoundException('Provider not found');
        }

        console.log('[FavoritesService] Provider found:', provider.displayName);

        try {
            // Use upsert to avoid race conditions and ensure idempotency
            const favorite = await this.prisma.favorite.upsert({
                where: {
                    userId_targetType_targetId: {
                        userId,
                        targetType: 'provider',
                        targetId: providerId,
                    },
                },
                update: {},
                create: {
                    userId,
                    targetType: 'provider',
                    targetId: providerId,
                },
            });

            console.log('[FavoritesService] Upsert result:', favorite);

            // Verification
            const count = await this.prisma.favorite.count({
                where: { userId, targetType: 'provider', targetId: providerId },
            });
            console.log('[FavoritesService] Post-upsert count:', count);

            // Fetch provider details (including services and user profile)
            const fullProvider = await this.prisma.providerProfile.findUnique({
                where: { userId: providerId },
                include: {
                    user: { select: { profile: true } },
                    providerServices: {
                        where: { deletedAt: null },
                        include: { service: true },
                    },
                },
            });

            const providerPayload = fullProvider
                ? {
                    userId: fullProvider.userId.toString(),
                    displayName: fullProvider.displayName,
                    bio: fullProvider.bio,
                    ratingAvg: fullProvider.ratingAvg?.toString() ?? '0',
                    ratingCount: fullProvider.ratingCount ?? 0,
                    isAvailable: fullProvider.isAvailable,
                    verificationStatus: fullProvider.verificationStatus,
                    avatarUrl: fullProvider.user?.profile?.avatarUrl ?? null,
                    serviceRadiusM: fullProvider.serviceRadiusM,
                    services: fullProvider.providerServices.map((ps: any) => ({
                        serviceId: ps.serviceId,
                        serviceName: ps.service.name,
                        price: ps.price.toString(),
                    })),
                    favoritedAt: favorite.createdAt,
                }
                : null;

            return {
                userId: favorite.userId.toString(),
                targetType: favorite.targetType,
                targetId: favorite.targetId.toString(),
                createdAt: favorite.createdAt,
                message: 'Provider added to favorites',
                verified: count > 0,
                provider: providerPayload,
            };
        } catch (error) {
            console.error('[FavoritesService] Error in addFavoriteProvider:', error);
            throw error;
        }
    }

    // DELETE /favorites/provider/:providerId - Remove provider from favorites
    async removeFavoriteProvider(userId: bigint, providerId: bigint) {
        const favorite = await this.prisma.favorite.findUnique({
            where: {
                userId_targetType_targetId: {
                    userId,
                    targetType: 'provider',
                    targetId: providerId,
                },
            },
        });

        if (!favorite) {
            throw new NotFoundException('Favorite not found');
        }

        // Fetch provider payload so we can return it to client
        const fullProvider = await this.prisma.providerProfile.findUnique({
            where: { userId: providerId },
            include: {
                user: { select: { profile: true } },
                providerServices: {
                    where: { deletedAt: null },
                    include: { service: true },
                },
            },
        });

        await this.prisma.favorite.delete({
            where: {
                userId_targetType_targetId: {
                    userId,
                    targetType: 'provider',
                    targetId: providerId,
                },
            },
        });

        const providerPayload = fullProvider
            ? {
                userId: fullProvider.userId.toString(),
                displayName: fullProvider.displayName,
                bio: fullProvider.bio,
                ratingAvg: fullProvider.ratingAvg?.toString() ?? '0',
                ratingCount: fullProvider.ratingCount ?? 0,
                isAvailable: fullProvider.isAvailable,
                verificationStatus: fullProvider.verificationStatus,
                avatarUrl: fullProvider.user?.profile?.avatarUrl ?? null,
                serviceRadiusM: fullProvider.serviceRadiusM,
                services: fullProvider.providerServices.map((ps: any) => ({
                    serviceId: ps.serviceId,
                    serviceName: ps.service.name,
                    price: ps.price.toString(),
                })),
            }
            : null;

        return {
            message: 'Provider removed from favorites',
            provider: providerPayload,
        };
    }

    // GET /favorites/providers - Get list of favorite providers
    async getFavoriteProviders(userId: bigint, page = 1, limit = 20) {
        console.log('[FavoritesService] getFavoriteProviders called');
        console.log('[FavoritesService] Params - userId:', userId, 'page:', page, 'limit:', limit);
        const [favorites, total] = await Promise.all([
            this.prisma.favorite.findMany({
                where: {
                    userId,
                    targetType: 'provider',
                },
                skip: (page - 1) * limit,
                take: limit,
                orderBy: { createdAt: 'desc' },
            }),
            this.prisma.favorite.count({
                where: {
                    userId,
                    targetType: 'provider',
                },
            }),
        ]);

        console.log('[FavoritesService] favorites found (paged):', favorites.length);
        console.log('[FavoritesService] favorites raw:', favorites);
        console.log('[FavoritesService] total favorites count:', total);

        // Fetch provider details for each favorite
        const providerIds = favorites.map((f) => f.targetId);
        console.log('[FavoritesService] providerIds extracted from favorites:', providerIds);
        const providers = await this.prisma.providerProfile.findMany({
            where: {
                userId: {
                    in: providerIds,
                },
            },
            include: {
                user: {
                    select: {
                        profile: true,
                    },
                },
                providerServices: {
                    where: { deletedAt: null },
                    include: {
                        service: true,
                    },
                },
            },
        });

        console.log('[FavoritesService] provider profiles fetched:', providers.length);
        console.log('[FavoritesService] provider profiles raw:', providers.map((p) => p.userId));

        return {
            providers: providers.map((p: any) => ({
                userId: p.userId.toString(),
                displayName: p.displayName,
                bio: p.bio,
                ratingAvg: p.ratingAvg.toString(),
                ratingCount: p.ratingCount,
                isAvailable: p.isAvailable,
                verificationStatus: p.verificationStatus,
                avatarUrl: p.user?.profile?.avatarUrl,
                serviceRadiusM: p.serviceRadiusM,
                services: p.providerServices.map((ps: any) => ({
                    serviceId: ps.serviceId,
                    serviceName: ps.service.name,
                    price: ps.price.toString(),
                })),
                favoritedAt: favorites.find((f) => f.targetId === p.userId)?.createdAt,
            })),
            meta: {
                total,
                page,
                limit,
                totalPages: Math.ceil(total / limit),
            },
        };
    }

    // GET /favorites/check/provider/:providerId - Check if provider is in favorites
    async checkFavoriteProvider(userId: bigint, providerId: bigint) {
        console.log('[FavoritesService] checkFavoriteProvider called');
        console.log('[FavoritesService] userId:', userId, 'type:', typeof userId);
        console.log('[FavoritesService] providerId:', providerId, 'type:', typeof providerId);
        console.log('[FavoritesService] userId.toString():', userId.toString());
        console.log('[FavoritesService] providerId.toString():', providerId.toString());

        // Use Raw SQL to bypass any Prisma abstraction/caching issues
        const favorites = await this.prisma.$queryRawUnsafe<any[]>(
            `SELECT * FROM favorites WHERE user_id = $1 AND target_id = $2 AND target_type = $3`,
            BigInt(userId),
            BigInt(providerId),
            'provider'
        );

        // GLOBAL DEBUG: Count total favorites in the entire table
        const globalCount = await this.prisma.favorite.count();
        console.log('[FavoritesService] GLOBAL favorite table count:', globalCount);

        // DEBUGGING: List ALL favorites for this user
        const allFavorites = await this.prisma.favorite.findMany({
            where: {
                userId: BigInt(userId),
            },
        });
        console.log('[FavoritesService] ALL Favorites for user:', allFavorites);

        // Manual check in memory
        const match = allFavorites.find(
            (f) =>
                f.targetType === 'provider' &&
                f.targetId.toString() === providerId.toString(), // Compare as strings to be safe
        );

        console.log('[FavoritesService] In-memory match found:', match);

        return {
            isFavorite: !!match,
            providerId: providerId.toString(),
        };
    }
}
