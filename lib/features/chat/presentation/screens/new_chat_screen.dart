import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/models/profile_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/friend_repository.dart';
import '../../data/models/friend_request_model.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _chatRepository = ChatRepository();
  final _friendRepository = FriendRepository();
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Profile> _results = [];
  Map<String, FriendStatus> _friendStatuses = {};
  bool _isLoading = false;
  bool _hasSearched = false;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        _performSearch(query.trim());
      } else {
        setState(() {
          _results = [];
          _hasSearched = false;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final results = await _chatRepository.searchUsers(query);
      Map<String, FriendStatus> statuses = {};
      for (var user in results) {
        statuses[user.id] = await _friendRepository.getFriendStatus(user.id);
      }

      if (mounted) {
        setState(() {
          _results = results;
          _friendStatuses = statuses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to search users. Try again.')),
        );
      }
    }
  }

  Future<void> _handleAction(Profile user) async {
    final status = _friendStatuses[user.id] ?? FriendStatus.none;

    if (status == FriendStatus.friends) {
      try {
        final conversationId = await _chatRepository.getOrCreateDirectConversation(user.id);
        if (mounted) context.pushReplacement('/chat/$conversationId');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
          );
        }
      }
    } else {
      context.push('/user/${user.id}');
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Chat'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: AppTextField(
              controller: _searchController,
              hint: 'Search by name or username...',
              prefixIcon: const Icon(Icons.search_rounded),
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search_rounded,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            const Text(
              'Find people on LinkUp',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Search by name or username.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sentiment_dissatisfied_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No people found'),
            const SizedBox(height: 4),
            const Text(
              'Try another name or username.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final profile = _results[index];
        final status = _friendStatuses[profile.id] ?? FriendStatus.none;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            padding: EdgeInsets.zero,
            onTap: () => _handleAction(profile),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: AppAvatar(
                imageUrl: profile.avatarUrl,
                initials: profile.fullName ?? 'U',
                size: 48,
              ),
              title: Text(
                profile.fullName ?? 'No Name',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '@${profile.username ?? 'username'}',
                style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              trailing: _buildTrailing(status),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrailing(FriendStatus status) {
    switch (status) {
      case FriendStatus.friends:
        return const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: AppColors.primary);
      case FriendStatus.pendingSent:
      case FriendStatus.pendingReceived:
        return const Icon(Icons.hourglass_empty_rounded, size: 20, color: Colors.orange);
      default:
        return const Icon(Icons.person_add_alt_1_rounded, size: 20, color: Colors.grey);
    }
  }
}
