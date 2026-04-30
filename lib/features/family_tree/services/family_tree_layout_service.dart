import 'dart:math';
import 'dart:ui';

import '../../../shared/models/relative_model.dart';
import '../../../shared/utils/relationship_label_helper.dart';
import '../models/family_graph.dart';
import '../models/placeholder_node.dart';
import '../models/tree_layout.dart';
import 'family_graph_service.dart';
import 'placeholder_spawn_service.dart';

/// Pure static service for computing family tree layout positions.
///
/// Uses a **spine-based** algorithm:
/// 1. The direct lineage (grandparents → parents → user → children) forms
///    a centered vertical spine.
/// 2. Side branches (aunts, uncles, cousins) are positioned as compact
///    2D grids extending outward: dad's side goes left, mom's side right.
/// 3. Descendants of side-branch nodes are placed below their parents.
///
/// This produces a natural tree shape with directional branching instead
/// of flat horizontal rows.
class FamilyTreeLayoutService {
  FamilyTreeLayoutService._();

  // Single-entry memoization cache for computeLayout. The function is
  // O(N²) in the worst case (per the Phase 7 perf audit) and gets called
  // on every LayoutBuilder constraint tick — most of which are no-op
  // changes. We hold the most recent input fingerprint + output. If the
  // next call's fingerprint matches, we skip the work.
  //
  // Cache size is intentionally 1: this fix targets the LayoutBuilder
  // re-fire pattern, not multi-viewer scenarios. A larger cache would
  // pay memory + invalidation complexity for marginal wins.
  static String? _cachedKey;
  static FamilyTreeLayout? _cachedLayout;

  /// Build a stable fingerprint from every input that could change the
  /// layout output. Order matters — the buffer is concatenated and the
  /// final string is the cache key.
  static String _layoutCacheKey({
    required String userId,
    required String userName,
    required FamilyGraph? graph,
    required List<Relative> relatives,
    required Size canvasSize,
    Gender? userGender,
    Set<String> linkedMemberNodeIds = const {},
    double nodeRadius = 30.0,
    double horizontalSpacing = 105.0,
    double verticalSpacing = 140.0,
  }) {
    final buf = StringBuffer()
      ..write(userId)
      ..write('|')
      ..write(userName)
      ..write('|')
      ..write(canvasSize.width.toStringAsFixed(1))
      ..write('x')
      ..write(canvasSize.height.toStringAsFixed(1))
      ..write('|')
      ..write(userGender?.name ?? 'null')
      ..write('|')
      ..write(nodeRadius)
      ..write(',')
      ..write(horizontalSpacing)
      ..write(',')
      ..write(verticalSpacing)
      ..write('|');

    // Graph fingerprint: edge count + structural hash. Edges are
    // deterministically ordered by id, so the hash is stable for the
    // same graph regardless of fetch order.
    if (graph == null) {
      buf.write('g:null');
    } else {
      buf.write('g:');
      buf.write(graph.userId);
      buf.write(':');
      buf.write(graph.edges.length);
      buf.write(':');
      // Combine edge identifiers — edge id alone is sufficient because
      // FamilyEdge fields are all final and edges are immutable.
      final edgeIds = graph.edges.map((e) => e.id).toList()..sort();
      buf.write(Object.hashAll(edgeIds));
    }
    buf.write('|');

    // Linked-member node ids (sorted for stability).
    final linked = linkedMemberNodeIds.toList()..sort();
    buf.write('lm:');
    buf.write(linked.join(','));
    buf.write('|');

    // Relatives fingerprint — id + the fields the layout reads.
    // (full_name is not used by layout, so we skip it.)
    buf.write('r:');
    buf.write(relatives.length);
    buf.write(':');
    final relIds = <String>[];
    for (final r in relatives) {
      relIds.add(
        '${r.id}:'
        '${r.relationshipType.value}:'
        '${r.gender?.name ?? "null"}:'
        '${r.familySide?.name ?? "null"}:'
        '${r.relativeCategory.name}:'
        '${r.familyGroupId ?? "null"}:'
        '${r.isArchived ? 1 : 0}:'
        '${r.isSelf ? 1 : 0}',
      );
    }
    relIds.sort();
    buf.write(Object.hashAll(relIds));

    return buf.toString();
  }

