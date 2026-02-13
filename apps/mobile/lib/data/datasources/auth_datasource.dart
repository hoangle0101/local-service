import 'package:dio/dio.dart';
import '../../core/entities/auth_entities.dart';

enum OtpPurpose { login, resetPassword, verifyPhone }

class AuthDataSource {
  final Dio _dio;

  AuthDataSource()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'http://10.0.2.2:3000',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        );

  // Register new user
  Future<Map<String, dynamic>> register({
    required String phone,
    required String password,
    required String fullName,
    String? role, // Optional: 'customer' or 'provider'
  }) async {
    try {
      print('📤 Sending registration request:');
      print('   Phone: $phone');
      print('   Password: ${password.replaceAll(RegExp(r'.'), '*')}');
      print('   Full Name: $fullName');
      print('   Role: ${role ?? 'customer (default)'}');

      final response = await _dio.post('/auth/register', data: {
        'phone': phone,
        'password': password,
        'fullName': fullName,
        if (role != null) 'role': role,
      });

      print('✅ Registration successful');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ Registration failed');
      print('   Status Code: ${e.response?.statusCode}');
      print('   Response Data: ${e.response?.data}');

      // Extract detailed error message from backend
      if (e.response?.data != null) {
        final errorData = e.response!.data;

        // Handle validation errors
        if (errorData is Map<String, dynamic>) {
          if (errorData.containsKey('message')) {
            final message = errorData['message'];

            // If message is a list (validation errors)
            if (message is List) {
              final errors = message.join('\n• ');
              throw Exception('Validation errors:\n• $errors');
            }

            // If message is a string
            if (message is String) {
              throw Exception(message);
            }
          }
        }
      }

      // Fallback error message
      throw Exception('Failed to register. Please check your input.');
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw Exception('Failed to register: $e');
    }
  }

  // Login with password
  Future<AuthTokens> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'phone': phone,
        'password': password,
      });

      final data = response.data;
      if (data is Map<String, dynamic>) {
        // Handle wrapped response
        if (data.containsKey('data')) {
          return AuthTokens.fromJson(data['data'] as Map<String, dynamic>);
        }
        return AuthTokens.fromJson(data);
      }
      throw Exception('Unexpected response format');
    } on DioException catch (e) {
      // Handle specific HTTP error codes
      if (e.response?.statusCode == 401) {
        throw Exception('Thông tin đăng nhập không chính xác');
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Số điện thoại chưa được đăng ký');
      }

      // Try to extract error message from backend
      if (e.response?.data != null &&
          e.response?.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        if (errorData.containsKey('message')) {
          final message = errorData['message'];
          if (message is String) {
            throw Exception(message);
          }
        }
      }

      throw Exception('Đăng nhập thất bại. Vui lòng thử lại.');
    } catch (e) {
      // Re-throw if it's already our Exception
      if (e is Exception) rethrow;
      throw Exception('Đăng nhập thất bại: $e');
    }
  }

  // Login with OTP
  Future<AuthTokens> loginWithOtp({
    required String phone,
    required String code,
  }) async {
    try {
      final response = await _dio.post('/auth/login-otp', data: {
        'phone': phone,
        'code': code,
      });

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('data')) {
          return AuthTokens.fromJson(data['data'] as Map<String, dynamic>);
        }
        return AuthTokens.fromJson(data);
      }
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception('Failed to login with OTP: $e');
    }
  }

  // Send OTP
  Future<Map<String, dynamic>> sendOtp({
    required String phone,
    required OtpPurpose purpose,
  }) async {
    try {
      final purposeString = _otpPurposeToString(purpose);
      final response = await _dio.post('/auth/send-otp', data: {
        'phone': phone,
        'purpose': purposeString,
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String code,
    required OtpPurpose purpose,
  }) async {
    try {
      final purposeString = _otpPurposeToString(purpose);
      final response = await _dio.post('/auth/verify-otp', data: {
        'phone': phone,
        'code': code,
        'purpose': purposeString,
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to verify OTP: $e');
    }
  }

  // Refresh token
  Future<String> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post('/auth/refresh-token', data: {
        'refreshToken': refreshToken,
      });

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('data')) {
          return data['data']['accessToken'] as String;
        }
        return data['accessToken'] as String;
      }
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception('Failed to refresh token: $e');
    }
  }

  // Logout
  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post('/auth/logout', data: {
        'refreshToken': refreshToken,
      });
    } catch (e) {
      // Logout is idempotent, so we don't throw error
      print('Logout error: $e');
    }
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post('/auth/reset-password', data: {
        'phone': phone,
        'otp': otp,
        'newPassword': newPassword,
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }

  // Get user profile
  Future<UserEntity> getUserProfile(String accessToken) async {
    try {
      final response = await _dio.get(
        '/users/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        // Handle wrapped response
        if (data.containsKey('data')) {
          return UserEntity.fromJson(data['data'] as Map<String, dynamic>);
        }
        return UserEntity.fromJson(data);
      }
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  String _otpPurposeToString(OtpPurpose purpose) {
    switch (purpose) {
      case OtpPurpose.login:
        return 'login';
      case OtpPurpose.resetPassword:
        return 'reset_password';
      case OtpPurpose.verifyPhone:
        return 'verify_phone';
    }
  }
}
