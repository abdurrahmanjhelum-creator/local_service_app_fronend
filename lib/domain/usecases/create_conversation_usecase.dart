import '../entities/chat_conversation_entity.dart';
import '../repositories/chat_repository.dart';

/// Create Conversation Use Case - Domain layer business logic for creating conversations
/// 
/// This use case encapsulates the business logic for creating a new conversation
/// between a customer and a provider, following clean architecture principles.
class CreateConversationUseCase {
  final ChatRepository _chatRepository;

  CreateConversationUseCase(this._chatRepository);

  /// Execute the use case to create a new conversation
  /// 
  /// Returns the created conversation entity
  Future<ChatConversationEntity> call({
    required String customerId,
    required String customerName,
    required String customerProfileImage,
    required String providerId,
    required String providerName,
    required String providerProfileImage,
  }) async {
    return await _chatRepository.createConversation(
      customerId: customerId,
      customerName: customerName,
      customerProfileImage: customerProfileImage,
      providerId: providerId,
      providerName: providerName,
      providerProfileImage: providerProfileImage,
    );
  }
}