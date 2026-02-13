import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import {
  CreateServiceItemDto,
  UpdateServiceItemDto,
} from './dto/service-item.dto';

@Injectable()
export class ProviderServiceItemsService {
  constructor(private prisma: PrismaService) {}

  private readonly MAX_ITEMS_PER_SERVICE = 20;

  /**
   * Get all items for a provider's service
   */
  async getItems(providerUserId: bigint, serviceId: number) {
    // Verify provider has this service
    const providerService = await this.prisma.providerService.findUnique({
      where: {
        providerUserId_serviceId: { providerUserId, serviceId },
      },
    });

    if (!providerService) {
      throw new NotFoundException('Provider service not found');
    }

    const items = await this.prisma.providerServiceItem.findMany({
      where: {
        providerUserId,
        serviceId,
        isActive: true,
      },
      orderBy: { sortOrder: 'asc' },
    });

    return items.map(this.serializeItem);
  }

  /**
   * Get items for a service (public - for customers)
   */
  async getPublicItems(providerUserId: bigint, serviceId: number) {
    console.log(
      `[ServiceItems] getPublicItems called - providerUserId: ${providerUserId}, serviceId: ${serviceId}`,
    );

    const items = await this.prisma.providerServiceItem.findMany({
      where: {
        providerUserId,
        serviceId,
        isActive: true,
      },
      orderBy: { sortOrder: 'asc' },
    });

    console.log(`[ServiceItems] Found ${items.length} items`);
    if (items.length > 0) {
      console.log('[ServiceItems] First item:', JSON.stringify(items[0]));
    }

    return items.map(this.serializeItem);
  }

  /**
   * Create a new service item
   */
  async createItem(
    providerUserId: bigint,
    serviceId: number,
    dto: CreateServiceItemDto,
  ) {
    console.log(
      `[ServiceItems] createItem called - providerUserId: ${providerUserId}, serviceId: ${serviceId}`,
    );
    console.log('[ServiceItems] DTO:', JSON.stringify(dto));

    // Verify provider has this service
    const providerService = await this.prisma.providerService.findUnique({
      where: {
        providerUserId_serviceId: { providerUserId, serviceId },
      },
    });

    if (!providerService) {
      console.log('[ServiceItems] ERROR: Provider service not found');
      throw new NotFoundException('Provider service not found');
    }

    console.log('[ServiceItems] Provider service found:', providerService);

    // Check max items limit
    const existingCount = await this.prisma.providerServiceItem.count({
      where: { providerUserId, serviceId },
    });

    console.log(`[ServiceItems] Existing items count: ${existingCount}`);

    if (existingCount >= this.MAX_ITEMS_PER_SERVICE) {
      throw new BadRequestException(
        `Maximum ${this.MAX_ITEMS_PER_SERVICE} items allowed per service`,
      );
    }

    const item = await this.prisma.providerServiceItem.create({
      data: {
        providerUserId,
        serviceId,
        name: dto.name,
        description: dto.description,
        price: dto.price,
        imageUrl: dto.imageUrl,
        sortOrder: dto.sortOrder ?? existingCount,
      },
    });

    console.log('[ServiceItems] Created item:', JSON.stringify(item));

    return this.serializeItem(item);
  }

  /**
   * Update a service item
   */
  async updateItem(
    providerUserId: bigint,
    itemId: bigint,
    dto: UpdateServiceItemDto,
  ) {
    const item = await this.prisma.providerServiceItem.findUnique({
      where: { id: itemId },
    });

    if (!item) {
      throw new NotFoundException('Item not found');
    }

    if (item.providerUserId !== providerUserId) {
      throw new ForbiddenException('Not authorized to update this item');
    }

    const updated = await this.prisma.providerServiceItem.update({
      where: { id: itemId },
      data: {
        name: dto.name,
        description: dto.description,
        price: dto.price,
        imageUrl: dto.imageUrl,
        isActive: dto.isActive,
        sortOrder: dto.sortOrder,
      },
    });

    return this.serializeItem(updated);
  }

  /**
   * Delete a service item
   */
  async deleteItem(providerUserId: bigint, itemId: bigint) {
    const item = await this.prisma.providerServiceItem.findUnique({
      where: { id: itemId },
    });

    if (!item) {
      throw new NotFoundException('Item not found');
    }

    if (item.providerUserId !== providerUserId) {
      throw new ForbiddenException('Not authorized to delete this item');
    }

    await this.prisma.providerServiceItem.delete({
      where: { id: itemId },
    });

    return { message: 'Item deleted successfully' };
  }

  /**
   * Reorder items
   */
  async reorderItems(
    providerUserId: bigint,
    serviceId: number,
    itemIds: string[],
  ) {
    // Update sort order for each item
    await Promise.all(
      itemIds.map((id, index) =>
        this.prisma.providerServiceItem.updateMany({
          where: {
            id: BigInt(id),
            providerUserId,
            serviceId,
          },
          data: { sortOrder: index },
        }),
      ),
    );

    return { message: 'Items reordered successfully' };
  }

  private serializeItem(item: any) {
    return {
      id: item.id.toString(),
      providerUserId: item.providerUserId.toString(),
      serviceId: item.serviceId,
      name: item.name,
      description: item.description,
      price: Number(item.price),
      imageUrl: item.imageUrl,
      isActive: item.isActive,
      sortOrder: item.sortOrder,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    };
  }
}
