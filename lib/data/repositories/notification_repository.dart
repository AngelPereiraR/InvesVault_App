import '../datasources/notification_remote_datasource.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final NotificationRemoteDatasource _datasource;
  NotificationRepository(this._datasource);

  Future<List<NotificationModel>> getNotifications() =>
      _datasource.getNotifications();

  Future<void> markRead(int id) => _datasource.markRead(id);

  Future<void> markAllRead() => _datasource.markAllRead();

  Future<void> deleteNotification(int id) =>
      _datasource.deleteNotification(id);

  Future<void> clearAll() => _datasource.clearAll();
}
