import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import 'shareable_card_generator.dart';

/// A branded card widget rendered off-screen for image capture and sharing.
///
/// This widget is NOT displayed in the UI. It is inserted into an [Overlay],
/// captured as an image, and shared via [Share.shareXFiles].
class ShareCardWidget extends StatelessWidget {
  final ShareableCardData cardData;
  final LinearGradient? gradient;

  const ShareCardWidget({
    super.key,
    required this.cardData,
    this.gradient,
  });

  /// Capture the card as an image and share it.
  ///
  /// Inserts the widget off-screen into the overlay, waits a frame for
  /// layout, captures the render object as a PNG, then shares.
  static Future<void> captureAndShare(
    BuildContext context,
    ShareableCardData cardData, {
    LinearGradient? gradient,
  }) async {
    final boundary = GlobalKey();

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        left: -2000, // Off-screen
        child: RepaintBoundary(
          key: boundary,
          child: ShareCardWidget(cardData: cardData, gradient: gradient),
        ),
      ),
    );

    overlay.insert(entry);
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final renderObject =
          boundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (renderObject == null) return;

      final image = await renderObject.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/silni_card_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: cardData.shareText,
      );
    } finally {
      entry.remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = gradient ?? AppColors.primaryGradient;

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 360,
        height: 360,
        child: Container(
          decoration: BoxDecoration(
            gradient: bg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Emoji
              Text(
                cardData.emoji,
                style: const TextStyle(fontSize: 72),
              ),

              const SizedBox(height: 16),

              // Title
              Text(
                cardData.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  cardData.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Watermark
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  '\u0635\u0650\u0644\u0646\u064A', // صِلني
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
        ),
      ),
    );
  }
}
