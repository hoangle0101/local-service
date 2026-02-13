import { Controller, Get, Param, Query, ParseIntPipe } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiParam, ApiQuery } from '@nestjs/swagger';
import { MarketplaceService } from './marketplace.service';
import { ServiceSearchDto, PaginationDto } from './dto/marketplace.dto';

@ApiTags('Marketplace')
@Controller('marketplace')
export class MarketplaceController {
  constructor(private marketplaceService: MarketplaceService) {}

  @Get('categories')
  @ApiOperation({ summary: 'Get all service categories' })
  async getCategories() {
    return this.marketplaceService.getCategories();
  }

  @Get('categories/:categoryId/services')
  @ApiOperation({ summary: 'Get generic services by category ID' })
  @ApiParam({ name: 'categoryId', example: 1 })
  async getGenericServicesByCategory(
    @Param('categoryId', ParseIntPipe) categoryId: number,
  ) {
    return this.marketplaceService.getGenericServicesByCategory(categoryId);
  }

  @Get('categories/:slug')
  @ApiOperation({ summary: 'Get category by slug' })
  @ApiParam({ name: 'slug', example: 'home-cleaning' })
  async getCategoryBySlug(@Param('slug') slug: string) {
    return this.marketplaceService.getCategoryBySlug(slug);
  }

  @Get('services/search')
  @ApiOperation({ summary: 'Search services with filters' })
  async searchServices(@Query() dto: ServiceSearchDto) {
    return this.marketplaceService.searchServices(dto);
  }

  @Get('services/:id')
  @ApiOperation({ summary: 'Get provider service details by ID' })
  @ApiParam({ name: 'id', example: '1' })
  async getServiceById(@Param('id') id: string) {
    return this.marketplaceService.getProviderServiceById(id);
  }

  @Get('providers/:id')
  @ApiOperation({ summary: 'Get provider details' })
  @ApiParam({ name: 'id', example: '1' })
  async getProviderById(@Param('id') id: string) {
    return this.marketplaceService.getProviderById(id);
  }

  @Get('providers/:id/reviews')
  @ApiOperation({ summary: 'Get provider reviews' })
  @ApiParam({ name: 'id', example: '1' })
  async getProviderReviews(
    @Param('id') id: string,
    @Query() pagination: PaginationDto,
  ) {
    return this.marketplaceService.getProviderReviews(id, pagination);
  }
}
