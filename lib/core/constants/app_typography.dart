import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App Typography System - Beautiful Arabic & English Support
class AppTypography {
  AppTypography._();

  // Font Families
  static const String arabicFont = 'Cairo'; // For Arabic
  static const String englishFont = 'Poppins'; // For English (from Google Fonts)

  // Display Styles (Large headers)
  static TextStyle displayLarge = GoogleFonts.cairo(
    fontSize: 57,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static TextStyle displayMedium = GoogleFonts.cairo(
    fontSize: 45,
    fontWeight: FontWeight.bold,
    height: 1.16,
  );

  static TextStyle displaySmall = GoogleFonts.cairo(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    height: 1.22,
  );

  // Headline Styles (Section headers)
  static TextStyle headlineLarge = GoogleFonts.cairo(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.25,
  );

  static TextStyle headlineMedium = GoogleFonts.cairo(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.29,
  );

  static TextStyle headlineSmall = GoogleFonts.cairo(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.33,
  );

  // Title Styles (Card titles)
  static TextStyle titleLarge = GoogleFonts.cairo(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.27,
  );

  static TextStyle titleMedium = GoogleFonts.cairo(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.50,
  );

  static TextStyle titleSmall = GoogleFonts.cairo(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // Body Styles (Main content)
  static TextStyle bodyLarge = GoogleFonts.cairo(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.5,
    height: 1.50,
  );

  static TextStyle bodyMedium = GoogleFonts.cairo(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static TextStyle bodySmall = GoogleFonts.cairo(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // Label Styles (Buttons, labels)
  static TextStyle labelLarge = GoogleFonts.cairo(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static TextStyle labelMedium = GoogleFonts.cairo(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static TextStyle labelSmall = GoogleFonts.cairo(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // Custom Dramatic Styles
  static TextStyle hero = GoogleFonts.cairo(
    fontSize: 48,
    fontWeight: FontWeight.w900,
    letterSpacing: -1,
    height: 1.0,
  );

  static TextStyle dramatic = GoogleFonts.cairo(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
    height: 1.2,
  );

  static TextStyle celebration = GoogleFonts.cairo(
    fontSize: 40,
    fontWeight: FontWeight.w900,
    letterSpacing: 1,
    height: 1.1,
  );

  // Hadith/Quote Styles (Islamic content)
  static TextStyle hadithText = GoogleFonts.amiriQuran(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    height: 2.0,
    letterSpacing: 0.5,
  );

  static TextStyle hadithReference = GoogleFonts.cairo(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontStyle: FontStyle.italic,
    height: 1.5,
  );

  // Number Styles (for statistics)
  static TextStyle numberLarge = GoogleFonts.poppins(
    fontSize: 64,
    fontWeight: FontWeight.w900,
    letterSpacing: -2,
    height: 1.0,
  );

  static TextStyle numberMedium = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
    height: 1.0,
  );

  static TextStyle numberSmall = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.0,
  );

  // Button Text Styles
  static TextStyle buttonLarge = GoogleFonts.cairo(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.25,
    height: 1.0,
  );

  static TextStyle buttonMedium = GoogleFonts.cairo(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    height: 1.0,
  );

  static TextStyle buttonSmall = GoogleFonts.cairo(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    height: 1.0,
  );
}
