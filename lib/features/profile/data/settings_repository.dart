import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/settings_model.dart';

class SettingsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<UserSettings?> getSettings() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('user_settings')
        .select()
        .eq('user_id', userId)
        .single();
    
    return UserSettings.fromJson(response);
  }

  Future<void> updateSettings(UserSettings settings) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    await _supabase
        .from('user_settings')
        .update(settings.toJson())
        .eq('user_id', userId);
  }

  Stream<UserSettings> subscribeToSettings() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return _supabase
        .from('user_settings')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((event) => UserSettings.fromJson(event.first));
  }
}
