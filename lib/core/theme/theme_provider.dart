import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_themes.dart';
import '../services/app_logger_service.dart';

/// Theme provider for managing app theme
class ThemeNotifier extends StateNotifier<AppThemeType> {
  final AppLoggerService _logger = AppLoggerService();

  ThemeNotifier() : super(AppThemeType.defaultGreen) {
    _loadTheme();
  }

  /// Load saved theme from shared preferences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeValue = prefs.getString('app_theme');
      if (themeValue != null) {
        state = AppThemeType.fromString(themeValue);
      }
    } catch (e) {
      // Default theme if loading fails, but log for visibility
      _logger.warning(
        'Failed to load theme from preferences, using default',
        category: LogCategory.service,
        tag: 'ThemeNotifier',
        metadata: {'error': e.toString()},
      );
      state = AppThemeType.defaultGreen;
    }
  }

  /// Change theme and save to preferences
  Future<void> setTheme(AppThemeType theme) async {
    state = theme;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_theme', theme.value);
    } catch (e) {
      // Theme is still changed in memory, but log the persistence failure
      _logger.warning(
        'Failed to persist theme to preferences',
        category: LogCategory.service,
        tag: 'ThemeNotifier',
        metadata: {'theme': theme.value, 'error': e.toString()},
      );
    }
  }
}

/// Provider for theme management
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeType>((ref) {
  return ThemeNotifier();
});

/// Provider for current theme colors
final themeColorsProvider = Provider<ThemeColors>((ref) {
  final themeType = ref.watch(themeProvider);
  return ThemeColors.getTheme(themeType);
});
