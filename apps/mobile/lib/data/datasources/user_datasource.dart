import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Data source for user profile API operations
class UserDataSource {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  UserDataSource() {
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

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? bio,
    String? gender,
    String? birthDate,
    String? avatarUrl,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (fullName != null) data['fullName'] = fullName;
      if (bio != null) data['bio'] = bio;
      if (gender != null) data['gender'] = gender;
      if (birthDate != null) data['birthDate'] = birthDate;
      if (avatarUrl != null) data['avatarUrl'] = avatarUrl;

      final response = await _dio.patch('/users/me/profile', data: data);

      var result = response.data;
      if (result is Map && result.containsKey('data')) {
        result = result['data'];
      }
      return result as Map<String, dynamic>;
    } catch (e) {
      print('[UserDataSource] Error updating profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Upload avatar image and return URL
  Future<String> uploadAvatar(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found');
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      // Use the correct upload endpoint
      final response = await _dio.post('/system/upload', data: formData);

      var data = response.data;
      if (data is Map && data.containsKey('data')) {
        data = data['data'];
      }

      // The backend returns {url: '/uploads/...'}
      final url = data['url'] as String?;
      if (url != null && url.isNotEmpty) {
        return url;
      }
      throw Exception('No URL returned from upload');
    } catch (e) {
      print('[UserDataSource] Error uploading avatar: $e');
      throw Exception('Failed to upload avatar: $e');
    }
  }

  /// Get user addresses
  Future<List<Map<String, dynamic>>> getAddresses() async {
    try {
      final response = await _dio.get('/users/me/addresses');

      var data = response.data;
      if (data is Map && data.containsKey('data')) {
        data = data['data'];
      }

      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('[UserDataSource] Error getting addresses: $e');
      return [];
    }
  }

  /// Add new address
  Future<bool> addAddress({
    required String addressText,
    String? label,
    bool isDefault = false,
  }) async {
    try {
      await _dio.post('/users/me/addresses', data: {
        'addressText': addressText,
        'label': label ?? 'Địa chỉ',
        'isDefault': isDefault,
      });
      return true;
    } catch (e) {
      print('[UserDataSource] Error adding address: $e');
      return false;
    }
  }
}
