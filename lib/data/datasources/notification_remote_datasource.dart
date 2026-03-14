import 'package:dio/dio.dart';
import '../models/notification_model.dart';
import '../../core/constants/api_constants.dart';
import '../../core/models/filter_params.dart';

class NotificationRemoteDatasource {
  final Dio _dio;
  NotificationRemoteDatasource(this._dio);

  Future<List<NotificationModel>> getNotifications([FilterParams params = FilterParams.empty]) async {
    try {
      final response = await _dio.get(
        ApiConstants.notifications,
        queryParameters: params.toQueryParameters(),
      );
      return (response.data as List)
          .map((e) =>
              NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      rethrow;
    }
  }

  Future<void> markRead(int id) =>
      _dio.patch(ApiConstants.notificationMarkRead(id));

  Future<void> markAllRead() =>
      _dio.patch(ApiConstants.notificationsMarkAllRead);

  Future<void> deleteNotification(int id) =>
      _dio.delete(ApiConstants.notificationDelete(id));

  Future<void> clearAll() =>
      _dio.delete(ApiConstants.notificationsClearAll);
}
