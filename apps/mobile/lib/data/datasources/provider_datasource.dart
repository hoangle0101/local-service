import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';

class ProviderDataSource {
  final Dio _dio;

  ProviderDataSource()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'http://10.0.2.2:3000',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        );

  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final token = await SecureStorage.getAccessToken();
      print(
          '[ProviderDataSource] getStatistics - token: ${token != null ? "exists" : "NULL"}');

      if (token == null || token.isEmpty) {
        throw Exception('Vui lòng đăng nhập lại');
      }

      final response = await _dio.get(
        '/provider/statistics',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return response.data['data'] as Map<String, dynamic>? ?? {};
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
      }
      throw Exception('Lỗi tải thống kê: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  Future<void> updateAvailability(bool isAvailable) async {
    try {
      final token = await SecureStorage.getAccessToken();
      print(
          '[ProviderDataSource] updateAvailability - token: ${token != null ? "exists" : "NULL"}');

      if (token == null || token.isEmpty) {
        throw Exception('Vui lòng đăng nhập lại');
      }

      await _dio.patch(
        '/provider/me/availability',
        data: {'isAvailable': isAvailable},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
      }
      throw Exception('Lỗi cập nhật: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  Future<void> createProviderProfile({
    required String displayName,
    String? bio,
    List<String>? skills,
    int? serviceRadiusM,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    try {
      final token = await SecureStorage.getAccessToken();
      print(
          'Creating provider profile with token: ${token?.substring(0, 10)}...');
      print('Request data: ${{
        'displayName': displayName,
        if (bio != null) 'bio': bio,
        if (skills != null) 'skills': skills,
        if (serviceRadiusM != null) 'serviceRadiusM': serviceRadiusM,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (address != null) 'address': address,
      }}');

      await _dio.post(
        '/provider/onboarding',
        data: {
          'displayName': displayName,
          if (bio != null) 'bio': bio,
          if (skills != null) 'skills': skills,
          if (serviceRadiusM != null) 'serviceRadiusM': serviceRadiusM,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (address != null) 'address': address,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      // Detailed error handling
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorData = e.response!.data;
        String errorMessage = 'Failed to create provider profile';

        if (errorData is Map && errorData.containsKey('message')) {
          errorMessage = errorData['message'].toString();
        }

        throw Exception('Error $statusCode: $errorMessage');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to create provider profile: ${e.toString()}');
    }
  }

  Future<void> updateProviderProfile({
    String? displayName,
    String? bio,
    List<String>? skills,
    int? serviceRadiusM,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    try {
      final token = await SecureStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Vui lòng đăng nhập lại');
      }

      await _dio.patch(
        '/provider/me',
        data: {
          if (displayName != null) 'displayName': displayName,
          if (bio != null) 'bio': bio,
          if (skills != null) 'skills': skills,
          if (serviceRadiusM != null) 'serviceRadiusM': serviceRadiusM,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (address != null) 'address': address,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Phiên đăng nhập hết hạn');
      }
      throw Exception('Lỗi cập nhật: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  /// Upload avatar image
  Future<String?> uploadAvatar(String filePath) async {
    try {
      print('[ProviderDataSource] uploadAvatar called with path: $filePath');

      final token = await SecureStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        print('[ProviderDataSource] No token found');
        throw Exception('Vui lòng đăng nhập lại');
      }
      print('[ProviderDataSource] Token exists, preparing FormData');

      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
      });
      print('[ProviderDataSource] FormData created, sending request...');

      final response = await _dio.post(
        '/provider/me/avatar',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print(
          '[ProviderDataSource] Upload response status: ${response.statusCode}');
      print('[ProviderDataSource] Upload response data: ${response.data}');

      // Extract avatar URL from response
      final data = response.data;
      if (data is Map && data.containsKey('data')) {
        final avatarUrl = data['data']['avatarUrl'] as String?;
        print('[ProviderDataSource] Avatar URL from data.data: $avatarUrl');
        return avatarUrl;
      }
      final avatarUrl = data['avatarUrl'] as String?;
      print('[ProviderDataSource] Avatar URL direct: $avatarUrl');
      return avatarUrl;
    } on DioException catch (e) {
      print('[ProviderDataSource] DioException: ${e.message}');
      print('[ProviderDataSource] Response status: ${e.response?.statusCode}');
      print('[ProviderDataSource] Response data: ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        throw Exception('Phiên đăng nhập hết hạn');
      }
      throw Exception('Lỗi upload ảnh: ${e.message}');
    } catch (e) {
      print('[ProviderDataSource] Upload error: $e');
      throw Exception('Lỗi: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMyServices() async {
    try {
      final token = await SecureStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Vui lòng đăng nhập lại');
      }

      final response = await _dio.get(
        '/provider/services',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final data = response.data['data'];
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Phiên đăng nhập hết hạn');
      }
      throw Exception('Lỗi tải dịch vụ: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  Future<void> addService({
    required int serviceId,
    required double price,
    String currency = 'VND',
  }) async {
    try {
      final token = await SecureStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Vui lòng đăng nhập lại');
      }

      await _dio.post(
        '/provider/services',
        data: {
          'serviceId': serviceId,
          'price': price,
          'currency': currency,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Phiên đăng nhập hết hạn');
      }
      throw Exception('Lỗi thêm dịch vụ: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  Future<void> updateService({
    required int serviceId,
    double? price,
    bool? isActive,
  }) async {
    try {
      final token = await SecureStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Vui lòng đăng nhập lại');
      }

      await _dio.patch(
        '/provider/services/$serviceId',
        data: {
          if (price != null) 'price': price,
          if (isActive != null) 'isActive': isActive,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Phiên đăng nhập hết hạn');
      }
      throw Exception('Lỗi cập nhật: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  Future<void> deleteService(int serviceId) async {
    try {
      final token = await SecureStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Vui lòng đăng nhập lại');
      }

      await _dio.delete(
        '/provider/services/$serviceId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Phiên đăng nhập hết hạn');
      }
      throw Exception('Lỗi xóa dịch vụ: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  // ============== Service Items ==============

  /// Get service items for a specific service
  Future<List<Map<String, dynamic>>> getServiceItems(int serviceId) async {
    try {
      final token = await SecureStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Vui lòng đăng nhập lại');
      }

      final response = await _dio.get(
        '/provider/services/$serviceId/items',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final data = response.data;
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      if (data is Map && data.containsKey('data')) {
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Phiên đăng nhập hết hạn');
      }
      throw Exception('Lỗi tải danh sách: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  /// Create a service item
  Future<Map<String, dynamic>> createServiceItem(
    int serviceId,
    Map<String, dynamic> data,
  ) async {
    try {
      final token = await SecureStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Vui lòng đăng nhập lại');
      }

      print(
          '[ProviderDataSource] Creating service item for serviceId: $serviceId');
      print('[ProviderDataSource] Data: $data');

      final response = await _dio.post(
        '/provider/services/$serviceId/items',
        data: data,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      print(
          '[ProviderDataSource] Create response status: ${response.statusCode}');
      print('[ProviderDataSource] Create response data: ${response.data}');

      return response.data is Map ? response.data : {};
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Phiên đăng nhập hết hạn');
      }
      throw Exception('Lỗi thêm mục: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  /// Update a service item
  Future<void> updateServiceItem(
      String itemId, Map<String, dynamic> data) async {
    try {
      final token = await SecureStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Vui lòng đăng nhập lại');
      }

      await _dio.patch(
        '/provider/services/items/$itemId',
        data: data,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Phiên đăng nhập hết hạn');
      }
      throw Exception('Lỗi cập nhật: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  /// Delete a service item
  Future<void> deleteServiceItem(String itemId) async {
    try {
      final token = await SecureStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Vui lòng đăng nhập lại');
      }

      await _dio.delete(
        '/provider/services/items/$itemId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Phiên đăng nhập hết hạn');
      }
      throw Exception('Lỗi xóa mục: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }
}
