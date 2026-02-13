import {
    Controller,
    Get,
    Post,
    Delete,
    Param,
    Query,
    UseGuards,
    ParseIntPipe,
} from '@nestjs/common';
import {
    ApiTags,
    ApiOperation,
    ApiBearerAuth,
    ApiParam,
} from '@nestjs/swagger';
import { FavoritesService } from './favorites.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('Favorites')
@Controller('favorites')
@ApiBearerAuth()
export class FavoritesController {
    constructor(private favoritesService: FavoritesService) { }

    @Post('provider/:providerId')
    @UseGuards(JwtAuthGuard)
    @ApiOperation({ summary: 'Add provider to favorites' })
    @ApiParam({ name: 'providerId', example: 5 })
    async addFavoriteProvider(
        @CurrentUser() user: any,
        @Param('providerId', ParseIntPipe) providerId: number,
    ) {
        console.log('[FavoritesController] addFavoriteProvider - user:', user);
        console.log('[FavoritesController] addFavoriteProvider - providerId:', providerId);

        return this.favoritesService.addFavoriteProvider(
            BigInt(user.userId),
            BigInt(providerId),
        );
    }

    @Delete('provider/:providerId')
    @UseGuards(JwtAuthGuard)
    @ApiOperation({ summary: 'Remove provider from favorites' })
    @ApiParam({ name: 'providerId', example: 5 })
    async removeFavoriteProvider(
        @CurrentUser() user: any,
        @Param('providerId', ParseIntPipe) providerId: number,
    ) {
        console.log('[FavoritesController] removeFavoriteProvider - user:', user);
        console.log('[FavoritesController] removeFavoriteProvider - providerId:', providerId);

        return this.favoritesService.removeFavoriteProvider(
            BigInt(user.userId),
            BigInt(providerId),
        );
    }

    @Get('providers')
    @UseGuards(JwtAuthGuard)
    @ApiOperation({ summary: 'Get list of favorite providers' })
    async getFavoriteProviders(
        @CurrentUser() user: any,
        @Query('page') page?: number,
        @Query('limit') limit?: number,
    ) {
        console.log('[FavoritesController] getFavoriteProviders - user:', user);

        return this.favoritesService.getFavoriteProviders(
            BigInt(user.userId),
            page,
            limit,
        );
    }

    @Get('check/provider/:providerId')
    @UseGuards(JwtAuthGuard)
    @ApiOperation({ summary: 'Check if provider is in favorites' })
    @ApiParam({ name: 'providerId', example: 5 })
    async checkFavoriteProvider(
        @CurrentUser() user: any,
        @Param('providerId', ParseIntPipe) providerId: number,
    ) {
        console.log('[FavoritesController] checkFavoriteProvider - user:', user);
        console.log('[FavoritesController] checkFavoriteProvider - providerId:', providerId);

        return this.favoritesService.checkFavoriteProvider(
            BigInt(user.userId),
            BigInt(providerId),
        );
    }
}
