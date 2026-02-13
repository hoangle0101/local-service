import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
  Query,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import {
  AddressDto,
  ChangePasswordDto,
  DeviceDto,
  FavoriteDto,
  UpdateProfileDto,
} from './dto/user.dto';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';

@ApiTags('Users')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('users')
export class UserController {
  constructor(private usersService: UsersService) {}

  @Get('me')
  @ApiOperation({ summary: 'Get my profile' })
  async getProfile(@CurrentUser() user: any) {
    return this.usersService.getProfile(BigInt(user.userId));
  }

  @Patch('me/profile')
  @ApiOperation({ summary: 'Update profile' })
  async updateProfile(@CurrentUser() user: any, @Body() dto: UpdateProfileDto) {
    return this.usersService.updateProfile(BigInt(user.userId), dto);
  }

  @Patch('me/password')
  @ApiOperation({ summary: 'Change password' })
  async changePassword(
    @CurrentUser() user: any,
    @Body() dto: ChangePasswordDto,
  ) {
    return this.usersService.changePassword(BigInt(user.userId), dto);
  }

  @Get('me/addresses')
  @ApiOperation({ summary: 'List addresses' })
  async getAddresses(@CurrentUser() user: any) {
    return this.usersService.getAddresses(BigInt(user.userId));
  }

  @Post('me/addresses')
  @ApiOperation({ summary: 'Add address' })
  async addAddress(@CurrentUser() user: any, @Body() dto: AddressDto) {
    return this.usersService.addAddress(BigInt(user.userId), dto);
  }

  @Patch('me/addresses/:id')
  @ApiOperation({ summary: 'Update address' })
  async updateAddress(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() dto: AddressDto,
  ) {
    return this.usersService.updateAddress(
      BigInt(user.userId),
      BigInt(id),
      dto,
    );
  }

  @Delete('me/addresses/:id')
  @ApiOperation({ summary: 'Delete address' })
  async deleteAddress(@CurrentUser() user: any, @Param('id') id: string) {
    return this.usersService.deleteAddress(BigInt(user.userId), BigInt(id));
  }

  @Get('me/favorites')
  @ApiOperation({ summary: 'List favorites' })
  async getFavorites(@CurrentUser() user: any) {
    return this.usersService.getFavorites(BigInt(user.userId));
  }

  @Post('me/favorites')
  @ApiOperation({ summary: 'Add favorite' })
  async addFavorite(@CurrentUser() user: any, @Body() dto: FavoriteDto) {
    return this.usersService.addFavorite(BigInt(user.userId), dto);
  }

  @Delete('me/favorites/:id')
  @ApiOperation({ summary: 'Remove favorite' })
  async removeFavorite(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Query('targetType') targetType: string,
  ) {
    const type = targetType || 'provider_service';
    return this.usersService.removeFavoriteComposite(
      BigInt(user.userId),
      BigInt(id),
      type,
    );
  }

  @Get('me/notifications')
  @ApiOperation({ summary: 'List notifications' })
  async getNotifications(@CurrentUser() user: any) {
    return this.usersService.getNotifications(BigInt(user.userId));
  }

  @Patch('me/notifications/read-all')
  @ApiOperation({ summary: 'Mark all notifications as read' })
  async readAllNotifications(@CurrentUser() user: any) {
    return this.usersService.readAllNotifications(BigInt(user.userId));
  }

  @Post('me/devices')
  @ApiOperation({ summary: 'Register FCM token' })
  async registerDevice(@CurrentUser() user: any, @Body() dto: DeviceDto) {
    return this.usersService.registerDevice(BigInt(user.userId), dto);
  }
}
