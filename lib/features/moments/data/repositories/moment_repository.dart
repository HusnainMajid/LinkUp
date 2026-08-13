import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/moment_model.dart';

class MomentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  SupabaseClient get supabase => _supabase;

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
    final path = '$userId/$fileName';

    await _supabase.storage.from('moments').upload(path, file);
    
    await _supabase.from('moments').insert({
      'user_id': userId,
      'content': caption,
      'image_url': path,
      'type': 'image',
    });
  }

  Future<void> deleteMoment(String id) async {
    final moment = await _supabase.from('moments').select().eq('id', id).single();
    if (moment['image_url'] != null) {
       await _supabase.storage.from('moments').remove([moment['image_url']]);
    }
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

    final moments = <Moment>[];
    for (var json in response as List) {
      final views = json['moment_views'] as List;
      final isViewed = views.any((v) => v['viewer_id'] == currentUserId);
      final enrichedJson = Map<String, dynamic>.from(json);
      
      if (enrichedJson['type'] == 'image' && enrichedJson['image_url'] != null) {
        try {
          final signedUrl = await _supabase.storage
              .from('moments')
              .createSignedUrl(enrichedJson['image_url'], 3600 * 24);
          enrichedJson['image_url'] = signedUrl;
        } catch (e) {
          debugPrint('MomentRepository: Error generating signed URL: $e');
        }
      }

      enrichedJson['viewer_count'] = views.length;
      enrichedJson['is_viewed'] = isViewed;
      moments.add(Moment.fromJson(enrichedJson));
    }
    return moments;
  }

  Stream<List<Moment>> subscribeToMoments() {
    final controller = StreamController<List<Moment>>();
    
    void fetchData() async {
      try {
        final data = await getActiveMoments();
        if (!controller.isClosed) controller.add(data);
      } catch (e) {
        debugPrint('MomentRepository: Stream fetch error: $e');
      }
    }

    final momentsSub = _supabase
        .from('moments')
        .stream(primaryKey: ['id'])
        .listen((_) => fetchData());

    final viewsSub = _supabase
        .from('moment_views')
        .stream(primaryKey: ['id'])
        .listen((_) => fetchData());

    fetchData(); // Initial fetch

    controller.onCancel = () {
      momentsSub.cancel();
      viewsSub.cancel();
    };
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
