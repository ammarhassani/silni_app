import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_themes.dart';
import 'dynamic_theme.dart';
import '../services/app_logger_service.dart';

/// Theme state that supports both hardcoded and custom admin themes.
///
/// Stores the theme key as a string to support arbitrary admin theme keys,
/// while providing backward-compatible access via [appThemeType].
class ThemeState {
  /// The theme key (e.g., 'default', 'lavender', or custom admin keys)
  final String themeKey;

  const ThemeState(this.themeKey);

  /// Default theme state
  static const ThemeState defaultTheme = ThemeState('default');

  /// Get the AppThemeType for backward compatibility.
  /// Returns [AppThemeType.defaultGreen] if key doesn't match any enum value.
  AppThemeType get appThemeType => AppThemeType.fromString(themeKey);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeState &&
          runtimeType == other.runtimeType &&
          themeKey == other.themeKey;

  @override
  int get hashCode => themeKey.hashCode;
}

/// Theme provider for managing app theme.
///
/// Supports both hardcoded [AppThemeType] themes and custom admin themes
/// by storing the theme key as a string.
class ThemeNotifier extends StateNotifier<ThemeState> {
  final AppLoggerService _logger = AppLoggerService();

  ThemeNotifier() : super(ThemeState.defaultTheme) {
    _loadTheme();
  }

  /// Load saved theme from shared preferences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeKey = prefs.getString('app_theme');
      if (themeKey != null) {
        state = ThemeState(themeKey);
      }
    } catch (e) {
      _logger.warning(
        'Failed to load theme from preferences, using default',
        category: LogCategory.service,
        tag: 'ThemeNotifier',
        metadata: {'error': e.toString()},
      );
      state = ThemeState.defaultTheme;
    }
  }

  /// Change theme by key (supports both enum values and custom admin keys)
  Future<void> setThemeByKey(String themeKey) async {
    state = ThemeState(themeKey);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_theme', themeKey);
    } catch (e) {
      _logger.warning(
        'Failed to persist theme to preferences',
        category: LogCategory.service,
        tag: 'ThemeNotifier',
        metadata: {'themeKey': themeKey, 'error': e.toString()},
      );
    }
  }

  /// Change theme using AppThemeType (backward compatibility)
  Future<void> setTheme(AppThemeType theme) async {
    await setThemeByKey(theme.value);
  }
}

/// Provider for theme management (returns ThemeState with key)
final themeStateProvider =
    StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

/// Provider for current theme key as string
final themeKeyProvider = Provider<String>((ref) {
  return ref.watch(themeStateProvider).themeKey;
});

/// Provider for AppThemeType (backward compatibility)
/// Note: Returns defaultGreen for custom admin themes not in the enum
final themeProvider = Provider<AppThemeType>((ref) {
  return ref.watch(themeStateProvider).appThemeType;
});

/// Dissolves theme colors over 500ms with a staggered cascade.
///
/// Different UI layers transition at different speeds:
/// - **Lead**: primary, accent, secondary, gradients (fastest — identity shifts first)
/// - **Mid**: backgrounds, surfaces, glass, cards
/// - **Trail**: text colors (slowest — text settles on the new background last)
///
/// This creates a "dissolving" effect instead of a uniform fade.
class AnimatedThemeColorsNotifier extends StateNotifier<ThemeColors> {
  AnimatedThemeColorsNotifier(super.initial);

  Timer? _timer;

