import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/models/profile_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/friend_repository.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _friendRepository = FriendRepository();
  final _chatRepository = ChatRepository();
  bool _isLoading = true;
  List<Profile> _friends = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);
    try {
      final friends = await _friendRepository.getFriends();
      if (mounted) setState(() { _friends = friends; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _friends.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadFriends,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _friends.length,
                    itemBuilder: (context, index) => _buildFriendRow(_friends[index]),
                  ),
                ),
    );
  }

  Widget _buildFriendRow(Profile friend) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: AppAvatar(imageUrl: friend.avatarUrl, initials: friend.fullName, size: 54, showOnlineIndicator: friend.isOnline ?? false),
      title: Text(friend.fullName ?? 'User', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      subtitle: Text('@${friend.username ?? 'username'}', style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionIcon(Icons.chat_bubble_outline_rounded, () async {
            final convId = await _chatRepository.getOrCreateDirectConversation(friend.id);
            if (mounted) context.push('/chat/$convId');
          }),
          const SizedBox(width: 8),
          _buildActionIcon(Icons.person_outline_rounded, () => context.push('/user/${friend.id}')),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: const Icon(Icons.people_outline_rounded, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          const Text('No friends yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          const Text('Discover and add people to start chatting.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 32),
          AppButton(text: 'Discover People', width: 200, type: AppButtonType.primary, height: 48, onPressed: () => context.push('/discovery')),
        ],
      ),
    );
  }
}
