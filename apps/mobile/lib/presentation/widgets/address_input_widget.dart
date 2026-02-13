import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/datasources/track_asia_datasource.dart';
import '../../core/utils/geo_utils.dart';

/// Reusable widget for address input with autocomplete and GPS support
class AddressInputWidget extends StatefulWidget {
  /// Initial address text
  final String? initialAddress;

  /// Initial latitude
  final double? initialLatitude;

  /// Initial longitude
  final double? initialLongitude;

  /// Reference point for distance calculation (optional)
  final double? referenceLatitude;
  final double? referenceLongitude;

  /// Callback when address is selected
  final void Function(FullAddress address)? onAddressSelected;

  /// Callback when coordinates change
  final void Function(double lat, double lng)? onCoordinatesChanged;

  /// Label text
  final String label;

  /// Hint text
  final String hint;

  /// Show GPS button
  final bool showGpsButton;

  /// Show coordinates display
  final bool showCoordinates;

  /// Show distance from reference point
  final bool showDistance;

  const AddressInputWidget({
    super.key,
    this.initialAddress,
    this.initialLatitude,
    this.initialLongitude,
    this.referenceLatitude,
    this.referenceLongitude,
    this.onAddressSelected,
    this.onCoordinatesChanged,
    this.label = 'Địa chỉ',
    this.hint = 'Nhập địa chỉ để tìm kiếm...',
    this.showGpsButton = true,
    this.showCoordinates = true,
    this.showDistance = false,
  });

  @override
  State<AddressInputWidget> createState() => _AddressInputWidgetState();
}

class _AddressInputWidgetState extends State<AddressInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final TrackAsiaDataSource _trackAsiaDataSource = TrackAsiaDataSource();

  List<AddressPrediction> _suggestions = [];
  Timer? _debounce;
  bool _showSuggestions = false;
  bool _isGettingLocation = false;
  double? _latitude;
  double? _longitude;
  FullAddress? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialAddress ?? '';
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onAddressChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.length < 3) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final suggestions = await _trackAsiaDataSource.searchAddress(query);
        if (mounted) {
          setState(() {
            _suggestions = suggestions;
            _showSuggestions = suggestions.isNotEmpty;
          });
        }
      } catch (e) {
        debugPrint('[AddressInput] Search error: $e');
      }
    });
  }

  Future<void> _selectSuggestion(AddressPrediction prediction) async {
    setState(() => _showSuggestions = false);

    try {
      final detail =
          await _trackAsiaDataSource.getPlaceDetail(prediction.placeId);
      if (mounted && detail != null) {
        final fullAddress = FullAddress.fromPlaceDetail(detail);
        setState(() {
          _controller.text = fullAddress.displayText;
          _latitude = fullAddress.latitude;
          _longitude = fullAddress.longitude;
          _selectedAddress = fullAddress;
        });
        widget.onAddressSelected?.call(fullAddress);
        widget.onCoordinatesChanged
            ?.call(fullAddress.latitude, fullAddress.longitude);
      } else if (mounted) {
        setState(() => _controller.text = prediction.description);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      // Check location services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Vui lòng bật dịch vụ định vị'),
              backgroundColor: Colors.orange.shade400,
              action: SnackBarAction(
                label: 'Mở cài đặt',
                textColor: Colors.white,
                onPressed: () => Geolocator.openLocationSettings(),
              ),
            ),
          );
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Quyền truy cập vị trí bị từ chối'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isGettingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Quyền vị trí bị từ chối vĩnh viễn'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Mở cài đặt',
                textColor: Colors.white,
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocode to get full address
      final address = await _trackAsiaDataSource.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        if (address != null) {
          setState(() {
            _controller.text = address.displayText;
            _latitude = address.latitude;
            _longitude = address.longitude;
            _selectedAddress = address;
            _isGettingLocation = false;
          });
          widget.onAddressSelected?.call(address);
          widget.onCoordinatesChanged
              ?.call(address.latitude, address.longitude);
        } else {
          // Fallback: use coordinates only
          setState(() {
            _controller.text =
                'Vị trí: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
            _latitude = position.latitude;
            _longitude = position.longitude;
            _isGettingLocation = false;
          });
          widget.onCoordinatesChanged
              ?.call(position.latitude, position.longitude);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.location_on, color: Colors.white),
                SizedBox(width: 8),
                Text('Đã lấy vị trí GPS thành công!'),
              ],
            ),
            backgroundColor: Colors.green.shade400,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGettingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lấy vị trí: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  double? _getDistance() {
    if (_latitude == null ||
        _longitude == null ||
        widget.referenceLatitude == null ||
        widget.referenceLongitude == null) {
      return null;
    }
    return GeoUtils.calculateDistance(
      _latitude!,
      _longitude!,
      widget.referenceLatitude!,
      widget.referenceLongitude!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final distance = _getDistance();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 10),

        // Address input field
        TextFormField(
          controller: _controller,
          onChanged: _onAddressChanged,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(Icons.location_on,
                  color: Colors.green.shade600, size: 22),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.green.shade600, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),

        // Suggestions dropdown
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 220),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (context, index) {
                  final s = _suggestions[index];
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.location_on,
                          color: Colors.green.shade600, size: 20),
                    ),
                    title: Text(s.mainText,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(
                      s.secondaryText,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _selectSuggestion(s),
                  );
                },
              ),
            ),
          ),

        // GPS Button
        if (widget.showGpsButton)
          Container(
            margin: const EdgeInsets.only(top: 12),
            child: ElevatedButton.icon(
              onPressed: _isGettingLocation ? null : _getCurrentLocation,
              icon: _isGettingLocation
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.green.shade700,
                      ),
                    )
                  : Icon(Icons.my_location,
                      size: 18, color: Colors.green.shade700),
              label: Text(
                _isGettingLocation
                    ? 'Đang lấy vị trí...'
                    : 'Lấy vị trí GPS hiện tại',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade50,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.green.shade200),
                ),
              ),
            ),
          ),

        // Coordinates display
        if (widget.showCoordinates && _latitude != null && _longitude != null)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.gps_fixed,
                        size: 18, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Đã xác định',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                // Address components detail (if available)
                if (_selectedAddress != null) ...[
                  const SizedBox(height: 8),
                  _buildAddressDetail(),
                ],
              ],
            ),
          ),

        // Distance display
        if (widget.showDistance && distance != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.straighten, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 6),
                Text(
                  'Khoảng cách: ${GeoUtils.formatDistance(distance)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAddressDetail() {
    final addr = _selectedAddress!;
    final details = <String>[];

    if (addr.street != null && addr.street!.isNotEmpty) {
      String street = addr.street!;
      if (addr.streetNumber != null && addr.streetNumber!.isNotEmpty) {
        street = '${addr.streetNumber} $street';
      }
      details.add('🏠 $street');
    }
    if (addr.ward != null && addr.ward!.isNotEmpty) {
      details.add('📍 ${addr.ward}');
    }
    if (addr.district != null && addr.district!.isNotEmpty) {
      details.add('🏛️ ${addr.district}');
    }
    if (addr.province != null && addr.province!.isNotEmpty) {
      details.add('🌆 ${addr.province}');
    }

    if (details.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: details
          .map((d) => Text(
                d,
                style: TextStyle(fontSize: 11, color: Colors.green.shade700),
              ))
          .toList(),
    );
  }
}
