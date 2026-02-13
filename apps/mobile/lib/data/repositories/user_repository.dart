import '../datasources/user_datasource.dart';

/// Repository layer for user profile operations.
/// Wraps UserDataSource to provide abstraction.
class UserRepository {
  final UserDataSource _dataSource;

  UserRepository([UserDataSource? dataSource])
      : _dataSource = dataSource ?? UserDataSource();

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? bio,
    String? gender,
    String? birthDate,
    String? avatarUrl,
  }) =>
      _dataSource.updateProfile(
        fullName: fullName,
        bio: bio,
        gender: gender,
        birthDate: birthDate,
        avatarUrl: avatarUrl,
      );

  /// Upload avatar image
  Future<String> uploadAvatar(String filePath) =>
      _dataSource.uploadAvatar(filePath);

  /// Get user addresses
  Future<List<Map<String, dynamic>>> getAddresses() =>
      _dataSource.getAddresses();

  /// Add new address
  Future<bool> addAddress({
    required String addressText,
    String? label,
    bool isDefault = false,
  }) =>
      _dataSource.addAddress(
        addressText: addressText,
        label: label,
        isDefault: isDefault,
      );
}
