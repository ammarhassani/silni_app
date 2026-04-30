import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cache_config_service.dart';

/// Model for an onboarding screen from admin_onboarding_screens table
class OnboardingScreenConfig {
  final String id;
  final int screenOrder;
  final String titleAr;
  final String? titleEn;
  final String? subtitleAr;
  final String? subtitleEn;
  final String? imageUrl;
  final String? animationName;
  final String backgroundColor;
  final String? backgroundGradientStart;
  final String? backgroundGradientEnd;
  final String textColor;
  final String? accentColor;
  final String buttonTextAr;
  final String? buttonTextEn;
  final String? buttonColor;
  final bool skipEnabled;
  final int? autoAdvanceSeconds;
  final List<String> showForTiers;
  final bool isActive;

  /// Phase 9.X.D.B: per-step action discriminator. Drives the wizard
  /// renderer's branching. Known values:
  ///   'confirm_name', 'add_relative_household', 'add_relative_extended',
  ///   'set_reminder_pref_and_permission', 'finish', 'next' (default).
  final String actionType;

  /// Optional route for steps that push another screen (currently unused —
  /// the wizard handles routing via `actionType`, but kept for future
  /// admin-driven pushes).
  final String? route;

  /// Per-step config (e.g. `{"min_count": 1, "category": "extended"}`).
  final Map<String, dynamic> metadata;

  OnboardingScreenConfig({
    required this.id,
    required this.screenOrder,
    required this.titleAr,
    this.titleEn,
    this.subtitleAr,
    this.subtitleEn,
    this.imageUrl,
    this.animationName,
    required this.backgroundColor,
    this.backgroundGradientStart,
    this.backgroundGradientEnd,
    required this.textColor,
    this.accentColor,
    required this.buttonTextAr,
    this.buttonTextEn,
    this.buttonColor,
    required this.skipEnabled,
    this.autoAdvanceSeconds,
    required this.showForTiers,
    required this.isActive,
    this.actionType = 'next',
    this.route,
    this.metadata = const {},
  });

  factory OnboardingScreenConfig.fromJson(Map<String, dynamic> json) {
    return OnboardingScreenConfig(
      id: json['id'] as String,
      screenOrder: json['screen_order'] as int,
      titleAr: json['title_ar'] as String,
      titleEn: json['title_en'] as String?,
      subtitleAr: json['subtitle_ar'] as String?,
      subtitleEn: json['subtitle_en'] as String?,
      imageUrl: json['image_url'] as String?,
      animationName: json['animation_name'] as String?,
      backgroundColor: json['background_color'] as String? ?? '#FFFFFF',
      backgroundGradientStart: json['background_gradient_start'] as String?,
      backgroundGradientEnd: json['background_gradient_end'] as String?,
      textColor: json['text_color'] as String? ?? '#1F2937',
      accentColor: json['accent_color'] as String?,
      buttonTextAr: json['button_text_ar'] as String? ?? 'التالي',
      buttonTextEn: json['button_text_en'] as String?,
      buttonColor: json['button_color'] as String?,
      skipEnabled: json['skip_enabled'] as bool? ?? true,
      autoAdvanceSeconds: json['auto_advance_seconds'] as int?,
      showForTiers: (json['show_for_tiers'] as List<dynamic>?)?.cast<String>() ?? ['free', 'max'],
      isActive: json['is_active'] as bool? ?? true,
      actionType: json['action_type'] as String? ?? 'next',
      route: json['route'] as String?,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  /// Parse hex color string to Color
  Color get backgroundColorParsed => _parseColor(backgroundColor);
  Color get textColorParsed => _parseColor(textColor);
  Color? get backgroundGradientStartParsed =>
      backgroundGradientStart != null ? _parseColor(backgroundGradientStart!) : null;
  Color? get backgroundGradientEndParsed =>
      backgroundGradientEnd != null ? _parseColor(backgroundGradientEnd!) : null;
  Color? get accentColorParsed => accentColor != null ? _parseColor(accentColor!) : null;
  Color? get buttonColorParsed => buttonColor != null ? _parseColor(buttonColor!) : null;

  /// Check if this screen should be shown for a tier
  bool shouldShowFor(String tier) => showForTiers.contains(tier);

  /// Get gradient if defined
  LinearGradient? get backgroundGradient {
    if (backgroundGradientStart != null) {
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          backgroundGradientStartParsed!,
          backgroundGradientEndParsed ?? backgroundColorParsed,
        ],
      );
    }
    return null;
  }

