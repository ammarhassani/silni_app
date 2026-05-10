import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/relative_model.dart';
import '../config/env/app_environment.dart';
import '../services/ai_config_service.dart';
import '../services/app_logger_service.dart';
import 'ai_models.dart';
import 'ai_prompts.dart';
import 'ai_service.dart';

/// DeepSeek AI Service Implementation
/// Uses DeepSeek API via Supabase Edge Function proxy for security
class DeepSeekAIService implements AIService {
  static DeepSeekAIService? _instance;
  final AppLoggerService _logger = AppLoggerService();
  // Use lazy initialization to avoid accessing Supabase before it's initialized
  SupabaseClient get _supabase => Supabase.instance.client;

  // Edge function endpoint (proxy to DeepSeek)
  static const String _edgeFunctionName = 'deepseek-proxy';

  factory DeepSeekAIService() => _instance ??= DeepSeekAIService._internal();
  DeepSeekAIService._internal();

  /// Build the edge function URL for direct HTTP calls (used for SSE streaming)
  Uri get _edgeFunctionUrl => Uri.parse(
        '${AppEnvironment.supabaseUrl}/functions/v1/$_edgeFunctionName',
      );

  @override
  Stream<AIStreamChunk> streamChatCompletion({
    required List<ChatMessage> messages,
    required String systemPrompt,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    try {
      final accessToken = _supabase.auth.currentSession?.accessToken;
      if (accessToken == null) {
        yield AIStreamChunk(
          content: '',
          isDone: true,
          error: 'يرجى تسجيل الدخول مرة أخرى.',
        );
        return;
      }

      final formattedMessages = [
        {'role': 'system', 'content': systemPrompt},
        ...messages.map((m) => m.toApiFormat()),
      ];

      // Use http package for streaming POST request
      final request = http.Request('POST', _edgeFunctionUrl);
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.headers['Content-Type'] = 'application/json';
      request.headers['apikey'] = AppEnvironment.supabaseAnonKey;
      request.body = jsonEncode({
        'messages': formattedMessages,
        'temperature': temperature,
        'max_tokens': maxTokens,
        'stream': true,
      });

      final client = http.Client();
      try {
        final streamedResponse = await client.send(request).timeout(
              const Duration(seconds: 90),
              onTimeout: () => throw AIServiceException(
                'انتهت مهلة الاتصال. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.',
                code: 'TIMEOUT',
              ),
            );

        // Handle non-200 responses
        if (streamedResponse.statusCode != 200) {
          final body = await streamedResponse.stream.bytesToString();
          _logger.error(
            'SSE stream error: ${streamedResponse.statusCode}',
            category: LogCategory.network,
            tag: 'DeepSeekAIService',
            metadata: {'status': streamedResponse.statusCode, 'body': body},
          );
          yield AIStreamChunk(
            content: '',
            isDone: true,
            error: _getErrorMessage(streamedResponse.statusCode),
          );
          return;
        }

        // Parse SSE stream.
        //
        // Critical: `utf8.decoder.bind(stream)` accumulates bytes across
        // chunk boundaries before decoding, so a multi-byte UTF-8 sequence
        // (Arabic characters are 2–3 bytes each) sliced by a TCP packet
        // boundary doesn't blow up the parser. The naïve `utf8.decode(bytes)`
        // per-chunk variant throws `FormatException: Unfinished UTF-8
        // octet sequence` mid-stream — that produced the user-visible
        // "حدث خطأ غير متوقع" within the first few seconds of any reply
        // containing Arabic content (Phase δ.fix.4).
        //
        // `LineSplitter` then yields complete `\n`-terminated lines, so
        // we don't need to manage a manual buffer.
        await for (final line in streamedResponse.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith(':')) continue;

          if (trimmed.startsWith('data: ')) {
            final data = trimmed.substring(6);

            if (data == '[DONE]') {
              yield AIStreamChunk(content: '', isDone: true);
              return;
            }

            try {
              final parsed = jsonDecode(data) as Map<String, dynamic>;
              if (parsed.containsKey('error')) {
                yield AIStreamChunk(
                  content: '',
                  isDone: true,
                  error: parsed['error'] as String? ??
                      'حدث خطأ غير متوقع.',
                );
                return;
              }
              final content = parsed['content'] as String?;
              if (content != null && content.isNotEmpty) {
                yield AIStreamChunk(content: content);
              }
            } catch (_) {
              // Skip malformed JSON chunks
            }
          }
        }

        // If we exit the stream without [DONE], send the done signal
        yield AIStreamChunk(content: '', isDone: true);
      } finally {
        client.close();
      }
    } on AIServiceException catch (e) {
      yield AIStreamChunk(content: '', isDone: true, error: e.message);
    } catch (e) {
      _logger.error(
        'Stream error',
        category: LogCategory.network,
        tag: 'DeepSeekAIService',
        metadata: {'error': e.toString()},
      );
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
    int? timeoutSeconds,
  }) async {
    try {
      final formattedMessages = [
        {'role': 'system', 'content': systemPrompt},
        ...messages.map((m) => m.toApiFormat()),
      ];

      // Use provided timeout or default from config (fallback to 60)
      final timeout = timeoutSeconds ?? 60;

      final response = await _supabase.functions.invoke(
        _edgeFunctionName,
        body: {
          'messages': formattedMessages,
          'temperature': temperature,
          'max_tokens': maxTokens,
        },
      ).timeout(
        Duration(seconds: timeout),
        onTimeout: () => throw AIServiceException(
          'انتهت مهلة الاتصال. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.',
          code: 'TIMEOUT',
        ),
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
  /// Uses dynamic config from admin panel with fallback
  String _getErrorMessage(int statusCode) {
    return AIConfigService.instance.getErrorMessage(statusCode);
  }

  @override
  Future<CommunicationScript> getCommunicationScript({
    required String scenario,
    required Relative? relative,
    String? additionalContext,
  }) async {
    try {
      final params = AIConfigService.instance.getParametersFor('communication_script');
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
        temperature: params.temperature,
        maxTokens: params.maxTokens,
        timeoutSeconds: params.timeoutSeconds,
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
      final config = AIConfigService.instance;
      final params = config.getParametersFor('message_generation');

      // Get occasion config for promptAddition
      final occasionConfig = config.messageOccasions
          .cast<AIMessageOccasion?>()
          .firstWhere((o) => o?.occasionKey == occasionType, orElse: () => null);

      // Get tone config for promptModifier
      final toneConfig = config.messageTones
          .cast<AIMessageTone?>()
          .firstWhere((t) => t?.toneKey == tone, orElse: () => null);

      final prompt = AIPrompts.messageGenerationPrompt(
        relative,
        occasionType,
        tone,
        occasionPromptAddition: occasionConfig?.promptAddition,
        tonePromptModifier: toneConfig?.promptModifier,
      );
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
        temperature: params.temperature,
        maxTokens: params.maxTokens,
        timeoutSeconds: params.timeoutSeconds,
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

  /// Generate personalized occasion messages for multiple relatives in a single call.
  /// Returns a map of relative ID → message string.
  Future<Map<String, String>> generateOccasionMessages({
    required List<Relative> relatives,
    required String occasionType,
    Map<String, String>? relationshipLabels,
  }) async {
    try {
      final config = AIConfigService.instance;
      final params = config.getParametersFor('message_generation');

      final occasionConfig = config.messageOccasions
          .cast<AIMessageOccasion?>()
          .firstWhere((o) => o?.occasionKey == occasionType, orElse: () => null);

      final prompt = AIPrompts.occasionBatchPrompt(
        relatives: relatives,
        occasionType: occasionType,
        relationshipLabels: relationshipLabels,
        occasionPromptAddition: occasionConfig?.promptAddition,
      );

      final response = await getChatCompletion(
        messages: [
          ChatMessage(
            id: '',
            conversationId: '',
            userId: '',
            role: MessageRole.user,
            content: 'اكتب رسائل المناسبة',
            createdAt: DateTime.now(),
          ),
        ],
        systemPrompt: prompt,
        temperature: params.temperature,
        maxTokens: params.maxTokens,
        timeoutSeconds: params.timeoutSeconds,
      );

      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) {
        throw AIServiceException('Invalid response format');
      }

      final data = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      final messagesMap = data['messages'] as Map<String, dynamic>?;
      if (messagesMap == null) {
        throw AIServiceException('Missing messages in response');
      }

      return messagesMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      _logger.error(
        'Occasion message generation error',
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
      final params = AIConfigService.instance.getParametersFor('relationship_analysis');
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
        temperature: params.temperature,
        maxTokens: params.maxTokens,
        timeoutSeconds: params.timeoutSeconds,
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
      final params = AIConfigService.instance.getParametersFor('smart_reminders');
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
        temperature: params.temperature,
        maxTokens: params.maxTokens,
        timeoutSeconds: params.timeoutSeconds,
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
  Future<String> generateShareCopy({
    required String cardType,
    required Map<String, dynamic> context,
  }) async {
    try {
      final params = AIConfigService.instance.getParametersFor('share_copy');
      final prompt = AIPrompts.shareCopyPrompt(
        cardType: cardType,
        context: context,
      );

      final response = await getChatCompletion(
        messages: [
          ChatMessage(
            id: '',
            conversationId: '',
            userId: '',
            role: MessageRole.user,
            content: 'اكتب نص مشاركة',
            createdAt: DateTime.now(),
          ),
        ],
        systemPrompt: prompt,
        temperature: params.temperature,
        maxTokens: params.maxTokens,
        timeoutSeconds: params.timeoutSeconds,
      );

      // Clean up response: trim quotes, markdown, whitespace
      String cleaned = response.trim();
      // Remove surrounding quotes
      if ((cleaned.startsWith('"') && cleaned.endsWith('"')) ||
          (cleaned.startsWith("'") && cleaned.endsWith("'"))) {
        cleaned = cleaned.substring(1, cleaned.length - 1);
      }
      // Remove markdown formatting
      cleaned = cleaned.replaceAll(RegExp(r'[*_`#]'), '');
      // Collapse whitespace
      cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

      return cleaned;
    } catch (e) {
      _logger.error(
        'Share copy generation error',
        category: LogCategory.network,
        tag: 'DeepSeekAIService',
        metadata: {'error': e.toString(), 'cardType': cardType},
      );
      rethrow;
    }
  }

  @override
  Future<({String title, String emoji})> generateWrappedPersonality({
    required Map<String, dynamic> stats,
  }) async {
    try {
      final params =
          AIConfigService.instance.getParametersFor('wrapped_personality');
      final prompt = AIPrompts.wrappedPersonalityPrompt(stats: stats);

      final response = await getChatCompletion(
        messages: [
          ChatMessage(
            id: '',
            conversationId: '',
            userId: '',
            role: MessageRole.user,
            content: 'ابتكر لقباً لملخص تواصلي',
            createdAt: DateTime.now(),
          ),
        ],
        systemPrompt: prompt,
        temperature: params.temperature,
        maxTokens: params.maxTokens,
        timeoutSeconds: params.timeoutSeconds,
      );

      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) {
        throw AIServiceException('Invalid response format');
      }

      final data =
          jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      final title = data['title'] as String? ?? '';
      final emoji = data['emoji'] as String? ?? '';

      if (title.isEmpty) {
        throw AIServiceException('Empty title in response');
      }

      return (title: title, emoji: emoji);
    } catch (e) {
      _logger.error(
        'Wrapped personality generation error',
        category: LogCategory.network,
        tag: 'DeepSeekAIService',
        metadata: {'error': e.toString()},
      );
      rethrow;
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

  @override
  Future<List<Map<String, dynamic>>> extractMemories(String conversation) async {
    try {
      final params = AIConfigService.instance.getParametersFor('memory_extraction');
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
        temperature: params.temperature,
        maxTokens: params.maxTokens,
        timeoutSeconds: params.timeoutSeconds,
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
أهلاً بك! أنا أنيس، مساعدك في صلة الرحم.

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
    int? timeoutSeconds,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return '''
أهلاً بك! أنا أنيس، مساعدك في صلة الرحم.

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
  Future<String> generateShareCopy({
    required String cardType,
    required Map<String, dynamic> context,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return 'ما شاء الله تواصلي مع أهلي ما وقف 🔥';
  }

  @override
  Future<({String title, String emoji})> generateWrappedPersonality({
    required Map<String, dynamic> stats,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return (title: 'حارس الروابط', emoji: '🌟');
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
