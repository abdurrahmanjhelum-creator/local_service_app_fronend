import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_provider.dart';
import 'providers/socket_event_provider.dart';
import 'screens/shared/splash_screen.dart';
import 'services/fcm_service.dart';
import 'services/socket_service.dart';
import 'utils/app_colors.dart';
import 'utils/app_constants.dart';

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
    // Keep socket event controller alive for app lifecycle
    ref.watch(socketEventProvider);
    
    final socketService = SocketService();

    // Manage socket connection based on user authentication state
    ref.listen(authProvider, (previous, next) async {
      // When user logs in
      if (previous?.user == null && next.user != null) {
        debugPrint('🟢 User logged in, connecting socket...');

        try {
          // Connect socket
          await socketService.connect();

          // Join user private room to receive real-time events
          socketService.joinRoom(next.user!.id);
        } catch (e) {
          debugPrint('⚠️ Socket connection failed: $e');
          debugPrint('⚠️ Ensure backend server is running on port 5000');
        }

        // Sync FCM token for push notifications
        await FcmService().syncCurrentToken();
      }
      // When user logs out
      else if (previous?.user != null && next.user == null) {
        debugPrint('🔴 User logged out, disconnecting socket...');
        socketService.disconnect();
      }
    });

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
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
