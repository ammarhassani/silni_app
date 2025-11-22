import 'package:flutter/material.dart';

/// App theme options with beautiful Islamic-inspired color schemes
enum AppThemeType {
  defaultGreen('default', 'الأخضر الإسلامي', 'Default Islamic Green'),
  lavenderPurple('lavender', 'خزامى', 'Lavender Purple'),
  royalBlue('royal', 'الأزرق الملكي', 'Royal Blue'),
  sunsetOrange('sunset', 'غروب الشمس', 'Sunset Orange'),
  roseGold('rose', 'ذهبي وردي', 'Rose Gold'),
  midnightDark('midnight', 'ليل', 'Midnight Dark');

  final String value;
  final String arabicName;
  final String englishName;

  const AppThemeType(this.value, this.arabicName, this.englishName);

  static AppThemeType fromString(String value) {
    return AppThemeType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AppThemeType.defaultGreen,
    );
  }
}

/// Theme colors for each theme type
class ThemeColors {
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color secondary;
  final Color accent;
  final Color background1;
  final Color background2;
  final Color background3;
  final LinearGradient primaryGradient;
  final LinearGradient backgroundGradient;
  final LinearGradient goldenGradient;
  final LinearGradient streakFire;

  const ThemeColors({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.secondary,
    required this.accent,
    required this.background1,
    required this.background2,
    required this.background3,
    required this.primaryGradient,
    required this.backgroundGradient,
    required this.goldenGradient,
    required this.streakFire,
  });

  /// Default Islamic Green Theme
  static const defaultGreen = ThemeColors(
    primary: Color(0xFF2E7D32),
    primaryLight: Color(0xFF60AD5E),
    primaryDark: Color(0xFF005005),
    secondary: Color(0xFFFFD700),
    accent: Color(0xFFFF6F00),
    background1: Color(0xFF1B5E20),
    background2: Color(0xFF2E7D32),
    background3: Color(0xFF388E3C),
    primaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2E7D32), Color(0xFF60AD5E), Color(0xFF81C784)],
    ),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
    ),
    goldenGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFD700), Color(0xFFFFA000), Color(0xFFFF6F00)],
    ),
    streakFire: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF6F00), Color(0xFFFF8F00), Color(0xFFFFA726)],
    ),
  );

  /// Lavender Purple Theme (خزامى)
  static const lavenderPurple = ThemeColors(
    primary: Color(0xFF7B1FA2),
    primaryLight: Color(0xFFBA68C8),
    primaryDark: Color(0xFF4A0072),
    secondary: Color(0xFFFFD700),
    accent: Color(0xFFE040FB),
    background1: Color(0xFF4A148C),
    background2: Color(0xFF6A1B9A),
    background3: Color(0xFF7B1FA2),
    primaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0), Color(0xFFBA68C8)],
    ),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF4A148C), Color(0xFF6A1B9A), Color(0xFF7B1FA2)],
    ),
    goldenGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFD700), Color(0xFFFFA000), Color(0xFFFF6F00)],
    ),
    streakFire: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE040FB), Color(0xFFCE93D8), Color(0xFFBA68C8)],
    ),
  );

  /// Royal Blue Theme
  static const royalBlue = ThemeColors(
    primary: Color(0xFF1565C0),
    primaryLight: Color(0xFF5E92F3),
    primaryDark: Color(0xFF003C8F),
    secondary: Color(0xFFFFD700),
    accent: Color(0xFF00B0FF),
    background1: Color(0xFF0D47A1),
    background2: Color(0xFF1565C0),
    background3: Color(0xFF1976D2),
    primaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1565C0), Color(0xFF1976D2), Color(0xFF42A5F5)],
    ),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1976D2)],
    ),
    goldenGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFD700), Color(0xFFFFA000), Color(0xFFFF6F00)],
    ),
    streakFire: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF00B0FF), Color(0xFF40C4FF), Color(0xFF80D8FF)],
    ),
  );

  /// Sunset Orange Theme
  static const sunsetOrange = ThemeColors(
    primary: Color(0xFFE65100),
    primaryLight: Color(0xFFFF8A50),
    primaryDark: Color(0xFFAC1900),
    secondary: Color(0xFFFFD700),
    accent: Color(0xFFFF6F00),
    background1: Color(0xFFBF360C),
    background2: Color(0xFFD84315),
    background3: Color(0xFFE64A19),
    primaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE65100), Color(0xFFFF6F00), Color(0xFFFF9800)],
    ),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFBF360C), Color(0xFFD84315), Color(0xFFE64A19)],
    ),
    goldenGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFD700), Color(0xFFFFA000), Color(0xFFFF6F00)],
    ),
    streakFire: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF6F00), Color(0xFFFF8F00), Color(0xFFFFA726)],
    ),
  );

  /// Rose Gold Theme
  static const roseGold = ThemeColors(
    primary: Color(0xFFC2185B),
    primaryLight: Color(0xFFF06292),
    primaryDark: Color(0xFF880E4F),
    secondary: Color(0xFFFFD700),
    accent: Color(0xFFFF4081),
    background1: Color(0xFF880E4F),
    background2: Color(0xFFAD1457),
    background3: Color(0xFFC2185B),
    primaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFC2185B), Color(0xFFE91E63), Color(0xFFF06292)],
    ),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF880E4F), Color(0xFFAD1457), Color(0xFFC2185B)],
    ),
    goldenGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFD700), Color(0xFFFFA000), Color(0xFFFF6F00)],
    ),
    streakFire: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF4081), Color(0xFFFF80AB), Color(0xFFF48FB1)],
    ),
  );

  /// Midnight Dark Theme
  static const midnightDark = ThemeColors(
    primary: Color(0xFF1A237E),
    primaryLight: Color(0xFF534BAE),
    primaryDark: Color(0xFF000051),
    secondary: Color(0xFFFFD700),
    accent: Color(0xFF536DFE),
    background1: Color(0xFF0A0E27),
    background2: Color(0xFF1A237E),
    background3: Color(0xFF283593),
    primaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
    ),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0A0E27), Color(0xFF1A237E), Color(0xFF283593)],
    ),
    goldenGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFD700), Color(0xFFFFA000), Color(0xFFFF6F00)],
    ),
    streakFire: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF536DFE), Color(0xFF7C4DFF), Color(0xFFB388FF)],
    ),
  );

  /// Get theme colors by type
  static ThemeColors getTheme(AppThemeType type) {
    switch (type) {
      case AppThemeType.defaultGreen:
        return defaultGreen;
      case AppThemeType.lavenderPurple:
        return lavenderPurple;
      case AppThemeType.royalBlue:
        return royalBlue;
      case AppThemeType.sunsetOrange:
        return sunsetOrange;
      case AppThemeType.roseGold:
        return roseGold;
      case AppThemeType.midnightDark:
        return midnightDark;
    }
  }
}