  /// Compute the complete layout for the family tree canvas.
  ///
  /// If [graph] is null (no persisted edges), infers edges from each
  /// relative's [RelationshipType] to build a temporary graph.
  static FamilyTreeLayout computeLayout({
    required String userId,
    required String userName,
    required FamilyGraph? graph,
    required List<Relative> relatives,
    required Map<String, Relative> relativesMap,
    required Size canvasSize,
    Gender? userGender,
    Set<String> linkedMemberNodeIds = const {},
    double nodeRadius = 30.0,
    double horizontalSpacing = 105.0,
    double verticalSpacing = 140.0,
  }) {
    // Memoization fast-path. See _layoutCacheKey + _cachedLayout above.
    final cacheKey = _layoutCacheKey(
      userId: userId,
      userName: userName,
      graph: graph,
      relatives: relatives,
      canvasSize: canvasSize,
      userGender: userGender,
      linkedMemberNodeIds: linkedMemberNodeIds,
      nodeRadius: nodeRadius,
      horizontalSpacing: horizontalSpacing,
      verticalSpacing: verticalSpacing,
    );
    if (_cachedKey == cacheKey && _cachedLayout != null) {
      return _cachedLayout!;
    }
    // ── 1. Build graph ──
    // For shared trees (graph provided and contains the user), use the
    // persisted edges which are correct for multi-perspective viewing.
    // For personal trees (no graph or user not in graph), infer from
    // RelationshipType metadata for backwards compatibility.
    final isSharedTree = graph != null && graph.containsNode(userId);
    FamilyGraph effectiveGraph;
    if (isSharedTree) {
      // Shared tree: use persisted edges
      effectiveGraph = graph;
    } else {
      // Personal tree: infer from metadata
      effectiveGraph = _inferGraph(userId, relatives);
    }
    effectiveGraph = _enrichSiblingEdges(effectiveGraph, userId);

    // ── 2. Compute generation for each person ──
    final generations = <String, int>{};
    generations[userId] = 0;
    for (final relative in relatives) {
      if (!relative.isArchived) {
        generations[relative.id] = effectiveGraph.containsNode(relative.id)
            ? effectiveGraph.getGeneration(relative.id)
            : _generationFromType(relative.relationshipType);
      }
    }

    // ── 3. Identify spine ──
    // The spine is the central trunk: user, their spouse, their
    // direct ancestors/descendants, and siblings (via shared parent).
    final spine = <String>{userId};

    final userSpouse = effectiveGraph.getSpouse(userId);
    if (userSpouse != null && generations.containsKey(userSpouse)) {
      spine.add(userSpouse);
    }

    // Walk up: ancestors
    void addAncestors(String id) {
      for (final p in effectiveGraph.getParents(id)) {
        if (generations.containsKey(p) && spine.add(p)) {
          addAncestors(p);
        }
      }
    }

    addAncestors(userId);

    // Walk down: descendants
    void addDescendants(String id) {
      for (final c in effectiveGraph.getChildren(id)) {
        if (generations.containsKey(c) && spine.add(c)) {
          addDescendants(c);
        }
      }
    }

    addDescendants(userId);

    // ── 3b. Compute family sides for direction ──
    // Paternal side → LEFT, maternal side → RIGHT.
    // BFS from each parent through siblings and ancestors (not children,
    // to avoid crossing over through the user to the other side).
    final familySide = <String, _FamilySide>{};
    final userParents = effectiveGraph.getParents(userId);
    for (final pid in userParents) {
      final rel = relativesMap[pid];
      final isMale = rel?.gender == Gender.male;
      final side = isMale ? _FamilySide.paternal : _FamilySide.maternal;
      _traceFamilySide(
        startId: pid,
        excludeId: userId,
        graph: effectiveGraph,
        generations: generations,
        side: side,
        result: familySide,
      );
    }

    // Propagate family side through spouse edges so uncle's spouse
    // gets the same side as the uncle, without BFS crossing lineages.
    for (final nodeId in familySide.keys.toList()) {
      final spouseId = effectiveGraph.getSpouse(nodeId);
      if (spouseId != null &&
          generations.containsKey(spouseId) &&
          !familySide.containsKey(spouseId)) {
        familySide[spouseId] = familySide[nodeId]!;
      }
    }

    // Fill familySide for disconnected relatives (no graph edges) using
    // the stored familySide on the relative model.
    for (final r in relatives) {
      if (familySide.containsKey(r.id)) continue;
      if (r.familySide == FamilySide.paternal) {
        familySide[r.id] = _FamilySide.paternal;
      } else if (r.familySide == FamilySide.maternal) {
        familySide[r.id] = _FamilySide.maternal;
      }
    }

    // ── 4. Position spine ──
    final centerX = canvasSize.width / 2;
    final userGenY = canvasSize.height / 2;
    final positions = <String, Offset>{};

    final spineByGen = <int, List<String>>{};
    for (final id in spine) {
      final gen = generations[id] ?? 0;
      spineByGen.putIfAbsent(gen, () => []).add(id);
    }

    final sortedSpineGens = spineByGen.keys.toList()..sort();

    for (final gen in sortedSpineGens) {
      final group = spineByGen[gen]!;
      _orderWithinGeneration(group, effectiveGraph, userId, relativesMap);
      final y = userGenY + gen * verticalSpacing;
      final totalW = (group.length - 1) * horizontalSpacing;
      final startX = centerX - totalW / 2;
      for (int i = 0; i < group.length; i++) {
        positions[group[i]] = Offset(startX + i * horizontalSpacing, y);
      }
    }

    // Bottom-up: center spine parents over their positioned children.
    for (int gi = sortedSpineGens.length - 2; gi >= 0; gi--) {
      final gen = sortedSpineGens[gi];
      final group = spineByGen[gen]!;
      final handled = <String>{};

      for (final nodeId in group) {
        if (handled.contains(nodeId)) continue;

        final spouseId = effectiveGraph.getSpouse(nodeId);
        final isCouple = spouseId != null &&
            group.contains(spouseId) &&
            !handled.contains(spouseId);

        final childIds = <String>{};
        childIds.addAll(
          effectiveGraph
              .getChildren(nodeId)
              .where((c) => positions.containsKey(c)),
        );
        if (isCouple) {
          childIds.addAll(
            effectiveGraph
                .getChildren(spouseId)
                .where((c) => positions.containsKey(c)),
          );
        }

        if (childIds.isEmpty) continue;

        double sum = 0;
        for (final c in childIds) {
          sum += positions[c]!.dx;
        }
        final childCenter = sum / childIds.length;

        if (isCouple) {
          final gap = horizontalSpacing * 0.5;
          final posA = positions[nodeId]!;
          final posB = positions[spouseId]!;
          final leftId = posA.dx <= posB.dx ? nodeId : spouseId;
          final rightId = leftId == nodeId ? spouseId : nodeId;
          positions[leftId] =
              Offset(childCenter - gap / 2, positions[leftId]!.dy);
          positions[rightId] =
              Offset(childCenter + gap / 2, positions[rightId]!.dy);
          handled.add(nodeId);
          handled.add(spouseId);
        } else {
          positions[nodeId] = Offset(childCenter, positions[nodeId]!.dy);
          handled.add(nodeId);
        }
      }

      _resolveOverlaps(group, positions, horizontalSpacing * 0.95);
    }

    // ── 4b. Position user's siblings adjacent to user+spouse cluster ──
    // User and spouse are already placed by the spine algorithm — do NOT
    // move them. Place siblings to the right of the user+spouse cluster.
    // This keeps the parent node directly above the user after step 8's
    // centering shift instead of being pushed to one side.
    final userSiblingIds = <String>{};
    for (final parentId in effectiveGraph.getParents(userId)) {
      for (final child in effectiveGraph.getChildren(parentId)) {
        if (child != userId && generations.containsKey(child)) {
          userSiblingIds.add(child);
        }
      }
    }
    for (final sib in effectiveGraph.getSiblings(userId)) {
      if (generations.containsKey(sib)) userSiblingIds.add(sib);
    }
    userSiblingIds.removeWhere((id) => positions.containsKey(id));

    if (userSiblingIds.isNotEmpty) {
      final hasSpouseOnSpine =
          userSpouse != null && spine.contains(userSpouse);
      final sibs = userSiblingIds.toList();
      _orderSideBranchNodes(sibs, effectiveGraph, relativesMap, goRight: true);

      final tightH = horizontalSpacing * 0.95;
      final tightV = verticalSpacing * 0.85;

      // Find the rightmost edge of the user+spouse cluster.
      // When no spouse is present yet, skip a slot for the spouse placeholder
      // so siblings don't overlap with where the placeholder will appear.
      double clusterRightX = positions[userId]!.dx;
      if (hasSpouseOnSpine && positions.containsKey(userSpouse)) {
        clusterRightX = max(clusterRightX, positions[userSpouse]!.dx);
      } else {
        clusterRightX += tightH; // leave gap for spouse placeholder
      }

      _positionAsGrid(
        nodeIds: sibs,
        anchor: Offset(clusterRightX + tightH, userGenY),
        goRight: true,
        colSpacing: tightH,
        rowSpacing: tightV,
        maxCols: 3,
        positions: positions,
      );
    }

    // ── 5. Position side branches as 2D grids ──
    // Process each generation: find non-spine nodes, group them by
    // their nearest positioned relative, and lay each group out as a
    // compact grid extending away from the center.
    final allGens = generations.values.toSet().toList()..sort();

    for (final gen in allGens) {
      final sideNodes = <String>[];
      for (final r in relatives) {
        if (r.isArchived) continue;
        // Skip the user's own self-node — the spine slot at `userId`
        // already represents them. Without this, the self-row's
        // relative.id (different from auth userId) doesn't match
        // anything in `positions` and gets re-placed as an unanchored
        // orphan on the right side.
        if (r.isSelf) continue;
        if (generations[r.id] != gen) continue;
        if (positions.containsKey(r.id)) continue;
        sideNodes.add(r.id);
      }
      if (sideNodes.isEmpty) continue;

      // Group by anchor (nearest positioned sibling or parent).
      final anchorGroups = <String, List<String>>{};
      final unanchored = <String>[];

      for (final nodeId in sideNodes) {
        String? anchor;
        // Prefer sibling anchor (same generation).
        for (final sib in effectiveGraph.getSiblings(nodeId)) {
          if (positions.containsKey(sib)) {
            anchor = sib;
            break;
          }
        }
        // Fall back to parent anchor.
        if (anchor == null) {
          for (final p in effectiveGraph.getParents(nodeId)) {
            if (positions.containsKey(p)) {
              anchor = p;
              break;
            }
          }
        }
        // Also try spouse as anchor.
        if (anchor == null) {
          final spouseId = effectiveGraph.getSpouse(nodeId);
          if (spouseId != null && positions.containsKey(spouseId)) {
            anchor = spouseId;
          }
        }

        if (anchor != null) {
          anchorGroups.putIfAbsent(anchor, () => []).add(nodeId);
        } else {
          unanchored.add(nodeId);
        }
      }

      // Pull unanchored spouses into their partner's anchor group.
      final unanchoredSet = unanchored.toSet();
      for (final entry in anchorGroups.entries) {
        final spousesToAdd = <String>[];
        for (final nodeId in entry.value) {
          final spouseId = effectiveGraph.getSpouse(nodeId);
          if (spouseId != null && unanchoredSet.contains(spouseId)) {
            spousesToAdd.add(spouseId);
            unanchoredSet.remove(spouseId);
          }
        }
        entry.value.addAll(spousesToAdd);
      }
      unanchored
        ..clear()
        ..addAll(unanchoredSet);

      final genY = userGenY + gen * verticalSpacing;

      for (final entry in anchorGroups.entries) {
        final anchorId = entry.key;
        final nodes = entry.value;
        final anchorPos = positions[anchorId]!;

        // Direction from family side, not position.
        // Paternal (dad's side) extends LEFT, maternal (mom's side) RIGHT.
        final anchorSide = familySide[anchorId];
        final goRight = anchorSide == _FamilySide.paternal
            ? false
            : anchorSide == _FamilySide.maternal
                ? true
                : anchorPos.dx >= centerX; // fallback

        // Find the furthest positioned node on this side near genY
        // so we don't overlap with already-placed nodes.
        double edgeX = anchorPos.dx;
        for (final pos in positions.values) {
          if ((pos.dy - genY).abs() < verticalSpacing * 0.4) {
            if (goRight && pos.dx > edgeX) edgeX = pos.dx;
            if (!goRight && pos.dx < edgeX) edgeX = pos.dx;
          }
        }

        final gridX = goRight
            ? edgeX + horizontalSpacing
            : edgeX - horizontalSpacing;

        _orderSideBranchNodes(nodes, effectiveGraph, relativesMap, goRight: goRight);
        _positionAsGrid(
          nodeIds: nodes,
          anchor: Offset(gridX, genY),
          goRight: goRight,
          colSpacing: horizontalSpacing * 0.95,
          rowSpacing: verticalSpacing * 0.85,
          maxCols: 3,
          positions: positions,
        );

        // Propagate family side to newly positioned nodes.
        if (anchorSide != null) {
          for (final nodeId in nodes) {
            familySide[nodeId] = anchorSide;
          }
        }
      }

      // Fallback for unanchored nodes — use family side for direction.
      final rightUnanchored = <String>[];
      final leftUnanchored = <String>[];
      for (final nodeId in unanchored) {
        final side = familySide[nodeId];
        if (side == _FamilySide.maternal) {
          leftUnanchored.add(nodeId);
        } else {
          rightUnanchored.add(nodeId);
        }
      }
      double fallbackRightX = centerX + 250;
      for (final nodeId in rightUnanchored) {
        positions[nodeId] = Offset(fallbackRightX, genY);
        fallbackRightX += horizontalSpacing * 0.5;
      }
      double fallbackLeftX = centerX - 250;
      for (final nodeId in leftUnanchored) {
        positions[nodeId] = Offset(fallbackLeftX, genY);
        fallbackLeftX -= horizontalSpacing * 0.5;
      }
    }

    // ── 6. Position descendants of side-branch nodes ──
    // For each positioned non-spine node, place their unpositioned
    // children at the correct generation Y, aligned below the parent.
    for (final gen in allGens) {
      for (final r in relatives) {
        if (r.isArchived) continue;
        if (generations[r.id] != gen) continue;
        if (!positions.containsKey(r.id)) continue;
        if (spine.contains(r.id)) continue;

        final children = effectiveGraph
            .getChildren(r.id)
            .where(
                (c) => generations.containsKey(c) && !positions.containsKey(c))
            .toList();
        if (children.isEmpty) continue;

        final parentPos = positions[r.id]!;
        final parentSide = familySide[r.id];
        final goRight = parentSide == _FamilySide.paternal
            ? false
            : parentSide == _FamilySide.maternal
                ? true
                : parentPos.dx >= centerX;
        final childGen = generations[children.first] ?? 0;
        final childY = userGenY + childGen * verticalSpacing;

        _orderSideBranchNodes(children, effectiveGraph, relativesMap, goRight: goRight);
        _positionAsGrid(
          nodeIds: children,
          anchor: Offset(parentPos.dx, childY),
          goRight: goRight,
          colSpacing: horizontalSpacing * 0.9,
          rowSpacing: verticalSpacing * 0.85,
          maxCols: 3,
          positions: positions,
        );

        // Propagate family side to children.
        if (parentSide != null) {
          for (final c in children) {
            familySide[c] = parentSide;
          }
        }
      }
    }

    // ── 7. Remaining unpositioned nodes ──
    for (final r in relatives) {
      if (r.isArchived) continue;
      // Skip the self-row — same reason as section 5: positions is keyed
      // by auth userId but the self-row carries its own relative.id, so
      // this catchall would otherwise re-place the user as a phantom
      // node at centerX + 250.
      if (r.isSelf) continue;
      if (positions.containsKey(r.id)) continue;
      final gen = generations[r.id] ?? 0;
      positions[r.id] = Offset(centerX + 250, userGenY + gen * verticalSpacing);
    }

    // ── 8. Center tree so user is at canvas center ──
    final userPos = positions[userId];
    if (userPos != null) {
      final shiftX = centerX - userPos.dx;
      if (shiftX.abs() > 0.5) {
        for (final id in positions.keys.toList()) {
          final old = positions[id]!;
          positions[id] = Offset(old.dx + shiftX, old.dy);
        }
      }
    }

    // ── 8b. Organic jitter ──
    // Apply small deterministic offsets to break the rigid grid alignment
    // and give the tree a natural, organic feel. Uses hashCode for
    // consistency across rebuilds.
    for (final id in positions.keys.toList()) {
      if (id == userId) continue; // keep user precisely centered
      final hash = id.hashCode;
      final jitterX = ((hash % 11) - 5) * 1.2; // ±6px
      final jitterY = ((hash % 7) - 3) * 1.0; // ±3px
      final old = positions[id]!;
      positions[id] = Offset(old.dx + jitterX, old.dy + jitterY);
    }

    // ── 8c. Global overlap resolution (runs AFTER jitter) ──
    // Check every pair of nodes for bounding-box overlap and push them
    // apart iteratively. Runs after jitter so jitter-introduced overlaps
    // are also resolved.
    _resolveGlobalOverlaps(positions, userId, 80.0, 100.0, 14.0);

    // ── 9. Build LayoutNodes ──
    final nodes = <LayoutNode>[];

    // Ensure the user's position exists — defensive fallback
    if (!positions.containsKey(userId)) {
      positions[userId] = Offset(centerX, userGenY);
    }

    // User node (viewer is always a linked member in shared trees)
    nodes.add(LayoutNode(
      id: userId,
      position: positions[userId]!,
      emoji: '\u{1F464}', // 👤
      name: userName,
      label: '\u0623\u0646\u0627', // أنا
      generation: 0,
      isUser: true,
      isLinkedMember: linkedMemberNodeIds.contains(userId),
      healthRatio: 1.0,
      streakDays: 0,
      radius: nodeRadius,
    ));

    // Relative nodes
    for (final relative in relatives) {
      if (relative.isArchived) continue;
      if (relative.id == userId) continue; // Skip viewer's own node (already added above)
      final pos = positions[relative.id];
      if (pos == null) continue;

      final graphLabel = FamilyGraphService.getLabelForViewer(
        graph: effectiveGraph,
        viewerId: userId,
        targetId: relative.id,
        relativesMap: relativesMap,
      );
      final label = graphLabel.isNotEmpty
          ? graphLabel
          : getSideAwareLabel(relative.relationshipType, relative.familySide, relative.gender);

      nodes.add(LayoutNode(
        id: relative.id,
        position: pos,
        emoji: relative.displayEmoji,
        name: relative.fullName,
        label: label,
        generation: generations[relative.id] ?? 0,
        isUser: false,
        isLinkedMember: linkedMemberNodeIds.contains(relative.id),
        healthRatio: _computeHealthRatio(relative),
        streakDays: 0,
        radius: nodeRadius,
      ));
    }

    // ── 10. Build junction bars for parent-sibling groups ──
    // For each of the user's parents, group their siblings (uncles/aunts)
    // into a junction bar. This replaces direct siblingOf edge rendering
    // with: parent → junction bar → siblings.
    final junctions = <LayoutJunction>[];
    final junctionSiblingIds = <String>{}; // track which sibling edges to skip

    for (final parentId in effectiveGraph.getParents(userId)) {
      final parentPos = positions[parentId];
      if (parentPos == null) continue;

      final parentSiblings = effectiveGraph
          .getSiblings(parentId)
          .where((id) => positions.containsKey(id))
          .toList();
      if (parentSiblings.isEmpty) continue;

      // Determine label based on family side.
      final side = familySide[parentId];
      final label = side == _FamilySide.maternal ? 'أخوال' : 'أعمام';

      // Find nearest sibling X to determine direction and gap.
      double nearestSibX = positions[parentSiblings.first]!.dx;
      for (final sibId in parentSiblings) {
        final sx = positions[sibId]!.dx;
        if ((sx - parentPos.dx).abs() < (nearestSibX - parentPos.dx).abs()) {
          nearestSibX = sx;
        }
      }

      // Junction INLINE at same Y as parent, in the gap between parent
      // and nearest uncle.
      final junctionX = (parentPos.dx + nearestSibX) / 2;
      final junctionY = parentPos.dy; // same Y as parent row

      junctions.add(LayoutJunction(
        id: 'junction-$parentId',
        position: Offset(junctionX, junctionY),
        label: label,
        anchorId: parentId,
        siblingIds: parentSiblings,
      ));

      // Track these sibling IDs so their siblingOf edges are skipped.
      for (final sibId in parentSiblings) {
        junctionSiblingIds.add(sibId);
      }
    }

    // ── 11. Build LayoutEdges ──
    // Skip siblingOf edges entirely — siblings are connected through
    // parent→child branches or junction bars.
    final edges = <LayoutEdge>[];
    for (final edge in effectiveGraph.edges) {
      // Skip all siblingOf edges — they're either:
      // 1. User↔sibling: already connected through shared parent branches
      // 2. Parent↔uncle/aunt: replaced by junction bars
      if (edge.type == EdgeType.siblingOf) continue;

      final fromPos = positions[edge.fromId];
      final toPos = positions[edge.toId];
      if (fromPos == null || toPos == null) continue;

      final fromHealthy = _isNodeHealthy(edge.fromId, userId, relativesMap);
      final toHealthy = _isNodeHealthy(edge.toId, userId, relativesMap);

      edges.add(LayoutEdge(
        fromId: edge.fromId,
        toId: edge.toId,
        from: fromPos,
        to: toPos,
        type: edge.type,
        isHealthy: fromHealthy && toHealthy,
      ));
    }

    // Add synthetic parentOf edges from spouse so child lines originate
    // from the couple midpoint (the "+" connector) rather than one parent.
    final syntheticEdges = <LayoutEdge>[];
    for (final edge in edges) {
      if (edge.type != EdgeType.parentOf) continue;
      final spouseId = effectiveGraph.getSpouse(edge.fromId);
      if (spouseId == null) continue;
      final spousePos = positions[spouseId];
      if (spousePos == null) continue;
      final alreadyExists = edges.any((e) =>
          e.type == EdgeType.parentOf &&
          e.fromId == spouseId &&
          e.toId == edge.toId);
      if (alreadyExists) continue;
      syntheticEdges.add(LayoutEdge(
        fromId: spouseId,
        toId: edge.toId,
        from: spousePos,
        to: edge.to,
        type: EdgeType.parentOf,
        isHealthy: edge.isHealthy,
      ));
    }
    edges.addAll(syntheticEdges);

    // ── 12. Generate and position placeholders ──
    final rawPlaceholders = PlaceholderSpawnService.computePlaceholders(
      relatives: relatives,
      userGender: userGender,
      isSharedTree: isSharedTree,
    );

    final positionedPlaceholders = _positionPlaceholders(
      rawPlaceholders: rawPlaceholders,
      nodePositions: positions,
      userId: userId,
      horizontalSpacing: horizontalSpacing,
      verticalSpacing: verticalSpacing,
      centerX: centerX,
      userGenY: userGenY,
    );

    // ── 13. Compute bounds (including placeholders) ──
    final allPositions = [
      ...positions.values,
      ...positionedPlaceholders.map((p) => p.position),
    ];
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;
    for (final p in allPositions) {
      minX = min(minX, p.dx);
      maxX = max(maxX, p.dx);
      minY = min(minY, p.dy);
      maxY = max(maxY, p.dy);
    }
    final padding = nodeRadius * 3;
    final bounds = Rect.fromLTRB(
      minX - padding,
      minY - padding,
      maxX + padding,
      maxY + padding,
    );

    final layout = FamilyTreeLayout(
      nodes: nodes,
      edges: edges,
      junctions: junctions,
      placeholders: positionedPlaceholders,
      bounds: bounds,
      userPosition: positions[userId] ?? Offset(centerX, 0),
    );

    // Memoize for the next LayoutBuilder tick. cacheKey was computed at
    // function entry from the same inputs.
    _cachedKey = cacheKey;
    _cachedLayout = layout;
    return layout;
  }

