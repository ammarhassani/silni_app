import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'share_card_base.dart';

/// Share card for level-up celebrations.
///
/// Displays a star emoji and the new level number
/// on a gold-to-purple gradient.
class LevelUpShareCard extends StatelessWidget {
  /// The card format (story or square).
  final ShareCardFormat format;

  /// The new level reached.
  final int level;

  /// Optional AI or static copy text.
  final String? copyText;

  /// Optional user name displayed at the bottom.
  final String? userName;

  const LevelUpShareCard({
    super.key,
    required this.format,
    required this.level,
    this.copyText,
    this.userName,
  });

  static const _gradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFF7B2FF7)],
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
            '\u{2B50}', // star emoji
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 12),
          Text(
            '\u0645\u0633\u062A\u0648\u0649 $level', // مستوى [N]
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
