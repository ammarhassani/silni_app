import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/family_graph.dart';
import '../models/tree_layout.dart';

/// CustomPainter that renders the family tree on a canvas.
///
/// Consumes a [FamilyTreeLayout] (positioned nodes and edges) and draws:
/// - Bezier connection lines (color-coded by edge type and health)
/// - Circular nodes with health gradient fills
/// - Emoji, name, and label text per node
/// - Breathing animation (subtle scale pulse)
/// - Attention pulse ring for neglected relatives
/// - Staggered entry animation by generation
class FamilyTreePainter extends CustomPainter {
  final FamilyTreeLayout layout;

  /// Continuous 0.0-1.0 value driving breathing and pulse animations.
  final double animationValue;

  /// 0.0-1.0 progress for staggered entry animation.
  final double entryProgress;

  FamilyTreePainter({
    required this.layout,
    required this.animationValue,
    required this.entryProgress,
  });

  // ---------------------------------------------------------------------------
  // Colors
  // ---------------------------------------------------------------------------

  static const _healthyEdgeColor = Color(0xFF81C784); // light green
  static const _unhealthyEdgeColor = Color(0xFFE57373); // light red
  static const _spouseEdgeColor = Color(0xFFD4AF37); // gold
  static const _siblingEdgeColor = Color(0xFFA5D6A7); // very light green

  static final _greenGradient = [
    const Color(0xFF2D7A3E),
    const Color(0xFF4CAF50),
  ];
  static final _amberGradient = [
    const Color(0xFFF57F17),
    const Color(0xFFFFCA28),
  ];
  static final _redGradient = [
    const Color(0xFFC62828),
    const Color(0xFFEF5350),
  ];

  // ---------------------------------------------------------------------------
  // Paint
  // ---------------------------------------------------------------------------

  @override
  void paint(Canvas canvas, Size size) {
    // Draw edges first (below nodes)
    for (final edge in layout.edges) {
      _drawEdge(canvas, edge);
    }

    // Draw nodes on top
    for (final node in layout.nodes) {
      _drawNode(canvas, node);
    }
  }

  // ---------------------------------------------------------------------------
  // Edge drawing
  // ---------------------------------------------------------------------------

  void _drawEdge(Canvas canvas, LayoutEdge edge) {
    switch (edge.type) {
      case EdgeType.parentOf:
        _drawParentEdge(canvas, edge);
      case EdgeType.spouseOf:
        _drawSpouseEdge(canvas, edge);
      case EdgeType.siblingOf:
        _drawSiblingEdge(canvas, edge);
    }
  }

  void _drawParentEdge(Canvas canvas, LayoutEdge edge) {
    final paint = Paint()
      ..color = edge.isHealthy ? _healthyEdgeColor : _unhealthyEdgeColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final dy = (edge.to.dy - edge.from.dy).abs();
    final controlOffset = dy * 0.4;

    final path = Path()
      ..moveTo(edge.from.dx, edge.from.dy)
      ..cubicTo(
        edge.from.dx,
        edge.from.dy + controlOffset,
        edge.to.dx,
        edge.to.dy - controlOffset,
        edge.to.dx,
        edge.to.dy,
      );

    if (edge.isHealthy) {
      canvas.drawPath(path, paint);
    } else {
      _drawDashedPath(canvas, path, paint);
    }
  }

  void _drawSpouseEdge(Canvas canvas, LayoutEdge edge) {
    final paint = Paint()
      ..color = _spouseEdgeColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(edge.from, edge.to, paint);

    // Draw small ring at midpoint
    final mid = Offset(
      (edge.from.dx + edge.to.dx) / 2,
      (edge.from.dy + edge.to.dy) / 2,
    );
    final ringPaint = Paint()
      ..color = _spouseEdgeColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(mid, 5, ringPaint);
  }

