import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Model class for Review data
class ReviewModel {
  final String id;
  final int rating;
  final String? title;
  final String? comment;
  final DateTime createdAt;
  final ReviewerInfo reviewer;
  final ReviewBookingInfo? booking;

  ReviewModel({
    required this.id,
    required this.rating,
    this.title,
    this.comment,
    required this.createdAt,
    required this.reviewer,
    this.booking,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id']?.toString() ?? '',
      rating: json['rating'] is int
          ? json['rating']
          : int.tryParse(json['rating'].toString()) ?? 5,
      title: json['title'] as String?,
      comment: json['comment'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      reviewer: ReviewerInfo.fromJson(json['reviewer'] ?? {}),
      booking: json['booking'] != null
          ? ReviewBookingInfo.fromJson(json['booking'])
          : null,
    );
  }
}

class ReviewerInfo {
  final String id;
  final String? fullName;
  final String? avatarUrl;

  ReviewerInfo({required this.id, this.fullName, this.avatarUrl});

  factory ReviewerInfo.fromJson(Map<String, dynamic> json) {
    // API returns: { id: "1", profile: { fullName: "...", avatarUrl: "..." } }
    final profile = json['profile'] as Map<String, dynamic>?;
    return ReviewerInfo(
      id: json['id']?.toString() ?? '',
      fullName: profile?['fullName'] as String? ?? json['fullName'] as String?,
      avatarUrl:
          profile?['avatarUrl'] as String? ?? json['avatarUrl'] as String?,
    );
  }
}

class ReviewBookingInfo {
  final String id;
  final ReviewServiceInfo? service;

  ReviewBookingInfo({required this.id, this.service});

  factory ReviewBookingInfo.fromJson(Map<String, dynamic> json) {
    return ReviewBookingInfo(
      id: json['id']?.toString() ?? '',
      service: json['service'] != null
          ? ReviewServiceInfo.fromJson(json['service'])
          : null,
    );
  }
}

class ReviewServiceInfo {
  final int id;
  final String name;

  ReviewServiceInfo({required this.id, required this.name});

  factory ReviewServiceInfo.fromJson(Map<String, dynamic> json) {
    return ReviewServiceInfo(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}

/// Model for review statistics/summary
class ReviewStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // 1-5 star counts

  ReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  /// Calculate percentage for each rating
  double getPercentage(int stars) {
    if (totalReviews == 0) return 0;
    return (ratingDistribution[stars] ?? 0) / totalReviews * 100;
  }
}

/// Data source for review-related API calls
class ReviewsDataSource {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ReviewsDataSource() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'http://10.0.2.2:3000',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  /// Get reviews for a specific provider
  Future<Map<String, dynamic>> getProviderReviews(
    String providerId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('[ReviewsDataSource] Fetching reviews for provider: $providerId');
      final response = await _dio.get(
        '/marketplace/providers/$providerId/reviews',
        queryParameters: {'page': page, 'limit': limit},
      );

      print('[ReviewsDataSource] Response: ${response.data}');

      // Handle nested response: {statusCode, message, data: {reviews: [...], meta: {...}}}
      var responseData = response.data;
      if (responseData is Map && responseData.containsKey('data')) {
        responseData = responseData['data'];
      }

      final List<dynamic> reviewsJson = responseData['reviews'] ?? [];

      print('[ReviewsDataSource] Found ${reviewsJson.length} reviews');

      final reviews = reviewsJson.map((json) {
        print('[ReviewsDataSource] Parsing review: $json');
        return ReviewModel.fromJson(json as Map<String, dynamic>);
      }).toList();

      return {
        'reviews': reviews,
        'meta': responseData['meta'] ??
            {'total': reviews.length, 'page': 1, 'limit': 20, 'totalPages': 1},
      };
    } catch (e) {
      print('[ReviewsDataSource] Error fetching provider reviews: $e');
      throw Exception('Failed to load reviews: $e');
    }
  }

  /// Get provider details including rating info
  Future<Map<String, dynamic>> getProviderDetails(String providerId) async {
    try {
      final response = await _dio.get('/marketplace/providers/$providerId');
      return response.data;
    } catch (e) {
      print('[ReviewsDataSource] Error fetching provider details: $e');
      throw Exception('Failed to load provider details: $e');
    }
  }
}
