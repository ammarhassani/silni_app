import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import 'share_card_base.dart';

/// Share card for monthly/yearly wrapped summaries.
///
/// Displays the user's relationship personality, period name,
/// and key stats (total interactions, unique relatives, longest streak)
/// on the app's primary gradient.
class WrappedShareCard extends StatelessWidget {
  /// The card format (story or square).
  final ShareCardFormat format;

  /// The emoji representing the user's relationship personality.
  final String personalityEmoji;

  /// The label for the personality type (e.g. "الواصل الدائم").
  final String personalityLabel;

  /// The display name of the period (e.g. "يناير 2025").
  final String periodName;

  /// Total number of interactions in the period.
  final int totalInteractions;

  /// Number of unique relatives interacted with.
  final int uniqueRelatives;

  /// Longest streak in the period (optional).
  final int? longestStreak;

  /// Coverage percentage (0-100), shown in second stats row.
  final int? coveragePercent;

  /// Most used interaction type label (e.g. "مكالمة"), shown in second stats row.
  final String? mostUsedTypeLabel;

  /// Total active days (yearly only), shown in second stats row.
  final int? totalActiveDays;

  /// Optional AI or static copy text.
  final String? copyText;

  /// Optional user name displayed at the bottom.
  final String? userName;

  /// Background gradient (theme-aware). Falls back to AppColors.primaryGradient.
  final LinearGradient? gradient;

  const WrappedShareCard({
    super.key,
    required this.format,
    required this.personalityEmoji,
    required this.personalityLabel,
    required this.periodName,
    required this.totalInteractions,
    required this.uniqueRelatives,
    this.longestStreak,
    this.coveragePercent,
    this.mostUsedTypeLabel,
    this.totalActiveDays,
    this.copyText,
    this.userName,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return ShareCardBase(
      format: format,
      gradient: gradient ?? AppColors.primaryGradient,
      copyText: copyText,
      userName: userName,
      heroContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            personalityEmoji,
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 8),
          Text(
            personalityLabel,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            periodName,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              _StatItem(
                value: '$totalInteractions',
                label: '\u062A\u0648\u0627\u0635\u0644', // تواصل
              ),
              const SizedBox(width: 24),
              _StatItem(
                value: '$uniqueRelatives',
                label: '\u0634\u062E\u0635', // شخص
              ),
              if (longestStreak != null && longestStreak! > 0) ...[
                const SizedBox(width: 24),
                _StatItem(
                  value: '$longestStreak',
                  label: '\u0623\u0637\u0648\u0644 \u0633\u0644\u0633\u0644\u0629', // أطول سلسلة
                ),
              ],
            ],
          ),
          if (coveragePercent != null || mostUsedTypeLabel != null || totalActiveDays != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: TextDirection.rtl,
              children: [
                if (coveragePercent != null) ...[
                  _StatItem(value: '$coveragePercent٪', label: 'تغطية'),
                ],
                if (coveragePercent != null && (mostUsedTypeLabel != null || totalActiveDays != null))
                  const SizedBox(width: 24),
                if (mostUsedTypeLabel != null) ...[
                  _StatItem(value: mostUsedTypeLabel!, label: 'أكثر نوع تواصل'),
                ],
                if (mostUsedTypeLabel != null && totalActiveDays != null)
                  const SizedBox(width: 24),
                if (totalActiveDays != null) ...[
                  _StatItem(value: '$totalActiveDays', label: 'يوم نشط'),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A single stat item showing a value and label vertically.
class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
