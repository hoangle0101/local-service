import '../datasources/review_datasource.dart';
import '../models/review_model.dart';

/// ReviewRepository - Manages business logic for reviews
class ReviewRepository {
  final ReviewDataSource dataSource;

  ReviewRepository({required this.dataSource});

  /// Submit a new review for a booking
  /// Returns the created review
  Future<Review> submitReview(CreateReviewRequest request) async {
    // Validate input
    if (request.rating < 1 || request.rating > 5) {
      throw ArgumentError('Rating must be between 1 and 5');
    }
    if (request.title == null || request.title!.isEmpty) {
      throw ArgumentError('Review title cannot be empty');
    }
    if ((request.comment ?? '').length > 500) {
      throw ArgumentError('Comment cannot exceed 500 characters');
    }

    return await dataSource.createReview(request);
  }

  /// Get all reviews for a booking with their details
  Future<List<Review>> getBookingReviews(int bookingId) async {
    return await dataSource.getReviewsByBooking(bookingId);
  }

  /// Get paginated reviews received by a user (provider's reviews)
  Future<ReviewListResponse> getUserReceivedReviews(
    int userId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    return await dataSource.getReviewsForUser(
      userId,
      page: page,
      pageSize: pageSize,
    );
  }

  /// Get all reviews given by a user
  Future<List<Review>> getUserGivenReviews(int userId) async {
    return await dataSource.getReviewsByUser(userId);
  }

  /// Get average rating and statistics for a provider
  Future<ReviewStatistics> getProviderStatistics(int providerId) async {
    return await dataSource.getReviewStatistics(providerId);
  }

  /// Check if user already reviewed the booking
  Future<bool> hasUserReviewedBooking(int bookingId, int userId) async {
    return await dataSource.hasUserReviewedBooking(bookingId, userId);
  }

  /// Delete user's review (only allowed for reviewer)
  Future<void> removeReview(int reviewId) async {
    return await dataSource.deleteReview(reviewId);
  }

  /// Calculate display rating (0-5 with 0 decimal places)
  static String formatRating(double rating) {
    return rating.toStringAsFixed(1);
  }

  /// Get star distribution for display (e.g., "4.5 out of 5")
  static String getRatingText(double rating, int totalReviews) {
    if (totalReviews == 0) return 'No reviews yet';
    return '$rating out of 5 ($totalReviews ${totalReviews == 1 ? 'review' : 'reviews'})';
  }
}
