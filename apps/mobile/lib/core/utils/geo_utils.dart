import 'dart:math';

/// Utility functions for geographical calculations
class GeoUtils {
  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  static double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLng = _degreesToRadians(lng2 - lng1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Calculate distance in meters
  static double calculateDistanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return calculateDistance(lat1, lng1, lat2, lng2) * 1000;
  }

  /// Format distance for display
  /// Returns distance string with appropriate unit (m or km)
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceKm.round()} km';
    }
  }

  /// Check if a point is within a radius (in meters)
  static bool isWithinRadius(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
    double radiusMeters,
  ) {
    double distanceMeters = calculateDistanceMeters(lat1, lng1, lat2, lng2);
    return distanceMeters <= radiusMeters;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
}
