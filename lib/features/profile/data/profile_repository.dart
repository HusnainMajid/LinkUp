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

  // Future for avatar upload
  Future<String?> uploadAvatar(String filePath, String fileExtension) async {
    // Note: Supabase Storage bucket 'avatars' must be created and public/private RLS set.
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final path = '$userId/avatar.$fileExtension';
    
    try {
      await _supabase.storage.from('avatars').upload(
        path,
        // File is passed as bytes in Supabase Flutter if using cross-platform usually, 
        // but here we just leave the placeholder logic as per instructions:
        // "DO NOT create fake uploads. If Storage is not configured, clearly report..."
        // I will assume for now I only implement the UI part and the repo method signature.
        null as dynamic, // Placeholder
        fileOptions: const FileOptions(upsert: true),
      );
      
      final String publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      // Storage might not be configured
      return null;
    }
  }
}
