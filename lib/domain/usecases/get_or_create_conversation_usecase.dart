import '../entities/chat_conversation_entity.dart';
import '../repositories/chat_repository.dart';

/// Get or Create Conversation Use Case - Domain layer business logic for getting or creating conversations
/// 
/// This use case encapsulates the business logic for getting an existing conversation
/// or creating a new one between a customer and a provider, following clean architecture principles.
class GetOrCreateConversationUseCase {
  final ChatRepository _chatRepository;

  GetOrCreateConversationUseCase(this._chatRepository);

  /// Execute the use case to get or create a conversation
  /// 
  /// Returns the existing conversation if found, or creates a new one
  Future<ChatConversationEntity> call({
    required String customerId,
    required String customerName,
    required String customerProfileImage,
    required String providerId,
    required String providerName,
    required String providerProfileImage,
  }) async {
    return await _chatRepository.getOrCreateConversation(
      customerId: customerId,
      customerName: customerName,
      customerProfileImage: customerProfileImage,
      providerId: providerId,
      providerName: providerName,
      providerProfileImage: providerProfileImage,
    );
  }
}