  // ---------------------------------------------------------------------------
  // Placeholder positioning
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // Overlap guardian — node dimensions for collision detection
  // ---------------------------------------------------------------------------

  /// Minimum horizontal clearance between any two node centers.
  /// Based on max(TreeNodeWidget.nodeWidth=80, PlaceholderNodeWidget.nodeSize=70).
  static const _minHClearance = 85.0;

  /// Minimum vertical clearance between any two node centers.
  static const _minVClearance = 75.0;

  /// Assign canvas positions to raw placeholders based on their type, side,
  /// and parent node positions.
  static List<PlaceholderNode> _positionPlaceholders({
    required List<PlaceholderNode> rawPlaceholders,
    required Map<String, Offset> nodePositions,
    required String userId,
    required double horizontalSpacing,
    required double verticalSpacing,
    required double centerX,
    required double userGenY,
  }) {
    final userPos = nodePositions[userId] ?? Offset(centerX, userGenY);
    final positioned = <PlaceholderNode>[];
    // Track all occupied positions (real nodes + already-placed placeholders)
    final occupied = <Offset>{...nodePositions.values};

    for (final ph in rawPlaceholders) {
      final genY = userGenY + ph.generation * verticalSpacing;
      Offset pos;
      // Default nudge direction: away from center on the placeholder's side.
      double nudgeDir = 1.0; // +1 = right, -1 = left

      switch (ph.type) {
        // ── Parents ──
        // Convention: male LEFT, female RIGHT.
        case RelationshipType.father:
          pos = Offset(userPos.dx - horizontalSpacing * 0.55, genY);
          nudgeDir = -1.0;
        case RelationshipType.mother:
          pos = Offset(userPos.dx + horizontalSpacing * 0.55, genY);
          nudgeDir = 1.0;

        // ── Grandparents ──
        // Both grandparents extend in their SIDE direction from the parent
        // node, so paternal grandparents stay LEFT and maternal stay RIGHT.
        // Grandfather (closer to parent), grandmother (farther out).
        case RelationshipType.grandfather:
        case RelationshipType.grandmother:
          final isGrandfather = ph.type == RelationshipType.grandfather;
          final isPat = ph.side == FamilySide.paternal;
          final sideDir = isPat ? -1.0 : 1.0;
          nudgeDir = sideDir;
          if (ph.parentNodeId != null &&
              nodePositions.containsKey(ph.parentNodeId)) {
            final parentPos = nodePositions[ph.parentNodeId]!;
            // Grandfather closer to parent, grandmother farther out
            final slot = isGrandfather ? 0.3 : 0.9;
            pos = Offset(parentPos.dx + sideDir * horizontalSpacing * slot, genY);
          } else {
            // Parent is also a placeholder — estimate from side
            final baseX = isPat
                ? userPos.dx - horizontalSpacing * 0.55
                : userPos.dx + horizontalSpacing * 0.55;
            final slot = isGrandfather ? 0.3 : 0.9;
            pos = Offset(baseX + sideDir * horizontalSpacing * slot, genY);
          }

        // ── Uncle / Aunt ──
        case RelationshipType.uncle:
        case RelationshipType.aunt:
          final isPat = ph.side == FamilySide.paternal;
          nudgeDir = isPat ? -1.0 : 1.0;
          if (ph.parentNodeId != null &&
              nodePositions.containsKey(ph.parentNodeId)) {
            final parentPos = nodePositions[ph.parentNodeId]!;
            // Paternal extends LEFT (-1), maternal extends RIGHT (+1)
            final direction = isPat ? -1.0 : 1.0;
            // Count existing nodes on this side at this generation
            int sideCount = 0;
            for (final p in occupied) {
              if ((p.dy - genY).abs() < verticalSpacing * 0.3) {
                if (isPat && p.dx < parentPos.dx - 10) sideCount++;
                if (!isPat && p.dx > parentPos.dx + 10) sideCount++;
              }
            }
            pos = Offset(
              parentPos.dx +
                  direction * horizontalSpacing * (1.0 + sideCount * 0.85),
              genY,
            );
          } else {
            final baseX = isPat
                ? userPos.dx - horizontalSpacing * 0.55
                : userPos.dx + horizontalSpacing * 0.55;
            final direction = isPat ? -1.0 : 1.0;
            pos = Offset(baseX + direction * horizontalSpacing, genY);
          }

        // ── Cousin ──
        case RelationshipType.cousin:
          final isPat = ph.side == FamilySide.paternal;
          nudgeDir = isPat ? -1.0 : 1.0;
          if (ph.parentNodeId != null &&
              nodePositions.containsKey(ph.parentNodeId)) {
            pos = Offset(nodePositions[ph.parentNodeId]!.dx, genY);
          } else {
            pos = Offset(
              userPos.dx + (isPat ? -horizontalSpacing * 2 : horizontalSpacing * 2),
              genY,
            );
          }

        // ── Spouse ──
        // Convention: male LEFT, female RIGHT (wife RIGHT of user).
        // Offset matches the grid slot reserved in step 4b (tightH).
        case RelationshipType.wife:
          pos = Offset(userPos.dx + horizontalSpacing * 0.95, genY);
          nudgeDir = 1.0;
        case RelationshipType.husband:
          pos = Offset(userPos.dx - horizontalSpacing * 0.95, genY);
          nudgeDir = -1.0;

        // ── Siblings ──
        // Same direction as spouse (RIGHT) so order is ME > SPOUSE > SIBS.
        case RelationshipType.brother:
        case RelationshipType.sister:
          nudgeDir = 1.0;
          pos = Offset(userPos.dx + horizontalSpacing * 0.9, genY);

        // ── Children ──
        case RelationshipType.son:
        case RelationshipType.daughter:
          pos = Offset(userPos.dx, genY);
          nudgeDir = 1.0;

        // ── Fallback ──
        default:
          pos = Offset(centerX, genY);
      }

      pos = _resolveOverlap(pos, occupied, nudgeDir);
      occupied.add(pos);
      positioned.add(ph.copyWithPosition(pos));
    }

    return positioned;
  }

