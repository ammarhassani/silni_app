import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../ai/ai_context_engine.dart';
import 'cache_config_service.dart';

/// Service for managing AI touch points across the app
///
/// Touch points are admin-configurable places where AI can inject
/// intelligence into the app experience. This service:
/// - Loads touch point configurations from Supabase
/// - Generates AI content using configured prompts
/// - Caches responses for performance
/// - Tracks usage for analytics
class AITouchPointService {
  AITouchPointService._();
  static final AITouchPointService instance = AITouchPointService._();

  final _supabase = Supabase.instance.client;
  final _contextEngine = AIContextEngine.instance;
  final _cacheConfig = CacheConfigService();

  // Cache for touch point configurations
  Map<String, AITouchPoint>? _touchPointsCache;
  DateTime? _lastFetchTime;

  // Cache for AI responses (key = hash of prompt + context)
  final Map<String, _CachedResponse> _responseCache = {};

  static const String _serviceKey = 'ai_touch_points';
  static const String _edgeFunctionName = 'deepseek-proxy';

  bool get _isCacheValid {
    if (_lastFetchTime == null) return false;
    return !_cacheConfig.isCacheExpired(_serviceKey, _lastFetchTime);
  }

  /// Initialize and load touch points
  Future<void> initialize() async {
    if (!_isCacheValid) {
      await refresh();
    }
  }

  /// Refresh touch points from server
  Future<void> refresh() async {
    try {
      final response = await _supabase
          .from('admin_ai_touch_points')
          .select()
          .eq('is_enabled', true);

      final touchPoints = (response as List)
          .map((json) => AITouchPoint.fromJson(json))
          .toList();

      _touchPointsCache = {
        for (var tp in touchPoints) '${tp.screenKey}:${tp.touchPointKey}': tp
      };
      _lastFetchTime = DateTime.now();
    } catch (_) {
      // Touch points refresh failed silently
    }
  }

  /// Clear all caches
  void clearCache() {
    _touchPointsCache = null;
    _responseCache.clear();
    _lastFetchTime = null;
  }

  /// Clear only AI response cache (for refresh functionality)
  void clearResponseCache() {
    _responseCache.clear();
  }

  /// Get a specific touch point configuration
  AITouchPoint? getTouchPoint(String screenKey, String touchPointKey) {
    return _touchPointsCache?['$screenKey:$touchPointKey'];
  }

  /// Check if a touch point is enabled
  bool isEnabled(String screenKey, String touchPointKey) {
    final tp = getTouchPoint(screenKey, touchPointKey);
    return tp?.isEnabled ?? false;
  }

  /// Generate AI content for a touch point
  ///
  /// [screenKey] - The screen (e.g., 'home', 'relative_detail')
  /// [touchPointKey] - The specific touch point (e.g., 'greeting', 'insight')
  /// [context] - Optional pre-built context (will build if not provided)
  /// [useCache] - Whether to use cached responses
  Future<AITouchPointResult> generate({
    required String screenKey,
    required String touchPointKey,
    AIContext? context,
    bool useCache = true,
  }) async {
    final startTime = DateTime.now();

    // Get touch point config
    final touchPoint = getTouchPoint(screenKey, touchPointKey);
    if (touchPoint == null) {
      return AITouchPointResult.error('Touch point not found: $screenKey:$touchPointKey');
    }

    try {
      // Build context if not provided
      context ??= await _contextEngine.buildContext(
        featureContext: screenKey,
      );

      // Build the prompt with context
      final prompt = _buildPrompt(touchPoint, context);
      final promptHash = _hashPrompt(prompt);

      // Check cache
      if (useCache) {
        final cached = _getCachedResponse(promptHash, touchPoint.cacheDurationSeconds);
        if (cached != null) {
          return AITouchPointResult.success(cached, fromCache: true);
        }
      }

      // Generate AI response
      final response = await _callAI(
        prompt: prompt,
        temperature: touchPoint.temperature,
        maxTokens: touchPoint.maxTokens,
      );

      final latencyMs = DateTime.now().difference(startTime).inMilliseconds;

      // Cache the response
      _cacheResponse(promptHash, response, touchPoint.cacheDurationSeconds);

      // Track usage (fire and forget)
      _trackUsage(
        touchPointKey: touchPointKey,
        screenKey: screenKey,
        promptHash: promptHash,
        response: response,
        latencyMs: latencyMs,
      );

      return AITouchPointResult.success(response);
    } catch (_) {
      return AITouchPointResult.error('حدث خطأ أثناء توليد المحتوى');
    }
  }

