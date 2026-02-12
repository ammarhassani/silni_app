import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_typography.dart';
import '../models/placeholder_node.dart';

/// A dashed-circle placeholder widget shown in the family tree for gaps
/// the user can fill by tapping.
///
/// Full placeholders show an Arabic label inside a dashed circle.
/// Compact placeholders show a small "+" button.
///
/// All placeholders have a uniform subtle breathing animation.
class PlaceholderNodeWidget extends StatelessWidget {
  final PlaceholderNode placeholder;
  final VoidCallback? onTap;

  const PlaceholderNodeWidget({
    super.key,
    required this.placeholder,
    this.onTap,
  });

  /// Full placeholder size (matches TreeNodeWidget dimensions).
  static const double nodeSize = 70.0;

  /// Compact "+" button size.
  static const double compactSize = 40.0;

  @override
  Widget build(BuildContext context) {
    final size = placeholder.isCompact ? compactSize : nodeSize;

    Widget child = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _DashedCirclePainter(isCompact: placeholder.isCompact),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                placeholder.label,
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: placeholder.isCompact ? 16 : 9,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );

    // Subtle breathing animation for all placeholders
    if (!placeholder.isCompact) {
      child = child
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scaleXY(
            begin: 1.0,
            end: 1.04,
            duration: 2000.ms,
            curve: Curves.easeInOut,
          );
    }

    return child;
  }
}

/// Paints a dashed circle border.
class _DashedCirclePainter extends CustomPainter {
  final bool isCompact;

  _DashedCirclePainter({required this.isCompact});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1.5;

    // Background fill
    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, fillPaint);

    // Dashed stroke
    final strokeAlpha = isCompact ? 0.35 : 0.4;
    final strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: strokeAlpha)
      ..strokeWidth = isCompact ? 1.2 : 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const segments = 12;
    const gapFraction = 0.3; // 30% gap between dashes
    for (int i = 0; i < segments; i++) {
      final startAngle = (2 * pi / segments) * i;
      final sweepAngle = (2 * pi / segments) * (1 - gapFraction);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        strokePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return isCompact != oldDelegate.isCompact;
  }
}
