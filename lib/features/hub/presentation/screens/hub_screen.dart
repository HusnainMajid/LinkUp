import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../auth/models/profile_model.dart';

import '../../../chat/data/repositories/chat_repository.dart';
import '../../../chat/data/repositories/friend_repository.dart';
import '../../../chat/data/models/friend_request_model.dart';
import '../../../moments/data/models/moment_model.dart';
import '../../../moments/data/repositories/moment_repository.dart';
import '../../../moments/presentation/widgets/moment_widgets.dart';
import '../../../profile/data/profile_repository.dart';
import '../../data/repositories/hub_repository.dart';

class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  final _chatRepository = ChatRepository();
  final _friendRepository = FriendRepository();
  final _hubRepository = HubRepository();
  final _momentRepository = MomentRepository();
  final _profileRepository = ProfileRepository();
  
  bool _isLoading = true;
  Profile? _currentProfile;
  List<Profile> _onlineUsers = [];
  List<Profile> _recentlyActiveUsers = [];
  List<Profile> _suggestedUsers = [];
  List<Profile> _friends = [];
  List<Moment> _allMoments = [];
  int _pendingRequestsCount = 0;
  final Map<String, FriendStatus> _friendStatuses = {};
  
  StreamSubscription? _realtimeSubscription;
  StreamSubscription? _momentsSubscription;

  @override
  void initState() {
    super.initState();
    _loadHubData();
    _setupRealtime();
    _momentsSubscription = _momentRepository.subscribeToMoments().listen((moments) {
      if (mounted) setState(() => _allMoments = moments);
    });
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _momentsSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtime() {
    _realtimeSubscription = _chatRepository.globalChatUpdateTrigger.listen((_) {
      _loadHubData(silent: true);
    });
  }

  Future<void> _loadHubData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _chatRepository.getOnlineUsers(),
        _chatRepository.getRecentlyActiveUsers(),
        _chatRepository.getSuggestedUsers(),
        _friendRepository.getIncomingRequests(),
        _friendRepository.getFriends(),
        _friendRepository.getOutgoingRequests(),
        _profileRepository.getCurrentProfile(),
      ]);

      if (mounted) {
        setState(() {
          _onlineUsers = results[0] as List<Profile>;
          _recentlyActiveUsers = results[1] as List<Profile>;
          _suggestedUsers = results[2] as List<Profile>;
          _pendingRequestsCount = (results[3] as List<FriendRequest>).length;
          _friends = results[4] as List<Profile>;
          _currentProfile = results[6] as Profile?;

          final incoming = results[3] as List<FriendRequest>;
          final friendsList = results[4] as List<Profile>;
          final outgoing = results[5] as List<FriendRequest>;

          _friendStatuses.clear();
          for (var f in friendsList) {
            _friendStatuses[f.id] = FriendStatus.friends;
          }
          for (var r in incoming) {
            _friendStatuses[r.senderId] = FriendStatus.pendingReceived;
          }
          for (var r in outgoing) {
            _friendStatuses[r.receiverId] = FriendStatus.pendingSent;
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('HubScreen: Error loading data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHubData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildHeader(isDark),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildMomentsRow(isDark),
                      const SizedBox(height: 32),
                      _buildOverview(isDark),
                      const SizedBox(height: 24),
                      _buildQuickActions(isDark),
                      const SizedBox(height: 32),
                      _buildSmartHubSection(isDark),
                      const SizedBox(height: 32),
                      _buildAIBanner(isDark),
                      const SizedBox(height: 32),
                      _buildOnlineNow(isDark),

                      const SizedBox(height: 32),
                      _buildFriendsSection(isDark),
                      const SizedBox(height: 32),
                      _buildRecentlyActive(isDark),
                      const SizedBox(height: 32),
                      _buildSuggestedPeople(isDark),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hub',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stay connected with your space.',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: () => context.push('/discovery'),
              style: IconButton.styleFrom(
                backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                padding: const EdgeInsets.all(12),
              ),
              icon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(bool isDark) {
    return Row(
      children: [
        _buildOverviewItem(_friends.length.toString(), 'Friends', isDark),
        _buildOverviewDivider(isDark),
        _buildOverviewItem(_onlineUsers.length.toString(), 'Online', isDark),
        _buildOverviewDivider(isDark),
        _buildOverviewItem(_pendingRequestsCount.toString(), 'Requests', isDark),
      ],
    );
  }

  Widget _buildOverviewItem(String count, String label, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewDivider(bool isDark) {
    return Container(
      height: 24,
      width: 1,
      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildCompactAction(Icons.people_alt_rounded, 'Friends', () => context.push('/friends'), isDark),
        _buildCompactAction(Icons.person_add_rounded, 'Requests', () => context.push('/friend-requests'), isDark, badge: _pendingRequestsCount),
        _buildCompactAction(Icons.explore_rounded, 'Discover', () => context.push('/discovery'), isDark),
        _buildCompactAction(Icons.sensors_rounded, 'Online', () {}, isDark),
      ],
    );
  }

  Widget _buildAIBanner(bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      onTap: () => context.push('/ai-assistant'),
      useGradient: true,
      gradient: LinearGradient(
        colors: [
          AppColors.primary,
          AppColors.secondary.withValues(alpha: 0.8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LinkUp AI Assistant',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Your intelligent partner for ideas and writing.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
        ],
      ),
    );
  }



  Widget _buildCompactAction(IconData icon, String label, VoidCallback onTap, bool isDark, {int badge = 0}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.2,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: AppColors.primary, size: 22),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                      child: Text(
                        badge.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildMomentsRow(bool isDark) {
    if (_isLoading && _allMoments.isEmpty) {
      return _buildMomentsSkeleton(isDark);
    }

    final Map<String, List<Moment>> groupedMoments = {};
    for (var m in _allMoments) {
      if (!groupedMoments.containsKey(m.userId)) {
        groupedMoments[m.userId] = [];
      }
      groupedMoments[m.userId]!.add(m);
    }

    final currentUserId = _chatRepository.supabase.auth.currentUser?.id;
    final myMoments = groupedMoments.remove(currentUserId) ?? [];
    final friendMomentEntries = groupedMoments.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MOMENTS',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 1.2),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (_currentProfile != null)
                UserMomentButton(
                  onAdd: () => _showCreateMomentOptions(),
                  onView: () => _openMomentViewer(myMoments),
                  hasActiveMoments: myMoments.isNotEmpty,
                  avatarUrl: _currentProfile!.avatarUrl,
                  initials: _currentProfile!.fullName ?? 'Me',
                ),
              if (friendMomentEntries.isEmpty && myMoments.isEmpty && !_isLoading)
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Center(child: Text('No new moments', style: TextStyle(color: Colors.grey, fontSize: 12))),
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
                          child: AppAvatar(
                            imageUrl: user?.avatarUrl,
                            initials: user?.fullName ?? 'U',
                            size: 58,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user?.fullName?.split(' ').first ?? 'User',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
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

  Widget _buildMomentsSkeleton(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MOMENTS',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 1.2),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) => Column(
              children: [
                Container(width: 64, height: 64, decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05), shape: BoxShape.circle)),
                const SizedBox(height: 8),
                Container(width: 40, height: 10, decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCreateMomentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              ),
              title: const Text('Image Moment', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Share a photo with a caption'),
              onTap: () {
                Navigator.pop(context);
                _createImageMoment();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.edit_note_rounded, color: AppColors.secondary),
              ),
              title: const Text('Text Moment', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Share a thought or quote'),
              onTap: () {
                Navigator.pop(context);
                _createTextMoment();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _createImageMoment() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null && mounted) {
      context.push('/create-image-moment', extra: image);
    }
  }

  void _createTextMoment() {
    context.push('/create-text-moment');
  }

  void _openMomentViewer(List<Moment> moments) {
    if (moments.isEmpty) return;
    context.push('/moment-viewer', extra: moments);
  }

  Widget _buildSmartHubSection(bool isDark) {
    return StreamBuilder<Map<String, int>>(
      stream: _hubRepository.subscribeToSmartHubCounts(),
      builder: (context, snapshot) {
        final counts = snapshot.data ?? {'tasks': 0, 'events': 0, 'notes': 0};
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SMART HUB',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
              ),
              child: Row(
                children: [
                  _buildSmartHubItem(Icons.checklist_rounded, 'Tasks', '${counts['tasks']} pending', () => context.push('/tasks'), isDark),
                  _buildSmartHubItem(Icons.calendar_month_rounded, 'Events', '${counts['events']} upcoming', () => context.push('/events'), isDark),
                  _buildSmartHubItem(Icons.note_alt_rounded, 'Notes', '${counts['notes']} saved', () => context.push('/notes'), isDark),
                ],
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildSmartHubItem(IconData icon, String label, String sub, VoidCallback onTap, bool isDark) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineNow(bool isDark) {
    if (_isLoading) return _buildSectionSkeleton('ONLINE NOW');
    if (_onlineUsers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('ONLINE NOW', _onlineUsers.length.toString()),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _onlineUsers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 20),
            itemBuilder: (context, index) {
              final user = _onlineUsers[index];
              return InkWell(
                onTap: () => context.push('/user/${user.id}'),
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        AppAvatar(imageUrl: user.avatarUrl, initials: user.fullName, size: 60),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            width: 15,
                            height: 15,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.fullName?.split(' ').first ?? 'User',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFriendsSection(bool isDark) {
    if (_isLoading) return _buildSectionSkeleton('FRIENDS');
    if (_friends.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('FRIENDS', _friends.length.toString(), onSeeAll: () => context.push('/friends')),
        const SizedBox(height: 16),
        ..._friends.take(3).map((u) => _buildCompactUserItem(u, isDark, showActions: true)),
      ],
    );
  }

  Widget _buildRecentlyActive(bool isDark) {
    if (_isLoading) return _buildSectionSkeleton('RECENTLY ACTIVE');
    
    final recent = _recentlyActiveUsers.where((u) => !u.isOnline).toList();
    if (recent.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('RECENTLY ACTIVE', null),
        const SizedBox(height: 16),
        ...recent.take(3).map((u) => _buildCompactUserItem(u, isDark)),
      ],
    );
  }

  Widget _buildSuggestedPeople(bool isDark) {
    if (_isLoading) return _buildSectionSkeleton('SUGGESTED FOR YOU');
    if (_suggestedUsers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('SUGGESTED FOR YOU', null, onSeeAll: () => context.push('/discovery')),
        const SizedBox(height: 16),
        ..._suggestedUsers.take(5).map((u) => _buildUserCard(u, isDark)),
      ],
    );
  }

  Widget _buildCompactUserItem(Profile user, bool isDark, {bool showActions = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/user/${user.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
          ),
          child: Row(
            children: [
              AppAvatar(imageUrl: user.avatarUrl, initials: user.fullName, size: 48, showOnlineIndicator: user.isOnline),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      DateFormatter.formatLastSeen(user.lastSeen, user.isOnline),
                      style: TextStyle(color: user.isOnline ? AppColors.success : Colors.grey, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (showActions)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIconAction(Icons.chat_bubble_outline_rounded, () async {
                      final convId = await _chatRepository.getOrCreateDirectConversation(user.id);
                      if (mounted) context.push('/chat/$convId');
                    }, isDark),
                    const SizedBox(width: 8),
                    _buildIconAction(Icons.call_outlined, () => context.push('/user/${user.id}'), isDark),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconAction(IconData icon, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
    );
  }

  Widget _buildUserCard(Profile user, bool isDark) {
    final status = _friendStatuses[user.id] ?? FriendStatus.none;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/user/${user.id}'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                AppAvatar(imageUrl: user.avatarUrl, initials: user.fullName, size: 48, showOnlineIndicator: user.isOnline),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('@${user.username ?? 'username'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                _buildUserAction(user, status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserAction(Profile user, FriendStatus status) {
    if (status == FriendStatus.friends) {
      return const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20);
    }

    if (status == FriendStatus.pendingSent) {
      return const Icon(Icons.hourglass_bottom_rounded, color: Colors.orange, size: 20);
    }

    return AppButton(
      text: 'Add',
      type: AppButtonType.gradient,
      width: 70,
      onPressed: () async {
        await _friendRepository.sendFriendRequest(user.id);
        setState(() => _friendStatuses[user.id] = FriendStatus.pendingSent);
      },
    );
  }

  Widget _buildSectionHeader(String title, String? badge, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 1.2),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: const Text('See all', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _buildSectionSkeleton(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title, null),
        const SizedBox(height: 16),
        const Center(child: SizedBox(height: 2, child: LinearProgressIndicator())),
      ],
    );
  }
}
