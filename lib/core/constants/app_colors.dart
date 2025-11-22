import 'package:flutter/material.dart';

/// App Color System - Dramatic and Beautiful
class AppColors {
  AppColors._();

  // Primary Gradient - Islamic Green
  static const primaryGradient = LinearGradient(
    colors: [
      Color(0xFF2D7A3E),
      Color(0xFF4CAF50),
      Color(0xFF81C784),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Golden Gradient - Premium & Achievement
  static const goldenGradient = LinearGradient(
    colors: [
      Color(0xFFD4AF37),
      Color(0xFFFFD700),
      Color(0xFFFFFF8D),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Emotional Colors
  static const emotionalPurple = Color(0xFF9C27B0);
  static const joyfulOrange = Color(0xFFFF9800);
  static const calmBlue = Color(0xFF2196F3);
  static const energeticRed = Color(0xFFE91E63);

  // Glassmorphism Colors
  static const glassLight = Color(0x66FFFFFF);
  static const glassDark = Color(0x66000000);
  static const glassWhite = Color(0x33FFFFFF);
  static const glassBlack = Color(0x33000000);
  static const blurStrength = 20.0;

  // Background Gradients - DRAMATIC & COLORFUL
  static const backgroundGradientLight = LinearGradient(
    colors: [
      Color(0xFF1B5E20), // Deep Islamic Green
      Color(0xFF2E7D32), // Medium Green
      Color(0xFF388E3C), // Lighter Green
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const backgroundGradientDark = LinearGradient(
    colors: [
      Color(0xFF1A1A1A),
      Color(0xFF2D3E2D),
      Color(0xFF1B5E20),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Semantic Colors
  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFE53935);
  static const warning = Color(0xFFFFA726);
  static const info = Color(0xFF29B6F6);

  // Text Colors
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const textHint = Color(0xFFBDBDBD);
  static const textWhite = Color(0xFFFFFFFF);

  // Card Colors
  static const cardLight = Color(0xFFFFFFFF);
  static const cardDark = Color(0xFF2C2C2C);

  // Islamic Green Shades
  static const islamicGreenDark = Color(0xFF1B5E20);
  static const islamicGreenPrimary = Color(0xFF4CAF50);
  static const islamicGreenLight = Color(0xFF81C784);
  static const islamicGreenLighter = Color(0xFFC8E6C9);

  // Premium Gold Shades
  static const premiumGold = Color(0xFFFFD700);
  static const premiumGoldDark = Color(0xFFD4AF37);
  static const premiumGoldLight = Color(0xFFFFFF8D);

  // Streak Colors (for gamification)
  static const streakFire = LinearGradient(
    colors: [
      Color(0xFFFF6B35),
      Color(0xFFFF9E00),
      Color(0xFFFFD60A),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Level Colors
  static const level1 = Color(0xFF81C784);
  static const level2 = Color(0xFF4CAF50);
  static const level3 = Color(0xFF388E3C);
  static const level4 = Color(0xFF2E7D32);
  static const level5 = Color(0xFF1B5E20);
  static const levelMax = Color(0xFFFFD700);

  // Priority Colors
  static const priorityHigh = Color(0xFFE53935);
  static const priorityMedium = Color(0xFFFFA726);
  static const priorityLow = Color(0xFF66BB6A);

  // Mood Colors
  static const moodHappy = Color(0xFFFFEB3B);
  static const moodNeutral = Color(0xFF9E9E9E);
  static const moodSad = Color(0xFF5C6BC0);
  static const moodExcited = Color(0xFFFF5722);
  static const moodCalm = Color(0xFF26C6DA);

  // Overlay Colors
  static const overlayLight = Color(0x33000000);
  static const overlayMedium = Color(0x66000000);
  static const overlayDark = Color(0x99000000);

  // Shadow Colors
  static const shadowLight = Color(0x1A000000);
  static const shadowMedium = Color(0x33000000);
  static const shadowDark = Color(0x4D000000);

  // Shimmer Colors (for loading states)
  static const shimmerBase = Color(0xFFE0E0E0);
  static const shimmerHighlight = Color(0xFFF5F5F5);

  // Neon/Glow Colors (for dramatic effects)
  static const neonGreen = Color(0xFF00FF41);
  static const neonGold = Color(0xFFFFD700);
  static const neonPurple = Color(0xFFBF40BF);
  static const neonBlue = Color(0xFF00D9FF);
}
