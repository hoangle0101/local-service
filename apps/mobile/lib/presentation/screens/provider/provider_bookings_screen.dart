import 'package:flutter/material.dart';
import 'package:mobile/data/repositories/bookings_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import 'package:mobile/data/repositories/quote_repository.dart';
import '../../bloc/bookings/bookings_bloc.dart';
import '../../bloc/bookings/bookings_event_state.dart';
import '../../widgets/minimalist_widgets.dart';
import 'package:go_router/go_router.dart';
import 'create_quote_screen.dart';
import '../booking/booking_detail_screen.dart';

class ProviderBookingsScreen extends StatefulWidget {
  const ProviderBookingsScreen({super.key});

  @override
  State<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BookingsRepository _bookingsRepository = BookingsRepository();
  final QuoteRepository _quoteRepository = QuoteRepository();

  List<Booking> _myRequests = [];
  List<Booking> _globalRequests = [];
  bool _isLoadingMyRequests = false;
  bool _isLoadingGlobalRequests = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    _loadMyRequests();
    _loadGlobalRequests();
    context.read<BookingsBloc>().add(const LoadProviderBookings());
  }

  Future<void> _loadMyRequests() async {
    if (!mounted) return;
    setState(() => _isLoadingMyRequests = true);
    try {
      final requests = await _bookingsRepository.getProviderRequests();
      if (mounted) {
        setState(() {
          _myRequests = requests;
          _isLoadingMyRequests = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMyRequests = false);
      }
    }
  }

  Future<void> _loadGlobalRequests() async {
    if (!mounted) return;
    setState(() => _isLoadingGlobalRequests = true);
    try {
      final requests =
          await _bookingsRepository.getGlobalRequests(onlyFar: true);
      if (mounted) {
        setState(() {
          _globalRequests = requests;
          _isLoadingGlobalRequests = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tải ${requests.length} đơn hàng ở xa'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingGlobalRequests = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<BookingsBloc, BookingsState>(
        listener: (context, state) {
          if (state is BookingActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
            _loadAllData();
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              _buildSliverAppBar(context),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRequestsTab(isGlobal: false),
                    _buildRequestsTab(isGlobal: true),
                    _buildInProgressTab(state),
                    _buildCompletedTab(state),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 200,
      backgroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: const FlexibleSpaceBar(
        background: Padding(
          padding: EdgeInsets.fromLTRB(24, 80, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Công việc của tôi',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -1.0,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Theo dõi và quản lý các yêu cầu của khách hàng gửi đến bạn',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border(
                bottom: BorderSide(color: AppColors.divider.withOpacity(0.5))),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textTertiary,
            indicatorSize: TabBarIndicatorSize.label,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: AppColors.primary, width: 4),
              insets: EdgeInsets.symmetric(horizontal: -8),
            ),
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.2),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: [
              _buildTab('Yêu cầu', _myRequests.length),
              _buildTab('Xa hơn', _globalRequests.length),
              const Tab(text: 'Đang làm'),
              const Tab(text: 'Hoàn tất'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestsTab({required bool isGlobal}) {
    final isLoading =
        isGlobal ? _isLoadingGlobalRequests : _isLoadingMyRequests;
    final requests = isGlobal ? _globalRequests : _myRequests;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (requests.isEmpty) {
      return _buildEmptyState(
        isGlobal ? 'Không có yêu cầu xa' : 'Chưa có yêu cầu mới',
        isGlobal
            ? 'Chúng tôi sẽ báo khi có khách hàng cần bạn.'
            : 'Hãy kiên nhẫn, công việc sẽ sớm đến.',
        Icons.work_outline_rounded,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: isGlobal ? _loadGlobalRequests : _loadMyRequests,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          return _buildRequestMinCard(requests[index], isGlobal: isGlobal);
        },
      ),
    );
  }

  Widget _buildInProgressTab(BookingsState state) {
    if (state is BookingsLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is BookingsLoaded) {
      // Build full avatar URL
      final inProgress = state.bookings
          .where((b) =>
              b.status == 'accepted' ||
              b.status == 'confirmed' ||
              b.status == 'in_progress' ||
              b.status == 'pending_completion' ||
              b.status == 'disputed') // Quote rejected - provider can see
          .toList();

      if (inProgress.isEmpty) {
        return _buildEmptyState(
            'Trống',
            'Bạn chưa có công việc đang thực hiện.',
            Icons.work_history_rounded);
      }

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async =>
            context.read<BookingsBloc>().add(const LoadProviderBookings()),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
          itemCount: inProgress.length,
          itemBuilder: (context, index) {
            return _buildBookingMinCard(inProgress[index]);
          },
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildCompletedTab(BookingsState state) {
    if (state is BookingsLoaded) {
      final completed =
          state.bookings.where((b) => b.status == 'completed').toList();
      if (completed.isEmpty) {
        return _buildEmptyState('Chưa xong việc nào',
            'Hãy bắt đầu nhận việc ngay.', Icons.check_circle_outline_rounded);
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        itemCount: completed.length,
        itemBuilder: (context, index) {
          return _buildBookingMinCard(completed[index]);
        },
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildRequestMinCard(Booking booking, {required bool isGlobal}) {
    final distanceKm = (booking.distance ?? 0) / 1000;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: MinCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.serviceName ?? 'Dịch vụ',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontSize: 18),
                  ),
                ),
                MinBadge(
                  label: '${distanceKm.toStringAsFixed(1)} km',
                  color: isGlobal
                      ? AppColors.warning.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.1),
                  textColor: isGlobal ? AppColors.warning : AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Khách hàng: ${booking.customerName ?? "N/A"}',
              style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            const Divider(height: 32, color: AppColors.divider),
            _buildInfoRow(
                Icons.location_on_rounded, booking.addressText ?? 'N/A'),
            const SizedBox(height: 10),
            _buildInfoRow(
                Icons.access_time_filled_rounded,
                booking.scheduledAt != null
                    ? DateFormat('HH:mm - dd/MM/yyyy')
                        .format(booking.scheduledAt!)
                    : 'Chưa định'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Thu nhập ước tính',
                        style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                    Text(
                      currencyFormat.format(
                          double.tryParse(booking.estimatedPrice ?? '0') ?? 0),
                      style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w800,
                          fontSize: 16),
                    ),
                  ],
                ),
                MinButton(
                  text: 'Nhận việc',
                  onPressed: () => _acceptRequest(booking),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingMinCard(Booking booking) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: MinCard(
        padding: const EdgeInsets.all(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                BookingDetailScreen(booking: booking, isProvider: true),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.serviceName ?? 'Dịch vụ',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _buildMinStatusBadge(booking.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Khách hàng: ${booking.customerName ?? "N/A"}',
              style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            const Divider(height: 32, color: AppColors.divider),
            _buildInfoRow(
                Icons.location_on_rounded, booking.addressText ?? 'N/A'),
            if (booking.distance != null) ...[
              const SizedBox(height: 10),
              _buildInfoRow(Icons.directions_car_rounded,
                  'Khoảng cách: ${booking.distance! < 1000 ? "${booking.distance} m" : "${(booking.distance! / 1000).toStringAsFixed(1)} km"}'),
            ],
            const SizedBox(height: 10),
            _buildInfoRow(
                Icons.access_time_filled_rounded,
                booking.scheduledAt != null
                    ? DateFormat('HH:mm - dd/MM/yyyy')
                        .format(booking.scheduledAt!)
                    : 'N/A'),
            const SizedBox(height: 20),
            _buildBookingActions(booking),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMinStatusBadge(String? status) {
    Color color = AppColors.textTertiary;
    String label = status?.toUpperCase() ?? 'N/A';

    switch (status) {
      case 'confirmed':
      case 'accepted':
        color = AppColors.accent;
        label = 'Đã nhận';
        break;
      case 'in_progress':
        color = AppColors.primary;
        label = 'Đang làm';
        break;
      case 'pending_completion':
        color = AppColors.warning;
        label = 'Chờ khách xác nhận';
        break;
      case 'completed':
        color = AppColors.success;
        label = 'Hoàn thành';
        break;
      case 'disputed':
        color = AppColors.error;
        label = 'Báo giá bị từ chối';
        break;
    }

    return MinBadge(
      label: label,
      color: color.withOpacity(0.1),
      textColor: color,
    );
  }

  Widget _buildBookingActions(Booking booking) {
    if (booking.status == 'accepted' || booking.status == 'confirmed') {
      return Row(
        children: [
          Expanded(
            child: MinButton(
              text: 'Bắt đầu ngay',
              onPressed: () => _startService(booking),
              icon: Icons.play_arrow_rounded,
            ),
          ),
          if (booking.latitude != null && booking.longitude != null) ...[
            const SizedBox(width: 12),
            MinButton(
              text: '',
              isPrimary: false,
              onPressed: () => _openNavigation(booking),
              icon: Icons.navigation_rounded,
            ),
          ],
        ],
      );
    }
    if (booking.status == 'in_progress') {
      return Column(
        children: [
          // Quote creation button
          MinButton(
            text: 'Tạo Báo Giá',
            isFullWidth: true,
            isPrimary: false,
            onPressed: () => _openCreateQuote(booking),
            icon: Icons.receipt_long_rounded,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: MinButton(
                  text: 'Hoàn thành việc',
                  onPressed: () => _completeService(booking),
                  icon: Icons.check_circle_rounded,
                ),
              ),
              if (booking.latitude != null && booking.longitude != null) ...[
                const SizedBox(width: 12),
                MinButton(
                  text: '',
                  isPrimary: false,
                  onPressed: () => _openNavigation(booking),
                  icon: Icons.navigation_rounded,
                ),
              ],
            ],
          ),
        ],
      );
    }
    if (booking.status == 'completed' && booking.review != null) {
      return MinButton(
        text: 'Xem đánh giá',
        isPrimary: false,
        isFullWidth: true,
        onPressed: () => _showCustomerReviewDialog(booking.review!,
            customerName: booking.customerName),
        icon: Icons.star_rounded,
      );
    }
    // Quote rejected - show agree to cancel button
    if (booking.status == 'disputed') {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Khách hàng đã từ chối báo giá',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          MinButton(
            text: 'Đồng ý hủy đơn',
            isFullWidth: true,
            isPrimary: false,
            onPressed: () => _agreeRejectQuote(booking),
            icon: Icons.cancel_rounded,
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.shelf.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 64, color: AppColors.textTertiary.withOpacity(0.3)),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptRequest(Booking booking) async {
    try {
      final bookingId = int.tryParse(booking.id) ?? 0;
      await _bookingsRepository.acceptBookingRequest(bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Đã gửi báo giá/nhận việc thành công!'),
              backgroundColor: AppColors.success),
        );
      }
      _loadAllData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Không thể nhận việc: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _startService(Booking booking) async {
    try {
      await _bookingsRepository.startService(booking.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Đã bắt đầu dịch vụ!'),
              backgroundColor: AppColors.success),
        );
      }
      _loadAllData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _completeService(Booking booking) async {
    try {
      await _bookingsRepository.completeService(booking.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Đã hoàn thành dịch vụ! Chờ khách xác nhận.'),
              backgroundColor: AppColors.success),
        );
      }
      _loadAllData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  /// Provider agrees to quote rejection - cancels booking
  Future<void> _agreeRejectQuote(Booking booking) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận hủy đơn'),
        content: const Text(
          'Bạn có chắc chắn muốn đồng ý hủy đơn này?\n\nĐơn hàng sẽ bị hủy và không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child:
                const Text('Đồng ý hủy', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Need to get quote ID - we'll use the latest rejected quote for this booking
      final quotes = await _quoteRepository.getQuotesForBooking(booking.id);
      final rejectedQuote = quotes.firstWhere(
        (q) => q['status'] == 'rejected',
        orElse: () => <String, dynamic>{},
      );

      if (rejectedQuote.isEmpty || rejectedQuote['id'] == null) {
        throw Exception('Không tìm thấy báo giá bị từ chối');
      }

      await _quoteRepository
          .providerAgreeReject(rejectedQuote['id'].toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hủy đơn hàng thành công'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      _loadAllData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  /// Opens quote creation screen
  void _openCreateQuote(Booking booking) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateQuoteScreen(
          bookingId: booking.id,
          serviceName: booking.serviceName,
          serviceId: booking.serviceId,
          providerId: booking.providerId,
          customerSelectedItems: booking.selectedItems,
        ),
      ),
    );

    if (result == true) {
      _loadAllData();
    }
  }

  /// Opens in-app navigation screen with route to customer
  void _openNavigation(Booking booking) {
    if (booking.latitude == null || booking.longitude == null) return;

    context.push('/provider/navigation', extra: {
      'lat': booking.latitude,
      'lng': booking.longitude,
      'address': booking.addressText,
      'customerName': booking.customerName,
    });
  }

  void _showCustomerReviewDialog(BookingReview review, {String? customerName}) {
    MinDialog.show(
      context: context,
      title: 'Đánh giá từ ${customerName ?? "khách"}',
      icon: Icons.star_rounded,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
                5,
                (index) => Icon(
                      index < review.rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: AppColors.warning,
                      size: 32,
                    )),
          ),
          const SizedBox(height: 16),
          Text(
            review.comment ?? 'Không có nhận xét.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      primaryLabel: 'Đóng',
      onPrimaryPressed: () {},
    );
  }
}
