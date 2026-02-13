import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import {
  CreateCategoryDto,
  UpdateCategoryDto,
  CreateServiceDto,
  UpdateServiceDto,
  SearchServiceDto,
} from './dto/services.dto';

@Injectable()
export class ServicesService {
  constructor(private prisma: PrismaService) {}

  // ==================== CATEGORY METHODS ====================

  async getCategories() {
    const categories = await this.prisma.serviceCategory.findMany({
      orderBy: { name: 'asc' },
    });

    // Build tree structure
    const buildTree = (parentId: number | null = null): any[] => {
      return categories
        .filter((c) => c.parentId === parentId)
        .map((c) => ({
          id: c.id,
          code: c.code,
          name: c.name,
          slug: c.slug,
          description: c.description,
          iconUrl: c.iconUrl,
          parentId: c.parentId,
          children: buildTree(c.id),
        }));
    };

    return buildTree();
  }

  async getCategoryById(id: number) {
    const category = await this.prisma.serviceCategory.findUnique({
      where: { id },
      include: {
        parent: {
          select: {
            id: true,
            name: true,
            slug: true,
          },
        },
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
    });

    if (!category) {
      throw new NotFoundException(`Category with ID ${id} not found`);
    }

    return category;
  }

  async createCategory(dto: CreateCategoryDto) {
    // Check if code already exists
    const existing = await this.prisma.serviceCategory.findUnique({
      where: { code: dto.code },
    });

    if (existing) {
      throw new BadRequestException(
        `Category with code '${dto.code}' already exists`,
      );
    }

    // Auto-generate slug if not provided
    const slug = dto.slug || dto.code.toLowerCase().replace(/_/g, '-');

    // Verify parent exists if provided
    if (dto.parentId) {
      const parent = await this.prisma.serviceCategory.findUnique({
        where: { id: dto.parentId },
      });

      if (!parent) {
        throw new NotFoundException(
          `Parent category with ID ${dto.parentId} not found`,
        );
      }
    }

    return await this.prisma.serviceCategory.create({
      data: {
        name: dto.name,
        code: dto.code,
        slug,
        description: dto.description,
        iconUrl: dto.iconUrl,
        parentId: dto.parentId,
      },
    });
  }

  async updateCategory(id: number, dto: UpdateCategoryDto) {
    // Verify category exists
    await this.getCategoryById(id);

    // Verify parent exists if provided
    if (dto.parentId) {
      if (dto.parentId === id) {
        throw new BadRequestException('Category cannot be its own parent');
      }

      const parent = await this.prisma.serviceCategory.findUnique({
        where: { id: dto.parentId },
      });

      if (!parent) {
        throw new NotFoundException(
          `Parent category with ID ${dto.parentId} not found`,
        );
      }
    }

    return await this.prisma.serviceCategory.update({
      where: { id },
      data: dto,
    });
  }

  async deleteCategory(id: number) {
    // Check if category has children
    const children = await this.prisma.serviceCategory.count({
      where: { parentId: id },
    });

    if (children > 0) {
      throw new BadRequestException(
        'Cannot delete category with subcategories',
      );
    }

    // Check if category has services
    const services = await this.prisma.service.count({
      where: { categoryId: id },
    });

    if (services > 0) {
      throw new BadRequestException(
        'Cannot delete category with existing services',
      );
    }

    await this.prisma.serviceCategory.delete({
      where: { id },
    });

    return { message: 'Category deleted successfully' };
  }

  // ==================== SERVICE METHODS ====================

  async searchServices(dto: SearchServiceDto) {
    const page = dto.page || 1;
    const limit = dto.limit || 20;
    const skip = (page - 1) * limit;
    const sortBy = dto.sortBy || 'createdAt';
    const sortOrder = dto.sortOrder || 'desc';

    // Build where clause
    const where: any = {};

    if (dto.keyword) {
      where.OR = [
        { name: { contains: dto.keyword, mode: 'insensitive' } },
        { description: { contains: dto.keyword, mode: 'insensitive' } },
      ];
    }

    if (dto.categoryId) {
      where.categoryId = dto.categoryId;
    }

    if (dto.minPrice !== undefined || dto.maxPrice !== undefined) {
      where.basePrice = {};
      if (dto.minPrice !== undefined) {
        where.basePrice.gte = dto.minPrice;
      }
      if (dto.maxPrice !== undefined) {
        where.basePrice.lte = dto.maxPrice;
      }
    }

    // Build orderBy
    const orderBy: any = {};
    if (sortBy === 'name') {
      orderBy.name = sortOrder;
    } else if (sortBy === 'price') {
      orderBy.basePrice = sortOrder;
    } else {
      orderBy.createdAt = sortOrder;
    }

    // Get services
    const [services, total] = await Promise.all([
      this.prisma.service.findMany({
        where,
        include: {
          category: {
            select: {
              id: true,
              name: true,
              slug: true,
            },
          },
        },
        skip,
        take: limit,
        orderBy,
      }),
      this.prisma.service.count({ where }),
    ]);

    return {
      data: services.map((s) => ({
        id: s.id,
        name: s.name,
        description: s.description,
        basePrice: s.basePrice.toString(),
        durationMinutes: s.durationMinutes,
        imageUrl: s.imageUrl,
        isActive: s.isActive,
        categoryId: s.categoryId,
        category: s.category,
        createdAt: s.createdAt,
        updatedAt: s.updatedAt,
      })),
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getServiceById(id: number) {
    const service = await this.prisma.service.findUnique({
      where: { id },
      include: {
        category: true,
      },
    });

    if (!service) {
      throw new NotFoundException(`Service with ID ${id} not found`);
    }

    return {
      id: service.id,
      name: service.name,
      description: service.description,
      basePrice: service.basePrice.toString(),
      durationMinutes: service.durationMinutes,
      imageUrl: service.imageUrl,
      isActive: service.isActive,
      categoryId: service.categoryId,
      category: service.category,
      createdAt: service.createdAt,
      updatedAt: service.updatedAt,
    };
  }

  async createService(dto: CreateServiceDto) {
    // Verify category exists
    const category = await this.prisma.serviceCategory.findUnique({
      where: { id: dto.categoryId },
    });

    if (!category) {
      throw new NotFoundException(
        `Category with ID ${dto.categoryId} not found`,
      );
    }

    const service = await this.prisma.service.create({
      data: {
        name: dto.name,
        categoryId: dto.categoryId,
        basePrice: dto.basePrice,
        description: dto.description,
        durationMinutes: dto.durationMinutes,
        imageUrl: dto.imageUrl,
        isActive: dto.isActive ?? true,
      },
      include: {
        category: true,
      },
    });

    return {
      id: service.id,
      name: service.name,
      description: service.description,
      basePrice: service.basePrice.toString(),
      durationMinutes: service.durationMinutes,
      imageUrl: service.imageUrl,
      isActive: service.isActive,
      category: service.category,
      message: 'Service created successfully',
    };
  }

  async updateService(id: number, dto: UpdateServiceDto) {
    // Verify service exists
    await this.getServiceById(id);

    // Verify category exists if provided
    if (dto.categoryId) {
      const category = await this.prisma.serviceCategory.findUnique({
        where: { id: dto.categoryId },
      });

      if (!category) {
        throw new NotFoundException(
          `Category with ID ${dto.categoryId} not found`,
        );
      }
    }

    const service = await this.prisma.service.update({
      where: { id },
      data: dto,
      include: {
        category: true,
      },
    });

    return {
      id: service.id,
      name: service.name,
      description: service.description,
      basePrice: service.basePrice.toString(),
      durationMinutes: service.durationMinutes,
      category: service.category,
      message: 'Service updated successfully',
    };
  }

  async deleteService(id: number) {
    // Check if service is used in provider services
    const providerServices = await this.prisma.providerService.count({
      where: { serviceId: id, deletedAt: null },
    });

    if (providerServices > 0) {
      throw new BadRequestException(
        'Cannot delete service that is currently offered by providers',
      );
    }

    await this.prisma.service.delete({
      where: { id },
    });

    return { message: 'Service deleted successfully' };
  }
}
