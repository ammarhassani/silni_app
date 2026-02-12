import 'dart:ui';

import '../../../shared/models/relative_model.dart';
import '../models/family_graph.dart';
import '../models/placeholder_node.dart';

/// Pure static service that computes which placeholder nodes to show
/// in the family tree based on existing relatives.
///
/// Each filled node independently spawns its natural connections as
/// placeholders. The logic is per-node, not per-level — branches grow
/// independently.
class PlaceholderSpawnService {
  PlaceholderSpawnService._();

  static const _maxPlaceholders = 15;

  /// A counter used to generate unique placeholder IDs within a single call.
  static int _idCounter = 0;

  /// Compute placeholder nodes for the family tree.
  ///
  /// Returns [PlaceholderNode]s without positioned coordinates
  /// (all at [Offset.zero]). The layout service assigns positions later.
  static List<PlaceholderNode> computePlaceholders({
    required List<Relative> relatives,
    required Gender? userGender,
    bool isSharedTree = false,
  }) {
    _idCounter = 0;
    final active = relatives.where((r) => !r.isArchived).toList();
    final placeholders = <PlaceholderNode>[];

    // Look up key relatives by type
    final father = _findByType(active, RelationshipType.father);
    final mother = _findByType(active, RelationshipType.mother);

    // ── 1. Parents (if missing) ──
    if (father == null) {
      placeholders.add(_make(
        type: RelationshipType.father,
        expectedGender: Gender.male,
        label: 'أضف أبوك',
        generation: -1,
      ));
    }
    if (mother == null) {
      placeholders.add(_make(
        type: RelationshipType.mother,
        expectedGender: Gender.female,
        label: 'أضف أمك',
        generation: -1,
      ));
    }

    // ── 2. Spouse (must come before siblings so it's positioned closest to user) ──
    final hasSpouse = active.any((r) =>
        r.relationshipType == RelationshipType.husband ||
        r.relationshipType == RelationshipType.wife);

    if (!hasSpouse) {
      final isMale = userGender == Gender.male || userGender == null;
      placeholders.add(_make(
        type: isMale ? RelationshipType.wife : RelationshipType.husband,
        expectedGender: isMale ? Gender.female : Gender.male,
        label: isMale ? 'أضف زوجتك' : 'أضف زوجك',
        generation: 0,
      ));
    }

    // ── 3. Siblings (if any parent exists and no siblings yet) ──
    if (father != null || mother != null) {
      final hasSiblings = active.any((r) =>
          r.relationshipType == RelationshipType.brother ||
          r.relationshipType == RelationshipType.sister);
      if (!hasSiblings) {
        placeholders.add(_make(
          type: RelationshipType.brother,
          label: 'أخ/أخت',
          generation: 0,
        ));
      }
    }

    // ── 4. Per-parent branch spawns (grandparents, uncles, aunts) ──
    if (father != null) {
      _spawnParentBranch(
        parent: father,
        side: FamilySide.paternal,
        active: active,
        placeholders: placeholders,
      );
    }
    if (mother != null) {
      _spawnParentBranch(
        parent: mother,
        side: FamilySide.maternal,
        active: active,
        placeholders: placeholders,
      );
    }

    // ── 5. Uncle/aunt children spawns (cousins) ──
    // In shared trees, skip — the uncle/aunt adds their own children.
    if (!isSharedTree) {
      for (final relative in active) {
        if (_isUncleOrAunt(relative)) {
          _spawnUncleAuntChildren(
            uncleOrAunt: relative,
            active: active,
            placeholders: placeholders,
          );
        }
      }
    }

    // ── 6. Children (only when spouse exists) ──
    if (hasSpouse) {
      final hasChildren = active.any((r) =>
          r.relationshipType == RelationshipType.son ||
          r.relationshipType == RelationshipType.daughter);
      placeholders.add(_make(
        type: RelationshipType.son,
        label: hasChildren ? '+' : 'ابن/بنت',
        generation: 1,
        isCompact: hasChildren,
      ));
    }

    // Cap at max
    if (placeholders.length > _maxPlaceholders) {
      return placeholders.sublist(0, _maxPlaceholders);
    }
    return placeholders;
  }

