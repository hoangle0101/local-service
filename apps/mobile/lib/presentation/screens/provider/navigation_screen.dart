import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/data/repositories/directions_repository.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/directions_datasource.dart';
import '../../widgets/minimalist_widgets.dart';

/// In-app navigation screen with real-time location tracking
/// Shows route from provider's current location to customer's address
class NavigationScreen extends StatefulWidget {
  final double destinationLat;
  final double destinationLng;
  final String? destinationAddress;
  final String? customerName;

  const NavigationScreen({
    super.key,
    required this.destinationLat,
    required this.destinationLng,
    this.destinationAddress,
    this.customerName,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final MapController _mapController = MapController();
  final DirectionsRepository _directionsRepository = DirectionsRepository();

  LatLng? _currentPosition;
  LatLng get _destination =>
      LatLng(widget.destinationLat, widget.destinationLng);

  List<LatLng> _routePoints = [];
  DirectionsResult? _directionsResult;

  bool _isLoading = true;
  String? _error;

  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    // Show map immediately, load location and route in background
    _isLoading = false;
    _initLocationAndRoute();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initLocationAndRoute() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[NavigationScreen] Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[NavigationScreen] Location permission denied forever');
        return;
      }

      // Get current position (don't block UI)
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      if (!mounted) return;
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      // Get route in background
      await _fetchRoute();

      // Start listening to position updates
      _startPositionStream();
    } catch (e) {
      debugPrint('[NavigationScreen] Location error: $e');
      // Don't show error - just proceed without current position
    }
  }

  Future<void> _fetchRoute() async {
    if (_currentPosition == null) return;

    try {
      final result = await _directionsRepository.getRoute(
        origin: _currentPosition!,
        destination: _destination,
      );

      setState(() {
        _routePoints = result.routePoints;
        _directionsResult = result;
      });
    } catch (e) {
      debugPrint('[NavigationScreen] Route error: $e');
      // Don't show error for route - still show markers
    }
  }

  void _startPositionStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
    });
  }

  void _centerOnCurrentPosition() {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 15);
    }
  }

  void _fitBothMarkers() {
    if (_currentPosition == null) return;

    final bounds = LatLngBounds.fromPoints([_currentPosition!, _destination]);
    _mapController.move(
      bounds.center,
      15,
    );
  }

  Future<void> _openExternalMaps() async {
    final googleNavUrl = Uri.parse(
      'google.navigation:q=${widget.destinationLat},${widget.destinationLng}&mode=d',
    );
    final googleDirectionsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${widget.destinationLat},${widget.destinationLng}&travelmode=driving',
    );

    try {
      if (await canLaunchUrl(googleNavUrl)) {
        await launchUrl(googleNavUrl);
      } else if (await canLaunchUrl(googleDirectionsUrl)) {
        await launchUrl(googleDirectionsUrl,
            mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[NavigationScreen] Error opening external maps: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : _buildMap(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Đang tải bản đồ...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off_rounded,
                size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Đã có lỗi xảy ra',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            MinButton(
              text: 'Thử lại',
              onPressed: _initLocationAndRoute,
            ),
            const SizedBox(height: 12),
            MinButton(
              text: 'Mở Google Maps',
              isPrimary: false,
              onPressed: _openExternalMaps,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return Stack(
      children: [
        // Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentPosition ?? _destination,
            initialZoom: 14,
            onMapReady: _fitBothMarkers,
          ),
          children: [
            // Tile layer (OpenStreetMap)
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.localservice.app',
            ),

            // Route polyline
            if (_routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 5,
                    color: AppColors.primary,
                  ),
                ],
              ),

            // Markers
            MarkerLayer(
              markers: [
                // Current position marker (provider)
                if (_currentPosition != null)
                  Marker(
                    point: _currentPosition!,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.navigation_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),

                // Destination marker (customer)
                Marker(
                  point: _destination,
                  width: 50,
                  height: 60,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        // Top bar with back button
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 12),
              // Info card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.customerName != null)
                        Text(
                          widget.customerName!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      if (widget.destinationAddress != null)
                        Text(
                          widget.destinationAddress!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom info panel
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Route info
                if (_directionsResult != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildInfoItem(
                        Icons.route_rounded,
                        _directionsResult!.formattedDistance,
                        'Khoảng cách',
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.divider,
                      ),
                      _buildInfoItem(
                        Icons.access_time_rounded,
                        _directionsResult!.formattedDuration,
                        'Thời gian',
                      ),
                    ],
                  )
                else
                  const Text(
                    'Đang tính toán đường đi...',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                const SizedBox(height: 20),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: MinButton(
                        text: 'VỊ TRÍ',
                        isPrimary: false,
                        icon: Icons.my_location_rounded,
                        onPressed: _centerOnCurrentPosition,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MinButton(
                        text: 'TOÀN BỘ',
                        icon: Icons.zoom_out_map_rounded,
                        onPressed: _fitBothMarkers,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
