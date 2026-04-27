import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Format options for share cards.
enum ShareCardFormat {
  /// Story format: 360x640 logical pixels, renders at 3x = 1080x1920.
  story,

  /// Square format: 360x360 logical pixels, renders at 3x = 1080x1080.
  square,
}

/// Base layout widget for all share cards.
///
/// Renders a branded card with app icon branding in the top-right,
/// hero content in the center, optional copy text, and optional user name
/// at the bottom. Supports both story (9:16) and square (1:1) formats.
class ShareCardBase extends StatelessWidget {
  /// The card format (story or square).
  final ShareCardFormat format;

  /// Background gradient for the card.
  final LinearGradient gradient;

  /// Main content displayed in the center of the card.
  final Widget heroContent;

  /// Optional AI or static text displayed below the hero content.
  final String? copyText;

  /// Optional user name displayed at the bottom.
  final String? userName;

  const ShareCardBase({
    super.key,
    required this.format,
    required this.gradient,
    required this.heroContent,
    this.copyText,
    this.userName,
  });

  double get _width => 360;

  double get _height => switch (format) {
        ShareCardFormat.story => 640,
        ShareCardFormat.square => 360,
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: _width,
        height: _height,
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Top-right: App icon + brand name
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.rtl,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        width: 32,
                        height: 32,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\u0635\u0650\u0644\u0646\u064A', // صِلْني
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Center: Hero content (expanded)
              Expanded(
                child: Center(child: heroContent),
              ),

              // Bottom: Copy text (if provided)
              if (copyText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    copyText!,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
                  ),
                ),

              // Bottom: User name (if provided)
              if (userName != null)
                Text(
                  userName!,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
