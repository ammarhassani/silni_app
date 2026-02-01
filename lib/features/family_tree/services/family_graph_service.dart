import '../../../shared/models/relative_model.dart';
import '../models/family_graph.dart';

/// Pure static service for building and querying the family graph.
///
/// Follows the project convention of private constructor + static methods.
/// No Supabase dependency — all operations are in-memory.
class FamilyGraphService {
  FamilyGraphService._();

  // ---------------------------------------------------------------------------
  // Graph construction
  // ---------------------------------------------------------------------------

  /// Build an in-memory [FamilyGraph] from a list of edges.
  ///
  /// Populates both forward and reverse adjacency maps for O(1) lookups.
  static FamilyGraph buildGraph({
    required String userId,
    required List<FamilyEdge> edges,
  }) {
    final adjacency = <String, List<FamilyEdge>>{};
    final reverseAdjacency = <String, List<FamilyEdge>>{};

    for (final edge in edges) {
      adjacency.putIfAbsent(edge.fromId, () => []).add(edge);
      reverseAdjacency.putIfAbsent(edge.toId, () => []).add(edge);
    }

    return FamilyGraph(
      userId: userId,
      adjacency: adjacency,
      reverseAdjacency: reverseAdjacency,
      edges: List.unmodifiable(edges),
    );
  }

  // ---------------------------------------------------------------------------
  // Edge inference
  // ---------------------------------------------------------------------------

  /// Infer graph edges from a relative's [RelationshipType].
  ///
  /// When the user adds a new relative, this method auto-generates the
  /// appropriate edges so the graph stays consistent without requiring
  /// the user to manually specify edges.
  ///
  /// Rules:
  /// - father/mother  -> parentOf(newRelative -> userId)
  /// - brother/sister  -> siblingOf(newRelative <-> userId)
  /// - son/daughter    -> parentOf(userId -> newRelative)
  /// - husband/wife    -> spouseOf(userId <-> newRelative)
  /// - grandfather/grandmother -> parentOf(newRelative -> father/mother)
  ///   (only if father/mother exists in existingRelatives)
  /// - uncle/aunt with [FamilySide.paternal] -> siblingOf(newRelative <-> father)
  /// - uncle/aunt with [FamilySide.maternal] -> siblingOf(newRelative <-> mother)
  static List<FamilyEdge> inferEdges({
    required String userId,
    required String newRelativeId,
    required RelationshipType relationshipType,
    FamilySide? side,
    required List<FamilyEdge> existingEdges,
    required List<Relative> existingRelatives,
  }) {
    final inferred = <FamilyEdge>[];

    switch (relationshipType) {
      // Parents: parentOf edge from parent to user
      case RelationshipType.father:
      case RelationshipType.mother:
        inferred.add(FamilyEdge.create(
          userId: userId,
          fromId: newRelativeId,
          toId: userId,
          type: EdgeType.parentOf,
        ));
        break;

      // Siblings: siblingOf edge between sibling and user
      case RelationshipType.brother:
      case RelationshipType.sister:
        inferred.add(FamilyEdge.create(
          userId: userId,
          fromId: newRelativeId,
          toId: userId,
          type: EdgeType.siblingOf,
        ));
        break;

      // Children: parentOf edge from user to child
      case RelationshipType.son:
      case RelationshipType.daughter:
        inferred.add(FamilyEdge.create(
          userId: userId,
          fromId: userId,
          toId: newRelativeId,
          type: EdgeType.parentOf,
        ));
        break;

      // Spouse: spouseOf edge between user and spouse
      case RelationshipType.husband:
      case RelationshipType.wife:
        inferred.add(FamilyEdge.create(
          userId: userId,
          fromId: userId,
          toId: newRelativeId,
          type: EdgeType.spouseOf,
        ));
        break;

      // Grandparents: parentOf edge from grandparent to father/mother
      case RelationshipType.grandfather:
      case RelationshipType.grandmother:
        final parentId = _findParentId(
          userId: userId,
          existingRelatives: existingRelatives,
          existingEdges: existingEdges,
          side: side,
        );
        if (parentId != null) {
          inferred.add(FamilyEdge.create(
            userId: userId,
            fromId: newRelativeId,
            toId: parentId,
            type: EdgeType.parentOf,
          ));
        }
        break;

      // Uncle/aunt: siblingOf edge between uncle/aunt and father or mother
      case RelationshipType.uncle:
      case RelationshipType.aunt:
        final parentId = _findParentForSide(
          userId: userId,
          existingRelatives: existingRelatives,
          side: side,
        );
        if (parentId != null) {
          inferred.add(FamilyEdge.create(
            userId: userId,
            fromId: newRelativeId,
            toId: parentId,
            type: EdgeType.siblingOf,
          ));
        }
        break;

      // Nephew/niece: child of a sibling
      // For now, just mark as child of user's sibling if one exists
      case RelationshipType.nephew:
      case RelationshipType.niece:
        final siblingId = _findFirstSibling(
          userId: userId,
          existingRelatives: existingRelatives,
        );
        if (siblingId != null) {
          inferred.add(FamilyEdge.create(
            userId: userId,
            fromId: siblingId,
            toId: newRelativeId,
            type: EdgeType.parentOf,
          ));
        }
        break;

      // Cousin: child of uncle/aunt
      case RelationshipType.cousin:
        final uncleAuntId = _findFirstUncleOrAunt(
          existingRelatives: existingRelatives,
        );
        if (uncleAuntId != null) {
          inferred.add(FamilyEdge.create(
            userId: userId,
            fromId: uncleAuntId,
            toId: newRelativeId,
            type: EdgeType.parentOf,
          ));
        }
        break;

      case RelationshipType.other:
        // No edges can be inferred for generic "other" relationships
        break;
    }

    return inferred;
  }

