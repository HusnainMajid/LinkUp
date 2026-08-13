import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ai_models.dart';

class AIRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<AIConversation>> getConversations() async {
    final response = await _supabase
        .from('ai_conversations')
        .select()
        .order('updated_at', ascending: false);
    
    return (response as List).map((json) => AIConversation.fromJson(json)).toList();
  }

  Future<AIConversation> createConversation(String title) async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase.from('ai_conversations').insert({
      'user_id': userId,
      'title': title,
    }).select().single();
    
    return AIConversation.fromJson(response);
  }

  Future<void> deleteConversation(String id) async {
    await _supabase.from('ai_conversations').delete().eq('id', id);
  }

  Future<List<AIMessage>> getMessages(String conversationId) async {
    final response = await _supabase
        .from('ai_messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
    
    return (response as List).map((json) => AIMessage.fromJson(json)).toList();
  }

  Future<AIMessage> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase.from('ai_messages').insert({
      'conversation_id': conversationId,
      'user_id': userId,
      'role': 'user',
      'content': content,
    }).select().single();

    // Update conversation timestamp
    await _supabase.from('ai_conversations').update({
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', conversationId);

    return AIMessage.fromJson(response);
  }

  Future<String> getAIResponse({
    required String conversationId,
    required String prompt,
    List<AIMessage>? history,
    bool saveToHistory = true,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'linkup-ai',
        body: {
          'conversationId': conversationId,
          'prompt': prompt,
          'history': history?.map((m) => {'role': m.role, 'content': m.content}).toList(),
        },
      );

      if (response.status != 200) {
        final errorData = response.data;
        String errorMessage = 'AI assistant is currently unavailable.';
        if (errorData != null && errorData is Map) {
          errorMessage = errorData['error'] ?? errorMessage;
        }
        throw Exception(errorMessage);
      }


      final data = response.data;
      if (data == null || data['content'] == null) {
        throw Exception('AI returned an empty response.');
      }
      
      final String aiContent = data['content'];


      if (saveToHistory) {
        // Save assistant message to DB
        await _supabase.from('ai_messages').insert({
          'conversation_id': conversationId,
          'user_id': _supabase.auth.currentUser!.id,
          'role': 'assistant',
          'content': aiContent,
        });
      }

      return aiContent;
    } catch (e) {
      throw Exception('Failed to get AI response: $e');
    }
  }


  Stream<List<AIConversation>> subscribeToConversations() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return _supabase
        .from('ai_conversations')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('updated_at', ascending: false)
        .map((event) => event.map((json) => AIConversation.fromJson(json)).toList());
  }
}
