import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rxdart/rxdart.dart';
import '../../../auth/models/profile_model.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/message_reaction_model.dart';

class ChatRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  SupabaseClient get supabase => _supabase;
  RealtimeChannel? _typingChannel;


  Future<List<Profile>> searchUsers(String query) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return [];

    final response = await _supabase
        .from('profiles')
        .select()
        .or('full_name.ilike.%$query%,username.ilike.%$query%')
        .neq('id', currentUserId)
        .limit(20);
    
    return (response as List).map((json) => Profile.fromJson(json)).toList();
  }

  Future<List<Profile>> getOnlineUsers() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('is_online', true)
        .neq('id', currentUserId ?? '')
        .limit(10);
    
    return (response as List).map((json) => Profile.fromJson(json)).toList();
  }

  Future<List<Profile>> getRecentlyActiveUsers() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    final response = await _supabase
        .from('profiles')
        .select()
        .neq('id', currentUserId ?? '')
        .order('last_seen', ascending: false)
        .limit(10);
    
    return (response as List).map((json) => Profile.fromJson(json)).toList();
  }

  Future<List<Profile>> getSuggestedUsers() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return [];

    // Get IDs of users who are already friends or have pending requests
    final friendsResponse = await _supabase
        .from('friend_requests')
        .select('sender_id, receiver_id')
        .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
        .neq('status', 'rejected')
        .neq('status', 'cancelled');
    
    final List<String> excludedIds = [currentUserId];
    for (var row in friendsResponse as List) {
      excludedIds.add(row['sender_id']);
      excludedIds.add(row['receiver_id']);
    }

    final response = await _supabase
        .from('profiles')
        .select()
        .not('id', 'in', excludedIds.toSet().toList())
        .limit(10);
    
    return (response as List).map((json) => Profile.fromJson(json)).toList();
  }


  Future<String> getOrCreateDirectConversation(String otherUserId) async {
    try {
      final response = await _supabase.rpc(
        'get_or_create_direct_conversation',
        params: {'other_user_id': otherUserId},
      );
      return response as String;
    } on PostgrestException catch (e) {
      if (e.message.contains('friends')) {
        throw Exception('Users must be friends before starting a conversation.');
      }
      rethrow;
    }
  }

  Future<bool> isStillFriends(String conversationId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return false;

    final conversation = await _supabase
        .from('conversation_members')
        .select('user_id')
        .eq('conversation_id', conversationId);
    
    final members = (conversation as List);
    if (members.length != 2) return true; // Group chat or invalid

    final otherUserId = members.firstWhere((m) => m['user_id'] != currentUserId)['user_id'];
    
    final result = await _supabase.rpc('is_friends', params: {
      'user_a': currentUserId,
      'user_b': otherUserId,
    });
    
    return result as bool;
  }

  Future<List<Conversation>> getUserConversations() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return [];

    try {
      final response = await _supabase.rpc('get_user_conversations_v6');
      if (response == null) return [];
      return (response as List).map((json) => Conversation.fromJson(json)).toList();
    } catch (e) {
      debugPrint('ChatRepository: Error mapping conversations (trying v5 fallback): $e');
      try {
        final response = await _supabase.rpc('get_user_conversations_v5');
        if (response == null) return [];
        return (response as List).map((json) => Conversation.fromJson(json)).toList();
      } catch (e2) {
        debugPrint('ChatRepository: Error in v5 fallback: $e2');
        return [];
      }
    }
  }

  Future<String> createGroup({
    required String name,
    String? avatarUrl,
    required List<String> memberIds,
  }) async {
    final response = await _supabase.rpc('create_group', params: {
      'group_name': name,
      'group_avatar_url': avatarUrl,
      'member_ids': memberIds,
    });
    return response as String;
  }

  Future<void> updateGroupInfo(String groupId, {String? name, String? avatarUrl}) async {
    final updates = <String, dynamic>{'updated_at': DateTime.now().toIso8601String()};
    if (name != null) updates['name'] = name;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    await _supabase.from('conversations').update(updates).eq('id', groupId);
  }

  Future<void> addGroupMembers(String groupId, List<String> userIds) async {
    final members = userIds.map((id) => {
      'conversation_id': groupId,
      'user_id': id,
      'role': 'MEMBER',
    }).toList();

    await _supabase.from('conversation_members').insert(members);
  }

  Future<void> removeGroupMember(String groupId, String userId) async {
    await _supabase
        .from('conversation_members')
        .delete()
        .eq('conversation_id', groupId)
        .eq('user_id', userId);
  }

  Future<void> updateMemberRole(String groupId, String userId, String role) async {
    await _supabase
        .from('conversation_members')
        .update({'role': role})
        .eq('conversation_id', groupId)
        .eq('user_id', userId);
  }

  Future<void> leaveGroup(String groupId) async {
    final userId = _supabase.auth.currentUser!.id;
    await removeGroupMember(groupId, userId);
  }

  Stream<List<Conversation>> subscribeToConversations() {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return Stream.value([]);

    // Listen to changes in conversation members (new chats)
    // AND listen to changes in conversations (updated activity)
    // AND listen to changes in messages (new messages)
    
    final membersStream = _supabase
        .from('conversation_members')
        .stream(primaryKey: ['conversation_id', 'user_id'])
        .eq('user_id', currentUserId);

    final messagesStream = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .limit(1);

    // Combine them into a single update trigger
    return Rx.combineLatest2(
      membersStream,
      messagesStream,
      (_, _) => null,
    ).asyncMap((_) => getUserConversations());
  }

  Stream<void> get globalChatUpdateTrigger {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .map((_) {});
  }

  // Conversation Management Methods (Restored)
  Future<void> togglePin(String conversationId, bool isPinned) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('user_conversation_preferences').upsert({
      'user_id': userId,
      'conversation_id': conversationId,
      'is_pinned': isPinned,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> toggleArchive(String conversationId, bool isArchived) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('user_conversation_preferences').upsert({
      'user_id': userId,
      'conversation_id': conversationId,
      'is_archived': isArchived,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> toggleMute(String conversationId, bool isMuted) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('user_conversation_preferences').upsert({
      'user_id': userId,
      'conversation_id': conversationId,
      'is_muted': isMuted,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> markAsDeleted(String conversationId) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('user_conversation_preferences').upsert({
      'user_id': userId,
      'conversation_id': conversationId,
      'is_deleted': true,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> markAsRead(String conversationId) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('user_conversation_preferences').upsert({
      'user_id': userId,
      'conversation_id': conversationId,
      'last_read_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Stream<Message> subscribeToAllMessages() {
    final currentUserId = _supabase.auth.currentUser?.id;
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(1)
        .map((event) => Message.fromJson(event.first))
        .where((msg) => msg.senderId != currentUserId);
  }

  Profile? getOtherParticipant(Conversation conversation) {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null || conversation.members == null) return null;

    try {
      return conversation.members!.firstWhere((m) => m.id != currentUserId);
    } catch (_) {
      return null;
    }
  }

  Future<Profile?> getUserProfile(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    
    return Profile.fromJson(response);
  }

  // Presence and Typing
  void setTypingStatus(String conversationId, bool isTyping) {
    if (_typingChannel == null) {
      _typingChannel = _supabase.channel('typing:$conversationId');
      _typingChannel!.subscribe();
    }
    
    // Using presence for typing status as a more reliable alternative
    _typingChannel!.track({
      'user_id': _supabase.auth.currentUser?.id,
      'is_typing': isTyping,
    });
  }

  Stream<Map<String, dynamic>> subscribeToTypingStatus(String conversationId) {
    final controller = StreamController<Map<String, dynamic>>();
    final channel = _supabase.channel('typing:$conversationId');
    
    channel.onPresenceSync((payload) {
      final state = channel.presenceState();
      for (var presenceState in state) {
        for (var presence in presenceState.presences) {
          if (presence.payload['is_typing'] == true && presence.payload['user_id'] != _supabase.auth.currentUser?.id) {
            if (!controller.isClosed) {
              controller.add(presence.payload);
            }
          }
        }
      }
    }).subscribe();

    return controller.stream;
  }

  Future<void> updatePresence(bool isOnline) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.rpc('update_user_presence', params: {'online': isOnline});
    } catch (e) {
      debugPrint('ChatRepository: Error updating presence: $e');
    }
  }

  Stream<Profile> subscribeToUserPresence(String userId) {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((event) => Profile.fromJson(event.first));
  }

  Future<List<Map<String, dynamic>>> getCallHistory() async {
    try {
      final response = await _supabase.rpc('get_call_history');
      if (response == null) return [];
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('ChatRepository: Error fetching call history: $e');
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> subscribeToCallHistory() {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return Stream.value([]);

    // Listen to changes in voice_calls involving the current user
    return _supabase
        .from('voice_calls')
        .stream(primaryKey: ['id'])
        .asyncMap((_) => getCallHistory());
  }

  Future<void> clearCallHistory() async {
    try {
      await _supabase.rpc('clear_call_history');
    } catch (e) {
      debugPrint('ChatRepository: Error clearing call history: $e');
    }
  }

  Stream<List<Profile>> subscribeToPresence(String conversationId) {
    // Listen to profile changes for members of this conversation
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .asyncMap((_) async {
          final membersResponse = await _supabase
              .from('conversation_members')
              .select('user_id')
              .eq('conversation_id', conversationId);
          
          final ids = (membersResponse as List).map((m) => m['user_id'] as String).toList();
          if (ids.isEmpty) return [];
          
          final profiles = await _supabase.from('profiles').select().inFilter('id', ids);
          return (profiles as List).map((json) => Profile.fromJson(json)).toList();
        });
  }

  // Messaging Methods
  Future<void> sendMessage({
    required String conversationId,
    required String content,
    String type = 'text',
    String? storagePath,
    String? fileName,
    int? fileSize,
    String? mimeType,
    String? replyToMessageId,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) throw Exception('User session is unavailable.');

    await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': currentUser.id,
      'content': content,
      'message_type': type,
      'storage_path': storagePath,
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'reply_to_message_id': replyToMessageId,
      'delivered_at': DateTime.now().toIso8601String(),
    });

    try {
      await _supabase
          .from('conversations')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', conversationId);
    } catch (e) {
      debugPrint('ChatRepository: Could not update conversation timestamp: $e');
    }
  }

  Stream<List<Message>> subscribeToMessages(String conversationId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .asyncMap((data) async {
          final messageIds = data.map((m) => m['id'] as String).toList();
          final senderIds = data.map((m) => m['sender_id'] as String).toSet().toList();
          if (messageIds.isEmpty) return [];

          List<MessageReaction> msgReactions = [];
          List<Profile> senders = [];
          
          try {
            // Parallel fetch for reactions and sender profiles
            final results = await Future.wait([
              _supabase.from('message_reactions').select().inFilter('message_id', messageIds),
              _supabase.from('profiles').select().inFilter('id', senderIds),
            ]);
            
            msgReactions = (results[0] as List).map((r) => MessageReaction.fromJson(r)).toList();
            senders = (results[1] as List).map((p) => Profile.fromJson(p)).toList();
          } catch (e) {
            debugPrint('ChatRepository: Error enriching messages: $e');
          }
          
          return data.map((json) {
            final reactions = msgReactions
                .where((r) => r.messageId == json['id'])
                .toList();
            
            final sender = senders.firstWhere((p) => p.id == json['sender_id'], orElse: () => Profile(id: json['sender_id']));
            
            final Map<String, dynamic> enrichedJson = Map.from(json);
            enrichedJson['sender_name'] = sender.fullName ?? sender.username ?? 'User';
            
            final message = Message.fromJson(enrichedJson);
            return message.copyWith(reactions: reactions);
          }).toList();
        });
  }

  Future<void> markMessagesAsRead(String conversationId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.rpc('mark_messages_as_read', params: {
        'conv_id': conversationId,
        'user_id': userId,
      });
    } catch (e) {
      debugPrint('ChatRepository: Error calling mark_messages_as_read (migration 007 might be missing): $e');
    }
    
    await markAsRead(conversationId);
  }

  Future<void> editMessage(String messageId, String newContent) async {
    await _supabase.from('messages').update({
      'content': newContent,
      'edited_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', messageId).eq('sender_id', _supabase.auth.currentUser!.id);
  }

  Future<void> deleteMessageForEveryone(String messageId) async {
    await _supabase.from('messages').update({
      'content': 'This message was deleted',
      'deleted_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', messageId).eq('sender_id', _supabase.auth.currentUser!.id);
  }

  Future<void> addReaction(String messageId, String reaction) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('message_reactions').upsert({
      'message_id': messageId,
      'user_id': userId,
      'reaction': reaction,
    });
  }

  Future<void> removeReaction(String messageId) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase
        .from('message_reactions')
        .delete()
        .eq('message_id', messageId)
        .eq('user_id', userId);
  }

  Future<List<Message>> searchMessages(String conversationId, String query) async {
    final response = await _supabase
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .ilike('content', '%$query%')
        .order('created_at', ascending: false);

    return (response as List).map((json) => Message.fromJson(json)).toList();
  }

  void dispose() {
    _typingChannel?.unsubscribe();
  }

  Future<String> getMediaUrl(String path) async {
    return await _supabase.storage.from('chat-media').createSignedUrl(path, 3600);
  }

  Future<void> uploadFile(String bucket, String path, File file) async {
    await _supabase.storage.from(bucket).upload(path, file);
  }
}
