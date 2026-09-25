import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/chat_conversation_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';
import '../models/chat_message_model.dart';

/// Chat Repository Implementation - Data layer implementation of chat repository
/// 
/// This class implements the ChatRepository interface and handles the coordination
/// between data sources and domain entities, following clean architecture principles.
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepositoryImpl(this._remoteDataSource);

  @override
  Future<ChatMessageEntity> sendMessage(ChatMessageEntity message) async {
    final messageModel = ChatMessageModel.fromEntity(message);
    
    try {
      // Send via HTTP API first to guarantee persistence in MongoDB and socket broadcast
      final sentMessage = await _remoteDataSource.sendMessageViaApi(messageModel);
      return sentMessage.toEntity();
    } catch (e) {
      // Fallback to Socket if HTTP fails
      final sentMessage = await _remoteDataSource.sendMessageViaSocket(messageModel);
      return sentMessage.toEntity();
    }
  }

  @override
  Future<List<ChatConversationEntity>> getConversations(String userId) async {
    final conversationModels = await _remoteDataSource.getConversations(userId);
    return conversationModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<ChatMessageEntity>> getMessages(String conversationId) async {
    final messageModels = await _remoteDataSource.getMessages(conversationId);
    return messageModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<ChatConversationEntity> createConversation({
    required String customerId,
    required String customerName,
    required String customerProfileImage,
    required String providerId,
    required String providerName,
    required String providerProfileImage,
  }) async {
    final conversationModel = await _remoteDataSource.createConversation(
      customerId: customerId,
      customerName: customerName,
      customerProfileImage: customerProfileImage,
      providerId: providerId,
      providerName: providerName,
      providerProfileImage: providerProfileImage,
    );
    return conversationModel.toEntity();
  }

  @override
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    await _remoteDataSource.markMessagesAsRead(conversationId, userId);
  }

  @override
  Future<void> deleteConversation(String conversationId, String userId) async {
    await _remoteDataSource.deleteConversation(conversationId, userId);
  }

  @override
  Future<ChatConversationEntity> getOrCreateConversation({
    required String customerId,
    required String customerName,
    required String customerProfileImage,
    required String providerId,
    required String providerName,
    required String providerProfileImage,
  }) async {
    final conversationModel = await _remoteDataSource.getOrCreateConversation(
      customerId: customerId,
      customerName: customerName,
      customerProfileImage: customerProfileImage,
      providerId: providerId,
      providerName: providerName,
      providerProfileImage: providerProfileImage,
    );
    return conversationModel.toEntity();
  }

  @override
  Stream<ChatMessageEntity> getMessageUpdates(String conversationId) {
    // Join the conversation room to receive real-time updates
    _remoteDataSource.joinConversationRoom(conversationId);
    return _remoteDataSource.messageStream;
  }

  @override
  Stream<ChatConversationEntity> getConversationUpdates(String userId) {
    return _remoteDataSource.conversationStream;
  }

  @override
  Future<void> sendTypingIndicator({
    required String conversationId,
    required String userId,
    required String userName,
    required bool isTyping,
  }) async {
    _remoteDataSource.sendTypingIndicator(
      conversationId: conversationId,
      userId: userId,
      userName: userName,
      isTyping: isTyping,
    );
  }

  @override
  Stream<TypingIndicatorEvent> getTypingIndicators(String conversationId) {
    return _remoteDataSource.typingIndicatorStream;
  }
}