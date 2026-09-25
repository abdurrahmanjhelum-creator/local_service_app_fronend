import '../repositories/chat_repository.dart';

/// Send Typing Indicator Use Case - Domain layer business logic for typing indicators
/// 
/// This use case encapsulates the business logic for sending typing indicators
/// in a conversation, following clean architecture principles.
class SendTypingIndicatorUseCase {
  final ChatRepository _chatRepository;

  SendTypingIndicatorUseCase(this._chatRepository);

  /// Execute the use case to send typing indicator
  Future<void> call({
    required String conversationId,
    required String userId,
    required String userName,
    required bool isTyping,
  }) async {
    await _chatRepository.sendTypingIndicator(
      conversationId: conversationId,
      userId: userId,
      userName: userName,
      isTyping: isTyping,
    );
  }
}