  // ---------------------------------------------------------------------------
  // Parent branch spawning
  // ---------------------------------------------------------------------------

  /// Spawns grandparent + uncle/aunt placeholders for a given parent node.
  static void _spawnParentBranch({
    required Relative parent,
    required FamilySide side,
    required List<Relative> active,
    required List<PlaceholderNode> placeholders,
  }) {
    final isPaternal = side == FamilySide.paternal;

    // Grandparents
    final hasGrandfather = active.any((r) =>
        r.relationshipType == RelationshipType.grandfather &&
        r.familySide == side);
    final hasGrandmother = active.any((r) =>
        r.relationshipType == RelationshipType.grandmother &&
        r.familySide == side);

    if (!hasGrandfather) {
      placeholders.add(_make(
        type: RelationshipType.grandfather,
        side: side,
        expectedGender: Gender.male,
        parentNodeId: parent.id,
        label: isPaternal ? 'أبو أبي' : 'أبو أمي',
        generation: -2,
      ));
    }
    if (!hasGrandmother) {
      placeholders.add(_make(
        type: RelationshipType.grandmother,
        side: side,
        expectedGender: Gender.female,
        parentNodeId: parent.id,
        label: isPaternal ? 'أم أبي' : 'أم أمي',
        generation: -2,
      ));
    }

    // Uncle (عم or خال) — only show placeholder when slot is empty
    final hasUncleOnSide = active.any((r) =>
        r.relationshipType == RelationshipType.uncle && r.familySide == side);
    if (!hasUncleOnSide) {
      placeholders.add(_make(
        type: RelationshipType.uncle,
        side: side,
        expectedGender: Gender.male,
        parentNodeId: parent.id,
        label: isPaternal ? 'عم' : 'خال',
        generation: -1,
      ));
    }

    // Aunt (عمة or خالة) — only show placeholder when slot is empty
    final hasAuntOnSide = active.any((r) =>
        r.relationshipType == RelationshipType.aunt && r.familySide == side);
    if (!hasAuntOnSide) {
      placeholders.add(_make(
        type: RelationshipType.aunt,
        side: side,
        expectedGender: Gender.female,
        parentNodeId: parent.id,
        label: isPaternal ? 'عمة' : 'خالة',
        generation: -1,
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Uncle/aunt children (cousins)
  // ---------------------------------------------------------------------------

  /// Spawns a cousin placeholder for an existing uncle or aunt.
  static void _spawnUncleAuntChildren({
    required Relative uncleOrAunt,
    required List<Relative> active,
    required List<PlaceholderNode> placeholders,
  }) {
    final side = uncleOrAunt.familySide;

    // Check if any cousins already exist under this uncle/aunt.
    // We approximate by checking if there are cousins on the same side.
    final hasCousinsFromThis = active.any((r) =>
        r.relationshipType == RelationshipType.cousin &&
        r.familySide == side);

    placeholders.add(_make(
      type: RelationshipType.cousin,
      side: side,
      parentNodeId: uncleOrAunt.id,
      label: hasCousinsFromThis ? '+' : 'أبناءهم',
      generation: 0,
      isCompact: hasCousinsFromThis,
    ));
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static bool _isUncleOrAunt(Relative r) =>
      r.relationshipType == RelationshipType.uncle ||
      r.relationshipType == RelationshipType.aunt;

  static Relative? _findByType(List<Relative> list, RelationshipType type) {
    for (final r in list) {
      if (r.relationshipType == type) return r;
    }
    return null;
  }

  static PlaceholderNode _make({
    required RelationshipType type,
    FamilySide? side,
    Gender? expectedGender,
    String? parentNodeId,
    required String label,
    required int generation,
    bool isCompact = false,
  }) {
    _idCounter++;
    return PlaceholderNode(
      id: 'ph-$_idCounter',
      type: type,
      side: side,
      expectedGender: expectedGender,
      parentNodeId: parentNodeId,
      label: label,
      generation: generation,
      position: Offset.zero, // Positioned later by layout service
      radius: isCompact ? 20.0 : 30.0,
      isCompact: isCompact,
    );
  }
}