  static Color _parseColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

/// Service for fetching and caching onboarding configuration from Supabase
class OnboardingConfigService {
  OnboardingConfigService._();
  static final OnboardingConfigService instance = OnboardingConfigService._();

  // Use lazy initialization to avoid accessing Supabase before it's initialized
  SupabaseClient get _supabase => Supabase.instance.client;

  // Cache
  List<OnboardingScreenConfig>? _screensCache;
  DateTime? _lastFetchTime;

  // Cache duration from remote config
  final CacheConfigService _cacheConfig = CacheConfigService();
  static const String _serviceKey = 'onboarding_config';

  // Fallback screens when not loaded — mirror the prod seed (Phase 9.X.D.B1)
  // so the wizard works offline / pre-fetch. Update both this and the prod
  // migration in lockstep when seed content changes.
  static List<OnboardingScreenConfig> get _fallbackScreens => [
    OnboardingScreenConfig(
      id: 'fallback-1',
      screenOrder: 1,
      titleAr: 'أهلاً بك في صِلْني',
      titleEn: 'Welcome to Silni',
      subtitleAr: 'لنبدأ معاً في تعزيز صلة رحمك. سنحتاج دقيقتين لإعداد تجربتك.',
      subtitleEn: "Let's set up your experience together. Two minutes to get going.",
      animationName: 'welcome',
      backgroundColor: '#FFFFFF',
      textColor: '#1F2937',
      buttonTextAr: 'لنبدأ',
      buttonTextEn: "Let's start",
      skipEnabled: false,
      showForTiers: ['free', 'max'],
      isActive: true,
      actionType: 'confirm_name',
      metadata: const {'prompt_for_name': true},
    ),
    OnboardingScreenConfig(
      id: 'fallback-2',
      screenOrder: 2,
      titleAr: 'من يعيش معك في نفس البيت؟',
      titleEn: 'Who lives with you?',
      subtitleAr: 'أضف من تتواصل معهم يومياً بشكل طبيعي. لن نزعجك بتذكيرات لمن تراهم كل يوم.',
      subtitleEn: "Add the people you see every day. We won't remind you about those.",
      animationName: 'household',
      backgroundColor: '#FFFFFF',
      textColor: '#1F2937',
      buttonTextAr: 'إضافة من أهل البيت',
      buttonTextEn: 'Add household',
      skipEnabled: true,
      showForTiers: ['free', 'max'],
      isActive: true,
      actionType: 'add_relative_household',
      metadata: const {'min_count': 0, 'category': 'household'},
    ),
    OnboardingScreenConfig(
      id: 'fallback-3',
      screenOrder: 3,
      titleAr: 'من تريد أن تحافظ على صلتك بهم؟',
      titleEn: 'Who do you want to stay connected with?',
      subtitleAr: 'أهل وأقارب تريد التواصل معهم بانتظام. سنذكّرك بهم في الوقت المناسب.',
      subtitleEn: "Family you want to keep in regular contact with. We'll remind you at the right time.",
      animationName: 'extended',
      backgroundColor: '#FFFFFF',
      textColor: '#1F2937',
      buttonTextAr: 'إضافة من الأقارب',
      buttonTextEn: 'Add extended family',
      skipEnabled: true,
      showForTiers: ['free', 'max'],
      isActive: true,
      actionType: 'add_relative_extended',
      metadata: const {'min_count': 1, 'category': 'extended'},
    ),
    OnboardingScreenConfig(
      id: 'fallback-4',
      screenOrder: 4,
      titleAr: 'كيف تفضّل أن نذكّرك؟',
      titleEn: 'How would you like reminders?',
      subtitleAr: 'سنرسل تذكيراً واحداً في اليوم بأنسب وقت لك. اختر الوقت الذي يناسبك.',
      subtitleEn: 'One reminder a day at your preferred time.',
      animationName: 'reminders',
      backgroundColor: '#FFFFFF',
      textColor: '#1F2937',
      buttonTextAr: 'حدد الوقت',
      buttonTextEn: 'Set time',
      skipEnabled: true,
      showForTiers: ['free', 'max'],
      isActive: true,
      actionType: 'set_reminder_pref_and_permission',
      metadata: const {'default_time': '09:00', 'default_frequency': 'daily'},
    ),
    // Anees "finish" step removed (founder request 2026-04-30): paywall
    // takes its place at the end of the wizard. The DB row was set to
    // is_active=false; the fallback list mirrors that. The wizard now
    // detects "last step reached" on the reminder step and runs the
    // finish flow directly, which pushes the paywall.
  ];

