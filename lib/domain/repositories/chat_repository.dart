import '../entities/chat_conversation_entity.dart';
import '../entities/chat_message_entity.dart';

/// Chat Repository Interface - Domain layer contract for chat data operations
/// 
/// This interface defines the contract that any chat repository implementation
/// must follow, following clean architecture principles. The domain layer
/// depends on this abstraction, not on concrete implementations.
abstract class ChatRepository {
  /// Send a message in a conversation
  Future<ChatMessageEntity> sendMessage(ChatMessageEntity message);

  /// Get all conversations for a user
  Future<List<ChatConversationEntity>> getConversations(String userId);

  /// Get messages from a specific conversation
  Future<List<ChatMessageEntity>> getMessages(String conversationId);

  /// Create a new conversation between customer and provider
  Future<ChatConversationEntity> createConversation({
    required String customerId,
    required String customerName,
    required String customerProfileImage,
    required String providerId,
    required String providerName,
    required String providerProfileImage,
  });

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId, String userId);

  /// Get or create conversation between two users
  Future<ChatConversationEntity> getOrCreateConversation({
    required String customerId,
    required String customerName,
    required String customerProfileImage,
    required String providerId,
    required String providerName,
    required String providerProfileImage,
  });

  /// Stream of real-time message updates for a conversation
  Stream<ChatMessageEntity> getMessageUpdates(String conversationId);

  /// Stream of real-time conversation updates for a user
  Stream<ChatConversationEntity> getConversationUpdates(String userId);

  /// Send typing indicator
  Future<void> sendTypingIndicator({
    required String conversationId,
    required String userId,
    required String userName,
    required bool isTyping,
  });

  /// Stream of typing indicators for a conversation
  Stream<TypingIndicatorEvent> getTypingIndicators(String conversationId);
}

/// Typing Indicator Event - Represents typing status changes
class TypingIndicatorEvent {
  final String userId;
  final String userName;
  final bool isTyping;
  final DateTime timestamp;

  TypingIndicatorEvent({
    required this.userId,
    required this.userName,
    required this.isTyping,
    required this.timestamp,
  });
}