  /// Build the final prompt by replacing placeholders with context data
  String _buildPrompt(AITouchPoint touchPoint, AIContext context) {
    var prompt = touchPoint.promptTemplate;

    // Replace common placeholders
    prompt = prompt
        .replaceAll('{{time_of_day}}', _getTimeOfDay())
        .replaceAll('{{active_streaks}}', context.totalActiveStreaks.toString())
        .replaceAll('{{at_risk_count}}', context.healthSummary.atRiskCount.toString())
        .replaceAll('{{healthy_count}}', context.healthSummary.healthyCount.toString())
        .replaceAll('{{needs_attention_count}}', context.healthSummary.needsAttentionCount.toString())
        .replaceAll('{{total_interactions}}', context.gamification.totalInteractions.toString())
        .replaceAll('{{user_level}}', context.gamification.level.toString())
        .replaceAll('{{total_points}}', context.gamification.totalPoints.toString());

    // Replace upcoming occasions
    if (prompt.contains('{{upcoming_occasions}}')) {
      final occasions = context.upcomingOccasions
          .take(3)
          .map((o) => '${o.relativeName}: ${o.occasionType} بعد ${o.daysUntil} يوم')
          .join(', ');
      prompt = prompt.replaceAll('{{upcoming_occasions}}', occasions.isEmpty ? 'لا مناسبات قريبة' : occasions);
    }

    // Replace relatives data
    if (prompt.contains('{{relatives_data}}')) {
      final relativesData = context.relatives
          .take(10)
          .map((r) => '- ${r.fullName} (${r.relationshipType.arabicName}): ${r.healthStatus2.arabicName}, آخر تواصل: ${r.daysSinceLastContact ?? "غير محدد"} يوم')
          .join('\n');
      prompt = prompt.replaceAll('{{relatives_data}}', relativesData);
    }

    // Replace streaks data
    if (prompt.contains('{{streaks_data}}')) {
      final streaksData = context.streaks.entries
          .where((e) => e.value.currentStreak > 0)
          .take(5)
          .map((e) {
            final relative = context.relatives.firstWhere(
              (r) => r.id == e.key,
              orElse: () => context.relatives.first,
            );
            return '- ${relative.fullName}: ${e.value.currentStreak} يوم';
          })
          .join('\n');
      prompt = prompt.replaceAll('{{streaks_data}}', streaksData.isEmpty ? 'لا شعلات نشطة' : streaksData);
    }

    // Replace occasions data
    if (prompt.contains('{{occasions_data}}')) {
      final occasionsData = context.upcomingOccasions
          .take(5)
          .map((o) => '- ${o.relativeName}: ${o.occasionType} في ${o.date.day}/${o.date.month}')
          .join('\n');
      prompt = prompt.replaceAll('{{occasions_data}}', occasionsData.isEmpty ? 'لا مناسبات قادمة' : occasionsData);
    }

    // Replace focus relative data
    if (context.focusRelative != null) {
      final r = context.focusRelative!;
      final isMale = r.gender?.value == 'male';
      final genderPronoun = isMale ? 'ه' : 'ها';
      final genderVerb = isMale ? 'يحب' : 'تحب';
      final genderAsk = isMale ? 'اسأله' : 'اسأليها';
      final genderPossessive = isMale ? 'له' : 'لها';

      prompt = prompt
          .replaceAll('{{relative_name}}', r.fullName)
          .replaceAll('{{relationship_type}}', r.relationshipType.arabicName)
          .replaceAll('{{interests}}', r.interests?.join('، ') ?? 'غير محدد')
          .replaceAll('{{last_contact}}', r.daysSinceLastContact?.toString() ?? 'غير محدد')
          .replaceAll('{{health_status}}', r.healthStatus2.arabicName)
          .replaceAll('{{days_since_contact}}', r.daysSinceLastContact?.toString() ?? 'غير محدد')
          .replaceAll('{{emotional_closeness}}', r.emotionalCloseness?.toString() ?? 'غير محدد')
          .replaceAll('{{communication_quality}}', r.communicationQuality?.toString() ?? 'غير محدد')
          .replaceAll('{{personality_type}}', r.personalityType ?? 'غير محدد')
          .replaceAll('{{gender}}', isMale ? 'ذكر' : 'أنثى')
          .replaceAll('{{gender_pronoun}}', genderPronoun)
          .replaceAll('{{gender_verb}}', genderVerb)
          .replaceAll('{{gender_ask}}', genderAsk)
          .replaceAll('{{gender_possessive}}', genderPossessive);

      final streak = context.getStreakFor(r.id);
      prompt = prompt.replaceAll('{{current_streak}}', streak?.currentStreak.toString() ?? '0');
    }

    // Replace memories
    if (prompt.contains('{{memories}}')) {
      final memories = context.memories
          .take(5)
          .map((m) => '- ${m.content}')
          .join('\n');
      prompt = prompt.replaceAll('{{memories}}', memories.isEmpty ? 'لا ذكريات مسجلة' : memories);
    }

    return prompt;
  }

