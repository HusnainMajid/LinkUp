import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/models/profile_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/friend_repository.dart';

class AddGroupMembersScreen extends StatefulWidget {
  final String groupId;
  const AddGroupMembersScreen({super.key, required this.groupId});

  @override
  State<AddGroupMembersScreen> createState() => _AddGroupMembersScreenState();
}

class _AddGroupMembersScreenState extends State<AddGroupMembersScreen> {
  final _chatRepository = ChatRepository();
  final _friendRepository = FriendRepository();
  final _searchController = TextEditingController();
  
  List<Profile> _friends = [];
  final List<String> _selectedIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final friends = await _friendRepository.getFriends();
      // Filter out existing members (would require fetching group members first)
      // For simplicity, we just show all friends
      if (mounted) {
        setState(() {
          _friends = friends;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addMembers() async {
    if (_selectedIds.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _chatRepository.addGroupMembers(widget.groupId, _selectedIds);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFriends = _friends.where((f) {
      final query = _searchController.text.toLowerCase();
      return f.fullName?.toLowerCase().contains(query) ?? false;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Members'),
      ),
      body: _isLoading && _friends.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: AppTextField(
                    controller: _searchController,
                    hint: 'Search friends...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Expanded(
                  child: filteredFriends.isEmpty
                      ? const Center(child: Text('No friends found.'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount: filteredFriends.length,
                          itemBuilder: (context, index) {
                            final friend = filteredFriends[index];
                            final isSelected = _selectedIds.contains(friend.id);

                            return ListTile(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedIds.remove(friend.id);
                                  } else {
                                    _selectedIds.add(friend.id);
                                  }
                                });
                              },
                              leading: AppAvatar(imageUrl: friend.avatarUrl, initials: friend.fullName, size: 48),
                              title: Text(friend.fullName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                              trailing: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                  color: isSelected ? AppColors.primary : Colors.transparent,
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: isSelected ? Colors.white : Colors.transparent,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: _selectedIds.isNotEmpty && !_isLoading
          ? FloatingActionButton.extended(
              onPressed: _addMembers,
              label: const Text('Add Selected', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.person_add_rounded, color: Colors.white),
              backgroundColor: AppColors.primary,
            )
          : null,
    );
  }
}
