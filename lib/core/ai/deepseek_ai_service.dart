import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/relative_model.dart';
import '../services/app_logger_service.dart';
import 'ai_models.dart';
import 'ai_prompts.dart';
import 'ai_service.dart';

/// DeepSeek AI Service Implementation
/// Uses DeepSeek API via Supabase Edge Function proxy for security
class DeepSeekAIService implements AIService {
  static DeepSeekAIService? _instance;
  final AppLoggerService _logger = AppLoggerService();
  final SupabaseClient _supabase = Supabase.instance.client;

  // Edge function endpoint (proxy to DeepSeek)
  static const String _edgeFunctionName = 'deepseek-proxy';

  factory DeepSeekAIService() => _instance ??= DeepSeekAIService._internal();
  DeepSeekAIService._internal();

  @override
  Stream<AIStreamChunk> streamChatCompletion({
    required List<ChatMessage> messages,
    required String systemPrompt,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    try {
      // For now, use non-streaming and yield the result
      // TODO: Implement SSE streaming when edge function is ready
      final response = await getChatCompletion(
        messages: messages,
        systemPrompt: systemPrompt,
        temperature: temperature,
        maxTokens: maxTokens,
      );

      // Simulate GPT-like streaming by yielding word by word
      final words = _tokenizeForStreaming(response);
      for (final word in words) {
        yield AIStreamChunk(content: word);
        // Variable delay based on content
        final delay = _getStreamingDelay(word);
        await Future.delayed(Duration(milliseconds: delay));
      }

      yield AIStreamChunk(content: '', isDone: true);
    } on AIServiceException catch (e) {
      // Use the user-friendly message from AIServiceException
      yield AIStreamChunk(content: '', isDone: true, error: e.message);
    } catch (e) {
      // Fallback for unexpected errors
      yield AIStreamChunk(
        content: '',
        isDone: true,
        error: 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.',
      );
    }
  }

  @override
  Future<String> getChatCompletion({
    required List<ChatMessage> messages,
    required String systemPrompt,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    try {
      final formattedMessages = [
        {'role': 'system', 'content': systemPrompt},
        ...messages.map((m) => m.toApiFormat()),
      ];

      final response = await _supabase.functions.invoke(
        _edgeFunctionName,
        body: {
          'messages': formattedMessages,
          'temperature': temperature,
          'max_tokens': maxTokens,
        },
      );

      if (response.status != 200) {
        throw AIServiceException(
          _getErrorMessage(response.status),
          code: response.status.toString(),
        );
      }

      final data = response.data as Map<String, dynamic>;
      final content = data['content'] as String? ?? '';

      // Handle empty response - throw error instead of returning blank
      if (content.trim().isEmpty) {
        throw AIServiceException(
          'لم يتمكن المساعد من الرد. يرجى إعادة صياغة السؤال.',
          code: 'EMPTY_RESPONSE',
        );
      }

      return content;
    } catch (e, stackTrace) {
      _logger.error(
        'DeepSeek API error',
        category: LogCategory.network,
        tag: 'DeepSeekAIService',
        metadata: {'error': e.toString()},
        stackTrace: stackTrace,
      );

      if (e is AIServiceException) rethrow;

      // Handle FunctionException from Supabase
      final errorStr = e.toString();
      if (errorStr.contains('402') || errorStr.contains('Payment Required')) {
        throw AIServiceException(
          'رصيد خدمة الذكاء الاصطناعي غير كافٍ. يرجى المحاولة لاحقاً.',
          code: '402',
          originalError: e,
        );
      }
      if (errorStr.contains('429') || errorStr.contains('Too Many Requests')) {
        throw AIServiceException(
          'تم تجاوز الحد الأقصى للطلبات. يرجى المحاولة بعد قليل.',
          code: '429',
          originalError: e,
        );
      }
      if (errorStr.contains('503') || errorStr.contains('Service Unavailable')) {
        throw AIServiceException(
          'الخدمة غير متاحة حالياً. يرجى المحاولة لاحقاً.',
          code: '503',
          originalError: e,
        );
      }

      throw AIServiceException(
        'حدث خطأ في الاتصال. يرجى التحقق من الإنترنت والمحاولة مرة أخرى.',
        originalError: e,
      );
    }
  }

  /// Get user-friendly Arabic error message based on HTTP status code
  String _getErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'طلب غير صالح. يرجى المحاولة مرة أخرى.';
      case 401:
        return 'خطأ في المصادقة. يرجى تسجيل الدخول مرة أخرى.';
      case 402:
        return 'رصيد خدمة الذكاء الاصطناعي غير كافٍ. يرجى المحاولة لاحقاً.';
      case 403:
        return 'ليس لديك صلاحية للوصول إلى هذه الخدمة.';
      case 404:
        return 'الخدمة غير موجودة.';
      case 429:
        return 'تم تجاوز الحد الأقصى للطلبات. يرجى المحاولة بعد قليل.';
      case 500:
        return 'خطأ في الخادم. يرجى المحاولة لاحقاً.';
      case 502:
      case 503:
      case 504:
        return 'الخدمة غير متاحة حالياً. يرجى المحاولة لاحقاً.';
      default:
        return 'حدث خطأ غير متوقع (رمز: $statusCode). يرجى المحاولة مرة أخرى.';
    }
  }

