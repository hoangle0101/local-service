import 'package:flutter/material.dart';
import 'package:mobile/data/repositories/track_asia_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import 'package:geolocator/geolocator.dart'; // Added geolocator
import '../../../core/entities/entities.dart';
import '../../../data/datasources/track_asia_datasource.dart';
import '../../../data/storage/secure_storage.dart';
import '../../bloc/bookings/bookings_bloc.dart';
import '../../bloc/bookings/bookings_event_state.dart';
import '../../widgets/minimalist_widgets.dart';

class CreateBookingScreen extends StatefulWidget {
  final int serviceId;
  final ProviderService? service;
  final int? providerId; // For direct booking
  final String? genericServiceName; // For public request

  const CreateBookingScreen({
    super.key,
    required this.serviceId,
    this.service,
    this.providerId,
    this.genericServiceName,
  });

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Default location (Hanoi)
  double _latitude = 21.0285;
  double _longitude = 105.8542;

  // Track Asia API for address autocomplete
  final TrackAsiaRepository _trackAsiaRepository = TrackAsiaRepository();
  List<AddressPrediction> _addressPredictions = [];
  Timer? _debounceTimer;
  bool _showPredictions = false;

  // Service Items Selection
  List<Map<String, dynamic>> _serviceItems = [];
  Map<String, int> _selectedItemQuantities = {}; // itemId -> quantity
  bool _loadingItems = false;
  bool _letProviderQuote =
      false; // true = don't select items, let provider quote

  @override
  void initState() {
    super.initState();
    if (widget.providerId != null) {
      _loadServiceItems();
    }
  }

  Future<void> _loadServiceItems() async {
    debugPrint(
        '[CreateBooking] _loadServiceItems called, providerId=${widget.providerId}');
    if (widget.providerId == null) return;
    setState(() => _loadingItems = true);
    try {
      final dio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:3000'));
      final token = await SecureStorage.getAccessToken();
      final url =
          '/services/${widget.serviceId}/provider/${widget.providerId}/items';
      debugPrint('[CreateBooking] Fetching items from: $url');
      final response = await dio.get(
        url,
        options: token != null
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );
      debugPrint('[CreateBooking] Response: ${response.data}');
      if (mounted) {
        List<dynamic> rawItems;
        if (response.data is List) {
          rawItems = response.data;
        } else if (response.data is Map && response.data['data'] is List) {
          rawItems = response.data['data'];
        } else {
          rawItems = [];
        }
        debugPrint('[CreateBooking] Parsed ${rawItems.length} items');
        setState(() {
          _serviceItems = List<Map<String, dynamic>>.from(rawItems);
          _loadingItems = false;
        });
      }
    } catch (e) {
      debugPrint('[CreateBooking] Load items error: $e');
      if (mounted) setState(() => _loadingItems = false);
    }
  }

  double get _totalFromSelectedItems {
    double total = 0;
    for (final entry in _selectedItemQuantities.entries) {
      final item = _serviceItems.firstWhere(
        (i) => i['id'].toString() == entry.key,
        orElse: () => {},
      );
      if (item.isNotEmpty) {
        final price = _parsePrice(item['price']);
        total += price * entry.value;
      }
    }
    return total;
  }

