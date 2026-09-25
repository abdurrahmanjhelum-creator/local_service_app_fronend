import '../entities/chat_message_entity.dart';
import '../repositories/chat_repository.dart';

/// Send Message Use Case - Domain layer business logic for sending messages
/// 
/// This use case encapsulates the business logic for sending a message
/// in a conversation, following clean architecture principles.
class SendMessageUseCase {
  final ChatRepository _chatRepository;

  SendMessageUseCase(this._chatRepository);

  /// Execute the use case to send a message
  /// 
  /// Returns the sent message entity with updated status
  Future<ChatMessageEntity> call({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String senderProfileImage,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    // Create a new message entity with sending status
    final message = ChatMessageEntity(
      id: '', // Will be assigned by backend
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderProfileImage: senderProfileImage,
      content: content,
      type: type,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
    );

    // Send the message through the repository
    return await _chatRepository.sendMessage(message);
  }
}