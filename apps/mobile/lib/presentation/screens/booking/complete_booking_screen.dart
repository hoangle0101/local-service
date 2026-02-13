import 'package:flutter/material.dart';
import 'package:mobile/data/repositories/track_asia_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/entities/entities.dart';
import '../../../data/datasources/track_asia_datasource.dart';
import '../../bloc/bookings/bookings_bloc.dart';
import '../../bloc/bookings/bookings_event_state.dart';
import '../../bloc/services/services_bloc.dart';
import '../../bloc/services/services_event_state.dart';
import '../../bloc/categories/categories_bloc.dart';
import '../../bloc/categories/categories_event_state.dart';
import '../../widgets/minimalist_widgets.dart';

class CompleteBookingScreen extends StatefulWidget {
  const CompleteBookingScreen({super.key});

  @override
  State<CompleteBookingScreen> createState() => _CompleteBookingScreenState();
}

class _CompleteBookingScreenState extends State<CompleteBookingScreen> {
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  Category? _selectedCategory;
  Service? _selectedGenericService;
  ProviderService? _selectedProvider;
  int _currentStep = 1;

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

  bool _useGPS = true;
  double _latitude = 21.0285;
  double _longitude = 105.8542;

  final TrackAsiaRepository _trackAsiaRepository = TrackAsiaRepository();
  List<AddressPrediction> _addressPredictions = [];
  Timer? _debounceTimer;
  bool _showPredictions = false;