  /// Smart overlap guardian — checks bounding-box overlap using actual node
  /// dimensions and nudges in [preferredDir] (-1 = left, +1 = right).
  static Offset _resolveOverlap(
    Offset pos,
    Set<Offset> occupied,
    double preferredDir,
  ) {
    for (int attempt = 0; attempt < 12; attempt++) {
      bool overlaps = false;
      for (final other in occupied) {
        final dx = (pos.dx - other.dx).abs();
        final dy = (pos.dy - other.dy).abs();
        // Bounding-box collision: both horizontal AND vertical overlap
        if (dx < _minHClearance && dy < _minVClearance) {
          overlaps = true;
          break;
        }
      }
      if (!overlaps) return pos;
      // Nudge in the preferred direction
      pos = Offset(pos.dx + preferredDir * _minHClearance * 0.6, pos.dy);
    }
    return pos;
  }

  // ---------------------------------------------------------------------------
  // Layout helpers
  // ---------------------------------------------------------------------------

  /// Position [nodeIds] in a compact 2D grid.
  ///
  /// When [goRight] is true columns extend rightward from [anchor];
  /// when false they extend leftward. Rows always extend downward.
  static void _positionAsGrid({
    required List<String> nodeIds,
    required Offset anchor,
    required bool goRight,
    required double colSpacing,
    required double rowSpacing,
    required int maxCols,
    required Map<String, Offset> positions,
  }) {
    if (nodeIds.isEmpty) return;
    final cols = min(nodeIds.length, maxCols);

    for (int i = 0; i < nodeIds.length; i++) {
      final row = i ~/ cols;
      final col = i % cols;

      final x = goRight
          ? anchor.dx + col * colSpacing
          : anchor.dx - col * colSpacing;
      final y = anchor.dy + row * rowSpacing;

      positions[nodeIds[i]] = Offset(x, y);
    }
  }

