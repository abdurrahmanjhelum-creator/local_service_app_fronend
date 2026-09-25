import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/chat_conversation_entity.dart';
import '../../domain/repositories/chat_repository.dart' show TypingIndicatorEvent;
import '../models/chat_message_model.dart';
import '../models/chat_conversation_model.dart';
import '../../services/socket_service.dart';
import '../../utils/api_constants.dart';
import '../../utils/token_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Chat Remote Data Source - Handles API calls and Socket events for chat
/// 
/// This data source is responsible for all remote data operations related to chat,
/// including HTTP API calls and real-time Socket.io events.
class ChatRemoteDataSource {
  final SocketService _socketService = SocketService();
  final http.Client _httpClient = http.Client();

  // Stream controllers for real-time updates
  final _messageController = StreamController<ChatMessageEntity>.broadcast();
  final _conversationController = StreamController<ChatConversationEntity>.broadcast();
  final _typingIndicatorController = StreamController<TypingIndicatorEvent>.broadcast();

  // Public streams
  Stream<ChatMessageEntity> get messageStream => _messageController.stream;
  Stream<ChatConversationEntity> get conversationStream => _conversationController.stream;
  Stream<TypingIndicatorEvent> get typingIndicatorStream => _typingIndicatorController.stream;

  ChatRemoteDataSource() {
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    // Listen for new messages
    _socketService.onChatMessage.listen((data) {
      try {
        final messageModel = ChatMessageModel.fromJson(data);
        _messageController.add(messageModel.toEntity());
      } catch (e) {
        debugPrint('Error parsing chat message: $e');
      }
    });

    // Listen for conversation updates
    _socketService.onConversationUpdated.listen((data) {
      try {
        final conversationModel = ChatConversationModel.fromJson(data);
        _conversationController.add(conversationModel.toEntity());
      } catch (e) {
        debugPrint('Error parsing conversation update: $e');
      }
    });

    // Listen for typing indicators
    _socketService.onTypingIndicator.listen((data) {
      try {
        final typingEvent = TypingIndicatorEvent(
          userId: data['userId']?.toString() ?? '',
          userName: data['userName'] ?? '',
          isTyping: data['isTyping'] ?? false,
          timestamp: DateTime.now(),
        );
        _typingIndicatorController.add(typingEvent);
      } catch (e) {
        debugPrint('Error parsing typing indicator: $e');
      }
    });

    // Listen for message status updates
    _socketService.onMessageStatusUpdated.listen((data) {
      try {
        final messageModel = ChatMessageModel.fromJson(data);
        _messageController.add(messageModel.toEntity());
      } catch (e) {
        debugPrint('Error parsing message status update: $e');
      }
    });
  }

  /// Send message via Socket
  Future<ChatMessageModel> sendMessageViaSocket(ChatMessageModel message) async {
    if (!_socketService.isConnected) {
      throw Exception('Socket not connected');
    }

    // Emit the message via socket for real-time delivery
    _socketService.sendChatMessage(message.toJson());
    
    return ChatMessageModel(
      id: message.id.isNotEmpty ? message.id : DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: message.conversationId,
      senderId: message.senderId,
      senderName: message.senderName,
      senderProfileImage: message.senderProfileImage,
      content: message.content,
      type: message.type,
      status: 'sent',
      createdAt: message.createdAt,
      updatedAt: DateTime.now(),
      isRead: message.isRead,
    );
  }

  /// Send message via HTTP API (fallback)
  Future<ChatMessageModel> sendMessageViaApi(ChatMessageModel message) async {
    final token = await TokenManager.getToken();
    final response = await _httpClient.post(
      Uri.parse('${ApiConstants.baseUrl}/chat/messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(message.toJson()),
    );

    if (response.statusCode == 201) {
      return ChatMessageModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to send message: ${response.statusCode}');
    }
  }

  /// Get conversations via HTTP API
  Future<List<ChatConversationModel>> getConversations(String userId) async {
    final token = await TokenManager.getToken();
    final response = await _httpClient
        .get(
          Uri.parse('${ApiConstants.baseUrl}/chat/conversations/$userId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException('Conversation request timed out', const Duration(seconds: 15));
          },
        );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ChatConversationModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get conversations: ${response.statusCode}');
    }
  }

