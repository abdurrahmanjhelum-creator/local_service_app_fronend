import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/chat_conversation_entity.dart';
import '../domain/entities/chat_message_entity.dart';
import '../domain/repositories/chat_repository.dart';
import '../domain/usecases/get_conversations_usecase.dart';
import '../domain/usecases/get_messages_usecase.dart';
import '../domain/usecases/send_message_usecase.dart';
import '../domain/usecases/create_conversation_usecase.dart';
import '../domain/usecases/get_or_create_conversation_usecase.dart';
import '../domain/usecases/send_typing_indicator_usecase.dart';
import '../domain/usecases/mark_messages_read_usecase.dart';
import '../data/repositories/chat_repository_impl.dart';
import '../data/datasources/chat_remote_datasource.dart';
import '../utils/api_constants.dart';

/// Chat State - Represents the state of the chat system
class ChatState {
  final List<ChatConversationEntity> conversations;
  final List<ChatMessageEntity> currentMessages;
  final ChatConversationEntity? currentConversation;
  final bool isLoading;
  final bool isSending;
  final bool isDeleting;
  final String? errorMessage;
  final Map<String, bool> typingUsers;
  final bool hasUnreadMessages;

  ChatState({
    this.conversations = const [],
    this.currentMessages = const [],
    this.currentConversation,
    this.isLoading = false,
    this.isSending = false,
    this.isDeleting = false,
    this.errorMessage,
    this.typingUsers = const {},
    this.hasUnreadMessages = false,
  });

  ChatState copyWith({
    List<ChatConversationEntity>? conversations,
    List<ChatMessageEntity>? currentMessages,
    ChatConversationEntity? currentConversation,
    bool? isLoading,
    bool? isSending,
    bool? isDeleting,
    String? errorMessage,
    Map<String, bool>? typingUsers,
    bool? hasUnreadMessages,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      currentMessages: currentMessages ?? this.currentMessages,
      currentConversation: currentConversation ?? this.currentConversation,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      isDeleting: isDeleting ?? this.isDeleting,
      errorMessage: errorMessage,
      typingUsers: typingUsers ?? this.typingUsers,
      hasUnreadMessages: hasUnreadMessages ?? this.hasUnreadMessages,
    );
  }
}

/// Chat Notifier - Manages chat state using Riverpod
class ChatNotifier extends Notifier<ChatState> {
  late final ChatRepository _chatRepository;
  late final GetConversationsUseCase _getConversationsUseCase;
  late final GetMessagesUseCase _getMessagesUseCase;
  late final SendMessageUseCase _sendMessageUseCase;
  late final CreateConversationUseCase _createConversationUseCase;
  late final GetOrCreateConversationUseCase _getOrCreateConversationUseCase;
  late final SendTypingIndicatorUseCase _sendTypingIndicatorUseCase;
  late final MarkMessagesReadUseCase _markMessagesReadUseCase;
  
  StreamSubscription? _messageSubscription;
  StreamSubscription? _conversationSubscription;
  StreamSubscription? _typingSubscription;
  Timer? _conversationPollTimer;
  Timer? _messagePollTimer;
  bool _isPollingConversations = false;
  bool _isPollingMessages = false;
  String? _activeConversationId;

  @override
  ChatState build() {
    _chatRepository = ref.watch(chatRepositoryProvider);
    _getConversationsUseCase = GetConversationsUseCase(_chatRepository);
    _getMessagesUseCase = GetMessagesUseCase(_chatRepository);
    _sendMessageUseCase = SendMessageUseCase(_chatRepository);
    _createConversationUseCase = CreateConversationUseCase(_chatRepository);
    _getOrCreateConversationUseCase = GetOrCreateConversationUseCase(_chatRepository);
    _sendTypingIndicatorUseCase = SendTypingIndicatorUseCase(_chatRepository);
    _markMessagesReadUseCase = MarkMessagesReadUseCase(_chatRepository);
    
    // Cleanup subscriptions when provider is disposed
    ref.onDispose(() {
      _messageSubscription?.cancel();
      _conversationSubscription?.cancel();
      _typingSubscription?.cancel();
      _conversationPollTimer?.cancel();
      _messagePollTimer?.cancel();
    });
    
    return ChatState();
  }

