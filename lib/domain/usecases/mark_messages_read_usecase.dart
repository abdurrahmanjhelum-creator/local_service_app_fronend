import '../repositories/chat_repository.dart';

/// Mark Messages Read Use Case - Domain layer business logic for marking messages as read
/// 
/// This use case encapsulates the business logic for marking messages as read
/// in a conversation, following clean architecture principles.
class MarkMessagesReadUseCase {
  final ChatRepository _chatRepository;

  MarkMessagesReadUseCase(this._chatRepository);

  /// Execute the use case to mark messages as read
  Future<void> call({
    required String conversationId,
    required String userId,
  }) async {
    await _chatRepository.markMessagesAsRead(conversationId, userId);
  }
}