import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ServicesService } from './services.service';
import {
  CreateCategoryDto,
  UpdateCategoryDto,
  CreateServiceDto,
  UpdateServiceDto,
  SearchServiceDto,
} from './dto/services.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';

@ApiTags('Services & Categories')
@Controller('services')
export class ServicesController {
  constructor(private servicesService: ServicesService) { }


  // ==================== CATEGORY ENDPOINTS ====================

  @Get('categories')
  @ApiOperation({ summary: 'Get all categories (tree structure)' })
  async getCategories() {
    return this.servicesService.getCategories();
  }

  @Get('categories/:id')
  @ApiOperation({ summary: 'Get category by ID' })
  async getCategoryById(@Param('id') id: string) {
    return this.servicesService.getCategoryById(parseInt(id));
  }

  @Post('categories')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin', 'super_admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Admin: Create category' })
  async createCategory(@Body() dto: CreateCategoryDto) {
    return this.servicesService.createCategory(dto);
  }

  @Put('categories/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin', 'super_admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Admin: Update category' })
  async updateCategory(
    @Param('id') id: string,
    @Body() dto: UpdateCategoryDto,
  ) {
    return this.servicesService.updateCategory(parseInt(id), dto);
  }

  @Delete('categories/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin', 'super_admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Admin: Delete category' })
  async deleteCategory(@Param('id') id: string) {
    return this.servicesService.deleteCategory(parseInt(id));
  }
  // ==================== SERVICE ENDPOINTS ====================

  @Get('search')
  @ApiOperation({ summary: 'Search services' })
  async searchServices(@Query() dto: SearchServiceDto) {
    return this.servicesService.searchServices(dto);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get service by ID' })
  async getServiceById(@Param('id') id: string) {
    return this.servicesService.getServiceById(parseInt(id));
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin', 'super_admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Admin: Create service' })
  async createService(@Body() dto: CreateServiceDto) {
    return this.servicesService.createService(dto);
  }

  @Put(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin', 'super_admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Admin: Update service' })
  async updateService(@Param('id') id: string, @Body() dto: UpdateServiceDto) {
    return this.servicesService.updateService(parseInt(id), dto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin', 'super_admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Admin: Delete service' })
  async deleteService(@Param('id') id: string) {
    return this.servicesService.deleteService(parseInt(id));
  }
}
