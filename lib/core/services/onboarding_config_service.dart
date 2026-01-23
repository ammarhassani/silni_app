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

  // Fallback screens when not loaded
  static List<OnboardingScreenConfig> get _fallbackScreens => [
    OnboardingScreenConfig(
      id: 'fallback-1',
      screenOrder: 1,
      titleAr: 'مرحباً بك في صِلني',
      titleEn: 'Welcome to Silni',
      subtitleAr: 'تطبيق يساعدك على التواصل مع أقاربك والحفاظ على صلة الرحم',
      subtitleEn: 'An app that helps you stay connected with your relatives',
      animationName: 'onboarding_welcome',
      backgroundColor: '#FFFFFF',
      textColor: '#1F2937',
      buttonTextAr: 'التالي',
      skipEnabled: true,
      showForTiers: ['free', 'max'],
      isActive: true,
    ),
    OnboardingScreenConfig(
      id: 'fallback-2',
      screenOrder: 2,
      titleAr: 'تذكيرات ذكية',
      titleEn: 'Smart Reminders',
      subtitleAr: 'لا تنسَ صلة أرحامك مع تذكيرات مخصصة لكل قريب',
      subtitleEn: 'Never forget to connect with personalized reminders',
      animationName: 'onboarding_reminders',
      backgroundColor: '#FFFFFF',
      textColor: '#1F2937',
      buttonTextAr: 'التالي',
      skipEnabled: true,
      showForTiers: ['free', 'max'],
      isActive: true,
    ),
    OnboardingScreenConfig(
      id: 'fallback-3',
      screenOrder: 3,
      titleAr: 'ابدأ رحلتك',
      titleEn: 'Start Your Journey',
      subtitleAr: 'سجّل الآن وابدأ صلة أرحامك',
      subtitleEn: 'Sign up now and start connecting',
      animationName: 'onboarding_start',
      backgroundColor: '#10B981',
      textColor: '#FFFFFF',
      buttonTextAr: 'ابدأ الآن',
      skipEnabled: false,
      showForTiers: ['free', 'max'],
      isActive: true,
    ),
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
          .order('screen_order');

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
