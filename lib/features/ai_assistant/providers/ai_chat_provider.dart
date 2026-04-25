import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/ai/ai_models.dart';
import '../../../core/ai/ai_service.dart';
import '../../../core/ai/ai_prompts.dart';
import '../../../core/ai/deepseek_ai_service.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/services/ai_config_service.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/services/chat_history_service.dart';
import '../../family_tree/providers/family_graph_providers.dart';
import '../../family_tree/services/family_graph_service.dart';
import '../../home/providers/home_providers.dart';

/// Provider for AI service instance
final aiServiceProvider = Provider<AIService>((ref) {
  return DeepSeekAIService();
});

/// Provider for chat history service
final chatHistoryServiceProvider = Provider<ChatHistoryService>((ref) {
  return ChatHistoryService();
});

/// Rahim-scoped relatives for AI context.
///
/// Non-autoDispose wrapper over [viewerFilteredRelativesProvider] so data
/// stays warm for [aiChatProvider]'s `ref.read()` one-shot reads.
final aiRelativesProvider = Provider<AsyncValue<List<Relative>>>((ref) {
  return ref.watch(viewerFilteredRelativesProvider);
});

/// Perspective-aware relationship labels for display.
///
/// In family group mode, computes labels like "عمي" instead of "عم/خال"
/// using [FamilyGraphService.getLabelForViewer].
/// Returns empty map in personal mode (arabicName is already correct).
final perspectiveLabelsProvider = Provider<Map<String, String>>((ref) {
  final relatives = ref.watch(viewerFilteredRelativesProvider).valueOrNull ?? [];
  final groupInfo = ref.watch(userFamilyGroupProvider).valueOrNull;

  if (groupInfo == null || groupInfo.nodeId == null || relatives.isEmpty) {
    return {};
  }

  final graph = ref.watch(sharedFamilyGraphProvider((
    groupId: groupInfo.groupId,
    viewerNodeId: groupInfo.nodeId,
  )));

  if (graph == null) return {};

  final enriched = FamilyGraphService.enrichAllSiblingEdges(graph);
  final relativesMap = {for (final r in relatives) r.id: r};

  final labels = <String, String>{};
  for (final r in relatives) {
    final label = FamilyGraphService.getLabelForViewer(
      graph: enriched,
      viewerId: groupInfo.nodeId!,
      targetId: r.id,
      relativesMap: relativesMap,
    );
    if (label.isNotEmpty) {
      labels[r.id] = label;
    }
  }
  return labels;
});

/// Provider for AI memories
final aiMemoriesProvider = FutureProvider<List<AIMemory>>((ref) async {
  final chatHistoryService = ref.watch(chatHistoryServiceProvider);
  return chatHistoryService.getMemories();
});

/// Provider for chat conversation history (auto-refresh on changes)
final chatHistoryProvider = FutureProvider.autoDispose<List<ChatConversation>>((ref) async {
  final chatHistoryService = ref.watch(chatHistoryServiceProvider);
  return chatHistoryService.getConversations();
});

/// Callback type for refreshing chat history
typedef RefreshHistoryCallback = void Function();

/// Provider for managing chat state
final aiChatProvider =
    StateNotifierProvider.autoDispose<AIChatNotifier, AIChatState>((ref) {
  final aiService = ref.watch(aiServiceProvider);
  final chatHistoryService = ref.watch(chatHistoryServiceProvider);

  // Use read instead of watch - we only need initial values for context
  // Watching these causes provider rebuild when invalidated, losing chat state
  final relatives = ref.read(viewerFilteredRelativesProvider).valueOrNull ?? [];
  final memories = ref.read(aiMemoriesProvider).valueOrNull ?? [];

  // Use pre-computed perspective labels from shared provider
  final relationshipLabels = ref.read(perspectiveLabelsProvider);

  return AIChatNotifier(
    aiService: aiService,
    chatHistoryService: chatHistoryService,
    allRelatives: relatives,
    memories: memories,
    relationshipLabels: relationshipLabels,
    onHistoryChanged: () {
      ref.invalidate(chatHistoryProvider);
      ref.invalidate(aiMemoriesProvider);
    },
  );
});

/// Current selected counseling mode
final counselingModeProvider = StateProvider<CounselingMode>((ref) {
  return CounselingMode.general;
});

