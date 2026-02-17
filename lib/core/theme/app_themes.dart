import 'package:flutter/material.dart';

/// App theme options with beautiful Islamic-inspired color schemes
enum AppThemeType {
  defaultGreen('default', 'صِلني', 'Silni Green'),
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

  // Health status gradients
  final LinearGradient healthyGradient;
  final LinearGradient warningGradient;
  final LinearGradient dangerGradient;

  // Semantic colors for consistent theming
  final Color onPrimary;
  final Color onSecondary;
  final Color surface;
  final Color onSurface;
  final Color surfaceVariant;
  final Color onSurfaceVariant;

  // Glass effect colors
  final Color glassBackground;
  final Color glassBorder;
  final Color glassHighlight;

  // Text colors
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color textOnGradient;

  // Loading/shimmer colors
  final Color shimmerBase;
  final Color shimmerHighlight;

  // Card colors
  final Color cardBackground;
  final Color cardBorder;

  // Divider and disabled
  final Color divider;
  final Color disabled;

  // === Semantic Status Colors ===
  final Color statusSuccess;
  final Color statusError;
  final Color statusWarning;
  final Color statusInfo;

  // === Communication Status Colors (contact frequency) ===
  final Color contactExcellent;
  final Color contactGood;
  final Color contactNormal;
  final Color contactNeedsCare;
  final Color contactCritical;
  final Color contactElderly;
  final Color contactDisabled;

  // === Mood Colors (emotional states) ===
  final Color moodHappy;
  final Color moodNeutral;
  final Color moodSad;
  final Color moodExcited;
  final Color moodCalm;
  final Color moodWorried;

  // === Priority Colors ===
  final Color priorityHigh;
  final Color priorityMedium;
  final Color priorityLow;

  // === Level/Gamification Colors ===
  final Color level1;
  final Color level2;
  final Color level3;
  final Color level4;
  final Color level5;
  final Color levelMax;

  // === Gamification Tier Gradients ===
  final LinearGradient tierLegendaryGradient;
  final LinearGradient tierEpicGradient;
  final LinearGradient tierRareGradient;
  final LinearGradient tierStarterGradient;

