import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/models/profile_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/friend_repository.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _chatRepository = ChatRepository();
  final _friendRepository = FriendRepository();
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  
  File? _imageFile;
  List<Profile> _friends = [];
  final List<String> _selectedIds = [];
  bool _isLoading = true;
  int _step = 1; // 1: Info, 2: Members

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
          _friends = friends;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _imageFile = File(image.path));
    }
  }

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a group name')));
      return;
    }

    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one member')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? avatarUrl;
      if (_imageFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = 'group-avatars/$fileName';
        await _chatRepository.uploadFile('chat-media', path, _imageFile!);
        avatarUrl = await _chatRepository.getMediaUrl(path);
      }

      final groupId = await _chatRepository.createGroup(
        name: _nameController.text.trim(),
        avatarUrl: avatarUrl,
        memberIds: _selectedIds,
      );

      if (mounted) {
        context.pushReplacement('/chat/$groupId');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_step == 1 ? 'New Group' : 'Add Members'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (_step == 2) {
              setState(() => _step = 1);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: _isLoading && _friends.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _step == 1
              ? _buildInfoStep()
              : _buildMembersStep(),
      floatingActionButton: _step == 2 && !_isLoading
          ? FloatingActionButton.extended(
              onPressed: _createGroup,
              label: const Text('Create Group', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.check_rounded, color: Colors.white),
              backgroundColor: AppColors.primary,
            )
          : null,
    );
  }

  Widget _buildInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      image: _imageFile != null
                          ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: _imageFile == null
                        ? const Icon(Icons.camera_alt_outlined, size: 40, color: AppColors.primary)
                        : null,
                  ),
                ),
                if (_imageFile != null)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          AppTextField(
            controller: _nameController,
            hint: 'Group Name',
            prefixIcon: const Icon(Icons.group_outlined),
          ),
          const SizedBox(height: 12),
          const Text(
            'Provide a group name and optional group icon.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          AppButton(
            text: 'Next',
            type: AppButtonType.gradient,
            onPressed: () {
              if (_nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a group name')));
                return;
              }
              setState(() => _step = 2);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMembersStep() {
    final filteredFriends = _friends.where((f) {
      final query = _searchController.text.toLowerCase();
      return f.fullName?.toLowerCase().contains(query) ?? false;
    }).toList();

    return Column(
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
        if (_selectedIds.isNotEmpty)
          Container(
            height: 100,
            padding: const EdgeInsets.only(bottom: 8),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _selectedIds.length,
              itemBuilder: (context, index) {
                final id = _selectedIds[index];
                final friend = _friends.firstWhere((f) => f.id == id);
                return Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          AppAvatar(imageUrl: friend.avatarUrl, initials: friend.fullName, size: 50),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedIds.remove(id)),
                              child: Container(
                                decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
                                child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        friend.fullName ?? '',
                        style: const TextStyle(fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        const Divider(height: 1),
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
    );
  }
}
