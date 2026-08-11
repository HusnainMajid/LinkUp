import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../auth/models/profile_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/friend_repository.dart';
import '../../data/models/friend_request_model.dart';

class UserProfilePreviewScreen extends StatefulWidget {
  final String userId;
  const UserProfilePreviewScreen({super.key, required this.userId});

  @override
  State<UserProfilePreviewScreen> createState() => _UserProfilePreviewScreenState();
}

class _UserProfilePreviewScreenState extends State<UserProfilePreviewScreen> {
  final _chatRepository = ChatRepository();
  final _friendRepository = FriendRepository();
  Profile? _profile;
  FriendStatus _friendStatus = FriendStatus.none;
  bool _isLoading = true;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final profile = await _chatRepository.getUserProfile(widget.userId);
      final status = await _friendRepository.getFriendStatus(widget.userId);
      if (mounted) {
        setState(() {
          _profile = profile;
          _friendStatus = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load user data.')),
        );
      }
    }
  }

  Future<void> _sendFriendRequest() async {
    setState(() => _isActionLoading = true);
    try {
      await _friendRepository.sendFriendRequest(widget.userId);
      await _loadData();
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _respondToRequest(bool accept) async {
    setState(() => _isActionLoading = true);
    try {
      final requests = await _friendRepository.getIncomingRequests();
      final request = requests.firstWhere((r) => r.senderId == widget.userId);
      await _friendRepository.respondToFriendRequest(request.id, accept);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to respond to request.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _cancelRequest() async {
    setState(() => _isActionLoading = true);
    try {
      final requests = await _friendRepository.getOutgoingRequests();
      final request = requests.firstWhere((r) => r.receiverId == widget.userId);
      await _friendRepository.cancelFriendRequest(request.id);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cancel request.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _startConversation() async {
    if (_profile == null) return;
    
    setState(() => _isActionLoading = true);
    try {
      final conversationId = await _chatRepository.getOrCreateDirectConversation(_profile!.id);
      if (mounted) {
        setState(() => _isActionLoading = false);
        context.pushReplacement('/chat/$conversationId');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('User not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Center(
              child: AppAvatar(
                imageUrl: _profile?.avatarUrl,
                initials: _profile?.fullName ?? 'U',
                size: 120,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _profile?.fullName ?? 'No Name',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              '@${_profile?.username ?? 'username'}',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            if (_profile?.bio != null && _profile!.bio!.isNotEmpty) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BIO',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _profile!.bio!,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    switch (_friendStatus) {
      case FriendStatus.friends:
        return AppButton(
          text: 'Message',
          type: AppButtonType.gradient,
          isLoading: _isActionLoading,
          onPressed: _startConversation,
        );
      case FriendStatus.pendingSent:
        return Column(
          children: [
            const Text('Friend Request Sent', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            AppButton(
              text: 'Cancel Request',
              type: AppButtonType.outlined,
              isLoading: _isActionLoading,
              onPressed: _cancelRequest,
            ),
          ],
        );
      case FriendStatus.pendingReceived:
        return Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Decline',
                type: AppButtonType.outlined,
                isLoading: _isActionLoading,
                onPressed: () => _respondToRequest(false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                text: 'Accept',
                type: AppButtonType.gradient,
                isLoading: _isActionLoading,
                onPressed: () => _respondToRequest(true),
              ),
            ),
          ],
        );
      case FriendStatus.none:
      case FriendStatus.rejected:
        return AppButton(
          text: 'Add Friend',
          type: AppButtonType.gradient,
          isLoading: _isActionLoading,
          onPressed: _sendFriendRequest,
        );
    }
  }
}