  // === Dialog Button Colors ===
  final Color dialogButtonPrimary;
  final Color dialogButtonSecondary;
  final Color dialogButtonDestructive;

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
    required this.healthyGradient,
    required this.warningGradient,
    required this.dangerGradient,
    required this.onPrimary,
    required this.onSecondary,
    required this.surface,
    required this.onSurface,
    required this.surfaceVariant,
    required this.onSurfaceVariant,
    required this.glassBackground,
    required this.glassBorder,
    required this.glassHighlight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.textOnGradient,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.cardBackground,
    required this.cardBorder,
    required this.divider,
    required this.disabled,
    // Semantic status
    required this.statusSuccess,
    required this.statusError,
    required this.statusWarning,
    required this.statusInfo,
    // Communication status
    required this.contactExcellent,
    required this.contactGood,
    required this.contactNormal,
    required this.contactNeedsCare,
    required this.contactCritical,
    required this.contactElderly,
    required this.contactDisabled,
    // Mood
    required this.moodHappy,
    required this.moodNeutral,
    required this.moodSad,
    required this.moodExcited,
    required this.moodCalm,
    required this.moodWorried,
    // Priority
    required this.priorityHigh,
    required this.priorityMedium,
    required this.priorityLow,
    // Level
    required this.level1,
    required this.level2,
    required this.level3,
    required this.level4,
    required this.level5,
    required this.levelMax,
    // Tier gradients
    required this.tierLegendaryGradient,
    required this.tierEpicGradient,
    required this.tierRareGradient,
    required this.tierStarterGradient,
    // Dialog button colors
    this.dialogButtonPrimary = const Color(0xFFFFFFFF),
    this.dialogButtonSecondary = const Color(0xB3FFFFFF),
    this.dialogButtonDestructive = const Color(0xFFE53935),
  });

  /// Linearly interpolate between two [ThemeColors] at position [t].
  ///
  /// Used by [AnimatedThemeColorsNotifier] to smoothly transition every
  /// color in the app when the user switches themes.
  static ThemeColors lerp(ThemeColors a, ThemeColors b, double t) {
    return ThemeColors(
      // Primary
      primary: Color.lerp(a.primary, b.primary, t)!,
      primaryLight: Color.lerp(a.primaryLight, b.primaryLight, t)!,
      primaryDark: Color.lerp(a.primaryDark, b.primaryDark, t)!,
      secondary: Color.lerp(a.secondary, b.secondary, t)!,
      accent: Color.lerp(a.accent, b.accent, t)!,
      // Backgrounds
      background1: Color.lerp(a.background1, b.background1, t)!,
      background2: Color.lerp(a.background2, b.background2, t)!,
      background3: Color.lerp(a.background3, b.background3, t)!,
      // Gradients
      primaryGradient:
          LinearGradient.lerp(a.primaryGradient, b.primaryGradient, t)!,
      backgroundGradient:
          LinearGradient.lerp(a.backgroundGradient, b.backgroundGradient, t)!,
      goldenGradient:
          LinearGradient.lerp(a.goldenGradient, b.goldenGradient, t)!,
      streakFire: LinearGradient.lerp(a.streakFire, b.streakFire, t)!,
      healthyGradient:
          LinearGradient.lerp(a.healthyGradient, b.healthyGradient, t)!,
      warningGradient:
          LinearGradient.lerp(a.warningGradient, b.warningGradient, t)!,
      dangerGradient:
          LinearGradient.lerp(a.dangerGradient, b.dangerGradient, t)!,
      // Semantic
      onPrimary: Color.lerp(a.onPrimary, b.onPrimary, t)!,
      onSecondary: Color.lerp(a.onSecondary, b.onSecondary, t)!,
      surface: Color.lerp(a.surface, b.surface, t)!,
      onSurface: Color.lerp(a.onSurface, b.onSurface, t)!,
      surfaceVariant: Color.lerp(a.surfaceVariant, b.surfaceVariant, t)!,
      onSurfaceVariant:
          Color.lerp(a.onSurfaceVariant, b.onSurfaceVariant, t)!,
      // Glass
      glassBackground: Color.lerp(a.glassBackground, b.glassBackground, t)!,
      glassBorder: Color.lerp(a.glassBorder, b.glassBorder, t)!,
      glassHighlight: Color.lerp(a.glassHighlight, b.glassHighlight, t)!,
      // Text
      textPrimary: Color.lerp(a.textPrimary, b.textPrimary, t)!,
      textSecondary: Color.lerp(a.textSecondary, b.textSecondary, t)!,
      textHint: Color.lerp(a.textHint, b.textHint, t)!,
      textOnGradient: Color.lerp(a.textOnGradient, b.textOnGradient, t)!,
      // Shimmer
      shimmerBase: Color.lerp(a.shimmerBase, b.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(a.shimmerHighlight, b.shimmerHighlight, t)!,
      // Card
      cardBackground: Color.lerp(a.cardBackground, b.cardBackground, t)!,
      cardBorder: Color.lerp(a.cardBorder, b.cardBorder, t)!,
      // Divider/disabled
      divider: Color.lerp(a.divider, b.divider, t)!,
      disabled: Color.lerp(a.disabled, b.disabled, t)!,
      // Status
      statusSuccess: Color.lerp(a.statusSuccess, b.statusSuccess, t)!,
      statusError: Color.lerp(a.statusError, b.statusError, t)!,
      statusWarning: Color.lerp(a.statusWarning, b.statusWarning, t)!,
      statusInfo: Color.lerp(a.statusInfo, b.statusInfo, t)!,
      // Contact frequency
      contactExcellent: Color.lerp(a.contactExcellent, b.contactExcellent, t)!,
      contactGood: Color.lerp(a.contactGood, b.contactGood, t)!,
      contactNormal: Color.lerp(a.contactNormal, b.contactNormal, t)!,
      contactNeedsCare:
          Color.lerp(a.contactNeedsCare, b.contactNeedsCare, t)!,
      contactCritical: Color.lerp(a.contactCritical, b.contactCritical, t)!,
      contactElderly: Color.lerp(a.contactElderly, b.contactElderly, t)!,
      contactDisabled: Color.lerp(a.contactDisabled, b.contactDisabled, t)!,
      // Mood
      moodHappy: Color.lerp(a.moodHappy, b.moodHappy, t)!,
      moodNeutral: Color.lerp(a.moodNeutral, b.moodNeutral, t)!,
      moodSad: Color.lerp(a.moodSad, b.moodSad, t)!,
      moodExcited: Color.lerp(a.moodExcited, b.moodExcited, t)!,
      moodCalm: Color.lerp(a.moodCalm, b.moodCalm, t)!,
      moodWorried: Color.lerp(a.moodWorried, b.moodWorried, t)!,
      // Priority
      priorityHigh: Color.lerp(a.priorityHigh, b.priorityHigh, t)!,
      priorityMedium: Color.lerp(a.priorityMedium, b.priorityMedium, t)!,
      priorityLow: Color.lerp(a.priorityLow, b.priorityLow, t)!,
      // Level
      level1: Color.lerp(a.level1, b.level1, t)!,
      level2: Color.lerp(a.level2, b.level2, t)!,
      level3: Color.lerp(a.level3, b.level3, t)!,
      level4: Color.lerp(a.level4, b.level4, t)!,
      level5: Color.lerp(a.level5, b.level5, t)!,
      levelMax: Color.lerp(a.levelMax, b.levelMax, t)!,
      // Tier gradients
      tierLegendaryGradient: LinearGradient.lerp(
          a.tierLegendaryGradient, b.tierLegendaryGradient, t)!,
      tierEpicGradient:
          LinearGradient.lerp(a.tierEpicGradient, b.tierEpicGradient, t)!,
      tierRareGradient:
          LinearGradient.lerp(a.tierRareGradient, b.tierRareGradient, t)!,
      tierStarterGradient: LinearGradient.lerp(
          a.tierStarterGradient, b.tierStarterGradient, t)!,
      // Dialog buttons
      dialogButtonPrimary:
          Color.lerp(a.dialogButtonPrimary, b.dialogButtonPrimary, t)!,
      dialogButtonSecondary:
          Color.lerp(a.dialogButtonSecondary, b.dialogButtonSecondary, t)!,
      dialogButtonDestructive:
          Color.lerp(a.dialogButtonDestructive, b.dialogButtonDestructive, t)!,
    );
  }

  /// Silni Green Theme (Default)
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
    healthyGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF43A047), Color(0xFF66BB6A), Color(0xFF81C784)],
    ),
    warningGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFA000), Color(0xFFFFB300), Color(0xFFFFCA28)],
    ),
    dangerGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE53935), Color(0xFFEF5350), Color(0xFFE57373)],
    ),
    // Semantic colors
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFF1B5E20),
    surface: Color(0xFF1B5E20),
    onSurface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFF2E7D32),
    onSurfaceVariant: Color(0xFFE8F5E9),
    // Glass effect colors
    glassBackground: Color(0x26FFFFFF),
    glassBorder: Color(0x33FFFFFF),
    glassHighlight: Color(0x4DFFFFFF),
    // Text colors
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xB3FFFFFF),
    textHint: Color(0x80FFFFFF),
    textOnGradient: Color(0xFFFFFFFF),
    // Loading/shimmer colors
    shimmerBase: Color(0xFF2E7D32),
    shimmerHighlight: Color(0xFF81C784),
    // Card colors
    cardBackground: Color(0x26FFFFFF),
    cardBorder: Color(0x33FFFFFF),
    // Divider and disabled
    divider: Color(0x33FFFFFF),
    disabled: Color(0x80FFFFFF),
    // Semantic status
    statusSuccess: Color(0xFF4CAF50),
    statusError: Color(0xFFE53935),
    statusWarning: Color(0xFFFFA726),
    statusInfo: Color(0xFF29B6F6),
    // Communication status (contact frequency)
    contactExcellent: Color(0xFF4CAF50),
    contactGood: Color(0xFF8BC34A),
    contactNormal: Color(0xFF2196F3),
    contactNeedsCare: Color(0xFFFF9800),
    contactCritical: Color(0xFFF44336),
    contactElderly: Color(0xFF9C27B0),
    contactDisabled: Color(0xFF607D8B),
    // Mood colors
    moodHappy: Color(0xFFFFEB3B),
    moodNeutral: Color(0xFF9E9E9E),
    moodSad: Color(0xFF5C6BC0),
    moodExcited: Color(0xFFFF5722),
    moodCalm: Color(0xFF26C6DA),
    moodWorried: Color(0xFFFFA726),
    // Priority
    priorityHigh: Color(0xFFE53935),
    priorityMedium: Color(0xFFFFA726),
    priorityLow: Color(0xFF66BB6A),
    // Level colors
    level1: Color(0xFF81C784),
    level2: Color(0xFF4CAF50),
    level3: Color(0xFF388E3C),
    level4: Color(0xFF2E7D32),
    level5: Color(0xFF1B5E20),
    levelMax: Color(0xFFFFD700),
    // Tier gradients
    tierLegendaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFD700), Color(0xFFFFA000), Color(0xFFFF6F00)],
    ),
    tierEpicGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2), Color(0xFFE91E63)],
    ),
    tierRareGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2196F3), Color(0xFF1976D2), Color(0xFF00BCD4)],
    ),
    tierStarterGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF81C784), Color(0xFF4CAF50), Color(0xFF388E3C)],
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
    healthyGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF43A047), Color(0xFF66BB6A), Color(0xFF81C784)],
    ),
    warningGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFA000), Color(0xFFFFB300), Color(0xFFFFCA28)],
    ),
    dangerGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE53935), Color(0xFFEF5350), Color(0xFFE57373)],
    ),
    // Semantic colors
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFF4A148C),
    surface: Color(0xFF4A148C),
    onSurface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFF6A1B9A),
    onSurfaceVariant: Color(0xFFF3E5F5),
    // Glass effect colors
    glassBackground: Color(0x26FFFFFF),
    glassBorder: Color(0x33FFFFFF),
    glassHighlight: Color(0x4DFFFFFF),
    // Text colors
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xB3FFFFFF),
    textHint: Color(0x80FFFFFF),
    textOnGradient: Color(0xFFFFFFFF),
    // Loading/shimmer colors
    shimmerBase: Color(0xFF7B1FA2),
    shimmerHighlight: Color(0xFFBA68C8),
    // Card colors
    cardBackground: Color(0x26FFFFFF),
    cardBorder: Color(0x33FFFFFF),
    // Divider and disabled
    divider: Color(0x33FFFFFF),
    disabled: Color(0x80FFFFFF),
    // Semantic status
    statusSuccess: Color(0xFF4CAF50),
    statusError: Color(0xFFE53935),
    statusWarning: Color(0xFFFFA726),
    statusInfo: Color(0xFF29B6F6),
    // Communication status (contact frequency) - purple tinted
    contactExcellent: Color(0xFFBA68C8),
    contactGood: Color(0xFFCE93D8),
    contactNormal: Color(0xFF7E57C2),
    contactNeedsCare: Color(0xFFFF9800),
    contactCritical: Color(0xFFF44336),
    contactElderly: Color(0xFF9C27B0),
    contactDisabled: Color(0xFF607D8B),
    // Mood colors
    moodHappy: Color(0xFFFFEB3B),
    moodNeutral: Color(0xFF9E9E9E),
    moodSad: Color(0xFF5C6BC0),
    moodExcited: Color(0xFFFF5722),
    moodCalm: Color(0xFF26C6DA),
    moodWorried: Color(0xFFFFA726),
    // Priority
    priorityHigh: Color(0xFFE53935),
    priorityMedium: Color(0xFFFFA726),
    priorityLow: Color(0xFF66BB6A),
    // Level colors - purple shades
    level1: Color(0xFFCE93D8),
    level2: Color(0xFFBA68C8),
    level3: Color(0xFF9C27B0),
    level4: Color(0xFF7B1FA2),
    level5: Color(0xFF4A148C),
    levelMax: Color(0xFFFFD700),
    // Tier gradients
    tierLegendaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFD700), Color(0xFFFFA000), Color(0xFFFF6F00)],
    ),
    tierEpicGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE040FB), Color(0xFF9C27B0), Color(0xFFE91E63)],
    ),
    tierRareGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF7E57C2), Color(0xFF5C6BC0), Color(0xFF9575CD)],
    ),
    tierStarterGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFCE93D8), Color(0xFFBA68C8), Color(0xFF9C27B0)],
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
    healthyGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF43A047), Color(0xFF66BB6A), Color(0xFF81C784)],
    ),
    warningGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFA000), Color(0xFFFFB300), Color(0xFFFFCA28)],
    ),
    dangerGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE53935), Color(0xFFEF5350), Color(0xFFE57373)],
    ),
    // Semantic colors
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFF0D47A1),
    surface: Color(0xFF0D47A1),
    onSurface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFF1565C0),
    onSurfaceVariant: Color(0xFFE3F2FD),
    // Glass effect colors
    glassBackground: Color(0x26FFFFFF),
    glassBorder: Color(0x33FFFFFF),
    glassHighlight: Color(0x4DFFFFFF),
    // Text colors
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xB3FFFFFF),
    textHint: Color(0x80FFFFFF),
    textOnGradient: Color(0xFFFFFFFF),
    // Loading/shimmer colors
    shimmerBase: Color(0xFF1565C0),
    shimmerHighlight: Color(0xFF42A5F5),
    // Card colors
    cardBackground: Color(0x26FFFFFF),
    cardBorder: Color(0x33FFFFFF),
    // Divider and disabled
    divider: Color(0x33FFFFFF),
    disabled: Color(0x80FFFFFF),
    // Semantic status
    statusSuccess: Color(0xFF4CAF50),
    statusError: Color(0xFFE53935),
    statusWarning: Color(0xFFFFA726),
    statusInfo: Color(0xFF29B6F6),
    // Communication status (contact frequency) - blue tinted
    contactExcellent: Color(0xFF42A5F5),
    contactGood: Color(0xFF64B5F6),
    contactNormal: Color(0xFF1976D2),
    contactNeedsCare: Color(0xFFFF9800),
    contactCritical: Color(0xFFF44336),
    contactElderly: Color(0xFF9C27B0),
    contactDisabled: Color(0xFF607D8B),
    // Mood colors
    moodHappy: Color(0xFFFFEB3B),
    moodNeutral: Color(0xFF9E9E9E),
    moodSad: Color(0xFF5C6BC0),
    moodExcited: Color(0xFFFF5722),
    moodCalm: Color(0xFF26C6DA),
    moodWorried: Color(0xFFFFA726),
    // Priority
    priorityHigh: Color(0xFFE53935),
    priorityMedium: Color(0xFFFFA726),
    priorityLow: Color(0xFF66BB6A),
    // Level colors - blue shades
    level1: Color(0xFF90CAF9),
    level2: Color(0xFF64B5F6),
    level3: Color(0xFF42A5F5),
    level4: Color(0xFF1976D2),
    level5: Color(0xFF0D47A1),
    levelMax: Color(0xFFFFD700),
    // Tier gradients
    tierLegendaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFD700), Color(0xFFFFA000), Color(0xFFFF6F00)],
    ),
    tierEpicGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2), Color(0xFFE91E63)],
    ),
    tierRareGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF00B0FF), Color(0xFF1976D2), Color(0xFF00BCD4)],
    ),
    tierStarterGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF90CAF9), Color(0xFF64B5F6), Color(0xFF42A5F5)],
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
    healthyGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF43A047), Color(0xFF66BB6A), Color(0xFF81C784)],
    ),
    warningGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFA000), Color(0xFFFFB300), Color(0xFFFFCA28)],
    ),
    dangerGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE53935), Color(0xFFEF5350), Color(0xFFE57373)],
    ),
    // Semantic colors
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFFBF360C),
    surface: Color(0xFFBF360C),
    onSurface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFD84315),
    onSurfaceVariant: Color(0xFFFBE9E7),
    // Glass effect colors
    glassBackground: Color(0x26FFFFFF),
    glassBorder: Color(0x33FFFFFF),
    glassHighlight: Color(0x4DFFFFFF),
    // Text colors
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xB3FFFFFF),
    textHint: Color(0x80FFFFFF),
    textOnGradient: Color(0xFFFFFFFF),
    // Loading/shimmer colors
    shimmerBase: Color(0xFFE65100),
    shimmerHighlight: Color(0xFFFF9800),
    // Card colors
    cardBackground: Color(0x26FFFFFF),
    cardBorder: Color(0x33FFFFFF),
    // Divider and disabled
    divider: Color(0x33FFFFFF),
    disabled: Color(0x80FFFFFF),
    // Semantic status
    statusSuccess: Color(0xFF4CAF50),
    statusError: Color(0xFFE53935),
    statusWarning: Color(0xFFFFA726),
    statusInfo: Color(0xFF29B6F6),
    // Communication status (contact frequency) - orange tinted
    contactExcellent: Color(0xFFFF9800),
    contactGood: Color(0xFFFFB74D),
    contactNormal: Color(0xFFFF6F00),
    contactNeedsCare: Color(0xFFFFCA28),
    contactCritical: Color(0xFFF44336),
    contactElderly: Color(0xFF9C27B0),
    contactDisabled: Color(0xFF607D8B),
    // Mood colors
    moodHappy: Color(0xFFFFEB3B),
    moodNeutral: Color(0xFF9E9E9E),
    moodSad: Color(0xFF5C6BC0),
    moodExcited: Color(0xFFFF5722),
    moodCalm: Color(0xFF26C6DA),
    moodWorried: Color(0xFFFFA726),
    // Priority
    priorityHigh: Color(0xFFE53935),
    priorityMedium: Color(0xFFFFA726),
    priorityLow: Color(0xFF66BB6A),
    // Level colors - orange shades
    level1: Color(0xFFFFCC80),
    level2: Color(0xFFFFB74D),
    level3: Color(0xFFFF9800),
    level4: Color(0xFFE65100),
    level5: Color(0xFFBF360C),
    levelMax: Color(0xFFFFD700),
    // Tier gradients
    tierLegendaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFD700), Color(0xFFFFA000), Color(0xFFFF6F00)],
    ),
    tierEpicGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2), Color(0xFFE91E63)],
    ),
    tierRareGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2196F3), Color(0xFF1976D2), Color(0xFF00BCD4)],
    ),
    tierStarterGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFCC80), Color(0xFFFFB74D), Color(0xFFFF9800)],
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
    healthyGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF43A047), Color(0xFF66BB6A), Color(0xFF81C784)],
    ),
    warningGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFA000), Color(0xFFFFB300), Color(0xFFFFCA28)],
    ),
    dangerGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE53935), Color(0xFFEF5350), Color(0xFFE57373)],
    ),
    // Semantic colors
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFF880E4F),
    surface: Color(0xFF880E4F),
    onSurface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFAD1457),
    onSurfaceVariant: Color(0xFFFCE4EC),
    // Glass effect colors
    glassBackground: Color(0x26FFFFFF),
    glassBorder: Color(0x33FFFFFF),
    glassHighlight: Color(0x4DFFFFFF),
    // Text colors
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xB3FFFFFF),
    textHint: Color(0x80FFFFFF),
    textOnGradient: Color(0xFFFFFFFF),
    // Loading/shimmer colors
    shimmerBase: Color(0xFFC2185B),
    shimmerHighlight: Color(0xFFF06292),
    // Card colors
    cardBackground: Color(0x26FFFFFF),
    cardBorder: Color(0x33FFFFFF),
    // Divider and disabled
    divider: Color(0x33FFFFFF),
    disabled: Color(0x80FFFFFF),
    // Semantic status
    statusSuccess: Color(0xFF4CAF50),
    statusError: Color(0xFFE53935),
    statusWarning: Color(0xFFFFA726),
    statusInfo: Color(0xFF29B6F6),
    // Communication status (contact frequency) - pink tinted
    contactExcellent: Color(0xFFF06292),
    contactGood: Color(0xFFF48FB1),
    contactNormal: Color(0xFFE91E63),
    contactNeedsCare: Color(0xFFFF9800),
    contactCritical: Color(0xFFF44336),
    contactElderly: Color(0xFF9C27B0),
    contactDisabled: Color(0xFF607D8B),
    // Mood colors
    moodHappy: Color(0xFFFFEB3B),
    moodNeutral: Color(0xFF9E9E9E),
    moodSad: Color(0xFF5C6BC0),
    moodExcited: Color(0xFFFF5722),
    moodCalm: Color(0xFF26C6DA),
    moodWorried: Color(0xFFFFA726),
    // Priority
    priorityHigh: Color(0xFFE53935),
    priorityMedium: Color(0xFFFFA726),
    priorityLow: Color(0xFF66BB6A),
    // Level colors - pink shades
    level1: Color(0xFFF8BBD9),
    level2: Color(0xFFF48FB1),
    level3: Color(0xFFF06292),
    level4: Color(0xFFC2185B),
    level5: Color(0xFF880E4F),
    levelMax: Color(0xFFFFD700),
    // Tier gradients
    tierLegendaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFD700), Color(0xFFFFA000), Color(0xFFFF6F00)],
    ),
    tierEpicGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF4081), Color(0xFFE91E63), Color(0xFFC2185B)],
    ),
    tierRareGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2196F3), Color(0xFF1976D2), Color(0xFF00BCD4)],
    ),
    tierStarterGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF8BBD9), Color(0xFFF48FB1), Color(0xFFF06292)],
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
    healthyGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF43A047), Color(0xFF66BB6A), Color(0xFF81C784)],
    ),
    warningGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFA000), Color(0xFFFFB300), Color(0xFFFFCA28)],
    ),
    dangerGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE53935), Color(0xFFEF5350), Color(0xFFE57373)],
    ),
    // Semantic colors
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFF0A0E27),
    surface: Color(0xFF0A0E27),
    onSurface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFF1A237E),
    onSurfaceVariant: Color(0xFFE8EAF6),
    // Glass effect colors
    glassBackground: Color(0x26FFFFFF),
    glassBorder: Color(0x33FFFFFF),
    glassHighlight: Color(0x4DFFFFFF),
    // Text colors
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xB3FFFFFF),
    textHint: Color(0x80FFFFFF),
    textOnGradient: Color(0xFFFFFFFF),
    // Loading/shimmer colors
    shimmerBase: Color(0xFF1A237E),
    shimmerHighlight: Color(0xFF3949AB),
    // Card colors
    cardBackground: Color(0x26FFFFFF),
    cardBorder: Color(0x33FFFFFF),
    // Divider and disabled
    divider: Color(0x33FFFFFF),
    disabled: Color(0x80FFFFFF),
    // Semantic status
    statusSuccess: Color(0xFF4CAF50),
    statusError: Color(0xFFE53935),
    statusWarning: Color(0xFFFFA726),
    statusInfo: Color(0xFF29B6F6),
    // Communication status (contact frequency) - indigo tinted
    contactExcellent: Color(0xFF536DFE),
    contactGood: Color(0xFF7C4DFF),
    contactNormal: Color(0xFF3949AB),
    contactNeedsCare: Color(0xFFFF9800),
    contactCritical: Color(0xFFF44336),
    contactElderly: Color(0xFF9C27B0),
    contactDisabled: Color(0xFF607D8B),
    // Mood colors
    moodHappy: Color(0xFFFFEB3B),
    moodNeutral: Color(0xFF9E9E9E),
    moodSad: Color(0xFF5C6BC0),
    moodExcited: Color(0xFFFF5722),
    moodCalm: Color(0xFF26C6DA),
    moodWorried: Color(0xFFFFA726),
    // Priority
    priorityHigh: Color(0xFFE53935),
    priorityMedium: Color(0xFFFFA726),
    priorityLow: Color(0xFF66BB6A),
    // Level colors - indigo shades
    level1: Color(0xFFC5CAE9),
    level2: Color(0xFF9FA8DA),
    level3: Color(0xFF7986CB),
    level4: Color(0xFF3949AB),
    level5: Color(0xFF1A237E),
    levelMax: Color(0xFFFFD700),
    // Tier gradients
    tierLegendaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFD700), Color(0xFFFFA000), Color(0xFFFF6F00)],
    ),
    tierEpicGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF7C4DFF), Color(0xFF536DFE), Color(0xFFB388FF)],
    ),
    tierRareGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF5C6BC0), Color(0xFF3949AB), Color(0xFF7986CB)],
    ),
    tierStarterGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFC5CAE9), Color(0xFF9FA8DA), Color(0xFF7986CB)],
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
