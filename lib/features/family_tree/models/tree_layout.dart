import 'dart:ui';
import 'family_graph.dart';

enum HealthColor { green, amber, red }

/// A positioned node ready for the painter.
class LayoutNode {
  final String id;
  final Offset position;
  final String emoji;
  final String name;
  final String label;
  final int generation;
  final bool isUser;
  /// 0.0 (never contacted) to 1.0 (just contacted). Drives node fill color.
  final double healthRatio;
  /// Active streak days. 0 = no streak. Shows fire badge when > 0.
  final int streakDays;
  /// Circle radius for hit testing and drawing.
  final double radius;

  const LayoutNode({
    required this.id,
    required this.position,
    required this.emoji,
    required this.name,
    required this.label,
    required this.generation,
    required this.isUser,
    required this.healthRatio,
    required this.streakDays,
    required this.radius,
  });

  HealthColor get healthColor {
    if (isUser) return HealthColor.green;
    if (healthRatio >= 0.7) return HealthColor.green;
    if (healthRatio >= 0.4) return HealthColor.amber;
    return HealthColor.red;
  }

  /// Whether this node needs an attention pulse animation.
  bool get needsAttention => !isUser && healthRatio < 0.4;
}

/// A positioned edge ready for the painter.
class LayoutEdge {
  final String fromId;
  final String toId;
  final Offset from;
  final Offset to;
  final EdgeType type;
  /// Healthy = solid line, unhealthy = dashed.
  final bool isHealthy;

  const LayoutEdge({
    required this.fromId,
    required this.toId,
    required this.from,
    required this.to,
    required this.type,
    required this.isHealthy,
  });
}

/// The complete layout data consumed by the painter.
class FamilyTreeLayout {
  final List<LayoutNode> nodes;
  final List<LayoutEdge> edges;
  final Rect bounds;
  final Offset userPosition;

  const FamilyTreeLayout({
    required this.nodes,
    required this.edges,
    required this.bounds,
    required this.userPosition,
  });

  /// Hit-test: find the node at [position], or null.
  /// Uses node radius + 10px tap padding.
  LayoutNode? findNodeAtPosition(Offset position) {
    const tapPadding = 10.0;
    for (final node in nodes) {
      final distance = (node.position - position).distance;
      if (distance <= node.radius + tapPadding) {
        return node;
      }
    }
    return null;
  }
}
