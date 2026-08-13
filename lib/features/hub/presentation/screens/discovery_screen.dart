import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
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
  
  Timer? _debounce;
  bool _isLoading = true;
  bool _isSearching = false;
  
  List<Profile> _suggestedUsers = [];
  List<Profile> _recentlyActiveUsers = [];
  List<Profile> _onlineUsers = [];
  List<Profile> _searchResults = [];
  
  final Map<String, FriendStatus> _friendStatuses = {};

  @override
  void initState() {
    super.initState();
    _loadDiscoveryData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDiscoveryData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _chatRepository.getSuggestedUsers(),
        _chatRepository.getRecentlyActiveUsers(),
        _chatRepository.getOnlineUsers(),
      ]);

      _suggestedUsers = results[0] as List<Profile>;
      _recentlyActiveUsers = results[1] as List<Profile>;
      _onlineUsers = results[2] as List<Profile>;

      // Prefetch some statuses
      final allUsers = [..._suggestedUsers, ..._recentlyActiveUsers, ..._onlineUsers];
      for (var user in allUsers) {
        if (!_friendStatuses.containsKey(user.id)) {
           _friendRepository.getFriendStatus(user.id).then((status) {
             if (mounted) setState(() => _friendStatuses[user.id] = status);
           });
        }
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('DiscoveryScreen: Error loading data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        _performSearch(query.trim());
      } else {
        setState(() {
          _isSearching = false;
          _searchResults = [];
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      final results = await _chatRepository.searchUsers(query);
      for (var user in results) {
        if (!_friendStatuses.containsKey(user.id)) {
          final status = await _friendRepository.getFriendStatus(user.id);
          _friendStatuses[user.id] = status;
        }
      }
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('DiscoveryScreen: Search error: $e');
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Discover People', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: AppTextField(
              controller: _searchController,
              hint: 'Search by name or username...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
              onChanged: _onSearchChanged,
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_searchController.text.isNotEmpty) {
      if (_isSearching) return const Center(child: CircularProgressIndicator());
      if (_searchResults.isEmpty) return _buildNoResults();
      return _buildResultsList(_searchResults);
    }

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _loadDiscoveryData,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          if (_onlineUsers.isNotEmpty) ...[
            _buildSectionHeader('Online Now', _onlineUsers.length.toString()),
            const SizedBox(height: 16),
            _buildOnlineHorizontalList(),
            const SizedBox(height: 32),
          ],
          if (_suggestedUsers.isNotEmpty) ...[
            _buildSectionHeader('Suggested for You', null),
            const SizedBox(height: 16),
            ..._suggestedUsers.map((u) => _buildUserCard(u)),
            const SizedBox(height: 32),
          ],
          if (_recentlyActiveUsers.isNotEmpty) ...[
            _buildSectionHeader('Recently Active', null),
            const SizedBox(height: 16),
            ..._recentlyActiveUsers.map((u) => _buildUserCard(u)),
            const SizedBox(height: 32),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? badge) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge,
              style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOnlineHorizontalList() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _onlineUsers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final user = _onlineUsers[index];
          return InkWell(
            onTap: () => context.push('/user/${user.id}'),
            child: Column(
              children: [
                Stack(
                  children: [
                    AppAvatar(imageUrl: user.avatarUrl, initials: user.fullName, size: 60),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  user.fullName?.split(' ').first ?? 'User',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsList(List<Profile> results) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildUserCard(results[index]),
    );
  }

  Widget _buildUserCard(Profile user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = _friendStatuses[user.id] ?? FriendStatus.none;

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/user/${user.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AppAvatar(
              imageUrl: user.avatarUrl,
              initials: user.fullName,
              size: 56,
              showOnlineIndicator: user.isOnline,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName ?? 'User',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${user.username ?? 'username'}',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            _buildUserAction(user, status),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAction(Profile user, FriendStatus status) {
    if (status == FriendStatus.friends) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 22),
            onPressed: () async {
              final convId = await _chatRepository.getOrCreateDirectConversation(user.id);
              if (mounted) context.push('/chat/$convId');
            },
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined, color: AppColors.primary, size: 22),
            onPressed: () => context.push('/user/${user.id}'),
          ),
        ],
      );
    }

    if (status == FriendStatus.pendingSent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('Pending', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
      );
    }
    
    if (status == FriendStatus.pendingReceived) {
      return AppButton(
        text: 'Accept',
        type: AppButtonType.gradient,
        width: 80,
        height: 36,
        onPressed: () async {
          final requests = await _friendRepository.getIncomingRequests();
          final request = requests.firstWhere((r) => r.senderId == user.id);
          await _friendRepository.respondToFriendRequest(request.id, true);
          setState(() => _friendStatuses[user.id] = FriendStatus.friends);
        },
      );
    }

    return SizedBox(
      width: 90,
      child: AppButton(
        text: 'Add Friend',
        type: AppButtonType.gradient,
        height: 36,
        onPressed: () async {
          await _friendRepository.sendFriendRequest(user.id);
          setState(() {
            _friendStatuses[user.id] = FriendStatus.pendingSent;
          });
        },
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_search_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No people found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try searching for someone else.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