  num _parsePrice(dynamic price) {
    if (price == null) return 0;
    if (price is num) return price;
    if (price is String) return num.tryParse(price) ?? 0;
    return 0;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onAddressSearch(String query) {
    _debounceTimer?.cancel();

    if (query.length < 3) {
      setState(() {
        _addressPredictions = [];
        _showPredictions = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        final predictions = await _trackAsiaRepository.searchAddress(query);
        if (mounted) {
          setState(() {
            _addressPredictions = predictions;
            _showPredictions = predictions.isNotEmpty;
          });
        }
      } catch (e) {
        debugPrint('[CreateBooking] Address search error: $e');
      }
    });
  }

  Future<void> _selectAddress(AddressPrediction prediction) async {
    setState(() => _showPredictions = false);

    try {
      final detail =
          await _trackAsiaRepository.getPlaceDetail(prediction.placeId);
      if (mounted && detail != null) {
        final fullAddress = FullAddress.fromPlaceDetail(detail);
        setState(() {
          _addressController.text = fullAddress.displayText;
          _latitude = fullAddress.latitude;
          _longitude = fullAddress.longitude;
        });
      } else {
        setState(() => _addressController.text = prediction.description);
      }
    } catch (e) {
      debugPrint('[CreateBooking] Place detail error: $e');
      setState(() => _addressController.text = prediction.description);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BookingsBloc(),
      child: BlocConsumer<BookingsBloc, BookingsState>(
        listener: (context, state) {
          if (state is BookingCreated) {
            _showPremiumSuccessDialog(context, state);
          } else if (state is BookingsError) {
            _showPremiumErrorDialog(context, state.message);
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(context),
                SliverToBoxAdapter(
                  child: Form(
                    
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildServiceInfo(),

                          const SizedBox(height: 32),
                          _buildSectionLabel('THỜI GIAN THỰC HIỆN'),
                          const SizedBox(height: 16),

                          _buildDateTimeSection(),
                          const SizedBox(height: 32),
                          // Service Items Selection (only for direct booking)
                          if (widget.providerId != null) ...[
                            _buildSectionLabel('CHỌN DỊCH VỤ CỤ THỂ'),
                            const SizedBox(height: 16),

                            _buildServiceItemsSection(),

                            const SizedBox(height: 32),
                          ],
                          _buildSectionLabel('ĐỊA ĐIỂM CỦA BẠN'),
                          const SizedBox(height: 16),
                          _buildLocationSection(),
                          const SizedBox(height: 32),
                          _buildSectionLabel('GHI CHÚ THÊM'),
                          const SizedBox(height: 16),
                          _buildNotesSection(),
                          const SizedBox(height: 32),
                          _buildSectionLabel('TỔNG HỢP CHI PHÍ'),
                          const SizedBox(height: 16),
                          _buildPriceSummary(),
                          const SizedBox(height: 48),
                          _buildSubmitButton(context, state),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: 120,
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(24, 64, 24, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 20),
              const Text(
                'Đặt lịch dịch vụ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: AppColors.textTertiary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildServiceInfo() {
    if (widget.service == null && widget.genericServiceName == null) {
      return MinCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.shelf.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child:
                  const Icon(Icons.sync_rounded, color: AppColors.textTertiary),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Đang chuẩn bị thông tin...',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    // Generic Request (No specific provider)
    if (widget.service == null) {
      return MinCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.public_rounded,
                  color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.genericServiceName ?? 'Dịch vụ yêu cầu',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'YÊU CẦU CÔNG KHAI',
                          style: TextStyle(
                              color: AppColors.success,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Direct Booking
    return MinCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.home_repair_service_rounded,
                color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.service!.service.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_pin_rounded,
                        size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      widget.service!.provider.displayName,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Row(
      children: [
        Expanded(
          child: MinCard(
            padding: const EdgeInsets.all(16),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 60)),
                builder: (context, child) => _buildThemePicker(context, child!),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Chọn ngày',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w900)),
                      Text(
                        DateFormat('dd/MM/yyyy').format(_selectedDate),
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MinCard(
            padding: const EdgeInsets.all(16),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
                builder: (context, child) => _buildThemePicker(context, child!),
              );
              if (time != null) setState(() => _selectedTime = time);
            },
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 22, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Chọn giờ',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w900)),
                      Text(
                        _selectedTime.format(context),
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemePicker(BuildContext context, Widget child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          onSurface: AppColors.textPrimary,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
      child: child,
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MinTextField(
          controller: _addressController,
          hint: 'Đang dùng vị trí hiện tại...',
          prefixIcon: const Icon(Icons.location_on_rounded,
              color: AppColors.primary, size: 22),
          suffixIcon: IconButton(
            icon: const Icon(Icons.my_location_rounded,
                color: AppColors.primary, size: 20),
            onPressed: _getCurrentLocation,
          ),
          onChanged: _onAddressSearch,
        ),
        if (_showPredictions && _addressPredictions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _addressPredictions.length,
              separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: AppColors.divider.withOpacity(0.2),
                  indent: 50),
              itemBuilder: (context, index) {
                final prediction = _addressPredictions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_searching_rounded,
                      size: 16, color: AppColors.textTertiary),
                  title: Text(prediction.mainText,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                  subtitle: Text(prediction.secondaryText,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w500)),
                  onTap: () => _selectAddress(prediction),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.shelf.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.gps_fixed_rounded,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TỌA ĐỘ GPS',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textTertiary)),
                  Text(
                    '${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _latitude = 0); // Trigger loading state if needed on UI

    try {
      // 1. Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Cần cấp quyền vị trí để sử dụng tính năng này.',
              isError: true);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar(
            'Quyền vị trí bị từ chối vĩnh viễn. Hãy kiểm tra cài đặt.',
            isError: true);
        return;
      }

      // 2. Get Position
      // 2. Get Position - Silent update

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3. Reverse Geocode
      final fullAddress = await _trackAsiaRepository.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _addressController.text = fullAddress?.displayText ??
              '${position.latitude}, ${position.longitude}';
        });

        // Silent success
      }
    } catch (e) {
      debugPrint('Location error: $e');
      _showSnackBar('Không thể lấy vị trí hiện tại: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.error : AppColors.success,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildNotesSection() {
    return MinTextField(
      controller: _notesController,
      maxLines: 3,
      hint: 'Ví dụ: Cổng số 2, gọi trước khi đến, hoặc lưu ý đặc biệt...',
      prefixIcon: const Icon(Icons.note_add_rounded,
          color: AppColors.primary, size: 22),
    );
  }

  Widget _buildServiceItemsSection() {
    if (_loadingItems) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_serviceItems.isEmpty) {
      return MinCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                size: 24, color: AppColors.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Thợ chưa có bảng giá. Giá sẽ được báo sau khi kiểm tra.',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Let provider quote toggle
        MinCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          onTap: () => setState(() => _letProviderQuote = !_letProviderQuote),
          child: Row(
            children: [
              Icon(
                _letProviderQuote
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                color: _letProviderQuote
                    ? AppColors.primary
                    : AppColors.textTertiary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Để thợ báo giá sau khi kiểm tra',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _letProviderQuote
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!_letProviderQuote) ...[
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider.withOpacity(0.3)),
            ),
            child: Column(
              children: _serviceItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final itemId = item['id'].toString();
                final isLast = index == _serviceItems.length - 1;
                final quantity = _selectedItemQuantities[itemId] ?? 0;
                final price = _parsePrice(item['price']);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(
                            bottom: BorderSide(
                                color: AppColors.divider.withOpacity(0.3))),
                  ),
                  child: Row(
                    children: [
                      // Item info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormat
                                  .format(price)
                                  .replaceAll(',00', ''),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Quantity controls
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (quantity > 0) {
                                setState(() {
                                  if (quantity == 1) {
                                    _selectedItemQuantities.remove(itemId);
                                  } else {
                                    _selectedItemQuantities[itemId] =
                                        quantity - 1;
                                  }
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: quantity > 0
                                    ? AppColors.primary.withOpacity(0.1)
                                    : AppColors.shelf,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.remove_rounded,
                                size: 18,
                                color: quantity > 0
                                    ? AppColors.primary
                                    : AppColors.textTertiary,
                              ),
                            ),
                          ),
                          Container(
                            width: 36,
                            alignment: Alignment.center,
                            child: Text(
                              quantity.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: quantity > 0
                                    ? AppColors.primary
                                    : AppColors.textTertiary,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedItemQuantities[itemId] = quantity + 1;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          if (_selectedItemQuantities.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng dịch vụ đã chọn:',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary),
                  ),
                  Text(
                    currencyFormat
                        .format(_totalFromSelectedItems)
                        .replaceAll(',00', ''),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildPriceSummary() {
    // Case 1: User selected "let provider quote later"
    if (_letProviderQuote ||
        (_serviceItems.isNotEmpty &&
            _selectedItemQuantities.isEmpty &&
            !_letProviderQuote == false)) {
      // When provider will quote later - show pending message
      if (_letProviderQuote) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.divider.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 24, color: AppColors.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'CHỜ BÁO GIÁ',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Thợ sẽ kiểm tra và gửi báo giá cho bạn sau.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    }

    // Case 2: User selected specific items - show their total
    if (_selectedItemQuantities.isNotEmpty) {
      final total = _totalFromSelectedItems;
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.divider.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            ...(_selectedItemQuantities.entries.map((entry) {
              final item = _serviceItems.firstWhere(
                (i) => i['id'].toString() == entry.key,
                orElse: () => {},
              );
              if (item.isEmpty) return const SizedBox.shrink();
              final price = _parsePrice(item['price']);
              final itemTotal = price * entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPriceRow(
                  '${item['name']} x${entry.value}',
                  itemTotal.toDouble(),
                ),
              );
            }).toList()),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: AppColors.divider),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TỔNG CỘNG',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5),
                ),
                Text(
                  NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                      .format(total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Case 3: Default - show base price
    final price = widget.service?.price ?? 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          _buildPriceRow('Giá dịch vụ (tham khảo)', price),
          const SizedBox(height: 16),
          Row(
            children: const [
              Icon(Icons.info_outline_rounded,
                  size: 14, color: AppColors.textTertiary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Chọn dịch vụ cụ thể bên trên để xem giá chính xác.',
                  style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isFree = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
        Text(
          isFree
              ? 'Miễn phí'
              : NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                  .format(amount),
          style: TextStyle(
              fontWeight: FontWeight.w900,
              color: isFree ? AppColors.success : AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context, BookingsState state) {
    return MinButton(
      text: 'XÁC NHẬN ĐẶT LỊCH',
      onPressed: () => _submitBooking(context),
      isLoading: state is BookingsLoading,
    );
  }

  void _submitBooking(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final scheduledAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Prepare selected items list for backend
      List<Map<String, dynamic>>? selectedItems;
      if (widget.providerId != null &&
          !_letProviderQuote &&
          _selectedItemQuantities.isNotEmpty) {
        selectedItems = _selectedItemQuantities.entries
            .map((e) => {'itemId': e.key, 'quantity': e.value})
            .toList();
      }

      context.read<BookingsBloc>().add(CreateBookingEvent(
            serviceId: widget.serviceId,
            scheduledAt: scheduledAt,
            addressText: _addressController.text,
            latitude: _latitude,
            longitude: _longitude,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
            providerId: widget.providerId,
            selectedItems: selectedItems,
          ));
    }
  }

  void _showPremiumSuccessDialog(BuildContext context, BookingCreated state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 64),
              ),
              const SizedBox(height: 24),
              const Text(
                'Đặt lịch thành công!',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                'Mã vận đơn: ${state.bookingCode}',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              MinButton(
                text: 'XEM ĐƠN ĐẶT',
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.go('/user/bookings');
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.go('/user/home');
                },
                child: const Text('VỀ TRANG CHỦ',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textTertiary,
                        letterSpacing: 1)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPremiumErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 60),
              ),
              const SizedBox(height: 24),
              const Text(
                'Không thể đặt lịch',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage.replaceAll('Exception:', '').trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    height: 1.5),
              ),
              const SizedBox(height: 32),
              MinButton(
                text: 'QUAY LẠI',
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
