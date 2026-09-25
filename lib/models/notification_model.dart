class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String bookingId;
  final String status;
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
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map ? json['data'] : <String, dynamic>{};
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
      isRead: json['isRead'] == true || json['isRead']?.toString() == 'true',
      createdAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }
}
