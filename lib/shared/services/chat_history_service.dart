import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ai/ai_models.dart';
import '../../core/config/supabase_config.dart';

/// Service for managing chat history persistence
class ChatHistoryService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Singleton
  static final ChatHistoryService _instance = ChatHistoryService._internal();
  factory ChatHistoryService() => _instance;
  ChatHistoryService._internal();

  String? get _userId => SupabaseConfig.currentUser?.id;

  // ============ CONVERSATIONS ============

  /// Create a new conversation
  Future<ChatConversation?> createConversation({
    required CounselingMode mode,
    String? relativeId,
    String? title,
  }) async {
    if (_userId == null) return null;

    try {
      final response = await _supabase.from('chat_conversations').insert({
        'user_id': _userId,
        'mode': mode.value,
        'relative_id': relativeId,
        'title': title,
      }).select().single();

      return ChatConversation.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Get all conversations for user (newest first)
  Future<List<ChatConversation>> getConversations({
    int limit = 50,
    bool includeArchived = false,
  }) async {
    if (_userId == null) return [];

    try {
      final query = _supabase
          .from('chat_conversations')
          .select()
          .eq('user_id', _userId!);

      final filteredQuery = includeArchived
          ? query
          : query.eq('is_archived', false);

      final response = await filteredQuery
          .order('updated_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => ChatConversation.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get a specific conversation by ID
  Future<ChatConversation?> getConversation(String conversationId) async {
    if (_userId == null) return null;

    try {
      final response = await _supabase
          .from('chat_conversations')
          .select()
          .eq('id', conversationId)
          .eq('user_id', _userId!)
          .single();

      return ChatConversation.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Update conversation title
  Future<bool> updateConversationTitle(String conversationId, String title) async {
    if (_userId == null) return false;

    try {
      await _supabase
          .from('chat_conversations')
          .update({'title': title, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', conversationId)
          .eq('user_id', _userId!);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Archive a conversation
  Future<bool> archiveConversation(String conversationId) async {
    if (_userId == null) return false;

    try {
      await _supabase
          .from('chat_conversations')
          .update({'is_archived': true})
          .eq('id', conversationId)
          .eq('user_id', _userId!);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete a conversation (and all its messages)
  Future<bool> deleteConversation(String conversationId) async {
    if (_userId == null) return false;

    try {
      await _supabase
          .from('chat_conversations')
          .delete()
          .eq('id', conversationId)
          .eq('user_id', _userId!);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============ MESSAGES ============

  /// Save a message to a conversation
  Future<ChatMessage?> saveMessage({
    required String conversationId,
    required MessageRole role,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    if (_userId == null) return null;

    try {
      final response = await _supabase.from('chat_messages').insert({
        'conversation_id': conversationId,
        'user_id': _userId,
        'role': role.value,
        'content': content,
        'metadata': metadata ?? {},
      }).select().single();

      return ChatMessage.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Get all messages for a conversation
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    if (_userId == null) return [];

    try {
      final response = await _supabase
          .from('chat_messages')
          .select()
          .eq('conversation_id', conversationId)
          .eq('user_id', _userId!)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => ChatMessage.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete messages from a conversation (for edit/regenerate)
  Future<bool> deleteMessagesFrom(String conversationId, DateTime fromTime) async {
    if (_userId == null) return false;

    try {
      await _supabase
          .from('chat_messages')
          .delete()
          .eq('conversation_id', conversationId)
          .eq('user_id', _userId!)
          .gte('created_at', fromTime.toIso8601String());
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============ MEMORIES ============

  /// Save a new memory
  Future<AIMemory?> saveMemory({
    required AIMemoryCategory category,
    required String content,
    String? relativeId,
    int importance = 5,
    String? sourceConversationId,
  }) async {
    if (_userId == null) return null;

    try {
      final response = await _supabase.from('ai_memories').insert({
        'user_id': _userId,
        'category': category.value,
        'content': content,
        'relative_id': relativeId,
        'importance': importance,
        'source_conversation_id': sourceConversationId,
      }).select().single();

      return AIMemory.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Get all active memories for user (sorted by importance)
  Future<List<AIMemory>> getMemories({int limit = 50}) async {
    if (_userId == null) return [];

    try {
      final response = await _supabase
          .from('ai_memories')
          .select()
          .eq('user_id', _userId!)
          .eq('is_active', true)
          .order('importance', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => AIMemory.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get memories for a specific relative
  Future<List<AIMemory>> getMemoriesForRelative(String relativeId) async {
    if (_userId == null) return [];

    try {
      final response = await _supabase
          .from('ai_memories')
          .select()
          .eq('user_id', _userId!)
          .eq('relative_id', relativeId)
          .eq('is_active', true)
          .order('importance', ascending: false);

      return (response as List)
          .map((json) => AIMemory.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Deactivate a memory
  Future<bool> deactivateMemory(String memoryId) async {
    if (_userId == null) return false;

    try {
      await _supabase
          .from('ai_memories')
          .update({'is_active': false})
          .eq('id', memoryId)
          .eq('user_id', _userId!);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete a memory permanently
  Future<bool> deleteMemory(String memoryId) async {
    if (_userId == null) return false;

    try {
      await _supabase
          .from('ai_memories')
          .delete()
          .eq('id', memoryId)
          .eq('user_id', _userId!);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============ UTILITIES ============

  /// Generate a title for a conversation from the first message
  String generateTitleFromMessage(String content) {
    // Take first 50 characters, trim to last complete word
    if (content.length <= 50) return content;
    final truncated = content.substring(0, 50);
    final lastSpace = truncated.lastIndexOf(' ');
    return lastSpace > 20 ? '${truncated.substring(0, lastSpace)}...' : '$truncated...';
  }
}
