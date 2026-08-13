import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/models/profile_model.dart';

class ProfileRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Profile?> getCurrentProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    
    return Profile.fromJson(response);
  }

  Future<void> updateProfile(Profile profile) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    // Ensure we are only updating the current user's profile
    if (profile.id != userId) throw Exception('Unauthorized profile update');

    await _supabase
        .from('profiles')
        .update(profile.toJson())
        .eq('id', userId);
  }

  Future<String?> uploadAvatar(File file) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final fileExtension = file.path.split('.').last;
    final path = '$userId/avatar.${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    
    try {
      // 1. Upload the file
      await _supabase.storage.from('avatars').upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: true),
      );
      
      // 2. Get public URL
      final String publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);

      // 3. Update profile with new URL
      await _supabase
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', userId);

      return publicUrl;
    } catch (e) {
      debugPrint('ProfileRepository: Avatar upload failed: $e');
      return null;
    }
  }
}
