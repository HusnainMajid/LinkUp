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
import '../../data/repositories/friend_repository.dart';

class ChatsListScreen extends StatefulWidget {
  final String? initialFilter;
  const ChatsListScreen({super.key, this.initialFilter});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  final _chatRepository = ChatRepository();
  final _friendRepository = FriendRepository();
  Stream<List<Conversation>>? _conversationsStream;
  String _searchQuery = '';
  late String _filter; // 'All', 'Chats', 'Groups'
  final _searchController = TextEditingController();
  List<Profile> _friends = [];

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter ?? 'All';
    _conversationsStream = _chatRepository.subscribeToConversations();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final friends = await _friendRepository.getFriends();
      if (mounted) setState(() => _friends = friends);
    } catch (_) {}
  }

  @override
  void didUpdateWidget(ChatsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilter != oldWidget.initialFilter && widget.initialFilter != null) {
      setState(() {
        _filter = widget.initialFilter!;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime date) {
    final localDate = date.toLocal();
    final now = DateTime.now();
    if (DateTime(localDate.year, localDate.month, localDate.day) == DateTime(now.year, now.month, now.day)) {
      return DateFormat('h:mm a').format(localDate);
    }
    return DateFormat('MMM d').format(localDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text('Inbox', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_rounded, color: AppColors.primary),
            onPressed: () => context.push('/new-chat'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: AppTextField(
              controller: _searchController,
              hint: 'Search friends or messages...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
          _buildFilters(),
          Expanded(
            child: StreamBuilder<List<Conversation>>(
              stream: _conversationsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allConversations = snapshot.data ?? [];
                
                final conversations = allConversations.where((c) {
                  final matchesSearch = _searchQuery.isEmpty || 
                      (c.members?.any((m) => (m.fullName?.toLowerCase().contains(_searchQuery) ?? false) || (m.username?.toLowerCase().contains(_searchQuery) ?? false)) ?? false) ||
                      (c.groupName?.toLowerCase().contains(_searchQuery) ?? false) ||
                      (c.latestMessage?.content.toLowerCase().contains(_searchQuery) ?? false);
                  
                  if (!matchesSearch) return false;
                  if (_filter == 'Chats' && c.type != 'direct') return false;
                  if (_filter == 'Groups' && c.type != 'group') return false;

                  return !(c.preferences?.isArchived ?? false) && !(c.preferences?.isDeleted ?? false);
                }).toList();

                final matchingFriends = _searchQuery.isEmpty || (_filter == 'Groups')
                    ? <Profile>[]
                    : _friends.where((f) {
                        final matchesQuery = (f.fullName?.toLowerCase().contains(_searchQuery) ?? false) || (f.username?.toLowerCase().contains(_searchQuery) ?? false);
                        if (!matchesQuery) return false;
                        return !conversations.any((c) => c.type == 'direct' && c.members?.any((m) => m.id == f.id) == true);
                      }).toList();

                if (conversations.isEmpty && matchingFriends.isEmpty) {
                  return _searchQuery.isNotEmpty 
                      ? const Center(child: Text('No results found.', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey))) 
                      : _buildEmptyState();
                }

                return _buildConversationsList(conversations, matchingFriends);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _buildFilterChip('All'),
            const SizedBox(width: 8),
            _buildFilterChip('Chats'),
            const SizedBox(width: 8),
            _buildFilterChip('Groups'),
            const SizedBox(width: 12),
            Container(width: 1, height: 20, color: Colors.grey.withValues(alpha: 0.15)),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => context.push('/create-group'),
              icon: const Icon(Icons.group_add_outlined, size: 20, color: AppColors.primary),
              tooltip: 'New Group',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) => setState(() => _filter = label),
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.grey.shade600,
        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
        fontSize: 13,
      ),
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? AppColors.primary.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.15)),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 32),
            const Text('Your inbox is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            const Text('Messages from your friends will appear here.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, height: 1.5, fontSize: 14)),
            const SizedBox(height: 32),
            AppButton(text: 'Start Chatting', width: 200, type: AppButtonType.primary, height: 48, onPressed: () => context.push('/new-chat')),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsList(List<Conversation> conversations, List<Profile> matchingFriends) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: conversations.length + (matchingFriends.isNotEmpty ? matchingFriends.length + 1 : 0) + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildArchivedTile();
        
        if (index <= conversations.length) {
          final conversation = conversations[index - 1];
          final otherUser = _chatRepository.getOtherParticipant(conversation);
          return _buildChatRow(conversation, otherUser);
        }

        if (matchingFriends.isNotEmpty) {
          final friendIndex = index - conversations.length - 1;
          if (friendIndex == 0) return _buildSectionHeader('FRIENDS');
          return _buildFriendRow(matchingFriends[friendIndex - 1]);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildArchivedTile() {
    return ListTile(
      leading: const SizedBox(width: 56, child: Icon(Icons.archive_outlined, color: AppColors.primary, size: 22)),
      title: const Text('Archived', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
      onTap: () => context.push('/archived-chats'),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 1.5)),
    );
  }

  Widget _buildChatRow(Conversation conversation, Profile? otherUser) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGroup = conversation.type == 'group';
    final isUnread = conversation.unreadCount > 0;



    return InkWell(
      onTap: () => context.push('/chat/${conversation.id}'),
      onLongPress: () => _showActionSheet(conversation),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            AppAvatar(
              imageUrl: isGroup ? conversation.groupAvatarUrl : otherUser?.avatarUrl,
              initials: isGroup ? (conversation.groupName ?? 'G') : (otherUser?.fullName ?? 'U'),
              size: 58,
              showOnlineIndicator: !isGroup && (otherUser?.isOnline ?? false),
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
                          isGroup ? (conversation.groupName ?? 'Group') : (otherUser?.fullName ?? 'User'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: isUnread ? FontWeight.w900 : FontWeight.w700, fontSize: 16),
                        ),
                      ),
                      if (conversation.latestMessage != null)
                        Text(
                          _formatTime(conversation.latestMessage!.createdAt),
                          style: TextStyle(color: isUnread ? AppColors.primary : Colors.grey.shade500, fontSize: 11, fontWeight: isUnread ? FontWeight.w900 : FontWeight.w500),
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
                            color: isUnread ? (isDark ? Colors.white : Colors.black) : Colors.grey.shade500,
                            fontSize: 14,
                            fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                          child: Text(conversation.unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
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

  Widget _buildFriendRow(Profile friend) {
    return InkWell(
      onTap: () async {
        final conversationId = await _chatRepository.getOrCreateDirectConversation(friend.id);
        if (context.mounted) context.push('/chat/$conversationId');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            AppAvatar(imageUrl: friend.avatarUrl, initials: friend.fullName ?? 'U', size: 58, showOnlineIndicator: friend.isOnline ?? false),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(friend.fullName ?? 'User', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text('@${friend.username ?? 'username'}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  String _getMessagePreview(Conversation conversation) {
    if (conversation.latestMessage == null) return 'No messages yet';
    final msg = conversation.latestMessage!;
    if (msg.deletedAt != null) return 'Message deleted';
    final isMe = msg.senderId == sb.Supabase.instance.client.auth.currentUser?.id;
    final prefix = isMe ? 'You: ' : (conversation.type == 'group' ? '${msg.senderName ?? 'User'}: ' : '');
    switch (msg.messageType) {
      case 'image': return '$prefix📷 Photo';
      case 'file': return '$prefix📎 File';
      default: return '$prefix${msg.content}';
    }
  }

  void _showActionSheet(Conversation conversation) {
    final isPinned = conversation.preferences?.isPinned ?? false;
    final isMuted = conversation.preferences?.isMuted ?? false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.only(top: 12, bottom: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            _buildActionItem(isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded, isPinned ? 'Unpin' : 'Pin', () {
              Navigator.pop(context);
              _chatRepository.togglePin(conversation.id, !isPinned);
            }),
            _buildActionItem(isMuted ? Icons.notifications_active_outlined : Icons.notifications_off_rounded, isMuted ? 'Unmute' : 'Mute', () {
              Navigator.pop(context);
              _chatRepository.toggleMute(conversation.id, !isMuted);
            }),
            _buildActionItem(Icons.archive_outlined, 'Archive', () {
              Navigator.pop(context);
              _chatRepository.toggleArchive(conversation.id, true);
            }),
            _buildActionItem(Icons.delete_outline_rounded, 'Delete', () => _confirmDelete(conversation.id), isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppColors.error : null, size: 22),
      title: Text(label, style: TextStyle(color: isDestructive ? AppColors.error : null, fontWeight: FontWeight.w700, fontSize: 15)),
      onTap: onTap,
    );
  }

  Future<void> _confirmDelete(String conversationId) async {
    Navigator.pop(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat?'),
        content: const Text('This will remove the conversation from your list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed == true) await _chatRepository.markAsDeleted(conversationId);
  }
}
