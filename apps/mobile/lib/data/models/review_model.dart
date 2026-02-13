import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'review_model.freezed.dart';
part 'review_model.g.dart';

/// Review model - represents a user review for a service booking
/// Maps to backend Review model
@freezed
class Review with _$Review {
  const factory Review({
    required int id,
    required int bookingId,
    required int reviewerId,
    required int revieweeId,
    required int rating, // 1-5 stars
    String? title,
    String? comment,
    required DateTime createdAt,
  }) = _Review;

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);
}

/// DTO for creating a new review
/// Sent from frontend to backend
@freezed
class CreateReviewRequest with _$CreateReviewRequest {
  const factory CreateReviewRequest({
    required int bookingId,
    required int revieweeId,
    required int rating,
    String? title,
    String? comment,
  }) = _CreateReviewRequest;

  factory CreateReviewRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateReviewRequestFromJson(json);
}

/// DTO for review list response from backend
@freezed
class ReviewListResponse with _$ReviewListResponse {
  const factory ReviewListResponse({
    required List<Review> reviews,
    required int total,
    required int page,
    required int pageSize,
  }) = _ReviewListResponse;

  factory ReviewListResponse.fromJson(Map<String, dynamic> json) =>
      _$ReviewListResponseFromJson(json);
}

/// Summary statistics for reviews
@freezed
class ReviewStatistics with _$ReviewStatistics {
  const factory ReviewStatistics({
    required double averageRating,
    required int totalReviews,
    required Map<int, int> ratingDistribution, // rating -> count
  }) = _ReviewStatistics;

  factory ReviewStatistics.fromJson(Map<String, dynamic> json) =>
      _$ReviewStatisticsFromJson(json);
}
