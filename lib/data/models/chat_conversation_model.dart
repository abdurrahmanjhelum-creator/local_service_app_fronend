import '../../domain/entities/chat_conversation_entity.dart';

/// Chat Conversation Model - Data layer representation for API/Socket responses
/// 
/// This model handles the conversion between JSON data from the backend
/// and domain entities, following clean architecture principles.
class ChatConversationModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerProfileImage;
  final String providerId;
  final String providerName;
  final String providerProfileImage;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  ChatConversationModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerProfileImage,
    required this.providerId,
    required this.providerName,
    required this.providerProfileImage,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    return ChatConversationModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      customerName: json['customerName'] ?? '',
      customerProfileImage: json['customerProfileImage'] ?? '',
      providerId: json['providerId']?.toString() ?? '',
      providerName: json['providerName'] ?? '',
      providerProfileImage: json['providerProfileImage'] ?? '',
      lastMessage: json['lastMessage'],
      lastMessageTime: _parseDateTime(json['lastMessageTime']),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerProfileImage': customerProfileImage,
      'providerId': providerId,
      'providerName': providerName,
      'providerProfileImage': providerProfileImage,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Convert to domain entity
  ChatConversationEntity toEntity() {
    return ChatConversationEntity(
      id: id,
      customerId: customerId,
      customerName: customerName,
      customerProfileImage: customerProfileImage,
      providerId: providerId,
      providerName: providerName,
      providerProfileImage: providerProfileImage,
      lastMessage: lastMessage,
      lastMessageTime: lastMessageTime,
      unreadCount: unreadCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
    );
  }

  /// Convert from domain entity
  factory ChatConversationModel.fromEntity(ChatConversationEntity entity) {
    return ChatConversationModel(
      id: entity.id,
      customerId: entity.customerId,
      customerName: entity.customerName,
      customerProfileImage: entity.customerProfileImage,
      providerId: entity.providerId,
      providerName: entity.providerName,
      providerProfileImage: entity.providerProfileImage,
      lastMessage: entity.lastMessage,
      lastMessageTime: entity.lastMessageTime,
      unreadCount: entity.unreadCount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isActive: entity.isActive,
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
}