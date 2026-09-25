import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  // 🚀 LIVE PRODUCTION VERCEL SERVER URL
  static const bool useProduction = true;
  static const String liveProductionUrl = 'https://local-service-app-backend-three.vercel.app';

  // 📱 LOCAL DEV IP (When testing locally with backend on same WiFi)
  static const String computerIp = '10.253.68.29';

  static String get baseUrl {
    if (useProduction) return '$liveProductionUrl/api';

    if (kIsWeb) return 'http://localhost:5000/api';
    
    if (Platform.isAndroid && !kIsWeb) {
      return 'http://10.0.2.2:5000/api'; 
    }

    if (computerIp.isNotEmpty) return 'http://$computerIp:5000/api';
    
    return 'http://localhost:5000/api';
  }

  static String get socketBaseUrl {
    if (useProduction) return liveProductionUrl;

    if (kIsWeb) return 'http://localhost:5000';
    if (Platform.isAndroid && !kIsWeb) return 'http://10.0.2.2:5000';
    
    if (computerIp.isNotEmpty) return 'http://$computerIp:5000';
    return 'http://localhost:5000';
  }

  // Chat-specific endpoints
  static String get chatConversations => '$baseUrl/chat/conversations';
  static String get chatMessages => '$baseUrl/chat/messages';
  static String get chatCreateConversation => '$baseUrl/chat/conversations';
  static String get chatGetOrCreate => '$baseUrl/chat/conversations/get-or-create';
  static String get chatSendMessage => '$baseUrl/chat/messages';
  static String get chatMarkRead => '$baseUrl/chat/messages';

  static String get register => '$baseUrl/auth/register-complete';
  static String get login => '$baseUrl/auth/login';
  static String get profile => '$baseUrl/auth/profile';
  static String get services => '$baseUrl/services/providers';
  static String get bookings => '$baseUrl/bookings';
  static String get categories => '$baseUrl/categories';
  static String get reviews => '$baseUrl/reviews';
}
