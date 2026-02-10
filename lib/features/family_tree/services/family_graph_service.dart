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
  // Perspective remapping
  // ---------------------------------------------------------------------------

  /// Remap each relative's [relationshipType] and [familySide] to the
  /// viewer's perspective using the graph.
  ///
  /// In a shared tree every relative is stored with the *original adder's*
  /// relationship type.  When a different member views the tree the
  /// placeholder service and layout need types from *their* perspective
  /// (e.g. the adder's "mother" is the viewer-uncle's "sister").
  ///
  /// Requires an **enriched** graph (run [enrichAllSiblingEdges] first).
  static List<Relative> remapForViewer({
    required String viewerId,
    required FamilyGraph graph,
    required List<Relative> relatives,
    required Map<String, Relative> relativesMap,
  }) {
    final parents = graph.getParents(viewerId);
    final siblings = graph.getSiblings(viewerId);
    final children = graph.getChildren(viewerId);
    final spouseId = graph.getSpouse(viewerId);

    // Identify which parent is male / female for familySide
    String? fatherId, motherId;
    for (final pid in parents) {
      final p = relativesMap[pid];
      if (p == null) continue;
      if (p.gender == Gender.male) {
        fatherId = pid;
      } else {
        motherId = pid;
      }
    }

    final result = <Relative>[];

    for (final relative in relatives) {
      final rid = relative.id;

      // Self — mark with isSelf, keep original type
      if (rid == viewerId) {
        result.add(relative);
        continue;
      }

      RelationshipType? newType;
      FamilySide? newSide;
      final gender = relative.gender;

      // --- Direct relationships (1 hop) ---

      if (parents.contains(rid)) {
        newType = gender == Gender.female
            ? RelationshipType.mother
            : RelationshipType.father;
      } else if (siblings.contains(rid)) {
        newType = gender == Gender.female
            ? RelationshipType.sister
            : RelationshipType.brother;
      } else if (children.contains(rid)) {
        newType = gender == Gender.female
            ? RelationshipType.daughter
            : RelationshipType.son;
      } else if (spouseId == rid) {
        newType = gender == Gender.female
            ? RelationshipType.wife
            : RelationshipType.husband;
      }

      // --- 2-hop relationships ---

      if (newType == null) {
        // Grandparent (parent of parent)
        if (fatherId != null && graph.getParents(fatherId).contains(rid)) {
          newType = gender == Gender.female
              ? RelationshipType.grandmother
              : RelationshipType.grandfather;
          newSide = FamilySide.paternal;
        } else if (motherId != null &&
            graph.getParents(motherId).contains(rid)) {
          newType = gender == Gender.female
              ? RelationshipType.grandmother
              : RelationshipType.grandfather;
          newSide = FamilySide.maternal;
        }
        // Uncle/aunt (sibling of parent)
        else if (fatherId != null &&
            graph.getSiblings(fatherId).contains(rid)) {
          newType = gender == Gender.female
              ? RelationshipType.aunt
              : RelationshipType.uncle;
          newSide = FamilySide.paternal;
        } else if (motherId != null &&
            graph.getSiblings(motherId).contains(rid)) {
          newType = gender == Gender.female
              ? RelationshipType.aunt
              : RelationshipType.uncle;
          newSide = FamilySide.maternal;
        }
        // Nephew/niece (child of sibling)
        else {
          for (final sibId in siblings) {
            if (graph.getChildren(sibId).contains(rid)) {
              newType = gender == Gender.female
                  ? RelationshipType.niece
                  : RelationshipType.nephew;
              break;
            }
          }
        }
      }

      // --- 3-hop: cousins (child of parent's sibling) ---

      if (newType == null) {
        if (fatherId != null) {
          for (final uncleId in graph.getSiblings(fatherId)) {
            if (graph.getChildren(uncleId).contains(rid)) {
              newType = RelationshipType.cousin;
              newSide = FamilySide.paternal;
              break;
            }
          }
        }
        if (newType == null && motherId != null) {
          for (final auntId in graph.getSiblings(motherId)) {
            if (graph.getChildren(auntId).contains(rid)) {
              newType = RelationshipType.cousin;
              newSide = FamilySide.maternal;
              break;
            }
          }
        }
      }

      result.add(relative.copyWith(
        relationshipType: newType ?? relative.relationshipType,
        familySide: newSide ?? relative.familySide,
      ));
    }

    return result;
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
  /// Falls back to the relative's [fullName] if the graph path cannot
  /// determine a more specific label.
  static String getLabelForViewer({
    required FamilyGraph graph,
    required String viewerId,
    required String targetId,
    required Map<String, Relative> relativesMap,
  }) {
    if (viewerId == targetId) return 'أنا';

    final target = relativesMap[targetId];
    final targetGender = target?.gender;

    // Is target a parent of viewer?
    final viewerParents = graph.getParents(viewerId);
    if (viewerParents.contains(targetId)) {
      if (targetGender == Gender.male) return 'أبي';
      if (targetGender == Gender.female) return 'أمي';
      return 'والدي';
    }

    // Is target a child of viewer?
    final viewerChildren = graph.getChildren(viewerId);
    if (viewerChildren.contains(targetId)) {
      if (targetGender == Gender.male) return 'ابني';
      if (targetGender == Gender.female) return 'ابنتي';
      return 'ابني';
    }

    // Is target a sibling of viewer?
    final viewerSiblings = graph.getSiblings(viewerId);
    if (viewerSiblings.contains(targetId)) {
      if (targetGender == Gender.male) return 'أخوي';
      if (targetGender == Gender.female) return 'أختي';
      return 'أخوي';
    }

    // Is target the spouse of viewer?
    final viewerSpouse = graph.getSpouse(viewerId);
    if (viewerSpouse == targetId) {
      if (targetGender == Gender.male) return 'زوجي';
      if (targetGender == Gender.female) return 'زوجتي';
      return 'زوجي';
    }

    // Is target a parent's sibling? (uncle/aunt)
    for (final parentId in viewerParents) {
      final parentSiblings = graph.getSiblings(parentId);
      if (parentSiblings.contains(targetId)) {
        final parent = relativesMap[parentId];
        if (target != null && parent != null) {
          final parentGender = parent.gender;
          if (parentGender == Gender.male) {
            if (targetGender == Gender.male) return 'عمي';
            if (targetGender == Gender.female) return 'عمتي';
          }
          if (parentGender == Gender.female) {
            if (targetGender == Gender.male) return 'خالي';
            if (targetGender == Gender.female) return 'خالتي';
          }
        }
        if (target != null && target.familySide != null) {
          return _labelFromFamilySide(target.familySide!, target.gender);
        }
        return 'عمي';
      }
    }

    // Is target a sibling's child? (nephew/niece)
    for (final siblingId in viewerSiblings) {
      final siblingChildren = graph.getChildren(siblingId);
      if (siblingChildren.contains(targetId)) {
        final sibling = relativesMap[siblingId];
        final siblingGender = sibling?.gender;
        if (siblingGender == Gender.male) {
          return targetGender == Gender.female ? 'بنت أخوي' : 'ابن أخوي';
        }
        if (siblingGender == Gender.female) {
          return targetGender == Gender.female ? 'بنت أختي' : 'ابن أختي';
        }
        return targetGender == Gender.female ? 'بنت أخوي' : 'ابن أخوي';
      }
    }

    // Is target a grandparent? (parent's parent)
    for (final parentId in viewerParents) {
      final grandparents = graph.getParents(parentId);
      if (grandparents.contains(targetId)) {
        if (targetGender == Gender.male) return 'جدي';
        if (targetGender == Gender.female) return 'جدتي';
        return 'جدي';
      }
    }

    // Is target a grandchild? (child's child)
    for (final childId in viewerChildren) {
      final grandchildren = graph.getChildren(childId);
      if (grandchildren.contains(targetId)) {
        if (targetGender == Gender.male) return 'حفيدي';
        if (targetGender == Gender.female) return 'حفيدتي';
        return 'حفيدي';
      }
    }

    // Is target a cousin? parent→sibling→child (4-way distinction)
    for (final parentId in viewerParents) {
      final parent = relativesMap[parentId];
      final parentGender = parent?.gender;

      for (final parentSibId in graph.getSiblings(parentId)) {
        final parentSib = relativesMap[parentSibId];
        final parentSibGender = parentSib?.gender;

        final cousinCandidates = graph.getChildren(parentSibId);
        if (cousinCandidates.contains(targetId)) {
          if (parentGender == Gender.male && parentSibGender == Gender.male) {
            return targetGender == Gender.female ? 'بنت عمي' : 'ابن عمي';
          }
          if (parentGender == Gender.male && parentSibGender == Gender.female) {
            return targetGender == Gender.female ? 'بنت عمتي' : 'ابن عمتي';
          }
          if (parentGender == Gender.female && parentSibGender == Gender.male) {
            return targetGender == Gender.female ? 'بنت خالي' : 'ابن خالي';
          }
          if (parentGender == Gender.female && parentSibGender == Gender.female) {
            return targetGender == Gender.female ? 'بنت خالتي' : 'ابن خالتي';
          }
          return targetGender == Gender.female ? 'بنت عمي' : 'ابن عمي';
        }
      }
    }

    // Is target a great-grandparent? (parent→parent→parent)
    for (final parentId in viewerParents) {
      for (final grandparentId in graph.getParents(parentId)) {
        final greatGrandparents = graph.getParents(grandparentId);
        if (greatGrandparents.contains(targetId)) {
          if (targetGender == Gender.male) return 'جدي الأكبر';
          if (targetGender == Gender.female) return 'جدتي الكبرى';
          return 'جدي الأكبر';
        }
      }
    }

    // Fallback: use person's full name (not arabicName which is generic)
    return target?.fullName ?? 'قريب';
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
