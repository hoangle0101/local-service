import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';

class MiniMapWidget extends StatelessWidget {
  final LatLng initialCenter;
  final double initialZoom;
  final List<Marker> markers;
  final bool interactive;

  final MapController? mapController;

  const MiniMapWidget({
    super.key,
    required this.initialCenter,
    this.initialZoom = 15.0,
    this.markers = const [],
    this.interactive = true,
    this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.localservice.app',
        ),
        MarkerLayer(
          markers: [
            // Current Location Marker (standard for driver apps)
            Marker(
              point: initialCenter,
              width: 60,
              height: 60,
              child: _buildLocationMarker(),
            ),
            ...markers,
          ],
        ),
      ],
    );
  }

  Widget _buildLocationMarker() {
    return Container(
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
    );
  }
}
