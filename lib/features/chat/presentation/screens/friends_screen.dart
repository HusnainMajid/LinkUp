import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/models/profile_model.dart';
import '../../data/repositories/friend_repository.dart';
import '../../data/repositories/chat_repository.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _friendRepository = FriendRepository();
  final _chatRepository = ChatRepository();
  final _searchController = TextEditingController();
  List<Profile> _allFriends = [];
  List<Profile> _filteredFriends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final friends = await _friendRepository.getFriends();
      if (mounted) {
        setState(() {
          _allFriends = friends;
          _filteredFriends = friends;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch(String query) {
    setState(() {
      _filteredFriends = _allFriends
          .where((f) =>
              (f.fullName?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
              (f.username?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
    });
  }

  Future<void> _startChat(String userId) async {
    try {
      final conversationId = await _chatRepository.getOrCreateDirectConversation(userId);
      if (mounted) {
        context.push('/chat/$conversationId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () => context.push('/new-chat'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppTextField(
              controller: _searchController,
              hint: 'Search friends...',
              prefixIcon: const Icon(Icons.search_rounded),
              onChanged: _onSearch,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFriends.isEmpty
                    ? _buildEmptyState(isDark)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredFriends.length,
                        itemBuilder: (context, index) {
                          final friend = _filteredFriends[index];
                          return _buildFriendItem(friend);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendItem(Profile friend) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: () => context.push('/user/${friend.id}'),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: AppAvatar(
            imageUrl: friend.avatarUrl,
            initials: friend.fullName ?? 'U',
            size: 48,
            showOnlineIndicator: true,
          ),
          title: Text(
            friend.fullName ?? 'User',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '@${friend.username ?? 'username'}',
            style: const TextStyle(color: AppColors.primary, fontSize: 12),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
            onPressed: () => _startChat(friend.id),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 64, color: AppColors.primary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('No friends found', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Find people to connect with.', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}
