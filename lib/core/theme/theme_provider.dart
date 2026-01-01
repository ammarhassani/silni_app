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

/// Provider for current theme colors (uses admin themes when available)
final themeColorsProvider = Provider<ThemeColors>((ref) {
  final currentDynamic = ref.watch(currentDynamicThemeProvider);
  return currentDynamic.colors;
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
