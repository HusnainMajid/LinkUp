import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../auth/models/profile_model.dart';
import '../../../chat/data/models/conversation_model.dart';
import '../../../chat/data/repositories/chat_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _profileRepository = ProfileRepository();
  final _chatRepository = ChatRepository();
  Profile? _profile;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Stream<List<Conversation>>? _recentConversationsStream;
  StreamSubscription? _triggerSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _loadProfile();
    _recentConversationsStream = _chatRepository.subscribeToConversations();
    
    // Global trigger for real-time updates
    _triggerSubscription = _chatRepository.globalChatUpdateTrigger.listen((_) {
      if (mounted) {
        setState(() {
          _recentConversationsStream = _chatRepository.subscribeToConversations();
        });
      }
    });
  }

  @override
  void dispose() {
    _triggerSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileRepository.getCurrentProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
        });
        _animationController.forward();
      }
    } catch (_) {
      // Handle error if needed
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildHeroCard(),
                const SizedBox(height: 32),
                _buildQuickActions(),
                const SizedBox(height: 32),
                _buildRecentConversationsSection(),
                const SizedBox(height: 32),
                _buildHubPreview(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting()},',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
              Text(
                '${_profile?.fullName ?? 'Husnain'} 👋',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Stay connected. Stay productive.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        AppAvatar(
          imageUrl: _profile?.avatarUrl,
          initials: _profile?.fullName ?? 'H',
          size: 56,
          showOnlineIndicator: true,
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return AppCard(
      useGradient: true,
      padding: const EdgeInsets.all(28),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              Icons.blur_on_rounded,
              size: 80,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'LINKUP SPACE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your space to connect.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chat, collaborate and keep everything together in one premium experience.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionItem(
              Icons.chat_bubble_outline_rounded, 
              'New Chat', 
              onTap: () => context.push('/new-chat'),
            ),
            _buildActionItem(
              Icons.group_add_outlined, 
              'New Group',
              onTap: () => context.go('/groups'),
            ),
            _buildActionItem(
              Icons.task_alt_rounded, 
              'Task',
              onTap: () => context.go('/hub'),
            ),
            _buildActionItem(
              Icons.event_note_rounded, 
              'Event',
              onTap: () => context.go('/hub'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label, {VoidCallback? onTap}) {
    return Column(
      children: [
        AppCard(
          padding: const EdgeInsets.all(16),
          onTap: onTap,
          child: Icon(
            icon, 
            color: AppColors.primary, 
            size: 24
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? AppColors.textSecondaryDark 
                    : AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildRecentConversationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Conversations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => context.go('/chats'),
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<Conversation>>(
          stream: _recentConversationsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final allConversations = snapshot.data ?? [];
            final conversations = allConversations
                .where((c) => !(c.preferences?.isDeleted ?? false) && !(c.preferences?.isArchived ?? false))
                .take(3)
                .toList();

            if (conversations.isEmpty) {
              return _buildEmptyState();
            }

            return Column(
              children: conversations.map((conv) => _buildConversationItem(conv)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildConversationItem(Conversation conversation) {
    final otherUser = _chatRepository.getOtherParticipant(conversation);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefs = conversation.preferences;
    final isUnread = prefs?.lastReadAt == null || 
        (conversation.latestMessage != null && 
         conversation.latestMessage!.createdAt.isAfter(prefs!.lastReadAt!));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: () => context.push('/chat/${conversation.id}'),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: AppAvatar(
            imageUrl: otherUser?.avatarUrl,
            initials: otherUser?.fullName ?? 'U',
            size: 48,
            showOnlineIndicator: true,
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  otherUser?.fullName ?? 'User',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ),
              if (conversation.latestMessage != null)
                Text(
                  _formatTime(conversation.latestMessage!.createdAt),
                  style: TextStyle(
                    color: isUnread ? AppColors.primary : Colors.grey,
                    fontSize: 11,
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
            ],
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                  _getMessagePreview(conversation),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isUnread ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ),
              if (isUnread)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final localDate = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(localDate.year, localDate.month, localDate.day);

    if (messageDate == today) {
      return DateFormat('h:mm a').format(localDate);
    } else {
      return DateFormat('MMM d').format(localDate);
    }
  }

  String _getMessagePreview(Conversation conversation) {
    if (conversation.latestMessage == null) return 'No messages yet';
    final msg = conversation.latestMessage!;
    if (msg.deletedAt != null) return 'This message was deleted';
    
    final prefix = msg.senderId == sb.Supabase.instance.client.auth.currentUser?.id ? 'You: ' : '';
    
    switch (msg.messageType) {
      case 'image': return '$prefix📷 Photo';
      case 'file': return '$prefix📎 ${msg.fileName ?? 'File'}';
      default: return '$prefix${msg.content}';
    }
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.forum_outlined, 
              size: 32, 
              color: isDark ? AppColors.textTertiaryDark : Colors.grey
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No conversations yet',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start a conversation and connect with someone.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          AppButton(
            text: '+ Start New Chat',
            width: 180,
            type: AppButtonType.gradient,
            onPressed: () => context.push('/new-chat'),
          ),
        ],
      ),
    );
  }

  Widget _buildHubPreview() {
    return AppCard(
      padding: const EdgeInsets.all(24),
      onTap: () => context.go('/hub'),
      useGradient: true,
      gradient: LinearGradient(
        colors: [
          AppColors.secondary.withValues(alpha: 0.15), 
          AppColors.primary.withValues(alpha: 0.15)
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart Hub',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Turn conversations into action.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHubIndicator(Icons.checklist_rounded, 'Tasks', '0'),
              _buildHubIndicator(Icons.calendar_today_rounded, 'Events', '0'),
              _buildHubIndicator(Icons.note_alt_rounded, 'Notes', '0'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHubIndicator(IconData icon, String label, String count) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(count, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
