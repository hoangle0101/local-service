import 'package:equatable/equatable.dart';

// Helper functions for safe type parsing
int _safeParseInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

double _safeParseDouble(dynamic value, {double defaultValue = 0.0}) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

class Category extends Equatable {
  final int id;
  final String code;
  final String name;
  final String? slug;
  final String? description;
  final String? iconUrl;
  final int? parentId;

  const Category({
    required this.id,
    required this.code,
    required this.name,
    this.slug,
    this.description,
    this.iconUrl,
    this.parentId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: _safeParseInt(json['id']),
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? 'Category').toString(),
      slug: json['slug']?.toString(),
      description: json['description']?.toString(),
      iconUrl: json['icon_url']?.toString() ?? json['iconUrl']?.toString(),
      parentId: json['parent_id'] != null
          ? _safeParseInt(json['parent_id'])
          : (json['parentId'] != null ? _safeParseInt(json['parentId']) : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'slug': slug,
      'description': description,
      'iconUrl': iconUrl,
      'parentId': parentId,
    };
  }

  @override
  List<Object?> get props =>
      [id, code, name, slug, description, iconUrl, parentId];
}

class Service extends Equatable {
  final int id;
  final String name;
  final String? description;
  final int categoryId;
  final String? iconUrl;
  final int? durationMinutes;
  final double basePrice;

  const Service({
    required this.id,
    required this.name,
    this.description,
    required this.categoryId,
    this.iconUrl,
    this.durationMinutes,
    this.basePrice = 0.0,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: _safeParseInt(json['id']),
      name: (json['name'] ?? 'Service').toString(),
      description: json['description']?.toString(),
      categoryId: _safeParseInt(json['category_id'] ?? json['categoryId']),
      iconUrl: json['icon_url']?.toString() ?? json['iconUrl']?.toString(),
      durationMinutes: json['duration_minutes'] != null
          ? _safeParseInt(json['duration_minutes'])
          : (json['durationMinutes'] != null
              ? _safeParseInt(json['durationMinutes'])
              : null),
      basePrice: _safeParseDouble(json['base_price'] ?? json['basePrice']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category_id': categoryId,
      'icon_url': iconUrl,
      'duration_minutes': durationMinutes,
      'base_price': basePrice,
    };
  }

  @override
  List<Object?> get props =>
      [id, name, description, categoryId, iconUrl, durationMinutes, basePrice];
}

class ProviderService extends Equatable {
  final int id; // Added 'id' field
  final int serviceId;
  final String providerUserId;
  final double price;
  final Service service;
  final ProviderInfo provider;
  final bool isActive; // Changed from required to optional with default
  final double? distance; // Added 'distance' field

  const ProviderService({
    required this.id,
    required this.serviceId,
    required this.providerUserId,
    required this.price,
    required this.service,
    required this.provider,
    this.isActive = true,
    this.distance,
  });

  factory ProviderService.fromJson(Map<String, dynamic> json) {
    return ProviderService(
      id: _safeParseInt(json['id']),
      providerUserId:
          (json['providerUserId'] ?? json['provider_user_id']).toString(),
      serviceId: _safeParseInt(json['serviceId'] ?? json['service_id']),
      price: _safeParseDouble(json['price']),
      service: Service.fromJson(json['service'] as Map<String, dynamic>),
      provider: ProviderInfo.fromJson(json['provider'] as Map<String, dynamic>),
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      distance: _safeParseDouble(json['distance']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        serviceId,
        providerUserId,
        price,
        isActive,
        service,
        provider,
        distance
      ];
}

class ProviderInfo extends Equatable {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final double? rating;
  final bool isVerified;
  final String verificationStatus;
  final double ratingAvg;
  final int ratingCount;

  const ProviderInfo({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.rating,
    this.isVerified = false,
    this.verificationStatus = 'unverified',
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
  });

  factory ProviderInfo.fromJson(Map<String, dynamic> json) {
    return ProviderInfo(
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      displayName:
          (json['display_name'] ?? json['displayName'] ?? 'Min Thợ').toString(),
      avatarUrl:
          json['avatar_url']?.toString() ?? json['avatarUrl']?.toString(),
      rating: _safeParseDouble(
          json['rating'] ?? json['rating_avg'] ?? json['ratingAvg']),
      isVerified:
          json['is_verified'] as bool? ?? json['isVerified'] as bool? ?? false,
      verificationStatus: (json['verification_status'] ??
              json['verificationStatus'] ??
              'unverified')
          .toString(),
      ratingAvg: _safeParseDouble(json['rating_avg'] ?? json['ratingAvg']),
      ratingCount: _safeParseInt(json['rating_count'] ?? json['ratingCount']),
    );
  }

  @override
  List<Object?> get props => [
        userId,
        displayName,
        avatarUrl,
        rating,
        isVerified,
        verificationStatus,
        ratingAvg,
        ratingCount
      ];
}

class NotificationEntry extends Equatable {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> payload;
  final bool isRead;
  final DateTime createdAt;

  const NotificationEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.payload,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationEntry.fromJson(Map<String, dynamic> json) {
    return NotificationEntry(
      id: json['id'].toString(),
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      isRead: (json['isRead'] as bool? ?? json['is_read'] as bool? ?? false),
      createdAt: DateTime.parse(json['createdAt']?.toString() ??
          json['created_at']?.toString() ??
          DateTime.now().toIso8601String()),
    );
  }

  @override
  List<Object?> get props =>
      [id, type, title, body, payload, isRead, createdAt];
}
