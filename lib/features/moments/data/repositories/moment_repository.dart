import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/moment_model.dart';

class MomentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> createTextMoment(String content, {String? backgroundColor}) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('moments').insert({
      'user_id': userId,
      'content': content,
      'type': 'text',
      'background_color': backgroundColor,
    });
  }

  Future<void> createImageMoment(File file, {String? caption}) async {
    final userId = _supabase.auth.currentUser!.id;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'moments/$userId/$fileName';

    await _supabase.storage.from('moments').upload(path, file);
    final imageUrl = _supabase.storage.from('moments').getPublicUrl(path);

    await _supabase.from('moments').insert({
      'user_id': userId,
      'content': caption,
      'image_url': imageUrl,
      'type': 'image',
    });
  }

  Future<void> deleteMoment(String id) async {
    // Note: Storage cleanup would be ideal here if it's an image moment
    await _supabase.from('moments').delete().eq('id', id);
  }

  Future<List<Moment>> getActiveMoments() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return [];

    final response = await _supabase
        .from('moments')
        .select('*, user:user_id(*), moment_views(viewer_id)')
        .gt('expires_at', DateTime.now().toUtc().toIso8601String())
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      final views = json['moment_views'] as List;
      final isViewed = views.any((v) => v['viewer_id'] == currentUserId);
      final enrichedJson = Map<String, dynamic>.from(json);
      enrichedJson['viewer_count'] = views.length;
      enrichedJson['is_viewed'] = isViewed;
      return Moment.fromJson(enrichedJson);
    }).toList();
  }

  Stream<List<Moment>> subscribeToMoments() {
    final controller = StreamController<List<Moment>>();
    
    void fetchData() async {
      final data = await getActiveMoments();
      if (!controller.isClosed) controller.add(data);
    }

    final subscription = _supabase
        .from('moments')
        .stream(primaryKey: ['id'])
        .listen((_) => fetchData());

    fetchData(); // Initial fetch

    controller.onCancel = () => subscription.cancel();
    return controller.stream;
  }

  Future<void> trackView(String momentId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('moment_views').upsert({
        'moment_id': momentId,
        'viewer_id': userId,
      });
    } catch (e) {
      // Ignore unique constraint errors
      debugPrint('MomentRepository: trackView error: $e');
    }
  }

  Future<List<MomentView>> getMomentViewers(String momentId) async {
    final response = await _supabase
        .from('moment_views')
        .select('*, viewer:viewer_id(*)')
        .eq('moment_id', momentId)
        .order('viewed_at', ascending: false);
    
    return (response as List).map((json) => MomentView.fromJson(json)).toList();
  }
}

// Global debug helper
void debugPrint(String s) => print(s);
