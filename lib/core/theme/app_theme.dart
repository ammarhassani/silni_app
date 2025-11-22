import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../constants/app_spacing.dart';

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.islamicGreenPrimary,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),

    // Color scheme
    colorScheme: const ColorScheme.light(
      primary: AppColors.islamicGreenPrimary,
      onPrimary: Colors.white,
      secondary: AppColors.premiumGold,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.cardLight,
      onSurface: AppColors.textPrimary,
    ),

    // App Bar Theme
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textPrimary,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: AppTypography.headlineSmall,
    ),

    // Card Theme
    cardTheme: CardTheme(
      elevation: AppSpacing.elevationMd,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      color: AppColors.cardLight,
      shadowColor: AppColors.shadowLight,
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: AppSpacing.elevationMd,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
        textStyle: AppTypography.buttonLarge,
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        textStyle: AppTypography.buttonMedium,
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        borderSide: const BorderSide(
          color: AppColors.islamicGreenPrimary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 2,
        ),
      ),
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.textHint,
      ),
      labelStyle: AppTypography.bodyMedium,
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      elevation: AppSpacing.elevationLg,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.islamicGreenPrimary,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: AppTypography.labelSmall,
      unselectedLabelStyle: AppTypography.labelSmall,
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: AppSpacing.elevationMd,
      backgroundColor: AppColors.islamicGreenPrimary,
      foregroundColor: Colors.white,
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      thickness: AppSpacing.dividerThickness,
      color: Color(0xFFE0E0E0),
      space: AppSpacing.md,
    ),

    // Icon Theme
    iconTheme: const IconThemeData(
      color: AppColors.textPrimary,
      size: AppSpacing.iconMd,
    ),

    // Text Theme
    textTheme: TextTheme(
      displayLarge: AppTypography.displayLarge,
      displayMedium: AppTypography.displayMedium,
      displaySmall: AppTypography.displaySmall,
      headlineLarge: AppTypography.headlineLarge,
      headlineMedium: AppTypography.headlineMedium,
      headlineSmall: AppTypography.headlineSmall,
      titleLarge: AppTypography.titleLarge,
      titleMedium: AppTypography.titleMedium,
      titleSmall: AppTypography.titleSmall,
      bodyLarge: AppTypography.bodyLarge,
      bodyMedium: AppTypography.bodyMedium,
      bodySmall: AppTypography.bodySmall,
      labelLarge: AppTypography.labelLarge,
      labelMedium: AppTypography.labelMedium,
      labelSmall: AppTypography.labelSmall,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.islamicGreenPrimary,
    scaffoldBackgroundColor: const Color(0xFF121212),

    // Color scheme
    colorScheme: const ColorScheme.dark(
      primary: AppColors.islamicGreenLight,
      onPrimary: Colors.black,
      secondary: AppColors.premiumGold,
      onSecondary: Colors.black,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.cardDark,
      onSurface: AppColors.textWhite,
    ),

    // App Bar Theme
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textWhite,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: AppTypography.headlineSmall.copyWith(
        color: AppColors.textWhite,
      ),
    ),

    // Card Theme
    cardTheme: CardTheme(
      elevation: AppSpacing.elevationMd,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      color: AppColors.cardDark,
      shadowColor: AppColors.shadowDark,
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: AppSpacing.elevationMd,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
        textStyle: AppTypography.buttonLarge,
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        borderSide: const BorderSide(
          color: AppColors.islamicGreenLight,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 2,
        ),
      ),
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.textSecondary,
      ),
      labelStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.textWhite,
      ),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      elevation: AppSpacing.elevationLg,
      backgroundColor: AppColors.cardDark,
      selectedItemColor: AppColors.islamicGreenLight,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: AppTypography.labelSmall,
      unselectedLabelStyle: AppTypography.labelSmall,
    ),

    // Icon Theme
    iconTheme: const IconThemeData(
      color: AppColors.textWhite,
      size: AppSpacing.iconMd,
    ),

    // Text Theme
    textTheme: TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.textWhite),
      displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.textWhite),
      displaySmall: AppTypography.displaySmall.copyWith(color: AppColors.textWhite),
      headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.textWhite),
      headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.textWhite),
      headlineSmall: AppTypography.headlineSmall.copyWith(color: AppColors.textWhite),
      titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.textWhite),
      titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.textWhite),
      titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.textWhite),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.textWhite),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite),
      bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.textWhite),
      labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.textWhite),
      labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.textWhite),
      labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.textWhite),
    ),
  );
}
