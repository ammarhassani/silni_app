import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'share_card_base.dart';

/// Share card for occasion greeting celebrations.
///
/// Displays the occasion emoji, name, and greeting text
/// on an occasion-specific gradient (Ramadan, Eid, National Day, etc.).
class OccasionShareCard extends StatelessWidget {
  /// The card format (story or square).
  final ShareCardFormat format;

  /// The emoji representing the occasion.
  final String occasionEmoji;

  /// The display name of the occasion.
  final String occasionName;

  /// The greeting/message text.
  final String greetingText;

  /// Optional AI or static copy text.
  final String? copyText;

  /// Optional user name displayed at the bottom.
  final String? userName;

  const OccasionShareCard({
    super.key,
    required this.format,
    required this.occasionEmoji,
    required this.occasionName,
    required this.greetingText,
    this.copyText,
    this.userName,
  });

  /// Returns an occasion-specific gradient based on the occasion name.
  LinearGradient get _gradient {
    final nameLower = occasionName.toLowerCase();

    // Ramadan: deep blue to teal
    if (nameLower.contains('\u0631\u0645\u0636\u0627\u0646') || // رمضان
        nameLower.contains('ramadan')) {
      return const LinearGradient(
        colors: [Color(0xFF1A237E), Color(0xFF00695C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    // Eid: green to gold
    if (nameLower.contains('\u0639\u064A\u062F') || // عيد
        nameLower.contains('eid')) {
      return const LinearGradient(
        colors: [Color(0xFF2E7D32), Color(0xFFD4AF37)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    // National Day: green to white
    if (nameLower.contains('\u0648\u0637\u0646\u064A') || // وطني
        nameLower.contains('national')) {
      return const LinearGradient(
        colors: [Color(0xFF1B5E20), Color(0xFFA5D6A7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    // Default: teal to indigo
    return const LinearGradient(
      colors: [Color(0xFF00796B), Color(0xFF283593)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

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
          Text(
            occasionEmoji,
            style: const TextStyle(fontSize: 72),
          ),
          const SizedBox(height: 12),
          Text(
            '$occasionName \u0645\u0628\u0627\u0631\u0643', // [occasionName] مبارك
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              greetingText,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