  /// Load all conversations for a user
  Future<void> loadConversations(String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final conversations = await _getConversationsUseCase(userId);
      final hasUnread = conversations.any((conv) => conv.hasUnreadMessages);

      state = state.copyWith(
        conversations: conversations,
        hasUnreadMessages: hasUnread,
      );

      // Listen for conversation updates
      _conversationSubscription?.cancel();
      _conversationSubscription = _chatRepository
          .getConversationUpdates(userId)
          .listen((updatedConversation) {
        _updateConversationInList(updatedConversation);
      });
      _startConversationPolling(userId);
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        conversations: [], // Ensure conversations is empty on error
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Load messages for a specific conversation
  Future<void> loadMessages(String conversationId, String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final messages = await _getMessagesUseCase(conversationId);
      final conversation = state.conversations.firstWhere(
        (conv) => conv.id == conversationId,
        orElse: () => state.currentConversation ?? ChatConversationEntity(
          id: conversationId,
          customerId: '',
          customerName: 'User',
          customerProfileImage: '',
          providerId: '',
          providerName: 'User',
          providerProfileImage: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      state = state.copyWith(
        currentMessages: messages,
        currentConversation: conversation,
      );

      // Mark messages as read
      try {
        await _markMessagesReadUseCase(
          conversationId: conversationId,
          userId: userId,
        ).timeout(const Duration(seconds: 5));
      } catch (_) {
      }

      // Listen for new messages
      _messageSubscription?.cancel();
      _messageSubscription = _chatRepository
          .getMessageUpdates(conversationId)
          .listen((newMessage) {
        _addMessageToCurrent(newMessage);
      });
      _startMessagePolling(conversationId);

      // Listen for typing indicators
      _typingSubscription?.cancel();
      _typingSubscription = _chatRepository
          .getTypingIndicators(conversationId)
          .listen((typingEvent) {
        _updateTypingIndicator(typingEvent);
      });
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void _startConversationPolling(String userId) {
    if (!kIsWeb || !ApiConstants.useProduction) return;

    _conversationPollTimer?.cancel();
    _conversationPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _pollConversations(userId);
    });
  }

  Future<void> _pollConversations(String userId) async {
    if (_isPollingConversations) return;
    _isPollingConversations = true;

    try {
      final conversations = await _getConversationsUseCase(userId);
      final hasUnread = conversations.any((conv) => conv.hasUnreadMessages);
      state = state.copyWith(
        conversations: conversations,
        hasUnreadMessages: hasUnread,
      );
    } catch (_) {
    } finally {
      _isPollingConversations = false;
    }
  }

  void _startMessagePolling(String conversationId) {
    if (!kIsWeb || !ApiConstants.useProduction) return;

    _activeConversationId = conversationId;
    _messagePollTimer?.cancel();
    _messagePollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollMessages(conversationId);
    });
  }

  Future<void> _pollMessages(String conversationId) async {
    if (_isPollingMessages || _activeConversationId != conversationId) return;
    _isPollingMessages = true;

    try {
      final messages = await _getMessagesUseCase(conversationId);
      if (_activeConversationId == conversationId) {
        state = state.copyWith(currentMessages: messages);
      }
    } catch (_) {
    } finally {
      _isPollingMessages = false;
    }
  }

