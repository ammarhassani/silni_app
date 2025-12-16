import 'package:flutter/material.dart';
import 'package:silni_app/core/theme/app_themes.dart';

/// Static Connected Heart Logo for app icons
class StaticHeartLogo extends StatelessWidget {
  final ThemeColors themeColors;
  final double size;

  const StaticHeartLogo({
    super.key,
    required this.themeColors,
    this.size = 1024,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StaticConnectedHeartPainter(themeColors: themeColors),
        size: Size(size, size),
      ),
    );
  }
}

/// Alias for backward compatibility
typedef StaticTreeOfLifeLogo = StaticHeartLogo;
typedef StaticFamilyNetworkLogo = StaticHeartLogo;

class _StaticConnectedHeartPainter extends CustomPainter {
  final ThemeColors themeColors;

  _StaticConnectedHeartPainter({required this.themeColors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;

    // 3 tree positions (triangle around center)
    final treePositions = [
      Offset(center.dx, center.dy - radius), // Top
      Offset(center.dx - radius * 0.87, center.dy + radius * 0.5), // Bottom-left
      Offset(center.dx + radius * 0.87, center.dy + radius * 0.5), // Bottom-right
    ];

    // Draw connections
    _drawConnections(canvas, center, treePositions, size);

    // Draw connection symbol in center (interlocking rings)
    _drawConnectionSymbol(canvas, center, size.width * 0.22);

    // Draw trees
    _drawTrees(canvas, treePositions, size.width * 0.09);
  }

  void _drawConnections(Canvas canvas, Offset center, List<Offset> nodes, Size size) {
    final linePaint = Paint()
      ..color = themeColors.primaryLight.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.012
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = themeColors.primaryLight.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.024
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.015);

    // Draw lines from each tree to center
    for (final node in nodes) {
      canvas.drawLine(node, center, glowPaint);
      canvas.drawLine(node, center, linePaint);
    }

    // Draw triangle connecting trees
    final trianglePaint = Paint()
      ..color = themeColors.primaryLight.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.012
      ..strokeCap = StrokeCap.round;

    final triangleGlowPaint = Paint()
      ..color = themeColors.primaryLight.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.024
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.015);

    for (int i = 0; i < 3; i++) {
      final from = nodes[i];
      final to = nodes[(i + 1) % 3];
      canvas.drawLine(from, to, triangleGlowPaint);
      canvas.drawLine(from, to, trianglePaint);
    }
  }

  void _drawConnectionSymbol(Canvas canvas, Offset center, double symbolSize) {
    final ringRadius = symbolSize * 0.4;
    final offset = symbolSize * 0.22;

    final leftCenter = Offset(center.dx - offset, center.dy);
    final rightCenter = Offset(center.dx + offset, center.dy);

    // Outer glow for both rings
    final outerGlow = Paint()
      ..color = themeColors.secondary.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = symbolSize * 0.12
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, symbolSize * 0.15);
    canvas.drawCircle(leftCenter, ringRadius, outerGlow);
    canvas.drawCircle(rightCenter, ringRadius, outerGlow);

    // Main ring stroke
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = symbolSize * 0.08
      ..strokeCap = StrokeCap.round;

    // Left ring gradient
    ringPaint.shader = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      radius: 1.2,
      colors: [themeColors.accent, themeColors.secondary],
    ).createShader(Rect.fromCircle(center: leftCenter, radius: ringRadius));
    canvas.drawCircle(leftCenter, ringRadius, ringPaint);

    // Right ring gradient
    ringPaint.shader = RadialGradient(
      center: const Alignment(0.3, -0.3),
      radius: 1.2,
      colors: [themeColors.secondary, themeColors.accent],
    ).createShader(Rect.fromCircle(center: rightCenter, radius: ringRadius));
    canvas.drawCircle(rightCenter, ringRadius, ringPaint);

    // Highlight on rings
    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, symbolSize * 0.03);
    canvas.drawCircle(
      Offset(leftCenter.dx - ringRadius * 0.4, leftCenter.dy - ringRadius * 0.4),
      symbolSize * 0.06,
      highlight,
    );
    canvas.drawCircle(
      Offset(rightCenter.dx - ringRadius * 0.4, rightCenter.dy - ringRadius * 0.4),
      symbolSize * 0.06,
      highlight,
    );
  }

  void _drawTrees(Canvas canvas, List<Offset> positions, double treeSize) {
    for (final pos in positions) {
      _drawTree(canvas, pos, treeSize);
    }
  }

  void _drawTree(Canvas canvas, Offset center, double size) {
    // Tree trunk
    final trunkWidth = size * 0.18;
    final trunkHeight = size * 0.5;
    final trunkRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + size * 0.25),
        width: trunkWidth,
        height: trunkHeight,
      ),
      Radius.circular(trunkWidth * 0.3),
    );

    // Trunk glow
    final trunkGlow = Paint()
      ..color = themeColors.primaryDark.withValues(alpha: 0.5)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.08);
    canvas.drawRRect(trunkRect, trunkGlow);

    // Trunk fill
    final trunkFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [themeColors.primary, themeColors.primaryDark],
      ).createShader(trunkRect.outerRect);
    canvas.drawRRect(trunkRect, trunkFill);

    // Tree crown (triangular foliage)
    final crownPath = Path();
    final crownTop = center.dy - size * 0.5;
    final crownBottom = center.dy + size * 0.1;
    final crownWidth = size * 0.7;

    crownPath.moveTo(center.dx, crownTop); // Top point
    crownPath.lineTo(center.dx - crownWidth / 2, crownBottom); // Bottom left
    crownPath.lineTo(center.dx + crownWidth / 2, crownBottom); // Bottom right
    crownPath.close();

    // Crown glow
    final crownGlow = Paint()
      ..color = themeColors.primary.withValues(alpha: 0.5)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.12);
    canvas.drawPath(crownPath, crownGlow);

    // Crown fill
    final crownFill = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.5),
        radius: 1.2,
        colors: [themeColors.primaryLight, themeColors.primary],
      ).createShader(Rect.fromCenter(
        center: Offset(center.dx, center.dy - size * 0.2),
        width: crownWidth,
        height: size * 0.6,
      ));
    canvas.drawPath(crownPath, crownFill);

    // Crown highlight
    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.45);
    canvas.drawCircle(
      Offset(center.dx - size * 0.12, crownTop + size * 0.2),
      size * 0.06,
      highlight,
    );
  }

  @override
  bool shouldRepaint(covariant _StaticConnectedHeartPainter old) =>
      old.themeColors != themeColors;
}

/// Screen to preview and export the static logo
class LogoExportScreen extends StatelessWidget {
  const LogoExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logo Export'),
        backgroundColor: ThemeColors.defaultGreen.primary,
      ),
      body: Container(
        color: Colors.grey[900],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Static Logo Preview',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ThemeColors.defaultGreen.secondary.withValues(alpha: 0.5),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const StaticHeartLogo(
                  themeColors: ThemeColors.defaultGreen,
                  size: 300,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'To export as app icon:\n'
                '1. Take a screenshot of the logo above\n'
                '2. Or use Flutter\'s RepaintBoundary to capture\n'
                '3. Resize to 1024x1024 for iOS App Store\n'
                '4. Use tools like App Icon Generator for all sizes',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
