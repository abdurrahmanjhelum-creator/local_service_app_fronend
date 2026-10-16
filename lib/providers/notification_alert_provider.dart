import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Latest in-app notification alert (toast banner) for real-time UX.
class NotificationAlert {
  final String id;
  final String title;
  final String body;
  final DateTime at;

  NotificationAlert({
    required this.id,
    required this.title,
    required this.body,
    DateTime? at,
  }) : at = at ?? DateTime.now();
}

class NotificationAlertNotifier extends Notifier<NotificationAlert?> {
  @override
  NotificationAlert? build() => null;

  void show({
    required String id,
    required String title,
    required String body,
  }) {
    state = NotificationAlert(id: id, title: title, body: body);
  }

  void clear() => state = null;
}

final notificationAlertProvider =
    NotifierProvider<NotificationAlertNotifier, NotificationAlert?>(
  NotificationAlertNotifier.new,
);
