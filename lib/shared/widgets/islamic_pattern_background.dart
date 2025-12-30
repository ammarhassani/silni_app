import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_themes.dart';
import '../../core/constants/pattern_animation_constants.dart';

/// Touch ripple data for animated pattern effects
class TouchRipple {
  final Offset center;
  final double progress; // 0.0 to 1.0
  final double maxRadius;

  const TouchRipple({
    required this.center,
    required this.progress,
    this.maxRadius = PatternAnimationConstants.rippleMaxRadius,
  });

  double get currentRadius => maxRadius * progress;
  double get opacity =>
      (1.0 - progress) * PatternAnimationConstants.rippleStartOpacity;
}

/// Islamic geometric pattern background widget (static version)
/// Each theme has its own unique pattern design
class IslamicPatternBackground extends StatelessWidget {
  final AppThemeType themeType;
  final Widget child;
  final double opacity;

  const IslamicPatternBackground({
    super.key,
    required this.themeType,
    required this.child,
    this.opacity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Pattern layer
        Positioned.fill(
          child: CustomPaint(
            painter: _getPatternPainter(themeType, opacity),
          ),
        ),
        // Content on top
        child,
      ],
    );
  }

  CustomPainter _getPatternPainter(AppThemeType type, double opacity) {
    switch (type) {
      case AppThemeType.defaultGreen:
        return _EightPointedStarPattern(opacity: opacity);
      case AppThemeType.lavenderPurple:
        return _ArabesquePattern(opacity: opacity);
      case AppThemeType.royalBlue:
        return _GeometricTilingPattern(opacity: opacity);
      case AppThemeType.sunsetOrange:
        return _MoroccanZelligePattern(opacity: opacity);
      case AppThemeType.roseGold:
        return _PersianFlowerPattern(opacity: opacity);
      case AppThemeType.midnightDark:
        return _StarAndCrossPattern(opacity: opacity);
    }
  }
}

// =============================================================================
// STATIC PATTERN PAINTERS (Original Implementation)
// =============================================================================

/// Eight-Pointed Star Pattern (Rub el Hizb) - for Islamic Green theme
class _EightPointedStarPattern extends CustomPainter {
  final double opacity;

