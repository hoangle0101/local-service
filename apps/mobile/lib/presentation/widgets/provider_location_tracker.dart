import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/socket_service.dart';

/// Widget that displays real-time provider location on a map
/// Used by customers to track provider's location during active bookings
class ProviderLocationTracker extends StatefulWidget {
  final String bookingId;
  final LatLng customerLocation;
  final String? providerName;

  const ProviderLocationTracker({
    super.key,
    required this.bookingId,
    required this.customerLocation,
    this.providerName,
  });

  @override
  State<ProviderLocationTracker> createState() =>
      _ProviderLocationTrackerState();
}

class _ProviderLocationTrackerState extends State<ProviderLocationTracker> {
  final SocketService _socketService = SocketService();
  final MapController _mapController = MapController();
  StreamSubscription<ProviderLocationUpdate>? _locationSubscription;

  LatLng? _providerLocation;
  double? _providerHeading;
  bool _isConnected = false;
  DateTime? _lastUpdate;

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _socketService.unsubscribeFromLocation(widget.bookingId);
    _mapController.dispose();
    super.dispose();
  }

  void _initLocationTracking() async {
    await _socketService.connectAsync();

    // Subscribe to location updates for this booking
    _socketService.subscribeToLocation(widget.bookingId);

    // Listen for location updates
    _locationSubscription = _socketService.locationStream.listen(
      (update) {
        if (update.bookingId == widget.bookingId) {
          debugPrint('[ProviderLocationTracker] Location update received');
          setState(() {
            _providerLocation = LatLng(update.latitude, update.longitude);
            _providerHeading = update.heading;
            _lastUpdate = update.timestamp;
            _isConnected = true;
          });

          // Fit map to show both locations
          _fitMapToBounds();
        }
      },
    );

    // Listen for connection status
    _socketService.connectionStream.listen((connected) {
      if (mounted) {
        setState(() => _isConnected = connected);
      }
    });
  }

  void _fitMapToBounds() {
    if (_providerLocation == null) return;

    try {
      final bounds = LatLngBounds.fromPoints([
        widget.customerLocation,
        _providerLocation!,
      ]);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
      );
    } catch (e) {
      debugPrint('Map fit error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Map
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.customerLocation,
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.localservice.app',
                ),
                MarkerLayer(
                  markers: [
                    // Customer location marker
                    Marker(
                      point: widget.customerLocation,
                      width: 50,
                      height: 60,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
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
                    // Provider location marker
                    if (_providerLocation != null)
                      Marker(
                        point: _providerLocation!,
                        width: 50,
                        height: 50,
                        child: Transform.rotate(
                          angle: (_providerHeading ?? 0) * (3.14159 / 180),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.success.withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
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
                      ),
                  ],
                ),
              ],
            ),

            // Status overlay
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _isConnected
                            ? AppColors.success
                            : AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.providerName ?? 'Thợ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _getStatusText(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_providerLocation != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getDistanceText(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Recenter button
            Positioned(
              bottom: 16,
              right: 16,
              child: GestureDetector(
                onTap: _fitMapToBounds,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.center_focus_strong_rounded,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    if (!_isConnected) {
      return 'Đang kết nối...';
    }
    if (_providerLocation == null) {
      return 'Đang chờ vị trí...';
    }
    if (_lastUpdate != null) {
      final diff = DateTime.now().difference(_lastUpdate!);
      if (diff.inSeconds < 10) {
        return 'Đang di chuyển';
      }
      return 'Cập nhật ${diff.inSeconds}s trước';
    }
    return 'Đang theo dõi';
  }

  String _getDistanceText() {
    if (_providerLocation == null) return '';

    final distance = const Distance();
    final meters = distance.as(
      LengthUnit.Meter,
      widget.customerLocation,
      _providerLocation!,
    );

    if (meters < 1000) {
      return '${meters.toInt()}m';
    }
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }
}
