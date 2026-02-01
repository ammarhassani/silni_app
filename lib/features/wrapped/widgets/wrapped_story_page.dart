import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable full-screen story page for the Wrapped experience.
///
/// Renders a centered column with a large emoji, a title, a big main value,
/// and a descriptive subtitle. Each element animates in sequentially when
/// the page becomes visible.
class WrappedStoryPage extends StatelessWidget {
  /// Large emoji displayed at the top of the page.
  final String emoji;

  /// Header text above the main value (e.g. "تواصلاتك هالسنة").
  final String title;

  /// The primary statistic or text, displayed prominently (e.g. "٣٤٢").
  final String mainValue;

  /// Descriptive text below the main value (e.g. "مرة تواصلت مع أقاربك").
  final String subtitle;

  /// Optional accent colour applied to the main value text.
  final Color? accentColor;

  const WrappedStoryPage({
    super.key,
    required this.emoji,
    required this.title,
    required this.mainValue,
    required this.subtitle,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 3),

          // Emoji
          Text(
            emoji,
            style: const TextStyle(fontSize: 80),
          )
              .animate()
              .scale(
                duration: 600.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 12),

          // Main value
          Text(
            mainValue,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: accentColor ?? Colors.white,
              height: 1.1,
            ),
          )
              .animate()
              .fadeIn(delay: 400.ms, duration: 500.ms)
              .slideY(
                begin: 0.2,
                end: 0,
                delay: 400.ms,
                duration: 500.ms,
                curve: Curves.easeOut,
              ),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

          const Spacer(flex: 4),
        ],
      ),
    );
  }
}
