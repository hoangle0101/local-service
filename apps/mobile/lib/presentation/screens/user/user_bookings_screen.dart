import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/socket_service.dart';
import '../../../data/repositories/bookings_repository.dart';
import '../../bloc/bookings/bookings_bloc.dart';
import '../../bloc/bookings/bookings_event_state.dart';
import '../../widgets/review/review_dialog.dart';
import '../../widgets/minimalist_widgets.dart';
import '../../widgets/booking_offers_dialog.dart';
import '../../widgets/quote_view_widget.dart';
import '../booking/invoice_screen.dart';
import '../booking/booking_detail_screen.dart';

class UserBookingsScreen extends StatefulWidget {
  const UserBookingsScreen({super.key});

  @override
  State<UserBookingsScreen> createState() => _UserBookingsScreenState();
}

class _UserBookingsScreenState extends State<UserBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Socket service for real-time updates
  final SocketService _socketService = SocketService();
  StreamSubscription<BookingStatusUpdate>? _bookingStatusSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initSocketConnection();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingsBloc>().add(const LoadBookings());
    });
  }

  @override
  void dispose() {
    _bookingStatusSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  /// Initialize socket connection
  void _initSocketConnection() async {
    await _socketService.connectAsync();
  }

  void _refreshBookings() {
    context.read<BookingsBloc>().add(const LoadBookings());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<BookingsBloc, BookingsState>(
        listener: (context, state) {
          if (state is BookingActionSuccess) {
            _showSnackBar(state.message, isError: false);
          } else if (state is BookingsError) {
            _showSnackBar(state.message, isError: true);
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              _buildSliverAppBar(context, state),
              SliverFillRemaining(
                child: _buildBody(state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, BookingsState state) {
    int pendingCount = 0;
    int acceptedCount = 0;
    int completedCount = 0;
    int cancelledCount = 0;

    if (state is BookingsLoaded) {
      final bookings = state.bookings;
      pendingCount = bookings.where((b) => b.status == 'pending').length;
      acceptedCount = bookings
          .where((b) =>
              b.status == 'accepted' ||
              b.status == 'confirmed' ||
              b.status == 'in_progress')
          .length;
      completedCount = bookings
          .where((b) =>
              b.status == 'completed' ||
              b.status == 'pending_payment' ||
              b.status == 'pending_completion')
          .length;
      cancelledCount = bookings
          .where((b) => b.status == 'cancelled' || b.status == 'disputed')
          .length;
    }

    return SliverAppBar(
      pinned: true,
      expandedHeight: 200,
      backgroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: const Icon(Icons.sync_rounded, color: AppColors.primary),
            onPressed: _refreshBookings,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(24, 80, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Lịch đặt của tôi',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -1.0,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Quản lý và theo dõi trạng thái các dịch vụ bạn đã đặt.',
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
              bottom: BorderSide(color: AppColors.divider.withOpacity(0.5)),
            ),
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
              borderSide: BorderSide(width: 4, color: AppColors.primary),
              insets: EdgeInsets.symmetric(horizontal: -8),
            ),
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.2),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: [
              _buildTab('Đang chờ', pendingCount),
              _buildTab('Đã nhận', acceptedCount),
              _buildTab('Hoàn thành', completedCount),
              _buildTab('Đã hủy', cancelledCount),
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
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(BookingsState state) {
    if (state is BookingsLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    } else if (state is BookingsLoaded || state is UserBookingsLoaded) {
      final bookings = state is BookingsLoaded
          ? state.bookings
          : (state as UserBookingsLoaded).bookings;
      return TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsList(
              bookings.where((b) => b.status == 'pending').toList()),
          _buildBookingsList(bookings
              .where((b) =>
                  b.status == 'accepted' ||
                  b.status == 'confirmed' ||
                  b.status == 'in_progress')
              .toList()),
          _buildBookingsList(bookings
              .where((b) =>
                  b.status == 'completed' ||
                  b.status == 'pending_payment' ||
                  b.status == 'pending_completion')
              .toList()),
          _buildBookingsList(bookings
              .where((b) => b.status == 'cancelled' || b.status == 'disputed')
              .toList()),
        ],
      );
    } else if (state is BookingsError) {
      return _buildErrorState(state.message);
    }
    return const Center(
        child: CircularProgressIndicator(color: AppColors.primary));
  }

  Widget _buildBookingsList(List<Booking> bookings) {
    if (bookings.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => _refreshBookings(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          return _buildBookingMinCard(bookings[index]);
        },
      ),
    );
  }

  Widget _buildBookingMinCard(Booking booking) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateFormat = DateFormat('EEE, dd/MM • HH:mm');
    final price = double.tryParse(booking.estimatedPrice ?? '0') ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: MinCard(
        padding: EdgeInsets.zero,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingDetailScreen(booking: booking),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMinStatusBadge(booking.status),
                      Text(
                        '#${booking.code}',
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    booking.serviceName ?? 'Dịch vụ',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoItem(
                      Icons.calendar_today_rounded,
                      booking.scheduledAt != null
                          ? dateFormat.format(booking.scheduledAt!)
                          : 'Chưa xác định'),
                  const SizedBox(height: 10),
                  _buildInfoItem(Icons.location_on_rounded,
                      booking.addressText ?? 'Địa chỉ không xác định'),
                  if (booking.providerName != null) ...[
                    const SizedBox(height: 10),
                    _buildInfoItem(Icons.person_rounded,
                        'Đối tác: ${booking.providerName}'),
                  ],
                  if (booking.providerAddress != null) ...[
                    const SizedBox(height: 10),
                    _buildInfoItem(Icons.store_rounded,
                        'Địa chỉ thợ: ${booking.providerAddress}'),
                  ],
                  if (booking.distance != null) ...[
                    const SizedBox(height: 10),
                    _buildInfoItem(Icons.directions_car_rounded,
                        'Khoảng cách: ${booking.distance! < 1000 ? "${booking.distance} m" : "${(booking.distance! / 1000).toStringAsFixed(1)} km"}'),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.shelf.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                border: Border(
                    top: BorderSide(color: AppColors.divider.withOpacity(0.5))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TỔNG THANH TOÁN',
                          style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5)),
                      Text(
                        price > 0
                            ? currencyFormat.format(price).replaceAll(',00', '')
                            : 'Chờ báo giá',
                        style: TextStyle(
                            color: price > 0
                                ? AppColors.success
                                : AppColors.warning,
                            fontWeight: FontWeight.w900,
                            fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: _buildActionButtons(booking),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMinStatusBadge(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'cancelled':
        color = AppColors.error;
        label = 'Đã hủy';
        break;
      case 'disputed':
        color = AppColors.error;
        label = 'Khiếu nại';
        break;
      case 'completed':
        color = AppColors.success;
        label = 'Hoàn thành';
        break;
      case 'pending':
        color = AppColors.warning;
        label = 'Đang chờ';
        break;
      case 'confirmed':
      case 'accepted':
        color = AppColors.accent;
        label = 'Đã nhận';
        break;
      case 'in_progress':
        color = AppColors.primary;
        label = 'Đang thực hiện';
        break;
      case 'pending_completion':
        color = AppColors.success;
        label = 'Chờ xác nhận';
        break;
      case 'pending_payment':
        color = Colors.orange;
        label = 'Chờ thanh toán';
        break;
      default:
        color = AppColors.textTertiary;
        label = status.toUpperCase();
    }

    return MinBadge(
      label: label,
      color: color.withOpacity(0.1),
      textColor: color,
    );
  }

  Widget _buildActionButtons(Booking booking) {
    final status = booking.status.toLowerCase();

    // Chat button for active bookings
    Widget? chatButton;
    if (['accepted', 'confirmed', 'in_progress', 'pending_completion']
        .contains(status)) {
      chatButton = _buildActionButton(
        'Nhắn tin',
        () => context.push(
          '/chat/${booking.id}',
          extra: booking.providerName,
        ),
        isPrimary: false,
      );
    }

    if (status == 'pending') {
      final offersText = booking.offersCount > 0
          ? 'Xem ${booking.offersCount} báo giá'
          : 'Chờ báo giá';
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton('Hủy', () => _showCancelDialog(booking.id),
              isPrimary: false),
          const SizedBox(width: 8),
          _buildActionButton(offersText, () => _showOffersDialog(booking.id)),
        ],
      );
    } else if (['accepted', 'confirmed', 'in_progress'].contains(status)) {
      // Active bookings - show chat and quote buttons
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (chatButton != null) ...[chatButton, const SizedBox(width: 8)],
          // Show quote button for any active status (provider may send quote)
          _buildActionButton('Báo giá', () => _showQuotesDialog(booking.id)),
          const SizedBox(width: 8),
          _buildActionButton('Hủy', () => _showCancelDialog(booking.id),
              isPrimary: false, isError: true),
        ],
      );
    } else if (status == 'pending_completion' || status == 'pending_payment') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (chatButton != null) ...[chatButton, const SizedBox(width: 8)],
          _buildActionButton('Thanh toán', () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => InvoiceScreen(bookingId: booking.id)),
            );
          }),
        ],
      );
    } else if (status == 'completed' && !booking.hasReview) {
      return _buildActionButton(
          'Đánh giá',
          () => _showReviewDialog(
                booking.id,
                serviceName: booking.serviceName,
              ));
    } else if (status == 'cancelled' || status == 'disputed') {
      return _buildActionButton('Đặt lại', () {}, isPrimary: false);
    }

    return const SizedBox.shrink();
  }

  Widget _buildActionButton(String text, VoidCallback onTap,
      {bool isPrimary = true, bool isError = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primary
              : (isError ? AppColors.error.withOpacity(0.1) : AppColors.shelf),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isPrimary
                ? Colors.white
                : (isError ? AppColors.error : AppColors.textPrimary),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              color: AppColors.shelf,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_today_rounded,
                size: 48, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chưa có thông tin',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hiện tại mục này chưa có đơn hàng nào.',
            style: TextStyle(
                color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Đã có lỗi xảy ra',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            MinButton(text: 'Thử lại', onPressed: _refreshBookings),
          ],
        ),
      ),
    );
  }

  void _showQuotesDialog(String bookingId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Báo giá từ thợ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: QuoteViewWidget(
                  bookingId: bookingId,
                  onQuoteAccepted: () {
                    Navigator.pop(ctx);
                    _refreshBookings();
                  },
                  onQuoteRejected: _refreshBookings,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOffersDialog(String bookingId) {
    showDialog(
      context: context,
      builder: (context) => BookingOffersDialog(
        bookingId: bookingId,
        onProviderSelected: _refreshBookings,
      ),
    );
  }

  void _showCancelDialog(String bookingId) {
    MinDialog.show(
      context: context,
      title: 'Hủy lịch đặt',
      message: 'Bạn có chắc chắn muốn hủy lịch đặt này không?',
      primaryLabel: 'Có, Hủy bỏ',
      isDestructive: true,
      icon: Icons.close_rounded,
      secondaryLabel: 'Quay lại',
      onPrimaryPressed: () {
        context.read<BookingsBloc>().add(CancelBooking(bookingId));
      },
    );
  }

  void _showDisputeDialog(String bookingId) {
    final reasonController = TextEditingController();
    MinDialog.show(
      context: context,
      title: 'Khiếu nại dịch vụ',
      icon: Icons.error_outline_rounded,
      content: MinTextField(
        controller: reasonController,
        hint: 'Nhập lý do khiếu nại...',
        maxLines: 3,
      ),
      primaryLabel: 'Gửi khiếu nại',
      isDestructive: true,
      secondaryLabel: 'Hủy',
      onPrimaryPressed: () async {
        await BookingsRepository()
            .disputeBooking(bookingId, reasonController.text);
        _refreshBookings();
      },
    );
  }

  void _showReviewDialog(String bookingId, {String? serviceName}) {
    ReviewDialog.show(
      context,
      bookingId: bookingId,
      serviceName: serviceName,
      onSubmit: (rating, comment) async {
        await BookingsRepository().reviewBooking(bookingId, rating, comment);
        _refreshBookings();
      },
    );
  }

  Future<void> _confirmCompletion(String bookingId) async {
    try {
      await BookingsRepository().confirmCompletion(bookingId);
      _showSnackBar('Đã xác nhận hoàn thành dịch vụ!', isError: false);
      _refreshBookings();
      _showReviewDialog(bookingId);
    } catch (e) {
      _showSnackBar('Lỗi: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
