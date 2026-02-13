import '../datasources/provider_datasource.dart';

/// Repository layer for provider-related operations.
/// Wraps ProviderDataSource to provide abstraction and testability.
class ProviderRepository {
  final ProviderDataSource _dataSource;

  ProviderRepository([ProviderDataSource? dataSource])
      : _dataSource = dataSource ?? ProviderDataSource();

  /// Get provider statistics (earnings, ratings, etc.)
  Future<Map<String, dynamic>> getStatistics() => _dataSource.getStatistics();

  /// Update provider availability status
  Future<void> updateAvailability(bool isAvailable) =>
      _dataSource.updateAvailability(isAvailable);

  /// Create provider profile during onboarding
  Future<void> createProviderProfile({
    required String displayName,
    String? bio,
    List<String>? skills,
    int? serviceRadiusM,
    double? latitude,
    double? longitude,
    String? address,
  }) =>
      _dataSource.createProviderProfile(
        displayName: displayName,
        bio: bio,
        skills: skills,
        serviceRadiusM: serviceRadiusM,
        latitude: latitude,
        longitude: longitude,
        address: address,
      );

  /// Update provider profile
  Future<void> updateProviderProfile({
    String? displayName,
    String? bio,
    List<String>? skills,
    int? serviceRadiusM,
    double? latitude,
    double? longitude,
    String? address,
  }) =>
      _dataSource.updateProviderProfile(
        displayName: displayName,
        bio: bio,
        skills: skills,
        serviceRadiusM: serviceRadiusM,
        latitude: latitude,
        longitude: longitude,
        address: address,
      );

  /// Upload provider avatar
  Future<String?> uploadAvatar(String filePath) =>
      _dataSource.uploadAvatar(filePath);

  /// Get provider's services
  Future<List<Map<String, dynamic>>> getMyServices() =>
      _dataSource.getMyServices();

  /// Add a new service
  Future<void> addService({
    required int serviceId,
    required double price,
    String currency = 'VND',
  }) =>
      _dataSource.addService(
        serviceId: serviceId,
        price: price,
        currency: currency,
      );

  /// Update existing service
  Future<void> updateService({
    required int serviceId,
    double? price,
    bool? isActive,
  }) =>
      _dataSource.updateService(
        serviceId: serviceId,
        price: price,
        isActive: isActive,
      );

  /// Delete a service
  Future<void> deleteService(int serviceId) =>
      _dataSource.deleteService(serviceId);

  /// Get service items for a specific service
  Future<List<Map<String, dynamic>>> getServiceItems(int serviceId) =>
      _dataSource.getServiceItems(serviceId);

  /// Create a service item
  Future<Map<String, dynamic>> createServiceItem(
    int serviceId,
    Map<String, dynamic> data,
  ) =>
      _dataSource.createServiceItem(serviceId, data);

  /// Update a service item
  Future<void> updateServiceItem(
    String itemId,
    Map<String, dynamic> data,
  ) =>
      _dataSource.updateServiceItem(itemId, data);

  /// Delete a service item
  Future<void> deleteServiceItem(String itemId) =>
      _dataSource.deleteServiceItem(itemId);
}
