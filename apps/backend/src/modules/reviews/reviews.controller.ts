import {
    Controller,
    Post,
    Get,
    Delete,
    Body,
    Param,
    Query,
    UseGuards,
    Request,
    ParseIntPipe,
} from '@nestjs/common';
import {
    ApiTags,
    ApiOperation,
    ApiResponse,
    ApiBearerAuth,
} from '@nestjs/swagger';
import { ReviewsService } from './reviews.service';
import {
    CreateReviewDto,
    ReviewDto,
    ReviewListResponseDto,
    ReviewStatisticsDto,
} from './dto/review.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@ApiTags('reviews')
@Controller('api/reviews')
export class ReviewsController {
    constructor(private readonly reviewsService: ReviewsService) { }

    @Post('bookings/:bookingId')
    @UseGuards(JwtAuthGuard)
    @ApiBearerAuth()
    @ApiOperation({ summary: 'Create a review for a booking' })
    @ApiResponse({ status: 201, type: ReviewDto })
    async createReview(
        @Param('bookingId') bookingId: number,
        @Body() dto: CreateReviewDto,
        @Request() req: { user: { id: number } },
    ): Promise<ReviewDto> {
        const reviewerId = req.user.id;
        return this.reviewsService.createReview(reviewerId, dto);
    }

    @Get('bookings/:bookingId')
    @ApiOperation({ summary: 'Get reviews for a specific booking' })
    @ApiResponse({ status: 200, type: [ReviewDto] })
    async getReviewsByBooking(
        @Param('bookingId') bookingId: number,
    ): Promise<ReviewDto[]> {
        return this.reviewsService.getReviewsByBooking(bookingId);
    }

    @Get('users/:userId/received')
    @ApiOperation({ summary: 'Get reviews received by a user (as provider)' })
    @ApiResponse({ status: 200, type: ReviewListResponseDto })
    async getReviewsForUser(
        @Param('userId') userId: number,
        @Query('page') page: number = 1,
        @Query('pageSize') pageSize: number = 10,
    ): Promise<ReviewListResponseDto> {
        return this.reviewsService.getReviewsForUser(userId, page, pageSize);
    }

    @Get('users/:userId/given')
    @ApiOperation({ summary: 'Get reviews given by a user (as customer)' })
    @ApiResponse({ status: 200, type: [ReviewDto] })
    async getReviewsByUser(
        @Param('userId') userId: number,
    ): Promise<ReviewDto[]> {
        return this.reviewsService.getReviewsByUser(userId);
    }

    @Get('users/:userId/statistics')
    @ApiOperation({ summary: 'Get review statistics for a user' })
    @ApiResponse({ status: 200, type: ReviewStatisticsDto })
    async getReviewStatistics(
        @Param('userId', ParseIntPipe) userId: number,
    ): Promise<ReviewStatisticsDto> {
        return this.reviewsService.getReviewStatistics(userId);
    }

    @Get('bookings/:bookingId/user/:userId/has-reviewed')
    @ApiOperation({ summary: 'Check if user has reviewed a booking' })
    @ApiResponse({ status: 200, type: Boolean })
    async hasUserReviewedBooking(
        @Param('bookingId') bookingId: number,
        @Param('userId') userId: number,
    ): Promise<boolean> {
        return this.reviewsService.hasUserReviewedBooking(bookingId, userId);
    }

    @Delete(':reviewId')
    @UseGuards(JwtAuthGuard)
    @ApiBearerAuth()
    @ApiOperation({ summary: 'Delete a review' })
    @ApiResponse({ status: 200 })
    async deleteReview(@Param('reviewId') reviewId: number): Promise<void> {
        return this.reviewsService.deleteReview(reviewId);
    }
}
