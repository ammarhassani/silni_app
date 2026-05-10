import 'dart:ui';
import 'family_graph.dart';
import 'placeholder_node.dart';

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
  /// True when a real user has claimed this node in the family group.
  final bool isLinkedMember;
  /// True when there is a pending node_claim against this node awaiting
  /// admin decision. Visualised as a distinct ring (Phase 4).
  final bool hasPendingClaim;
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
    this.isLinkedMember = false,
    this.hasPendingClaim = false,
    required this.healthRatio,
    required this.streakDays,
    required this.radius,
  });

  LayoutNode copyWith({
    bool? hasPendingClaim,
    bool? isLinkedMember,
  }) {
    return LayoutNode(
      id: id,
      position: position,
      emoji: emoji,
      name: name,
      label: label,
      generation: generation,
      isUser: isUser,
      isLinkedMember: isLinkedMember ?? this.isLinkedMember,
      hasPendingClaim: hasPendingClaim ?? this.hasPendingClaim,
      healthRatio: healthRatio,
      streakDays: streakDays,
      radius: radius,
    );
  }

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

/// A junction bar that groups parent→sibling connections.
///
/// Instead of drawing individual sibling edges from a parent to each uncle/aunt,
/// a junction bar is placed between the parent and the sibling group with a
/// label like "أعمام" (paternal uncles) or "أخوال" (maternal uncles).
class LayoutJunction {
  final String id;
  final Offset position;
  final String label;

  /// The spine node (parent) this junction connects to.
  final String anchorId;

  /// The sibling node IDs branching from this junction.
  final List<String> siblingIds;

  const LayoutJunction({
    required this.id,
    required this.position,
    required this.label,
    required this.anchorId,
    required this.siblingIds,
  });
}

/// The complete layout data consumed by the painter.
class FamilyTreeLayout {
  final List<LayoutNode> nodes;
  final List<LayoutEdge> edges;
  final List<LayoutJunction> junctions;
  final List<PlaceholderNode> placeholders;
  final Rect bounds;
  final Offset userPosition;

  const FamilyTreeLayout({
    required this.nodes,
    required this.edges,
    this.junctions = const [],
    this.placeholders = const [],
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

  /// Hit-test: find the placeholder at [position], or null.
  /// Uses placeholder radius + 10px tap padding.
  PlaceholderNode? findPlaceholderAtPosition(Offset position) {
    const tapPadding = 10.0;
    for (final ph in placeholders) {
      final distance = (ph.position - position).distance;
      if (distance <= ph.radius + tapPadding) {
        return ph;
      }
    }
    return null;
  }
}
