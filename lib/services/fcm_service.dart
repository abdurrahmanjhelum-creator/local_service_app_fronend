import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_api.dart';

const String kNotificationChannelId = 'local_services_high_importance_v3';
const String kNotificationChannelName = 'Service Alerts & Status Updates';
const String kNotificationChannelDescription =
    'Ringing sound and top banner alerts for bookings and notifications';

// High Importance Android Notification Channel (Banner + Ringing Sound + Vibration)
const AndroidNotificationChannel highImportanceChannel =
    AndroidNotificationChannel(
  kNotificationChannelId,
  kNotificationChannelName,
  description: kNotificationChannelDescription,
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
  showBadge: true,
);

/// Top-level background message handler for FCM (App Killed / Closed State)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('📱 Handling FCM background message: ${message.messageId}');
    
    // FCM already displays a `notification` payload in background/killed.
    // Only show a local notification for data-only messages.
    if (message.notification != null) return;

    final title = message.data['title']?.toString() ?? 'New Notification';
    final body = message.data['body']?.toString() ?? '';
    await _showBackgroundNotification(
      title: title,
      body: body,
      payload: message.data['bookingId']?.toString(),
    );
  } catch (e) {
    debugPrint('⚠️ Error in FCM background handler: $e');
  }
}

/// Static method to show notifications from background handler
Future<void> _showBackgroundNotification({
  required String title,
  required String body,
  String? payload,
}) async {
  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await localNotifications.initialize(initSettings);

  final androidImplementation = localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  if (androidImplementation != null) {
    await androidImplementation.requestNotificationsPermission();
    await androidImplementation.createNotificationChannel(highImportanceChannel);
  }

  final androidDetails = AndroidNotificationDetails(
    kNotificationChannelId,
    kNotificationChannelName,
    channelDescription: kNotificationChannelDescription,
    importance: Importance.max,
    priority: Priority.max,
    playSound: true,
    enableVibration: true,
    icon: '@mipmap/ic_launcher',
    visibility: NotificationVisibility.public,
    channelShowBadge: true,
    audioAttributesUsage: AudioAttributesUsage.notification,
    styleInformation: BigTextStyleInformation(body),
  );

  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    sound: 'default',
  );

  final notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  await localNotifications.show(
    id,
    title,
    body,
    notificationDetails,
    payload: payload,
  );
}

/// FcmService (System Notifications & Firebase Cloud Messaging Manager)
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final NotificationApi _api = NotificationApi();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _lastShownKey;
  DateTime? _lastShownAt;

  /// 1. System Notifications & FCM Initialize
  Future<void> init() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      debugPrint('ℹ️ Web environment: Skipping mobile native FCM & Local Notifications');
      _isInitialized = true;
      return;
    }

    try {
      // Safe Firebase Core Initialization
      try {
        await Firebase.initializeApp();
        debugPrint('✅ Firebase Core initialized');
      } catch (e) {
        debugPrint('⚠️ Firebase Core init notice: $e');
      }

      // Android ke liye App Launcher Icon
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS ke liye Sound + Alert Permissions
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Local Notifications Plugin Initialize
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('🔔 System Notification Tapped: ${details.payload}');
        },
      );

      // Android 13+ Runtime Permission Request & Channel Creation
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        // Register High Importance Notification Channel on Android Device
        await androidImplementation.createNotificationChannel(highImportanceChannel);
      }

      // Setup FCM Listeners & Token Sync
      _setupFcmListeners();

      _isInitialized = true;
      debugPrint('✅ System Ringing & FCM Notifications Initialized Successfully!');
    } catch (e) {
      debugPrint('⚠️ System Notification Init Error: $e');
    }
  }

  /// 2. Setup FCM Listeners & Token Synchronization
  void _setupFcmListeners() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Get FCM Device Token & Sync with Backend
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('📱 FCM Token: $token');
        await syncTokenWithBackend(token);
      }

      // Listen for Token Refresh
      messaging.onTokenRefresh.listen((newToken) {
        syncTokenWithBackend(newToken);
      });

      // Foreground FCM Message Listener (deduped with socket local alerts)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final title = notification?.title ??
            message.data['title']?.toString() ??
            'New Notification';
        final body =
            notification?.body ?? message.data['body']?.toString() ?? '';
        showSystemNotification(
          title: title,
          body: body,
          payload: message.data['bookingId']?.toString(),
        );
      });
    } catch (e) {
      debugPrint('⚠️ FCM Setup Warning: $e');
    }
  }

  /// 3. Mobile System Bar Par Ringing Sound Ke Saath Notification Dikhaayein
  Future<void> showSystemNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (kIsWeb) return;
      if (!_isInitialized) await init();

      final dedupeKey = '$title|$body';
      final now = DateTime.now();
      if (_lastShownKey == dedupeKey &&
          _lastShownAt != null &&
          now.difference(_lastShownAt!) < const Duration(seconds: 3)) {
        return;
      }
      _lastShownKey = dedupeKey;
      _lastShownAt = now;

      // Android Notification Channel Details (High Importance = Top Banner + Shade Panel + Ringing Sound)
      final androidDetails = AndroidNotificationDetails(
        kNotificationChannelId,
        kNotificationChannelName,
        channelDescription: kNotificationChannelDescription,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        visibility: NotificationVisibility.public,
        channelShowBadge: true,
        audioAttributesUsage: AudioAttributesUsage.notification,
        styleInformation: BigTextStyleInformation(body),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Mobile System Tray Par Notification Pop Up Karein
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _localNotifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ Failed to show system notification: $e');
    }
  }

  Future<void> syncTokenWithBackend(String token) async {
    await _api.sendFcmToken(token);
  }

  /// Call after login so the token is stored on the authenticated user.
  Future<void> syncCurrentToken() async {
    if (kIsWeb) return;
    try {
      if (!_isInitialized) await init();
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await syncTokenWithBackend(token);
      }
    } catch (e) {
      debugPrint('⚠️ FCM token sync skipped: $e');
    }
  }

  /// Test Notification Function - Verify Sound + Vibration Working
  Future<void> testNotification() async {
    await showSystemNotification(
      title: '🔔 Test Notification',
      body: 'Notification system with sound and vibration is working!',
      payload: 'test',
    );
    debugPrint('🔔 Test notification sent - Check for sound and vibration!');
  }

  /// Test Multiple Notifications
  Future<void> testMultipleNotifications() async {
    await testNotification();
    await Future.delayed(const Duration(seconds: 2));
    await showSystemNotification(
      title: '📱 New Booking Alert',
      body: 'You have received a new booking request for Plumbing Service',
      payload: 'booking123',
    );
    await Future.delayed(const Duration(seconds: 2));
    await showSystemNotification(
      title: '✅ Booking Confirmed',
      body: 'Your booking has been confirmed by the service provider',
      payload: 'booking123',
    );
    debugPrint('🔔 Multiple test notifications sent!');
  }
}
