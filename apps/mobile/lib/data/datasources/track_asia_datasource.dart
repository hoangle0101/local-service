import 'package:dio/dio.dart';

/// Track Asia API DataSource for Vietnamese address autocomplete and geocoding
class TrackAsiaDataSource {
  final Dio _dio;

  // Track Asia API base URL and key
  static const String _baseUrl = 'https://maps.track-asia.com/api/v2';
  static const String _apiKey =
      'a7de17654364332e589f9357257ca01d10'; // Free tier key

  TrackAsiaDataSource()
      : _dio = Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );

  /// Search for Vietnamese addresses using autocomplete
  /// Returns list of [AddressPrediction]
  Future<List<AddressPrediction>> searchAddress(String query) async {
    if (query.isEmpty || query.length < 2) {
      return [];
    }

    try {
      final response = await _dio.get(
        '/place/autocomplete/json',
        queryParameters: {
          'input': query,
          'key': _apiKey,
          'size': 5, // Limit results
          'new_admin': 'true', // Use new Vietnamese admin boundaries
        },
      );

      if (response.data['status'] == 'OK') {
        final predictions =
            response.data['predictions'] as List<dynamic>? ?? [];
        return predictions.map((p) => AddressPrediction.fromJson(p)).toList();
      }
      return [];
    } catch (e) {
      print('[TrackAsia] Search error: $e');
      return [];
    }
  }

  /// Get place details including GPS coordinates from place_id
  Future<PlaceDetail?> getPlaceDetail(String placeId) async {
    try {
      final response = await _dio.get(
        '/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'key': _apiKey,
          'new_admin': 'true',
        },
      );

      if (response.data['status'] == 'OK' && response.data['result'] != null) {
        return PlaceDetail.fromJson(response.data['result']);
      }
      return null;
    } catch (e) {
      print('[TrackAsia] Place detail error: $e');
      return null;
    }
  }

  /// Reverse geocode: Get full address from GPS coordinates
  /// Returns [FullAddress] with street, ward, district, province, etc.
  Future<FullAddress?> reverseGeocode(double latitude, double longitude) async {
    try {
      print(
          '[TrackAsia] Reverse geocode request: lat=$latitude, lng=$longitude');

      final response = await _dio.get(
        '/geocode/json',
        queryParameters: {
          'latlng': '$latitude,$longitude',
          'key': _apiKey,
          'new_admin': 'true',
        },
      );

      print('[TrackAsia] Reverse geocode status: ${response.data['status']}');

      if (response.data['status'] == 'OK' &&
          response.data['results'] != null &&
          (response.data['results'] as List).isNotEmpty) {
        final result = response.data['results'][0] as Map<String, dynamic>;

        // Debug: Print what we received
        print('[TrackAsia] Formatted address: ${result['formatted_address']}');
        print(
            '[TrackAsia] Address components: ${result['address_components']}');

        final address =
            FullAddress.fromGeocodeResult(result, latitude, longitude);
        print('[TrackAsia] Parsed displayText: ${address.displayText}');
        print('[TrackAsia] Parsed fullAddress: ${address.fullAddress}');

        return address;
      }
      print('[TrackAsia] No results from reverse geocode');
      return null;
    } catch (e) {
      print('[TrackAsia] Reverse geocode error: $e');
      return null;
    }
  }
}

/// Model for address prediction from autocomplete
class AddressPrediction {
  final String placeId;
  final String description;
  final String formattedAddress;
  final String mainText;
  final String secondaryText;

  AddressPrediction({
    required this.placeId,
    required this.description,
    required this.formattedAddress,
    required this.mainText,
    required this.secondaryText,
  });

  factory AddressPrediction.fromJson(Map<String, dynamic> json) {
    final structuredFormatting =
        json['structured_formatting'] as Map<String, dynamic>?;
    return AddressPrediction(
      placeId: json['place_id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      formattedAddress: json['formatted_address'] as String? ??
          json['description'] as String? ??
          '',
      mainText: structuredFormatting?['main_text'] as String? ?? '',
      secondaryText: structuredFormatting?['secondary_text'] as String? ?? '',
    );
  }
}

/// Model for place detail with coordinates
class PlaceDetail {
  final String placeId;
  final String name;
  final String formattedAddress;
  final double latitude;
  final double longitude;
  final List<AddressComponent> addressComponents;

  PlaceDetail({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    required this.addressComponents,
  });

  factory PlaceDetail.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;

    final components = (json['address_components'] as List<dynamic>?)
            ?.map((c) => AddressComponent.fromJson(c))
            .toList() ??
        [];

