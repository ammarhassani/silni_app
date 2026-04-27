import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../models/monthly_wrapped_model.dart';

/// A branded card widget that previews the monthly wrapped summary.
///
/// Shows the personality emoji, label, month name, key stat, and a
/// "صِلْني" watermark. Intended for use both as an in-screen preview
/// and as the capture target for sharing.
class WrappedCardWidget extends StatelessWidget {
  final MonthlyWrapped wrapped;
  final LinearGradient? gradient;

  const WrappedCardWidget({
    super.key,
    required this.wrapped,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final bg = gradient ?? AppColors.primaryGradient;
    final screenWidth = MediaQuery.of(context).size.width;
    final side = (screenWidth - 32).clamp(0.0, 360.0); // 16px padding each side, max 360

    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        gradient: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Month name
          Text(
            wrapped.arabicMonthName,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),

          const SizedBox(height: 8),

          // Personality emoji (large)
          Text(
            wrapped.personalityEmoji,
            style: const TextStyle(fontSize: 72),
          ),

          const SizedBox(height: 12),

          // Personality label
          Text(
            wrapped.personalityLabel,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 8),

          // Key stat
          Text(
            '${wrapped.totalInteractions} تفاعل',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),

          const Spacer(flex: 2),

          // Watermark
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              '\u0635\u0650\u0644\u0646\u064A', // صِلْني
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.6),
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
