import 'package:latlong2/latlong.dart';
import '../datasources/directions_datasource.dart';

// Export models for consumers
export '../datasources/directions_datasource.dart' show DirectionsResult;

/// Repository layer for directions/routing operations.
/// Wraps DirectionsDataSource to provide abstraction.
class DirectionsRepository {
  final DirectionsDataSource _dataSource;

  DirectionsRepository([DirectionsDataSource? dataSource])
      : _dataSource = dataSource ?? DirectionsDataSource();

  /// Get route between two points
  Future<DirectionsResult> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) =>
      _dataSource.getRoute(origin: origin, destination: destination);
}
