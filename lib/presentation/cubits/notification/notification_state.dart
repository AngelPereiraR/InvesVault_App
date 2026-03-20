part of 'notification_cubit.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool hasMore;
  final int currentPage;
  final bool isLoadingMore;
  final bool isSearching;

  const NotificationLoaded({
    required this.notifications,
    required this.unreadCount,
    this.hasMore = false,
    this.currentPage = 1,
    this.isLoadingMore = false,
    this.isSearching = false,
  });

  NotificationLoaded copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? hasMore,
    int? currentPage,
    bool? isLoadingMore,
    bool? isSearching,
  }) =>
      NotificationLoaded(
        notifications: notifications ?? this.notifications,
        unreadCount: unreadCount ?? this.unreadCount,
        hasMore: hasMore ?? this.hasMore,
        currentPage: currentPage ?? this.currentPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        isSearching: isSearching ?? this.isSearching,
      );

  @override
  List<Object?> get props =>
      [notifications, unreadCount, hasMore, currentPage, isLoadingMore, isSearching];
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}
