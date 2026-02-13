import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

/// Service to get driving directions using OpenRouteService API
/// Sign up for free API key at: https://openrouteservice.org/dev/#/signup
class DirectionsDataSource {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.openrouteservice.org',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // TODO: Replace with your OpenRouteService API key
  // Get free key at: https://openrouteservice.org/dev/#/signup
  static const String _apiKey =
      'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjZkNzkzYjMxOWM4YTRiZjlhZDNiN2E0YjlkZTY3YjAyIiwiaCI6Im11cm11cjY0In0=';

  /// Get route between two points
  /// Returns list of LatLng points for polyline
  Future<DirectionsResult> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final response = await _dio.get(
        '/v2/directions/driving-car',
        queryParameters: {
          'api_key': _apiKey,
          'start': '${origin.longitude},${origin.latitude}',
          'end': '${destination.longitude},${destination.latitude}',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Extract route geometry (polyline points)
        final features = data['features'] as List;
        if (features.isEmpty) {
          throw Exception('No route found');
        }

        final feature = features[0];
        final geometry = feature['geometry'];
        final coordinates = geometry['coordinates'] as List;

        // Convert coordinates to LatLng list
        final List<LatLng> routePoints = coordinates.map<LatLng>((coord) {
          return LatLng(coord[1].toDouble(), coord[0].toDouble());
        }).toList();

        // Extract summary info
        final properties = feature['properties'];
        final summary = properties['summary'];
        final distanceMeters = summary['distance']?.toDouble() ?? 0.0;
        final durationSeconds = summary['duration']?.toDouble() ?? 0.0;

        return DirectionsResult(
          routePoints: routePoints,
          distanceMeters: distanceMeters,
          durationSeconds: durationSeconds,
        );
      } else {
        throw Exception('Failed to get directions: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('API key không hợp lệ. Vui lòng kiểm tra lại.');
      }
      throw Exception('Không thể lấy đường đi: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }
}

/// Result from directions API
class DirectionsResult {
  final List<LatLng> routePoints;
  final double distanceMeters;
  final double durationSeconds;

  DirectionsResult({
    required this.routePoints,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  /// Get formatted distance string
  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toInt()} m';
    } else {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Get formatted duration string
  String get formattedDuration {
    final minutes = (durationSeconds / 60).round();
    if (minutes < 60) {
      return '$minutes phút';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '$hours giờ $mins phút';
    }
  }
}
