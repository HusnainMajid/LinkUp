import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../auth/models/profile_model.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/chat_repository.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatRepository = ChatRepository();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Profile? _otherParticipant;
  bool _isLoading = true;
  bool _isInputEmpty = true;
  Stream<List<Message>>? _messageStream;

  @override
  void initState() {
    super.initState();
    _loadConversationDetails();
    _messageController.addListener(_onTextChanged);
    _messageStream = _chatRepository.subscribeToMessages(widget.conversationId);
  }

  void _onTextChanged() {
    final isEmpty = _messageController.text.trim().isEmpty;
    if (isEmpty != _isInputEmpty) {
      setState(() {
        _isInputEmpty = isEmpty;
      });
    }
  }

  Future<void> _loadConversationDetails() async {
    try {
      final conversations = await _chatRepository.getUserConversations();
      final conversation = conversations.firstWhere((c) => c.id == widget.conversationId);
      
      if (mounted) {
        setState(() {
          _otherParticipant = _chatRepository.getOtherParticipant(conversation);
          _isLoading = false;
        });
        // Mark conversation as read
        _chatRepository.markAsRead(widget.conversationId);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    debugPrint('UI: Sending message to conversation: ${widget.conversationId}');

    _messageController.clear();
    try {
      await _chatRepository.sendMessage(
        conversationId: widget.conversationId,
        content: content,
      );
      _scrollToBottom();
    } on sb.PostgrestException catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to send message: ${e.message}')),
        );
      }
    } catch (e) {
      debugPrint('UI Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to send message. Please try again.')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming soon.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: _isLoading 
          ? const Text('Loading...') 
          : Row(
              children: [
                AppAvatar(
                  imageUrl: _otherParticipant?.avatarUrl,
                  initials: _otherParticipant?.fullName ?? 'U',
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _otherParticipant?.fullName ?? 'User',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _otherParticipant?.bio != null && _otherParticipant!.bio!.isNotEmpty
                          ? _otherParticipant!.bio!
                          : (_otherParticipant?.username != null ? '@${_otherParticipant!.username}' : 'LinkUp'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12, 
                          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined, size: 24), 
            onPressed: () => _showComingSoon('Video calling'),
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined, size: 22), 
            onPressed: () => _showComingSoon('Voice calling'),
          ),
          _buildOverflowMenu(),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Message Area
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _messageStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == sb.Supabase.instance.client.auth.currentUser?.id;
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),
          
          // Message Input UI
          _buildComposer(isDark),
        ],
      ),
    );
  }

  Widget _buildOverflowMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) {
        switch (value) {
          case 'search':
            _showComingSoon('Search in conversation');
            break;
          case 'profile':
            // Navigate to profile
            break;
          case 'clear':
            _confirmClearChat();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'search', child: Text('Search in conversation')),
        const PopupMenuItem(value: 'profile', child: Text('View profile')),
        const PopupMenuItem(value: 'media', child: Text('Media, links & files')),
        const PopupMenuItem(value: 'mute', child: Text('Mute notifications')),
        const PopupMenuItem(value: 'clear', child: Text('Clear chat')),
        const PopupMenuItem(value: 'delete', child: Text('Delete conversation')),
        const PopupMenuItem(value: 'block', child: Text('Block user')),
        const PopupMenuItem(value: 'report', child: Text('Report user')),
      ],
    );
  }

  Future<void> _confirmClearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear chat?'),
        content: const Text('This will remove your messages from this conversation.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _chatRepository.clearChat(widget.conversationId);
    }
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Convert UTC time from database to user's local time zone
    final localTime = message.createdAt.toLocal();
    final time = DateFormat('h:mm a').format(localTime);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe 
            ? AppColors.primary.withValues(alpha: isDark ? 0.9 : 1.0)
            : (isDark ? AppColors.cardDark : Colors.grey.shade200),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMe || isDark ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: (isMe || isDark ? Colors.white : Colors.black54).withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppAvatar(
            imageUrl: _otherParticipant?.avatarUrl,
            initials: _otherParticipant?.fullName ?? 'U',
            size: 80,
          ),
          const SizedBox(height: 24),
          Text(
            'Start your conversation',
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Send your first message to start the conversation with ${_otherParticipant?.fullName ?? 'your friend'}.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, 
                fontSize: 13,
                height: 1.5
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.elevatedDark : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.add_rounded, color: AppColors.primary, size: 24),
                onPressed: () => _showComingSoon('Attachments'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.elevatedDark : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(fontSize: 15),
                  maxLines: 5,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'Message...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _isInputEmpty 
                  ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200)
                  : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_upward_rounded, 
                  color: _isInputEmpty ? Colors.grey : Colors.white, 
                  size: 22
                ),
                onPressed: _isInputEmpty ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