  void _drawSiblingEdge(Canvas canvas, LayoutEdge edge) {
    final paint = Paint()
      ..color = _siblingEdgeColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Horizontal bracket: up from both, then across
    final bracketY = min(edge.from.dy, edge.to.dy) - 20;
    final path = Path()
      ..moveTo(edge.from.dx, edge.from.dy)
      ..lineTo(edge.from.dx, bracketY)
      ..lineTo(edge.to.dx, bracketY)
      ..lineTo(edge.to.dx, edge.to.dy);

    canvas.drawPath(path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final metrics = path.computeMetrics();
    const dashLength = 6.0;
    const gapLength = 4.0;

    for (final metric in metrics) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final len = draw ? dashLength : gapLength;
        final end = min(distance + len, metric.length);
        if (draw) {
          final extracted = metric.extractPath(distance, end);
          canvas.drawPath(extracted, paint);
        }
        distance = end;
        draw = !draw;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Node drawing
  // ---------------------------------------------------------------------------

  void _drawNode(Canvas canvas, LayoutNode node) {
    // Entry animation: stagger by generation
    final genDelay = node.generation.abs() * 0.2;
    if (entryProgress < genDelay) return; // not visible yet

    final entryOpacity = ((entryProgress - genDelay) / 0.2).clamp(0.0, 1.0);

    // Breathing animation
    final phase = (animationValue + node.generation * 0.1) % 1.0;
    final breathScale = 0.98 + 0.04 * sin(phase * 2 * pi);
    final animatedRadius = node.radius * breathScale;

    canvas.save();
    canvas.translate(node.position.dx, node.position.dy);

    // 1. Draw attention pulse ring (for neglected relatives)
    if (node.needsAttention) {
      _drawAttentionPulse(canvas, animatedRadius, entryOpacity);
    }

    // 2. Draw node circle with health gradient
    _drawNodeCircle(canvas, node, animatedRadius, entryOpacity);

    // 3. Draw user ring
    if (node.isUser) {
      _drawUserRing(canvas, animatedRadius, entryOpacity);
    }

    // 4. Draw emoji
    _drawEmoji(canvas, node.emoji, animatedRadius, entryOpacity);

    // 5. Draw name below circle
    _drawName(canvas, node.name, animatedRadius, entryOpacity);

    // 6. Draw label below name
    _drawLabel(canvas, node.label, animatedRadius, entryOpacity);

    // 7. Draw streak badge
    if (node.streakDays > 0) {
      _drawStreakBadge(canvas, node.streakDays, animatedRadius, entryOpacity);
    }

    canvas.restore();
  }

  void _drawAttentionPulse(Canvas canvas, double radius, double opacity) {
    final pulsePhase = (animationValue * 2) % 1.0;
    final pulseRadius = radius + 10 + pulsePhase * 15;
    final pulseOpacity = (1.0 - pulsePhase) * 0.4 * opacity;

    final pulsePaint = Paint()
      ..color = const Color(0xFFE57373).withValues(alpha: pulseOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(Offset.zero, pulseRadius, pulsePaint);
  }

  void _drawNodeCircle(
    Canvas canvas,
    LayoutNode node,
    double radius,
    double opacity,
  ) {
    final gradientColors = switch (node.healthColor) {
      HealthColor.green => _greenGradient,
      HealthColor.amber => _amberGradient,
      HealthColor.red => _redGradient,
    };

    final gradient = ui.Gradient.radial(
      Offset.zero,
      radius,
      [
        gradientColors[0].withValues(alpha: opacity),
        gradientColors[1].withValues(alpha: opacity),
      ],
    );

    final paint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, radius, paint);
  }

  void _drawUserRing(Canvas canvas, double radius, double opacity) {
    final ringPaint = Paint()
      ..color = AppColors.calmBlue.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(Offset.zero, radius + 2, ringPaint);
  }

  void _drawEmoji(Canvas canvas, String emoji, double radius, double opacity) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(
          fontSize: radius * 0.8,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
  }

  void _drawName(Canvas canvas, String name, double radius, double opacity) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      maxLines: 1,
      ellipsis: '...',
    );
    textPainter.layout(maxWidth: radius * 3);
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, radius + 6),
    );
  }

  void _drawLabel(Canvas canvas, String label, double radius, double opacity) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 10,
          color: Colors.white.withValues(alpha: opacity * 0.7),
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      maxLines: 1,
    );
    textPainter.layout(maxWidth: radius * 3);
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, radius + 22),
    );
  }

  void _drawStreakBadge(
    Canvas canvas,
    int streakDays,
    double radius,
    double opacity,
  ) {
    final badgeOffset = Offset(radius * 0.6, -radius * 0.6);
    final textPainter = TextPainter(
      text: TextSpan(
        text: '\u{1F525}$streakDays',
        style: TextStyle(
          fontSize: 10,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, badgeOffset);
  }

  // ---------------------------------------------------------------------------
  // Repaint logic
  // ---------------------------------------------------------------------------

  @override
  bool shouldRepaint(covariant FamilyTreePainter oldDelegate) {
    return layout != oldDelegate.layout ||
        animationValue != oldDelegate.animationValue ||
        entryProgress != oldDelegate.entryProgress;
  }
}
