import '../entities/chat_message_entity.dart';
import '../repositories/chat_repository.dart';

/// Get Messages Use Case - Domain layer business logic for fetching messages
/// 
/// This use case encapsulates the business logic for retrieving messages
/// from a specific conversation, following clean architecture principles.
class GetMessagesUseCase {
  final ChatRepository _chatRepository;

  GetMessagesUseCase(this._chatRepository);

  /// Execute the use case to get messages from a conversation
  /// 
  /// Returns a list of message entities sorted by creation time (oldest first)
  Future<List<ChatMessageEntity>> call(String conversationId) async {
    final messages = await _chatRepository.getMessages(conversationId);
    
    // Sort by creation time (oldest first for chat display)
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    return messages;
  }
}