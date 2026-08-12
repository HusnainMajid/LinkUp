import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../auth/models/profile_model.dart';
import '../../data/models/conversation_model.dart';
import '../../data/repositories/chat_repository.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String conversationId;
  const GroupDetailsScreen({super.key, required this.conversationId});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  final _chatRepository = ChatRepository();
  Conversation? _group;
  bool _isLoading = true;
  String? _myRole;

  @override
  void initState() {
    super.initState();
    _loadGroupDetails();
  }

  Future<void> _loadGroupDetails() async {
    try {
      final conversations = await _chatRepository.getUserConversations();
      final group = conversations.firstWhere((c) => c.id == widget.conversationId);
      final myId = Supabase.instance.client.auth.currentUser!.id;
      
      if (mounted) {
        setState(() {
          _group = group;
          _myRole = group.roles?[myId];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _isAdminOrOwner => _myRole == 'OWNER' || _myRole == 'ADMIN';

  Future<void> _editGroupName() async {
    final controller = TextEditingController(text: _group?.groupName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Group Name'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Enter name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != _group?.groupName) {
      await _chatRepository.updateGroupInfo(widget.conversationId, name: newName);
      _loadGroupDetails();
    }
  }

  Future<void> _changeAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'group-avatars/$fileName';
      await _chatRepository.uploadFile('chat-media', path, File(image.path));
      final url = await _chatRepository.getMediaUrl(path);
      await _chatRepository.updateGroupInfo(widget.conversationId, avatarUrl: url);
      _loadGroupDetails();
    }
  }

  Future<void> _leaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group?'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Leave', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );

    if (confirmed == true) {
      await _chatRepository.leaveGroup(widget.conversationId);
      if (mounted) context.go('/chats');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_group == null) return const Scaffold(body: Center(child: Text('Group not found')));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildInfoSection(),
                _buildActionSection(),
                _buildMembersHeader(),
              ],
            ),
          ),
          _buildMembersList(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _group?.groupName ?? 'Group Details',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            AppAvatar(
              imageUrl: _group?.groupAvatarUrl,
              initials: _group?.groupName,
              size: double.infinity,
              backgroundColor: Colors.grey.shade200,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (_isAdminOrOwner)
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _changeAvatar),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _group?.groupName ?? '',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              if (_isAdminOrOwner)
                IconButton(icon: const Icon(Icons.edit_rounded, size: 20, color: AppColors.primary), onPressed: _editGroupName),
            ],
          ),
          Text(
            '${_group?.members?.length ?? 0} members',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          if (_isAdminOrOwner)
            ListTile(
              onTap: () => context.push('/add-group-members/${widget.conversationId}'),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.person_add_outlined, color: AppColors.primary),
              ),
              title: const Text('Add Members', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ListTile(
            onTap: _leaveGroup,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.logout_rounded, color: AppColors.error),
            ),
            title: const Text('Leave Group', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
          const Divider(height: 32),
        ],
      ),
    );
  }

  Widget _buildMembersHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Group Members',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildMembersList() {
    final members = _group?.members ?? [];
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final profile = members[index];
          final role = _group?.roles?[profile.id] ?? 'MEMBER';
          final isMe = profile.id == Supabase.instance.client.auth.currentUser?.id;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            onTap: () => context.push('/user/${profile.id}'),
            leading: AppAvatar(imageUrl: profile.avatarUrl, initials: profile.fullName, size: 48, showOnlineIndicator: profile.isOnline),
            title: Text(profile.fullName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(profile.isOnline ? 'Online' : 'Offline', style: TextStyle(color: profile.isOnline ? AppColors.success : Colors.grey, fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (role != 'MEMBER')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: role == 'OWNER' ? Colors.orange.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: role == 'OWNER' ? Colors.orange.withValues(alpha: 0.5) : Colors.blue.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: role == 'OWNER' ? Colors.orange : Colors.blue),
                    ),
                  ),
                if (_isAdminOrOwner && !isMe && role != 'OWNER')
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    onPressed: () => _showMemberActionSheet(profile, role),
                  ),
              ],
            ),
          );
        },
        childCount: members.length,
      ),
    );
  }

  void _showMemberActionSheet(Profile profile, String currentRole) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: Text('View ${profile.fullName}'),
              onTap: () {
                Navigator.pop(context);
                context.push('/user/${profile.id}');
              },
            ),
            if (_myRole == 'OWNER') ...[
              if (currentRole == 'MEMBER')
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text('Make Admin'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _chatRepository.updateMemberRole(widget.conversationId, profile.id, 'ADMIN');
                    _loadGroupDetails();
                  },
                ),
              if (currentRole == 'ADMIN')
                ListTile(
                  leading: const Icon(Icons.person_remove_outlined),
                  title: const Text('Remove as Admin'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _chatRepository.updateMemberRole(widget.conversationId, profile.id, 'MEMBER');
                    _loadGroupDetails();
                  },
                ),
            ],
            ListTile(
              leading: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.error),
              title: const Text('Remove from Group', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(context);
                await _chatRepository.removeGroupMember(widget.conversationId, profile.id);
                _loadGroupDetails();
              },
            ),
          ],
        ),
      ),
    );
  }
}
