import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/models/profile_model.dart';
import '../../data/models/conversation_model.dart';
import '../../data/repositories/chat_repository.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  final _chatRepository = ChatRepository();
  Stream<List<Conversation>>? _conversationsStream;
  StreamSubscription? _triggerSubscription;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _conversationsStream = _chatRepository.subscribeToConversations();
    // Force refresh when ANY message is sent/received globally
    // We re-create the stream to force StreamBuilder to re-fetch
    _triggerSubscription = _chatRepository.globalChatUpdateTrigger.listen((_) {
      if (mounted) {
        setState(() {
          _conversationsStream = _chatRepository.subscribeToConversations();
        });
      }
    });
  }

  @override
  void dispose() {
    _triggerSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime date) {
    final localDate = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(localDate.year, localDate.month, localDate.day);

    if (messageDate == today) {
      return DateFormat('h:mm a').format(localDate);
    } else if (today.difference(messageDate).inDays == 1) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(localDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_rounded),
            onPressed: () => context.push('/new-chat'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: AppTextField(
              controller: _searchController,
              hint: 'Search chats or messages...',
              prefixIcon: const Icon(Icons.search_rounded),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Conversation>>(
              stream: _conversationsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  debugPrint('ChatsListScreen: Stream Error: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Couldn\'t load your conversations.'),
                        const SizedBox(height: 16),
                        AppButton(
                          text: 'Retry',
                          width: 120,
                          onPressed: () {
                            setState(() {
                              _conversationsStream = _chatRepository.subscribeToConversations();
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }

                final allConversations = snapshot.data ?? [];
                debugPrint('ChatsListScreen: Total conversations from stream: ${allConversations.length}');
                
                // Filter and Search logic
                final conversations = allConversations.where((c) {
                  final prefs = c.preferences;
                  final matchesSearch = _searchQuery.isEmpty || 
                      (c.members?.any((m) => m.fullName?.toLowerCase().contains(_searchQuery) ?? false) ?? false) ||
                      (c.latestMessage?.content.toLowerCase().contains(_searchQuery) ?? false);
                  
                  final isVisible = !(prefs?.isArchived ?? false) && !(prefs?.isDeleted ?? false) && matchesSearch;
                  return isVisible;
                }).toList();

                debugPrint('ChatsListScreen: Filtered conversations to display: ${conversations.length}');

                if (conversations.isEmpty) {
                  if (_searchQuery.isNotEmpty) {
                    return const Center(child: Text('No matching chats found.'));
                  }
                  return _buildEmptyState();
                }

                return _buildConversationsList(conversations);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/new-chat'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.message_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.forum_outlined, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 32),
            const Text(
              'No conversations yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Start a conversation with someone and connect on LinkUp.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 32),
            AppButton(
              text: 'Start New Chat',
              width: 200,
              type: AppButtonType.gradient,
              onPressed: () => context.push('/new-chat'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsList(List<Conversation> conversations) {
    return RefreshIndicator(
      onRefresh: () async => _chatRepository.getUserConversations(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: conversations.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildArchivedTile(context);
          }
          
          final conversation = conversations[index - 1];
          final otherUser = _chatRepository.getOtherParticipant(conversation);
          final prefs = conversation.preferences;
          final isUnread = prefs?.lastReadAt == null || 
              (conversation.latestMessage != null && 
               conversation.latestMessage!.createdAt.isAfter(prefs!.lastReadAt!));

          return _buildChatRow(context, conversation, otherUser, isUnread);
        },
      ),
    );
  }

  Widget _buildArchivedTile(BuildContext context) {
    return ListTile(
      leading: const SizedBox(
        width: 56,
        child: Icon(Icons.archive_outlined, color: AppColors.primary),
      ),
      title: const Text('Archived Chats', style: TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: () => context.push('/archived-chats'),
    );
  }

  Widget _buildChatRow(BuildContext context, Conversation conversation, Profile? otherUser, bool isUnread) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefs = conversation.preferences;

    return InkWell(
      onTap: () => context.push('/chat/${conversation.id}'),
      onLongPress: () => _showActionSheet(context, conversation),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            AppAvatar(
              imageUrl: otherUser?.avatarUrl,
              initials: otherUser?.fullName ?? 'U',
              size: 56,
              showOnlineIndicator: true, 
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          otherUser?.fullName ?? 'User',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (conversation.latestMessage != null)
                        Text(
                          _formatTime(conversation.latestMessage!.createdAt),
                          style: TextStyle(
                            color: isUnread ? AppColors.primary : Colors.grey.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _getMessagePreview(conversation),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isUnread ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
                            fontSize: 14,
                            fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (prefs?.isPinned ?? false)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.push_pin_rounded, size: 14, color: AppColors.primary),
                        ),
                      if (prefs?.isMuted ?? false)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.notifications_off_rounded, size: 14, color: Colors.grey),
                        ),
                      if (isUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMessagePreview(Conversation conversation) {
    if (conversation.latestMessage == null) return 'No messages yet';
    
    final msg = conversation.latestMessage!;
    if (msg.deletedAt != null) return 'This message was deleted';
    
    final prefix = msg.senderId == sb.Supabase.instance.client.auth.currentUser?.id ? 'You: ' : '';
    
    switch (msg.messageType) {
      case 'image': return '$prefix📷 Photo';
      case 'file': return '$prefix📎 ${msg.fileName ?? 'File'}';
      case 'audio': return '$prefix🎤 Voice message';
      default: return '$prefix${msg.content}';
    }
  }

  void _showActionSheet(BuildContext context, Conversation conversation) {
    final isPinned = conversation.preferences?.isPinned ?? false;
    final isMuted = conversation.preferences?.isMuted ?? false;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionItem(
              isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
              isPinned ? 'Unpin chat' : 'Pin chat',
              () {
                Navigator.pop(context);
                _chatRepository.togglePin(conversation.id, !isPinned);
              },
            ),
            _buildActionItem(
              isMuted ? Icons.notifications_active_outlined : Icons.notifications_off_rounded,
              isMuted ? 'Unmute notifications' : 'Mute notifications',
              () {
                Navigator.pop(context);
                _chatRepository.toggleMute(conversation.id, !isMuted);
              },
            ),
            _buildActionItem(
              Icons.archive_outlined,
              'Archive chat',
              () {
                Navigator.pop(context);
                _chatRepository.toggleArchive(conversation.id, true);
              },
            ),
            _buildActionItem(
              Icons.delete_outline_rounded,
              'Delete chat',
              () => _confirmDelete(context, conversation.id),
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppColors.error : null),
      title: Text(
        label,
        style: TextStyle(
          color: isDestructive ? AppColors.error : null,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> _confirmDelete(BuildContext context, String conversationId) async {
    Navigator.pop(context); // Close action sheet
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete conversation?'),
        content: const Text('This will remove this conversation from your chat list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _chatRepository.markAsDeleted(conversationId);
    }
  }
}
