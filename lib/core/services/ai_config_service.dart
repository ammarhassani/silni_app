import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cache_config_service.dart';

/// Service for fetching AI configuration from admin panel (Supabase)
/// Provides dynamic configuration for AI identity, personality, modes, etc.
class AIConfigService {
  AIConfigService._();
  static final AIConfigService instance = AIConfigService._();

  final _supabase = Supabase.instance.client;

  // Cached configs
  AIIdentityConfig? _identityCache;
  List<AIPersonalitySection>? _personalityCache;
  List<AICounselingModeConfig>? _modesCache;
  List<AIMessageOccasion>? _occasionsCache;
  List<AIMessageTone>? _tonesCache;
  Map<String, AIParameterConfig>? _parametersCache;
  List<AISuggestedPrompt>? _suggestedPromptsCache;
  AIMemorySystemConfig? _memoryConfigCache;
  List<AIMemoryCategoryConfig>? _memoryCategoriesCache;
  Map<int, AIErrorMessageConfig>? _errorMessagesCache;
  AIStreamingConfig? _streamingConfigCache;
  List<AICommunicationScenario>? _scenariosCache;
  DateTime? _lastFetchTime;

  // Cache duration from remote config
  final CacheConfigService _cacheConfig = CacheConfigService();
  static const String _serviceKey = 'ai_config';

  bool get _isCacheValid {
    if (_lastFetchTime == null) return false;
    return !_cacheConfig.isCacheExpired(_serviceKey, _lastFetchTime);
  }

  /// Check if config is loaded
  bool get isLoaded => _lastFetchTime != null;

  /// Initialize and load all AI configs
  Future<void> initialize() async {
    if (!_isCacheValid) {
      await refresh();
    }
  }

  /// Refresh all configs from server
  Future<void> refresh() async {
    debugPrint('[AIConfigService] Refreshing all AI configs...');
    try {
      await Future.wait([
        _fetchIdentity(),
        _fetchPersonality(),
        _fetchModes(),
        _fetchOccasions(),
        _fetchTones(),
        _fetchParameters(),
        _fetchSuggestedPrompts(),
        _fetchMemoryConfig(),
        _fetchMemoryCategories(),
        _fetchErrorMessages(),
        _fetchStreamingConfig(),
        _fetchCommunicationScenarios(),
      ]);
      _lastFetchTime = DateTime.now();
      debugPrint('[AIConfigService] All configs refreshed successfully');
    } catch (e) {
      debugPrint('[AIConfigService] Error refreshing configs: $e');
    }
  }

  /// Clear cache
  void clearCache() {
    _identityCache = null;
    _personalityCache = null;
    _modesCache = null;
    _occasionsCache = null;
    _tonesCache = null;
    _parametersCache = null;
    _suggestedPromptsCache = null;
    _memoryConfigCache = null;
    _memoryCategoriesCache = null;
    _errorMessagesCache = null;
    _streamingConfigCache = null;
    _scenariosCache = null;
    _lastFetchTime = null;
  }

  // ============ Identity ============

  Future<void> _fetchIdentity() async {
    try {
      final response = await _supabase
          .from('admin_ai_identity')
          .select()
          .eq('is_active', true)
          .single();
      _identityCache = AIIdentityConfig.fromJson(response);
      debugPrint('[AIConfigService] Loaded identity: ${_identityCache?.aiName}');
    } catch (e) {
      debugPrint('[AIConfigService] Error fetching identity: $e');
    }
  }

  AIIdentityConfig get identity => _identityCache ?? AIIdentityConfig.fallback();

  // ============ Personality ============

  Future<void> _fetchPersonality() async {
    try {
      final response = await _supabase
          .from('admin_ai_personality')
          .select()
          .eq('is_active', true)
          .order('priority');
      _personalityCache = (response as List)
          .map((json) => AIPersonalitySection.fromJson(json))
          .toList();
      debugPrint('[AIConfigService] Loaded ${_personalityCache?.length} personality sections');
    } catch (e) {
      debugPrint('[AIConfigService] Error fetching personality: $e');
    }
  }

  List<AIPersonalitySection> get personalitySections =>
      _personalityCache ?? AIPersonalitySection.fallbackSections();

  /// Build complete personality prompt from sections
  String get fullPersonalityPrompt {
    final sections = personalitySections;
    if (sections.isEmpty) return _hardcodedPersonality;

    final buffer = StringBuffer();
    buffer.writeln('أنت "${identity.aiName}"، ${identity.aiRoleAr}');
    buffer.writeln();

    for (final section in sections) {
      buffer.writeln('## ${section.sectionNameAr}:');
      buffer.writeln(section.contentAr);
      buffer.writeln();
    }

    return buffer.toString();
  }

  // ============ Counseling Modes ============

  Future<void> _fetchModes() async {
    try {
      final response = await _supabase
          .from('admin_counseling_modes')
          .select()
          .eq('is_active', true)
          .order('sort_order');
      _modesCache = (response as List)
          .map((json) => AICounselingModeConfig.fromJson(json))
          .toList();
      debugPrint('[AIConfigService] Loaded ${_modesCache?.length} counseling modes');
    } catch (e) {
      debugPrint('[AIConfigService] Error fetching modes: $e');
    }
  }

  List<AICounselingModeConfig> get counselingModes =>
      _modesCache ?? AICounselingModeConfig.fallbackModes();

