import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

/// Builds a theme-matched MarkdownStyleSheet for the AI chat
/// Supports RTL Arabic text with proper styling
MarkdownStyleSheet buildChatMarkdownStyle(BuildContext context) {
  return MarkdownStyleSheet(
    // Base paragraph text
    p: AppTypography.bodyMedium.copyWith(
      color: Colors.white,
      height: 1.7,
    ),
    pPadding: const EdgeInsets.only(bottom: AppSpacing.sm),

    // Headers - decreasing sizes
    h1: AppTypography.headlineMedium.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
    h1Padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
    h2: AppTypography.headlineSmall.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
    h2Padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
    h3: AppTypography.titleLarge.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    ),
    h3Padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
    h4: AppTypography.titleMedium.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    ),
    h5: AppTypography.titleSmall.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    ),
    h6: AppTypography.labelLarge.copyWith(
      color: Colors.white70,
      fontWeight: FontWeight.w600,
    ),

    // Bold and italic
    strong: const TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    em: const TextStyle(
      fontStyle: FontStyle.italic,
      color: Colors.white,
    ),

    // Inline code
    code: GoogleFonts.firaCode(
      color: AppColors.islamicGreenLight,
      backgroundColor: Colors.black.withValues(alpha: 0.3),
      fontSize: 13,
    ),

    // Code blocks with glass effect
    codeblockDecoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.1),
        width: 1,
      ),
    ),
    codeblockPadding: const EdgeInsets.all(AppSpacing.md),

    // Blockquotes with Islamic green accent (right border for RTL)
    blockquote: AppTypography.bodyMedium.copyWith(
      color: Colors.white70,
      fontStyle: FontStyle.italic,
      height: 1.6,
    ),
    blockquoteDecoration: BoxDecoration(
      border: Border(
        right: BorderSide(
          color: AppColors.islamicGreenPrimary,
          width: 3,
        ),
      ),
    ),
    blockquotePadding: const EdgeInsets.only(
      right: AppSpacing.md,
      top: AppSpacing.xs,
      bottom: AppSpacing.xs,
    ),

    // Lists (RTL - padding on right side)
    listBullet: AppTypography.bodyMedium.copyWith(
      color: AppColors.islamicGreenLight,
    ),
    listIndent: 24,
    listBulletPadding: const EdgeInsets.only(right: AppSpacing.sm),

    // Links
    a: AppTypography.bodyMedium.copyWith(
      color: AppColors.islamicGreenLight,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.islamicGreenLight,
    ),

    // Horizontal rule
    horizontalRuleDecoration: BoxDecoration(
      border: Border(
        top: BorderSide(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
    ),

    // Table styling
    tableHead: AppTypography.labelMedium.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
    tableBody: AppTypography.bodySmall.copyWith(
      color: Colors.white,
    ),
    tableBorder: TableBorder.all(
      color: Colors.white.withValues(alpha: 0.2),
      width: 1,
    ),
    tableHeadAlign: TextAlign.right, // RTL
    tableCellsPadding: const EdgeInsets.all(AppSpacing.sm),

    // Checkbox for task lists
    checkbox: AppTypography.bodyMedium.copyWith(
      color: AppColors.islamicGreenPrimary,
    ),

    // Text alignment for RTL
    textAlign: WrapAlignment.end,
  );
}

/// Builds a compact markdown style for streaming content
MarkdownStyleSheet buildStreamingMarkdownStyle(BuildContext context) {
  final baseStyle = buildChatMarkdownStyle(context);
  return baseStyle.copyWith(
    // Reduce padding during streaming for smoother appearance
    pPadding: EdgeInsets.zero,
    h1Padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    h2Padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    h3Padding: const EdgeInsets.only(bottom: AppSpacing.xs),
  );
}
