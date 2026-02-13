import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/navigation/animated_bottom_nav_item.dart';
import '../../../core/services/socket_service.dart';
import '../../bloc/bookings/bookings_bloc.dart';
import '../../bloc/bookings/bookings_event_state.dart';
import '../../theme/app_colors.dart';

class UserShellScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const UserShellScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  State<UserShellScreen> createState() => _UserShellScreenState();
}

class _UserShellScreenState extends State<UserShellScreen> {
  StreamSubscription? _bookingStatusSubscription;
  String? _lastNotificationMessage;
  Timer? _messageClearTimer;

  @override
  void initState() {
    super.initState();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    final socket = SocketService();

    // Unified handling via bookingStatusStream to avoid duplicates
    _bookingStatusSubscription =
        socket.bookingStatusStream.distinct((prev, next) {
      return prev.status == next.status &&
          prev.bookingId == next.bookingId &&
          prev.message == next.message;
    }).listen((update) {
      if (!mounted) return;

      // Refresh bookings data
      context.read<BookingsBloc>().add(const LoadUserBookingsEvent());

      // Show notification if action was by someone else or it's a new offer
      if (update.actorId != socket.currentUserId) {
        String message =
            update.message ?? 'Trạng thái đơn hàng: ${update.status}';
        IconData icon = Icons.info_outline_rounded;
        Color color = AppColors.primary;

        if (update.status == 'cancelled') {
          icon = Icons.cancel_outlined;
          color = AppColors.error;
        } else if (update.status == 'OFFER_RECEIVED') {
          icon = Icons.local_offer_rounded;
          color = Colors.blue;
        }

        _showNotification(
          message,
          icon: icon,
          color: color,
        );
      }
    });

    // to avoid duplicate notifications.
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

  @override
  void dispose() {
    _bookingStatusSubscription?.cancel();
    _messageClearTimer?.cancel();
    final socket = SocketService();
    socket.off('booking.new_offer');
    super.dispose();
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
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Trang chủ',
                  isSelected: widget.navigationShell.currentIndex == 0,
                  onTap: () => _onTap(0),
                ),
                AnimatedBottomNavItem(
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_today,
                  label: 'Đơn hàng',
                  isSelected: widget.navigationShell.currentIndex == 1,
                  onTap: () => _onTap(1),
                  badgeCount: 0,
                ),
                AnimatedBottomNavItem(
                  icon: Icons.favorite_outline,
                  activeIcon: Icons.favorite,
                  label: 'Yêu thích',
                  isSelected: widget.navigationShell.currentIndex == 2,
                  onTap: () => _onTap(2),
                  badgeCount: 0,
                ),
                AnimatedBottomNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Hồ sơ',
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
