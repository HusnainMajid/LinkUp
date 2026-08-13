import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
import '../../../chat/data/repositories/friend_repository.dart';
import '../../../hub/data/repositories/hub_repository.dart';
import '../../../moments/data/models/moment_model.dart';
import '../../../moments/data/repositories/moment_repository.dart';
import '../../../moments/presentation/widgets/moment_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _profileRepository = ProfileRepository();
  final _chatRepository = ChatRepository();
  final _friendRepository = FriendRepository();
  final _hubRepository = HubRepository();
  final _momentRepository = MomentRepository();
  Profile? _profile;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Stream<List<Conversation>>? _recentConversationsStream;
  Stream<Map<String, int>>? _hubCountsStream;
  List<Moment> _allMoments = [];
  int _pendingRequestCount = 0;
  StreamSubscription? _triggerSubscription;
  StreamSubscription? _friendSubscription;
  StreamSubscription? _momentsSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _loadProfile();
    _loadPendingRequests();
    _recentConversationsStream = _chatRepository.subscribeToConversations();
    _hubCountsStream = _hubRepository.subscribeToSmartHubCounts();
    
    _momentsSubscription = _momentRepository.subscribeToMoments().listen((moments) {
      if (mounted) setState(() => _allMoments = moments);
    });
    
    _triggerSubscription = _chatRepository.globalChatUpdateTrigger.listen((_) {
      if (mounted) {
        setState(() {
          _recentConversationsStream = _chatRepository.subscribeToConversations();
        });
      }
    });

    _friendSubscription = _friendRepository.subscribeToFriendRequests().listen((_) {
      _loadPendingRequests();
    });
  }

  Future<void> _loadPendingRequests() async {
    try {
      final requests = await _friendRepository.getIncomingRequests();
      if (mounted) setState(() => _pendingRequestCount = requests.length);
    } catch (_) {}
  }

  @override
  void dispose() {
    _triggerSubscription?.cancel();
    _friendSubscription?.cancel();
    _momentsSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileRepository.getCurrentProfile();
      if (mounted) {
        setState(() => _profile = profile);
        _animationController.forward();
      }
    } catch (_) {}
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadProfile();
            await _loadPendingRequests();
            // Streams will update automatically via listeners
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme, isDark),
                  const SizedBox(height: 32),
                  _buildMomentsRow(theme),
                  const SizedBox(height: 32),
                  _buildHeroCard(),
                  const SizedBox(height: 32),
                  _buildQuickActions(theme, isDark),
                  const SizedBox(height: 32),
                  _buildRecentConversationsSection(theme, isDark),
                  const SizedBox(height: 32),
                  _buildHubPreview(theme),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
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
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_profile?.fullName ?? 'Husnain'} 👋',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => context.go('/profile'),
          child: Hero(
            tag: 'profile_avatar',
            child: AppAvatar(
              imageUrl: _profile?.avatarUrl,
              initials: _profile?.fullName ?? 'H',
              size: 54,
              showOnlineIndicator: true,
            ),
          ),
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
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 100,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PRO SPACE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your premium world.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Connect, collaborate, and share moments in a beautiful, secure environment.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionItem(Icons.chat_bubble_outline_rounded, 'Chat', () => context.push('/new-chat')),
            _buildActionItem(Icons.people_outline_rounded, 'Friends', () => context.push('/friends')),
            _buildActionItem(Icons.person_add_outlined, 'Requests', () => context.push('/friend-requests'), badgeCount: _pendingRequestCount),
            _buildActionItem(Icons.auto_awesome_rounded, 'AI', () => context.push('/ai-assistant')),
          ],
        ),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap, {int badgeCount = 0}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            AppCard(
              padding: const EdgeInsets.all(18),
              onTap: onTap,
              child: Icon(icon, color: AppColors.primary, size: 26),
            ),
            if (badgeCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? AppColors.backgroundDark : Colors.white, width: 2.5),
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildRecentConversationsSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Chats',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            TextButton(
              onPressed: () => context.go('/chats'),
              child: const Text('See all', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        StreamBuilder<List<Conversation>>(
          stream: _recentConversationsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
            }

            final allConversations = snapshot.data ?? [];
            final conversations = allConversations
                .where((c) => !(c.preferences?.isDeleted ?? false) && !(c.preferences?.isArchived ?? false))
                .take(3)
                .toList();

            if (conversations.isEmpty) return _buildEmptyState(isDark);

            return Column(
              children: conversations.map((conv) => _buildConversationItem(conv, isDark)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildConversationItem(Conversation conversation, bool isDark) {
    final otherUser = _chatRepository.getOtherParticipant(conversation);
    final prefs = conversation.preferences;
    final isUnread = conversation.unreadCount > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: () => context.push('/chat/${conversation.id}'),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: AppAvatar(
            imageUrl: otherUser?.avatarUrl,
            initials: otherUser?.fullName ?? 'U',
            size: 52,
            showOnlineIndicator: otherUser?.isOnline ?? false,
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
                    fontWeight: isUnread ? FontWeight.w900 : FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              if (conversation.latestMessage != null)
                Text(
                  _formatTime(conversation.latestMessage!.createdAt),
                  style: TextStyle(
                    color: isUnread ? AppColors.primary : Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: isUnread ? FontWeight.w900 : FontWeight.w500,
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
                    color: isUnread ? (isDark ? Colors.white : Colors.black87) : Colors.grey.shade500,
                    fontSize: 14,
                    fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (isUnread)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: Text(
                    conversation.unreadCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
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
    if (DateTime(localDate.year, localDate.month, localDate.day) == DateTime(now.year, now.month, now.day)) {
      return DateFormat('h:mm a').format(localDate);
    }
    return DateFormat('MMM d').format(localDate);
  }

  String _getMessagePreview(Conversation conversation) {
    if (conversation.latestMessage == null) return 'No messages yet';
    final msg = conversation.latestMessage!;
    if (msg.deletedAt != null) return 'Message deleted';
    final prefix = msg.senderId == sb.Supabase.instance.client.auth.currentUser?.id ? 'You: ' : '';
    if (msg.messageType == 'image') return '$prefix📷 Photo';
    return '$prefix${msg.content}';
  }

  Widget _buildEmptyState(bool isDark) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.forum_outlined, size: 36, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('No conversations yet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Connect with friends to start chatting.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 24),
          AppButton(text: 'Find Friends', width: 160, type: AppButtonType.primary, height: 48, onPressed: () => context.go('/hub')),
        ],
      ),
    );
  }

  Widget _buildHubPreview(ThemeData theme) {
    return StreamBuilder<Map<String, int>>(
      stream: _hubCountsStream,
      builder: (context, snapshot) {
        final counts = snapshot.data ?? {'tasks': 0, 'events': 0, 'notes': 0};
        
        return AppCard(
          padding: const EdgeInsets.all(24),
          onTap: () => context.go('/hub'),
          useGradient: true,
          gradient: LinearGradient(
            colors: [AppColors.secondary.withValues(alpha: 0.12), AppColors.primary.withValues(alpha: 0.12)],
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
                      Text('Smart Hub', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                      Text('Stay organized and productive.', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHubIndicator(Icons.checklist_rounded, 'Tasks', counts['tasks'].toString()),
                  _buildHubIndicator(Icons.calendar_today_rounded, 'Events', counts['events'].toString()),
                  _buildHubIndicator(Icons.note_alt_rounded, 'Notes', counts['notes'].toString()),
                ],
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildHubIndicator(IconData icon, String label, String count) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(count, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMomentsRow(ThemeData theme) {
    if (_allMoments.isEmpty) return const SizedBox.shrink();

    final Map<String, List<Moment>> groupedMoments = {};
    for (var m in _allMoments) {
      if (!groupedMoments.containsKey(m.userId)) groupedMoments[m.userId] = [];
      groupedMoments[m.userId]!.add(m);
    }

    final currentUserId = sb.Supabase.instance.client.auth.currentUser?.id;
    final myMoments = groupedMoments.remove(currentUserId) ?? [];
    final friendMomentEntries = groupedMoments.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Moments', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              UserMomentButton(
                onAdd: () => _showCreateMomentOptions(),
                onView: () => _openMomentViewer(myMoments),
                hasActiveMoments: myMoments.isNotEmpty,
                avatarUrl: _profile?.avatarUrl,
                initials: _profile?.fullName ?? 'Me',
              ),
              const SizedBox(width: 16),
              ...friendMomentEntries.map((entry) {
                final moments = entry.value;
                final user = moments.first.user;
                final hasUnseen = moments.any((m) => !m.isViewed);

                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: InkWell(
                    onTap: () => _openMomentViewer(moments),
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      children: [
                        MomentRing(
                          isUnseen: hasUnseen,
                          child: AppAvatar(imageUrl: user?.avatarUrl, initials: user?.fullName ?? 'U', size: 60),
                        ),
                        const SizedBox(height: 8),
                        Text(user?.fullName?.split(' ').first ?? 'User', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  void _showCreateMomentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            _buildMomentOption(Icons.camera_alt_rounded, 'Image Moment', 'Share a photo with your friends', AppColors.primary, _createImageMoment),
            _buildMomentOption(Icons.edit_note_rounded, 'Text Moment', 'Post a thought or status', AppColors.secondary, _createTextMoment),
          ],
        ),
      ),
    );
  }

  Widget _buildMomentOption(IconData icon, String title, String sub, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _createImageMoment() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null && mounted) context.push('/create-image-moment', extra: image);
  }

  void _createTextMoment() => context.push('/create-text-moment');
  void _openMomentViewer(List<Moment> moments) => context.push('/moment-viewer', extra: moments);
}