  /// Push apart any overlapping nodes in a generation.
  ///
  /// Walks left-to-right and ensures every pair of adjacent nodes has at
  /// least [minSpacing] between their centres.
  static void _resolveOverlaps(
    List<String> group,
    Map<String, Offset> positions,
    double minSpacing,
  ) {
    final sorted = group
        .where((id) => positions.containsKey(id))
        .toList()
      ..sort((a, b) => positions[a]!.dx.compareTo(positions[b]!.dx));

    for (int i = 1; i < sorted.length; i++) {
      final prevX = positions[sorted[i - 1]]!.dx;
      final currX = positions[sorted[i]]!.dx;
      if (currX - prevX < minSpacing) {
        final shift = minSpacing - (currX - prevX);
        for (int j = i; j < sorted.length; j++) {
          final old = positions[sorted[j]]!;
          positions[sorted[j]] = Offset(old.dx + shift, old.dy);
        }
      }
    }
  }

  /// Global overlap resolution: checks every pair of positioned nodes and
  /// pushes overlapping bounding boxes apart. Runs iteratively until
  /// convergence or [_maxOverlapIterations] passes.
  ///
  /// [nodeWidth] and [nodeHeight] are the card dimensions. [padding] is the
  /// minimum gap between cards.
  static void _resolveGlobalOverlaps(
    Map<String, Offset> positions,
    String userId,
    double nodeWidth,
    double nodeHeight,
    double padding,
  ) {
    const maxIterations = 20;
    final minDx = nodeWidth + padding;
    final minDy = nodeHeight + padding;

    for (int iter = 0; iter < maxIterations; iter++) {
      bool anyOverlap = false;
      final ids = positions.keys.toList();

      for (int i = 0; i < ids.length; i++) {
        for (int j = i + 1; j < ids.length; j++) {
          final aId = ids[i];
          final bId = ids[j];
          final a = positions[aId]!;
          final b = positions[bId]!;

          final dx = (a.dx - b.dx).abs();
          final dy = (a.dy - b.dy).abs();

          if (dx < minDx && dy < minDy) {
            anyOverlap = true;
            final overlapX = minDx - dx;
            final overlapY = minDy - dy;

            // Never move the user node.
            final aFixed = aId == userId;
            final bFixed = bId == userId;

            if (overlapX <= overlapY) {
              // Push horizontally (smaller overlap axis).
              final push = overlapX / 2 + 0.5;
              if (a.dx <= b.dx) {
                if (!aFixed) positions[aId] = Offset(a.dx - push, a.dy);
                if (!bFixed) positions[bId] = Offset(b.dx + push, b.dy);
              } else {
                if (!aFixed) positions[aId] = Offset(a.dx + push, a.dy);
                if (!bFixed) positions[bId] = Offset(b.dx - push, b.dy);
              }
            } else {
              // Push vertically.
              final push = overlapY / 2 + 0.5;
              if (a.dy <= b.dy) {
                if (!aFixed) positions[aId] = Offset(a.dx, a.dy - push);
                if (!bFixed) positions[bId] = Offset(b.dx, b.dy + push);
              } else {
                if (!aFixed) positions[aId] = Offset(a.dx, a.dy + push);
                if (!bFixed) positions[bId] = Offset(b.dx, b.dy - push);
              }
            }
          }
        }
      }

      if (!anyOverlap) break;
    }
  }

