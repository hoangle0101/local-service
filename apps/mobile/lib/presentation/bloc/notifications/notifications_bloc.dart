import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/notifications_repository.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/entities/entities.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsRepository _repository = NotificationsRepository();
  final SocketService _socketService = SocketService();
  StreamSubscription? _socketSubscription;

  NotificationsBloc() : super(NotificationsInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<NewNotificationReceived>(_onNewNotificationReceived);
    on<MarkNotificationAsRead>(_onMarkAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllAsRead);

    // Listen for real-time notifications
    _socketSubscription = _socketService.notificationStream.listen((event) {
      final notification = NotificationEntry(
        id: event.id,
        type: event.type,
        title: event.title,
        body: event.body,
        payload: event.payload ?? {},
        isRead: false,
        createdAt: DateTime.now(),
      );
      add(NewNotificationReceived(notification));
    });
  }

  Future<void> _onLoadNotifications(
      LoadNotifications event, Emitter<NotificationsState> emit) async {
    emit(NotificationsLoading());
    try {
      final notifications = await _repository.getNotifications();
      final unreadCount = notifications.where((n) => !n.isRead).length;
      emit(NotificationsLoaded(
          notifications: notifications, unreadCount: unreadCount));
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  void _onNewNotificationReceived(
      NewNotificationReceived event, Emitter<NotificationsState> emit) {
    // Reload from server to ensure accurate unread count
    // This prevents duplicate counting issues
    add(LoadNotifications());
  }

  Future<void> _onMarkAsRead(
      MarkNotificationAsRead event, Emitter<NotificationsState> emit) async {
    if (state is NotificationsLoaded) {
      try {
        await _repository.markAsRead(event.id);
        final currentState = state as NotificationsLoaded;
        final updatedList = currentState.notifications.map((n) {
          if (n.id == event.id) {
            return NotificationEntry(
              id: n.id,
              type: n.type,
              title: n.title,
              body: n.body,
              payload: n.payload,
              isRead: true,
              createdAt: n.createdAt,
            );
          }
          return n;
        }).toList();
        final unreadCount = updatedList.where((n) => !n.isRead).length;
        emit(NotificationsLoaded(
            notifications: updatedList, unreadCount: unreadCount));
      } catch (e) {
        // Silent error or handle
      }
    }
  }

  Future<void> _onMarkAllAsRead(MarkAllNotificationsAsRead event,
      Emitter<NotificationsState> emit) async {
    if (state is NotificationsLoaded) {
      try {
        await _repository.markAllAsRead();
        final currentState = state as NotificationsLoaded;
        final updatedList = currentState.notifications.map((n) {
          return NotificationEntry(
            id: n.id,
            type: n.type,
            title: n.title,
            body: n.body,
            payload: n.payload,
            isRead: true,
            createdAt: n.createdAt,
          );
        }).toList();
        emit(NotificationsLoaded(notifications: updatedList, unreadCount: 0));
      } catch (e) {
        // Silent error
      }
    }
  }

  @override
  Future<void> close() {
    _socketSubscription?.cancel();
    return super.close();
  }
}
