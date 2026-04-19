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
