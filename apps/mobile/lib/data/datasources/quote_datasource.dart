import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage.dart';

class QuoteDataSource {
  final Dio _dio;

  QuoteDataSource()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'http://10.0.2.2:3000',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await SecureStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Provider creates a quote for a booking
  Future<Map<String, dynamic>> createQuote({
    required String bookingId,
    required String diagnosis,
    required List<Map<String, dynamic>> items,
    required int laborCost,
    int? surcharge,
    String? warranty,
    int? estimatedTime,
    List<String>? images,
    String? notes,
    String? providerNotes, // Notes about changes from customer selection
  }) async {
    try {
      final response = await _dio.post(
        '/bookings/$bookingId/quotes',
        data: {
          'diagnosis': diagnosis,
          'items': items,
          'laborCost': laborCost,
          if (surcharge != null && surcharge > 0) 'surcharge': surcharge,
          if (warranty != null) 'warranty': warranty,
          if (estimatedTime != null) 'estimatedTime': estimatedTime,
          if (images != null && images.isNotEmpty) 'images': images,
          if (notes != null) 'notes': notes,
          if (providerNotes != null) 'providerNotes': providerNotes,
        },
        options: Options(headers: await _getAuthHeaders()),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to create quote');
    }
  }

  /// Get quotes for a booking
  Future<List<Map<String, dynamic>>> getQuotesForBooking(
      String bookingId) async {
    debugPrint('[QuoteDS] Calling GET /bookings/$bookingId/quotes');
    try {
      final response = await _dio.get(
        '/bookings/$bookingId/quotes',
        options: Options(headers: await _getAuthHeaders()),
      );
      debugPrint('[QuoteDS] Response: ${response.statusCode}');

      // Handle wrapped response {statusCode, message, data: [...]}
      final responseData = response.data;
      final List<dynamic> quotes = responseData is Map
          ? (responseData['data'] ?? [])
          : (responseData ?? []);

      debugPrint('[QuoteDS] Parsed ${quotes.length} quotes');
      return List<Map<String, dynamic>>.from(quotes);
    } on DioException catch (e) {
      debugPrint(
          '[QuoteDS] Error: ${e.response?.statusCode} - ${e.response?.data}');
      throw Exception(e.response?.data?['message'] ?? 'Failed to get quotes');
    }
  }

  /// Get quote by ID
  Future<Map<String, dynamic>> getQuoteById(String quoteId) async {
    try {
      final response = await _dio.get(
        '/quotes/$quoteId',
        options: Options(headers: await _getAuthHeaders()),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to get quote');
    }
  }

  /// Customer accepts a quote
  Future<Map<String, dynamic>> acceptQuote(
    String quoteId, {
    String? customerNote,
  }) async {
    try {
      final response = await _dio.patch(
        '/quotes/$quoteId/accept',
        data: {
          if (customerNote != null) 'customerNote': customerNote,
        },
        options: Options(headers: await _getAuthHeaders()),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to accept quote');
    }
  }

  /// Customer rejects a quote
  Future<Map<String, dynamic>> rejectQuote(
    String quoteId, {
    required String reason,
  }) async {
    try {
      final response = await _dio.patch(
        '/quotes/$quoteId/reject',
        data: {'reason': reason},
        options: Options(headers: await _getAuthHeaders()),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to reject quote');
    }
  }

  /// Provider agrees to rejection - cancels booking
  Future<Map<String, dynamic>> providerAgreeReject(String quoteId) async {
    try {
      final response = await _dio.patch(
        '/quotes/$quoteId/agree-reject',
        options: Options(headers: await _getAuthHeaders()),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to agree reject');
    }
  }
}