  @override
  Future<CommunicationScript> getCommunicationScript({
    required String scenario,
    required Relative? relative,
    String? additionalContext,
  }) async {
    try {
      final prompt = AIPrompts.communicationScriptPrompt(scenario, relative, additionalContext);
      final response = await getChatCompletion(
        messages: [
          ChatMessage(
            id: '',
            conversationId: '',
            userId: '',
            role: MessageRole.user,
            content: 'ساعدني في هذه المحادثة',
            createdAt: DateTime.now(),
          ),
        ],
        systemPrompt: prompt,
        temperature: 0.7,
      );

      // Parse JSON response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) {
        throw AIServiceException('Invalid response format');
      }

      final data = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      return CommunicationScript.fromJson(data);
    } catch (e) {
      _logger.error(
        'Communication script error',
        category: LogCategory.network,
        tag: 'DeepSeekAIService',
        metadata: {'error': e.toString()},
      );
      rethrow;
    }
  }

  @override
  Future<List<String>> generateMessages({
    required Relative relative,
    required String occasionType,
    required String tone,
    int count = 3,
  }) async {
    try {
      final prompt = AIPrompts.messageGenerationPrompt(relative, occasionType, tone);
      final response = await getChatCompletion(
        messages: [
          ChatMessage(
            id: '',
            conversationId: '',
            userId: '',
            role: MessageRole.user,
            content: 'اكتب رسائل للمناسبة',
            createdAt: DateTime.now(),
          ),
        ],
        systemPrompt: prompt,
        temperature: 0.9,
      );

      // Parse JSON response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) {
        throw AIServiceException('Invalid response format');
      }

      final data = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      final messages = (data['messages'] as List?)?.map((e) => e.toString()).toList() ?? [];

      return messages;
    } catch (e) {
      _logger.error(
        'Message generation error',
        category: LogCategory.network,
        tag: 'DeepSeekAIService',
        metadata: {'error': e.toString()},
      );
      rethrow;
    }
  }

  @override
  Future<RelationshipAnalysis> analyzeRelationship({
    required Relative relative,
  }) async {
    try {
      final prompt = AIPrompts.relationshipAnalysisPrompt(relative);
      final response = await getChatCompletion(
        messages: [
          ChatMessage(
            id: '',
            conversationId: '',
            userId: '',
            role: MessageRole.user,
            content: 'حلل هذه العلاقة وقدم نصائح',
            createdAt: DateTime.now(),
          ),
        ],
        systemPrompt: prompt,
        temperature: 0.7,
      );

      // Parse JSON response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) {
        throw AIServiceException('Invalid response format');
      }

      final data = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      return RelationshipAnalysis.fromJson(data);
    } catch (e) {
      _logger.error(
        'Relationship analysis error',
        category: LogCategory.network,
        tag: 'DeepSeekAIService',
        metadata: {'error': e.toString()},
      );
      // Return a fallback analysis
      return RelationshipAnalysis(
        summary: 'تعذر تحليل العلاقة. يرجى المحاولة مرة أخرى.',
        insights: [],
        suggestions: [
          AnalysisSuggestion(
            icon: '📞',
            title: 'تواصل مع ${relative.fullName}',
            description: 'حاول التواصل بشكل منتظم',
            priority: 'medium',
          ),
        ],
        alerts: [],
      );
    }
  }

  @override
  Future<List<SmartReminderSuggestion>> getSmartReminderSuggestions({
    required List<Relative> relatives,
  }) async {
    if (relatives.isEmpty) return [];

    try {
      final prompt = AIPrompts.smartReminderPrompt(relatives);
      final response = await getChatCompletion(
        messages: [
          ChatMessage(
            id: '',
            conversationId: '',
            userId: '',
            role: MessageRole.user,
            content: 'اقترح تذكيرات للتواصل',
            createdAt: DateTime.now(),
          ),
        ],
        systemPrompt: prompt,
        temperature: 0.7,
      );

      // Parse JSON response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) {
        throw AIServiceException('Invalid response format');
      }

      final data = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      final suggestions = (data['suggestions'] as List?)
              ?.map((e) => SmartReminderSuggestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      return suggestions;
    } catch (e) {
      _logger.error(
        'Smart reminder error',
        category: LogCategory.network,
        tag: 'DeepSeekAIService',
        metadata: {'error': e.toString()},
      );
      return [];
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      // Check if edge function is deployed
      final response = await _supabase.functions.invoke(
        _edgeFunctionName,
        body: {'health_check': true},
      );
      return response.status == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    // Nothing to dispose currently
  }

  /// Tokenize text for natural streaming (word by word with punctuation)
  List<String> _tokenizeForStreaming(String text) {
    final tokens = <String>[];
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      final char = text[i];

      if (char == ' ') {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        tokens.add(' ');
      } else if (_isPunctuation(char)) {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        tokens.add(char);
      } else if (char == '\n') {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        tokens.add('\n');
      } else {
        buffer.write(char);
      }
    }

    if (buffer.isNotEmpty) {
      tokens.add(buffer.toString());
    }

    return tokens;
  }

  /// Check if character is punctuation
  bool _isPunctuation(String char) {
    return ['.', '،', '؟', '!', ':', '؛', '-', '*', '#', ')', '(', '"', '\'']
        .contains(char);
  }

  /// Get variable delay for natural typing effect (ultra-fast, ChatGPT-like)
  int _getStreamingDelay(String token) {
    // Minimal pauses after punctuation
    if (token == '.' || token == '؟' || token == '!') {
      return 10; // Brief pause at sentence end
    }
    if (token == '،' || token == '؛' || token == ':') {
      return 6; // Very brief pause
    }
    if (token == '\n') {
      return 12; // Slight pause for new line
    }
    if (token == ' ') {
      return 2; // Almost instant for spaces
    }
    // Regular words - ultra-fast
    return 3 + (token.length % 2) * 2; // 3-5ms per word
  }

  @override
  Future<List<Map<String, dynamic>>> extractMemories(String conversation) async {
    try {
      final response = await getChatCompletion(
        messages: [
          ChatMessage(
            id: 'extract',
            conversationId: '',
            userId: '',
            role: MessageRole.user,
            content: conversation,
            createdAt: DateTime.now(),
          ),
        ],
        systemPrompt: AIPrompts.memoryExtractionPrompt,
        temperature: 0.3, // Lower temperature for more consistent JSON
        maxTokens: 500,
      );

      // Parse JSON response
      try {
        // Clean up response - remove markdown code blocks if present
        String cleanResponse = response.trim();
        if (cleanResponse.startsWith('```json')) {
          cleanResponse = cleanResponse.substring(7);
        } else if (cleanResponse.startsWith('```')) {
          cleanResponse = cleanResponse.substring(3);
        }
        if (cleanResponse.endsWith('```')) {
          cleanResponse = cleanResponse.substring(0, cleanResponse.length - 3);
        }
        cleanResponse = cleanResponse.trim();

        final json = jsonDecode(cleanResponse);
        final memories = json['memories'] as List<dynamic>?;
        if (memories == null || memories.isEmpty) {
          return [];
        }
        return memories.cast<Map<String, dynamic>>();
      } catch (parseError) {
        _logger.warning(
          'Failed to parse memory extraction response',
          category: LogCategory.network,
          tag: 'ExtractMemories',
          metadata: {'response': response, 'error': parseError.toString()},
        );
        return [];
      }
    } catch (e) {
      _logger.warning(
        'Memory extraction failed',
        category: LogCategory.network,
        tag: 'ExtractMemories',
        metadata: {'error': e.toString()},
      );
      return [];
    }
  }
}

