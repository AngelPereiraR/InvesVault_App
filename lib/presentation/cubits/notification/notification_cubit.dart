import 'package:equatable/equatable.dart';
import '../../../core/utils/error_messages.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/filter_params.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';

part 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _repository;
  FilterParams _currentParams = FilterParams.empty;

  NotificationCubit(this._repository) : super(const NotificationInitial());

  Future<void> load([FilterParams params = FilterParams.empty]) async {
    _currentParams = params;
    emit(const NotificationLoading());
    try {
      final notifications = await _repository.getNotifications(params);
      final unreadCount = notifications.where((n) => !n.isRead).length;
      emit(NotificationLoaded(
          notifications: notifications, unreadCount: unreadCount));
    } catch (e) {
      emit(NotificationError(friendlyError(e)));
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _repository.markRead(id);
      await load(_currentParams);
    } catch (e) {
      emit(NotificationError(friendlyError(e)));
    }
  }

  Future<void> markAllRead() async {
    try {
      await _repository.markAllRead();
      await load(_currentParams);
    } catch (e) {
      emit(NotificationError(friendlyError(e)));
    }
  }

  Future<void> delete(int id) async {
    try {
      await _repository.deleteNotification(id);
      await load(_currentParams);
    } catch (e) {
      emit(NotificationError(friendlyError(e)));
    }
  }

  Future<void> clearAll() async {
    try {
      await _repository.clearAll();
      emit(const NotificationLoaded(notifications: [], unreadCount: 0));
    } catch (e) {
      emit(NotificationError(friendlyError(e)));
    }
  }
}
