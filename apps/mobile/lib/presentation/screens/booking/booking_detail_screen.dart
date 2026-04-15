import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/quote_datasource.dart';
import '../../../data/datasources/bookings_datasource.dart';
import '../../../data/datasources/payment_datasource.dart';
import '../../bloc/bookings/bookings_bloc.dart';
import '../../bloc/bookings/bookings_event_state.dart';
import '../../../core/services/socket_service.dart';
import 'dart:async';

import '../../widgets/minimalist_widgets.dart';
import '../../widgets/booking_offers_dialog.dart';
import '../provider/create_quote_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final Booking booking;
  final bool isProvider;

  const BookingDetailScreen({
    super.key,
    required this.booking,
    this.isProvider = false,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final QuoteDataSource _quoteDataSource = QuoteDataSource();
  final BookingsDataSource _bookingsDataSource = BookingsDataSource();
  final PaymentDataSource _paymentDataSource = PaymentDataSource();
  bool _isActionLoading = false;
  StreamSubscription? _bookingSocketSubscription;

  @override
  void initState() {
    super.initState();
    _initSocketListener();
  }

  void _initSocketListener() {
    _bookingSocketSubscription =
        SocketService().bookingStatusStream.listen((data) {
      final bookingId = data.bookingId;
      if (bookingId == widget.booking.id) {
        // Refresh the booking data
        if (mounted) {
          context.read<BookingsBloc>().add(const LoadBookings());
          // Optional: Force a local state update if needed,
          // but BlocListener below usually handles this.
        }
      }
    });
  }

  @override
  void dispose() {
    _bookingSocketSubscription?.cancel();
    super.dispose();
  }

  void _onActionSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context); // Go back after success
    }
  }

  void _onActionError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateFormat = DateFormat('EEEE, dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    return BlocListener<BookingsBloc, BookingsState>(
      listener: (context, state) {
        if (state is BookingActionSuccess) {
          _onActionSuccess(state.message);
        } else if (state is BookingsError) {
          _onActionError(state.message);
        }
      },
      child: BlocBuilder<BookingsBloc, BookingsState>(
        builder: (context, state) {
          Booking booking = widget.booking;
          if (state is BookingsLoaded) {
            try {
              booking =
                  state.bookings.firstWhere((b) => b.id == widget.booking.id);
            } catch (_) {
              // Stay with initial booking if not found in current loaded list
            }
          }

          final price = double.tryParse(booking.finalPrice ?? '0') ?? 0;

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(
                'Chi tiết đơn hàng',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
              backgroundColor: AppColors.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Section
                  _buildStatusHeader(booking),
                  const SizedBox(height: 24),

                  // Service Info
                  _buildSectionTitle('DỊCH VỤ'),
                  MinCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(Icons.cleaning_services_rounded,
                                  color: AppColors.primary, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking.serviceName ?? 'Dịch vụ',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (booking.categoryName != null)
                                    Text(
                                      booking.categoryName!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (booking.notes != null &&
                            booking.notes!.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(color: AppColors.divider),
                          ),
                          const Text(
                            'Ghi chú từ khách hàng:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textTertiary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            booking.notes!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Time and Date
                  _buildSectionTitle('THỜI GIAN'),
                  MinCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        _buildDateTimeItem(
                          Icons.calendar_month_rounded,
                          'Ngày thực hiện',
                          booking.scheduledAt != null
                              ? dateFormat.format(booking.scheduledAt!)
                              : 'N/A',
                        ),
                        const SizedBox(width: 24),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.divider.withOpacity(0.5),
                        ),
                        const SizedBox(width: 24),
                        _buildDateTimeItem(
                          Icons.access_time_filled_rounded,
                          'Giờ bắt đầu',
                          booking.scheduledAt != null
                              ? timeFormat.format(booking.scheduledAt!)
                              : 'N/A',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Location Section
                  _buildSectionTitle('ĐỊA ĐIỂM'),
                  MinCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildLocationRow(
                          Icons.my_location_rounded,
                          'Địa chỉ khách hàng',
                          booking.addressText ?? 'N/A',
                          AppColors.primary,
                        ),
                        if (booking.providerAddress != null) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(color: AppColors.divider),
                          ),
                          _buildLocationRow(
                            Icons.store_rounded,
                            'Địa chỉ đối tác',
                            booking.providerAddress!,
                            AppColors.accent,
                          ),
                        ],
                        if (booking.distance != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.shelf.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.directions_car_rounded,
                                    size: 18, color: AppColors.textSecondary),
                                const SizedBox(width: 10),
                                Text(
                                  'Khoảng cách: ${booking.distance! < 1000 ? "${booking.distance} m" : "${(booking.distance! / 1000).toStringAsFixed(1)} km"}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Provider/Customer Info
                  _buildSectionTitle(
                      widget.isProvider ? 'KHÁCH HÀNG' : 'ĐỐI TÁC'),
                  MinCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.shelf,
                          child: Icon(Icons.person_rounded,
                              color: AppColors.textTertiary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (widget.isProvider
                                        ? booking.customerName
                                        : booking.providerName) ??
                                    'N/A',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                widget.isProvider
                                    ? 'Khách hàng'
                                    : 'Người cung cấp dịch vụ',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {}, // TODO: Chat integration
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chat_bubble_rounded,
                                color: AppColors.primary, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment Info
                  _buildSectionTitle('THANH TOÁN'),
                  MinCard(
                    padding: const EdgeInsets.all(24),
                    backgroundColor: AppColors.white,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng thanh toán',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              price > 0
                                  ? currencyFormat
                                      .format(price)
                                      .replaceAll(',00', '')
                                  : 'CHỜ BÁO GIÁ',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: price > 0
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                        if (price == 0) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Thợ sẽ kiểm tra tình trạng thực tế và gửi báo giá lại cho bạn sau.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textTertiary,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Action Buttons
                  _buildActionButtons(context, booking),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: AppColors.textTertiary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildStatusHeader(Booking booking) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildDetailStatusBadge(booking),
        Text(
          '#${booking.code}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textTertiary.withOpacity(0.7),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailStatusBadge(Booking booking) {
    String status = booking.status;
    Color color = AppColors.textTertiary;
    String label = status.toUpperCase();

    switch (status) {
      case 'pending':
        color = AppColors.warning;
        label = 'ĐANG CHỜ';
        break;
      case 'accepted':
      case 'confirmed':
        color = AppColors.accent;
        label = 'ĐÃ NHẬN';
        break;
      case 'in_progress':
        color = AppColors.primary;
        label = 'ĐANG LÀM';
        break;
      case 'pending_payment':
        color = AppColors.warning;
        label = 'CHỜ THANH TOÁN';
        break;
      case 'pending_completion':
        color = AppColors.success;
        label = 'CHỜ THỢ XÁC NHẬN';
        break;
      case 'completed':
        if (booking.paymentStatus == 'held') {
          color = AppColors.accent;
          label = 'ĐÃ THANH TOÁN';
        } else {
          color = AppColors.success;
          label = 'HOÀN THÀNH';
        }
        break;
      case 'cancelled':
        color = AppColors.error;
        label = 'ĐÃ HỦY';
        break;
      case 'disputed':
        color = AppColors.error;
        label = 'BÁO GIÁ BỊ TỪ CHỐI';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDateTimeItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(
      IconData icon, String label, String address, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, Booking booking) {
    final status = booking.status;
    final id = booking.id;

    if (widget.isProvider) {
      if (status == 'accepted' || status == 'confirmed') {
        return MinButton(
          text: 'Bắt đầu dịch vụ',
          isFullWidth: true,
          isLoading: _isActionLoading,
          onPressed: () => context.read<BookingsBloc>().add(StartService(id)),
          icon: Icons.play_arrow_rounded,
        );
      }
      if (status == 'in_progress') {
        return Column(
          children: [
            MinButton(
              text: 'Tạo Báo Giá',
              isFullWidth: true,
              isPrimary: false,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => CreateQuoteScreen(
                    bookingId: booking.id,
                    serviceName: booking.serviceName,
                    serviceId: booking.serviceId,
                    providerId: booking.providerId,
                    customerSelectedItems: booking.selectedItems,
                  ),
                ),
              ),
              icon: Icons.receipt_long_rounded,
            ),
            const SizedBox(height: 12),
            MinButton(
              text: 'Hoàn thành việc',
              isFullWidth: true,
              isLoading: _isActionLoading,
              onPressed: () =>
                  context.read<BookingsBloc>().add(CompleteService(id)),
              icon: Icons.check_circle_rounded,
            ),
          ],
        );
      }
      if (status == 'pending_payment') {
        // Provider sees confirmation button ONLY for COD
        if (booking.paymentMethod?.toUpperCase() == 'COD') {
          return MinButton(
            text: 'Xác nhận thu tiền mặt',
            isFullWidth: true,
            isLoading: _isActionLoading,
            onPressed: _handleConfirmCod,
            icon: Icons.payments_outlined,
          );
        }
        // If MoMo or not set, provider just waits
        return MinBadge(
          label: 'Chờ khách thanh toán',
          color: AppColors.warning.withOpacity(0.1),
          textColor: AppColors.warning,
        );
      }
      if (status == 'disputed') {
        return MinButton(
          text: 'Đồng ý hủy đơn',
          isFullWidth: true,
          isPrimary: false,
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.error,
          onPressed: _handleProviderAgreeReject,
          icon: Icons.cancel_outlined,
        );
      }
    } else {
      // Customer actions
      if (status == 'pending') {
        if (!booking.isDirectBooking) {
          return MinButton(
            text: 'Xem các báo giá (${booking.offersCount})',
            isFullWidth: true,
            onPressed: () => _showOffersDialog(context),
            icon: Icons.local_offer_rounded,
          );
        }
        return MinButton(
          text: 'Hủy yêu cầu',
          isFullWidth: true,
          isPrimary: false,
          onPressed: () => _showCancelDialog(context),
          icon: Icons.close_rounded,
        );
      }

      if (status == 'pending_payment') {
        return Column(
          children: [
            // MoMo payment option
            MinButton(
              text: 'Thanh toán MoMo',
              isFullWidth: true,
              isLoading: _isActionLoading,
              onPressed: _handleMomoPayment,
              icon: Icons.wallet_outlined,
            ),
            const SizedBox(height: 12),
            // COD payment option - always show
            MinButton(
              text: 'Dùng Tiền mặt (COD)',
              isFullWidth: true,
              isPrimary: false,
              isLoading: _isActionLoading,
              onPressed: _handleSelectCod,
              icon: Icons.money_outlined,
            ),
            const SizedBox(height: 12),
            MinButton(
              text: 'Gửi khiếu nại',
              isFullWidth: true,
              isPrimary: false,
              backgroundColor: AppColors.error.withOpacity(0.1),
              foregroundColor: AppColors.error,
              onPressed: _handleDispute,
              icon: Icons.report_problem_rounded,
            ),
          ],
        );
      }

      // Customer waiting for provider to confirm COD payment
      if (status == 'pending_completion') {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AppColors.success),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Đã chọn thanh toán tiền mặt.\nChờ thợ xác nhận đã thu tiền.',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }

      if (status == 'completed' && booking.paymentStatus == 'held') {
        return Column(
          children: [
            MinButton(
              text: 'Xác nhận hoàn tất & Trả tiền',
              isFullWidth: true,
              isLoading: _isActionLoading,
              onPressed: _handleConfirmCompletion,
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(height: 12),
            MinButton(
              text: 'Khiếu nại / Báo cáo sự cố',
              isFullWidth: true,
              isPrimary: false,
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.error,
              onPressed: _handleDispute,
              icon: Icons.report_problem_outlined,
            ),
          ],
        );
      }

      if (status == 'accepted' ||
          status == 'confirmed' ||
          status == 'in_progress') {
        return MinButton(
          text: 'Hủy đơn hàng',
          isFullWidth: true,
          isPrimary: false,
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.error,
          onPressed: () => _showCancelDialog(context),
          icon: Icons.cancel_outlined,
        );
      }
    }

    return const SizedBox.shrink();
  }

  void _showOffersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => BookingOffersDialog(
        bookingId: widget.booking.id,
        onProviderSelected: () {
          // Reloaing since a provider was selected
          context.read<BookingsBloc>().add(const LoadBookings());
        },
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hủy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vui lòng nhập lý do hủy đơn:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Lý do...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
          ElevatedButton(
            onPressed: () {
              context
                  .read<BookingsBloc>()
                  .add(CancelBooking(widget.booking.id, reasonController.text));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hủy đơn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleProviderAgreeReject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hủy đơn'),
        content: const Text('Bạn có chắc chắn muốn đồng ý hủy đơn này?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Không')),
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

    setState(() => _isActionLoading = true);
    try {
      final quotes =
          await _quoteDataSource.getQuotesForBooking(widget.booking.id);
      final rejectedQuote = quotes.firstWhere(
        (q) => q['status'] == 'rejected',
        orElse: () => <String, dynamic>{},
      );

      if (rejectedQuote.isEmpty || rejectedQuote['id'] == null) {
        throw Exception('Không tìm thấy báo giá bị từ chối');
      }

      await _quoteDataSource
          .providerAgreeReject(rejectedQuote['id'].toString());
      _onActionSuccess('Đã hủy đơn hàng thành công');
    } catch (e) {
      _onActionError(e.toString());
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  // Handle MoMo Payment for Customer
  Future<void> _handleMomoPayment() async {
    setState(() => _isActionLoading = true);
    try {
      final response = await _paymentDataSource.payWithMomo(widget.booking.id);
      final payUrl = response['payUrl'] as String?;
      final deeplink = response['deeplink'] as String?;
      final orderId = response['orderId'] as String?;

      if (payUrl != null) {
        if (mounted) {
          _showPaymentQrSheet(payUrl, deeplink, orderId);
        }
      } else {
        throw 'Không nhận được liên kết thanh toán từ hệ thống';
      }
    } catch (e) {
      _onActionError(e.toString());
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  void _showPaymentQrSheet(String payUrl, String? deeplink, String? orderId) {
    Timer? pollingTimer;
    bool paymentProcessed = false; // Prevent double processing

    // Helper function to handle successful payment
    void handlePaymentSuccess() {
      if (paymentProcessed) return; // Already processed
      paymentProcessed = true;
      pollingTimer?.cancel();

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        _onActionSuccess('Thanh toán thành công!');
        context.read<BookingsBloc>().add(const LoadBookings());
      }
    }

    // Start polling for payment status
    if (orderId != null) {
      int attempts = 0;
      const maxAttempts = 40; // 2 minutes

      pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
        if (paymentProcessed) {
          timer.cancel();
          return;
        }

        attempts++;
        if (attempts > maxAttempts) {
          timer.cancel();
          return;
        }

        try {
          // Check payment status via the /bookings/check-payment-status endpoint
          final result =
              await _paymentDataSource.checkBookingPaymentStatus(orderId);
          final status = result['status'] as String?;

          if (status == 'success') {
            handlePaymentSuccess();
          }
        } catch (e) {
          debugPrint('[BookingDetail] Polling error: $e');
        }
      });
    }

    // Listen for booking status changes while QR is showing
    StreamSubscription? tempSubscription;
    tempSubscription = SocketService().bookingStatusStream.listen((event) {
      if (!paymentProcessed &&
          event.bookingId == widget.booking.id.toString() &&
          event.status == 'completed') {
        handlePaymentSuccess();
        tempSubscription?.cancel();
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Quét mã để thanh toán đơn hàng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thanh toán: ${NumberFormat.currency(locale: "vi_VN", symbol: "₫").format(double.tryParse(widget.booking.estimatedPrice ?? "0") ?? 0)}',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: QrImageView(
                data: payUrl,
                version: QrVersions.auto,
                size: 200.0,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.primary,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: payUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã sao chép liên kết')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    label: const Text('Sao chép'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(deeplink ?? payUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      } else {
                        await launchUrl(Uri.parse(payUrl),
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 20),
                    label: const Text('Mở MoMo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Giao dịch được bảo mật bởi MoMo. Đừng đóng cửa sổ này cho đến khi giao dịch hoàn thành.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Quay lại chi tiết đơn hàng'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Handle COD Selection for Customer
  Future<void> _handleSelectCod() async {
    setState(() => _isActionLoading = true);
    try {
      await _paymentDataSource.createPayment(
        bookingId: widget.booking.id,
        amount: int.parse(widget.booking.finalPrice ?? '0'),
        paymentMethod: 'COD',
      );
      _onActionSuccess('Đã chọn thanh toán tiền mặt');
      context.read<BookingsBloc>().add(const LoadBookings());
    } catch (e) {
      _onActionError(e.toString());
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  // Handle COD Confirmation for Provider
  Future<void> _handleConfirmCod() async {
    setState(() => _isActionLoading = true);
    try {
      await _paymentDataSource.confirmBookingCod(widget.booking.id);
      _onActionSuccess('Đã xác nhận thanh toán tiền mặt');
      context.read<BookingsBloc>().add(const LoadBookings());
    } catch (e) {
      _onActionError(e.toString());
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  // Handle Confirmation of Completion (Escrow Release)
  Future<void> _handleConfirmCompletion() async {
    setState(() => _isActionLoading = true);
    try {
      await _bookingsDataSource.confirmCompletion(widget.booking.id);
      _onActionSuccess(
          'Đã xác nhận hoàn tất dịch vụ. Tiền đã được chuyển cho thợ.');
      context.read<BookingsBloc>().add(const LoadBookings());
    } catch (e) {
      _onActionError(e.toString());
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  // Handle Dispute
  void _handleDispute() {
    GoRouter.of(context).push('/booking/dispute/${widget.booking.id}');
  }
}