  /// Get messages via HTTP API
  Future<List<ChatMessageModel>> getMessages(String conversationId) async {
    final token = await TokenManager.getToken();
    final response = await _httpClient
        .get(
          Uri.parse('${ApiConstants.baseUrl}/chat/messages/$conversationId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException('Messages request timed out', const Duration(seconds: 15));
          },
        );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ChatMessageModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get messages: ${response.statusCode}');
    }
  }

  /// Create conversation via HTTP API
  Future<ChatConversationModel> createConversation({
    required String customerId,
    required String customerName,
    required String customerProfileImage,
    required String providerId,
    required String providerName,
    required String providerProfileImage,
  }) async {
    final token = await TokenManager.getToken();
    final response = await _httpClient.post(
      Uri.parse('${ApiConstants.baseUrl}/chat/conversations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'customerId': customerId,
        'customerName': customerName,
        'customerProfileImage': customerProfileImage,
        'providerId': providerId,
        'providerName': providerName,
        'providerProfileImage': providerProfileImage,
      }),
    );

    if (response.statusCode == 201) {
      return ChatConversationModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create conversation: ${response.statusCode}');
    }
  }

  /// Get or create conversation via HTTP API
  Future<ChatConversationModel> getOrCreateConversation({
    required String customerId,
    required String customerName,
    required String customerProfileImage,
    required String providerId,
    required String providerName,
    required String providerProfileImage,
  }) async {
    final token = await TokenManager.getToken();
    final response = await _httpClient.post(
      Uri.parse('${ApiConstants.baseUrl}/chat/conversations/get-or-create'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'customerId': customerId,
        'customerName': customerName,
        'customerProfileImage': customerProfileImage,
        'providerId': providerId,
        'providerName': providerName,
        'providerProfileImage': providerProfileImage,
      }),
    );

    if (response.statusCode == 200) {
      return ChatConversationModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get or create conversation: ${response.statusCode}');
    }
  }

  /// Mark messages as read via HTTP API
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    final token = await TokenManager.getToken();
    final response = await _httpClient
        .put(
          Uri.parse('${ApiConstants.baseUrl}/chat/messages/$conversationId/read'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({'userId': userId}),
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw Exception('Failed to mark messages as read: ${response.statusCode}');
    }
  }

  Future<void> deleteConversation(String conversationId, String userId) async {
    final token = await TokenManager.getToken();
    final response = await _httpClient
        .delete(
          Uri.parse('${ApiConstants.baseUrl}/chat/conversations/$conversationId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({'userId': userId}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      String message = 'Failed to delete conversation (${response.statusCode})';
      try {
        final data = json.decode(response.body);
        if (data is Map && data['message'] is String) {
          message = data['message'] as String;
        }
      } catch (_) {
      }
      throw Exception(message);
    }
  }

  /// Send typing indicator via Socket
  void sendTypingIndicator({
    required String conversationId,
    required String userId,
    required String userName,
    required bool isTyping,
  }) {
    _socketService.sendTypingIndicator(
      conversationId: conversationId,
      userId: userId,
      userName: userName,
      isTyping: isTyping,
    );
  }

  /// Join conversation room via Socket
  void joinConversationRoom(String conversationId) {
    _socketService.joinConversationRoom(conversationId);
  }

  /// Leave conversation room via Socket
  void leaveConversationRoom(String conversationId) {
    _socketService.leaveConversationRoom(conversationId);
  }

  void dispose() {
    _messageController.close();
    _conversationController.close();
    _typingIndicatorController.close();
  }
}