  AICounselingModeConfig? getModeByKey(String modeKey) {
    return counselingModes.cast<AICounselingModeConfig?>().firstWhere(
          (m) => m?.modeKey == modeKey,
          orElse: () => null,
        );
  }

  AICounselingModeConfig get defaultMode {
    return counselingModes.firstWhere(
      (m) => m.isDefault,
      orElse: () => counselingModes.first,
    );
  }

  // ============ Message Occasions ============

  Future<void> _fetchOccasions() async {
    try {
      final response = await _supabase
          .from('admin_message_occasions')
          .select()
          .eq('is_active', true)
          .order('sort_order');
      _occasionsCache = (response as List)
          .map((json) => AIMessageOccasion.fromJson(json))
          .toList();
      debugPrint('[AIConfigService] Loaded ${_occasionsCache?.length} occasions');
    } catch (e) {
      debugPrint('[AIConfigService] Error fetching occasions: $e');
    }
  }

  List<AIMessageOccasion> get messageOccasions =>
      _occasionsCache ?? AIMessageOccasion.fallbackOccasions();

  // ============ Message Tones ============

  Future<void> _fetchTones() async {
    try {
      final response = await _supabase
          .from('admin_message_tones')
          .select()
          .eq('is_active', true)
          .order('sort_order');
      _tonesCache = (response as List)
          .map((json) => AIMessageTone.fromJson(json))
          .toList();
      debugPrint('[AIConfigService] Loaded ${_tonesCache?.length} tones');
    } catch (e) {
      debugPrint('[AIConfigService] Error fetching tones: $e');
    }
  }

  List<AIMessageTone> get messageTones =>
      _tonesCache ?? AIMessageTone.fallbackTones();

  /// Get the default tone key (configured in admin panel)
  String get defaultToneKey {
    final defaultTone = messageTones.cast<AIMessageTone?>().firstWhere(
          (t) => t?.isDefault == true,
          orElse: () => null,
        );
    return defaultTone?.toneKey ?? 'warm';
  }

  // ============ AI Parameters ============

  Future<void> _fetchParameters() async {
    try {
      final response = await _supabase
          .from('admin_ai_parameters')
          .select()
          .eq('is_active', true);
      final params = (response as List)
          .map((json) => AIParameterConfig.fromJson(json))
          .toList();
      _parametersCache = {for (var p in params) p.featureKey: p};
      debugPrint('[AIConfigService] Loaded ${_parametersCache?.length} parameter configs');
    } catch (e) {
      debugPrint('[AIConfigService] Error fetching parameters: $e');
    }
  }

  AIParameterConfig getParametersFor(String featureKey) {
    return _parametersCache?[featureKey] ?? AIParameterConfig.fallback(featureKey);
  }

  // ============ Suggested Prompts ============

  Future<void> _fetchSuggestedPrompts() async {
    try {
      final response = await _supabase
          .from('admin_suggested_prompts')
          .select()
          .eq('is_active', true)
          .order('sort_order');
      _suggestedPromptsCache = (response as List)
          .map((json) => AISuggestedPrompt.fromJson(json))
          .toList();
      debugPrint('[AIConfigService] Loaded ${_suggestedPromptsCache?.length} suggested prompts');
    } catch (e) {
      debugPrint('[AIConfigService] Error fetching suggested prompts: $e');
    }
  }

  List<AISuggestedPrompt> getSuggestedPromptsForMode(String modeKey) {
    final prompts = _suggestedPromptsCache ?? AISuggestedPrompt.fallbackPrompts();
    return prompts.where((p) => p.modeKey == modeKey).toList();
  }

  // ============ Memory Config ============

  Future<void> _fetchMemoryConfig() async {
    try {
      final response = await _supabase
          .from('admin_ai_memory_config')
          .select()
          .eq('is_active', true)
          .single();
      _memoryConfigCache = AIMemorySystemConfig.fromJson(response);
      debugPrint('[AIConfigService] Loaded memory config');
    } catch (e) {
      debugPrint('[AIConfigService] Error fetching memory config: $e');
    }
  }

  AIMemorySystemConfig get memoryConfig =>
      _memoryConfigCache ?? AIMemorySystemConfig.fallback();

  // ============ Memory Categories ============

  Future<void> _fetchMemoryCategories() async {
    try {
      final response = await _supabase
          .from('admin_memory_categories')
          .select()
          .eq('is_active', true)
          .order('sort_order');
      _memoryCategoriesCache = (response as List)
          .map((json) => AIMemoryCategoryConfig.fromJson(json))
          .toList();
      debugPrint('[AIConfigService] Loaded ${_memoryCategoriesCache?.length} memory categories');
    } catch (e) {
      debugPrint('[AIConfigService] Error fetching memory categories: $e');
    }
  }

  List<AIMemoryCategoryConfig> get memoryCategories =>
      _memoryCategoriesCache ?? AIMemoryCategoryConfig.fallbackCategories();

  // ============ Error Messages ============

  Future<void> _fetchErrorMessages() async {
    try {
      final response = await _supabase
          .from('admin_ai_error_messages')
          .select();
      final messages = (response as List)
          .map((json) => AIErrorMessageConfig.fromJson(json))
          .toList();
      _errorMessagesCache = {for (var m in messages) m.errorCode: m};
      debugPrint('[AIConfigService] Loaded ${_errorMessagesCache?.length} error messages');
    } catch (e) {
      debugPrint('[AIConfigService] Error fetching error messages: $e');
    }
  }

