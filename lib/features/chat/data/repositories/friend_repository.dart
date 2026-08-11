import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friend_request_model.dart';
import '../../../auth/models/profile_model.dart';

class FriendRepository {
  final _supabase = Supabase.instance.client;

  Future<void> sendFriendRequest(String receiverId) async {
    final senderId = _supabase.auth.currentUser!.id;
    await _supabase.from('friend_requests').upsert({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'status': 'pending',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> respondToFriendRequest(String requestId, bool accept) async {
    await _supabase.from('friend_requests').update({
      'status': accept ? 'accepted' : 'rejected',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }

  Future<void> cancelFriendRequest(String requestId) async {
    await _supabase.from('friend_requests').update({
      'status': 'cancelled',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }

  Future<FriendStatus> getFriendStatus(String otherUserId) async {
    final response = await _supabase.rpc('get_friend_status', params: {
      'other_user_id': otherUserId,
    });

    switch (response) {
      case 'friends': return FriendStatus.friends;
      case 'pending_sent': return FriendStatus.pendingSent;
      case 'pending_received': return FriendStatus.pendingReceived;
      case 'rejected': return FriendStatus.rejected;
      default: return FriendStatus.none;
    }
  }

  Future<List<Profile>> getFriends() async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase
        .from('friend_requests')
        .select('sender_id, receiver_id, sender:sender_id(*), receiver:receiver_id(*)')
        .eq('status', 'accepted')
        .or('sender_id.eq.$userId,receiver_id.eq.$userId');

    return (response as List).map((row) {
      final isSender = row['sender_id'] == userId;
      final profileJson = isSender ? row['receiver'] : row['sender'];
      return Profile.fromJson(profileJson);
    }).toList();
  }

  Future<List<FriendRequest>> getIncomingRequests() async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase
        .from('friend_requests')
        .select('*, sender_profile:sender_id(*)')
        .eq('receiver_id', userId)
        .eq('status', 'pending');

    return (response as List).map((json) => FriendRequest.fromJson(json)).toList();
  }

  Future<List<FriendRequest>> getOutgoingRequests() async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase
        .from('friend_requests')
        .select('*, receiver_profile:receiver_id(*)')
        .eq('sender_id', userId)
        .eq('status', 'pending');

    return (response as List).map((json) => FriendRequest.fromJson(json)).toList();
  }

  Stream<void> subscribeToFriendRequests() {
    final userId = _supabase.auth.currentUser!.id;
    return _supabase
        .from('friend_requests')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', userId)
        .map((_) {
          return;
        });
  }
}
