import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  UseGuards,
  ParseIntPipe,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiTags,
  ApiParam,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { ProviderServiceItemsService } from './provider-service-items.service';
import {
  CreateServiceItemDto,
  UpdateServiceItemDto,
} from './dto/service-item.dto';

@ApiTags('Provider Service Items')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('provider')
@Controller('provider/services')
export class ProviderServiceItemsController {
  constructor(private readonly service: ProviderServiceItemsService) {}

  @Get(':serviceId/items')
  @ApiOperation({ summary: 'Get all items for a service' })
  @ApiParam({ name: 'serviceId', example: 1 })
  async getItems(
    @CurrentUser() user: any,
    @Param('serviceId', ParseIntPipe) serviceId: number,
  ) {
    return this.service.getItems(BigInt(user.userId), serviceId);
  }

  @Post(':serviceId/items')
  @ApiOperation({ summary: 'Create a new service item' })
  @ApiParam({ name: 'serviceId', example: 1 })
  async createItem(
    @CurrentUser() user: any,
    @Param('serviceId', ParseIntPipe) serviceId: number,
    @Body() dto: CreateServiceItemDto,
  ) {
    return this.service.createItem(BigInt(user.userId), serviceId, dto);
  }

  @Patch('items/:itemId')
  @ApiOperation({ summary: 'Update a service item' })
  @ApiParam({ name: 'itemId', example: 1 })
  async updateItem(
    @CurrentUser() user: any,
    @Param('itemId') itemId: string,
    @Body() dto: UpdateServiceItemDto,
  ) {
    return this.service.updateItem(BigInt(user.userId), BigInt(itemId), dto);
  }

  @Delete('items/:itemId')
  @ApiOperation({ summary: 'Delete a service item' })
  @ApiParam({ name: 'itemId', example: 1 })
  async deleteItem(@CurrentUser() user: any, @Param('itemId') itemId: string) {
    return this.service.deleteItem(BigInt(user.userId), BigInt(itemId));
  }

  @Post(':serviceId/items/reorder')
  @ApiOperation({ summary: 'Reorder service items' })
  @ApiParam({ name: 'serviceId', example: 1 })
  async reorderItems(
    @CurrentUser() user: any,
    @Param('serviceId', ParseIntPipe) serviceId: number,
    @Body('itemIds') itemIds: string[],
  ) {
    return this.service.reorderItems(BigInt(user.userId), serviceId, itemIds);
  }
}

// Public controller for customers to view items
@ApiTags('Service Items')
@Controller('services')
export class PublicServiceItemsController {
  constructor(private readonly service: ProviderServiceItemsService) {}

  @Get(':serviceId/provider/:providerId/items')
  @ApiOperation({ summary: 'Get public items for a provider service' })
  @ApiParam({ name: 'serviceId', example: 1 })
  @ApiParam({ name: 'providerId', example: 1 })
  async getPublicItems(
    @Param('serviceId', ParseIntPipe) serviceId: number,
    @Param('providerId') providerId: string,
  ) {
    console.log(
      `[PublicServiceItems] GET /services/${serviceId}/provider/${providerId}/items`,
    );
    const result = await this.service.getPublicItems(
      BigInt(providerId),
      serviceId,
    );
    console.log(`[PublicServiceItems] Returning ${result.length} items`);
    return result;
  }
}
