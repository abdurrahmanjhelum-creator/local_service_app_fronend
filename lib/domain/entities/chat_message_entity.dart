/// Chat Message Entity - Domain layer representation of a chat message
/// 
/// This entity represents a single message in a conversation between
/// a customer and a provider, following clean architecture principles.
class ChatMessageEntity {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderProfileImage;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isRead;

  ChatMessageEntity({
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

  /// Check if message is sent by current user
  bool isSentByCurrentUser(String currentUserId) {
    return senderId == currentUserId;
  }

  /// Check if message is delivered
  bool get isDelivered => status == MessageStatus.delivered || status == MessageStatus.read;

  /// Check if message is read
  bool get isReadStatus => status == MessageStatus.read;

  ChatMessageEntity copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderProfileImage,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRead,
  }) {
    return ChatMessageEntity(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderProfileImage: senderProfileImage ?? this.senderProfileImage,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

enum MessageType {
  text,
  image,
  system,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

extension MessageTypeExtension on MessageType {
  String toJson() {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.system:
        return 'system';
    }
  }

  static MessageType fromJson(String value) {
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
}

extension MessageStatusExtension on MessageStatus {
  String toJson() {
    switch (this) {
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

  static MessageStatus fromJson(String value) {
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
}