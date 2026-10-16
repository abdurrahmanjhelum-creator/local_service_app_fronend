import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_alert_provider.dart';
import 'providers/socket_event_provider.dart';
import 'screens/shared/notifications_screen.dart';
import 'screens/shared/splash_screen.dart';
import 'services/fcm_service.dart';
import 'services/socket_service.dart';
import 'utils/app_colors.dart';
import 'utils/app_constants.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('⚠️ Firebase background handler setup skipped: $e');
  }

  // Initialize System Notifications and Sound channel
  await FcmService().init();

  runApp(const ProviderScope(child: LocalServicesApp()));
}

class LocalServicesApp extends ConsumerWidget {
  const LocalServicesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep socket/poll controller alive for app lifecycle
    ref.watch(socketEventProvider);

    final socketService = SocketService();

    // Manage socket connection based on user authentication state
    ref.listen(authProvider, (previous, next) async {
      if (previous?.user == null && next.user != null) {
        debugPrint('🟢 User logged in, connecting socket...');

        try {
          await socketService.connect();
          socketService.joinRoom(next.user!.id);
        } catch (e) {
          debugPrint('⚠️ Socket connection failed: $e');
        }

        await FcmService().syncCurrentToken();
      } else if (previous?.user != null && next.user == null) {
        debugPrint('🔴 User logged out, disconnecting socket...');
        socketService.disconnect();
      }
    });

    // Real-time in-app banner when booking/chat notifications arrive
    ref.listen(notificationAlertProvider, (previous, next) {
      if (next == null) return;
      final messenger = rootScaffoldMessengerKey.currentState;
      if (messenger == null) return;

      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.gray900,
          duration: const Duration(seconds: 4),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                next.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                next.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'View',
            textColor: AppColors.secondary,
            onPressed: () {
              final nav = rootNavigatorKey.currentState;
              if (nav == null) return;
              nav.push(
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
          ),
        ),
      );
      ref.read(notificationAlertProvider.notifier).clear();
    });

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      navigatorKey: rootNavigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: Colors.transparent,
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            gradient: AppColors.appBackgroundGradient,
          ),
          child: child,
        );
      },
      home: const SplashScreen(),
    );
  }
}
