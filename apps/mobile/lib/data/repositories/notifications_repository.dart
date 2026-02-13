import '../datasources/notifications_datasource.dart';
import '../../core/entities/entities.dart';

class NotificationsRepository {
  final NotificationsDataSource _dataSource = NotificationsDataSource();

  Future<List<NotificationEntry>> getNotifications() {
    return _dataSource.getNotifications();
  }

  Future<void> markAsRead(String id) {
    return _dataSource.markAsRead(id);
  }

  Future<void> markAllAsRead() {
    return _dataSource.markAllAsRead();
  }
}
