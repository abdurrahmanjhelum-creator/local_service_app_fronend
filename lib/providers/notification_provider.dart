import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/fcm_service.dart';
import '../services/notification_api.dart';
import 'notification_alert_provider.dart';

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
  final Set<String> _knownIds = {};
  bool _hasHydrated = false;

  @override
  NotificationState build() => NotificationState();

  Future<void> loadNotifications({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }
    try {
      final res = await _api.getNotifications();
      final list = res['notifications'] as List<NotificationModel>;
      final unread = res['unreadCount'] as int;

      // After first load, any NEW unread items = real-time alert (like real apps)
      if (_hasHydrated && silent) {
        for (final n in list) {
          if (n.id.isEmpty || _knownIds.contains(n.id) || n.isRead) continue;
          _emitRealtimeAlert(n);
        }
      }

      _knownIds
        ..clear()
        ..addAll(list.map((n) => n.id).where((id) => id.isNotEmpty));
      _hasHydrated = true;

      state = state.copyWith(
        notifications: list,
        unreadCount: unread,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void _emitRealtimeAlert(NotificationModel n) {
    ref.read(notificationAlertProvider.notifier).show(
          id: n.id,
          title: n.title,
          body: n.body,
        );
    FcmService().showSystemNotification(
      title: n.title,
      body: n.body,
      payload: n.id,
    );
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
            conversationId: item.conversationId,
            fromUserName: item.fromUserName,
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
          conversationId: item.conversationId,
          fromUserName: item.fromUserName,
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

    if (notification.id.isNotEmpty) {
      _knownIds.add(notification.id);
    }

    final updatedList = [notification, ...state.notifications];
    final newUnread = notification.isRead ? state.unreadCount : state.unreadCount + 1;

    state = state.copyWith(
      notifications: updatedList,
      unreadCount: newUnread,
    );

    if (!notification.isRead) {
      _emitRealtimeAlert(notification);
    }
  }
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);