/// Dynamic counseling modes from admin config (with fallback)
/// Returns a list of mode configs for UI display
final dynamicCounselingModesProvider = Provider<List<AICounselingModeConfig>>((ref) {
  final config = AIConfigService.instance;
  if (config.isLoaded) {
    return config.counselingModes;
  }
  return AICounselingModeConfig.fallbackModes();
});

/// Optional relative context for the chat
final chatRelativeContextProvider = StateProvider<Relative?>((ref) {
  return null;
});

/// AI Chat State
class AIChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isStreaming;
  final String? error;
  final String currentStreamContent;
  final ChatConversation? conversation;
  final bool isSaving;
  final int memorySavedCount; // Number of memories saved in last extraction

  const AIChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isStreaming = false,
    this.error,
    this.currentStreamContent = '',
    this.conversation,
    this.isSaving = false,
    this.memorySavedCount = 0,
  });

  AIChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isStreaming,
    String? error,
    String? currentStreamContent,
    ChatConversation? conversation,
    bool? isSaving,
    int? memorySavedCount,
  }) {
    return AIChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      error: error,
      currentStreamContent: currentStreamContent ?? this.currentStreamContent,
      conversation: conversation ?? this.conversation,
      isSaving: isSaving ?? this.isSaving,
      memorySavedCount: memorySavedCount ?? this.memorySavedCount,
    );
  }
}

/// AI Chat Notifier with persistence and full context
class AIChatNotifier extends StateNotifier<AIChatState> {
  final AIService _aiService;
  final ChatHistoryService _chatHistoryService;
  final List<Relative> _allRelatives;
  final List<AIMemory> _memories;
  final Map<String, String> _relationshipLabels;
  final RefreshHistoryCallback? _onHistoryChanged;
  final _uuid = const Uuid();

  AIChatNotifier({
    required AIService aiService,
    required ChatHistoryService chatHistoryService,
    required List<Relative> allRelatives,
    required List<AIMemory> memories,
    Map<String, String> relationshipLabels = const {},
    RefreshHistoryCallback? onHistoryChanged,
  })  : _aiService = aiService,
        _chatHistoryService = chatHistoryService,
        _allRelatives = allRelatives,
        _memories = memories,
        _relationshipLabels = relationshipLabels,
        _onHistoryChanged = onHistoryChanged,
        super(const AIChatState());

  /// Start a new conversation (creates in Supabase)
  Future<void> startNewConversation({
    required CounselingMode mode,
    Relative? relativeContext,
  }) async {
    // Create conversation in Supabase
    final conversation = await _chatHistoryService.createConversation(
      mode: mode,
      relativeId: relativeContext?.id,
    );

    // Check if disposed after async operation
    if (!mounted) return;

    if (conversation != null) {
      state = AIChatState(conversation: conversation);
      _onHistoryChanged?.call();
    } else {
      // Fallback to local-only conversation
      final userId = SupabaseConfig.currentUser?.id ?? 'anonymous';
      final localConversation = ChatConversation(
        id: _uuid.v4(),
        userId: userId,
        mode: mode,
        relativeId: relativeContext?.id,
        createdAt: DateTime.now(),
      );
      state = AIChatState(conversation: localConversation);
    }
  }

