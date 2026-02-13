import {
    IsInt,
    IsNotEmpty,
    IsOptional,
    IsString,
    Max,
    Min,
    MaxLength,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateReviewDto {
    @ApiProperty({ description: 'Booking ID' })
    @IsNotEmpty()
    @IsInt()
    bookingId: number;

    @ApiProperty({ description: 'Reviewee (provider) ID' })
    @IsNotEmpty()
    @IsInt()
    revieweeId: number;

    @ApiProperty({ description: 'Rating from 1 to 5', minimum: 1, maximum: 5 })
    @IsNotEmpty()
    @IsInt()
    @Min(1)
    @Max(5)
    rating: number;

    @ApiProperty({ description: 'Review title', maxLength: 255 })
    @IsOptional()
    @IsString()
    @MaxLength(255)
    title?: string;

    @ApiProperty({ description: 'Review comment', maxLength: 5000 })
    @IsOptional()
    @IsString()
    @MaxLength(5000)
    comment?: string;
}

export class ReviewDto {
    @ApiProperty()
    id: number;

    @ApiProperty()
    bookingId: number;

    @ApiProperty()
    reviewerId: number;

    @ApiProperty()
    revieweeId: number;

    @ApiProperty()
    rating: number;

    @ApiProperty({ nullable: true })
    title: string | null;

    @ApiProperty({ nullable: true })
    comment: string | null;

    @ApiProperty()
    createdAt: Date;
}

export class ReviewListResponseDto {
    @ApiProperty({ type: [ReviewDto] })
    reviews: ReviewDto[];

    @ApiProperty()
    total: number;

    @ApiProperty()
    page: number;

    @ApiProperty()
    pageSize: number;
}

export class ReviewStatisticsDto {
    @ApiProperty()
    averageRating: number;

    @ApiProperty()
    totalReviews: number;

    @ApiProperty()
    ratingDistribution: {
        1: number;
        2: number;
        3: number;
        4: number;
        5: number;
    };
}
