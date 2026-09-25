import '../entities/chat_conversation_entity.dart';
import '../repositories/chat_repository.dart';

/// Get Conversations Use Case - Domain layer business logic for fetching conversations
/// 
/// This use case encapsulates the business logic for retrieving all conversations
/// for the current user, following clean architecture principles.
class GetConversationsUseCase {
  final ChatRepository _chatRepository;

  GetConversationsUseCase(this._chatRepository);

  /// Execute the use case to get all conversations for a user
  /// 
  /// Returns a list of conversation entities sorted by last message time
  Future<List<ChatConversationEntity>> call(String userId) async {
    final conversations = await _chatRepository.getConversations(userId);
    
    // Sort by last message time (most recent first)
    conversations.sort((a, b) {
      if (a.lastMessageTime == null && b.lastMessageTime == null) {
        return b.createdAt.compareTo(a.createdAt);
      }
      if (a.lastMessageTime == null) return 1;
      if (b.lastMessageTime == null) return -1;
      return b.lastMessageTime!.compareTo(a.lastMessageTime!);
    });
    
    return conversations;
  }
}