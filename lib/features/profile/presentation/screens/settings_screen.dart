import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/settings/settings_service.dart';
import '../../../../shared/widgets/app_card.dart';
import '../widgets/settings_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsService = SettingsService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ValueListenableBuilder(
        valueListenable: settingsService.settings,
        builder: (context, settings, child) {
          if (settings == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(20),
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
                    SettingsToggleTile(
                      icon: Icons.access_time_rounded,
                      title: 'Last Seen',
                      subtitle: 'Show when you were last active',
                      value: settings.showLastSeen,
                      onChanged: (v) => settingsService.updatePrivacy('show_last_seen', v),
                    ),
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
              const SizedBox(height: 24),
              
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
                    SettingsToggleTile(
                      icon: Icons.call_outlined,
                      title: 'Calls',
                      subtitle: 'Alerts for incoming calls',
                      value: settings.notifyCalls,
                      onChanged: (v) => settingsService.updateNotification('notify_calls', v),
                    ),
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
              const SizedBox(height: 24),

              _buildSectionHeader('APPEARANCE'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SettingsActionTile(
                      icon: Icons.palette_outlined,
                      title: 'Theme',
                      value: settings.themeMode.toUpperCase(),
                      onTap: () => _showThemePicker(context, settingsService),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionHeader('ABOUT'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    const SettingsInfoTile(
                      icon: Icons.info_outline_rounded,
                      title: 'Version',
                      value: '1.0.0 (Build 1)',
                    ),
                    SettingsActionTile(
                      icon: Icons.description_outlined,
                      title: 'Privacy Policy',
                      onTap: () {},
                    ),
                    SettingsActionTile(
                      icon: Icons.gavel_rounded,
                      title: 'Terms of Service',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context, SettingsService service) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Choose Theme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            ListTile(
              leading: const Icon(Icons.brightness_auto_rounded),
              title: const Text('System Default'),
              onTap: () { service.updateThemeMode(ThemeMode.system); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode_rounded),
              title: const Text('Light Mode'),
              onTap: () { service.updateThemeMode(ThemeMode.light); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_rounded),
              title: const Text('Dark Mode'),
              onTap: () { service.updateThemeMode(ThemeMode.dark); Navigator.pop(context); },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
