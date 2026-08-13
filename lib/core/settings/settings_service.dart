import 'dart:async';
import 'package:flutter/material.dart';
import '../../features/profile/data/models/settings_model.dart';
import '../../features/profile/data/settings_repository.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  final _repository = SettingsRepository();
  final themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);
  final settings = ValueNotifier<UserSettings?>(null);
  StreamSubscription? _subscription;

  Future<void> initialize() async {
    final initialSettings = await _repository.getSettings();
    if (initialSettings != null) {
      _updateLocalState(initialSettings);
    }
    
    // Subscribe to changes
    _subscription?.cancel();
    _subscription = _repository.subscribeToSettings().listen((updatedSettings) {
      _updateLocalState(updatedSettings);
    });
  }

  void _updateLocalState(UserSettings s) {
    settings.value = s;
    switch (s.themeMode) {
      case 'light':
        themeMode.value = ThemeMode.light;
        break;
      case 'dark':
        themeMode.value = ThemeMode.dark;
        break;
      default:
        themeMode.value = ThemeMode.system;
    }
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    if (settings.value == null) return;
    
    String modeStr = 'system';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';

    final updated = settings.value!.copyWith(themeMode: modeStr, updatedAt: DateTime.now());
    await _repository.updateSettings(updated);
  }

  Future<void> updatePrivacy(String key, bool value) async {
    if (settings.value == null) return;
    
    UserSettings updated;
    switch (key) {
      case 'show_online_status':
        updated = settings.value!.copyWith(showOnlineStatus: value);
        break;
      case 'show_last_seen':
        updated = settings.value!.copyWith(showLastSeen: value);
        break;
      case 'allow_discovery':
        updated = settings.value!.copyWith(allowDiscovery: value);
        break;
      default:
        return;
    }
    await _repository.updateSettings(updated.copyWith(updatedAt: DateTime.now()));
  }

  Future<void> updateNotification(String key, bool value) async {
    if (settings.value == null) return;
    
    UserSettings updated;
    switch (key) {
      case 'notify_messages':
        updated = settings.value!.copyWith(notifyMessages: value);
        break;
      case 'notify_calls':
        updated = settings.value!.copyWith(notifyCalls: value);
        break;
      case 'notify_moments':
        updated = settings.value!.copyWith(notifyMoments: value);
        break;
      default:
        return;
    }
    await _repository.updateSettings(updated.copyWith(updatedAt: DateTime.now()));
  }

  void dispose() {
    _subscription?.cancel();
  }
}
