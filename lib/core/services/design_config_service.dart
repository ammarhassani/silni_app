import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_colors.dart';
import 'cache_config_service.dart';

/// Service for fetching and caching design configuration from admin tables.
///
/// Provides dynamic colors, themes, and animation settings from the CMS.
/// Falls back to hardcoded defaults when config is not loaded or unavailable.
class DesignConfigService {
  DesignConfigService._();
  static final DesignConfigService instance = DesignConfigService._();

  final _supabase = Supabase.instance.client;

  // Cache variables
  Map<String, AdminColor>? _colorsCache;
  List<AdminTheme>? _themesCache;
  Map<String, AdminAnimation>? _animationsCache;
  List<AdminPatternAnimation>? _patternAnimationsCache;
  DateTime? _lastFetchTime;

  // Cache duration from remote config
  final CacheConfigService _cacheConfig = CacheConfigService();
  static const String _serviceKey = 'design_config';

  bool get _isCacheValid {
    if (_lastFetchTime == null) return false;
    return !_cacheConfig.isCacheExpired(_serviceKey, _lastFetchTime);
  }

  /// Check if config is loaded
  bool get isLoaded => _lastFetchTime != null;

  /// Initialize and load all design configs
  Future<void> initialize() async {
    if (!_isCacheValid) {
      await refresh();
    }
  }

  /// Refresh all configs from server
  Future<void> refresh() async {
    try {
      await Future.wait([
        _fetchColors(),
        _fetchThemes(),
        _fetchAnimations(),
        _fetchPatternAnimations(),
      ]);
      _lastFetchTime = DateTime.now();
    } catch (_) {
      // Config refresh failed silently
    }
  }

  /// Clear cache
  void clearCache() {
    _colorsCache = null;
    _themesCache = null;
    _animationsCache = null;
    _patternAnimationsCache = null;
    _lastFetchTime = null;
  }

  // ============ Colors ============

  Future<void> _fetchColors() async {
    try {
      final response = await _supabase
          .from('admin_colors')
          .select()
          .eq('is_active', true)
          .order('sort_order');
      final colors = (response as List)
          .map((json) => AdminColor.fromJson(json))
          .toList();
      _colorsCache = {for (var c in colors) c.colorKey: c};
    } catch (_) {
      // Colors fetch failed silently
    }
  }

  /// Get a color by key with fallback
  Color getColor(String colorKey, [Color? fallback]) {
    final adminColor = _colorsCache?[colorKey];
    if (adminColor != null) {
      return adminColor.color;
    }
    return fallback ?? _getDefaultColor(colorKey);
  }

  /// Get the primary brand color (gold)
  Color get primaryAccent => getColor('gold', AppColors.goldenGradient.colors[0]);

  /// Get the primary theme color (teal)
  Color get primaryColor => getColor('teal', const Color(0xFF008080));

  /// Get all colors as a map
  Map<String, Color> get allColors {
    if (_colorsCache == null) return {};
    return {for (var e in _colorsCache!.entries) e.key: e.value.color};
  }

  Color _getDefaultColor(String key) {
    // Hardcoded fallbacks for known color keys
    switch (key) {
      case 'gold':
        return const Color(0xFFD4AF37);
      case 'gold_light':
        return const Color(0xFFE6C65C);
      case 'gold_dark':
        return const Color(0xFFB8962E);
      case 'teal':
        return const Color(0xFF008080);
      case 'teal_light':
        return const Color(0xFF4DB6AC);
      case 'teal_dark':
        return const Color(0xFF006666);
      case 'green':
        return const Color(0xFF2E7D32);
      case 'green_light':
        return const Color(0xFF4CAF50);
      case 'green_dark':
        return const Color(0xFF1B5E20);
      default:
        return Colors.grey;
    }
  }

  // ============ Themes ============

  Future<void> _fetchThemes() async {
    try {
      final response = await _supabase
          .from('admin_themes')
          .select()
          .eq('is_active', true)
          .order('sort_order');
      _themesCache = (response as List)
          .map((json) => AdminTheme.fromJson(json))
          .toList();
    } catch (_) {
      // Themes fetch failed silently
    }
  }

  /// Get all available themes
  List<AdminTheme> get themes => _themesCache ?? [];

  /// Get the default theme
  AdminTheme? get defaultTheme {
    return themes.cast<AdminTheme?>().firstWhere(
          (t) => t?.isDefault == true,
          orElse: () => themes.isNotEmpty ? themes.first : null,
        );
  }

  /// Get a theme by key
  AdminTheme? getTheme(String themeKey) {
    return themes.cast<AdminTheme?>().firstWhere(
          (t) => t?.themeKey == themeKey,
          orElse: () => null,
        );
  }

