import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/profile_repository.dart';
import '../../../auth/models/profile_model.dart';
import '../../../auth/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileRepository = ProfileRepository();
  final _authService = AuthService();
  Profile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileRepository.getCurrentProfile();
      if (mounted) setState(() { _profile = profile; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('You will need to sign in again to access your account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.signOut();
            },
            child: const Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildMainInfo(isDark),
                  const SizedBox(height: 40),
                  _buildAccountSection(),
                  const SizedBox(height: 32),
                  _buildGeneralSection(),
                  const SizedBox(height: 48),
                  AppButton(text: 'Logout', type: AppButtonType.secondary, height: 50, onPressed: _confirmLogout),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
      actions: [
        IconButton(
          onPressed: () => context.push('/profile/settings'),
          icon: const Icon(Icons.settings_outlined, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildMainInfo(bool isDark) {
    return Column(
      children: [
        Stack(
          children: [
            Hero(
              tag: 'profile_avatar',
              child: AppAvatar(imageUrl: _profile?.avatarUrl, initials: _profile?.fullName ?? 'U', size: 120),
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? AppColors.backgroundDark : Colors.white, width: 4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(_profile?.fullName ?? 'User', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 6),
        Text('@${_profile?.username ?? 'username'}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16)),
        if (_profile?.bio != null && _profile!.bio!.isNotEmpty) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _profile!.bio!,
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary, fontSize: 15, height: 1.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             _buildStatItem('Active', DateFormatter.formatChatDate(_profile?.lastSeen ?? DateTime.now())),
             _buildStatDivider(),
             _buildStatItem('Joined', 'Aug 2026'),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 28, width: 1.5, margin: const EdgeInsets.symmetric(horizontal: 40), color: Colors.grey.withValues(alpha: 0.15));
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ACCOUNT'),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildMenuTile(Icons.person_outline_rounded, 'Edit Profile', 'Update personal info', () { context.push('/profile/edit').then((_) => _loadProfile()); }),
              _buildMenuTile(Icons.alternate_email_rounded, 'Email', _authService.currentUser?.email ?? '', () {}),
              _buildMenuTile(Icons.phone_outlined, 'Phone', _profile?.phone ?? 'Not set', () {}),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('PREFERENCES'),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildMenuTile(Icons.shield_outlined, 'Privacy', 'Online status & visibility', () => context.push('/profile/settings')),
              _buildMenuTile(Icons.notifications_none_rounded, 'Notifications', 'Alerts & sounds', () => context.push('/profile/settings')),
              _buildMenuTile(Icons.palette_outlined, 'Appearance', 'Dark mode & theme', () => context.push('/profile/settings')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 1.5)),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, String sub, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
    );
  }
}