  /// Dissolve from the current colors to [target] over 500ms.
  void animateTo(ThemeColors target) {
    final from = state;
    _timer?.cancel();
    int elapsed = 0;
    const durationMs = 500;
    const frameMs = 16; // ~60 fps

    _timer = Timer.periodic(
      const Duration(milliseconds: frameMs),
      (timer) {
        elapsed += frameMs;
        final t = (elapsed / durationMs).clamp(0.0, 1.0);

        // Staggered dissolve: each layer has its own timing
        final lead = Curves.easeOutCubic
            .transform((t * 1.4).clamp(0.0, 1.0)); // fastest
        final mid = Curves.easeOutCubic
            .transform((t * 1.15).clamp(0.0, 1.0));
        final follow = Curves.easeOutCubic.transform(t);
        final trail = Curves.easeOutCubic
            .transform(((t - 0.08) * 1.15).clamp(0.0, 1.0)); // text last

        state = ThemeColors(
          // ── Lead: identity colors + gradients ──
          primary: Color.lerp(from.primary, target.primary, lead)!,
          primaryLight:
              Color.lerp(from.primaryLight, target.primaryLight, lead)!,
          primaryDark:
              Color.lerp(from.primaryDark, target.primaryDark, lead)!,
          secondary: Color.lerp(from.secondary, target.secondary, lead)!,
          accent: Color.lerp(from.accent, target.accent, lead)!,
          primaryGradient: LinearGradient.lerp(
              from.primaryGradient, target.primaryGradient, lead)!,
          backgroundGradient: LinearGradient.lerp(
              from.backgroundGradient, target.backgroundGradient, lead)!,
          goldenGradient: LinearGradient.lerp(
              from.goldenGradient, target.goldenGradient, lead)!,
          streakFire: LinearGradient.lerp(
              from.streakFire, target.streakFire, lead)!,
          healthyGradient: LinearGradient.lerp(
              from.healthyGradient, target.healthyGradient, lead)!,
          warningGradient: LinearGradient.lerp(
              from.warningGradient, target.warningGradient, lead)!,
          dangerGradient: LinearGradient.lerp(
              from.dangerGradient, target.dangerGradient, lead)!,
          tierLegendaryGradient: LinearGradient.lerp(
              from.tierLegendaryGradient,
              target.tierLegendaryGradient,
              lead)!,
          tierEpicGradient: LinearGradient.lerp(
              from.tierEpicGradient, target.tierEpicGradient, lead)!,
          tierRareGradient: LinearGradient.lerp(
              from.tierRareGradient, target.tierRareGradient, lead)!,
          tierStarterGradient: LinearGradient.lerp(
              from.tierStarterGradient,
              target.tierStarterGradient,
              lead)!,

          // ── Mid: backgrounds + surfaces ──
          background1:
              Color.lerp(from.background1, target.background1, mid)!,
          background2:
              Color.lerp(from.background2, target.background2, mid)!,
          background3:
              Color.lerp(from.background3, target.background3, mid)!,
          onPrimary: Color.lerp(from.onPrimary, target.onPrimary, mid)!,
          onSecondary:
              Color.lerp(from.onSecondary, target.onSecondary, mid)!,
          surface: Color.lerp(from.surface, target.surface, mid)!,
          onSurface: Color.lerp(from.onSurface, target.onSurface, mid)!,
          surfaceVariant:
              Color.lerp(from.surfaceVariant, target.surfaceVariant, mid)!,
          onSurfaceVariant: Color.lerp(
              from.onSurfaceVariant, target.onSurfaceVariant, mid)!,

          // ── Follow: glass, cards, shimmer, status, misc ──
          glassBackground: Color.lerp(
              from.glassBackground, target.glassBackground, follow)!,
          glassBorder:
              Color.lerp(from.glassBorder, target.glassBorder, follow)!,
          glassHighlight: Color.lerp(
              from.glassHighlight, target.glassHighlight, follow)!,
          cardBackground: Color.lerp(
              from.cardBackground, target.cardBackground, follow)!,
          cardBorder:
              Color.lerp(from.cardBorder, target.cardBorder, follow)!,
          shimmerBase:
              Color.lerp(from.shimmerBase, target.shimmerBase, follow)!,
          shimmerHighlight: Color.lerp(
              from.shimmerHighlight, target.shimmerHighlight, follow)!,
          divider: Color.lerp(from.divider, target.divider, follow)!,
          disabled: Color.lerp(from.disabled, target.disabled, follow)!,
          statusSuccess: Color.lerp(
              from.statusSuccess, target.statusSuccess, follow)!,
          statusError:
              Color.lerp(from.statusError, target.statusError, follow)!,
          statusWarning: Color.lerp(
              from.statusWarning, target.statusWarning, follow)!,
          statusInfo:
              Color.lerp(from.statusInfo, target.statusInfo, follow)!,
          contactExcellent: Color.lerp(
              from.contactExcellent, target.contactExcellent, follow)!,
          contactGood:
              Color.lerp(from.contactGood, target.contactGood, follow)!,
          contactNormal: Color.lerp(
              from.contactNormal, target.contactNormal, follow)!,
          contactNeedsCare: Color.lerp(
              from.contactNeedsCare, target.contactNeedsCare, follow)!,
          contactCritical: Color.lerp(
              from.contactCritical, target.contactCritical, follow)!,
          contactElderly: Color.lerp(
              from.contactElderly, target.contactElderly, follow)!,
          contactDisabled: Color.lerp(
              from.contactDisabled, target.contactDisabled, follow)!,
          moodHappy:
              Color.lerp(from.moodHappy, target.moodHappy, follow)!,
          moodNeutral:
              Color.lerp(from.moodNeutral, target.moodNeutral, follow)!,
          moodSad: Color.lerp(from.moodSad, target.moodSad, follow)!,
          moodExcited:
              Color.lerp(from.moodExcited, target.moodExcited, follow)!,
          moodCalm: Color.lerp(from.moodCalm, target.moodCalm, follow)!,
          moodWorried:
              Color.lerp(from.moodWorried, target.moodWorried, follow)!,
          priorityHigh: Color.lerp(
              from.priorityHigh, target.priorityHigh, follow)!,
          priorityMedium: Color.lerp(
              from.priorityMedium, target.priorityMedium, follow)!,
          priorityLow:
              Color.lerp(from.priorityLow, target.priorityLow, follow)!,
          level1: Color.lerp(from.level1, target.level1, follow)!,
          level2: Color.lerp(from.level2, target.level2, follow)!,
          level3: Color.lerp(from.level3, target.level3, follow)!,
          level4: Color.lerp(from.level4, target.level4, follow)!,
          level5: Color.lerp(from.level5, target.level5, follow)!,
          levelMax: Color.lerp(from.levelMax, target.levelMax, follow)!,
          dialogButtonPrimary: Color.lerp(from.dialogButtonPrimary,
              target.dialogButtonPrimary, follow)!,
          dialogButtonSecondary: Color.lerp(from.dialogButtonSecondary,
              target.dialogButtonSecondary, follow)!,
          dialogButtonDestructive: Color.lerp(
              from.dialogButtonDestructive,
              target.dialogButtonDestructive,
              follow)!,

          // ── Trail: text colors transition last ──
          textPrimary:
              Color.lerp(from.textPrimary, target.textPrimary, trail)!,
          textSecondary: Color.lerp(
              from.textSecondary, target.textSecondary, trail)!,
          textHint: Color.lerp(from.textHint, target.textHint, trail)!,
          textOnGradient: Color.lerp(
              from.textOnGradient, target.textOnGradient, trail)!,
        );

        if (t >= 1.0) {
          timer.cancel();
          _timer = null;
          state = target; // ensure exact final colors
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Provider for current theme colors (animated transitions).
///
/// When the theme changes, colors smoothly interpolate over 400ms instead
/// of snapping. All 122+ consuming files get smooth transitions for free.
final themeColorsProvider =
    StateNotifierProvider<AnimatedThemeColorsNotifier, ThemeColors>((ref) {
  final initial = ref.read(currentDynamicThemeProvider).colors;
  final notifier = AnimatedThemeColorsNotifier(initial);

  ref.listen(currentDynamicThemeProvider, (prev, next) {
    if (prev?.key != next.key) {
      notifier.animateTo(next.colors);
    }
  });

  return notifier;
});

/// Provider for all available themes (dynamic from admin or hardcoded fallbacks)
///
/// This provider returns a list of [DynamicTheme] objects that can be used
/// to display theme options in the UI. It automatically uses admin-configured
/// themes when available, falling back to hardcoded themes otherwise.
final dynamicThemesProvider = Provider<List<DynamicTheme>>((ref) {
  // Watch the current theme key to trigger rebuild when theme changes
  ref.watch(themeKeyProvider);
  return DynamicTheme.getAllThemes();
});

/// Provider for current theme as DynamicTheme
final currentDynamicThemeProvider = Provider<DynamicTheme>((ref) {
  final themeKey = ref.watch(themeKeyProvider);
  return DynamicTheme.findByKey(themeKey) ??
      DynamicTheme.fromAppTheme(AppThemeType.defaultGreen);
});
