import '../models/notification_model.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';

class NotificationApi {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getNotifications() async {
    final response = await _api.get('${ApiConstants.baseUrl}/notifications');
    final map = asMap(response);
    final listRaw = map['notifications'];
    final List<NotificationModel> notifications = [];
    if (listRaw is List) {
      for (var item in listRaw) {
        notifications.add(NotificationModel.fromJson(asMap(item)));
      }
    }
    final int unreadCount = (map['unreadCount'] as num?)?.toInt() ?? 0;
    return {
      'notifications': notifications,
      'unreadCount': unreadCount,
    };
  }

  Future<bool> markAsRead(String id) async {
    try {
      await _api.put('${ApiConstants.baseUrl}/notifications/$id/read', {});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      await _api.put('${ApiConstants.baseUrl}/notifications/read-all', {});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clearNotifications() async {
    try {
      await _api.delete('${ApiConstants.baseUrl}/notifications/clear');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendFcmToken(String token) async {
    try {
      await _api.post('${ApiConstants.baseUrl}/notifications/fcm-token', {
        'fcmToken': token,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
