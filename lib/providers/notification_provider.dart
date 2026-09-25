import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notification_api.dart';

class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? errorMessage;

  NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? errorMessage,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationState> {
  final NotificationApi _api = NotificationApi();

  @override
  NotificationState build() => NotificationState();

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _api.getNotifications();
      state = state.copyWith(
        notifications: res['notifications'] as List<NotificationModel>,
        unreadCount: res['unreadCount'] as int,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> markAsRead(String id) async {
    final success = await _api.markAsRead(id);
    if (success) {
      final updatedList = state.notifications.map((item) {
        if (item.id == id) {
          return NotificationModel(
            id: item.id,
            userId: item.userId,
            title: item.title,
            body: item.body,
            type: item.type,
            bookingId: item.bookingId,
            status: item.status,
            isRead: true,
            createdAt: item.createdAt,
          );
        }
        return item;
      }).toList();

      final newUnread = (state.unreadCount - 1).clamp(0, 999);
      state = state.copyWith(
        notifications: updatedList,
        unreadCount: newUnread,
      );
    }
  }

  Future<void> markAllAsRead() async {
    final success = await _api.markAllAsRead();
    if (success) {
      final updatedList = state.notifications.map((item) {
        return NotificationModel(
          id: item.id,
          userId: item.userId,
          title: item.title,
          body: item.body,
          type: item.type,
          bookingId: item.bookingId,
          status: item.status,
          isRead: true,
          createdAt: item.createdAt,
        );
      }).toList();

      state = state.copyWith(
        notifications: updatedList,
        unreadCount: 0,
      );
    }
  }

  Future<void> clearAll() async {
    final success = await _api.clearNotifications();
    if (success) {
      state = state.copyWith(
        notifications: [],
        unreadCount: 0,
      );
    }
  }

  /// Real-time In-Memory State Updates from Socket Events (Zero HTTP Overhead)
  void addNotificationToState(NotificationModel notification) {
    // Avoid duplicates if same notification arrives twice
    if (notification.id.isNotEmpty &&
        state.notifications.any((n) => n.id == notification.id)) {
      return;
    }

    final updatedList = [notification, ...state.notifications];
    final newUnread = notification.isRead ? state.unreadCount : state.unreadCount + 1;

    state = state.copyWith(
      notifications: updatedList,
      unreadCount: newUnread,
    );
  }
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);
