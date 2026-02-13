import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/entities/entities.dart';
import '../../../core/services/socket_service.dart';
import '../../../data/repositories/bookings_repository.dart';
import '../../bloc/categories/categories_bloc.dart';
import '../../bloc/categories/categories_event_state.dart';
import '../../bloc/services/services_bloc.dart';
import '../../bloc/services/services_event_state.dart';
import '../../bloc/bookings/bookings_event_state.dart';
import '../../widgets/minimalist_widgets.dart';

class JobMarketScreen extends StatefulWidget {
  const JobMarketScreen({super.key});

  @override
  State<JobMarketScreen> createState() => _JobMarketScreenState();
}

class _JobMarketScreenState extends State<JobMarketScreen> {
  Category? _selectedCategory;
  Service? _selectedService;
  List<Booking> _jobs = [];
  bool _isLoadingJobs = false;
  final BookingsRepository _bookingsRepository = BookingsRepository();

  // Socket service for real-time updates
  final SocketService _socketService = SocketService();
  StreamSubscription<NewJobEvent>? _newJobSubscription;
  StreamSubscription<JobTakenEvent>? _jobTakenSubscription;
  StreamSubscription<BookingStatusUpdate>? _bookingStatusSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    context.read<CategoriesBloc>().add(LoadCategories());
    _fetchJobs(); // Load all pending jobs initially
    _initSocketConnection();
  }

  @override
  void dispose() {
    _newJobSubscription?.cancel();
    _jobTakenSubscription?.cancel();
    _bookingStatusSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  /// Initialize socket connection and subscribe to job market updates
  void _initSocketConnection() async {
    await _socketService.connectAsync();

    // Subscribe to job market for all categories initially
    _socketService.subscribeToJobMarket();

    // Listen for new job events
    _newJobSubscription = _socketService.newJobStream.listen(
      (event) {
        debugPrint('[JobMarketScreen] New job available: ${event.bookingId}');

        // Refresh the job list to include the new job
        _fetchJobs();

        // Show a snackbar notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Có việc mới: ${event.serviceName}'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'XEM',
                textColor: Colors.white,
                onPressed: () {
                  // Job list will already be refreshed
                },
              ),
            ),
          );
        }
      },
    );

    // Listen for job taken events (to remove from list)
    _jobTakenSubscription = _socketService.jobTakenStream.listen(
      (event) {
        debugPrint('[JobMarketScreen] Job taken: ${event.bookingId}');

        // Remove the job from local list immediately
        if (mounted) {
          setState(() {
            _jobs.removeWhere((job) => job.id == event.bookingId);
          });

          // Show notification only if someone else took the job
          if (event.takenByProviderId != _socketService.currentUserId) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Một đơn hàng đã có người nhận'),
                backgroundColor: AppColors.textSecondary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
    );

    _bookingStatusSubscription = _socketService.bookingStatusStream.listen(
      (update) {
        debugPrint(
            '[JobMarketScreen] Status Update: ${update.status}, providerId=${update.providerId}, currentUserId=${_socketService.currentUserId}');

        // Refresh the job list if relevant
        _fetchJobs();

        // The booking dialog for direct jobs is now handled globally in ProviderShellScreen
      },
    );
  }

  Future<void> _fetchJobs() async {
    if (!mounted) return;
    setState(() => _isLoadingJobs = true);
    try {
      final jobs = await _bookingsRepository.getGlobalRequests(
        serviceId: _selectedService?.id,
        categoryId: _selectedCategory?.id,
      );
      if (!mounted) return;
      setState(() {
        _jobs = jobs;
        _isLoadingJobs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingJobs = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _acceptJob(Booking job) async {
    try {
      final result =
          await _bookingsRepository.acceptBookingRequest(int.parse(job.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Đã gửi báo giá thành công!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        // Navigate to home to see the active job
        if (mounted) {
          context.go('/provider/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Thị trường công việc',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoadingJobs
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _jobs.isEmpty
                    ? _buildEmptyState()
                    : _buildJobsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LỌC THEO DỊCH VỤ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.textTertiary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          // Category
          BlocBuilder<CategoriesBloc, CategoriesState>(
            builder: (context, state) {
              if (state is CategoriesLoaded) {
                return _buildDropdown<Category>(
                  value: _selectedCategory,
                  hint: 'Chọn Danh mục',
                  items: state.categories,
                  itemBuilder: (cat) => Text(cat.name),
                  onChanged: (cat) {
                    setState(() {
                      _selectedCategory = cat;
                      _selectedService = null;
                      _jobs = [];
                    });
                    _fetchJobs(); // Fetch all jobs in this category
                    if (cat != null) {
                      context
                          .read<ServicesBloc>()
                          .add(LoadGenericServices(categoryId: cat.id));
                    }
                  },
                );
              }
              return const LinearProgressIndicator(color: AppColors.primary);
            },
          ),
          const SizedBox(height: 12),
          // Service
          BlocBuilder<ServicesBloc, ServicesState>(
            builder: (context, state) {
              final List<Service> services = [];
              if (state is GenericServicesLoaded) {
                services.addAll(state.services);
              }

              return _buildDropdown<Service>(
                value: _selectedService,
                hint: _selectedCategory == null
                    ? 'Chọn danh mục trước'
                    : 'Chọn Dịch vụ cụ thể',
                items: services,
                itemBuilder: (svc) => Text(svc.name),
                onChanged: _selectedCategory == null
                    ? null
                    : (svc) {
                        setState(() => _selectedService = svc);
                        if (svc != null) _fetchJobs();
                      },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildJobsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _jobs.length,
      itemBuilder: (context, index) {
        final job = _jobs[index];
        return _buildJobCard(job);
      },
    );
  }

  Widget _buildJobCard(Booking job) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateStr = job.scheduledAt != null
        ? DateFormat('HH:mm - dd/MM/yyyy').format(job.scheduledAt!)
        : 'Chưa đặt thời gian';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                job.code,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currencyFormat
                      .format(double.parse(job.estimatedPrice ?? '0')),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.person_pin_circle_rounded,
              job.customerName ?? 'Khách hàng'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.calendar_today_rounded, dateStr),
          const SizedBox(height: 8),
          _buildInfoRow(
              Icons.location_on_rounded, job.addressText ?? 'Không rõ địa chỉ'),
          const SizedBox(height: 20),
          MinButton(
            text: 'GỬI BÁO GIÁ',
            isFullWidth: true,
            onPressed: () => _acceptJob(job),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: AppColors.shelf),
          const SizedBox(height: 16),
          Text(
            _selectedCategory == null && _selectedService == null
                ? 'Hiện chưa có yêu cầu nào mới'
                : 'Không có yêu cầu phù hợp với bộ lọc',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required Widget Function(T) itemBuilder,
    required void Function(T?)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 14)),
          isExpanded: true,
          items: items
              .map((it) => DropdownMenuItem(value: it, child: itemBuilder(it)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
