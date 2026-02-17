import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'share_card_base.dart';

/// Share card for streak milestone celebrations.
///
/// Displays a fire emoji, the streak count, and "يوم متتالي" label
/// on an amber-to-deep-orange gradient.
/// Arabic day form based on number agreement rules (تمييز العدد).
String _arabicDaysLabel(int count) {
  if (count >= 3 && count <= 10) return 'أيام متتالية';
  if (count % 100 == 0) return 'يوم متتالٍ';
  final lastTwo = count % 100;
  if (lastTwo >= 3 && lastTwo <= 10) return 'أيام متتالية';
  if (lastTwo >= 11) return 'يومًا متتاليًا';
  return 'يوم متتالٍ';
}

class StreakShareCard extends StatelessWidget {
  /// The card format (story or square).
  final ShareCardFormat format;

  /// The streak count in days.
  final int streak;

  /// Optional AI or static copy text.
  final String? copyText;

  /// Optional user name displayed at the bottom.
  final String? userName;

  /// Background gradient for the card (theme-aware).
  final LinearGradient gradient;

  const StreakShareCard({
    super.key,
    required this.format,
    required this.streak,
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
            _arabicDaysLabel(streak),
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
