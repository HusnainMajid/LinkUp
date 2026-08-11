import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../auth/models/profile_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _profileRepository = ProfileRepository();
  Profile? _profile;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
  }

  @override
  void dispose() {
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
                _buildRecentConversations(),
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
            _buildActionItem(Icons.chat_bubble_outline_rounded, 'New Chat'),
            _buildActionItem(Icons.group_add_outlined, 'New Group'),
            _buildActionItem(Icons.task_alt_rounded, 'Task'),
            _buildActionItem(Icons.event_note_rounded, 'Event'),
          ],
        ),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label) {
    return Column(
      children: [
        AppCard(
          padding: const EdgeInsets.all(16),
          onTap: () {},
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

  Widget _buildRecentConversations() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Conversations',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppCard(
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
              Text(
                'No conversations yet',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Start a conversation and connect with someone.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              AppButton(
                text: '+ Start New Chat',
                width: 180,
                type: AppButtonType.gradient,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHubPreview() {
    return AppCard(
      padding: const EdgeInsets.all(24),
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
            Gap.w8,
            Text(count, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Gap.h4,
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
