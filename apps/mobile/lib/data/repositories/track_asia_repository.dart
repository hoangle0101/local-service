import '../datasources/track_asia_datasource.dart';

// Export models for consumers
export '../datasources/track_asia_datasource.dart'
    show AddressPrediction, PlaceDetail, FullAddress;

/// Repository layer for TrackAsia (mapping) operations.
/// Wraps TrackAsiaDataSource to provide abstraction.
class TrackAsiaRepository {
  final TrackAsiaDataSource _dataSource;

  TrackAsiaRepository([TrackAsiaDataSource? dataSource])
      : _dataSource = dataSource ?? TrackAsiaDataSource();

  /// Search for Vietnamese addresses using autocomplete
  Future<List<AddressPrediction>> searchAddress(String query) =>
      _dataSource.searchAddress(query);

  /// Get place details including GPS coordinates from place_id
  Future<PlaceDetail?> getPlaceDetail(String placeId) =>
      _dataSource.getPlaceDetail(placeId);

  /// Reverse geocode: Get full address from GPS coordinates
  Future<FullAddress?> reverseGeocode(double latitude, double longitude) =>
      _dataSource.reverseGeocode(latitude, longitude);
}