  /// Initialize the service (call on app start)
  Future<void> initialize() async {
    await _fetchScreens();
  }

  /// Fetch all screens from Supabase
  Future<void> _fetchScreens() async {
    try {
      final response = await _supabase
          .from('admin_onboarding_screens')
          .select()
          .eq('is_active', true)
          // CRITICAL: postgrest .order() defaults to DESCENDING. Without
          // `ascending: true` the wizard renders the last screen first.
          .order('screen_order', ascending: true);

      _screensCache = (response as List)
          .map((json) => OnboardingScreenConfig.fromJson(json))
          .toList();
      _lastFetchTime = DateTime.now();
    } catch (_) {
      // Keep existing cache if available
    }
  }

  /// Get all onboarding screens
  List<OnboardingScreenConfig> getScreens({String? forTier}) {
    final screens = _screensCache ?? _fallbackScreens;

    if (forTier != null) {
      return screens.where((s) => s.shouldShowFor(forTier)).toList();
    }

    return screens;
  }

  /// Get a specific screen by order
  OnboardingScreenConfig? getScreen(int order) {
    final screens = _screensCache ?? _fallbackScreens;
    try {
      return screens.firstWhere((s) => s.screenOrder == order);
    } catch (_) {
      return null;
    }
  }

  /// Get the total number of screens
  int get screenCount => (_screensCache ?? _fallbackScreens).length;

  /// Get screens for a specific tier
  List<OnboardingScreenConfig> getScreensForTier(String tier) {
    return getScreens(forTier: tier);
  }

  /// Check if any screen has auto-advance enabled
  bool get hasAutoAdvance {
    final screens = _screensCache ?? _fallbackScreens;
    return screens.any((s) => s.autoAdvanceSeconds != null);
  }

  /// Check if skip is enabled for any screen
  bool get hasSkipOption {
    final screens = _screensCache ?? _fallbackScreens;
    return screens.any((s) => s.skipEnabled);
  }

  /// Refresh screens from server
  Future<void> refresh() async {
    await _fetchScreens();
  }

  /// Check if cache needs refresh
  bool get needsRefresh {
    if (_lastFetchTime == null) return true;
    return _cacheConfig.isCacheExpired(_serviceKey, _lastFetchTime);
  }

  /// Ensure screens are fresh
  Future<void> ensureFresh() async {
    if (needsRefresh) {
      await _fetchScreens();
    }
  }

  /// Clear cache
  void clearCache() {
    _screensCache = null;
    _lastFetchTime = null;
  }

  /// Check if screens are loaded
  bool get isLoaded => _screensCache != null;
}
