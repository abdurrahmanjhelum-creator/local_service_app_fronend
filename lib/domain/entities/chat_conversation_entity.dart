/// Chat Conversation Entity - Domain layer representation of a conversation
/// 
/// This entity represents a conversation between a customer and a provider,
/// following clean architecture principles.
class ChatConversationEntity {
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

  ChatConversationEntity({
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

  /// Get the other participant's details based on current user role
  String getOtherParticipantName(String currentUserId, String userRole) {
    if (userRole == 'customer') {
      return providerName;
    } else {
      return customerName;
    }
  }

  String getOtherParticipantProfileImage(String currentUserId, String userRole) {
    if (userRole == 'customer') {
      return providerProfileImage;
    } else {
      return customerProfileImage;
    }
  }

  String getOtherParticipantId(String currentUserId, String userRole) {
    if (userRole == 'customer') {
      return providerId;
    } else {
      return customerId;
    }
  }

  /// Check if conversation has unread messages
  bool get hasUnreadMessages => unreadCount > 0;

  /// Get formatted last message time
  String getFormattedLastMessageTime() {
    if (lastMessageTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(lastMessageTime!);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastMessageTime!.day}/${lastMessageTime!.month}/${lastMessageTime!.year}';
    }
  }

  ChatConversationEntity copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerProfileImage,
    String? providerId,
    String? providerName,
    String? providerProfileImage,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ChatConversationEntity(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerProfileImage: customerProfileImage ?? this.customerProfileImage,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      providerProfileImage: providerProfileImage ?? this.providerProfileImage,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}