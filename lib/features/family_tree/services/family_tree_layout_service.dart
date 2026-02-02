import 'dart:math';
import 'dart:ui';

import '../../../shared/models/relative_model.dart';
import '../models/family_graph.dart';
import '../models/tree_layout.dart';
import 'family_graph_service.dart';

/// Pure static service for computing family tree layout positions.
///
/// Takes a [FamilyGraph] (or null) plus a list of [Relative]s and produces
/// a [FamilyTreeLayout] ready for the painter. Follows the project convention
/// of private constructor + static methods.
class FamilyTreeLayoutService {
  FamilyTreeLayoutService._();

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
    double nodeRadius = 30.0,
    double horizontalSpacing = 100.0,
    double verticalSpacing = 140.0,
  }) {
    // 1. Build or infer graph
    final effectiveGraph = graph ?? _inferGraph(userId, relatives);

    // 2. Compute generation for each person
    final generations = <String, int>{};
    generations[userId] = 0;
    for (final relative in relatives) {
      if (!relative.isArchived) {
        generations[relative.id] = effectiveGraph.containsNode(relative.id)
            ? effectiveGraph.getGeneration(relative.id)
            : 0;
      }
    }

    // 3. Group by generation
    final genGroups = <int, List<String>>{};
    genGroups.putIfAbsent(0, () => []).add(userId);
    for (final relative in relatives) {
      if (!relative.isArchived) {
        final gen = generations[relative.id] ?? 0;
        genGroups.putIfAbsent(gen, () => []).add(relative.id);
      }
    }

    // 4. Sort generations and order nodes within each generation
    // Place spouses adjacent to their partner
    for (final gen in genGroups.keys) {
      final group = genGroups[gen]!;
      _orderWithinGeneration(group, effectiveGraph, userId);
    }

    // 5. Compute positions
    final sortedGens = genGroups.keys.toList()..sort();

    // Center user's generation vertically
    final userGenY = canvasSize.height / 2;
    final centerX = canvasSize.width / 2;

    final positions = <String, Offset>{};
    for (final gen in sortedGens) {
      final group = genGroups[gen]!;
      final y = userGenY + gen * verticalSpacing;
      final totalWidth = (group.length - 1) * horizontalSpacing;
      final startX = centerX - totalWidth / 2;

      for (int i = 0; i < group.length; i++) {
        positions[group[i]] = Offset(startX + i * horizontalSpacing, y);
      }
    }

    // 6. Build LayoutNodes
    final nodes = <LayoutNode>[];

    // User node
    nodes.add(LayoutNode(
      id: userId,
      position: positions[userId]!,
      emoji: '\u{1F464}', // 👤
      name: userName,
      label: '\u0623\u0646\u0627', // أنا
      generation: 0,
      isUser: true,
      healthRatio: 1.0,
      streakDays: 0,
      radius: nodeRadius,
    ));

    // Relative nodes
    for (final relative in relatives) {
      if (relative.isArchived) continue;
      final pos = positions[relative.id];
      if (pos == null) continue;

      final label = FamilyGraphService.getLabelForViewer(
        graph: effectiveGraph,
        viewerId: userId,
        targetId: relative.id,
        relativesMap: relativesMap,
      );

      nodes.add(LayoutNode(
        id: relative.id,
        position: pos,
        emoji: relative.displayEmoji,
        name: relative.fullName,
        label: label,
        generation: generations[relative.id] ?? 0,
        isUser: false,
        healthRatio: _computeHealthRatio(relative),
        streakDays: 0,
        radius: nodeRadius,
      ));
    }

    // 7. Build LayoutEdges
    final edges = <LayoutEdge>[];
    for (final edge in effectiveGraph.edges) {
      final fromPos = positions[edge.fromId];
      final toPos = positions[edge.toId];
      if (fromPos == null || toPos == null) continue;

      // Edge is healthy if both endpoints are healthy
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

    // 8. Compute bounds
    final allPositions = positions.values.toList();
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

    return FamilyTreeLayout(
      nodes: nodes,
      edges: edges,
      bounds: bounds,
      userPosition: positions[userId]!,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Infer a temporary graph from relationship types when no persisted graph
  /// exists.
  static FamilyGraph _inferGraph(String userId, List<Relative> relatives) {
    final allEdges = <FamilyEdge>[];
    final activeRelatives = relatives.where((r) => !r.isArchived).toList();

    for (final relative in activeRelatives) {
      final inferred = FamilyGraphService.inferEdges(
        userId: userId,
        newRelativeId: relative.id,
        relationshipType: relative.relationshipType,
        existingEdges: allEdges,
        existingRelatives: activeRelatives,
      );
      allEdges.addAll(inferred);
    }

    return FamilyGraphService.buildGraph(userId: userId, edges: allEdges);
  }

  /// Order nodes within a generation so spouses appear adjacent to their
  /// partner.
  static void _orderWithinGeneration(
    List<String> group,
    FamilyGraph graph,
    String userId,
  ) {
    // Find spouse pairs and place them adjacent
    final ordered = <String>[];
    final placed = <String>{};

    for (final nodeId in group) {
      if (placed.contains(nodeId)) continue;
      ordered.add(nodeId);
      placed.add(nodeId);

      // Check for spouse
      final spouseId = graph.getSpouse(nodeId);
      if (spouseId != null &&
          group.contains(spouseId) &&
          !placed.contains(spouseId)) {
        ordered.add(spouseId);
        placed.add(spouseId);
      }
    }

    group.clear();
    group.addAll(ordered);
  }

  /// Compute health ratio for a relative (0.0 to 1.0).
  static double _computeHealthRatio(Relative relative) {
    if (relative.lastContactDate == null) return 0.0;
    final days = DateTime.now().difference(relative.lastContactDate!).inDays;
    if (days < 0) return 1.0; // Future date (clock skew) → treat as just contacted
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
}
