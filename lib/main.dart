import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/supabase_config.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/notifications/notification_service.dart';
import 'core/settings/settings_service.dart';
import 'features/chat/domain/services/presence_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
  }

  // Initialize Notifications
  await NotificationService().initialize();
  
  // Initialize Presence
  PresenceService().initialize();

  // Initialize Settings
  final settingsService = SettingsService();
  await settingsService.initialize();
  
  runApp(const LinkUpApp());
}

class LinkUpApp extends StatelessWidget {
  const LinkUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: SettingsService().themeMode,
      builder: (context, mode, child) {
        return MaterialApp.router(
          title: 'LinkUp',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}