  /// Create conversation lazily if it doesn't exist (for first message)
  Future<void> _createConversationIfNeeded({
    required CounselingMode mode,
    Relative? relativeContext,
  }) async {
    if (state.conversation != null) return;

    final conversation = await _chatHistoryService.createConversation(
      mode: mode,
      relativeId: relativeContext?.id,
    );

    if (!mounted) return;

    if (conversation != null) {
      state = state.copyWith(conversation: conversation);
      _onHistoryChanged?.call();
    } else {
      // Fallback to local-only conversation
      final userId = SupabaseConfig.currentUser?.id ?? 'anonymous';
      state = state.copyWith(
        conversation: ChatConversation(
          id: _uuid.v4(),
          userId: userId,
          mode: mode,
          relativeId: relativeContext?.id,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  /// Load an existing conversation from history
  Future<void> loadConversation(String conversationId) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);

    try {
      final conversation = await _chatHistoryService.getConversation(conversationId);
      if (!mounted) return;

      if (conversation == null) {
        state = state.copyWith(isLoading: false, error: 'المحادثة غير موجودة');
        return;
      }

      final messages = await _chatHistoryService.getMessages(conversationId);
      if (!mounted) return;

      state = AIChatState(
        conversation: conversation,
        messages: messages,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: 'فشل تحميل المحادثة');
    }
  }

  /// Send a message and get AI response (with persistence)
  Future<void> sendMessage(
    String content, {
    CounselingMode mode = CounselingMode.general,
    Relative? relativeContext,
  }) async {
    if (content.trim().isEmpty || !mounted) return;

    final userId = SupabaseConfig.currentUser?.id ?? 'anonymous';
    final conversationId = state.conversation?.id ?? _uuid.v4();

    // Create user message
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      userId: userId,
      role: MessageRole.user,
      content: content.trim(),
      createdAt: DateTime.now(),
    );

    // Update state with user message
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    // Save user message to Supabase (async, don't wait)
    _saveMessageAsync(userMessage);

    // Update conversation title if this is the first message
    if (state.messages.length == 1 && state.conversation != null) {
      final title = _chatHistoryService.generateTitleFromMessage(content);
      _chatHistoryService.updateConversationTitle(conversationId, title);
    }

    try {
      // Build system prompt with FULL context (all relatives + memories)
      final systemPrompt = AIPrompts.buildChatSystemPrompt(
        mode: mode,
        relative: relativeContext,
        allRelatives: _allRelatives,
        memories: _memories,
        relationshipLabels: _relationshipLabels.isNotEmpty ? _relationshipLabels : null,
      );

      // Get AI parameters from admin config
      final aiParams = AIConfigService.instance.getParametersFor('chat');

      // Get AI response
      final response = await _aiService.getChatCompletion(
        messages: state.messages,
        systemPrompt: systemPrompt,
        temperature: aiParams.temperature,
        maxTokens: aiParams.maxTokens,
      );

      if (!mounted) return;

      // Create assistant message
      final assistantMessage = ChatMessage(
        id: _uuid.v4(),
        conversationId: conversationId,
        userId: userId,
        role: MessageRole.assistant,
        content: response,
        createdAt: DateTime.now(),
      );

      // Update state with assistant message
      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
      );

      // Save assistant message to Supabase (async)
      _saveMessageAsync(assistantMessage);
    } on AIServiceException catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'حدث خطأ غير متوقع. حاول مرة أخرى.',
      );
    }
  }

  /// Send message with streaming response
  Future<void> sendMessageStreaming(
    String content, {
    CounselingMode mode = CounselingMode.general,
    Relative? relativeContext,
  }) async {
    if (content.trim().isEmpty || !mounted) return;

    // Set loading state immediately so UI transitions from empty state
    state = state.copyWith(isLoading: true, error: null);

    // Create conversation lazily if it doesn't exist
    if (state.conversation == null) {
      await _createConversationIfNeeded(mode: mode, relativeContext: relativeContext);
      if (!mounted) return;
    }

    final userId = SupabaseConfig.currentUser?.id ?? 'anonymous';
    final conversationId = state.conversation?.id ?? _uuid.v4();

    // Create user message
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      userId: userId,
      role: MessageRole.user,
      content: content.trim(),
      createdAt: DateTime.now(),
    );

    // Update state with user message
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: false,
      isStreaming: true,
      currentStreamContent: '',
      error: null,
    );

    // Save user message (async)
    _saveMessageAsync(userMessage);

    // Update conversation title if first message
    if (state.messages.length == 1 && state.conversation != null) {
      _updateConversationTitleAsync(conversationId, content);
    }

    try {
      // Build system prompt with full context
      final systemPrompt = AIPrompts.buildChatSystemPrompt(
        mode: mode,
        relative: relativeContext,
        allRelatives: _allRelatives,
        memories: _memories,
        relationshipLabels: _relationshipLabels.isNotEmpty ? _relationshipLabels : null,
      );

      // Get AI parameters from admin config
      final aiParams = AIConfigService.instance.getParametersFor('chat');

      // Stream AI response
      final stream = _aiService.streamChatCompletion(
        messages: state.messages,
        systemPrompt: systemPrompt,
        temperature: aiParams.temperature,
        maxTokens: aiParams.maxTokens,
      );

      String fullContent = '';

      await for (final chunk in stream) {
        if (!mounted) return;

        if (chunk.error != null) {
          state = state.copyWith(
            isStreaming: false,
            error: chunk.error,
          );
          return;
        }

        fullContent += chunk.content;
        state = state.copyWith(currentStreamContent: fullContent);

        if (chunk.isDone) {
          // Create final assistant message
          final assistantMessage = ChatMessage(
            id: _uuid.v4(),
            conversationId: conversationId,
            userId: userId,
            role: MessageRole.assistant,
            content: fullContent,
            createdAt: DateTime.now(),
          );

          state = state.copyWith(
            messages: [...state.messages, assistantMessage],
            isStreaming: false,
            currentStreamContent: '',
          );

          // Save assistant message (async)
          _saveMessageAsync(assistantMessage);

          // Memory extraction disabled — Memory Viewer was deleted in Phase 0; collecting without surfacing is privacy debt.
        }
      }
    } on AIServiceException catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isStreaming: false,
        error: e.message,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isStreaming: false,
        error: 'حدث خطأ غير متوقع. حاول مرة أخرى.',
      );
    }
  }

  /// Save message to Supabase asynchronously
  Future<void> _saveMessageAsync(ChatMessage message) async {
    if (!mounted) return;
    try {
      await _chatHistoryService.saveMessage(
        conversationId: message.conversationId,
        role: message.role,
        content: message.content,
        metadata: message.metadata,
      );
    } catch (e) {
      // Silent fail - message is still in local state
    }
  }

  /// Update conversation title asynchronously with intelligent naming
  Future<void> _updateConversationTitleAsync(String conversationId, String firstMessage) async {
    if (!mounted) return;
    try {
      final title = _generateSmartTitle(firstMessage);
      await _chatHistoryService.updateConversationTitle(conversationId, title);
      _onHistoryChanged?.call();
    } catch (e) {
      // Silent fail
    }
  }

  /// Generate a smart title from the first message
  String _generateSmartTitle(String content) {
    final trimmed = content.trim().toLowerCase();
    final original = content.trim();

    // Detect greetings and give them descriptive titles
    final greetings = [
      'السلام عليكم',
      'سلام عليكم',
      'مرحبا',
      'مرحباً',
      'اهلا',
      'أهلا',
      'اهلين',
      'أهلين',
      'هلا',
      'هاي',
      'صباح الخير',
      'مساء الخير',
      'كيف الحال',
      'كيفك',
      'شلونك',
      'hi',
      'hello',
      'hey',
    ];

    for (final greeting in greetings) {
      if (trimmed == greeting || trimmed.startsWith('$greeting ') || trimmed.startsWith('$greeting،')) {
        return 'محادثة جديدة';
      }
    }

    // Detect short generic messages
    if (original.length <= 10 && !original.contains('؟')) {
      return 'محادثة جديدة';
    }

    // Remove common question starters for cleaner titles
    final cleanedContent = original
        .replaceFirst(RegExp(r'^(كيف|ما هي|ما هو|هل|لماذا|أين|متى|من)\s+'), '')
        .replaceFirst(RegExp(r'^(ممكن|أريد|أحتاج|ساعدني|أرجو)\s+'), '');

    // If it's a question, keep the question mark context
    final isQuestion = original.contains('؟') || original.endsWith('?');

    // Take first meaningful part (up to 40 chars)
    String title;
    if (cleanedContent.length <= 40) {
      title = cleanedContent;
    } else {
      // Find a natural break point
      final breakPoints = [' ', '،', '؟', '.', '!'];
      int breakIndex = 40;

      for (int i = 35; i < 45 && i < cleanedContent.length; i++) {
        if (breakPoints.contains(cleanedContent[i])) {
          breakIndex = i;
          break;
        }
      }

      title = cleanedContent.substring(0, breakIndex).trim();
      if (!title.endsWith('؟') && !title.endsWith('.') && !title.endsWith('!')) {
        title = '$title...';
      }
    }

    // Add question indicator if original was a question but title lost it
    if (isQuestion && !title.contains('؟') && !title.contains('?')) {
      title = '$title؟';
    }

    return title.isEmpty ? 'محادثة جديدة' : title;
  }

  /// Clear the current conversation
  void clearConversation() {
    state = const AIChatState();
  }

  /// Clear any error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear memory saved indicator
  void clearMemoryIndicator() {
    state = state.copyWith(memorySavedCount: 0);
  }

  /// Edit a user message and regenerate the AI response
  Future<void> editAndResend(
    String messageId,
    String newContent, {
    CounselingMode mode = CounselingMode.general,
    Relative? relativeContext,
  }) async {
    if (newContent.trim().isEmpty || !mounted) return;

    // Find the message index
    final messageIndex = state.messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;

    // Keep only messages before the edited one
    final messagesBeforeEdit = state.messages.sublist(0, messageIndex);

    // Update state with truncated messages
    state = state.copyWith(messages: messagesBeforeEdit);

    // Send the new message
    await sendMessage(newContent, mode: mode, relativeContext: relativeContext);
  }

  /// Regenerate the last AI response
  Future<void> regenerateLastResponse({
    CounselingMode mode = CounselingMode.general,
    Relative? relativeContext,
  }) async {
    if (state.messages.isEmpty || !mounted) return;

    // Find the last user message
    String? lastUserContent;
    int removeFromIndex = state.messages.length;

    for (int i = state.messages.length - 1; i >= 0; i--) {
      final message = state.messages[i];
      if (message.role == MessageRole.user) {
        lastUserContent = message.content;
        removeFromIndex = i;
        break;
      }
    }

    if (lastUserContent == null) return;

    // Keep only messages before the last user message
    final messagesBeforeLastUser = state.messages.sublist(0, removeFromIndex);

    // Update state with truncated messages
    state = state.copyWith(messages: messagesBeforeLastUser);

    // Resend the last user message
    await sendMessage(
      lastUserContent,
      mode: mode,
      relativeContext: relativeContext,
    );
  }

  /// Get a specific message by ID
  ChatMessage? getMessageById(String messageId) {
    try {
      return state.messages.firstWhere((m) => m.id == messageId);
    } catch (_) {
      return null;
    }
  }

  /// Delete current conversation
  Future<bool> deleteConversation() async {
    if (state.conversation == null || !mounted) return false;
    final success = await _chatHistoryService.deleteConversation(state.conversation!.id);
    if (success && mounted) {
      state = const AIChatState();
      _onHistoryChanged?.call();
    }
    return success;
  }

  /// Archive current conversation
  Future<bool> archiveConversation() async {
    if (state.conversation == null || !mounted) return false;
    final success = await _chatHistoryService.archiveConversation(state.conversation!.id);
    if (success) {
      _onHistoryChanged?.call();
    }
    return success;
  }

  /// Save a memory from the current conversation
  Future<void> saveMemory({
    required AIMemoryCategory category,
    required String content,
    String? relativeId,
    int importance = 5,
  }) async {
    if (!mounted) return;
    await _chatHistoryService.saveMemory(
      category: category,
      content: content,
      relativeId: relativeId,
      importance: importance,
      sourceConversationId: state.conversation?.id,
    );
  }
}