  /// Get error message for a specific status code
  String getErrorMessage(int statusCode) {
    final config = _errorMessagesCache?[statusCode];
    if (config != null) {
      return config.messageAr;
    }
    // Check for fallback by code ranges (e.g., 502, 503, 504 -> same message)
    if (statusCode >= 500 && statusCode < 600) {
      final fallback = _errorMessagesCache?[500];
      if (fallback != null) return fallback.messageAr;
    }
    return AIErrorMessageConfig.fallbackMessage(statusCode);
  }

  /// Check if retry button should be shown for this error
  bool shouldShowRetryButton(int statusCode) {
    return _errorMessagesCache?[statusCode]?.showRetryButton ?? true;
  }

  // ============ Streaming Config ============

  Future<void> _fetchStreamingConfig() async {
    try {
      final response = await _supabase
          .from('admin_ai_streaming_config')
          .select()
          .single();
      _streamingConfigCache = AIStreamingConfig.fromJson(response);
      debugPrint('[AIConfigService] Loaded streaming config');
    } catch (e) {
      debugPrint('[AIConfigService] Error fetching streaming config: $e');
    }
  }

  AIStreamingConfig get streamingConfig =>
      _streamingConfigCache ?? AIStreamingConfig.fallback();

  // ============ Communication Scenarios ============

  Future<void> _fetchCommunicationScenarios() async {
    try {
      final response = await _supabase
          .from('admin_communication_scenarios')
          .select()
          .eq('is_active', true)
          .order('sort_order');
      _scenariosCache = (response as List)
          .map((json) => AICommunicationScenario.fromJson(json))
          .toList();
      debugPrint('[AIConfigService] Loaded ${_scenariosCache?.length} communication scenarios');
    } catch (e) {
      debugPrint('[AIConfigService] Error fetching communication scenarios: $e');
    }
  }

  List<AICommunicationScenario> get communicationScenarios =>
      _scenariosCache ?? AICommunicationScenario.fallbackScenarios();

  AICommunicationScenario? getScenario(String scenarioKey) {
    return communicationScenarios.cast<AICommunicationScenario?>().firstWhere(
          (s) => s?.scenarioKey == scenarioKey,
          orElse: () => null,
        );
  }

  // ============ Hardcoded Fallback ============

  static const String _hardcodedPersonality = '''
أنت "واصل"، مساعد ذكي متخصص في صلة الرحم والعلاقات الأسرية.

## شخصيتك الأساسية:
- تتحدث بالعامية السعودية البيضاء بأسلوب دافئ ومحب وطبيعي
- تجسّد قيم الإسلام بشكل طبيعي: المحبة، الرحمة، الصبر، والإحسان

## لهجتك:
- استخدم العامية السعودية البيضاء (المفهومة لجميع السعوديين)
- لا تستخدم الفصحى الأدبية المتكلفة أو اللغة الرسمية
- اكتب كما يتحدث الناس عادةً في الحياة اليومية

## ذكاءك العاطفي:
- تلتقط مشاعر المستخدم من كلماته
- ترد على المشاعر أولاً قبل تقديم النصيحة
- لا تتسرع في الحلول

## قيمك الثابتة:
- صلة الرحم فريضة وليست اختياراً
- العائلة هي أساس المجتمع الصالح
- الصبر والحلم في التعامل مع الخلافات
''';
}

// ============ Config Models ============

class AIIdentityConfig {
  final String aiName;
  final String? aiNameEn;
  final String aiRoleAr;
  final String? aiRoleEn;
  final String greetingMessageAr;
  final String? greetingMessageEn;
  final String dialect;
  final String? personalitySummaryAr;

  AIIdentityConfig({
    required this.aiName,
    this.aiNameEn,
    required this.aiRoleAr,
    this.aiRoleEn,
    required this.greetingMessageAr,
    this.greetingMessageEn,
    required this.dialect,
    this.personalitySummaryAr,
  });

  factory AIIdentityConfig.fromJson(Map<String, dynamic> json) {
    return AIIdentityConfig(
      aiName: json['ai_name'] as String? ?? 'واصل',
      aiNameEn: json['ai_name_en'] as String?,
      aiRoleAr: json['ai_role_ar'] as String? ?? 'مساعد ذكي متخصص في صلة الرحم',
      aiRoleEn: json['ai_role_en'] as String?,
      greetingMessageAr: json['greeting_message_ar'] as String? ?? 'السلام عليكم!',
      greetingMessageEn: json['greeting_message_en'] as String?,
      dialect: json['dialect'] as String? ?? 'saudi_arabic',
      personalitySummaryAr: json['personality_summary_ar'] as String?,
    );
  }

  factory AIIdentityConfig.fallback() {
    return AIIdentityConfig(
      aiName: 'واصل',
      aiNameEn: 'Wasel',
      aiRoleAr: 'مساعد ذكي متخصص في صلة الرحم والعلاقات الأسرية',
      aiRoleEn: 'Smart assistant for family connections',
      greetingMessageAr: 'السلام عليكم! أنا واصل، مساعدك الشخصي لصلة الرحم. كيف يمكنني مساعدتك اليوم؟',
      dialect: 'saudi_arabic',
    );
  }
}

class AIPersonalitySection {
  final String sectionKey;
  final String sectionNameAr;
  final String contentAr;
  final String? contentEn;
  final int priority;

