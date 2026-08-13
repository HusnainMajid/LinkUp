import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/models/profile_model.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../../chat/data/repositories/friend_repository.dart';
import '../../../chat/data/models/friend_request_model.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final _chatRepository = ChatRepository();
  final _friendRepository = FriendRepository();
  final _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<Profile> _suggestedUsers = [];
  List<Profile> _searchResults = [];
  String _searchQuery = '';
  final Map<String, FriendStatus> _friendStatuses = {};

  @override
  void initState() {
    super.initState();
    _loadDiscoveryData();
  }

  Future<void> _loadDiscoveryData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _chatRepository.getSuggestedUsers(),
        _friendRepository.getIncomingRequests(),
        _friendRepository.getFriends(),
        _friendRepository.getOutgoingRequests(),
      ]);

      if (mounted) {
        setState(() {
          _suggestedUsers = results[0] as List<Profile>;
          
          final incoming = results[1] as List<FriendRequest>;
          final friends = results[2] as List<Profile>;
          final outgoing = results[3] as List<FriendRequest>;

          _friendStatuses.clear();
          for (var f in friends) { _friendStatuses[f.id] = FriendStatus.friends; }
          for (var r in incoming) { _friendStatuses[r.senderId] = FriendStatus.pendingReceived; }
          for (var r in outgoing) { _friendStatuses[r.receiverId] = FriendStatus.pendingSent; }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onSearch(String query) async {
    setState(() { _searchQuery = query; _isLoading = true; });
    if (query.isEmpty) { _searchResults = []; setState(() => _isLoading = false); return; }
    try {
      final results = await _chatRepository.searchUsers(query);
      if (mounted) setState(() { _searchResults = results; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover People', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: AppTextField(
              controller: _searchController,
              hint: 'Search by name or username...',
              prefixIcon: const Icon(Icons.search_rounded),
              onChanged: (v) => _onSearch(v.toLowerCase()),
            ),
          ),
          Expanded(
            child: _isLoading && (_searchResults.isEmpty && _suggestedUsers.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadDiscoveryData,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        if (_searchQuery.isEmpty) ...[
                          _buildSectionHeader('SUGGESTED FOR YOU'),
                          const SizedBox(height: 16),
                          ..._suggestedUsers.map((u) => _buildDiscoveryCard(u, isDark)),
                        ] else ...[
                          _buildSectionHeader('SEARCH RESULTS'),
                          const SizedBox(height: 16),
                          if (_searchResults.isEmpty && !_isLoading)
                             const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No users found.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))),
                          ..._searchResults.map((u) => _buildDiscoveryCard(u, isDark)),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 1.5));
  }

  Widget _buildDiscoveryCard(Profile user, bool isDark) {
    final status = _friendStatuses[user.id] ?? FriendStatus.none;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
      ),
      child: ListTile(
        onTap: () => context.push('/user/${user.id}'),
        contentPadding: const EdgeInsets.all(12),
        leading: AppAvatar(imageUrl: user.avatarUrl, initials: user.fullName, size: 54, showOnlineIndicator: user.isOnline),
        title: Text(user.fullName ?? 'User', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        subtitle: Text('@${user.username ?? 'username'}', style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
        trailing: _buildAction(user, status),
      ),
    );
  }

  Widget _buildAction(Profile user, FriendStatus status) {
    if (status == FriendStatus.friends) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: const Text('Friends', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w900)),
      );
    }
    if (status == FriendStatus.pendingSent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: const Text('Pending', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w900)),
      );
    }
    if (status == FriendStatus.pendingReceived) {
       return AppButton(text: 'Accept', type: AppButtonType.primary, height: 36, width: 80, onPressed: () async {
         await _friendRepository.acceptFriendRequest(user.id);
         _loadDiscoveryData();
       });
    }

    return AppButton(
      text: 'Add',
      type: AppButtonType.gradient,
      height: 36,
      width: 70,
      onPressed: () async {
        await _friendRepository.sendFriendRequest(user.id);
        setState(() => _friendStatuses[user.id] = FriendStatus.pendingSent);
      },
    );
  }
}

enum FriendStatus { none, pendingSent, pendingReceived, friends }
