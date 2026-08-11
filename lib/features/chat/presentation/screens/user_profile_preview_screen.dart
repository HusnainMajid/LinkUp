import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../auth/models/profile_model.dart';
import '../../data/repositories/chat_repository.dart';

class UserProfilePreviewScreen extends StatefulWidget {
  final String userId;
  const UserProfilePreviewScreen({super.key, required this.userId});

  @override
  State<UserProfilePreviewScreen> createState() => _UserProfilePreviewScreenState();
}

class _UserProfilePreviewScreenState extends State<UserProfilePreviewScreen> {
  final _chatRepository = ChatRepository();
  Profile? _profile;
  bool _isLoading = true;
  bool _isCreatingChat = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _chatRepository.getUserProfile(widget.userId);
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load user profile.')),
        );
      }
    }
  }

  Future<void> _startConversation() async {
    if (_profile == null) return;
    
    setState(() => _isCreatingChat = true);
    try {
      final conversationId = await _chatRepository.getOrCreateDirectConversation(_profile!.id);
      if (mounted) {
        setState(() => _isCreatingChat = false);
        context.pushReplacement('/chat/$conversationId');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreatingChat = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start conversation.')),
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
            AppButton(
              text: 'Message',
              type: AppButtonType.gradient,
              isLoading: _isCreatingChat,
              onPressed: _startConversation,
            ),
          ],
        ),
      ),
    );
  }
}
