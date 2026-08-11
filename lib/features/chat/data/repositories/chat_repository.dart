import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/models/profile_model.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/message_reaction_model.dart';

class ChatRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
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
      final response = await _supabase.rpc('get_user_conversations_v4');
      if (response == null) return [];
      return (response as List).map((json) => Conversation.fromJson(json)).toList();
    } catch (e) {
      debugPrint('ChatRepository: Error mapping conversations: $e');
      return [];
    }
  }

  Stream<List<Conversation>> subscribeToConversations() {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return Stream.value([]);

    return _supabase
        .from('conversation_members')
        .stream(primaryKey: ['conversation_id', 'user_id'])
        .eq('user_id', currentUserId)
        .asyncMap((_) async => await getUserConversations());
  }

  Stream<void> get globalChatUpdateTrigger {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .map((_) => null);
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

    await _supabase.from('profiles').update({
      'is_online': isOnline,
      'last_seen': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Stream<List<Profile>> subscribeToPresence(String conversationId) {
    return _supabase
        .from('conversation_members')
        .stream(primaryKey: ['conversation_id', 'user_id'])
        .eq('conversation_id', conversationId)
        .asyncMap((members) async {
          final ids = members.map((m) => m['user_id'] as String).toList();
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
          if (messageIds.isEmpty) return [];

          List<MessageReaction> msgReactions = [];
          try {
            final reactionsResponse = await _supabase
                .from('message_reactions')
                .select()
                .inFilter('message_id', messageIds);
            msgReactions = (reactionsResponse as List).map((r) => MessageReaction.fromJson(r)).toList();
          } catch (e) {
            debugPrint('ChatRepository: Error fetching reactions (ensure migration 007 is run): $e');
          }
          
          return data.map((json) {
            final reactions = msgReactions
                .where((r) => r.messageId == json['id'])
                .toList();
            
            final Map<String, dynamic> enrichedJson = Map.from(json);
            // We don't put 'reactions' into json because Message.fromJson handles it differently
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
