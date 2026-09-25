import '../../domain/entities/chat_message_entity.dart'
    show ChatMessageEntity, MessageType, MessageStatus;

/// Chat Message Model - Data layer representation for API/Socket responses
/// 
/// This model handles the conversion between JSON data from the backend
/// and domain entities, following clean architecture principles.
class ChatMessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderProfileImage;
  final String content;
  final String type;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isRead;

  ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderProfileImage,
    required this.content,
    required this.type,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.isRead = false,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName'] ?? '',
      senderProfileImage: json['senderProfileImage'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'text',
      status: json['status'] ?? 'sending',
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderProfileImage': senderProfileImage,
      'content': content,
      'type': type,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      'isRead': isRead,
    };
  }

  /// Convert to domain entity
  ChatMessageEntity toEntity() {
    return ChatMessageEntity(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderProfileImage: senderProfileImage,
      content: content,
      type: _parseMessageType(type),
      status: _parseMessageStatus(status),
      createdAt: createdAt,
      updatedAt: updatedAt,
      isRead: isRead,
    );
  }

  /// Convert from domain entity
  factory ChatMessageModel.fromEntity(ChatMessageEntity entity) {
    return ChatMessageModel(
      id: entity.id,
      conversationId: entity.conversationId,
      senderId: entity.senderId,
      senderName: entity.senderName,
      senderProfileImage: entity.senderProfileImage,
      content: entity.content,
      type: _typeToString(entity.type),
      status: _statusToString(entity.status),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isRead: entity.isRead,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static MessageType _parseMessageType(String value) {
    switch (value) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  static MessageStatus _parseMessageStatus(String value) {
    switch (value) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sending;
    }
  }

  static String _typeToString(MessageType type) {
    switch (type) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.system:
        return 'system';
    }
  }

  static String _statusToString(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return 'sending';
      case MessageStatus.sent:
        return 'sent';
      case MessageStatus.delivered:
        return 'delivered';
      case MessageStatus.read:
        return 'read';
      case MessageStatus.failed:
        return 'failed';
    }
  }
}