  /// Get all free (non-premium) themes
  List<AdminTheme> get freeThemes {
    return themes.where((t) => !t.isPremium).toList();
  }

  /// Get all premium themes
  List<AdminTheme> get premiumThemes {
    return themes.where((t) => t.isPremium).toList();
  }

  // ============ Animations ============

  Future<void> _fetchAnimations() async {
    try {
      final response = await _supabase
          .from('admin_animations')
          .select()
          .eq('is_active', true);
      final animations = (response as List)
          .map((json) => AdminAnimation.fromJson(json))
          .toList();
      _animationsCache = {for (var a in animations) a.animationKey: a};
    } catch (_) {
      // Animations fetch failed silently
    }
  }

  /// Get animation duration by key
  Duration getAnimationDuration(String animationKey, [Duration? fallback]) {
    final animation = _animationsCache?[animationKey];
    if (animation != null) {
      return animation.duration;
    }
    return fallback ?? _getDefaultDuration(animationKey);
  }

  /// Get animation curve by key
  Curve getAnimationCurve(String animationKey, [Curve? fallback]) {
    final animation = _animationsCache?[animationKey];
    if (animation != null) {
      return animation.curve;
    }
    return fallback ?? Curves.easeOut;
  }

  Duration _getDefaultDuration(String key) {
    switch (key) {
      case 'instant':
        return const Duration(milliseconds: 100);
      case 'fast':
        return const Duration(milliseconds: 200);
      case 'normal':
        return const Duration(milliseconds: 300);
      case 'modal':
        return const Duration(milliseconds: 400);
      case 'slow':
        return const Duration(milliseconds: 500);
      default:
        return const Duration(milliseconds: 300);
    }
  }

  // ============ Pattern Animations ============

  Future<void> _fetchPatternAnimations() async {
    try {
      final response = await _supabase
          .from('admin_pattern_animations')
          .select()
          .eq('is_active', true)
          .order('sort_order');
      _patternAnimationsCache = (response as List)
          .map((json) => AdminPatternAnimation.fromJson(json))
          .toList();
    } catch (_) {
      // Pattern animations fetch failed silently
    }
  }

  /// Get all pattern animations
  List<AdminPatternAnimation> get patternAnimations => _patternAnimationsCache ?? [];

  /// Get a pattern animation by key
  AdminPatternAnimation? getPatternAnimation(String effectKey) {
    return patternAnimations.cast<AdminPatternAnimation?>().firstWhere(
          (p) => p?.effectKey == effectKey,
          orElse: () => null,
        );
  }

  /// Get all enabled pattern animations (default_enabled = true)
  List<AdminPatternAnimation> get enabledPatternAnimations {
    return patternAnimations.where((p) => p.defaultEnabled).toList();
  }

  /// Get all free (non-premium) pattern animations
  List<AdminPatternAnimation> get freePatternAnimations {
    return patternAnimations.where((p) => !p.isPremium).toList();
  }

  /// Get all premium pattern animations
  List<AdminPatternAnimation> get premiumPatternAnimations {
    return patternAnimations.where((p) => p.isPremium).toList();
  }

  /// Check if a pattern effect is enabled by default
  bool isPatternEnabledByDefault(String effectKey) {
    return getPatternAnimation(effectKey)?.defaultEnabled ?? false;
  }

  /// Get the default intensity for a pattern effect
  double getPatternDefaultIntensity(String effectKey) {
    return getPatternAnimation(effectKey)?.defaultIntensity ?? 0.5;
  }
}

// ============ Models ============

/// Model for color configuration from admin_colors table
class AdminColor {
  final String id;
  final String colorKey;
  final String displayNameAr;
  final String? displayNameEn;
  final String hexValue;
  final Map<String, dynamic>? rgbValue;
  final String? usageContext;
  final bool isPrimary;
  final int sortOrder;

  AdminColor({
    required this.id,
    required this.colorKey,
    required this.displayNameAr,
    this.displayNameEn,
    required this.hexValue,
    this.rgbValue,
    this.usageContext,
    required this.isPrimary,
    required this.sortOrder,
  });

