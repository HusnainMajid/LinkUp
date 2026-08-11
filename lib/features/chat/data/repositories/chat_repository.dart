import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/models/profile_model.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ChatRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

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
    final response = await _supabase.rpc(
      'get_or_create_direct_conversation',
      params: {'other_user_id': otherUserId},
    );
    return response as String;
  }

  Future<List<Conversation>> getUserConversations() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return [];

    try {
      // Use the latest RPC version (v4 includes storage fields)
      final response = await _supabase.rpc('get_user_conversations_v4');
      
      if (response == null) return [];

      final List<Conversation> conversations = (response as List).map((json) {
        return Conversation.fromJson(json);
      }).toList();
      
      return conversations;
    } catch (e) {
      debugPrint('ChatRepository: Error mapping conversations: $e');
      return [];
    }
  }

  Stream<List<Conversation>> subscribeToConversations() {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return Stream.value([]);

    // Listen to changes in ANY of these tables:
    // 1. conversation_members (when a new chat is started)
    // 2. messages (when a message is sent/received, to update preview and order)
    // 3. user_conversation_preferences (when a chat is pinned/archived)
    
    // We combine these into a single trigger stream
    return _supabase
        .from('conversation_members')
        .stream(primaryKey: ['conversation_id', 'user_id'])
        .eq('user_id', currentUserId)
        .asyncMap((_) => getUserConversations());
  }

  // We need a better way to trigger updates on message receive.
  // The current .stream() on membership only triggers when a membership ROW changes.
  // Instead, let's use a real-time channel to listen for any message in user's conversations.

  // A more aggressive global listener that forces the chat list to update on any message
  Stream<void> get globalChatUpdateTrigger {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .map((_) => null);
  }

  // Conversation Management Methods
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

  // Messaging Methods
  Future<void> sendMessage({
    required String conversationId,
    required String content,
    String type = 'text',
    String? storagePath,
    String? fileName,
    int? fileSize,
    String? mimeType,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      debugPrint('Error: User session is unavailable.');
      throw Exception('User session is unavailable.');
    }

    try {
      await _supabase.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': currentUser.id,
        'content': content,
        'message_type': type,
        'storage_path': storagePath,
        'file_name': fileName,
        'file_size': fileSize,
        'mime_type': mimeType,
      });
      
      // Update conversation's updated_at
      try {
        await _supabase
            .from('conversations')
            .update({'updated_at': DateTime.now().toIso8601String()})
            .eq('id', conversationId);
      } catch (_) {}
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  Future<String> uploadChatMedia({
    required String conversationId,
    required String filePath,
    required String fileName,
    required String bucket,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final path = '$conversationId/$currentUserId/images/$uniqueName';

    // File handling is done in the UI layer for Step 7 to keep the repo clean
    return path;
  }

  // To be used with real File objects in implementation
  Future<String> uploadFile(String bucket, String path, dynamic file) async {
    return await _supabase.storage.from(bucket).upload(path, file);
  }

  Future<String> getMediaUrl(String path) async {
    // Because it is a private bucket, we use createSignedUrl
    return await _supabase.storage.from('chat-media').createSignedUrl(path, 3600);
  }

  Stream<List<Message>> subscribeToMessages(String conversationId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Message.fromJson(json)).toList());
  }

  Future<List<Message>> getMessages(String conversationId, {int limit = 50}) async {
    final response = await _supabase
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List).map((json) => Message.fromJson(json)).toList();
  }

  Future<void> deleteMessage(String messageId) async {
    await _supabase
        .from('messages')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', messageId);
  }

  Future<void> clearChat(String conversationId) async {
    // For now, we perform a global delete for the user as per instructions "implement safely"
    // In a production app, we'd use a messages_deleted_for_users table
    await _supabase
        .from('messages')
        .delete()
        .eq('conversation_id', conversationId)
        .eq('sender_id', _supabase.auth.currentUser!.id);
  }

  Future<void> blockUser(String userId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    await _supabase.from('blocked_users').insert({
      'blocker_id': currentUserId,
      'blocked_id': userId,
    });
  }

  Future<void> reportUser({
    required String reportedUserId,
    required String conversationId,
    required String reason,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    await _supabase.from('reports').insert({
      'reporter_id': currentUserId,
      'reported_user_id': reportedUserId,
      'conversation_id': conversationId,
      'reason': reason,
    });
  }
}