  // ---------------------------------------------------------------------------
  // Perspective-shifting labels
  // ---------------------------------------------------------------------------

  /// Compute the Arabic relationship label for [targetId] from
  /// [viewerId]'s perspective.
  ///
  /// Falls back to the relative's own [RelationshipType.arabicName] if
  /// the graph path cannot determine a more specific label.
  static String getLabelForViewer({
    required FamilyGraph graph,
    required String viewerId,
    required String targetId,
    required Map<String, Relative> relativesMap,
  }) {
    if (viewerId == targetId) return 'أنا';

    // Check direct relationships first

    // Is target a parent of viewer?
    final viewerParents = graph.getParents(viewerId);
    if (viewerParents.contains(targetId)) {
      final target = relativesMap[targetId];
      if (target != null) {
        final gender = target.gender;
        if (gender == Gender.male) return 'أبي';
        if (gender == Gender.female) return 'أمي';
      }
      return 'والدي';
    }

    // Is target a child of viewer?
    final viewerChildren = graph.getChildren(viewerId);
    if (viewerChildren.contains(targetId)) {
      final target = relativesMap[targetId];
      if (target != null) {
        final gender = target.gender;
        if (gender == Gender.male) return 'ابني';
        if (gender == Gender.female) return 'ابنتي';
      }
      return 'ابني';
    }

    // Is target a sibling of viewer?
    final viewerSiblings = graph.getSiblings(viewerId);
    if (viewerSiblings.contains(targetId)) {
      final target = relativesMap[targetId];
      if (target != null) {
        final gender = target.gender;
        if (gender == Gender.male) return 'أخوي';
        if (gender == Gender.female) return 'أختي';
      }
      return 'أخوي';
    }

    // Is target the spouse of viewer?
    final viewerSpouse = graph.getSpouse(viewerId);
    if (viewerSpouse == targetId) {
      final target = relativesMap[targetId];
      if (target != null) {
        final gender = target.gender;
        if (gender == Gender.male) return 'زوجي';
        if (gender == Gender.female) return 'زوجتي';
      }
      return 'زوجي';
    }

    // Is target a parent's sibling? (uncle/aunt from viewer's perspective)
    for (final parentId in viewerParents) {
      final parentSiblings = graph.getSiblings(parentId);
      if (parentSiblings.contains(targetId)) {
        final target = relativesMap[targetId];
        final parent = relativesMap[parentId];
        if (target != null && parent != null) {
          final targetGender = target.gender;
          final parentGender = parent.gender;

          // Father's side (paternal)
          if (parentGender == Gender.male) {
            if (targetGender == Gender.male) return 'عمي';
            if (targetGender == Gender.female) return 'عمتي';
          }
          // Mother's side (maternal)
          if (parentGender == Gender.female) {
            if (targetGender == Gender.male) return 'خالي';
            if (targetGender == Gender.female) return 'خالتي';
          }
        }
        return 'عمي'; // fallback
      }
    }

    // Is target a grandparent of viewer? (parent's parent)
    for (final parentId in viewerParents) {
      final grandparents = graph.getParents(parentId);
      if (grandparents.contains(targetId)) {
        final target = relativesMap[targetId];
        if (target != null) {
          final gender = target.gender;
          if (gender == Gender.male) return 'جدي';
          if (gender == Gender.female) return 'جدتي';
        }
        return 'جدي';
      }
    }

    // Is target a grandchild of viewer? (child's child)
    for (final childId in viewerChildren) {
      final grandchildren = graph.getChildren(childId);
      if (grandchildren.contains(targetId)) {
        final target = relativesMap[targetId];
        if (target != null) {
          final gender = target.gender;
          if (gender == Gender.male) return 'حفيدي';
          if (gender == Gender.female) return 'حفيدتي';
        }
        return 'حفيدي';
      }
    }

    // Fallback: use the relative's own label
    final target = relativesMap[targetId];
    if (target != null) {
      return target.relationshipType.arabicName;
    }
    return '';
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Find the parent (father or mother) that a grandparent should link to.
  ///
  /// If [side] is provided, looks for the matching gendered parent.
  /// Otherwise, falls back to the first available parent.
  static String? _findParentId({
    required String userId,
    required List<Relative> existingRelatives,
    required List<FamilyEdge> existingEdges,
    FamilySide? side,
  }) {
    // Try to find based on side
    if (side == FamilySide.paternal) {
      final father = existingRelatives.firstWhereOrNull(
        (r) => r.relationshipType == RelationshipType.father,
      );
      if (father != null) return father.id;
    } else if (side == FamilySide.maternal) {
      final mother = existingRelatives.firstWhereOrNull(
        (r) => r.relationshipType == RelationshipType.mother,
      );
      if (mother != null) return mother.id;
    }

    // Fallback: find any parent
    final father = existingRelatives.firstWhereOrNull(
      (r) => r.relationshipType == RelationshipType.father,
    );
    if (father != null) return father.id;

    final mother = existingRelatives.firstWhereOrNull(
      (r) => r.relationshipType == RelationshipType.mother,
    );
    if (mother != null) return mother.id;

    return null;
  }

  /// Find the parent matching a given [FamilySide].
  static String? _findParentForSide({
    required String userId,
    required List<Relative> existingRelatives,
    FamilySide? side,
  }) {
    if (side == FamilySide.paternal) {
      return existingRelatives
          .firstWhereOrNull(
            (r) => r.relationshipType == RelationshipType.father,
          )
          ?.id;
    } else if (side == FamilySide.maternal) {
      return existingRelatives
          .firstWhereOrNull(
            (r) => r.relationshipType == RelationshipType.mother,
          )
          ?.id;
    }

    // No side specified — try father first, then mother
    final father = existingRelatives.firstWhereOrNull(
      (r) => r.relationshipType == RelationshipType.father,
    );
    if (father != null) return father.id;

    return existingRelatives
        .firstWhereOrNull(
          (r) => r.relationshipType == RelationshipType.mother,
        )
        ?.id;
  }

  /// Find the first sibling of the user.
  static String? _findFirstSibling({
    required String userId,
    required List<Relative> existingRelatives,
  }) {
    return existingRelatives
        .firstWhereOrNull(
          (r) =>
              r.relationshipType == RelationshipType.brother ||
              r.relationshipType == RelationshipType.sister,
        )
        ?.id;
  }

  /// Find the first uncle or aunt in the relatives list.
  static String? _findFirstUncleOrAunt({
    required List<Relative> existingRelatives,
  }) {
    return existingRelatives
        .firstWhereOrNull(
          (r) =>
              r.relationshipType == RelationshipType.uncle ||
              r.relationshipType == RelationshipType.aunt,
        )
        ?.id;
  }
}

/// Extension to add `firstWhereOrNull` without requiring collection package.
extension _IterableExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