  factory AdminColor.fromJson(Map<String, dynamic> json) {
    return AdminColor(
      id: json['id'] as String,
      colorKey: json['color_key'] as String,
      displayNameAr: json['display_name_ar'] as String,
      displayNameEn: json['display_name_en'] as String?,
      hexValue: json['hex_value'] as String,
      rgbValue: json['rgb_value'] as Map<String, dynamic>?,
      usageContext: json['usage_context'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  /// Get the color as a Flutter Color
  Color get color {
    try {
      final hex = hexValue.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}

/// Model for theme configuration from admin_themes table
class AdminTheme {
  final String id;
  final String themeKey;
  final String displayNameAr;
  final String? displayNameEn;
  final bool isDark;
  final Map<String, dynamic> colors;
  final Map<String, dynamic> gradients;
  final Map<String, dynamic> shadows;
  final bool isPremium;
  final bool isDefault;
  final String? previewImageUrl;
  final int sortOrder;

  AdminTheme({
    required this.id,
    required this.themeKey,
    required this.displayNameAr,
    this.displayNameEn,
    required this.isDark,
    required this.colors,
    required this.gradients,
    required this.shadows,
    required this.isPremium,
    required this.isDefault,
    this.previewImageUrl,
    required this.sortOrder,
  });

  factory AdminTheme.fromJson(Map<String, dynamic> json) {
    return AdminTheme(
      id: json['id'] as String,
      themeKey: json['theme_key'] as String,
      displayNameAr: json['display_name_ar'] as String,
      displayNameEn: json['display_name_en'] as String?,
      isDark: json['is_dark'] as bool? ?? false,
      colors: (json['colors'] as Map<String, dynamic>?) ?? {},
      gradients: (json['gradients'] as Map<String, dynamic>?) ?? {},
      shadows: (json['shadows'] as Map<String, dynamic>?) ?? {},
      isPremium: json['is_premium'] as bool? ?? false,
      isDefault: json['is_default'] as bool? ?? false,
      previewImageUrl: json['preview_image_url'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  /// Get a color from this theme by key
  Color? getColor(String key) {
    final colorData = colors[key];
    if (colorData == null) return null;
    if (colorData is String) {
      try {
        final hex = colorData.replaceFirst('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}

/// Model for animation configuration from admin_animations table
class AdminAnimation {
  final String id;
  final String animationKey;
  final String displayNameAr;
  final String? displayNameEn;
  final int durationMs;
  final String curveString;
  final String? description;
  final String? usageContext;

  AdminAnimation({
    required this.id,
    required this.animationKey,
    required this.displayNameAr,
    this.displayNameEn,
    required this.durationMs,
    required this.curveString,
    this.description,
    this.usageContext,
  });

  factory AdminAnimation.fromJson(Map<String, dynamic> json) {
    return AdminAnimation(
      id: json['id'] as String,
      animationKey: json['animation_key'] as String,
      displayNameAr: json['display_name_ar'] as String,
      displayNameEn: json['display_name_en'] as String?,
      durationMs: json['duration_ms'] as int? ?? 300,
      curveString: json['curve'] as String? ?? 'easeOut',
      description: json['description'] as String?,
      usageContext: json['usage_context'] as String?,
    );
  }

  /// Get the duration as a Duration
  Duration get duration => Duration(milliseconds: durationMs);

  /// Get the curve as a Flutter Curve
  Curve get curve {
    switch (curveString) {
      case 'linear':
        return Curves.linear;
      case 'easeIn':
        return Curves.easeIn;
      case 'easeOut':
        return Curves.easeOut;
      case 'easeInOut':
        return Curves.easeInOut;
      case 'easeOutBack':
        return Curves.easeOutBack;
      case 'bounceOut':
        return Curves.bounceOut;
      case 'elasticOut':
        return Curves.elasticOut;
      default:
        return Curves.easeOut;
    }
  }
}

/// Model for pattern animation from admin_pattern_animations table
class AdminPatternAnimation {
  final String id;
  final String effectKey;
  final String displayNameAr;
  final String? displayNameEn;
  final String? descriptionAr;
  final bool defaultEnabled;
  final String batteryImpact; // 'low', 'medium', 'high'
  final double defaultIntensity;
  final String settingsKey;
  final bool isPremium;
  final int sortOrder;

  AdminPatternAnimation({
    required this.id,
    required this.effectKey,
    required this.displayNameAr,
    this.displayNameEn,
    this.descriptionAr,
    required this.defaultEnabled,
    required this.batteryImpact,
    required this.defaultIntensity,
    required this.settingsKey,
    required this.isPremium,
    required this.sortOrder,
  });

  factory AdminPatternAnimation.fromJson(Map<String, dynamic> json) {
    return AdminPatternAnimation(
      id: json['id'] as String,
      effectKey: json['effect_key'] as String,
      displayNameAr: json['display_name_ar'] as String,
      displayNameEn: json['display_name_en'] as String?,
      descriptionAr: json['description_ar'] as String?,
      defaultEnabled: json['default_enabled'] as bool? ?? true,
      batteryImpact: json['battery_impact'] as String? ?? 'low',
      defaultIntensity: (json['default_intensity'] as num?)?.toDouble() ?? 0.5,
      settingsKey: json['settings_key'] as String,
      isPremium: json['is_premium'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  /// Check if this is a low battery impact effect
  bool get isLowImpact => batteryImpact == 'low';

  /// Check if this is a high battery impact effect
  bool get isHighImpact => batteryImpact == 'high';
}
