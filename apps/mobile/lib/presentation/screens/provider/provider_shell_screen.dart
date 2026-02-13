import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../widgets/navigation/animated_bottom_nav_item.dart';
import '../../../core/services/socket_service.dart';
import '../../../data/repositories/bookings_repository.dart';
import '../../bloc/bookings/bookings_bloc.dart';
import '../../bloc/bookings/bookings_event_state.dart';
import '../../../core/theme/app_colors.dart';

class ProviderShellScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ProviderShellScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  State<ProviderShellScreen> createState() => _ProviderShellScreenState();
}

class _ProviderShellScreenState extends State<ProviderShellScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final BookingsRepository _bookingsRepository = BookingsRepository();
  bool _isDialogShowing = false;
  StreamSubscription? _bookingStatusSubscription;
  String? _lastNotificationMessage;
  Timer? _messageClearTimer;

  @override
  void initState() {
    super.initState();
    _setupSocketListeners();
  }

  @override
  void dispose() {
    _bookingStatusSubscription?.cancel();
    _messageClearTimer?.cancel();
    final socket = SocketService();
    socket.off('booking.new_request');
    socket.off('booking.accepted');
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setupSocketListeners() {
    final socket = SocketService();

    // NOTE: All booking status updates are now handled by bookingStatusStream to avoid duplicate notifications
    // including new requests and acceptance.

    // NOTE: booking.confirmed is now handled by bookingStatusStream to avoid duplicate notifications

    // Listen to unified status updates
    _bookingStatusSubscription =
        socket.bookingStatusStream.distinct((prev, next) {
      return prev.status == next.status &&
          prev.bookingId == next.bookingId &&
          prev.message == next.message;
    }).listen((update) {
      if (!mounted) return;

      // Refresh provider data
      context.read<BookingsBloc>().add(const LoadProviderBookings());

      // Show dialog if pending and assigned to this provider
      if (update.status == 'pending' &&
          update.providerId == socket.currentUserId &&
          update.actorId != socket.currentUserId) {
        if (!_isDialogShowing) {
          _playNotificationSound();
          _showBookingRequestDialog(update);
        }
      } else if (update.actorId != socket.currentUserId &&
          update.status != 'completed') {
        // Skip 'completed' status - already has persistent notification
        _showNotification(
          update.message ?? 'Cập nhật trạng thái: ${update.status}',
          icon: update.status == 'cancelled'
              ? Icons.cancel_outlined
              : Icons.info_outline_rounded,
          color: update.status == 'cancelled'
              ? AppColors.error
              : AppColors.primary,
        );
      }

      // Auto redirect to navigation map if accepted and location is available
      if (update.status == 'accepted' &&
          update.actorId != socket.currentUserId &&
          update.latitude != null &&
          update.longitude != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.push('/provider/navigation', extra: {
              'lat': double.tryParse(update.latitude!.toString()) ?? 0.0,
              'lng': double.tryParse(update.longitude!.toString()) ?? 0.0,
              'address': update.addressText,
              'customerName': update.customerName,
            });
          }
        });
      }
    });
  }

  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.play(UrlSource(
          'https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3'));
    } catch (e) {
      debugPrint('Error playing notification sound: $e');
    }
  }

  void _showBookingRequestDialog(BookingStatusUpdate update) {
    if (!mounted) return;
    setState(() => _isDialogShowing = true);

    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row: Service name + Price
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.work_rounded,
                        color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(update.serviceName ?? 'Dịch vụ mới',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(
                            currencyFormat.format(
                                double.tryParse(update.estimatedPrice ?? '0') ??
                                    0),
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.success)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Info rows - compact
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildCompactRow(Icons.person_outline_rounded,
                        update.customerName ?? 'Khách hàng'),
                    const SizedBox(height: 8),
                    _buildCompactRow(Icons.location_on_outlined,
                        update.addressText ?? 'Địa chỉ không rõ'),
                    if (update.scheduledAt != null) ...[
                      const SizedBox(height: 8),
                      _buildCompactRow(
                          Icons.schedule_rounded,
                          DateFormat('HH:mm - dd/MM')
                              .format(DateTime.parse(update.scheduledAt!))),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Action buttons - icon style
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reject button
                  _buildDialogActionIcon(
                    icon: Icons.close_rounded,
                    label: 'Từ chối',
                    color: AppColors.error,
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      setState(() => _isDialogShowing = false);
                      _bookingsRepository.cancelBooking(
                          update.bookingId, 'Thợ từ chối yêu cầu');
                    },
                  ),
                  // Accept button
                  _buildDialogActionIcon(
                    icon: Icons.check_rounded,
                    label: 'Nhận việc',
                    color: AppColors.success,
                    onTap: () async {
                      Navigator.of(dialogContext).pop();
                      setState(() => _isDialogShowing = false);
                      try {
                        await _bookingsRepository
                            .acceptBookingLegacy(update.bookingId);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Không thể nhận đơn: $e'),
                              backgroundColor: Colors.red));
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildDialogActionIcon({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showNotification(String message, {IconData? icon, Color? color}) {
    // Tránh hiện lại tin nhắn cũ trong thời gian ngắn
    if (_lastNotificationMessage == message) return;
    _lastNotificationMessage = message;

    // Clear cache sau 2 giây
    _messageClearTimer?.cancel();
    _messageClearTimer = Timer(const Duration(seconds: 2), () {
      _lastNotificationMessage = null;
    });

    // Xóa snackbar cũ trước khi hiện cái mới
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: color ?? AppColors.primary),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                AnimatedBottomNavItem(
                  icon: Icons.map_outlined,
                  activeIcon: Icons.map,
                  label: 'Trang chủ',
                  isSelected: widget.navigationShell.currentIndex == 0,
                  onTap: () => _onTap(0),
                ),
                AnimatedBottomNavItem(
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet,
                  label: 'Thu nhập',
                  isSelected: widget.navigationShell.currentIndex == 1,
                  onTap: () => _onTap(1),
                ),
                AnimatedBottomNavItem(
                  icon: Icons.assignment_outlined,
                  activeIcon: Icons.assignment,
                  label: 'Hoạt động',
                  isSelected: widget.navigationShell.currentIndex == 2,
                  onTap: () => _onTap(2),
                  badgeCount: 0,
                ),
                AnimatedBottomNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Tài khoản',
                  isSelected: widget.navigationShell.currentIndex == 3,
                  onTap: () => _onTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
