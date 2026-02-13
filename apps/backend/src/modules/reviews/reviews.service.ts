import {
    Injectable,
    BadRequestException,
    NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import {
    CreateReviewDto,
    ReviewDto,
    ReviewListResponseDto,
    ReviewStatisticsDto,
} from './dto/review.dto';

@Injectable()
export class ReviewsService {
    constructor(private prisma: PrismaService) { }

    async createReview(
        reviewerId: number,
        dto: CreateReviewDto,
    ): Promise<ReviewDto> {
        // Validate reviewer is not reviewing themselves
        if (reviewerId === dto.revieweeId) {
            throw new BadRequestException('Cannot review yourself');
        }

        // Check if booking exists and is completed
        const booking = await this.prisma.booking.findUnique({
            where: { id: BigInt(dto.bookingId) },
        });

        if (!booking) {
            throw new NotFoundException('Booking not found');
        }

        if (booking.status !== 'completed') {
            throw new BadRequestException('Can only review completed bookings');
        }

        // Check if user has already reviewed this booking
        const existingReview = await this.prisma.review.findUnique({
            where: {
                bookingId: BigInt(dto.bookingId),
            },
        });

        if (existingReview) {
            throw new BadRequestException('You have already reviewed this booking');
        }

        // Create review
        const review = await this.prisma.review.create({
            data: {
                bookingId: BigInt(dto.bookingId),
                reviewerId: BigInt(reviewerId),
                revieweeId: BigInt(dto.revieweeId),
                rating: dto.rating,
                title: dto.title || null,
                comment: dto.comment || null,
            },
        });

        return this.mapReviewToDto(review);
    }

    async getReviewsByBooking(bookingId: number): Promise<ReviewDto[]> {
        const reviews = await this.prisma.review.findMany({
            where: { bookingId: BigInt(bookingId) },
            orderBy: { createdAt: 'desc' },
        });

        return reviews.map((r) => this.mapReviewToDto(r));
    }

    async getReviewsForUser(
        userId: number,
        page: number = 1,
        pageSize: number = 10,
    ): Promise<ReviewListResponseDto> {
        const skip = (page - 1) * pageSize;

        const [reviews, total] = await Promise.all([
            this.prisma.review.findMany({
                where: { revieweeId: BigInt(userId) },
                orderBy: { createdAt: 'desc' },
                skip,
                take: pageSize,
            }),
            this.prisma.review.count({
                where: { revieweeId: BigInt(userId) },
            }),
        ]);

        return {
            reviews: reviews.map((r) => this.mapReviewToDto(r)),
            total,
            page,
            pageSize,
        };
    }

    async getReviewsByUser(userId: number): Promise<ReviewDto[]> {
        const reviews = await this.prisma.review.findMany({
            where: { reviewerId: BigInt(userId) },
            orderBy: { createdAt: 'desc' },
        });

        return reviews.map((r) => this.mapReviewToDto(r));
    }

    async getReviewStatistics(userId: number): Promise<ReviewStatisticsDto> {
        const reviews = await this.prisma.review.findMany({
            where: { revieweeId: BigInt(userId) },
        });

        if (reviews.length === 0) {
            return {
                averageRating: 0,
                totalReviews: 0,
                ratingDistribution: { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 },
            };
        }

        const ratings = reviews.map((r) => r.rating);
        const sum = ratings.reduce((a, b) => a + b, 0);
        const averageRating = sum / reviews.length;

        const distribution = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
        ratings.forEach((rating) => {
            distribution[rating]++;
        });

        return {
            averageRating: Math.round(averageRating * 100) / 100,
            totalReviews: reviews.length,
            ratingDistribution: distribution,
        };
    }

    async hasUserReviewedBooking(
        bookingId: number,
        userId: number,
    ): Promise<boolean> {
        const review = await this.prisma.review.findUnique({
            where: { bookingId: BigInt(bookingId) },
        });

        return !!review && review.reviewerId === BigInt(userId);
    }

    async deleteReview(reviewId: number): Promise<void> {
        const review = await this.prisma.review.findUnique({
            where: { id: BigInt(reviewId) },
        });

        if (!review) {
            throw new NotFoundException('Review not found');
        }

        await this.prisma.review.delete({
            where: { id: BigInt(reviewId) },
        });
    }

    private mapReviewToDto(review: {
        id: bigint;
        bookingId: bigint;
        reviewerId: bigint;
        revieweeId: bigint;
        rating: number;
        title: string | null;
        comment: string | null;
        createdAt: Date;
    }): ReviewDto {
        return {
            id: Number(review.id),
            bookingId: Number(review.bookingId),
            reviewerId: Number(review.reviewerId),
            revieweeId: Number(review.revieweeId),
            rating: review.rating,
            title: review.title,
            comment: review.comment,
            createdAt: review.createdAt,
        };
    }
}