  /// Get time of day in Arabic
  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'الليل';
    if (hour < 12) return 'الصباح';
    if (hour < 17) return 'الظهر';
    if (hour < 21) return 'المساء';
    return 'الليل';
  }

  /// Hash a prompt for caching (simple hash using hashCode)
  String _hashPrompt(String prompt) {
    // Use a combination of hashCode and length for a simple cache key
    final hash1 = prompt.hashCode;
    final hash2 = prompt.length;
    return '${hash1.toRadixString(16)}_$hash2';
  }

  /// Get cached response if valid
  String? _getCachedResponse(String hash, int maxAgeSeconds) {
    final cached = _responseCache[hash];
    if (cached == null) return null;

    final age = DateTime.now().difference(cached.timestamp).inSeconds;
    if (age > maxAgeSeconds) {
      _responseCache.remove(hash);
      return null;
    }

    return cached.response;
  }

  /// Cache a response
  void _cacheResponse(String hash, String response, int maxAgeSeconds) {
    _responseCache[hash] = _CachedResponse(
      response: response,
      timestamp: DateTime.now(),
    );

    // Clean old entries (keep max 50)
    if (_responseCache.length > 50) {
      final sortedKeys = _responseCache.keys.toList()
        ..sort((a, b) => _responseCache[a]!.timestamp.compareTo(_responseCache[b]!.timestamp));
      for (final key in sortedKeys.take(10)) {
        _responseCache.remove(key);
      }
    }
  }

  /// Call the AI API
  Future<String> _callAI({
    required String prompt,
    required double temperature,
    required int maxTokens,
  }) async {
    final stopwatch = Stopwatch()..start();

    final response = await _supabase.functions.invoke(
      _edgeFunctionName,
      body: {
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'temperature': temperature,
        'max_tokens': maxTokens,
      },
    ).timeout(
      const Duration(seconds: 15), // Reduced timeout for faster fail
      onTimeout: () => throw Exception('AI request timed out'),
    );

    stopwatch.stop();

    if (response.status != 200) {
      throw Exception('API error: ${response.status}');
    }

    final data = response.data as Map<String, dynamic>;
    return data['content'] as String? ?? '';
  }

  /// Track AI generation usage
  Future<void> _trackUsage({
    required String touchPointKey,
    required String screenKey,
    required String promptHash,
    required String response,
    required int latencyMs,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('ai_generations').insert({
        'user_id': userId,
        'touch_point_key': touchPointKey,
        'screen_key': screenKey,
        'prompt_hash': promptHash,
        'response': response.length > 500 ? response.substring(0, 500) : response,
        'latency_ms': latencyMs,
      });
    } catch (_) {
      // Usage tracking failed silently
    }
  }
}

/// Cached AI response
class _CachedResponse {
  final String response;
  final DateTime timestamp;

  _CachedResponse({required this.response, required this.timestamp});
}

/// AI Touch Point configuration from admin panel
class AITouchPoint {
  final String id;
  final String screenKey;
  final String touchPointKey;
  final String nameAr;
  final String? nameEn;
  final String? descriptionAr;
  final bool isEnabled;
  final String promptTemplate;
  final List<String> contextFields;
  final Map<String, dynamic> displayConfig;
  final int cacheDurationSeconds;
  final int priority;
  final double temperature;
  final int maxTokens;

  AITouchPoint({
    required this.id,
    required this.screenKey,
    required this.touchPointKey,
    required this.nameAr,
    this.nameEn,
    this.descriptionAr,
    required this.isEnabled,
    required this.promptTemplate,
    required this.contextFields,
    required this.displayConfig,
    required this.cacheDurationSeconds,
    required this.priority,
    required this.temperature,
    required this.maxTokens,
  });

  factory AITouchPoint.fromJson(Map<String, dynamic> json) {
    return AITouchPoint(
      id: json['id'] as String,
      screenKey: json['screen_key'] as String,
      touchPointKey: json['touch_point_key'] as String,
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String?,
      descriptionAr: json['description_ar'] as String?,
      isEnabled: json['is_enabled'] as bool? ?? true,
      promptTemplate: json['prompt_template'] as String? ?? '',
      contextFields: (json['context_fields'] as List?)?.cast<String>() ?? [],
      displayConfig: (json['display_config'] as Map<String, dynamic>?) ?? {},
      cacheDurationSeconds: json['cache_duration_seconds'] as int? ?? 300,
      priority: json['priority'] as int? ?? 0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      maxTokens: json['max_tokens'] as int? ?? 150,
    );
  }

  /// Get icon from display config
  String get icon => displayConfig['icon'] as String? ?? 'sparkles';

  /// Get position from display config
  String get position => displayConfig['position'] as String? ?? 'default';
}

/// Result of AI touch point generation
class AITouchPointResult {
  final bool success;
  final String? content;
  final String? error;
  final bool fromCache;

  AITouchPointResult._({
    required this.success,
    this.content,
    this.error,
    this.fromCache = false,
  });

  factory AITouchPointResult.success(String content, {bool fromCache = false}) {
    return AITouchPointResult._(
      success: true,
      content: content,
      fromCache: fromCache,
    );
  }

  factory AITouchPointResult.error(String error) {
    return AITouchPointResult._(
      success: false,
      error: error,
    );
  }

  /// Parse JSON response (for structured outputs)
  T? parseJson<T>(T Function(dynamic) parser) {
    if (content == null) return null;
    try {
      // Try to extract JSON from the response
      final jsonMatch = RegExp(r'\[[\s\S]*\]|\{[\s\S]*\}').firstMatch(content!);
      if (jsonMatch != null) {
        final decoded = jsonDecode(jsonMatch.group(0)!);
        return parser(decoded);
      }
    } catch (_) {
      // JSON parsing failed
    }
    return null;
  }
}