  AIPersonalitySection({
    required this.sectionKey,
    required this.sectionNameAr,
    required this.contentAr,
    this.contentEn,
    required this.priority,
  });

  factory AIPersonalitySection.fromJson(Map<String, dynamic> json) {
    return AIPersonalitySection(
      sectionKey: json['section_key'] as String,
      sectionNameAr: json['section_name_ar'] as String,
      contentAr: json['content_ar'] as String,
      contentEn: json['content_en'] as String?,
      priority: json['priority'] as int? ?? 0,
    );
  }

  static List<AIPersonalitySection> fallbackSections() {
    return [
      AIPersonalitySection(
        sectionKey: 'base',
        sectionNameAr: 'الهوية الأساسية',
        contentAr: 'أنت واصل، مساعد ذكي متخصص في تعزيز صلة الرحم والعلاقات الأسرية. تتحدث بالعامية السعودية البيضاء وتهتم بالقيم الإسلامية.',
        priority: 1,
      ),
      AIPersonalitySection(
        sectionKey: 'values',
        sectionNameAr: 'القيم الإسلامية',
        contentAr: 'تستند في نصائحك إلى تعاليم الإسلام حول صلة الرحم وبر الوالدين والإحسان للأقارب.',
        priority: 2,
      ),
      AIPersonalitySection(
        sectionKey: 'style',
        sectionNameAr: 'أسلوب التواصل',
        contentAr: 'تتحدث بأسلوب ودي ومحترم، تستخدم التشجيع والتحفيز، وتتجنب الأحكام السلبية.',
        priority: 3,
      ),
    ];
  }
}

class AICounselingModeConfig {
  final String modeKey;
  final String displayNameAr;
  final String? displayNameEn;
  final String? descriptionAr;
  final String iconName;
  final String colorHex;
  final String modeInstructions;
  final bool isDefault;
  final int sortOrder;

  AICounselingModeConfig({
    required this.modeKey,
    required this.displayNameAr,
    this.displayNameEn,
    this.descriptionAr,
    required this.iconName,
    required this.colorHex,
    required this.modeInstructions,
    required this.isDefault,
    required this.sortOrder,
  });

