import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

/// Builds a theme-matched MarkdownStyleSheet for the AI chat.
/// Supports RTL Arabic text with proper styling.
///
/// β6 — themeColors is required so quotes (scripture pull-quote treatment),
/// inline code, links, and the bullet glyph all adopt the active theme's
/// accent color instead of the hardcoded Islamic-green.
MarkdownStyleSheet buildChatMarkdownStyle(
  BuildContext context,
  dynamic themeColors,
) {
  final Color accent = themeColors.accent;

  return MarkdownStyleSheet(
    p: AppTypography.bodyMedium.copyWith(
      color: Colors.white.withValues(alpha: 0.95),
      height: 1.55,
      fontSize: 16.5,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
    ),
    pPadding: const EdgeInsets.only(bottom: AppSpacing.xs),

    // Headers — decreasing sizes
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

    strong: const TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    em: const TextStyle(
      fontStyle: FontStyle.italic,
      color: Colors.white,
    ),

    // β6 — inline code: theme-accent foreground on a dim background.
    code: GoogleFonts.firaCode(
      color: accent,
      backgroundColor: Colors.black.withValues(alpha: 0.3),
      fontSize: 13,
    ),

    // β6 — code block: theme-accent border + faint surface, monospace
    // body. Used for the rare AI snippets that include code.
    codeblockDecoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      border: Border.all(
        color: accent.withValues(alpha: 0.2),
        width: 1,
      ),
    ),
    codeblockPadding: const EdgeInsets.all(AppSpacing.sm + 4),

    // β6 — pull-quote treatment for blockquotes. The AI primarily uses
    // blockquotes for scripture references (hadiths, Quranic citations),
    // so all blockquotes adopt the reverent pull-quote treatment:
    // theme-accent thick border + faint accent surface + italic body.
    blockquote: AppTypography.bodyMedium.copyWith(
      color: Colors.white,
      fontStyle: FontStyle.italic,
      height: 1.7,
      fontSize: 16,
    ),
    blockquoteDecoration: BoxDecoration(
      color: accent.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      border: Border(
        right: BorderSide(
          color: accent,
          width: 3,
        ),
      ),
    ),
    blockquotePadding: const EdgeInsets.all(AppSpacing.md),

    // Lists — RTL: tighten the indent so continuation lines wrap closer to
    // the right edge instead of sliding toward the center (β.fix#3 — the
    // 24px indent was making numbered-list continuation feel "hugged to
    // the middle" because each wrap would drift inward by 24px).
    listBullet: AppTypography.bodyMedium.copyWith(
      color: accent,
      fontSize: 16.5,
      fontWeight: FontWeight.w600,
    ),
    listIndent: 14,
    listBulletPadding: const EdgeInsets.only(right: AppSpacing.xs),

    // Links
    a: AppTypography.bodyMedium.copyWith(
      color: accent,
      decoration: TextDecoration.underline,
      decorationColor: accent,
    ),

    horizontalRuleDecoration: BoxDecoration(
      border: Border(
        top: BorderSide(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
    ),

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

    checkbox: AppTypography.bodyMedium.copyWith(
      color: accent,
    ),

    // RTL alignment — α1 fix preserved.
    textAlign: WrapAlignment.start,
    h1Align: WrapAlignment.start,
    h2Align: WrapAlignment.start,
    h3Align: WrapAlignment.start,
    h4Align: WrapAlignment.start,
    h5Align: WrapAlignment.start,
    h6Align: WrapAlignment.start,
    unorderedListAlign: WrapAlignment.start,
    orderedListAlign: WrapAlignment.start,
    blockquoteAlign: WrapAlignment.start,
  );
}

/// Builds a markdown style for AI content in cards (reports, analysis).
/// Adds text shadows for readability on gradient backgrounds.
MarkdownStyleSheet buildCardMarkdownStyle(
  BuildContext context,
  dynamic themeColors,
) {
  final shadow = [
    Shadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 6,
    ),
  ];
  final base = buildChatMarkdownStyle(context, themeColors);
  return base.copyWith(
    p: base.p?.copyWith(
      color: Colors.white.withValues(alpha: 0.9),
      height: 1.6,
      shadows: shadow,
    ),
    pPadding: const EdgeInsets.only(bottom: 4),
    strong: base.strong?.copyWith(shadows: shadow),
    em: base.em?.copyWith(shadows: shadow),
    h1: base.h1?.copyWith(shadows: shadow),
    h2: base.h2?.copyWith(shadows: shadow),
    h3: base.h3?.copyWith(shadows: shadow),
  );
}

/// Builds a compact markdown style for streaming content.
MarkdownStyleSheet buildStreamingMarkdownStyle(
  BuildContext context,
  dynamic themeColors,
) {
  final baseStyle = buildChatMarkdownStyle(context, themeColors);
  return baseStyle.copyWith(
    pPadding: EdgeInsets.zero,
    h1Padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    h2Padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    h3Padding: const EdgeInsets.only(bottom: AppSpacing.xs),
  );
}
