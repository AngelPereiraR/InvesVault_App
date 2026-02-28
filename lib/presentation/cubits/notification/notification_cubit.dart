import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';

part 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _repository;
  NotificationCubit(this._repository) : super(const NotificationInitial());

  Future<void> load() async {
    emit(const NotificationLoading());
    try {
      final notifications = await _repository.getNotifications();
      final unreadCount = notifications.where((n) => !n.isRead).length;
      emit(NotificationLoaded(
          notifications: notifications, unreadCount: unreadCount));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _repository.markRead(id);
      await load();
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> markAllRead() async {
    try {
      await _repository.markAllRead();
      await load();
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> delete(int id) async {
    try {
      await _repository.deleteNotification(id);
      await load();
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> clearAll() async {
    try {
      await _repository.clearAll();
      emit(const NotificationLoaded(notifications: [], unreadCount: 0));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }
}
