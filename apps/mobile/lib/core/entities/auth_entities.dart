class AuthTokens {
  final String accessToken;
  final String refreshToken;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }
}

class UserEntity {
  final String id;
  final String phone;
  final String? email;
  final String status;
  final bool isVerified;
  final DateTime? lastLoginAt;
  final UserProfileEntity? profile;
  final ProviderProfileEntity? providerProfile;

  UserEntity({
    required this.id,
    required this.phone,
    this.email,
    required this.status,
    required this.isVerified,
    this.lastLoginAt,
    this.profile,
    this.providerProfile,
  });

  /// Check if user is a provider
  bool get isProvider => providerProfile != null;

  /// Get user's full name
  String get fullName =>
      profile?.fullName ?? providerProfile?.displayName ?? 'User';

  /// Get user's role
  String get role => isProvider ? 'provider' : 'user';

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'].toString(),
      phone: json['phone'] as String,
      email: json['email'] as String?,
      status: json['status'] as String,
      isVerified: json['isVerified'] as bool? ?? false,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      profile: json['profile'] != null
          ? UserProfileEntity.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
      providerProfile: json['providerProfile'] != null
          ? ProviderProfileEntity.fromJson(
              json['providerProfile'] as Map<String, dynamic>)
          : null,
    );
  }
}

class UserProfileEntity {
  final String userId;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final String? gender;
  final DateTime? birthDate;

  UserProfileEntity({
    required this.userId,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.gender,
    this.birthDate,
  });

  factory UserProfileEntity.fromJson(Map<String, dynamic> json) {
    return UserProfileEntity(
      userId: json['userId'].toString(),
      fullName: json['fullName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      gender: json['gender'] as String?,
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : null,
    );
  }
}

class ProviderProfileEntity {
  final String userId;
  final String displayName;
  final String? bio;
  final dynamic skills;
  final int? serviceRadiusM;
  final String verificationStatus;
  final bool isAvailable;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double? ratingAvg;
  final int? ratingCount;

  ProviderProfileEntity({
    required this.userId,
    required this.displayName,
    this.bio,
    this.skills,
    this.serviceRadiusM,
    required this.verificationStatus,
    required this.isAvailable,
    this.address,
    this.latitude,
    this.longitude,
    this.ratingAvg,
    this.ratingCount,
  });

  factory ProviderProfileEntity.fromJson(Map<String, dynamic> json) {
    return ProviderProfileEntity(
      userId: json['userId']?.toString() ?? '',
      displayName: json['displayName'] as String? ?? 'Provider',
      bio: json['bio'] as String?,
      skills: json['skills'],
      serviceRadiusM: json['serviceRadiusM'] != null
          ? (json['serviceRadiusM'] is int
              ? json['serviceRadiusM']
              : int.tryParse(json['serviceRadiusM'].toString()))
          : null,
      verificationStatus: json['verificationStatus'] as String? ?? 'unverified',
      isAvailable: json['isAvailable'] as bool? ?? false,
      address: json['address'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] is double
              ? json['latitude']
              : double.tryParse(json['latitude'].toString()))
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] is double
              ? json['longitude']
              : double.tryParse(json['longitude'].toString()))
          : null,
      ratingAvg: json['ratingAvg'] != null
          ? (json['ratingAvg'] is double
              ? json['ratingAvg']
              : double.tryParse(json['ratingAvg'].toString()))
          : null,
      ratingCount: json['ratingCount'] != null
          ? (json['ratingCount'] is int
              ? json['ratingCount']
              : int.tryParse(json['ratingCount'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'bio': bio,
      'skills': skills,
      'serviceRadiusM': serviceRadiusM,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