  /// Send a message
  Future<void> sendMessage({
    required String content,
    required String senderId,
    required String senderName,
    required String senderProfileImage,
    MessageType type = MessageType.text,
  }) async {
    if (state.currentConversation == null) return;
    
    state = state.copyWith(isSending: true, errorMessage: null);
    
    try {
      final message = await _sendMessageUseCase(
        conversationId: state.currentConversation!.id,
        senderId: senderId,
        senderName: senderName,
        senderProfileImage: senderProfileImage,
        content: content,
        type: type,
      );
      
      _addMessageToCurrent(message);

      // Update current conversation last message and list
      if (state.currentConversation != null) {
        final updatedConv = state.currentConversation!.copyWith(
          lastMessage: content,
          lastMessageTime: message.createdAt,
          updatedAt: DateTime.now(),
        );
        state = state.copyWith(currentConversation: updatedConv);
        _updateConversationInList(updatedConv);
      }

      state = state.copyWith(isSending: false);
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> deleteConversation(String conversationId, String userId) async {
    if (state.isDeleting) return false;

    state = state.copyWith(isDeleting: true, errorMessage: null);
    try {
      await _chatRepository.deleteConversation(conversationId, userId);
      _messageSubscription?.cancel();
      _typingSubscription?.cancel();
      _messagePollTimer?.cancel();
      _activeConversationId = null;

      state = state.copyWith(
        conversations:
            state.conversations.where((conversation) => conversation.id != conversationId).toList(),
        currentMessages: [],
        currentConversation: null,
        isDeleting: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isDeleting: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Create a new conversation
  Future<void> createConversation({
    required String customerId,
    required String customerName,
    required String customerProfileImage,
    required String providerId,
    required String providerName,
    required String providerProfileImage,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final conversation = await _createConversationUseCase(
        customerId: customerId,
        customerName: customerName,
        customerProfileImage: customerProfileImage,
        providerId: providerId,
        providerName: providerName,
        providerProfileImage: providerProfileImage,
      );
      
      final updatedConversations = [...state.conversations, conversation];
      state = state.copyWith(
        conversations: updatedConversations,
        currentConversation: conversation,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Get or create a conversation (useful for starting chat from profile)
  Future<void> getOrCreateConversation({
    required String customerId,
    required String customerName,
    required String customerProfileImage,
    required String providerId,
    required String providerName,
    required String providerProfileImage,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final conversation = await _getOrCreateConversationUseCase(
        customerId: customerId,
        customerName: customerName,
        customerProfileImage: customerProfileImage,
        providerId: providerId,
        providerName: providerName,
        providerProfileImage: providerProfileImage,
      );
      
      // Check if conversation already exists in list
      final existingIndex = state.conversations.indexWhere(
        (conv) => conv.id == conversation.id,
      );
      
      List<ChatConversationEntity> updatedConversations;
      if (existingIndex >= 0) {
        updatedConversations = [...state.conversations];
        updatedConversations[existingIndex] = conversation;
      } else {
        updatedConversations = [...state.conversations, conversation];
      }
      
      state = state.copyWith(
        conversations: updatedConversations,
        currentConversation: conversation,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Send typing indicator
  Future<void> sendTypingIndicator({
    required String conversationId,
    required String userId,
    required String userName,
    required bool isTyping,
  }) async {
    await _sendTypingIndicatorUseCase(
      conversationId: conversationId,
      userId: userId,
      userName: userName,
      isTyping: isTyping,
    );
  }

  /// Clear current conversation
  void clearCurrentConversation() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _messagePollTimer?.cancel();
    _activeConversationId = null;
    state = state.copyWith(
      currentMessages: [],
      currentConversation: null,
      typingUsers: {},
    );
  }

  /// Add message to current conversation (with deduplication and status update)
  void _addMessageToCurrent(ChatMessageEntity message) {
    if (state.currentConversation?.id != message.conversationId) return;

    // Check if message already exists by ID or content + sender proximity
    final existingIndex = state.currentMessages.indexWhere((m) =>
        (m.id.isNotEmpty && message.id.isNotEmpty && m.id == message.id) ||
        (m.senderId == message.senderId &&
            m.content == message.content &&
            m.createdAt.difference(message.createdAt).abs().inSeconds < 4));

    if (existingIndex >= 0) {
      final updatedMessages = [...state.currentMessages];
      updatedMessages[existingIndex] = message;
      state = state.copyWith(currentMessages: updatedMessages);
      return;
    }

    final updatedMessages = [...state.currentMessages, message];
    state = state.copyWith(currentMessages: updatedMessages);
  }

  /// Update conversation in the list
  void _updateConversationInList(ChatConversationEntity updatedConversation) {
    if (!updatedConversation.isActive) {
      state = state.copyWith(
        conversations: state.conversations
            .where((conversation) => conversation.id != updatedConversation.id)
            .toList(),
      );
      return;
    }

    final updatedConversations = state.conversations.map((conv) {
      return conv.id == updatedConversation.id ? updatedConversation : conv;
    }).toList();
    
    final hasUnread = updatedConversations.any((conv) => conv.hasUnreadMessages);
    
    state = state.copyWith(
      conversations: updatedConversations,
      hasUnreadMessages: hasUnread,
    );
  }

  /// Update typing indicator
  void _updateTypingIndicator(TypingIndicatorEvent event) {
    final updatedTypingUsers = Map<String, bool>.from(state.typingUsers);
    updatedTypingUsers[event.userId] = event.isTyping;
    
    // Remove typing indicator after 3 seconds of no updates
    if (event.isTyping) {
      Future.delayed(const Duration(seconds: 3), () {
        if (ref.mounted) {
          final currentTypingUsers = Map<String, bool>.from(state.typingUsers);
          currentTypingUsers[event.userId] = false;
          state = state.copyWith(typingUsers: currentTypingUsers);
        }
      });
    }
    
    state = state.copyWith(typingUsers: updatedTypingUsers);
  }
}

/// Provider for Chat Remote Data Source
final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSource();
});

/// Provider for Chat Repository
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final remoteDataSource = ref.watch(chatRemoteDataSourceProvider);
  return ChatRepositoryImpl(remoteDataSource);
});

/// Provider for Chat Notifier
final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);