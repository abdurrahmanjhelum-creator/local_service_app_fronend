import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking_model.dart';
import '../models/notification_model.dart';
import '../services/socket_service.dart';
import '../utils/api_constants.dart';
import 'booking_provider.dart';
import 'notification_provider.dart';

/// Clean Architecture Controller for Real-Time Socket Events & System Notifications
/// On Vercel production, WebSockets are unavailable — poll HTTP instead.
class SocketEventController {
  final Ref ref;
  final SocketService _socketService = SocketService();
  StreamSubscription? _bookingCreatedSub;
  StreamSubscription? _bookingStatusSub;
  StreamSubscription? _notificationSub;
  Timer? _notificationPollTimer;
  Timer? _bookingPollTimer;

  SocketEventController(this.ref) {
    _initListeners();
    if (ApiConstants.useProduction) {
      _startProductionPolling();
    }
  }

  void _startProductionPolling() {
    // Notification panel: refresh every 8s so new booking alerts appear without sockets
    // Fast poll so booking/chat alerts appear within a few seconds (Vercel has no sockets)
    _notificationPollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      ref.read(notificationProvider.notifier).loadNotifications(silent: true);
    });
    _bookingPollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      ref.read(bookingProvider.notifier).loadBookings();
    });
    debugPrint('ℹ️ Production mode: HTTP polling enabled for live notifications');
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
        // addNotificationToState also triggers in-app + system alert
        ref.read(notificationProvider.notifier).addNotificationToState(notification);
      } catch (e) {
        debugPrint('⚠️ Error parsing socket notification_received: $e');
        ref.read(notificationProvider.notifier).loadNotifications();
      }
    });
  }



  void dispose() {
    _bookingCreatedSub?.cancel();
    _bookingStatusSub?.cancel();
    _notificationSub?.cancel();
    _notificationPollTimer?.cancel();
    _bookingPollTimer?.cancel();
  }
}

/// Riverpod Provider managing SocketEventController lifecycle
final socketEventProvider = Provider<SocketEventController>((ref) {
  final controller = SocketEventController(ref);
  ref.onDispose(() => controller.dispose());
  return controller;
});
