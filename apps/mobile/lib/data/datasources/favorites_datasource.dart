import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Model for a favorite item
class FavoriteItem {
  final int serviceId;
  final String targetId;
  final DateTime? createdAt;
  final FavoriteService service;
  final FavoriteProvider provider;
  final double price;
  final String currency;

  FavoriteItem({
    required this.serviceId,
    required this.targetId,
    this.createdAt,
    required this.service,
    required this.provider,
    required this.price,
    required this.currency,
  });

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    // Safely parse IDs
    final targetIdStr = json['targetId']?.toString() ?? '';
    final targetIdInt = int.tryParse(targetIdStr);

    // Check various common field names for service identity
    final rawServiceId = json['id'] ?? json['serviceId'] ?? json['service_id'];
    final fallbackServiceId = rawServiceId is int
        ? rawServiceId
        : int.tryParse(rawServiceId?.toString() ?? '0') ?? 0;

    return FavoriteItem(
      // Use targetId (ProviderService.id) as the primary identifier if available
      serviceId: targetIdInt ?? fallbackServiceId,
      targetId: targetIdStr,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      service: FavoriteService.fromJson(json['service'] ?? {}),
      provider: FavoriteProvider.fromJson(json['provider'] ?? {}),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'VND',
    );
  }
}

class FavoriteService {
  final int id;
  final String name;
  final String? description;
  final String? category;

  FavoriteService({
    required this.id,
    required this.name,
    this.description,
    this.category,
  });

  factory FavoriteService.fromJson(Map<String, dynamic> json) {
    return FavoriteService(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      category: json['category'] as String?,
    );
  }
}

class FavoriteProvider {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final double ratingAvg;
  final int ratingCount;
  final bool isVerified;

  FavoriteProvider({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.isVerified = false,
  });

  factory FavoriteProvider.fromJson(Map<String, dynamic> json) {
    return FavoriteProvider(
      id: json['userId']?.toString() ?? '',
      displayName: json['displayName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
      ratingCount: json['ratingCount'] as int? ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }
}

/// Data source for favorites API
class FavoritesDataSource {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  FavoritesDataSource() {
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

  /// Get all favorites for current user
  Future<List<FavoriteItem>> getFavorites() async {
    try {
      final response = await _dio.get('/users/me/favorites');

      // Handle nested data response
      var data = response.data;
      if (data is Map && data.containsKey('data')) {
        data = data['data'];
      }

      if (data is List) {
        return data
            .map((json) => FavoriteItem.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('[FavoritesDataSource] Error getting favorites: $e');
      return [];
    }
  }

  /// Add a service to favorites
  Future<bool> addFavorite(int serviceId) async {
    try {
      await _dio.post('/users/me/favorites', data: {
        'targetType': 'provider_service',
        'targetId': serviceId,
      });
      return true;
    } catch (e) {
      print('[FavoritesDataSource] Error adding favorite: $e');
      return false;
    }
  }

  /// Remove a service from favorites
  Future<bool> removeFavorite(int serviceId) async {
    try {
      await _dio.delete('/users/me/favorites/$serviceId', queryParameters: {
        'targetType': 'provider_service',
      });
      return true;
    } catch (e) {
      print('[FavoritesDataSource] Error removing favorite: $e');
      return false;
    }
  }

  /// Check if a service is in favorites (local check from cached list)
  Future<Set<int>> getFavoriteServiceIds() async {
    final favorites = await getFavorites();
    return favorites.map((f) => f.serviceId).toSet();
  }

  // ========== PROVIDER FAVORITES ==========

  /// Get favorite providers with pagination
  Future<Map<String, dynamic>> getFavoriteProviders({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/users/me/favorites/providers',
        queryParameters: {'page': page, 'limit': limit},
      );

      var data = response.data;
      if (data is Map && data.containsKey('data')) {
        data = data['data'];
      }

      return {
        'providers': (data['providers'] as List?) ?? [],
        'total': data['total'] ?? 0,
        'page': data['page'] ?? page,
        'limit': data['limit'] ?? limit,
      };
    } catch (e) {
      print('[FavoritesDataSource] Error getting favorite providers: $e');
      return {'providers': [], 'total': 0, 'page': page, 'limit': limit};
    }
  }

  /// Check if a provider is in favorites
  Future<bool> checkFavoriteProvider(int providerId) async {
    try {
      final response = await _dio.get(
        '/users/me/favorites/providers/$providerId/check',
      );

      var data = response.data;
      if (data is Map && data.containsKey('data')) {
        data = data['data'];
      }

      return data['isFavorite'] == true;
    } catch (e) {
      print('[FavoritesDataSource] Error checking favorite provider: $e');
      return false;
    }
  }

  /// Add a provider to favorites
  Future<Map<String, dynamic>> addFavoriteProvider(int providerId) async {
    try {
      final response = await _dio.post(
        '/users/me/favorites/providers',
        data: {'providerId': providerId},
      );

      var data = response.data;
      if (data is Map && data.containsKey('data')) {
        data = data['data'];
      }

      return data as Map<String, dynamic>? ?? {};
    } catch (e) {
      print('[FavoritesDataSource] Error adding favorite provider: $e');
      rethrow;
    }
  }

  /// Remove a provider from favorites
  Future<Map<String, dynamic>?> removeFavoriteProvider(int providerId) async {
    try {
      final response = await _dio.delete(
        '/users/me/favorites/providers/$providerId',
      );

      var data = response.data;
      if (data is Map && data.containsKey('data')) {
        data = data['data'];
      }

      return data as Map<String, dynamic>?;
    } catch (e) {
      print('[FavoritesDataSource] Error removing favorite provider: $e');
      rethrow;
    }
  }
}
