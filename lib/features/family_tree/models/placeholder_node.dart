import 'dart:ui';
import '../../../shared/models/relative_model.dart';
import 'family_graph.dart';

/// A dashed placeholder node in the family tree that represents a gap
/// the user can fill by tapping.
///
/// Each placeholder carries all relationship metadata derived from its
/// position in the tree — so the user never needs a relationship picker,
/// side selector, or gender dropdown.
class PlaceholderNode {
  final String id;

  /// The relationship type this slot expects (father, uncle, cousin...).
  final RelationshipType type;

  /// Paternal or maternal — determined by which parent branch this hangs from.
  final FamilySide? side;

  /// Expected gender — male for عم, female for خالة, null if either.
  final Gender? expectedGender;

  /// The existing relative whose node spawned this placeholder.
  /// e.g. father's node spawns the عم placeholder, so parentNodeId = father's ID.
  final String? parentNodeId;

  /// Arabic label shown inside the dashed circle.
  /// e.g. "أضف أبوك", "أضف عمك", "أضف أبناء خالك"
  final String label;

  /// Generation level in the tree (same system as LayoutNode).
  final int generation;

  /// Position computed by the layout service (same coordinate system as LayoutNode).
  final Offset position;

  /// Circle radius for hit testing and drawing.
  final double radius;

  /// Whether this is a small "+" button (for adding more siblings/cousins)
  /// rather than a full labeled placeholder circle.
  final bool isCompact;

  const PlaceholderNode({
    required this.id,
    required this.type,
    this.side,
    this.expectedGender,
    this.parentNodeId,
    required this.label,
    required this.generation,
    required this.position,
    required this.radius,
    this.isCompact = false,
  });

  /// Create a copy with a new position (used by layout service).
  PlaceholderNode copyWithPosition(Offset newPosition) {
    return PlaceholderNode(
      id: id,
      type: type,
      side: side,
      expectedGender: expectedGender,
      parentNodeId: parentNodeId,
      label: label,
      generation: generation,
      position: newPosition,
      radius: radius,
      isCompact: isCompact,
    );
  }
}