  @override
  void initState() {
    super.initState();
    context.read<CategoriesBloc>().add(LoadCategories());
    context.read<ServicesBloc>().add(const LoadServices());
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
        debugPrint('[CompleteBooking] Address search error: $e');
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
      }
    } catch (e) {
      debugPrint('[CompleteBooking] Place detail error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingsBloc, BookingsState>(
      listener: (context, state) {
        if (state is BookingCreated) {
          context.go('/user/bookings');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Container(
          color: AppColors.background,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStepIndicator(),
                    const SizedBox(height: 32),
                    if (_currentStep == 1) ...[
                      _buildSectionLabel('1. CHỌN LOẠI DỊCH VỤ'),
                      const SizedBox(height: 16),
                      _buildCategorySelector(),
                      const SizedBox(height: 24),
                      _buildServiceSelector(),
                    ] else if (_currentStep == 2) ...[
                      _buildSectionLabel('2. CHỌN THỢ XUNG QUANH'),
                      const SizedBox(height: 16),
                      _buildNearbyProvidersSection(),
                    ] else ...[
                      _buildSectionLabel('3. THÔNG TIN CHI TIẾT'),
                      const SizedBox(height: 16),
                      _buildDateTimeSection(),
                      const SizedBox(height: 32),
                      _buildSectionLabel('4. ĐỊA CHỈ LÀM VIỆC'),
                      const SizedBox(height: 16),
                      _buildAddressSection(),
                      const SizedBox(height: 32),
                      _buildNotesSection(),
                      const SizedBox(height: 32),
                      _buildSectionLabel('5. TÓM TẮT CHI PHÍ'),
                      const SizedBox(height: 16),
                      _buildPriceSummary(),
                    ],
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepItem(1, 'Dịch vụ', _currentStep >= 1),
        _buildStepDivider(),
        _buildStepItem(2, 'Chọn thợ', _currentStep >= 2),
        _buildStepDivider(),
        _buildStepItem(3, 'Đặt lịch', _currentStep >= 3),
      ],
    );
  }

  Widget _buildStepItem(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color:
                isActive ? AppColors.primary : AppColors.shelf.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive ? AppColors.white : AppColors.textTertiary,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.textPrimary : AppColors.textTertiary,
            fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider() {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24, left: 12, right: 12),
        color: AppColors.shelf.withOpacity(0.2),
      ),
    );
  }

  Widget _buildBottomBar() {
    String text = 'TIẾP TỤC';
    VoidCallback? onPressed;

    if (_currentStep == 1 && _selectedGenericService != null) {
      onPressed = () {
        setState(() => _currentStep = 2);
        _fetchNearbyProviders();
      };
    } else if (_currentStep == 2 && _selectedProvider != null) {
      onPressed = () => setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      text = 'XÁC NHẬN ĐẶT LỊCH';
      onPressed = _submitBooking;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5))
        ],
      ),
      child: MinButton(
        text: text,
        onPressed: onPressed,
      ),
    );
  }

  void _fetchNearbyProviders() {
    if (_selectedGenericService != null) {
      context.read<ServicesBloc>().add(SearchNearbyProviders(
            serviceId: _selectedGenericService!.id,
            latitude: _latitude,
            longitude: _longitude,
          ));
    }
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
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
                          offset: const Offset(0, 4)),
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
                    letterSpacing: -0.5),
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
          letterSpacing: 1.2),
    );
  }

  Widget _buildCategorySelector() {
    return BlocBuilder<CategoriesBloc, CategoriesState>(
      builder: (context, state) {
        if (state is CategoriesLoaded) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: state.categories.map((cat) {
                final isSelected = _selectedCategory?.id == cat.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedCategory = cat;
                      _selectedGenericService = null;
                      _selectedProvider = null;
                      context
                          .read<ServicesBloc>()
                          .add(LoadGenericServices(categoryId: cat.id));
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.white,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.divider.withOpacity(0.5)),
                      ),
                      child: Text(
                        cat.name,
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }
        return const SizedBox(
            height: 50, child: Center(child: CircularProgressIndicator()));
      },
    );
  }

  Widget _buildServiceSelector() {
    if (_selectedCategory == null) {
      return MinCard(
        backgroundColor: AppColors.shelf.withOpacity(0.3),
        child: const Center(
          child: Text('Vui lòng chọn danh mục trước',
              style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ),
      );
    }

    return BlocBuilder<ServicesBloc, ServicesState>(
      builder: (context, state) {
        if (state is GenericServicesLoaded) {
          if (state.services.isEmpty) {
            return const Center(
                child: Text('Không có loại dịch vụ nào trong danh mục này',
                    style: TextStyle(fontSize: 13)));
          }
          return Column(
            children:
                state.services.map((s) => _buildGenericServiceCard(s)).toList(),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildNearbyProvidersSection() {
    return BlocBuilder<ServicesBloc, ServicesState>(
      builder: (context, state) {
        if (state is ServicesLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ServicesLoaded) {
          if (state.services.isEmpty) {
            return Center(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Icon(Icons.person_off_rounded,
                      size: 48, color: AppColors.textTertiary.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text('Không tìm thấy thợ nào ở gần bạn',
                      style: TextStyle(
                          color: AppColors.textTertiary, fontSize: 13)),
                  const SizedBox(height: 8),
                  const Text('Vui lòng thử lại với dịch vụ hoặc vị trí khác',
                      style: TextStyle(
                          color: AppColors.textTertiary, fontSize: 12)),
                ],
              ),
            );
          }
          return Column(
            children: state.services.map((s) => _buildProviderCard(s)).toList(),
          );
        }
        if (state is ServicesError) {
          return Center(child: Text('Lỗi: ${state.message}'));
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildProviderCard(ProviderService s) {
    final isSelected = _selectedProvider?.providerUserId == s.providerUserId;
    final distanceKm = (s.distance ?? 0) / 1000;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MinCard(
        onTap: () => setState(() => _selectedProvider = s),
        backgroundColor:
            isSelected ? AppColors.primary.withOpacity(0.05) : AppColors.white,
        border: isSelected
            ? const BorderSide(color: AppColors.primary, width: 2)
            : null,
        child: Row(
          children: [
            _buildAvatar(s.provider.avatarUrl),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.provider.displayName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(s.provider.rating?.toStringAsFixed(1) ?? 'N/A',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 12)),
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on_rounded,
                          color: AppColors.textTertiary, size: 14),
                      const SizedBox(width: 2),
                      Text('${distanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(
                              color: AppColors.textTertiary, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            _buildPriceText(s.price),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? url) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.shelf.withOpacity(0.2),
        shape: BoxShape.circle,
        image: url != null
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      child: url == null
          ? const Icon(Icons.person_rounded, color: AppColors.textTertiary)
          : null,
    );
  }

  Widget _buildGenericServiceCard(Service s) {
    final isSelected = _selectedGenericService?.id == s.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MinCard(
        onTap: () => setState(() {
          _selectedGenericService = s;
          _selectedProvider = null;
        }),
        backgroundColor:
            isSelected ? AppColors.primary.withOpacity(0.05) : AppColors.white,
        border: isSelected
            ? const BorderSide(color: AppColors.primary, width: 2)
            : null,
        child: Row(
          children: [
            _buildServiceIcon(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 15)),
                  Text(s.description ?? 'Dịch vụ chuyên nghiệp',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 12)),
                ],
              ),
            ),
            if (s.basePrice > 0) _buildPriceText(s.basePrice),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceIcon() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
      child: const Icon(Icons.star_rounded, color: AppColors.primary, size: 20),
    );
  }

  Widget _buildPriceText(double price) {
    return Text(
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
          .format(price)
          .replaceAll(',00', ''),
      style: const TextStyle(
          fontWeight: FontWeight.w900, color: AppColors.primary),
    );
  }

  Widget _buildDateTimeSection() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Row(
      children: [
        Expanded(
          child: MinCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(dateFormat.format(_selectedDate),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MinCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            onTap: () async {
              final time = await showTimePicker(
                  context: context, initialTime: _selectedTime);
              if (time != null) setState(() => _selectedTime = time);
            },
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(_selectedTime.format(context),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Column(
      children: [
        MinTextField(
          controller: _addressController,
          hint: _useGPS
              ? 'Vị trí hiện tại của bạn...'
              : 'Nhập địa chỉ nhà, số phòng...',
          prefixIcon: const Icon(Icons.location_on_rounded,
              color: AppColors.primary, size: 22),
          onChanged: _onAddressSearch,
        ),
        if (!_useGPS && _showPredictions && _addressPredictions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider.withOpacity(0.3)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _addressPredictions.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: AppColors.divider.withOpacity(0.2)),
              itemBuilder: (context, index) {
                final p = _addressPredictions[index];
                return ListTile(
                  title: Text(p.mainText,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                  subtitle: Text(p.secondaryText,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textTertiary)),
                  onTap: () => _selectAddress(p),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return MinTextField(
      controller: _notesController,
      maxLines: 3,
      hint: 'Chỉ dẫn thêm cho người làm...',
      prefixIcon: const Icon(Icons.note_add_rounded,
          color: AppColors.primary, size: 22),
    );
  }

  Widget _buildPriceSummary() {
    final double price = _selectedProvider?.price ?? 0;
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Giá dịch vụ',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700)),
              Text(formatter.format(price),
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary)),
            ],
          ),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(height: 1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TỔNG CỘNG',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              Text(formatter.format(price),
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      color: AppColors.primary,
                      letterSpacing: -1)),
            ],
          ),
        ],
      ),
    );
  }

  void _submitBooking() {
    if (_selectedProvider == null) return;

    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    context.read<BookingsBloc>().add(CreateBookingEvent(
          serviceId: _selectedProvider!.serviceId,
          providerId:
              int.tryParse(_selectedProvider!.providerUserId.toString()),
          scheduledAt: scheduledAt,
          addressText: _addressController.text,
          latitude: _latitude,
          longitude: _longitude,
          notes: _notesController.text,
        ));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang gửi yêu cầu đặt lịch cho thợ...'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