  factory AICounselingModeConfig.fromJson(Map<String, dynamic> json) {
    return AICounselingModeConfig(
      modeKey: json['mode_key'] as String,
      displayNameAr: json['display_name_ar'] as String,
      displayNameEn: json['display_name_en'] as String?,
      descriptionAr: json['description_ar'] as String?,
      iconName: json['icon_name'] as String? ?? 'message-circle',
      colorHex: json['color_hex'] as String? ?? '#008080',
      modeInstructions: json['mode_instructions'] as String,
      isDefault: json['is_default'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  static List<AICounselingModeConfig> fallbackModes() {
    return [
      AICounselingModeConfig(
        modeKey: 'general',
        displayNameAr: 'محادثة عامة',
        displayNameEn: 'General Chat',
        descriptionAr: 'محادثة عامة حول صلة الرحم',
        iconName: 'message-circle',
        colorHex: '#008080',
        modeInstructions: 'تحدث بشكل عام عن أي موضوع يتعلق بصلة الرحم والعلاقات الأسرية.',
        isDefault: true,
        sortOrder: 1,
      ),
      AICounselingModeConfig(
        modeKey: 'relationship',
        displayNameAr: 'تحسين العلاقات',
        displayNameEn: 'Improve Relationships',
        descriptionAr: 'نصائح لتحسين العلاقات مع الأقارب',
        iconName: 'heart',
        colorHex: '#E91E63',
        modeInstructions: 'ركز على تقديم نصائح عملية لتحسين وتعزيز العلاقات مع الأقارب.',
        isDefault: false,
        sortOrder: 2,
      ),
      AICounselingModeConfig(
        modeKey: 'conflict',
        displayNameAr: 'حل النزاعات',
        displayNameEn: 'Conflict Resolution',
        descriptionAr: 'مساعدة في حل المشاكل العائلية',
        iconName: 'scale',
        colorHex: '#FF9800',
        modeInstructions: 'ساعد في تحليل المشاكل العائلية واقترح حلولاً عملية وحكيمة.',
        isDefault: false,
        sortOrder: 3,
      ),
      AICounselingModeConfig(
        modeKey: 'communication',
        displayNameAr: 'فن التواصل',
        displayNameEn: 'Communication Skills',
        descriptionAr: 'تطوير مهارات التواصل العائلي',
        iconName: 'users',
        colorHex: '#2196F3',
        modeInstructions: 'قدم نصائح لتحسين مهارات التواصل والحوار مع الأقارب.',
        isDefault: false,
        sortOrder: 4,
      ),
    ];
  }
}

class AIMessageOccasion {
  final String occasionKey;
  final String displayNameAr;
  final String? displayNameEn;
  final String emoji;
  final String? promptAddition;
  final bool seasonal;
  final int sortOrder;

  AIMessageOccasion({
    required this.occasionKey,
    required this.displayNameAr,
    this.displayNameEn,
    required this.emoji,
    this.promptAddition,
    required this.seasonal,
    required this.sortOrder,
  });

  factory AIMessageOccasion.fromJson(Map<String, dynamic> json) {
    return AIMessageOccasion(
      occasionKey: json['occasion_key'] as String,
      displayNameAr: json['display_name_ar'] as String,
      displayNameEn: json['display_name_en'] as String?,
      emoji: json['emoji'] as String,
      promptAddition: json['prompt_addition'] as String?,
      seasonal: json['seasonal'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  static List<AIMessageOccasion> fallbackOccasions() {
    return [
      AIMessageOccasion(occasionKey: 'eid', displayNameAr: 'عيد', emoji: '🎉', seasonal: true, sortOrder: 1),
      AIMessageOccasion(occasionKey: 'ramadan', displayNameAr: 'رمضان', emoji: '🌙', seasonal: true, sortOrder: 2),
      AIMessageOccasion(occasionKey: 'birthday', displayNameAr: 'عيد ميلاد', emoji: '🎂', seasonal: false, sortOrder: 3),
      AIMessageOccasion(occasionKey: 'wedding', displayNameAr: 'زواج', emoji: '💍', seasonal: false, sortOrder: 4),
      AIMessageOccasion(occasionKey: 'graduation', displayNameAr: 'تخرج', emoji: '🎓', seasonal: false, sortOrder: 5),
      AIMessageOccasion(occasionKey: 'newborn', displayNameAr: 'مولود جديد', emoji: '👶', seasonal: false, sortOrder: 6),
      AIMessageOccasion(occasionKey: 'condolence', displayNameAr: 'تعزية', emoji: '🤲', seasonal: false, sortOrder: 7),
      AIMessageOccasion(occasionKey: 'recovery', displayNameAr: 'شفاء', emoji: '💚', seasonal: false, sortOrder: 8),
      AIMessageOccasion(occasionKey: 'missing', displayNameAr: 'اشتياق', emoji: '💭', seasonal: false, sortOrder: 9),
      AIMessageOccasion(occasionKey: 'checkin', displayNameAr: 'اطمئنان', emoji: '👋', seasonal: false, sortOrder: 10),
      AIMessageOccasion(occasionKey: 'apology', displayNameAr: 'اعتذار', emoji: '🙏', seasonal: false, sortOrder: 11),
      AIMessageOccasion(occasionKey: 'thanks', displayNameAr: 'شكر', emoji: '❤️', seasonal: false, sortOrder: 12),
    ];
  }
}

class AIMessageTone {
  final String toneKey;
  final String displayNameAr;
  final String? displayNameEn;
  final String emoji;
  final String? promptModifier;
  final int sortOrder;
  final bool isDefault;

  AIMessageTone({
    required this.toneKey,
    required this.displayNameAr,
    this.displayNameEn,
    required this.emoji,
    this.promptModifier,
    required this.sortOrder,
    this.isDefault = false,
  });

  factory AIMessageTone.fromJson(Map<String, dynamic> json) {
    return AIMessageTone(
      toneKey: json['tone_key'] as String,
      displayNameAr: json['display_name_ar'] as String,
      displayNameEn: json['display_name_en'] as String?,
      emoji: json['emoji'] as String,
      promptModifier: json['prompt_modifier'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  static List<AIMessageTone> fallbackTones() {
    return [
      AIMessageTone(toneKey: 'formal', displayNameAr: 'رسمي', emoji: '👔', promptModifier: 'استخدم لغة رسمية ومحترمة', sortOrder: 1),
      AIMessageTone(toneKey: 'warm', displayNameAr: 'دافئ', emoji: '🤗', promptModifier: 'استخدم لغة دافئة ومحببة', sortOrder: 2, isDefault: true),
      AIMessageTone(toneKey: 'humorous', displayNameAr: 'مرح', emoji: '😄', promptModifier: 'أضف لمسة خفيفة ومرحة', sortOrder: 3),
      AIMessageTone(toneKey: 'religious', displayNameAr: 'ديني', emoji: '🤲', promptModifier: 'أضف آيات أو أدعية مناسبة', sortOrder: 4),
    ];
  }
}

class AIParameterConfig {
  final String featureKey;
  final String displayNameAr;
  final String modelName;
  final double temperature;
  final int maxTokens;
  final int timeoutSeconds;
  final bool streamEnabled;
  final int? outputCount; // For features that generate multiple outputs (e.g., message_generation)

  AIParameterConfig({
    required this.featureKey,
    required this.displayNameAr,
    required this.modelName,
    required this.temperature,
    required this.maxTokens,
    required this.timeoutSeconds,
    required this.streamEnabled,
    this.outputCount,
  });

  factory AIParameterConfig.fromJson(Map<String, dynamic> json) {
    return AIParameterConfig(
      featureKey: json['feature_key'] as String,
      displayNameAr: json['display_name_ar'] as String? ?? '',
      modelName: json['model_name'] as String? ?? 'deepseek',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      maxTokens: json['max_tokens'] as int? ?? 2048,
      timeoutSeconds: json['timeout_seconds'] as int? ?? 30,
      streamEnabled: json['stream_enabled'] as bool? ?? true,
      outputCount: json['output_count'] as int?,
    );
  }

  factory AIParameterConfig.fallback(String featureKey) {
    // Default parameters based on feature
    final defaults = {
      'chat': (temp: 0.7, tokens: 2048, count: null),
      'message_generation': (temp: 0.9, tokens: 2048, count: 3),
      'communication_script': (temp: 0.7, tokens: 2048, count: null),
      'relationship_analysis': (temp: 0.7, tokens: 2048, count: null),
      'smart_reminders': (temp: 0.7, tokens: 1024, count: null),
      'memory_extraction': (temp: 0.3, tokens: 500, count: null),
      'weekly_report': (temp: 0.7, tokens: 1500, count: null),
    };
    final config = defaults[featureKey] ?? (temp: 0.7, tokens: 2048, count: null);

    return AIParameterConfig(
      featureKey: featureKey,
      displayNameAr: featureKey,
      modelName: 'deepseek',
      temperature: config.temp,
      maxTokens: config.tokens,
      timeoutSeconds: 30,
      streamEnabled: true,
      outputCount: config.count,
    );
  }
}

class AISuggestedPrompt {
  final String modeKey;
  final String promptAr;
  final String? promptEn;
  final int sortOrder;

  AISuggestedPrompt({
    required this.modeKey,
    required this.promptAr,
    this.promptEn,
    required this.sortOrder,
  });

  factory AISuggestedPrompt.fromJson(Map<String, dynamic> json) {
    return AISuggestedPrompt(
      modeKey: json['mode_key'] as String,
      promptAr: json['prompt_ar'] as String,
      promptEn: json['prompt_en'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  static List<AISuggestedPrompt> fallbackPrompts() {
    return [
      AISuggestedPrompt(modeKey: 'general', promptAr: 'كيف أحافظ على صلة الرحم؟', sortOrder: 1),
      AISuggestedPrompt(modeKey: 'general', promptAr: 'ما أهمية صلة الرحم في الإسلام؟', sortOrder: 2),
      AISuggestedPrompt(modeKey: 'general', promptAr: 'كيف أتواصل مع قريب بعيد؟', sortOrder: 3),
      AISuggestedPrompt(modeKey: 'relationship', promptAr: 'كيف أحسن علاقتي بوالديّ؟', sortOrder: 1),
      AISuggestedPrompt(modeKey: 'relationship', promptAr: 'كيف أتقرب من أقاربي؟', sortOrder: 2),
      AISuggestedPrompt(modeKey: 'conflict', promptAr: 'هناك خلاف عائلي، كيف أتصرف؟', sortOrder: 1),
      AISuggestedPrompt(modeKey: 'conflict', promptAr: 'كيف أتعامل مع قريب صعب المراس؟', sortOrder: 2),
      AISuggestedPrompt(modeKey: 'communication', promptAr: 'كيف أبدأ محادثة مع قريب؟', sortOrder: 1),
      AISuggestedPrompt(modeKey: 'communication', promptAr: 'ماذا أقول في أول اتصال بعد انقطاع؟', sortOrder: 2),
    ];
  }
}

class AIMemorySystemConfig {
  final int maxMemoriesPerContext;
  final int maxMemoriesForRelative;
  final int maxInsightsDisplayed;
  final int importanceDefault;
  final int importanceMin;
  final int importanceMax;
  final double duplicateMatchThreshold;
  final int cacheDurationMinutes;
  final int autoCleanupDays;
  // Extraction rules - configurable from admin panel
  final bool skipRelativeFacts;
  final List<String> skipKeywords;
  final String extractionInstructionsAr;
  final List<String> extractionExamplesIgnore;
  final List<String> extractionExamplesExtract;

  AIMemorySystemConfig({
    required this.maxMemoriesPerContext,
    required this.maxMemoriesForRelative,
    required this.maxInsightsDisplayed,
    required this.importanceDefault,
    required this.importanceMin,
    required this.importanceMax,
    required this.duplicateMatchThreshold,
    required this.cacheDurationMinutes,
    required this.autoCleanupDays,
    required this.skipRelativeFacts,
    required this.skipKeywords,
    required this.extractionInstructionsAr,
    required this.extractionExamplesIgnore,
    required this.extractionExamplesExtract,
  });

  factory AIMemorySystemConfig.fromJson(Map<String, dynamic> json) {
    return AIMemorySystemConfig(
      maxMemoriesPerContext: json['max_memories_per_context'] as int? ?? 30,
      maxMemoriesForRelative: json['max_memories_for_relative'] as int? ?? 10,
      maxInsightsDisplayed: json['max_insights_displayed'] as int? ?? 5,
      importanceDefault: json['importance_default'] as int? ?? 5,
      importanceMin: json['importance_min'] as int? ?? 1,
      importanceMax: json['importance_max'] as int? ?? 10,
      duplicateMatchThreshold: (json['duplicate_match_threshold'] as num?)?.toDouble() ?? 0.8,
      cacheDurationMinutes: json['cache_duration_minutes'] as int? ?? 30,
      autoCleanupDays: json['auto_cleanup_days'] as int? ?? 365,
      skipRelativeFacts: json['skip_relative_facts'] as bool? ?? true,
      skipKeywords: (json['skip_keywords'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? _defaultSkipKeywords,
      extractionInstructionsAr: json['extraction_instructions_ar'] as String? ?? _defaultExtractionInstructions,
      extractionExamplesIgnore: (json['extraction_examples_ignore'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? _defaultIgnoreExamples,
      extractionExamplesExtract: (json['extraction_examples_extract'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? _defaultExtractExamples,
    );
  }

  factory AIMemorySystemConfig.fallback() {
    return AIMemorySystemConfig(
      maxMemoriesPerContext: 30,
      maxMemoriesForRelative: 10,
      maxInsightsDisplayed: 5,
      importanceDefault: 5,
      importanceMin: 1,
      importanceMax: 10,
      duplicateMatchThreshold: 0.8,
      cacheDurationMinutes: 30,
      autoCleanupDays: 365,
      skipRelativeFacts: true,
      skipKeywords: _defaultSkipKeywords,
      extractionInstructionsAr: _defaultExtractionInstructions,
      extractionExamplesIgnore: _defaultIgnoreExamples,
      extractionExamplesExtract: _defaultExtractExamples,
    );
  }

  // Default skip keywords (relationship terms)
  static const List<String> _defaultSkipKeywords = [
    'اسم', 'اسمه', 'اسمها', 'يدعى', 'تدعى',
    'والد', 'والدة', 'أب', 'أم', 'جد', 'جدة',
    'أخ', 'أخت', 'إخوة', 'أخوات',
    'عم', 'عمة', 'خال', 'خالة',
    'ابن', 'ابنة', 'أبناء', 'بنات',
    'زوج', 'زوجة',
  ];

  // Default extraction instructions
  static const String _defaultExtractionInstructions = '''
⚠️ هام جداً - لا تستخرج هذه المعلومات (موجودة بالفعل في قاعدة البيانات):
- أسماء الأقارب (الأب، الأم، الإخوة، الجد، الجدة، إلخ)
- نوع صلة القرابة (والد، والدة، أخ، أخت، عم، خال، إلخ)
- معلومات أساسية عن الأقارب موجودة في ملفاتهم

✅ استخرج فقط:
- تفضيلات شخصية للمستخدم (أسلوب تواصله، اهتماماته، شخصيته)
- تواريخ مهمة جديدة (مناسبات، ذكريات، أحداث قادمة)
- مشاعر أو مخاوف أو أهداف عبّر عنها المستخدم''';

  // Default ignore examples
  static const List<String> _defaultIgnoreExamples = [
    'اسم والد المستخدم محمد',
    'أم المستخدم اسمها فاطمة',
    'لديه أخ اسمه أحمد',
    'جده/جدته اسمه...',
  ];

  // Default extract examples
  static const List<String> _defaultExtractExamples = [
    'يفضل التواصل صباحاً',
    'يشعر بالذنب لعدم زيارة جدته',
    'ذكرى زواج والديه في شهر رجب',
    'يجد صعوبة في التحدث عن مشاعره',
    'يريد تحسين علاقته بأبيه',
  ];
}

class AIMemoryCategoryConfig {
  final String categoryKey;
  final String displayNameAr;
  final String? displayNameEn;
  final String iconName;
  final int defaultImportance;
  final bool autoExtract;
  final int sortOrder;

  AIMemoryCategoryConfig({
    required this.categoryKey,
    required this.displayNameAr,
    this.displayNameEn,
    required this.iconName,
    required this.defaultImportance,
    required this.autoExtract,
    required this.sortOrder,
  });

  factory AIMemoryCategoryConfig.fromJson(Map<String, dynamic> json) {
    return AIMemoryCategoryConfig(
      categoryKey: json['category_key'] as String,
      displayNameAr: json['display_name_ar'] as String,
      displayNameEn: json['display_name_en'] as String?,
      iconName: json['icon_name'] as String? ?? 'brain',
      defaultImportance: json['default_importance'] as int? ?? 5,
      autoExtract: json['auto_extract'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  static List<AIMemoryCategoryConfig> fallbackCategories() {
    return [
      AIMemoryCategoryConfig(categoryKey: 'user_preference', displayNameAr: 'تفضيلات المستخدم', iconName: 'settings', defaultImportance: 5, autoExtract: true, sortOrder: 1),
      AIMemoryCategoryConfig(categoryKey: 'relative_fact', displayNameAr: 'معلومة عن قريب', iconName: 'user', defaultImportance: 5, autoExtract: true, sortOrder: 2),
      AIMemoryCategoryConfig(categoryKey: 'family_dynamic', displayNameAr: 'ديناميكية عائلية', iconName: 'users', defaultImportance: 5, autoExtract: true, sortOrder: 3),
      AIMemoryCategoryConfig(categoryKey: 'important_date', displayNameAr: 'تاريخ مهم', iconName: 'calendar', defaultImportance: 5, autoExtract: true, sortOrder: 4),
      AIMemoryCategoryConfig(categoryKey: 'conversation_insight', displayNameAr: 'ملاحظة من محادثة', iconName: 'message-circle', defaultImportance: 5, autoExtract: true, sortOrder: 5),
    ];
  }
}

class AIErrorMessageConfig {
  final int errorCode;
  final String messageAr;
  final String? messageEn;
  final bool showRetryButton;

  AIErrorMessageConfig({
    required this.errorCode,
    required this.messageAr,
    this.messageEn,
    required this.showRetryButton,
  });

  factory AIErrorMessageConfig.fromJson(Map<String, dynamic> json) {
    return AIErrorMessageConfig(
      errorCode: json['error_code'] as int,
      messageAr: json['message_ar'] as String,
      messageEn: json['message_en'] as String?,
      showRetryButton: json['show_retry_button'] as bool? ?? true,
    );
  }

  /// Fallback error message when config not loaded
  static String fallbackMessage(int statusCode) {
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
}

class AIStreamingConfig {
  final int sentenceEndDelayMs;
  final int commaDelayMs;
  final int newlineDelayMs;
  final int spaceDelayMs;
  final int wordMinDelayMs;
  final int wordMaxDelayMs;
  final bool isStreamingEnabled;

  AIStreamingConfig({
    required this.sentenceEndDelayMs,
    required this.commaDelayMs,
    required this.newlineDelayMs,
    required this.spaceDelayMs,
    required this.wordMinDelayMs,
    required this.wordMaxDelayMs,
    required this.isStreamingEnabled,
  });

  factory AIStreamingConfig.fromJson(Map<String, dynamic> json) {
    return AIStreamingConfig(
      sentenceEndDelayMs: json['sentence_end_delay_ms'] as int? ?? 10,
      commaDelayMs: json['comma_delay_ms'] as int? ?? 6,
      newlineDelayMs: json['newline_delay_ms'] as int? ?? 12,
      spaceDelayMs: json['space_delay_ms'] as int? ?? 2,
      wordMinDelayMs: json['word_min_delay_ms'] as int? ?? 3,
      wordMaxDelayMs: json['word_max_delay_ms'] as int? ?? 5,
      isStreamingEnabled: json['is_streaming_enabled'] as bool? ?? true,
    );
  }

  factory AIStreamingConfig.fallback() {
    return AIStreamingConfig(
      sentenceEndDelayMs: 10,
      commaDelayMs: 6,
      newlineDelayMs: 12,
      spaceDelayMs: 2,
      wordMinDelayMs: 3,
      wordMaxDelayMs: 5,
      isStreamingEnabled: true,
    );
  }

  /// Get delay for a specific token
  int getDelayForToken(String token) {
    // Sentence end punctuation
    if (token == '.' || token == '؟' || token == '!') {
      return sentenceEndDelayMs;
    }
    // Comma/semicolon
    if (token == '،' || token == '؛' || token == ':') {
      return commaDelayMs;
    }
    // Newline
    if (token == '\n') {
      return newlineDelayMs;
    }
    // Space
    if (token == ' ') {
      return spaceDelayMs;
    }
    // Regular words - variable delay based on length
    return wordMinDelayMs + (token.length % 2) * (wordMaxDelayMs - wordMinDelayMs);
  }
}

/// Communication scenario for AI-assisted conversation scripts
class AICommunicationScenario {
  final String scenarioKey;
  final String titleAr;
  final String? titleEn;
  final String descriptionAr;
  final String? descriptionEn;
  final String emoji;
  final String colorHex;
  final String? promptContext;
  final int sortOrder;

  AICommunicationScenario({
    required this.scenarioKey,
    required this.titleAr,
    this.titleEn,
    required this.descriptionAr,
    this.descriptionEn,
    required this.emoji,
    required this.colorHex,
    this.promptContext,
    required this.sortOrder,
  });

  factory AICommunicationScenario.fromJson(Map<String, dynamic> json) {
    return AICommunicationScenario(
      scenarioKey: json['scenario_key'] as String,
      titleAr: json['title_ar'] as String,
      titleEn: json['title_en'] as String?,
      descriptionAr: json['description_ar'] as String,
      descriptionEn: json['description_en'] as String?,
      emoji: json['emoji'] as String? ?? '💬',
      colorHex: json['color_hex'] as String? ?? '#2196F3',
      promptContext: json['prompt_context'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  /// Fallback scenarios when database not available
  static List<AICommunicationScenario> fallbackScenarios() {
    return [
      AICommunicationScenario(
        scenarioKey: 'apology',
        titleAr: 'طلب مسامحة',
        titleEn: 'Seeking Forgiveness',
        descriptionAr: 'بعد خلاف أو سوء تفاهم',
        descriptionEn: 'After a disagreement or misunderstanding',
        emoji: '🤝',
        colorHex: '#FF9800',
        sortOrder: 1,
      ),
      AICommunicationScenario(
        scenarioKey: 'congratulation',
        titleAr: 'تهنئة',
        titleEn: 'Congratulation',
        descriptionAr: 'بمناسبة سعيدة',
        descriptionEn: 'For a happy occasion',
        emoji: '🎉',
        colorHex: '#4CAF50',
        sortOrder: 2,
      ),
      AICommunicationScenario(
        scenarioKey: 'condolence',
        titleAr: 'مواساة',
        titleEn: 'Condolence',
        descriptionAr: 'في مصيبة أو حزن',
        descriptionEn: 'During grief or hardship',
        emoji: '💐',
        colorHex: '#9C27B0',
        sortOrder: 3,
      ),
      AICommunicationScenario(
        scenarioKey: 'reconnect',
        titleAr: 'إعادة تواصل',
        titleEn: 'Reconnecting',
        descriptionAr: 'بعد انقطاع طويل',
        descriptionEn: 'After a long absence',
        emoji: '🔄',
        colorHex: '#2196F3',
        sortOrder: 4,
      ),
      AICommunicationScenario(
        scenarioKey: 'gratitude',
        titleAr: 'شكر وامتنان',
        titleEn: 'Gratitude',
        descriptionAr: 'على معروف أو مساعدة',
        descriptionEn: 'For a favor or help',
        emoji: '🙏',
        colorHex: '#009688',
        sortOrder: 5,
      ),
      AICommunicationScenario(
        scenarioKey: 'sensitive',
        titleAr: 'موضوع حساس',
        titleEn: 'Sensitive Topic',
        descriptionAr: 'مناقشة أمر صعب',
        descriptionEn: 'Discussing a difficult matter',
        emoji: '💬',
        colorHex: '#FFC107',
        sortOrder: 6,
      ),
    ];
  }
}
