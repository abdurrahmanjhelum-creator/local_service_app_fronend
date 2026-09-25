import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking_model.dart';
import '../models/notification_model.dart';
import '../services/fcm_service.dart';
import '../services/socket_service.dart';
import 'booking_provider.dart';
import 'notification_provider.dart';

/// Clean Architecture Controller for Real-Time Socket Events & System Notifications
class SocketEventController {
  final Ref ref;
  final SocketService _socketService = SocketService();
  StreamSubscription? _bookingCreatedSub;
  StreamSubscription? _bookingStatusSub;
  StreamSubscription? _notificationSub;

  SocketEventController(this.ref) {
    _initListeners();
  }

  void _initListeners() {
    // 1. Provider Notification: New booking created
    _bookingCreatedSub = _socketService.onBookingCreated.listen((data) {
      try {
        final booking = BookingModel.fromJson(data);
        ref.read(bookingProvider.notifier).addOrUpdateBookingInState(booking);
      } catch (e) {
        debugPrint('⚠️ Error parsing socket booking_created: $e');
        ref.read(bookingProvider.notifier).loadBookings();
      }

      // Tone + in-app panel come from `notification_received` (avoids duplicate alerts)
    });

    // 2. Booking Status Updates (Customer & Provider)
    _bookingStatusSub = _socketService.onBookingStatusUpdated.listen((data) {
      try {
        final booking = BookingModel.fromJson(data);
        ref.read(bookingProvider.notifier).addOrUpdateBookingInState(booking);
      } catch (e) {
        debugPrint('⚠️ Error parsing socket booking_status_updated: $e');
        ref.read(bookingProvider.notifier).loadBookings();
      }

      // Tone + in-app panel come from `notification_received` (avoids duplicate alerts)
    });

    // 3. Persisted Notifications
    _notificationSub = _socketService.onNotificationReceived.listen((data) {
      try {
        final notification = NotificationModel.fromJson(data);
        ref.read(notificationProvider.notifier).addNotificationToState(notification);
      } catch (e) {
        debugPrint('⚠️ Error parsing socket notification_received: $e');
        ref.read(notificationProvider.notifier).loadNotifications();
      }

      final title = data['title']?.toString() ?? 'New notification';
      final body = data['body']?.toString() ?? '';
      FcmService().showSystemNotification(
        title: title,
        body: body,
        payload: data['_id']?.toString(),
      );
    });
  }

  void dispose() {
    _bookingCreatedSub?.cancel();
    _bookingStatusSub?.cancel();
    _notificationSub?.cancel();
  }
}

/// Riverpod Provider managing SocketEventController lifecycle
final socketEventProvider = Provider<SocketEventController>((ref) {
  final controller = SocketEventController(ref);
  ref.onDispose(() => controller.dispose());
  return controller;
});
