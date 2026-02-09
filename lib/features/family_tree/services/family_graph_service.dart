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
  // Global sibling edge enrichment
  // ---------------------------------------------------------------------------

  /// For every siblingOf edge (A↔B), propagate parentOf from A's parents to B
  /// and vice versa. This ensures the graph is complete for perspective labeling.
  ///
  /// Example: If Grandpa→Dad (parentOf) and Uncle↔Dad (siblingOf),
  /// this adds Grandpa→Uncle (parentOf).
  static FamilyGraph enrichAllSiblingEdges(FamilyGraph graph) {
    final extra = <FamilyEdge>[];
    final existingParentEdges = <String>{};

    // Index existing parentOf edges for fast duplicate checking
    for (final edge in graph.edges) {
      if (edge.type == EdgeType.parentOf) {
        existingParentEdges.add('${edge.fromId}->${edge.toId}');
      }
    }

    // Also track what we add so we don't add duplicates within this pass
    final added = <String>{};

    for (final edge in graph.edges) {
      if (edge.type != EdgeType.siblingOf) continue;

      // siblingOf is bidirectional: process both directions
      final pairs = [
        (edge.fromId, edge.toId),
        (edge.toId, edge.fromId),
      ];

      for (final (sibA, sibB) in pairs) {
        // For each parent of sibA, add parentOf→sibB if missing
        for (final parentId in graph.getParents(sibA)) {
          final key = '$parentId->$sibB';
          if (!existingParentEdges.contains(key) && !added.contains(key)) {
            extra.add(FamilyEdge.create(
              userId: graph.userId,
              fromId: parentId,
              toId: sibB,
              type: EdgeType.parentOf,
            ));
            added.add(key);
          }
        }
      }
    }

    if (extra.isEmpty) return graph;

    return FamilyGraphService.buildGraph(
      userId: graph.userId,
      edges: [...graph.edges, ...extra],
    );
  }

  // ---------------------------------------------------------------------------
  // Rahim scope (directional BFS)
  // ---------------------------------------------------------------------------

  /// Compute the set of node IDs visible from [viewerId]'s perspective.
  ///
  /// Uses directional BFS where the direction a node was reached from
  /// determines which edges can be traversed next:
  /// - **START** (viewer): UP + SIDEWAYS + DOWN
  /// - **VIA UP** (ancestor): UP + SIDEWAYS (not DOWN — prevents leaking)
  ///   SIDEWAYS here includes both explicit sibling edges AND the ancestor's
  ///   other children (who are the viewer's uncles/aunts/siblings by blood).
  /// - **VIA SIDEWAYS** (sibling of ancestor): DOWN only
  /// - **VIA DOWN** (descendant): DOWN only
  ///
  /// Additionally, the viewer's direct spouse is added (1-hop, not traversed from).
  static Set<String> computeRahimScope({
    required String viewerId,
    required FamilyGraph graph,
  }) {
    final scope = <String>{viewerId};

    final queue = <(String, _BfsDirection)>[(viewerId, _BfsDirection.start)];
    final visited = <String>{viewerId};

    while (queue.isNotEmpty) {
      final (nodeId, direction) = queue.removeAt(0);

      final canGoUp = direction == _BfsDirection.start ||
          direction == _BfsDirection.up;
      final canGoSideways = direction == _BfsDirection.start ||
          direction == _BfsDirection.up;
      final canGoDown = direction == _BfsDirection.start ||
          direction == _BfsDirection.sideways ||
          direction == _BfsDirection.down;

      if (canGoUp) {
        for (final parentId in graph.getParents(nodeId)) {
          if (visited.add(parentId)) {
            scope.add(parentId);
            queue.add((parentId, _BfsDirection.up));
          }
        }
      }

      if (canGoSideways) {
        // Explicit sibling edges
        for (final siblingId in graph.getSiblings(nodeId)) {
          if (visited.add(siblingId)) {
            scope.add(siblingId);
            queue.add((siblingId, _BfsDirection.sideways));
          }
        }

        // When at an ancestor (reached via UP), also discover the ancestor's
        // other children as SIDEWAYS — they are blood-related siblings/uncles
        // of the original viewer. This handles cases where siblings share
        // parents but lack explicit siblingOf edges between each other.
        if (direction == _BfsDirection.up) {
          for (final childId in graph.getChildren(nodeId)) {
            if (visited.add(childId)) {
              scope.add(childId);
              queue.add((childId, _BfsDirection.sideways));
            }
          }
        }
      }

      if (canGoDown) {
        for (final childId in graph.getChildren(nodeId)) {
          if (visited.add(childId)) {
            scope.add(childId);
            queue.add((childId, _BfsDirection.down));
          }
        }
      }
    }

    // Add direct spouse (1-hop, not traversed from)
    final spouseId = graph.getSpouse(viewerId);
    if (spouseId != null) {
      scope.add(spouseId);
    }

    return scope;
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
      // Parents: parentOf edge from parent to user + spouse edge to other parent
      case RelationshipType.father:
      case RelationshipType.mother:
        inferred.add(FamilyEdge.create(
          userId: userId,
          fromId: newRelativeId,
          toId: userId,
          type: EdgeType.parentOf,
        ));
        // Auto-link parents as spouses so they're treated as a couple
        final otherParentType = relationshipType == RelationshipType.father
            ? RelationshipType.mother
            : RelationshipType.father;
        final otherParent = existingRelatives.firstWhereOrNull(
          (r) => r.relationshipType == otherParentType,
        );
        if (otherParent != null) {
          final alreadyLinked = existingEdges.any((e) =>
              e.type == EdgeType.spouseOf &&
              ((e.fromId == newRelativeId && e.toId == otherParent.id) ||
                  (e.fromId == otherParent.id && e.toId == newRelativeId)));
          if (!alreadyLinked) {
            inferred.add(FamilyEdge.create(
              userId: userId,
              fromId: newRelativeId,
              toId: otherParent.id,
              type: EdgeType.spouseOf,
            ));
          }
        }
        break;

      // Siblings: siblingOf edge between sibling and user, plus shared parent edges
      case RelationshipType.brother:
      case RelationshipType.sister:
        inferred.add(FamilyEdge.create(
          userId: userId,
          fromId: newRelativeId,
          toId: userId,
          type: EdgeType.siblingOf,
        ));
        // Siblings share parents — add parent edges for the sibling too
        // This allows the graph to work from either sibling's perspective
        final father = existingRelatives.firstWhereOrNull(
          (r) => r.relationshipType == RelationshipType.father,
        );
        final mother = existingRelatives.firstWhereOrNull(
          (r) => r.relationshipType == RelationshipType.mother,
        );
        if (father != null) {
          inferred.add(FamilyEdge.create(
            userId: userId,
            fromId: father.id,
            toId: newRelativeId,
            type: EdgeType.parentOf,
          ));
        }
        if (mother != null) {
          inferred.add(FamilyEdge.create(
            userId: userId,
            fromId: mother.id,
            toId: newRelativeId,
            type: EdgeType.parentOf,
          ));
        }
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
          side: side,
          existingEdges: existingEdges,
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
          existingEdges: existingEdges,
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
        // Parent archived/deleted — use target's stored familySide.
        if (target != null && target.familySide != null) {
          return _labelFromFamilySide(target.familySide!, target.gender);
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

    // Fallback: use the relative's own label, with familySide disambiguation.
    final target = relativesMap[targetId];
    if (target != null) {
      if ((target.relationshipType == RelationshipType.uncle ||
              target.relationshipType == RelationshipType.aunt) &&
          target.familySide != null) {
        return _labelFromFamilySide(target.familySide!, target.gender);
      }
      return target.relationshipType.arabicName;
    }
    return '';
  }

  /// Resolve uncle/aunt label from stored [FamilySide] and gender.
  static String _labelFromFamilySide(FamilySide side, Gender? gender) {
    if (side == FamilySide.paternal) {
      return gender == Gender.female ? 'عمتي' : 'عمي';
    }
    return gender == Gender.female ? 'خالتي' : 'خالي';
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Find the parent (father or mother) that a grandparent should link to.
  ///
  /// If [side] is provided, returns ONLY the matching gendered parent.
  /// When a specific side is given but that parent doesn't exist, returns
  /// `null` rather than incorrectly falling back to the other parent
  /// (e.g. linking a maternal grandmother to the father).
  ///
  /// Only when [side] is `null` does it fall back to the first available
  /// parent.
  static String? _findParentId({
    required String userId,
    required List<Relative> existingRelatives,
    FamilySide? side,
    List<FamilyEdge> existingEdges = const [],
  }) {
    // When side is specified, return only the matching parent (or null).
    if (side == FamilySide.paternal) {
      return existingRelatives
          .firstWhereOrNull(
            (r) => r.relationshipType == RelationshipType.father,
          )
          ?.id;
    }
    if (side == FamilySide.maternal) {
      return existingRelatives
          .firstWhereOrNull(
            (r) => r.relationshipType == RelationshipType.mother,
          )
          ?.id;
    }

    // No side specified — be smart about which parent to pick.
    final father = existingRelatives.firstWhereOrNull(
      (r) => r.relationshipType == RelationshipType.father,
    );
    final mother = existingRelatives.firstWhereOrNull(
      (r) => r.relationshipType == RelationshipType.mother,
    );

    if (father == null && mother == null) return null;
    if (father != null && mother == null) return father.id;
    if (mother != null && father == null) return mother.id;

    // Both parents exist. Check if a grandparent is already linked to one
    // parent — if so, prefer the other to distribute evenly.
    final fatherHasParent = existingEdges.any(
      (e) => e.type == EdgeType.parentOf && e.toId == father!.id,
    );
    final motherHasParent = existingEdges.any(
      (e) => e.type == EdgeType.parentOf && e.toId == mother!.id,
    );

    if (fatherHasParent && !motherHasParent) return mother!.id;
    if (motherHasParent && !fatherHasParent) return father!.id;

    // Both or neither have grandparents — default to father.
    return father!.id;
  }

  /// Find the parent matching a given [FamilySide].
  static String? _findParentForSide({
    required String userId,
    required List<Relative> existingRelatives,
    FamilySide? side,
    List<FamilyEdge> existingEdges = const [],
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

    // No side specified — check if one parent already has siblings linked.
    final father = existingRelatives.firstWhereOrNull(
      (r) => r.relationshipType == RelationshipType.father,
    );
    final mother = existingRelatives.firstWhereOrNull(
      (r) => r.relationshipType == RelationshipType.mother,
    );

    if (father == null && mother == null) return null;
    if (father != null && mother == null) return father.id;
    if (mother != null && father == null) return mother.id;

    // Both exist, no side specified — default to father (paternal).
    // Don't alternate between parents; the caller should specify a side.
    return father!.id;
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

/// BFS direction for Rahim scope traversal.
enum _BfsDirection { start, up, sideways, down }

/// Extension to add `firstWhereOrNull` without requiring collection package.
extension _IterableExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