  /// Order nodes within a generation so spouses and siblings appear adjacent.
  ///
  /// Within each couple, the female is placed LEFT and the male RIGHT.
  /// This ensures paternal side branches extend right and maternal left.
  static void _orderWithinGeneration(
    List<String> group,
    FamilyGraph graph,
    String userId,
    Map<String, Relative> relativesMap,
  ) {
    final ordered = <String>[];
    final placed = <String>{};

    for (final nodeId in group) {
      if (placed.contains(nodeId)) continue;

      final spouseId = graph.getSpouse(nodeId);
      final hasSpouse = spouseId != null &&
          group.contains(spouseId) &&
          !placed.contains(spouseId);

      if (hasSpouse) {
        _addCouple(nodeId, spouseId, userId, relativesMap, ordered, placed);
      } else {
        ordered.add(nodeId);
        placed.add(nodeId);
      }

      // Add siblings adjacent (with their spouses).
      for (final sib in graph.getSiblings(nodeId)) {
        if (!group.contains(sib) || placed.contains(sib)) continue;

        final sibSpouse = graph.getSpouse(sib);
        final sibHasSpouse = sibSpouse != null &&
            group.contains(sibSpouse) &&
            !placed.contains(sibSpouse);

        if (sibHasSpouse) {
          _addCouple(sib, sibSpouse, userId, relativesMap, ordered, placed);
        } else {
          ordered.add(sib);
          placed.add(sib);
        }
      }
    }

    group.clear();
    group.addAll(ordered);
  }

