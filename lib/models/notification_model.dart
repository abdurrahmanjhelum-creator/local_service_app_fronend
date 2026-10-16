class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String bookingId;
  final String status;
  final String conversationId;
  final String fromUserName;
  final bool isRead;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.bookingId,
    required this.status,
    this.conversationId = '',
    this.fromUserName = '',
    required this.isRead,
    required this.createdAt,
  });

  /// WhatsApp-style: who the alert is about
  String get displayName {
    if (fromUserName.trim().isNotEmpty) return fromUserName.trim();
    // Title for messages is already the sender name
    if (type == 'message' && title.trim().isNotEmpty) return title.trim();
    if (title.contains('·')) {
      final parts = title.split('·');
      if (parts.length > 1) return parts.last.trim();
    }
    return title;
  }

  String get contextLabel {
    switch (type) {
      case 'message':
        return 'Message';
      case 'booking_created':
        return 'New booking';
      case 'booking_status':
        return status.isNotEmpty ? 'Booking · $status' : 'Booking update';
      case 'review_received':
        return 'Review';
      default:
        return 'Alert';
    }
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map ? json['data'] as Map : <String, dynamic>{};
    final rawId = json['_id']?.toString() ??
        json['id']?.toString() ??
        json['notificationId']?.toString() ??
        '';
    final rawUserId = json['user']?.toString() ??
        json['userId']?.toString() ??
        '';

    return NotificationModel(
      id: rawId.trim(),
      userId: rawUserId.trim(),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      bookingId: data['bookingId']?.toString() ?? '',
      status: data['status']?.toString() ?? '',
      conversationId: data['conversationId']?.toString() ?? '',
      fromUserName: data['fromUserName']?.toString() ?? '',
      isRead: json['isRead'] == true || json['isRead']?.toString() == 'true',
      createdAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }
}
