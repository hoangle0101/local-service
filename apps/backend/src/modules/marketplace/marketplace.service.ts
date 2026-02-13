import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ServiceSearchDto, PaginationDto } from './dto/marketplace.dto';

@Injectable()
export class MarketplaceService {
  constructor(private prisma: PrismaService) {}

  // GET /marketplace/categories
  async getCategories() {
    const categories = await this.prisma.serviceCategory.findMany({
      where: { parentId: null }, // Only root categories
      include: {
        children: {
          select: {
            id: true,
            code: true,
            name: true,
            slug: true,
            description: true,
            iconUrl: true,
          },
        },
      },
      orderBy: { name: 'asc' },
    });

    return categories.map((cat) => ({
      id: cat.id,
      code: cat.code,
      name: cat.name,
      slug: cat.slug,
      description: cat.description,
      iconUrl: cat.iconUrl,
      children: cat.children,
    }));
  }

  // GET /marketplace/categories/:categoryId/services
  async getGenericServicesByCategory(categoryId: number) {
    const services = await this.prisma.service.findMany({
      where: { categoryId: categoryId },
      orderBy: { name: 'asc' },
    });

    return services.map((s) => ({
      id: s.id,
      name: s.name,
      description: s.description,
      basePrice: s.basePrice.toString(),
      durationMinutes: s.durationMinutes,
      categoryId: s.categoryId,
    }));
  }

  // GET /marketplace/categories/:slug
  async getCategoryBySlug(slug: string) {
    const category = await this.prisma.serviceCategory.findUnique({
      where: { slug },
      include: {
        children: {
          select: {
            id: true,
            code: true,
            name: true,
            slug: true,
            description: true,
            iconUrl: true,
          },
        },
        parent: {
          select: {
            id: true,
            code: true,
            name: true,
            slug: true,
          },
        },
      },
    });

    if (!category) {
      throw new NotFoundException(`Category with slug '${slug}' not found`);
    }

    return {
      id: category.id,
      code: category.code,
      name: category.name,
      slug: category.slug,
      description: category.description,
      iconUrl: category.iconUrl,
      parent: category.parent,
      children: category.children,
    };
  }

