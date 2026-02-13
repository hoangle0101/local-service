import 'package:equatable/equatable.dart';
import '../../../core/entities/entities.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationsEvent {}

class NewNotificationReceived extends NotificationsEvent {
  final NotificationEntry notification;
  const NewNotificationReceived(this.notification);

  @override
  List<Object?> get props => [notification];
}

class MarkNotificationAsRead extends NotificationsEvent {
  final String id;
  const MarkNotificationAsRead(this.id);

  @override
  List<Object?> get props => [id];
}

class MarkAllNotificationsAsRead extends NotificationsEvent {}