    return PlaceDetail(
      placeId: json['place_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      formattedAddress: json['formatted_address'] as String? ?? '',
      latitude: (location?['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (location?['lng'] as num?)?.toDouble() ?? 0.0,
      addressComponents: components,
    );
  }
}

/// Model for address component (province, district, ward, etc.)
class AddressComponent {
  final String longName;
  final String shortName;
  final List<String> types;

  AddressComponent({
    required this.longName,
    required this.shortName,
    required this.types,
  });

  factory AddressComponent.fromJson(Map<String, dynamic> json) {
    return AddressComponent(
      longName: json['long_name'] as String? ?? '',
      shortName: json['short_name'] as String? ?? '',
      types: (json['types'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  /// Check if this is a province/city
  bool get isProvince => types.contains('administrative_area_level_1');

  /// Check if this is a district
  bool get isDistrict => types.contains('administrative_area_level_2');

  /// Check if this is a ward/commune
  bool get isWard =>
      types.contains('administrative_area_level_3') ||
      types.contains('sublocality');

  /// Check if this is a street/route
  bool get isStreet => types.contains('route');
}

/// Model for full address with all components from reverse geocoding
class FullAddress {
  final String? streetNumber;
  final String? street;
  final String? ward;
  final String? district;
  final String? province;
  final String? country;
  final String fullAddress;
  final double latitude;
  final double longitude;

  FullAddress({
    this.streetNumber,
    this.street,
    this.ward,
    this.district,
    this.province,
    this.country,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
  });

  /// Create from reverse geocode result
  factory FullAddress.fromGeocodeResult(
    Map<String, dynamic> json,
    double lat,
    double lng,
  ) {
    final components = (json['address_components'] as List<dynamic>?)
            ?.map((c) => AddressComponent.fromJson(c))
            .toList() ??
        [];

    String? streetNumber;
    String? street;
    String? ward;
    String? district;
    String? province;
    String? country;

    for (final comp in components) {
      if (comp.types.contains('street_number')) {
        streetNumber = comp.longName;
      } else if (comp.isStreet) {
        street = comp.longName;
      } else if (comp.isWard) {
        ward = comp.longName;
      } else if (comp.isDistrict) {
        district = comp.longName;
      } else if (comp.isProvince) {
        province = comp.longName;
      } else if (comp.types.contains('country')) {
        country = comp.longName;
      }
    }

    return FullAddress(
      streetNumber: streetNumber,
      street: street,
      ward: ward,
      district: district,
      province: province,
      country: country,
      fullAddress: json['formatted_address'] as String? ?? '',
      latitude: lat,
      longitude: lng,
    );
  }

  /// Create from PlaceDetail
  factory FullAddress.fromPlaceDetail(PlaceDetail detail) {
    String? streetNumber;
    String? street;
    String? ward;
    String? district;
    String? province;
    String? country;

    for (final comp in detail.addressComponents) {
      if (comp.types.contains('street_number')) {
        streetNumber = comp.longName;
      } else if (comp.isStreet) {
        street = comp.longName;
      } else if (comp.isWard) {
        ward = comp.longName;
      } else if (comp.isDistrict) {
        district = comp.longName;
      } else if (comp.isProvince) {
        province = comp.longName;
      } else if (comp.types.contains('country')) {
        country = comp.longName;
      }
    }

    return FullAddress(
      streetNumber: streetNumber,
      street: street,
      ward: ward,
      district: district,
      province: province,
      country: country,
      fullAddress: detail.formattedAddress,
      latitude: detail.latitude,
      longitude: detail.longitude,
    );
  }

  /// Get display text - prioritize fullAddress from API
  String get displayText {
    // Always use fullAddress from API as it's most complete
    if (fullAddress.isNotEmpty) {
      return fullAddress;
    }
    // Fallback: build from components if fullAddress is empty
    final parts = <String>[];
    if (streetNumber != null && streetNumber!.isNotEmpty) {
      parts.add(streetNumber!);
    }
    if (street != null && street!.isNotEmpty) {
      parts.add(street!);
    }
    if (ward != null && ward!.isNotEmpty) {
      parts.add(ward!);
    }
    if (district != null && district!.isNotEmpty) {
      parts.add(district!);
    }
    if (province != null && province!.isNotEmpty) {
      parts.add(province!);
    }
    return parts.join(', ');
  }

  /// Get short display text (street + ward + district)
  String get shortText {
    final parts = <String>[];
    if (street != null && street!.isNotEmpty) {
      if (streetNumber != null && streetNumber!.isNotEmpty) {
        parts.add('$streetNumber $street');
      } else {
        parts.add(street!);
      }
    }
    if (ward != null && ward!.isNotEmpty) {
      parts.add(ward!);
    }
    if (district != null && district!.isNotEmpty) {
      parts.add(district!);
    }
    return parts.isEmpty ? fullAddress : parts.join(', ');
  }
}
