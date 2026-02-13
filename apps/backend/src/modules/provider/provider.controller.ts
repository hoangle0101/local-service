import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  UseGuards,
  ParseIntPipe,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiParam,
  ApiConsumes,
  ApiBody,
} from '@nestjs/swagger';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { ProviderService } from './provider.service';
import {
  OnboardingDto,
  UpdateProviderProfileDto,
  UpdateAvailabilityDto,
  AddServiceDto,
  UpdateProviderServiceDto,
  UpdateLocationDto,
} from './dto/provider.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { ProviderVerifiedGuard } from '../../common/guards/provider-verified.guard';

// Multer configuration for avatar upload
// Use process.cwd() to match static serving path in main.ts
const uploadPath = join(process.cwd(), 'uploads', 'avatars');
const avatarStorage = diskStorage({
  destination: (req, file, callback) => {
    // Ensure directory exists
    const fs = require('fs');
    if (!fs.existsSync(uploadPath)) {
      fs.mkdirSync(uploadPath, { recursive: true });
    }
    console.log('[Multer] Saving avatar to:', uploadPath);
    callback(null, uploadPath);
  },
  filename: (req, file, callback) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    const ext = extname(file.originalname);
    const filename = `avatar-${uniqueSuffix}${ext}`;
    console.log('[Multer] Avatar filename:', filename);
    callback(null, filename);
  },
});

const imageFileFilter = (req: any, file: any, callback: any) => {
  if (!file.mimetype.match(/\/(jpg|jpeg|png|gif|webp)$/)) {
    return callback(
      new BadRequestException('Only image files are allowed!'),
      false,
    );
  }
  callback(null, true);
};

@ApiTags('Provider')
@Controller('provider')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ProviderController {
  constructor(private providerService: ProviderService) {}

  @Post('onboarding')
  @ApiOperation({ summary: 'Register as provider' })
  async onboarding(@CurrentUser() user: any, @Body() dto: OnboardingDto) {
    return this.providerService.onboarding(BigInt(user.userId), dto);
  }

  @Get('me')
  @UseGuards(RolesGuard)
  @Roles('provider')
  @ApiOperation({ summary: 'Get provider profile' })
  async getProfile(@CurrentUser() user: any) {
    return this.providerService.getProfile(BigInt(user.userId));
  }

  @Patch('me')
  @UseGuards(RolesGuard)
  @Roles('provider')
  @ApiOperation({ summary: 'Update provider profile' })
  async updateProfile(
    @CurrentUser() user: any,
    @Body() dto: UpdateProviderProfileDto,
  ) {
    return this.providerService.updateProfile(BigInt(user.userId), dto);
  }

  @Post('me/avatar')
  @UseGuards(RolesGuard)
  @Roles('provider')
  @UseInterceptors(
    FileInterceptor('avatar', {
      storage: avatarStorage,
      fileFilter: imageFileFilter,
      limits: {
        fileSize: 5 * 1024 * 1024, // 5MB max
      },
    }),
  )
  @ApiOperation({ summary: 'Upload provider avatar' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        avatar: {
          type: 'string',
          format: 'binary',
        },
      },
    },
  })
  async uploadAvatar(
    @CurrentUser() user: any,
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException('No file uploaded');
    }
    return this.providerService.updateAvatar(
      BigInt(user.userId),
      `/uploads/avatars/${file.filename}`,
    );
  }

  @Patch('me/availability')
  @UseGuards(RolesGuard, ProviderVerifiedGuard)
  @Roles('provider')
  @ApiOperation({ summary: 'Update availability status' })
  async updateAvailability(
    @CurrentUser() user: any,
    @Body() dto: UpdateAvailabilityDto,
  ) {
    return this.providerService.updateAvailability(BigInt(user.userId), dto);
  }

  @Get('services')
  @UseGuards(RolesGuard)
  @Roles('provider')
  @ApiOperation({ summary: 'Get provider services' })
  async getServices(@CurrentUser() user: any) {
    return this.providerService.getServices(BigInt(user.userId));
  }

  @Post('services')
  @UseGuards(RolesGuard, ProviderVerifiedGuard)
  @Roles('provider')
  @ApiOperation({ summary: 'Add service to provider' })
  async addService(@CurrentUser() user: any, @Body() dto: AddServiceDto) {
    return this.providerService.addService(BigInt(user.userId), dto);
  }

  @Patch('services/:serviceId')
  @UseGuards(RolesGuard, ProviderVerifiedGuard)
  @Roles('provider')
  @ApiOperation({ summary: 'Update provider service' })
  @ApiParam({ name: 'serviceId', example: 1 })
  async updateService(
    @CurrentUser() user: any,
    @Param('serviceId', ParseIntPipe) serviceId: number,
    @Body() dto: UpdateProviderServiceDto,
  ) {
    return this.providerService.updateService(
      BigInt(user.userId),
      serviceId,
      dto,
    );
  }

  @Delete('services/:serviceId')
  @UseGuards(RolesGuard)
  @Roles('provider')
  @ApiOperation({ summary: 'Remove service from provider' })
  @ApiParam({ name: 'serviceId', example: 1 })
  async removeService(
    @CurrentUser() user: any,
    @Param('serviceId', ParseIntPipe) serviceId: number,
  ) {
    return this.providerService.removeService(BigInt(user.userId), serviceId);
  }

  @Get('statistics')
  @UseGuards(RolesGuard)
  @Roles('provider')
  @ApiOperation({ summary: 'Get provider statistics' })
  async getStatistics(@CurrentUser() user: any) {
    return this.providerService.getStatistics(BigInt(user.userId));
  }

  @Patch('me/location')
  @UseGuards(RolesGuard)
  @Roles('provider')
  @ApiOperation({ summary: 'Update provider location (GPS coordinates)' })
  async updateLocation(
    @CurrentUser() user: any,
    @Body() dto: UpdateLocationDto,
  ) {
    return this.providerService.updateLocation(
      BigInt(user.userId),
      dto.latitude,
      dto.longitude,
      dto.addressText,
    );
  }
}
