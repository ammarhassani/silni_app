import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'share_card_base.dart';

/// Share card for badge unlock celebrations.
///
/// Displays the badge emoji, badge name, and "وسام جديد!" label
/// on a gradient derived from the badge's color.
class BadgeShareCard extends StatelessWidget {
  /// The card format (story or square).
  final ShareCardFormat format;

  /// The emoji representing the badge.
  final String badgeEmoji;

  /// The display name of the badge.
  final String badgeName;

  /// The badge's primary color, used to derive the gradient.
  final Color badgeColor;

  /// Optional AI or static copy text.
  final String? copyText;

  /// Optional user name displayed at the bottom.
  final String? userName;

  /// Background gradient for the card (theme-aware).
  final LinearGradient gradient;

  const BadgeShareCard({
    super.key,
    required this.format,
    required this.badgeEmoji,
    required this.badgeName,
    required this.badgeColor,
    required this.gradient,
    this.copyText,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return ShareCardBase(
      format: format,
      gradient: gradient,
      copyText: copyText,
      userName: userName,
      heroContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            badgeEmoji,
            style: const TextStyle(fontSize: 80),
          ),
          const SizedBox(height: 12),
          Text(
            badgeName,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\u0648\u0633\u0627\u0645 \u062C\u062F\u064A\u062F!', // وسام جديد!
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
