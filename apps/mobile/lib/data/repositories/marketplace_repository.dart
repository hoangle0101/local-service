import '../datasources/marketplace_datasource.dart';
import '../../core/entities/entities.dart';

/// Repository layer for marketplace/services operations.
/// Wraps MarketplaceDataSource to provide abstraction.
class MarketplaceRepository {
  final MarketplaceDataSource _dataSource;

  MarketplaceRepository([MarketplaceDataSource? dataSource])
      : _dataSource = dataSource ?? MarketplaceDataSource();

  /// Get all categories
  Future<List<Category>> getCategories() => _dataSource.getCategories();

  /// Get generic services for a category
  Future<List<Service>> getGenericServices(int categoryId) =>
      _dataSource.getGenericServices(categoryId);

  /// Search provider services with filters
  Future<List<ProviderService>> searchServices({
    int limit = 10,
    int? categoryId,
    int? serviceId,
    double? latitude,
    double? longitude,
  }) =>
      _dataSource.searchServices(
        limit: limit,
        categoryId: categoryId,
        serviceId: serviceId,
        latitude: latitude,
        longitude: longitude,
      );

  /// Get service details by ID
  Future<ProviderService> getServiceById(int serviceId) =>
      _dataSource.getServiceById(serviceId);
}
