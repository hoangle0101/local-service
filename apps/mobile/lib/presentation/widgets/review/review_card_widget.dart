import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../../data/models/review_model.dart';
import '../rating/star_rating_bar.dart';

/// ReviewCardWidget - Display a single review
class ReviewCardWidget extends StatelessWidget {
  final Review review;
  final bool isOwnReview;
  final VoidCallback? onDeleteTap;

  const ReviewCardWidget({
    super.key,
    required this.review,
    this.isOwnReview = false,
    this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with reviewer info and rating
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Reviewer avatar and name
                Expanded(
                  child: Row(
                    children: [
                      // Avatar
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.grey200,
                        child: Icon(
                          Icons.person,
                          color: AppColors.grey500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Name and date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User #${review.reviewerId}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(review.createdAt),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Rating and delete button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StarRatingDisplay(
                      rating: review.rating,
                      starSize: 18,
                    ),
                    if (isOwnReview) ...[
                      const SizedBox(height: 8),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            onTap: onDeleteTap,
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.delete_outline,
                                  color: AppColors.error,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                        icon: const Icon(
                          Icons.more_vert,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            if (review.title != null && review.title!.isNotEmpty) ...[
              Text(
                review.title!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
            ],

            // Comment
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              Text(
                review.comment!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],

            // Helpful actions (optional)
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Đánh giá này có hữu ích không?',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Hôm nay';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks tuần trước';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months tháng trước';
    } else {
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    }
  }
}

/// ReviewListWidget - Display a list of reviews with load more
class ReviewListWidget extends StatelessWidget {
  final List<Review> reviews;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback? onLoadMore;
  final VoidCallback? onDeleteReview;

  const ReviewListWidget({
    super.key,
    required this.reviews,
    this.isLoading = false,
    this.hasMore = false,
    this.onLoadMore,
    this.onDeleteReview,
  });

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty && !isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.rate_review_outlined,
                size: 48,
                color: AppColors.grey300,
              ),
              const SizedBox(height: 16),
              Text(
                'No reviews yet',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: reviews.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == reviews.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: onLoadMore,
                      icon: const Icon(Icons.expand_more),
                      label: const Text('Load More Reviews'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                    ),
            ),
          );
        }

        return ReviewCardWidget(
          review: reviews[index],
          onDeleteTap: onDeleteReview,
        );
      },
    );
  }
}
