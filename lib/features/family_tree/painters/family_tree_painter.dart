import 'dart:math';

import 'package:flutter/material.dart';

import '../models/family_graph.dart';
import '../models/tree_layout.dart';

/// CustomPainter that renders organic connections between family tree cards.
///
/// Edge types:
/// - [EdgeType.parentOf]: Organic branch from parent midpoint, curving
///   outward to each child.
/// - [EdgeType.spouseOf]: Gentle arc with a "+" connector circle.
///
/// Junction bars replace sibling edges: parent → labeled bar → uncle/aunt nodes.
class FamilyTreeEdgePainter extends CustomPainter {
  final FamilyTreeLayout layout;

  /// Offset to translate edge coordinates into the local coordinate system
  /// of the containing widget (typically [FamilyTreeLayout.bounds.topLeft]).
  final Offset boundsOrigin;

  /// Whether to draw dashed connection lines to placeholder nodes.
  final bool showPlaceholders;

  FamilyTreeEdgePainter({
    required this.layout,
    this.boundsOrigin = Offset.zero,
    this.showPlaceholders = true,
  });

  // ---------------------------------------------------------------------------
  // Colors — clean, subtle palette
  // ---------------------------------------------------------------------------

  static const _lineColor = Color(0xFFB0BEC5); // soft blue-gray
  static const _unhealthyColor = Color(0xFFE57373); // soft red
  static const _spouseColor = Color(0xFFB0BEC5); // matching lines

  // ---------------------------------------------------------------------------
  // Paint
  // ---------------------------------------------------------------------------

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(-boundsOrigin.dx, -boundsOrigin.dy);

    // Draw organic parent→children branches.
    _paintParentConnectors(canvas);

    // Draw spouse edges.
    for (final edge in layout.edges) {
      if (edge.type == EdgeType.spouseOf) {
        _drawSpouseEdge(canvas, edge);
      }
    }

    // Draw junction bars for parent-sibling groups.
    _paintJunctionBars(canvas);

    // Draw dashed connections to placeholder nodes.
    if (showPlaceholders) {
      _paintPlaceholderConnections(canvas);
    }

    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // Parent branches
  // ---------------------------------------------------------------------------

  void _paintParentConnectors(Canvas canvas) {
    final parentEdges =
        layout.edges.where((e) => e.type == EdgeType.parentOf).toList();
    if (parentEdges.isEmpty) return;

    final childEdges = <String, List<LayoutEdge>>{};
    for (final e in parentEdges) {
      childEdges.putIfAbsent(e.toId, () => []).add(e);
    }

    final groups = <String, List<String>>{};
    final parentPosMap = <String, List<Offset>>{};

    for (final entry in childEdges.entries) {
      final childId = entry.key;
      final edges = entry.value;
      final key = (edges.map((e) => e.fromId).toList()..sort()).join(',');
      groups.putIfAbsent(key, () => []).add(childId);
      parentPosMap.putIfAbsent(
          key, () => edges.map((e) => e.from).toSet().toList());
    }

    for (final key in groups.keys) {
      final childIds = groups[key]!;
      final parentPositions = parentPosMap[key]!;
      final children = childIds.map((id) {
        final edges = childEdges[id]!;
        return (pos: edges.first.to, healthy: edges.every((e) => e.isHealthy));
      }).toList();

      _drawBranch(canvas, parentPositions, children);
    }
  }

  /// Draws a single continuous curve from parent midpoint to each child.
  /// Each connection is one bezier path — no intermediate junction point.
  /// A wider, low-alpha glow stroke is drawn first behind the main line.
  void _drawBranch(
    Canvas canvas,
    List<Offset> parentPositions,
    List<({Offset pos, bool healthy})> children,
  ) {
    // Parent midpoint.
    double px = 0, py = 0;
    for (final p in parentPositions) {
      px += p.dx;
      py += p.dy;
    }
    final midX = px / parentPositions.length;
    final parentY = py / parentPositions.length;

    final sorted = children.toList()
      ..sort((a, b) => a.pos.dx.compareTo(b.pos.dx));

    for (final child in sorted) {
      final color = child.healthy ? _lineColor : _unhealthyColor;

      final dx = child.pos.dx - midX;
      final dy = child.pos.dy - parentY;

      // Build a single continuous curve from parent to child.
      final path = Path()..moveTo(midX, parentY);

      if (dx.abs() < 3) {
        // Nearly vertical: gentle S-wobble.
        path.cubicTo(
          midX + 6, parentY + dy * 0.3,
          midX - 5, parentY + dy * 0.65,
          child.pos.dx, child.pos.dy,
        );
      } else {
        // Lateral: sweep outward then drop into child.
        path.cubicTo(
          midX + dx * 0.15, parentY + dy * 0.35,
          child.pos.dx - dx * 0.1, parentY + dy * 0.6,
          child.pos.dx, child.pos.dy,
        );
      }

      // Glow layer (wider, softer).
      _drawGlowPath(canvas, path, color);
    }
  }

  /// Draws a path with a two-layer glow effect: a wide soft halo behind
  /// a crisp foreground stroke, both the same hue.
  void _drawGlowPath(Canvas canvas, Path path, Color color) {
    // Glow: wide, very soft.
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, glowPaint);

    // Foreground: crisp line.
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  // ---------------------------------------------------------------------------
  // Spouse edge — arc with "+" connector
  // ---------------------------------------------------------------------------