  _EightPointedStarPattern({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const spacing = 100.0;
    for (double x = -spacing; x < size.width + spacing; x += spacing) {
      for (double y = -spacing; y < size.height + spacing; y += spacing) {
        _drawEightPointedStar(canvas, Offset(x, y), 30, paint);
      }
    }
  }

  void _drawEightPointedStar(
      Canvas canvas, Offset center, double radius, Paint paint) {
    const pointCount = 8;
    final path = Path();

    for (int i = 0; i < pointCount * 2; i++) {
      final angle = (i * math.pi / pointCount) - math.pi / 2;
      final r = i.isEven ? radius : radius * 0.5;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Inner circle
    canvas.drawCircle(center, radius * 0.3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Arabesque Curved Pattern - for Lavender theme
class _ArabesquePattern extends CustomPainter {
  final double opacity;

  _ArabesquePattern({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const spacing = 80.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        _drawArabesqueTile(canvas, Offset(x, y), spacing / 2, paint);
      }
    }
  }

  void _drawArabesqueTile(
      Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();

    // Create flowing arabesque curves
    path.moveTo(center.dx - size, center.dy);
    path.quadraticBezierTo(
      center.dx - size / 2,
      center.dy - size,
      center.dx,
      center.dy,
    );
    path.quadraticBezierTo(
      center.dx + size / 2,
      center.dy + size,
      center.dx + size,
      center.dy,
    );

    canvas.drawPath(path, paint);

    // Mirror vertically
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1, -1);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawPath(path, paint);
    canvas.restore();

    // Add decorative circles
    canvas.drawCircle(center, size * 0.2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Geometric Tiling Pattern - for Royal Blue theme
class _GeometricTilingPattern extends CustomPainter {
  final double opacity;

  _GeometricTilingPattern({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const spacing = 90.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        _drawHexagonalTile(canvas, Offset(x, y), 30, paint);
      }
    }
  }

  void _drawHexagonalTile(
      Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();

    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3) - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Inner star
    for (int i = 0; i < 6; i++) {
      final angle1 = (i * math.pi / 3) - math.pi / 2;
      final angle2 = ((i + 1) * math.pi / 3) - math.pi / 2;

      final x1 = center.dx + radius * 0.5 * math.cos(angle1);
      final y1 = center.dy + radius * 0.5 * math.sin(angle1);
      final x2 = center.dx + radius * 0.5 * math.cos(angle2);
      final y2 = center.dy + radius * 0.5 * math.sin(angle2);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Moroccan Zellige Pattern - for Sunset Orange theme
class _MoroccanZelligePattern extends CustomPainter {
  final double opacity;

  _MoroccanZelligePattern({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const spacing = 100.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        _drawZelligeTile(canvas, Offset(x, y), 35, paint);
      }
    }
  }

  void _drawZelligeTile(Canvas canvas, Offset center, double size, Paint paint) {
    // Draw four-pointed star
    final path = Path();
    const points = 4;

    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points);
      final r = i.isEven ? size : size * 0.4;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Surrounding squares
    canvas.drawRect(
      Rect.fromCenter(center: center, width: size * 1.6, height: size * 1.6),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Persian Flower Pattern - for Rose Gold theme
class _PersianFlowerPattern extends CustomPainter {
  final double opacity;

  _PersianFlowerPattern({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const spacing = 95.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        _drawPersianFlower(canvas, Offset(x, y), 30, paint);
      }
    }
  }

  void _drawPersianFlower(
      Canvas canvas, Offset center, double radius, Paint paint) {
    const petalCount = 8;

    // Draw petals
    for (int i = 0; i < petalCount; i++) {
      final angle = (i * 2 * math.pi / petalCount);
      final path = Path();

      final startX = center.dx + radius * 0.3 * math.cos(angle);
      final startY = center.dy + radius * 0.3 * math.sin(angle);
      final endX = center.dx + radius * math.cos(angle);
      final endY = center.dy + radius * math.sin(angle);

      final controlAngle1 = angle - math.pi / 16;
      final controlAngle2 = angle + math.pi / 16;

      path.moveTo(startX, startY);
      path.quadraticBezierTo(
        center.dx + radius * 0.8 * math.cos(controlAngle1),
        center.dy + radius * 0.8 * math.sin(controlAngle1),
        endX,
        endY,
      );
      path.quadraticBezierTo(
        center.dx + radius * 0.8 * math.cos(controlAngle2),
        center.dy + radius * 0.8 * math.sin(controlAngle2),
        startX,
        startY,
      );

      canvas.drawPath(path, paint);
    }

    // Center circle
    canvas.drawCircle(center, radius * 0.25, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Star and Cross Pattern - for Midnight Dark theme
class _StarAndCrossPattern extends CustomPainter {
  final double opacity;

  _StarAndCrossPattern({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const spacing = 90.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        _drawStarAndCross(canvas, Offset(x, y), 35, paint);
      }
    }
  }

  void _drawStarAndCross(
      Canvas canvas, Offset center, double size, Paint paint) {
    // Draw 12-pointed star
    const points = 12;
    final path = Path();

    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final r = i.isEven ? size : size * 0.6;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Cross pattern
    canvas.drawLine(
      Offset(center.dx - size, center.dy),
      Offset(center.dx + size, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - size),
      Offset(center.dx, center.dy + size),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// ANIMATED PATTERN PAINTERS
// =============================================================================

/// Base class for all animated pattern painters
abstract class AnimatedPatternPainter extends CustomPainter {
  final double opacity;
  final double pulseMultiplier;
  final Offset parallaxOffset;
  final double shimmerPosition;
  final List<TouchRipple> ripples;
  final Offset? touchPosition;

  AnimatedPatternPainter({
    required this.opacity,
    this.pulseMultiplier = 1.0,
    this.parallaxOffset = Offset.zero,
    this.shimmerPosition = -1.0,
    this.ripples = const [],
    this.touchPosition,
    super.repaint,
  });

  /// Subclasses override this to draw their specific pattern
  void paintPattern(Canvas canvas, Size size, Paint paint);

  @override
  void paint(Canvas canvas, Size size) {
    final effectiveOpacity = (opacity * pulseMultiplier).clamp(0.0, 1.0);

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: effectiveOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.save();

    // Apply parallax/flow offset (includes vertical drift)
    canvas.translate(parallaxOffset.dx, parallaxOffset.dy);

    // Draw the pattern
    paintPattern(canvas, size, paint);

    canvas.restore();

    // Draw shimmer overlay
    if (shimmerPosition >= 0 && shimmerPosition <= 1) {
      _drawShimmer(canvas, size);
    }

    // Draw touch ripples
    for (final ripple in ripples) {
      _drawRipple(canvas, ripple);
    }

    // Draw touch glow
    if (touchPosition != null) {
      _drawTouchGlow(canvas, touchPosition!);
    }
  }

  void _drawShimmer(Canvas canvas, Size size) {
    final shimmerX = size.width * shimmerPosition;
    final shimmerWidth = size.width * PatternAnimationConstants.shimmerWidth;

    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.white.withValues(alpha: 0.0),
        Colors.white
            .withValues(alpha: PatternAnimationConstants.shimmerOpacityBoost),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final rect = Rect.fromLTWH(
      shimmerX - shimmerWidth / 2,
      0,
      shimmerWidth,
      size.height,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..blendMode = BlendMode.plus;

    canvas.drawRect(rect, paint);
  }

  void _drawRipple(Canvas canvas, TouchRipple ripple) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: ripple.opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(ripple.center, ripple.currentRadius, paint);
  }

  void _drawTouchGlow(Canvas canvas, Offset position) {
    final gradient = RadialGradient(
      colors: [
        Colors.white
            .withValues(alpha: PatternAnimationConstants.touchGlowOpacity),
        Colors.white.withValues(alpha: 0.0),
      ],
    );

    final rect = Rect.fromCircle(
      center: position,
      radius: PatternAnimationConstants.touchGlowRadius,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..blendMode = BlendMode.plus;

    canvas.drawCircle(
        position, PatternAnimationConstants.touchGlowRadius, paint);
  }

  @override
  bool shouldRepaint(covariant AnimatedPatternPainter oldDelegate) {
    return opacity != oldDelegate.opacity ||
        pulseMultiplier != oldDelegate.pulseMultiplier ||
        parallaxOffset != oldDelegate.parallaxOffset ||
        shimmerPosition != oldDelegate.shimmerPosition ||
        ripples.length != oldDelegate.ripples.length ||
        touchPosition != oldDelegate.touchPosition;
  }
}

/// Animated Eight-Pointed Star Pattern (Rub el Hizb) - for Islamic Green theme
class AnimatedEightPointedStarPattern extends AnimatedPatternPainter {
  AnimatedEightPointedStarPattern({
    required super.opacity,
        super.pulseMultiplier,
    super.parallaxOffset,
    super.shimmerPosition,
    super.ripples,
    super.touchPosition,
    super.repaint,
  });

  @override
  void paintPattern(Canvas canvas, Size size, Paint paint) {
    const spacing = 100.0;
    for (double x = -spacing; x < size.width + spacing * 2; x += spacing) {
      for (double y = -spacing; y < size.height + spacing * 2; y += spacing) {
        _drawEightPointedStar(canvas, Offset(x, y), 30, paint);
      }
    }
  }

  void _drawEightPointedStar(
      Canvas canvas, Offset center, double radius, Paint paint) {
    const pointCount = 8;
    final path = Path();

    for (int i = 0; i < pointCount * 2; i++) {
      final angle = (i * math.pi / pointCount) - math.pi / 2;
      final r = i.isEven ? radius : radius * 0.5;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawCircle(center, radius * 0.3, paint);
  }
}

/// Animated Arabesque Curved Pattern - for Lavender theme
class AnimatedArabesquePattern extends AnimatedPatternPainter {
  AnimatedArabesquePattern({
    required super.opacity,
        super.pulseMultiplier,
    super.parallaxOffset,
    super.shimmerPosition,
    super.ripples,
    super.touchPosition,
    super.repaint,
  });

  @override
  void paintPattern(Canvas canvas, Size size, Paint paint) {
    const spacing = 80.0;
    for (double x = -spacing; x < size.width + spacing * 2; x += spacing) {
      for (double y = -spacing; y < size.height + spacing * 2; y += spacing) {
        _drawArabesqueTile(canvas, Offset(x, y), spacing / 2, paint);
      }
    }
  }

  void _drawArabesqueTile(
      Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx - size, center.dy);
    path.quadraticBezierTo(
        center.dx - size / 2, center.dy - size, center.dx, center.dy);
    path.quadraticBezierTo(
        center.dx + size / 2, center.dy + size, center.dx + size, center.dy);
    canvas.drawPath(path, paint);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1, -1);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawPath(path, paint);
    canvas.restore();

    canvas.drawCircle(center, size * 0.2, paint);
  }
}

/// Animated Geometric Tiling Pattern - for Royal Blue theme
class AnimatedGeometricTilingPattern extends AnimatedPatternPainter {
  AnimatedGeometricTilingPattern({
    required super.opacity,
        super.pulseMultiplier,
    super.parallaxOffset,
    super.shimmerPosition,
    super.ripples,
    super.touchPosition,
    super.repaint,
  });

  @override
  void paintPattern(Canvas canvas, Size size, Paint paint) {
    const spacing = 90.0;
    for (double x = -spacing; x < size.width + spacing * 2; x += spacing) {
      for (double y = -spacing; y < size.height + spacing * 2; y += spacing) {
        _drawHexagonalTile(canvas, Offset(x, y), 30, paint);
      }
    }
  }

  void _drawHexagonalTile(
      Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3) - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    for (int i = 0; i < 6; i++) {
      final angle1 = (i * math.pi / 3) - math.pi / 2;
      final angle2 = ((i + 1) * math.pi / 3) - math.pi / 2;
      final x1 = center.dx + radius * 0.5 * math.cos(angle1);
      final y1 = center.dy + radius * 0.5 * math.sin(angle1);
      final x2 = center.dx + radius * 0.5 * math.cos(angle2);
      final y2 = center.dy + radius * 0.5 * math.sin(angle2);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }
}

/// Animated Moroccan Zellige Pattern - for Sunset Orange theme
class AnimatedMoroccanZelligePattern extends AnimatedPatternPainter {
  AnimatedMoroccanZelligePattern({
    required super.opacity,
        super.pulseMultiplier,
    super.parallaxOffset,
    super.shimmerPosition,
    super.ripples,
    super.touchPosition,
    super.repaint,
  });

  @override
  void paintPattern(Canvas canvas, Size size, Paint paint) {
    const spacing = 100.0;
    for (double x = -spacing; x < size.width + spacing * 2; x += spacing) {
      for (double y = -spacing; y < size.height + spacing * 2; y += spacing) {
        _drawZelligeTile(canvas, Offset(x, y), 35, paint);
      }
    }
  }

  void _drawZelligeTile(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    const points = 4;
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points);
      final r = i.isEven ? size : size * 0.4;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawRect(
      Rect.fromCenter(center: center, width: size * 1.6, height: size * 1.6),
      paint,
    );
  }
}

/// Animated Persian Flower Pattern - for Rose Gold theme
class AnimatedPersianFlowerPattern extends AnimatedPatternPainter {
  AnimatedPersianFlowerPattern({
    required super.opacity,
        super.pulseMultiplier,
    super.parallaxOffset,
    super.shimmerPosition,
    super.ripples,
    super.touchPosition,
    super.repaint,
  });

  @override
  void paintPattern(Canvas canvas, Size size, Paint paint) {
    const spacing = 95.0;
    for (double x = -spacing; x < size.width + spacing * 2; x += spacing) {
      for (double y = -spacing; y < size.height + spacing * 2; y += spacing) {
        _drawPersianFlower(canvas, Offset(x, y), 30, paint);
      }
    }
  }

  void _drawPersianFlower(
      Canvas canvas, Offset center, double radius, Paint paint) {
    const petalCount = 8;
    for (int i = 0; i < petalCount; i++) {
      final angle = (i * 2 * math.pi / petalCount);
      final path = Path();
      final startX = center.dx + radius * 0.3 * math.cos(angle);
      final startY = center.dy + radius * 0.3 * math.sin(angle);
      final endX = center.dx + radius * math.cos(angle);
      final endY = center.dy + radius * math.sin(angle);
      final controlAngle1 = angle - math.pi / 16;
      final controlAngle2 = angle + math.pi / 16;

      path.moveTo(startX, startY);
      path.quadraticBezierTo(
        center.dx + radius * 0.8 * math.cos(controlAngle1),
        center.dy + radius * 0.8 * math.sin(controlAngle1),
        endX,
        endY,
      );
      path.quadraticBezierTo(
        center.dx + radius * 0.8 * math.cos(controlAngle2),
        center.dy + radius * 0.8 * math.sin(controlAngle2),
        startX,
        startY,
      );
      canvas.drawPath(path, paint);
    }
    canvas.drawCircle(center, radius * 0.25, paint);
  }
}

/// Animated Star and Cross Pattern - for Midnight Dark theme
class AnimatedStarAndCrossPattern extends AnimatedPatternPainter {
  AnimatedStarAndCrossPattern({
    required super.opacity,
        super.pulseMultiplier,
    super.parallaxOffset,
    super.shimmerPosition,
    super.ripples,
    super.touchPosition,
    super.repaint,
  });

  @override
  void paintPattern(Canvas canvas, Size size, Paint paint) {
    const spacing = 90.0;
    for (double x = -spacing; x < size.width + spacing * 2; x += spacing) {
      for (double y = -spacing; y < size.height + spacing * 2; y += spacing) {
        _drawStarAndCross(canvas, Offset(x, y), 35, paint);
      }
    }
  }

  void _drawStarAndCross(
      Canvas canvas, Offset center, double size, Paint paint) {
    const points = 12;
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final r = i.isEven ? size : size * 0.6;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    canvas.drawLine(
      Offset(center.dx - size, center.dy),
      Offset(center.dx + size, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - size),
      Offset(center.dx, center.dy + size),
      paint,
    );
  }
}

/// Factory function to get animated painter for theme type
AnimatedPatternPainter getAnimatedPatternPainter({
  required AppThemeType themeType,
  required double opacity,
  double pulseMultiplier = 1.0,
  Offset parallaxOffset = Offset.zero,
  double shimmerPosition = -1.0,
  List<TouchRipple> ripples = const [],
  Offset? touchPosition,
  Listenable? repaint,
}) {
  switch (themeType) {
    case AppThemeType.defaultGreen:
      return AnimatedEightPointedStarPattern(
        opacity: opacity,
        pulseMultiplier: pulseMultiplier,
        parallaxOffset: parallaxOffset,
        shimmerPosition: shimmerPosition,
        ripples: ripples,
        touchPosition: touchPosition,
        repaint: repaint,
      );
    case AppThemeType.lavenderPurple:
      return AnimatedArabesquePattern(
        opacity: opacity,
        pulseMultiplier: pulseMultiplier,
        parallaxOffset: parallaxOffset,
        shimmerPosition: shimmerPosition,
        ripples: ripples,
        touchPosition: touchPosition,
        repaint: repaint,
      );
    case AppThemeType.royalBlue:
      return AnimatedGeometricTilingPattern(
        opacity: opacity,
        pulseMultiplier: pulseMultiplier,
        parallaxOffset: parallaxOffset,
        shimmerPosition: shimmerPosition,
        ripples: ripples,
        touchPosition: touchPosition,
        repaint: repaint,
      );
    case AppThemeType.sunsetOrange:
      return AnimatedMoroccanZelligePattern(
        opacity: opacity,
        pulseMultiplier: pulseMultiplier,
        parallaxOffset: parallaxOffset,
        shimmerPosition: shimmerPosition,
        ripples: ripples,
        touchPosition: touchPosition,
        repaint: repaint,
      );
    case AppThemeType.roseGold:
      return AnimatedPersianFlowerPattern(
        opacity: opacity,
        pulseMultiplier: pulseMultiplier,
        parallaxOffset: parallaxOffset,
        shimmerPosition: shimmerPosition,
        ripples: ripples,
        touchPosition: touchPosition,
        repaint: repaint,
      );
    case AppThemeType.midnightDark:
      return AnimatedStarAndCrossPattern(
        opacity: opacity,
        pulseMultiplier: pulseMultiplier,
        parallaxOffset: parallaxOffset,
        shimmerPosition: shimmerPosition,
        ripples: ripples,
        touchPosition: touchPosition,
        repaint: repaint,
      );
  }
}
