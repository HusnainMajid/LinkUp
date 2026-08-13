import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/settings/settings_service.dart';
import '../../../../shared/widgets/app_card.dart';
import '../widgets/settings_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = SettingsService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: ValueListenableBuilder(
        valueListenable: settingsService.settings,
        builder: (context, settings, child) {
          if (settings == null) return const Center(child: CircularProgressIndicator());

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              _buildSectionHeader('PRIVACY'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SettingsToggleTile(
                      icon: Icons.visibility_rounded,
                      title: 'Online Status',
                      subtitle: 'Show when you are active',
                      value: settings.showOnlineStatus,
                      onChanged: (v) => settingsService.updatePrivacy('show_online_status', v),
                    ),
                    const Divider(indent: 56),
                    SettingsToggleTile(
                      icon: Icons.access_time_rounded,
                      title: 'Last Seen',
                      subtitle: 'Show when you were last active',
                      value: settings.showLastSeen,
                      onChanged: (v) => settingsService.updatePrivacy('show_last_seen', v),
                    ),
                    const Divider(indent: 56),
                    SettingsToggleTile(
                      icon: Icons.person_search_rounded,
                      title: 'Allow Discovery',
                      subtitle: 'Appear in suggested people',
                      value: settings.allowDiscovery,
                      onChanged: (v) => settingsService.updatePrivacy('allow_discovery', v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              _buildSectionHeader('NOTIFICATIONS'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SettingsToggleTile(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Messages',
                      subtitle: 'Alerts for new messages',
                      value: settings.notifyMessages,
                      onChanged: (v) => settingsService.updateNotification('notify_messages', v),
                    ),
                    const Divider(indent: 56),
                    SettingsToggleTile(
                      icon: Icons.call_outlined,
                      title: 'Calls',
                      subtitle: 'Alerts for incoming calls',
                      value: settings.notifyCalls,
                      onChanged: (v) => settingsService.updateNotification('notify_calls', v),
                    ),
                    const Divider(indent: 56),
                    SettingsToggleTile(
                      icon: Icons.auto_awesome_mosaic_outlined,
                      title: 'Moments',
                      subtitle: 'Alerts for moment replies',
                      value: settings.notifyMoments,
                      onChanged: (v) => settingsService.updateNotification('notify_moments', v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionHeader('APPEARANCE'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SettingsActionTile(
                      icon: Icons.palette_outlined,
                      title: 'Theme Mode',
                      value: _formatThemeName(settings.themeMode),
                      onTap: () => _showThemePicker(context, settingsService),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionHeader('ABOUT'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    const SettingsInfoTile(icon: Icons.info_outline_rounded, title: 'App Version', value: '1.0.0 (Gold)'),
                    const Divider(indent: 56),
                    SettingsActionTile(icon: Icons.description_outlined, title: 'Privacy Policy', onTap: () {}),
                    const Divider(indent: 56),
                    SettingsActionTile(icon: Icons.gavel_rounded, title: 'Terms of Service', onTap: () {}),
                  ],
                ),
              ),
              const SizedBox(height: 60),
            ],
          );
        },
      ),
    );
  }

  String _formatThemeName(String mode) {
    if (mode == 'system') return 'System Default';
    return mode.substring(0, 1).toUpperCase() + mode.substring(1);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 1.5),
      ),
    );
  }

  void _showThemePicker(BuildContext context, SettingsService service) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            const Padding(padding: EdgeInsets.all(24), child: Text('Choose Appearance', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
            ListTile(
              leading: _buildPickerIcon(Icons.brightness_auto_rounded),
              title: const Text('System Default', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () { service.updateThemeMode(ThemeMode.system); Navigator.pop(context); },
            ),
            ListTile(
              leading: _buildPickerIcon(Icons.light_mode_rounded),
              title: const Text('Light Mode', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () { service.updateThemeMode(ThemeMode.light); Navigator.pop(context); },
            ),
            ListTile(
              leading: _buildPickerIcon(Icons.dark_mode_rounded),
              title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () { service.updateThemeMode(ThemeMode.dark); Navigator.pop(context); },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
      child: Icon(icon, color: AppColors.primary, size: 22),
    );
  }
}
