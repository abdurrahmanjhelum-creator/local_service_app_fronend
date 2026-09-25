import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking_model.dart';
import '../models/notification_model.dart';
import '../services/fcm_service.dart';
import '../services/socket_service.dart';
import '../utils/api_constants.dart';
import 'booking_provider.dart';
import 'notification_provider.dart';

/// Clean Architecture Controller for Real-Time Socket Events & System Notifications
/// 2-second polling for instant booking status updates when WebSocket unavailable
class SocketEventController {
  final Ref ref;
  final SocketService _socketService = SocketService();
  StreamSubscription? _bookingCreatedSub;
  StreamSubscription? _bookingStatusSub;
  StreamSubscription? _notificationSub;
  
  // 2-second polling for instant status updates
  Timer? _bookingStatusPollTimer;
  bool _isPollingBookingStatus = false;

  SocketEventController(this.ref) {
    _initListeners();
    // Polling disabled - relying on WebSocket only for better performance
    // Uncomment below for production Vercel deployment if needed
    // if (kIsWeb && ApiConstants.useProduction) {
    //   _startBookingStatusPolling();
    // }
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

  /// 2-second polling for instant booking status updates (Production/Vercel only)
  void _startBookingStatusPolling() {
    debugPrint('🔄 Starting 2-second polling for production environment (Vercel WebSockets unavailable)');
    _bookingStatusPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _pollBookingStatusFallback();
    });
  }

  /// Fallback polling for booking status when WebSocket fails
  Future<void> _pollBookingStatusFallback() async {
    if (_isPollingBookingStatus) return;
    _isPollingBookingStatus = true;

    try {
      // In production (Vercel), always poll since WebSockets don't work
      if (kIsWeb && ApiConstants.useProduction) {
        await ref.read(bookingProvider.notifier).loadBookings();
      } else if (!_socketService.isConnected) {
        // In development, only poll if socket is disconnected
        debugPrint('🔄 Status polling: Socket disconnected, checking booking status');
        await ref.read(bookingProvider.notifier).loadBookings();
      }
    } catch (e) {
      debugPrint('⚠️ Booking status polling error: $e');
    } finally {
      _isPollingBookingStatus = false;
    }
  }

  void dispose() {
    _bookingCreatedSub?.cancel();
    _bookingStatusSub?.cancel();
    _notificationSub?.cancel();
    _bookingStatusPollTimer?.cancel();
  }
}

/// Riverpod Provider managing SocketEventController lifecycle
final socketEventProvider = Provider<SocketEventController>((ref) {
  final controller = SocketEventController(ref);
  ref.onDispose(() => controller.dispose());
  return controller;
});