/// Mock AI Service for testing and development without API key
class MockAIService implements AIService {
  @override
  Stream<AIStreamChunk> streamChatCompletion({
    required List<ChatMessage> messages,
    required String systemPrompt,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    const mockResponse = '''
أهلاً بك! أنا واصل، مساعدك في صلة الرحم.

صلة الرحم من أعظم الأعمال عند الله، وهي سبب للبركة في الرزق والعمر.

كيف يمكنني مساعدتك اليوم في التواصل مع أقاربك؟
''';

    for (var i = 0; i < mockResponse.length; i += 10) {
      final end = (i + 10 < mockResponse.length) ? i + 10 : mockResponse.length;
      yield AIStreamChunk(content: mockResponse.substring(i, end));
      await Future.delayed(const Duration(milliseconds: 50));
    }
    yield AIStreamChunk(content: '', isDone: true);
  }

  @override
  Future<String> getChatCompletion({
    required List<ChatMessage> messages,
    required String systemPrompt,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return '''
أهلاً بك! أنا واصل، مساعدك في صلة الرحم.

صلة الرحم من أعظم الأعمال عند الله، وهي سبب للبركة في الرزق والعمر.

كيف يمكنني مساعدتك اليوم في التواصل مع أقاربك؟
''';
  }

  @override
  Future<CommunicationScript> getCommunicationScript({
    required String scenario,
    required Relative? relative,
    String? additionalContext,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return CommunicationScript(
      opening: 'السلام عليكم، كيف حالك؟ أتمنى أن تكون بخير',
      keyPoints: [
        'عبّر عن اشتياقك',
        'اسأل عن أحوالهم',
        'اقترح لقاء قريب',
      ],
      phrasesToUse: [
        'وحشتني كثيراً',
        'أتمنى أن نلتقي قريباً',
        'أنت في بالي دائماً',
      ],
      phrasesToAvoid: [
        'لماذا لم تتصل؟',
        'أنت دائماً مشغول',
      ],
      closing: 'أحبك في الله، وأتطلع لرؤيتك قريباً',
    );
  }

  @override
  Future<List<String>> generateMessages({
    required Relative relative,
    required String occasionType,
    required String tone,
    int count = 3,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      'كل عام وأنت بخير، أسأل الله أن يحفظك ويبارك فيك',
      'أهنئك من كل قلبي، وأتمنى لك السعادة والتوفيق',
      'مبارك عليك، وأسأل الله أن يجعلها أياماً سعيدة',
    ];
  }

  @override
  Future<RelationshipAnalysis> analyzeRelationship({
    required Relative relative,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return RelationshipAnalysis(
      summary: 'العلاقة بحاجة إلى المزيد من التواصل المنتظم',
      insights: [
        AnalysisInsight(
          icon: '💡',
          title: 'فرصة للتقارب',
          description: 'يمكنك تحسين العلاقة من خلال التواصل المستمر',
        ),
      ],
      suggestions: [
        AnalysisSuggestion(
          icon: '📞',
          title: 'اتصل اليوم',
          description: 'مكالمة قصيرة تصنع الفرق',
          priority: 'high',
        ),
        AnalysisSuggestion(
          icon: '💬',
          title: 'أرسل رسالة',
          description: 'رسالة بسيطة للاطمئنان',
          priority: 'medium',
        ),
      ],
      alerts: [],
    );
  }

  @override
  Future<List<SmartReminderSuggestion>> getSmartReminderSuggestions({
    required List<Relative> relatives,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (relatives.isEmpty) return [];

    return [
      SmartReminderSuggestion(
        relativeName: relatives.first.fullName,
        reason: 'مضى وقت على آخر تواصل',
        urgency: 'medium',
        suggestedAction: 'رسالة',
        suggestedMessage: 'السلام عليكم، كيف حالك؟',
      ),
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> extractMemories(String conversation) async {
    // Mock implementation - returns empty list
    return [];
  }

  @override
  Future<bool> isAvailable() async => true;

  @override
  void dispose() {}
}
