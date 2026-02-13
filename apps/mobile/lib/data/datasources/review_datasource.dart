import 'package:dio/dio.dart';
import '../models/review_model.dart';

/// ReviewDataSource - Handles all API calls related to reviews
class ReviewDataSource {
  final Dio dio;
  static const String _baseUrl = '/api/reviews';

  ReviewDataSource({required this.dio});

  /// Create a new review for a booking
  /// POST /api/reviews/bookings/{bookingId}
  Future<Review> createReview(CreateReviewRequest request) async {
    try {
      final response = await dio.post(
        '$_baseUrl/bookings/${request.bookingId}',
        data: request.toJson(),
      );
      return Review.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get all reviews for a specific booking
  /// GET /api/reviews/bookings/{bookingId}
  Future<List<Review>> getReviewsByBooking(int bookingId) async {
    try {
      final response = await dio.get(
        '$_baseUrl/bookings/$bookingId',
      );
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data
          .map((review) => Review.fromJson(review as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get reviews for a specific user (as reviewee - reviews received)
  /// GET /api/reviews/users/{userId}/received?page=1&pageSize=10
  Future<ReviewListResponse> getReviewsForUser(
    int userId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await dio.get(
        '$_baseUrl/users/$userId/received',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      final data = response.data['data'] ?? response.data;
      return ReviewListResponse.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get reviews given by a specific user (as reviewer)
  /// GET /api/reviews/users/{userId}/given
  Future<List<Review>> getReviewsByUser(int userId) async {
    try {
      final response = await dio.get(
        '$_baseUrl/users/$userId/given',
      );
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data
          .map((review) => Review.fromJson(review as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get review statistics for a user (provider profile)
  /// GET /api/reviews/users/{userId}/statistics
  Future<ReviewStatistics> getReviewStatistics(int userId) async {
    try {
      final response = await dio.get(
        '$_baseUrl/users/$userId/statistics',
      );
      final data = response.data['data'] ?? response.data;
      return ReviewStatistics.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Check if a user already reviewed a booking
  /// GET /api/reviews/bookings/{bookingId}/user/{userId}/has-reviewed
  Future<bool> hasUserReviewedBooking(
    int bookingId,
    int userId,
  ) async {
    try {
      final response = await dio.get(
        '$_baseUrl/bookings/$bookingId/user/$userId/has-reviewed',
      );
      final data = response.data['data'] ?? response.data;
      return data is Map ? (data['hasReviewed'] ?? false) : false;
    } on DioException catch (e) {
      // 404 means not reviewed, return false instead of error
      if (e.response?.statusCode == 404) {
        return false;
      }
      throw _handleDioError(e);
    }
  }

  /// Delete a review (only by reviewer)
  /// DELETE /api/reviews/{reviewId}
  Future<void> deleteReview(int reviewId) async {
    try {
      await dio.delete(
        '$_baseUrl/$reviewId',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get provider statistics (rating, reviewCount, completedCount)
  /// GET /api/reviews/users/{userId}/statistics
  Future<Map<String, dynamic>> getProviderStatistics(int userId) async {
    try {
      final response = await dio.get(
        '$_baseUrl/users/$userId/statistics',
      );
      return (response.data['data'] ?? response.data) as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Handle Dio errors and convert to custom exceptions
  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return Exception('Connection timeout. Please try again.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data['message'] ??
            error.response?.data['error'] ??
            'Error: $statusCode';
        return Exception(message);
      case DioExceptionType.cancel:
        return Exception('Request was cancelled');
      case DioExceptionType.badCertificate:
        return Exception('SSL certificate error');
      default:
        return Exception('Network error: ${error.message}');
    }
  }
}