/// Suggested prompts for each mode - FALLBACK (used when admin config not loaded)
const Map<String, List<String>> _fallbackSuggestedPrompts = {
  'general': [
    'كيف أقوي علاقتي بعائلتي؟',
    'ما أهمية صلة الرحم؟',
    'كيف أتواصل مع أقاربي البعيدين؟',
    'اقترح لي أفكار لقضاء وقت مع عائلتي',
  ],
  'relationship': [
    'كيف أحسن علاقتي بوالديّ؟',
    'كيف أتعامل مع أخي/أختي المختلف عني؟',
    'كيف أحافظ على علاقتي بأبناء عمي؟',
    'نصائح للتقرب من الأقارب كبار السن',
  ],
  'conflict': [
    'كيف أصلح بين أفراد عائلتي؟',
    'كيف أتعامل مع قريب مسيء؟',
    'كيف أعتذر لقريب أخطأت بحقه؟',
    'كيف أتجاوز خلاف قديم مع قريب؟',
  ],
  'communication': [
    'كيف أبدأ حديثاً مع قريب لم أره منذ فترة؟',
    'كيف أطلب حاجة من قريب بطريقة لبقة؟',
    'كيف أتحدث مع قريب عن موضوع حساس؟',
    'كيف أعبر عن مشاعري لعائلتي؟',
  ],
};

/// Suggested prompts provider - uses dynamic config from admin panel (with fallback)
final suggestedPromptsProvider = Provider<List<String>>((ref) {
  final mode = ref.watch(counselingModeProvider);
  final modeKey = mode.name;

  // Try to get prompts from admin config
  final config = AIConfigService.instance;
  if (config.isLoaded) {
    final dynamicPrompts = config.getSuggestedPromptsForMode(modeKey);
    if (dynamicPrompts.isNotEmpty) {
      return dynamicPrompts.map((p) => p.promptAr).toList();
    }
  }

  // Fallback to hardcoded prompts
  return _fallbackSuggestedPrompts[modeKey] ?? _fallbackSuggestedPrompts['general']!;
});
