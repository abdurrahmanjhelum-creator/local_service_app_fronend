import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../utils/api_constants.dart';
import '../utils/token_manager.dart';

/// SocketService (Singleton)
/// Handles real-time communication with Socket.io backend server
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  socket_io.Socket? _socket;
  bool _isConnected = false;
  String? _pendingRoomJoin;
  String? _currentUserId;
  Completer<void>? _connectionCompleter;

  // Stream controllers for broadcasting real-time events across UI
  final _bookingCreatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _bookingStatusUpdatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _notificationReceivedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();
  
  // Chat stream controllers
  final _chatMessageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _conversationUpdatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _typingIndicatorController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _messageStatusUpdatedController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Public streams for UI subscription
  Stream<Map<String, dynamic>> get onBookingCreated =>
      _bookingCreatedController.stream;
  Stream<Map<String, dynamic>> get onBookingStatusUpdated =>
      _bookingStatusUpdatedController.stream;
  Stream<Map<String, dynamic>> get onNotificationReceived =>
      _notificationReceivedController.stream;
  Stream<bool> get onConnectionStatusChanged =>
      _connectionStatusController.stream;
  
  // Chat public streams
  Stream<Map<String, dynamic>> get onChatMessage =>
      _chatMessageController.stream;
  Stream<Map<String, dynamic>> get onConversationUpdated =>
      _conversationUpdatedController.stream;
  Stream<Map<String, dynamic>> get onTypingIndicator =>
      _typingIndicatorController.stream;
  Stream<Map<String, dynamic>> get onMessageStatusUpdated =>
      _messageStatusUpdatedController.stream;

  bool get isConnected => _isConnected;

  /// Connect to Socket.io server
  Future<void> connect() async {
    // Vercel serverless platform does not host persistent WebSocket servers.
    if (kIsWeb && ApiConstants.useProduction) {
      debugPrint('ℹ️ Web environment on Vercel: WebSockets not supported by serverless. Using clean HTTP REST API.');
      _isConnected = false;
      _connectionStatusController.add(false);
      return;
    }

    if (_socket != null && _socket!.connected) {
      debugPrint('✅ Socket already connected');
      return;
    }

    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }

    _connectionCompleter = Completer<void>();

    try {
      final token = await TokenManager.getToken();

      debugPrint('🔑 Token: ${token != null ? 'Found' : 'Not found'}');
      debugPrint('🌐 Connecting to: ${ApiConstants.socketBaseUrl}');

      _socket = socket_io.io(
        ApiConstants.socketBaseUrl,
        socket_io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setReconnectionAttempts(3)
            .setAuth({'token': token})
            .build(),
      );

      _setupEventHandlers();
      _socket!.connect();
      debugPrint('🔄 Connecting to socket server...');

      await _connectionCompleter!.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('⏱️ Socket connection timeout (Falling back to HTTP API)');
          _isConnected = false;
          _connectionStatusController.add(false);
          if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
            _connectionCompleter!.complete();
          }
        },
      );
    } catch (e) {
      debugPrint('⚠️ Socket connection info: $e (HTTP fallback active)');
      _isConnected = false;
      _connectionStatusController.add(false);
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.complete();
      }
    }
  }

  /// Setup Socket event handlers
  void _setupEventHandlers() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      debugPrint('✅ Socket connected successfully');
      _isConnected = true;
      _connectionStatusController.add(true);
      
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.complete();
      }

      final roomToJoin = _pendingRoomJoin ?? _currentUserId;
      if (roomToJoin != null && roomToJoin.isNotEmpty) {
        debugPrint('📌 Joining room on connect: $roomToJoin');
        _socket!.emit('join_room', roomToJoin);
        _pendingRoomJoin = null;
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint('❌ Socket disconnected');
      _isConnected = false;
      _connectionStatusController.add(false);
    });

    _socket!.onConnectError((error) {
      debugPrint('⚠️ Socket connect error: $error (HTTP fallback active)');
      _isConnected = false;
      _connectionStatusController.add(false);
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.complete();
      }
    });

    _socket!.on('booking_created', (data) {
      debugPrint('📬 New booking received: $data');
      final mapData = _parseMap(data);
      if (mapData != null) {
        _bookingCreatedController.add(mapData);
      }
    });

    _socket!.on('booking_status_updated', (data) {
      debugPrint('📬 Booking status updated: $data');
      final mapData = _parseMap(data);
      if (mapData != null) {
        _bookingStatusUpdatedController.add(mapData);
      }
    });

    _socket!.on('notification_received', (data) {
      debugPrint('🔔 Notification received: $data');
      final mapData = _parseMap(data);
      if (mapData != null) {
        _notificationReceivedController.add(mapData);
      }
    });

    _socket!.on('chat_message', (data) {
      debugPrint('💬 New chat message: $data');
      final mapData = _parseMap(data);
      if (mapData != null) {
        _chatMessageController.add(mapData);
      }
    });

    _socket!.on('conversation_updated', (data) {
      debugPrint('🔄 Conversation updated: $data');
      final mapData = _parseMap(data);
      if (mapData != null) {
        _conversationUpdatedController.add(mapData);
      }
    });

    _socket!.on('typing_indicator', (data) {
      debugPrint('⌨️ Typing indicator: $data');
      final mapData = _parseMap(data);
      if (mapData != null) {
        _typingIndicatorController.add(mapData);
      }
    });

    _socket!.on('message_status_updated', (data) {
      debugPrint('📨 Message status updated: $data');
      final mapData = _parseMap(data);
      if (mapData != null) {
        _messageStatusUpdatedController.add(mapData);
      }
    });

    _socket!.on('message_sent', (data) {
      debugPrint('✅ Message sent confirmation: $data');
      final mapData = _parseMap(data);
      if (mapData != null) {
        _messageStatusUpdatedController.add(mapData);
      }
    });
  }

  Map<String, dynamic>? _parseMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  /// Join private user room for real-time notifications
  void joinRoom(String userId) {
    if (userId.isEmpty) return;
    _currentUserId = userId;

    if (_socket == null) {
      debugPrint('⚠️ Socket not initialized, saving room join for later: $userId');
      _pendingRoomJoin = userId;
      return;
    }

    if (!_socket!.connected) {
      debugPrint('⚠️ Socket not connected yet, saving room join: $userId');
      _pendingRoomJoin = userId;
      return;
    }

    _socket!.emit('join_room', userId);
    debugPrint('📌 Joined room for user: $userId');
  }

  /// Join a conversation room for real-time messaging
  void joinConversationRoom(String conversationId) {
    if (_socket == null || !_socket!.connected) {
      debugPrint('⚠️ Socket not connected, cannot join conversation room');
      return;
    }
    
    _socket!.emit('join_conversation', conversationId);
    debugPrint('💬 Joined conversation room: $conversationId');
  }

  /// Leave a conversation room
  void leaveConversationRoom(String conversationId) {
    if (_socket == null || !_socket!.connected) {
      debugPrint('⚠️ Socket not connected, cannot leave conversation room');
      return;
    }
    
    _socket!.emit('leave_conversation', conversationId);
    debugPrint('💬 Left conversation room: $conversationId');
  }

  /// Send a chat message
  void sendChatMessage(Map<String, dynamic> messageData) {
    if (_socket == null || !_socket!.connected) {
      debugPrint('⚠️ Socket not connected, cannot send message');
      return;
    }
    
    _socket!.emit('send_message', messageData);
    debugPrint('💬 Sending message: ${messageData['content']}');
  }

  /// Send typing indicator
  void sendTypingIndicator({
    required String conversationId,
    required String userId,
    required String userName,
    required bool isTyping,
  }) {
    if (_socket == null || !_socket!.connected) {
      debugPrint('⚠️ Socket not connected, cannot send typing indicator');
      return;
    }
    
    _socket!.emit('typing_indicator', {
      'conversationId': conversationId,
      'userId': userId,
      'userName': userName,
      'isTyping': isTyping,
    });
    debugPrint('⌨️ Typing indicator: $isTyping for user $userName');
  }

  void emit(String event, dynamic data) {
    if (_socket == null || !_socket!.connected) {
      debugPrint('⚠️ Socket not connected, cannot emit event: $event');
      return;
    }
    
    _socket!.emit(event, data);
  }

  void on(String event, Function(dynamic) callback) {
    if (_socket == null) {
      debugPrint('⚠️ Socket not initialized, cannot listen to event: $event');
      return;
    }
    
    _socket!.on(event, callback);
  }

  /// Disconnect socket connection
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
      _connectionStatusController.add(false);
      debugPrint('🔌 Socket disconnected manually');
    }
  }

  /// Cleanup resources
  void dispose() {
    _bookingCreatedController.close();
    _bookingStatusUpdatedController.close();
    _notificationReceivedController.close();
    _connectionStatusController.close();
    _chatMessageController.close();
    _conversationUpdatedController.close();
    _typingIndicatorController.close();
    _messageStatusUpdatedController.close();
  }
}