  /// Add a couple to [ordered], placing the female LEFT and male RIGHT.
  static void _addCouple(
    String aId,
    String bId,
    String userId,
    Map<String, Relative> relativesMap,
    List<String> ordered,
    Set<String> placed,
  ) {
    final aGender = aId == userId ? null : relativesMap[aId]?.gender;
    final bGender = bId == userId ? null : relativesMap[bId]?.gender;

    // Determine if A should be on the left (male side).
    // Convention: male LEFT, female RIGHT.
    final aIsMale = aGender == Gender.male ||
        (aGender == null && bGender == Gender.female);

    if (aIsMale) {
      // A (male) left, B (female) right
      ordered.addAll([aId, bId]);
      placed.addAll({aId, bId});
    } else {
      // B left, A right (A is female → B is male, B goes left)
      ordered.addAll([bId, aId]);
      placed.addAll({bId, aId});
    }
  }

  /// Order side-branch nodes so spouses are adjacent.
  ///
  /// Convention: male LEFT, female RIGHT.
  /// In right-going grids (col 0 = leftmost), order is [male, female].
  /// In left-going grids (col 0 = rightmost), order is [female, male].
  static void _orderSideBranchNodes(
    List<String> group,
    FamilyGraph graph,
    Map<String, Relative> relativesMap, {
    required bool goRight,
  }) {
    final ordered = <String>[];
    final placed = <String>{};

    for (final nodeId in List.of(group)) {
      if (placed.contains(nodeId)) continue;

      final spouseId = graph.getSpouse(nodeId);
      final hasSpouse = spouseId != null &&
          group.contains(spouseId) &&
          !placed.contains(spouseId);

      if (hasSpouse) {
        final aGender = relativesMap[nodeId]?.gender;
        final bGender = relativesMap[spouseId]?.gender;
        final aIsMale = aGender == Gender.male ||
            (aGender == null && bGender == Gender.female);

        final maleId = aIsMale ? nodeId : spouseId;
        final femaleId = aIsMale ? spouseId : nodeId;

        // goRight → col 0 is left → [male, female]
        // goLeft  → col 0 is right → [female, male]
        if (goRight) {
          ordered.addAll([maleId, femaleId]);
        } else {
          ordered.addAll([femaleId, maleId]);
        }
        placed.addAll({nodeId, spouseId});
      } else {
        ordered.add(nodeId);
        placed.add(nodeId);
      }
    }

    group.clear();
    group.addAll(ordered);
  }

