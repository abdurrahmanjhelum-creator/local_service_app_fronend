import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chat_conversation_entity.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/chat_message_bubble.dart';
import '../../widgets/typing_indicator.dart';
import '../../widgets/chat_input_field.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final ChatConversationEntity? conversation;

  const ChatScreen({
    super.key,
    this.conversation,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.conversation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadMessages();
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final user = ref.read(authProvider).user;
    if (user != null && widget.conversation != null) {
      await ref.read(chatProvider.notifier).loadMessages(
        widget.conversation!.id,
        user.id,
      );
      if (mounted) {
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage(String content) async {
    final user = ref.read(authProvider).user;
    if (user == null || widget.conversation == null) return;

    await ref.read(chatProvider.notifier).sendMessage(
      content: content,
      senderId: user.id,
      senderName: user.name,
      senderProfileImage: user.profileImage,
    );

    if (mounted) {
      _scrollToBottom();
    }
  }

  void _onTypingChanged(bool isTyping) {
    final user = ref.read(authProvider).user;
    if (user == null || widget.conversation == null) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      ref.read(chatProvider.notifier).sendTypingIndicator(
        conversationId: widget.conversation!.id,
        userId: user.id,
        userName: user.name,
        isTyping: isTyping,
      );
    });
  }

  void _retrySendMessage(ChatMessageEntity message) {
    _sendMessage(message.content);
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final user = ref.watch(authProvider).user;
    final conversation = widget.conversation ?? chatState.currentConversation;

    if (conversation == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chat'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('No conversation selected'),
        ),
      );
    }

    final userRole = user?.isProvider == true ? 'provider' : 'customer';
    final otherParticipantName = conversation.getOtherParticipantName(
      user?.id ?? '',
      userRole,
    );
    final otherParticipantImage = conversation.getOtherParticipantProfileImage(
      user?.id ?? '',
      userRole,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: Colors.white24,
              backgroundImage: otherParticipantImage.isNotEmpty
                  ? NetworkImage(otherParticipantImage)
                  : null,
              child: otherParticipantImage.isEmpty
                  ? const Icon(Icons.person_rounded, size: 22, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    otherParticipantName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.statusOnline,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_rounded, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Call feature coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, size: 22),
            onPressed: () {
              _showMoreOptions(context, conversation);
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.appBackgroundGradient,
        ),
        child: Column(
          children: [
            Expanded(
              child: _buildMessagesList(chatState, user),
            ),
            TypingIndicator(
              typingUsers: chatState.typingUsers.keys.toList(),
              currentUserId: user?.id ?? '',
            ),
            ChatInputField(
              onSendMessage: _sendMessage,
              onTypingChanged: _onTypingChanged,
              isLoading: chatState.isSending,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(ChatState chatState, user) {
    if (chatState.isLoading && chatState.currentMessages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (chatState.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                chatState.errorMessage!,
                style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadMessages,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (chatState.currentMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 52,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 17,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Say hi to start the conversation!',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: chatState.currentMessages.length,
      itemBuilder: (context, index) {
        final message = chatState.currentMessages[index];
        return ChatMessageBubble(
          message: message,
          currentUserId: user?.id ?? '',
          onRetry: message.status == MessageStatus.failed
              ? () => _retrySendMessage(message)
              : null,
        );
      },
    );
  }

  void _showMoreOptions(BuildContext context, ChatConversationEntity conversation) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              title: const Text('Delete Conversation', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, conversation);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    ChatConversationEntity conversation,
  ) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text(
          'This will remove the conversation for both participants. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    final deleted = await ref.read(chatProvider.notifier).deleteConversation(
          conversation.id,
          user.id,
        );
    if (!context.mounted) return;

    Navigator.of(context, rootNavigator: true).pop();

    if (deleted) {
      Navigator.pop(context);
    } else {
      final error = ref.read(chatProvider).errorMessage ?? 'Unable to delete conversation';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}