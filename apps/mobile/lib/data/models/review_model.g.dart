// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReviewImpl _$$ReviewImplFromJson(Map<String, dynamic> json) => _$ReviewImpl(
      id: (json['id'] as num).toInt(),
      bookingId: (json['bookingId'] as num).toInt(),
      reviewerId: (json['reviewerId'] as num).toInt(),
      revieweeId: (json['revieweeId'] as num).toInt(),
      rating: (json['rating'] as num).toInt(),
      title: json['title'] as String?,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$ReviewImplToJson(_$ReviewImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bookingId': instance.bookingId,
      'reviewerId': instance.reviewerId,
      'revieweeId': instance.revieweeId,
      'rating': instance.rating,
      'title': instance.title,
      'comment': instance.comment,
      'createdAt': instance.createdAt.toIso8601String(),
    };

_$CreateReviewRequestImpl _$$CreateReviewRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$CreateReviewRequestImpl(
      bookingId: (json['bookingId'] as num).toInt(),
      revieweeId: (json['revieweeId'] as num).toInt(),
      rating: (json['rating'] as num).toInt(),
      title: json['title'] as String?,
      comment: json['comment'] as String?,
    );

Map<String, dynamic> _$$CreateReviewRequestImplToJson(
        _$CreateReviewRequestImpl instance) =>
    <String, dynamic>{
      'bookingId': instance.bookingId,
      'revieweeId': instance.revieweeId,
      'rating': instance.rating,
      'title': instance.title,
      'comment': instance.comment,
    };

_$ReviewListResponseImpl _$$ReviewListResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$ReviewListResponseImpl(
      reviews: (json['reviews'] as List<dynamic>)
          .map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      pageSize: (json['pageSize'] as num).toInt(),
    );

Map<String, dynamic> _$$ReviewListResponseImplToJson(
        _$ReviewListResponseImpl instance) =>
    <String, dynamic>{
      'reviews': instance.reviews,
      'total': instance.total,
      'page': instance.page,
      'pageSize': instance.pageSize,
    };

_$ReviewStatisticsImpl _$$ReviewStatisticsImplFromJson(
        Map<String, dynamic> json) =>
    _$ReviewStatisticsImpl(
      averageRating: (json['averageRating'] as num).toDouble(),
      totalReviews: (json['totalReviews'] as num).toInt(),
      ratingDistribution:
          (json['ratingDistribution'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(int.parse(k), (e as num).toInt()),
      ),
    );

Map<String, dynamic> _$$ReviewStatisticsImplToJson(
        _$ReviewStatisticsImpl instance) =>
    <String, dynamic>{
      'averageRating': instance.averageRating,
      'totalReviews': instance.totalReviews,
      'ratingDistribution':
          instance.ratingDistribution.map((k, e) => MapEntry(k.toString(), e)),
    };
