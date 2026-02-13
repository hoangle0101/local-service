import '../datasources/favorites_datasource.dart';

/// Repository layer for favorites operations.
/// Wraps FavoritesDataSource to provide abstraction.
class FavoritesRepository {
  final FavoritesDataSource _dataSource;

  FavoritesRepository([FavoritesDataSource? dataSource])
      : _dataSource = dataSource ?? FavoritesDataSource();

  /// Get all favorites for current user
  Future<List<FavoriteItem>> getFavorites() => _dataSource.getFavorites();

  /// Add a service to favorites
  Future<bool> addFavorite(int serviceId) => _dataSource.addFavorite(serviceId);

  /// Remove a service from favorites
  Future<bool> removeFavorite(int serviceId) =>
      _dataSource.removeFavorite(serviceId);

  /// Get set of favorite service IDs
  Future<Set<int>> getFavoriteServiceIds() =>
      _dataSource.getFavoriteServiceIds();

  /// Get favorite providers with pagination
  Future<Map<String, dynamic>> getFavoriteProviders({
    int page = 1,
    int limit = 20,
  }) =>
      _dataSource.getFavoriteProviders(page: page, limit: limit);

  /// Check if a provider is in favorites
  Future<bool> checkFavoriteProvider(int providerId) =>
      _dataSource.checkFavoriteProvider(providerId);

  /// Add a provider to favorites
  Future<Map<String, dynamic>> addFavoriteProvider(int providerId) =>
      _dataSource.addFavoriteProvider(providerId);

  /// Remove a provider from favorites
  Future<Map<String, dynamic>?> removeFavoriteProvider(int providerId) =>
      _dataSource.removeFavoriteProvider(providerId);
}