  void _drawSpouseEdge(Canvas canvas, LayoutEdge edge) {
    // Gentle arc above the connection.
    final arcPeakY = min(edge.from.dy, edge.to.dy) - 8;
    final path = Path()
      ..moveTo(edge.from.dx, edge.from.dy)
      ..quadraticBezierTo(
        (edge.from.dx + edge.to.dx) / 2,
        arcPeakY,
        edge.to.dx,
        edge.to.dy,
      );
    _drawGlowPath(canvas, path, _spouseColor);

    // "+" connector circle at midpoint.
    final plusX = (edge.from.dx + edge.to.dx) / 2;
    final plusY = arcPeakY + (min(edge.from.dy, edge.to.dy) - arcPeakY) * 0.4;

    // Filled circle background.
    final bgPaint = Paint()
      ..color = const Color(0xFF37474F) // dark slate
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(plusX, plusY), 7, bgPaint);

    // Circle border.
    final borderPaint = Paint()
      ..color = _spouseColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(plusX, plusY), 7, borderPaint);

    // "+" sign — horizontal and vertical lines.
    final plusPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(plusX - 3.5, plusY), Offset(plusX + 3.5, plusY), plusPaint);
    canvas.drawLine(
      Offset(plusX, plusY - 3.5), Offset(plusX, plusY + 3.5), plusPaint);
  }

  // ---------------------------------------------------------------------------
  // Junction bars — parent → [label] → uncle/aunt nodes
  // ---------------------------------------------------------------------------

  void _paintJunctionBars(Canvas canvas) {
    if (layout.junctions.isEmpty) return;

    // Build a position lookup from layout nodes.
    final nodePos = <String, Offset>{};
    for (final node in layout.nodes) {
      nodePos[node.id] = node.position;
    }

    for (final junction in layout.junctions) {
      final anchorPos = nodePos[junction.anchorId];
      if (anchorPos == null) continue;

      for (final sibId in junction.siblingIds) {
        final sibPos = nodePos[sibId];
        if (sibPos == null) continue;

        final dx = sibPos.dx - anchorPos.dx;
        final dy = sibPos.dy - anchorPos.dy;

        final path = Path()..moveTo(anchorPos.dx, anchorPos.dy);

        if (dy.abs() < 5) {
          // Same row — wavy horizontal curve.
          const wavePeak = -8.0;
          path.cubicTo(
            anchorPos.dx + dx * 0.3, anchorPos.dy + wavePeak,
            anchorPos.dx + dx * 0.7, anchorPos.dy - wavePeak * 0.6,
            sibPos.dx, sibPos.dy,
          );
        } else {
          // Different row — bezier curve.
          path.cubicTo(
            anchorPos.dx + dx * 0.5, anchorPos.dy,
            sibPos.dx, anchorPos.dy + dy * 0.4,
            sibPos.dx, sibPos.dy,
          );
        }

        _drawGlowPath(canvas, path, _lineColor);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Placeholder connections — dashed lines to parent nodes
  // ---------------------------------------------------------------------------

  void _paintPlaceholderConnections(Canvas canvas) {
    if (layout.placeholders.isEmpty) return;

    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Build position lookup from layout nodes.
    final nodePos = <String, Offset>{};
    for (final node in layout.nodes) {
      nodePos[node.id] = node.position;
    }
    // Also include user position for parent-less placeholders.
    final userNode = layout.nodes.where((n) => n.isUser).firstOrNull;
    final userPos = userNode?.position ?? layout.userPosition;

    for (final ph in layout.placeholders) {
      // Determine anchor point: parentNodeId's position, or user.
      final Offset anchor;
      if (ph.parentNodeId != null && nodePos.containsKey(ph.parentNodeId)) {
        anchor = nodePos[ph.parentNodeId]!;
      } else {
        anchor = userPos;
      }

      // Draw curved dashed line from anchor to placeholder.
      _drawDashedCurve(canvas, anchor, ph.position, dashPaint);
    }
  }

  /// Draw a dashed bezier curve between two points.
  /// Uses a slight lateral offset so lines don't pass straight through nodes.
  void _drawDashedCurve(Canvas canvas, Offset from, Offset to, Paint paint) {
    final delta = to - from;
    final distance = delta.distance;
    if (distance < 5) return;

    // Control point: offset perpendicular to the line to create a gentle curve
    final midX = (from.dx + to.dx) / 2;
    final midY = (from.dy + to.dy) / 2;
    // Perpendicular offset (swap dx/dy, negate one) scaled to ~12% of distance
    final perpScale = distance * 0.12;
    final nx = -delta.dy / distance;
    final controlPt = Offset(midX + nx * perpScale, midY);

    // Sample the quadratic bezier and draw dashed segments
    const dashLength = 5.0;
    const gapLength = 4.0;
    const step = 0.01; // parameter step for sampling
    double drawnDist = 0;
    bool drawing = true;
    Offset prev = from;

    for (double t = step; t <= 1.0; t += step) {
      final oneMinusT = 1.0 - t;
      final pt = Offset(
        oneMinusT * oneMinusT * from.dx +
            2 * oneMinusT * t * controlPt.dx +
            t * t * to.dx,
        oneMinusT * oneMinusT * from.dy +
            2 * oneMinusT * t * controlPt.dy +
            t * t * to.dy,
      );
      final seg = (pt - prev).distance;
      drawnDist += seg;

      if (drawing) {
        canvas.drawLine(prev, pt, paint);
        if (drawnDist >= dashLength) {
          drawnDist = 0;
          drawing = false;
        }
      } else {
        if (drawnDist >= gapLength) {
          drawnDist = 0;
          drawing = true;
        }
      }
      prev = pt;
    }
  }

  // ---------------------------------------------------------------------------
  // Repaint
  // ---------------------------------------------------------------------------

  @override
  bool shouldRepaint(covariant FamilyTreeEdgePainter oldDelegate) {
    return layout != oldDelegate.layout ||
        boundsOrigin != oldDelegate.boundsOrigin ||
        showPlaceholders != oldDelegate.showPlaceholders;
  }
}