  // ---------------------------------------------------------------------------
  // Graph inference
  // ---------------------------------------------------------------------------

  /// Enrich sibling edges globally — delegates to FamilyGraphService.
  static FamilyGraph _enrichSiblingEdges(FamilyGraph graph, String userId) {
    return FamilyGraphService.enrichAllSiblingEdges(graph);
  }

  /// Processing order for inference: parents first so that grandparents,
  /// uncles, and cousins can find their anchor.
  static int _inferOrder(RelationshipType type) {
    switch (type) {
      case RelationshipType.father:
      case RelationshipType.mother:
        return 0;
      case RelationshipType.husband:
      case RelationshipType.wife:
        return 1;
      case RelationshipType.grandfather:
      case RelationshipType.grandmother:
        return 2;
      case RelationshipType.brother:
      case RelationshipType.sister:
        return 3;
      case RelationshipType.uncle:
      case RelationshipType.aunt:
        return 4;
      case RelationshipType.son:
      case RelationshipType.daughter:
        return 5;
      case RelationshipType.cousin:
        return 6;
      case RelationshipType.nephew:
      case RelationshipType.niece:
        return 7;
      case RelationshipType.other:
        return 8;
    }
  }

  /// Infer a graph from relationship types.
  ///
  /// Sorts relatives by dependency order so parents are in the edge list
  /// before uncles, grandparents, or cousins need them as anchors.
  /// This makes the result deterministic regardless of database order.
  static FamilyGraph _inferGraph(String userId, List<Relative> relatives) {
    final allEdges = <FamilyEdge>[];
    final activeRelatives = relatives.where((r) => !r.isArchived).toList();

    // Sort by dependency: parents first, then spouse/siblings, then
    // grandparents/uncles, then children, then cousins/nephew/niece/other.
    activeRelatives.sort((a, b) =>
        _inferOrder(a.relationshipType) - _inferOrder(b.relationshipType));

    for (final relative in activeRelatives) {
      final inferred = FamilyGraphService.inferEdges(
        userId: userId,
        newRelativeId: relative.id,
        relationshipType: relative.relationshipType,
        side: relative.familySide,
        existingEdges: allEdges,
        existingRelatives: activeRelatives,
      );
      allEdges.addAll(inferred);
    }

    // Ensure parent couples have a spouse edge so the layout treats them
    // as a unit (centered over children). The per-relative inferEdges may
    // miss this if processing order puts the second parent before the first.
    final father = activeRelatives
        .where((r) => r.relationshipType == RelationshipType.father)
        .firstOrNull;
    final mother = activeRelatives
        .where((r) => r.relationshipType == RelationshipType.mother)
        .firstOrNull;
    if (father != null && mother != null) {
      final hasSpouse = allEdges.any((e) =>
          e.type == EdgeType.spouseOf &&
          ((e.fromId == father.id && e.toId == mother.id) ||
              (e.fromId == mother.id && e.toId == father.id)));
      if (!hasSpouse) {
        allEdges.add(FamilyEdge.create(
          userId: userId,
          fromId: father.id,
          toId: mother.id,
          type: EdgeType.spouseOf,
        ));
      }
    }

    return FamilyGraphService.buildGraph(userId: userId, edges: allEdges);
  }

  // ---------------------------------------------------------------------------
  // Health helpers
  // ---------------------------------------------------------------------------

  /// Compute health ratio for a relative (0.0 to 1.0).
  static double _computeHealthRatio(Relative relative) {
    if (relative.lastContactDate == null) return 0.0;
    final days = DateTime.now().difference(relative.lastContactDate!).inDays;
    if (days < 0) return 1.0;
    final expectedFreq = _expectedFrequency(relative.priority);
    return 1.0 - min(1.0, days / expectedFreq);
  }

  /// Expected contact frequency in days by priority.
  static int _expectedFrequency(int priority) {
    switch (priority) {
      case 1:
        return 2;
      case 2:
        return 7;
      default:
        return 14;
    }
  }

  /// Check if a node is "healthy" (for edge styling).
  static bool _isNodeHealthy(
    String nodeId,
    String userId,
    Map<String, Relative> relativesMap,
  ) {
    if (nodeId == userId) return true;
    final relative = relativesMap[nodeId];
    if (relative == null) return true;
    return _computeHealthRatio(relative) >= 0.4;
  }

  // ---------------------------------------------------------------------------
  // Family side helpers
  // ---------------------------------------------------------------------------

  /// Map [RelationshipType] to a default generation when no graph edges exist.
  static int _generationFromType(RelationshipType type) {
    switch (type) {
      case RelationshipType.father:
      case RelationshipType.mother:
      case RelationshipType.uncle:
      case RelationshipType.aunt:
        return -1;
      case RelationshipType.grandfather:
      case RelationshipType.grandmother:
        return -2;
      case RelationshipType.son:
      case RelationshipType.daughter:
      case RelationshipType.nephew:
      case RelationshipType.niece:
        return 1;
      default:
        return 0;
    }
  }

  /// BFS from [startId] through siblings and parents (not children) to mark
  /// all reachable nodes with [side]. Avoids traversing through [excludeId]
  /// (the user) so paternal/maternal sides don't cross over.
  static void _traceFamilySide({
    required String startId,
    required String excludeId,
    required FamilyGraph graph,
    required Map<String, int> generations,
    required _FamilySide side,
    required Map<String, _FamilySide> result,
  }) {
    final queue = <String>[startId];
    final visited = <String>{startId, excludeId};
    result[startId] = side;

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);

      // Traverse UP (parents) and SIDEWAYS (siblings) only.
      // Not DOWN (children) — that would cross through user's generation
      // to the other parent's side.
      for (final neighbor in [
        ...graph.getSiblings(current),
        ...graph.getParents(current),
      ]) {
        if (!visited.contains(neighbor) &&
            generations.containsKey(neighbor)) {
          visited.add(neighbor);
          result[neighbor] = side;
          queue.add(neighbor);
        }
      }
    }
  }
}

/// Which side of the family a node belongs to.
/// Paternal (dad's side) extends LEFT, maternal (mom's side) extends RIGHT.
enum _FamilySide { paternal, maternal }