  // GET /marketplace/services/search
  async searchServices(dto: ServiceSearchDto) {
    const page = dto.page || 1;
    const limit = dto.limit || 20;
    const skip = (page - 1) * limit;

    // Build where clause
    const where: any = {
      isActive: true,
      deletedAt: null,
    };

    // Filter by category
    if (dto.categoryId) {
      where.service = {
        categoryId: dto.categoryId,
      };
    }

    // Filter by price range
    if (dto.minPrice !== undefined || dto.maxPrice !== undefined) {
      where.price = {};
      if (dto.minPrice !== undefined) {
        where.price.gte = dto.minPrice;
      }
      if (dto.maxPrice !== undefined) {
        where.price.lte = dto.maxPrice;
      }
    }

    // Filter by rating
    if (dto.minRating !== undefined) {
      where.provider = {
        ratingAvg: { gte: dto.minRating },
      };
    }

    // Location-based search using PostGIS
    let locationFilter: {
      latitude: number;
      longitude: number;
      radius: number;
    } | null = null;
    if (dto.latitude && dto.longitude) {
      const radius = dto.radiusMeters || 5000;
      // We'll handle this with raw SQL for PostGIS
      locationFilter = {
        latitude: dto.latitude,
        longitude: dto.longitude,
        radius,
      };
    }

    // Get provider services
    let providerServices;

    if (locationFilter) {
      // Build WHERE clauses for filters
      const whereClauses = [
        'ps.is_active = true',
        'ps.deleted_at IS NULL',
        'pp.is_available = true',
      ];

      const params: any[] = [
        locationFilter.longitude,
        locationFilter.latitude,
        locationFilter.longitude,
        locationFilter.latitude,
      ];

      if (dto.serviceId) {
        whereClauses.push(`ps.service_id = $${params.length + 1}`);
        params.push(dto.serviceId);
      } else if (dto.categoryId) {
        whereClauses.push(
          `ps.service_id IN (SELECT id FROM services WHERE category_id = $${params.length + 1})`,
        );
        params.push(dto.categoryId);
      }

      if (dto.minPrice !== undefined) {
        whereClauses.push(`ps.price >= $${params.length + 1}`);
        params.push(dto.minPrice);
      }

      if (dto.maxPrice !== undefined) {
        whereClauses.push(`ps.price <= $${params.length + 1}`);
        params.push(dto.maxPrice);
      }

      // Use Prisma.sql for raw SQL
      const query = `
        SELECT 
          ps.provider_user_id,
          ps.service_id,
          ps.price,
          ps.currency,
          ps.is_active,
          ST_Distance(
            pp.location::geography,
            ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography
          ) as distance
        FROM provider_services ps
        INNER JOIN provider_profiles pp ON ps.provider_user_id = pp.user_id
        WHERE ${whereClauses.join(' AND ')}
          AND ST_DWithin(
            pp.location::geography,
            ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
            pp.service_radius_m
          )
        ORDER BY distance ASC
        LIMIT ${limit}
        OFFSET ${skip}
      `;

      providerServices = await this.prisma.$queryRawUnsafe(query, ...params);
    } else {
      // Regular search without location
      providerServices = await this.prisma.providerService.findMany({
        where,
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
                  id: true,
                  phone: true,
                  profile: {
                    select: {
                      fullName: true,
                      avatarUrl: true,
                    },
                  },
                },
              },
            },
          },
        },
        skip,
        take: limit,
        orderBy:
          dto.sortBy === 'price'
            ? { price: dto.sortOrder === 'asc' ? 'asc' : 'desc' }
            : dto.sortBy === 'rating'
              ? {
                  provider: {
                    ratingAvg: dto.sortOrder === 'asc' ? 'asc' : 'desc',
                  },
                }
              : { createdAt: 'desc' },
      });
    }

    // Get total count
    const total = await this.prisma.providerService.count({ where });

    // Format response
    const results = Array.isArray(providerServices)
      ? providerServices.map((ps: any) => {
          const pId = BigInt(ps.provider_user_id || ps.providerUserId || 0);
          const sId = BigInt(ps.service_id || ps.serviceId || 0);
          const virtualId = (pId << 32n) | (sId & 0xffffffffn);

          return {
            id: virtualId.toString(),
            providerUserId: pId.toString(),
            serviceId: Number(sId),
            price: ps.price.toString(),
            currency: ps.currency,
            distance: ps.distance ? Math.round(ps.distance) : null,
            service: ps.service
              ? {
                  id: ps.service.id,
                  name: ps.service.name,
                  description: ps.service.description,
                  basePrice: ps.service.basePrice.toString(),
                  durationMinutes: ps.service.durationMinutes,
                  category: ps.service.category
                    ? {
                        id: ps.service.category.id,
                        name: ps.service.category.name,
                        slug: ps.service.category.slug,
                      }
                    : null,
                }
              : null,
            provider: ps.provider
              ? {
                  userId: ps.provider.userId.toString(),
                  displayName: ps.provider.displayName,
                  bio: ps.provider.bio,
                  ratingAvg: ps.provider.ratingAvg.toString(),
                  ratingCount: ps.provider.ratingCount,
                  isAvailable: ps.provider.isAvailable,
                  verificationStatus: ps.provider.verificationStatus,
                  user: ps.provider.user
                    ? {
                        profile: ps.provider.user.profile,
                      }
                    : null,
                }
              : null,
          };
        })
      : [];

    return {
      results,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getProviderServiceById(idOrServiceId: string | number) {
    const id = BigInt(idOrServiceId);
    let where: any = {};

    // If the ID is larger than a typical 32-bit INT, it's likely a Virtual ID
    // (composite of providerUserId and serviceId)
    if (id > 2147483647n) {
      const pId = id >> 32n;
      const sId = Number(id & 0xffffffffn);
      where = {
        providerUserId: pId,
        serviceId: sId,
      };
    } else {
      // Fallback for normal service IDs if needed
      where = {
        serviceId: Number(id),
      };
    }

    // Find the first active provider service
    const providerService = await this.prisma.providerService.findFirst({
      where: {
        ...where,
        isActive: true,
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
                profile: true,
              },
            },
          },
        },
      },
    });

    if (!providerService) {
      throw new NotFoundException(`Service with ID ${id} not found`);
    }

    const pId = BigInt(providerService.providerUserId);
    const sId = BigInt(providerService.serviceId);
    const virtualId = (pId << 32n) | (sId & 0xffffffffn);

    return {
      data: {
        id: virtualId.toString(),
        providerUserId: pId.toString(),
        serviceId: Number(sId),
        price: providerService.price.toString(),
        currency: providerService.currency,
        isActive: providerService.isActive,
        service: {
          id: providerService.service.id,
          name: providerService.service.name,
          description: providerService.service.description,
          basePrice: providerService.service.basePrice.toString(),
          durationMinutes: providerService.service.durationMinutes,
          categoryId: providerService.service.categoryId,
          // iconUrl: providerService.service.iconUrl,
          category: providerService.service.category,
        },
        provider: {
          userId: providerService.provider.userId.toString(),
          displayName: providerService.provider.displayName,
          isVerified:
            (providerService.provider.verificationStatus as any) === 'VERIFIED',
          ratingAvg: providerService.provider.ratingAvg.toString(),
          ratingCount: providerService.provider.ratingCount,
        },
      },
    };
  }

  // GET /marketplace/providers/:id
  async getProviderById(providerId: string) {
    const provider = await this.prisma.providerProfile.findUnique({
      where: { userId: BigInt(providerId) },
      include: {
        user: {
          select: {
            id: true,
            phone: true,
            createdAt: true,
            profile: {
              select: {
                fullName: true,
                avatarUrl: true,
                bio: true,
              },
            },
          },
        },
        providerServices: {
          where: {
            isActive: true,
            deletedAt: null,
          },
          include: {
            service: {
              include: {
                category: true,
              },
            },
          },
        },
      },
    });

    if (!provider) {
      throw new NotFoundException(`Provider with ID ${providerId} not found`);
    }

    return {
      userId: provider.userId.toString(),
      displayName: provider.displayName,
      bio: provider.bio,
      skills: provider.skills,
      ratingAvg: provider.ratingAvg.toString(),
      ratingCount: provider.ratingCount,
      isAvailable: provider.isAvailable,
      verificationStatus: provider.verificationStatus,
      serviceRadiusM: provider.serviceRadiusM,
      user: {
        profile: provider.user.profile,
      },
      services: provider.providerServices.map((ps) => ({
        serviceId: ps.serviceId,
        price: ps.price.toString(),
        currency: ps.currency,
        service: {
          id: ps.service.id,
          name: ps.service.name,
          description: ps.service.description,
          basePrice: ps.service.basePrice.toString(),
          durationMinutes: ps.service.durationMinutes,
          category: ps.service.category
            ? {
                id: ps.service.category.id,
                name: ps.service.category.name,
                slug: ps.service.category.slug,
              }
            : null,
        },
      })),
    };
  }

  // GET /marketplace/providers/:id/reviews
  async getProviderReviews(providerId: string, pagination: PaginationDto) {
    const page = pagination.page || 1;
    const limit = pagination.limit || 20;
    const skip = (page - 1) * limit;

    const [reviews, total] = await Promise.all([
      this.prisma.review.findMany({
        where: {
          revieweeId: BigInt(providerId),
        },
        include: {
          reviewer: {
            select: {
              id: true,
              profile: {
                select: {
                  fullName: true,
                  avatarUrl: true,
                },
              },
            },
          },
          booking: {
            select: {
              id: true,
              service: {
                select: {
                  id: true,
                  name: true,
                },
              },
            },
          },
        },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.review.count({
        where: {
          revieweeId: BigInt(providerId),
        },
      }),
    ]);

    return {
      reviews: reviews.map((review) => ({
        id: review.id.toString(),
        rating: review.rating,
        comment: review.comment,
        createdAt: review.createdAt,
        reviewer: {
          id: review.reviewer.id.toString(),
          fullName: review.reviewer.profile?.fullName,
          avatarUrl: review.reviewer.profile?.avatarUrl,
        },
        booking: review.booking
          ? {
              id: review.booking.id.toString(),
              service: review.booking.service
                ? {
                    id: review.booking.service.id,
                    name: review.booking.service.name,
                  }
                : null,
            }
          : null,
      })),
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }
}
