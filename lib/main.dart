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
    // Firebase background message handler setup may fail on web or without proper config
    debugPrint('⚠️ Firebase background handler setup skipped: $e');
  }

  // System Notifications and Sound channel initialize karein
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

    // Socket connection manage karo - user login/logout ke basis par
    ref.listen(authProvider, (previous, next) async {
      // Jab user login ho jaye
      if (previous?.user == null && next.user != null) {
        debugPrint('🟢 User logged in, connecting socket...');

        try {
          // Pehle socket connect karo (wait for connection)
          await socketService.connect();

          // Phir user ki private room join karo taake usko specific events milein
          socketService.joinRoom(next.user!.id);
        } catch (e) {
          debugPrint('⚠️ Socket connection failed: $e');
          debugPrint('⚠️ Make sure backend server is running on port 5000');
        }

        // Save FCM token on this logged-in user so later pushes can ring
        await FcmService().syncCurrentToken();
      }
      // Jab user logout ho jaye
      else if (previous?.user != null && next.user == null) {
        debugPrint('🔴 User logged out, disconnecting socket...');
        socketService.disconnect(); // Socket connection disconnect karo
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
