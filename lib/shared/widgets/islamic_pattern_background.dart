import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_themes.dart';

/// Islamic geometric pattern background widget
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

/// Eight-Pointed Star Pattern (Rub el Hizb) - for Islamic Green theme
class _EightPointedStarPattern extends CustomPainter {
  final double opacity;

  _EightPointedStarPattern({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const spacing = 100.0;
    for (double x = -spacing; x < size.width + spacing; x += spacing) {
      for (double y = -spacing; y < size.height + spacing; y += spacing) {
        _drawEightPointedStar(canvas, Offset(x, y), 30, paint);
      }
    }
  }

  void _drawEightPointedStar(Canvas canvas, Offset center, double radius, Paint paint) {
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
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const spacing = 80.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        _drawArabesqueTile(canvas, Offset(x, y), spacing / 2, paint);
      }
    }
  }

  void _drawArabesqueTile(Canvas canvas, Offset center, double size, Paint paint) {
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
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const spacing = 90.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        _drawHexagonalTile(canvas, Offset(x, y), 30, paint);
      }
    }
  }

  void _drawHexagonalTile(Canvas canvas, Offset center, double radius, Paint paint) {
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
      ..color = Colors.white.withOpacity(opacity)
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
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const spacing = 95.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        _drawPersianFlower(canvas, Offset(x, y), 30, paint);
      }
    }
  }

  void _drawPersianFlower(Canvas canvas, Offset center, double radius, Paint paint) {
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
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const spacing = 90.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        _drawStarAndCross(canvas, Offset(x, y), 35, paint);
      }
    }
  }

  void _drawStarAndCross(Canvas canvas, Offset center, double size, Paint paint) {
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
