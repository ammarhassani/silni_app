import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'share_card_base.dart';

/// Share card for streak milestone celebrations.
///
/// Displays a fire emoji, the streak count, and "يوم متتالي" label
/// on an amber-to-deep-orange gradient.
class StreakShareCard extends StatelessWidget {
  /// The card format (story or square).
  final ShareCardFormat format;

  /// The streak count in days.
  final int streak;

  /// Optional AI or static copy text.
  final String? copyText;

  /// Optional user name displayed at the bottom.
  final String? userName;

  const StreakShareCard({
    super.key,
    required this.format,
    required this.streak,
    this.copyText,
    this.userName,
  });

  static const _gradient = LinearGradient(
    colors: [Color(0xFFFF8A00), Color(0xFFE52E71)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    return ShareCardBase(
      format: format,
      gradient: _gradient,
      copyText: copyText,
      userName: userName,
      heroContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '\u{1F525}', // fire emoji
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 8),
          Text(
            '$streak',
            style: GoogleFonts.cairo(
              fontSize: 72,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\u064A\u0648\u0645 \u0645\u062A\u062A\u0627\u0644\u064A', // يوم متتالي
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
