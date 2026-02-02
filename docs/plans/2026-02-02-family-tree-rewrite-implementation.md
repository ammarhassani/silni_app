# Family Tree Canvas Rewrite — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the hardcoded-grid family tree with a full CustomPainter canvas visualization driven by the existing FamilyGraph model, with living animations and interaction-health visuals.

**Architecture:** Flutter CustomPainter renders all nodes and edges on a single canvas. A new `FamilyTreeLayoutService` computes graph-driven positions from the existing `FamilyGraph` + `FamilyGraphService`. `InteractiveViewer` handles pan/zoom. Tap interaction uses hit-testing on canvas coordinates with Flutter `OverlayEntry` for detail popups. Single `AnimationController` drives all living animations.

**Tech Stack:** Flutter/Dart, CustomPainter, InteractiveViewer, Riverpod providers (existing), FamilyGraph model (existing), ContactPriorityService (existing for health scoring)

**Design Doc:** `docs/plans/2026-02-02-family-tree-rewrite-design.md`

---

## Task 1: Layout Data Model

Create the data structures that the layout service outputs and the painter consumes. No logic yet — just the shapes.

**Files:**
- Create: `lib/features/family_tree/models/tree_layout.dart`
- Test: `test/unit/models/tree_layout_test.dart`

**Step 1: Write the test**

```dart
// test/unit/models/tree_layout_test.dart
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/features/family_tree/models/tree_layout.dart';
import 'package:silni_app/features/family_tree/models/family_graph.dart';

void main() {
  group('LayoutNode', () {
    test('should store position, label, and health data', () {
      final node = LayoutNode(
        id: 'father-1',
        position: const Offset(100, 200),
        emoji: '👨',
        name: 'سعيد',
        label: 'أبي',
        generation: -1,
        isUser: false,
        healthRatio: 0.8,
        streakDays: 5,
        radius: 30.0,
      );

      expect(node.id, 'father-1');
      expect(node.position, const Offset(100, 200));
      expect(node.label, 'أبي');
      expect(node.healthRatio, 0.8);
      expect(node.streakDays, 5);
      expect(node.isUser, false);
    });

    test('healthColor returns green for healthy ratio', () {
      final node = LayoutNode(
        id: 'n1',
        position: Offset.zero,
        emoji: '👤',
        name: 'Test',
        label: 'Test',
        generation: 0,
        isUser: false,
        healthRatio: 0.9,
        streakDays: 0,
        radius: 30.0,
      );
      // >= 0.7 is green
      expect(node.healthColor, HealthColor.green);
    });

    test('healthColor returns amber for moderate ratio', () {
      final node = LayoutNode(
        id: 'n1',
        position: Offset.zero,
        emoji: '👤',
        name: 'Test',
        label: 'Test',
        generation: 0,
        isUser: false,
        healthRatio: 0.5,
        streakDays: 0,
        radius: 30.0,
      );
      expect(node.healthColor, HealthColor.amber);
    });

    test('healthColor returns red for poor ratio', () {
      final node = LayoutNode(
        id: 'n1',
        position: Offset.zero,
        emoji: '👤',
        name: 'Test',
        label: 'Test',
        generation: 0,
        isUser: false,
        healthRatio: 0.2,
        streakDays: 0,
        radius: 30.0,
      );
      expect(node.healthColor, HealthColor.red);
    });
  });

  group('LayoutEdge', () {
    test('should store from/to positions and type', () {
      final edge = LayoutEdge(
        fromId: 'father-1',
        toId: 'user-1',
        from: const Offset(100, 200),
        to: const Offset(100, 400),
        type: EdgeType.parentOf,
        isHealthy: true,
      );

      expect(edge.fromId, 'father-1');
      expect(edge.type, EdgeType.parentOf);
      expect(edge.isHealthy, true);
    });
  });

  group('FamilyTreeLayout', () {
    test('should provide nodes, edges, and bounds', () {
      final layout = FamilyTreeLayout(
        nodes: [
          LayoutNode(
            id: 'me',
            position: const Offset(200, 300),
            emoji: '👤',
            name: 'أنا',
            label: 'أنا',
            generation: 0,
            isUser: true,
            healthRatio: 1.0,
            streakDays: 0,
            radius: 30.0,
          ),
        ],
        edges: [],
        bounds: const Rect.fromLTWH(0, 0, 400, 600),
        userPosition: const Offset(200, 300),
      );

      expect(layout.nodes, hasLength(1));
      expect(layout.edges, isEmpty);
      expect(layout.bounds.width, 400);
      expect(layout.userPosition, const Offset(200, 300));
    });

    test('findNodeAtPosition returns node when hit', () {
      final node = LayoutNode(
        id: 'me',
        position: const Offset(200, 300),
        emoji: '👤',
        name: 'أنا',
        label: 'أنا',
        generation: 0,
        isUser: true,
        healthRatio: 1.0,
        streakDays: 0,
        radius: 30.0,
      );
      final layout = FamilyTreeLayout(
        nodes: [node],
        edges: [],
        bounds: const Rect.fromLTWH(0, 0, 400, 600),
        userPosition: const Offset(200, 300),
      );

      // Tap within radius (30 + 10 padding = 40)
      expect(layout.findNodeAtPosition(const Offset(210, 305)), node);
      // Tap outside
      expect(layout.findNodeAtPosition(const Offset(0, 0)), isNull);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/models/tree_layout_test.dart`
Expected: FAIL — `tree_layout.dart` not found

**Step 3: Implement the data model**

```dart
// lib/features/family_tree/models/tree_layout.dart
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
  /// Active streak days. 0 = no streak. Shows 🔥 badge when > 0.
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
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/unit/models/tree_layout_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/family_tree/models/tree_layout.dart test/unit/models/tree_layout_test.dart
git commit -m "feat(tree): add layout data model for canvas-based family tree"
```

---

## Task 2: Layout Service — Graph-Driven Positioning

The core computation: take a FamilyGraph + relatives list and produce positioned nodes and edges.

**Files:**
- Create: `lib/features/family_tree/services/family_tree_layout_service.dart`
- Test: `test/unit/services/family_tree_layout_service_test.dart`

**Step 1: Write the test**

```dart
// test/unit/services/family_tree_layout_service_test.dart
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/features/family_tree/models/family_graph.dart';
import 'package:silni_app/features/family_tree/models/tree_layout.dart';
import 'package:silni_app/features/family_tree/services/family_graph_service.dart';
import 'package:silni_app/features/family_tree/services/family_tree_layout_service.dart';
import 'package:silni_app/shared/models/relative_model.dart';

void main() {
  const userId = 'user-1';
  const fatherId = 'father-1';
  const motherId = 'mother-1';
  const brotherId = 'brother-1';
  const wifeId = 'wife-1';
  const sonId = 'son-1';
  const grandfatherId = 'grandfather-1';
  const uncleId = 'uncle-1';
  const cousinId = 'cousin-1';

  FamilyEdge makeEdge({
    required String fromId,
    required String toId,
    required EdgeType type,
  }) {
    return FamilyEdge(
      id: 'edge-$fromId-$toId-${type.value}',
      userId: userId,
      fromId: fromId,
      toId: toId,
      type: type,
      createdAt: DateTime(2025, 1, 1),
    );
  }

  Relative makeRelative({
    required String id,
    required RelationshipType type,
    Gender? gender,
    DateTime? lastContactDate,
    int priority = 2,
  }) {
    return Relative(
      id: id,
      userId: userId,
      fullName: 'Test ${type.arabicName}',
      relationshipType: type,
      gender: gender ?? Gender.male,
      priority: priority,
      lastContactDate: lastContactDate,
      createdAt: DateTime(2025, 1, 1),
    );
  }

  group('FamilyTreeLayoutService.computeLayout', () {
    test('places user at center of canvas', () {
      final layout = FamilyTreeLayoutService.computeLayout(
        userId: userId,
        userName: 'محمد',
        graph: FamilyGraphService.buildGraph(userId: userId, edges: []),
        relatives: [],
        relativesMap: {},
        canvasSize: const Size(400, 600),
      );

      expect(layout.nodes, hasLength(1)); // just the user
      final userNode = layout.nodes.first;
      expect(userNode.isUser, true);
      expect(userNode.position.dx, closeTo(200, 1)); // centered horizontally
    });

    test('parents appear above user (lower y)', () {
      final edges = [
        makeEdge(fromId: fatherId, toId: userId, type: EdgeType.parentOf),
        makeEdge(fromId: motherId, toId: userId, type: EdgeType.parentOf),
      ];
      final father = makeRelative(id: fatherId, type: RelationshipType.father);
      final mother = makeRelative(
        id: motherId,
        type: RelationshipType.mother,
        gender: Gender.female,
      );
      final graph = FamilyGraphService.buildGraph(userId: userId, edges: edges);

      final layout = FamilyTreeLayoutService.computeLayout(
        userId: userId,
        userName: 'محمد',
        graph: graph,
        relatives: [father, mother],
        relativesMap: {fatherId: father, motherId: mother},
        canvasSize: const Size(400, 600),
      );

      final userNode = layout.nodes.firstWhere((n) => n.isUser);
      final fatherNode = layout.nodes.firstWhere((n) => n.id == fatherId);
      final motherNode = layout.nodes.firstWhere((n) => n.id == motherId);

      // Parents above user (smaller y)
      expect(fatherNode.position.dy, lessThan(userNode.position.dy));
      expect(motherNode.position.dy, lessThan(userNode.position.dy));
      // Parents at same y (same generation)
      expect(fatherNode.position.dy, closeTo(motherNode.position.dy, 1));
    });

    test('children appear below user (higher y)', () {
      final edges = [
        makeEdge(fromId: userId, toId: sonId, type: EdgeType.parentOf),
      ];
      final son = makeRelative(id: sonId, type: RelationshipType.son);
      final graph = FamilyGraphService.buildGraph(userId: userId, edges: edges);

      final layout = FamilyTreeLayoutService.computeLayout(
        userId: userId,
        userName: 'محمد',
        graph: graph,
        relatives: [son],
        relativesMap: {sonId: son},
        canvasSize: const Size(400, 600),
      );

      final userNode = layout.nodes.firstWhere((n) => n.isUser);
      final sonNode = layout.nodes.firstWhere((n) => n.id == sonId);

      expect(sonNode.position.dy, greaterThan(userNode.position.dy));
    });

    test('uncle at same generation as parent (-1)', () {
      final edges = [
        makeEdge(fromId: fatherId, toId: userId, type: EdgeType.parentOf),
        makeEdge(fromId: uncleId, toId: fatherId, type: EdgeType.siblingOf),
      ];
      final father = makeRelative(id: fatherId, type: RelationshipType.father);
      final uncle = makeRelative(id: uncleId, type: RelationshipType.uncle);
      final graph = FamilyGraphService.buildGraph(userId: userId, edges: edges);

      final layout = FamilyTreeLayoutService.computeLayout(
        userId: userId,
        userName: 'محمد',
        graph: graph,
        relatives: [father, uncle],
        relativesMap: {fatherId: father, uncleId: uncle},
        canvasSize: const Size(400, 600),
      );

      final fatherNode = layout.nodes.firstWhere((n) => n.id == fatherId);
      final uncleNode = layout.nodes.firstWhere((n) => n.id == uncleId);

      // Same generation = same y
      expect(uncleNode.position.dy, closeTo(fatherNode.position.dy, 1));
    });

    test('cousin at same generation as user (0)', () {
      final edges = [
        makeEdge(fromId: fatherId, toId: userId, type: EdgeType.parentOf),
        makeEdge(fromId: uncleId, toId: fatherId, type: EdgeType.siblingOf),
        makeEdge(fromId: uncleId, toId: cousinId, type: EdgeType.parentOf),
      ];
      final father = makeRelative(id: fatherId, type: RelationshipType.father);
      final uncle = makeRelative(id: uncleId, type: RelationshipType.uncle);
      final cousin = makeRelative(id: cousinId, type: RelationshipType.cousin);
      final graph = FamilyGraphService.buildGraph(userId: userId, edges: edges);

      final layout = FamilyTreeLayoutService.computeLayout(
        userId: userId,
        userName: 'محمد',
        graph: graph,
        relatives: [father, uncle, cousin],
        relativesMap: {fatherId: father, uncleId: uncle, cousinId: cousin},
        canvasSize: const Size(400, 600),
      );

      final userNode = layout.nodes.firstWhere((n) => n.isUser);
      final cousinNode = layout.nodes.firstWhere((n) => n.id == cousinId);

      // Same generation = same y
      expect(cousinNode.position.dy, closeTo(userNode.position.dy, 1));
    });

    test('spouse positioned adjacent to user (same y)', () {
      final edges = [
        makeEdge(fromId: userId, toId: wifeId, type: EdgeType.spouseOf),
      ];
      final wife = makeRelative(
        id: wifeId,
        type: RelationshipType.wife,
        gender: Gender.female,
      );
      final graph = FamilyGraphService.buildGraph(userId: userId, edges: edges);

      final layout = FamilyTreeLayoutService.computeLayout(
        userId: userId,
        userName: 'محمد',
        graph: graph,
        relatives: [wife],
        relativesMap: {wifeId: wife},
        canvasSize: const Size(400, 600),
      );

      final userNode = layout.nodes.firstWhere((n) => n.isUser);
      final wifeNode = layout.nodes.firstWhere((n) => n.id == wifeId);

      expect(wifeNode.position.dy, closeTo(userNode.position.dy, 1));
    });

    test('generates edges for all graph connections', () {
      final edges = [
        makeEdge(fromId: fatherId, toId: userId, type: EdgeType.parentOf),
        makeEdge(fromId: brotherId, toId: userId, type: EdgeType.siblingOf),
      ];
      final father = makeRelative(id: fatherId, type: RelationshipType.father);
      final brother = makeRelative(id: brotherId, type: RelationshipType.brother);
      final graph = FamilyGraphService.buildGraph(userId: userId, edges: edges);

      final layout = FamilyTreeLayoutService.computeLayout(
        userId: userId,
        userName: 'محمد',
        graph: graph,
        relatives: [father, brother],
        relativesMap: {fatherId: father, brotherId: brother},
        canvasSize: const Size(400, 600),
      );

      // One parentOf edge (father→user) + one siblingOf edge (brother↔user)
      expect(layout.edges.length, greaterThanOrEqualTo(2));
    });

    test('handles empty graph by inferring edges from relationship types', () {
      final father = makeRelative(id: fatherId, type: RelationshipType.father);
      final mother = makeRelative(
        id: motherId,
        type: RelationshipType.mother,
        gender: Gender.female,
      );

      final layout = FamilyTreeLayoutService.computeLayout(
        userId: userId,
        userName: 'محمد',
        graph: null, // no graph — should infer
        relatives: [father, mother],
        relativesMap: {fatherId: father, motherId: mother},
        canvasSize: const Size(400, 600),
      );

      // Should still have 3 nodes (user + father + mother) and edges
      expect(layout.nodes, hasLength(3));
      expect(layout.edges, isNotEmpty);

      final userNode = layout.nodes.firstWhere((n) => n.isUser);
      final fatherNode = layout.nodes.firstWhere((n) => n.id == fatherId);
      // Father still above user even with inferred graph
      expect(fatherNode.position.dy, lessThan(userNode.position.dy));
    });

    test('computes health ratio from last contact date', () {
      final father = makeRelative(
        id: fatherId,
        type: RelationshipType.father,
        priority: 1,
        lastContactDate: DateTime.now().subtract(const Duration(days: 10)),
      );
      final edges = [
        makeEdge(fromId: fatherId, toId: userId, type: EdgeType.parentOf),
      ];
      final graph = FamilyGraphService.buildGraph(userId: userId, edges: edges);

      final layout = FamilyTreeLayoutService.computeLayout(
        userId: userId,
        userName: 'محمد',
        graph: graph,
        relatives: [father],
        relativesMap: {fatherId: father},
        canvasSize: const Size(400, 600),
      );

      final fatherNode = layout.nodes.firstWhere((n) => n.id == fatherId);
      // Priority 1 expected freq = 2 days, 10 days overdue → low health
      expect(fatherNode.healthRatio, lessThan(0.5));
    });

    test('handles 30+ relatives without error', () {
      final relatives = <Relative>[];
      final edgesList = <FamilyEdge>[];

      // Add father
      relatives.add(makeRelative(id: fatherId, type: RelationshipType.father));
      edgesList.add(makeEdge(fromId: fatherId, toId: userId, type: EdgeType.parentOf));

      // Add 30 cousins (as children of father for simplicity)
      for (int i = 0; i < 30; i++) {
        final id = 'cousin-$i';
        relatives.add(makeRelative(id: id, type: RelationshipType.cousin));
      }

      final graph = FamilyGraphService.buildGraph(userId: userId, edges: edgesList);
      final relativesMap = {for (final r in relatives) r.id: r};

      final layout = FamilyTreeLayoutService.computeLayout(
        userId: userId,
        userName: 'محمد',
        graph: graph,
        relatives: relatives,
        relativesMap: relativesMap,
        canvasSize: const Size(400, 600),
      );

      // 31 relatives + 1 user = 32 nodes
      expect(layout.nodes, hasLength(32));
      expect(layout.bounds.width, greaterThan(0));
      expect(layout.bounds.height, greaterThan(0));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/services/family_tree_layout_service_test.dart`
Expected: FAIL — `family_tree_layout_service.dart` not found

**Step 3: Implement the layout service**

Create `lib/features/family_tree/services/family_tree_layout_service.dart`.

This is a pure static service (same pattern as `ContactPriorityService`). Key logic:

1. If `graph` is null, infer edges using `FamilyGraphService.inferEdges()` for each relative and build a temporary graph.
2. Compute generation level for each relative using `graph.getGeneration()`.
3. Compute labels using `FamilyGraphService.getLabelForViewer()`.
4. Group nodes by generation level.
5. Within each generation: cluster by shared parent, place spouses adjacent.
6. Compute x/y positions: y = generation * verticalSpacing + center offset. x = node index within generation * horizontalSpacing, centered.
7. Compute health ratio per node: `1.0 - min(1.0, daysSince / expectedFreq)` (reuse `ContactPriorityService._expectedFrequency` logic — inline it since it's private).
8. Generate `LayoutEdge` for each edge in graph, mapping node IDs to positions.
9. Compute bounds (bounding rect of all node positions + padding).
10. Return `FamilyTreeLayout`.

The method signature:

```dart
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
})
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/unit/services/family_tree_layout_service_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/family_tree/services/family_tree_layout_service.dart test/unit/services/family_tree_layout_service_test.dart
git commit -m "feat(tree): add graph-driven layout service for family tree canvas"
```

---

## Task 3: Canvas Painter — Edges and Nodes

The `CustomPainter` that draws everything from a `FamilyTreeLayout`.

**Files:**
- Create: `lib/features/family_tree/painters/family_tree_painter.dart`
- Test: `test/unit/painters/family_tree_painter_test.dart`

**Step 1: Write the test**

```dart
// test/unit/painters/family_tree_painter_test.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/features/family_tree/models/tree_layout.dart';
import 'package:silni_app/features/family_tree/models/family_graph.dart';
import 'package:silni_app/features/family_tree/painters/family_tree_painter.dart';

void main() {
  group('FamilyTreePainter', () {
    test('shouldRepaint returns true when layout changes', () {
      final layout1 = FamilyTreeLayout(
        nodes: [],
        edges: [],
        bounds: Rect.zero,
        userPosition: Offset.zero,
      );
      final layout2 = FamilyTreeLayout(
        nodes: [
          LayoutNode(
            id: 'n1',
            position: Offset.zero,
            emoji: '👤',
            name: 'Test',
            label: 'Test',
            generation: 0,
            isUser: true,
            healthRatio: 1.0,
            streakDays: 0,
            radius: 30,
          ),
        ],
        edges: [],
        bounds: const Rect.fromLTWH(0, 0, 100, 100),
        userPosition: Offset.zero,
      );

      final painter1 = FamilyTreePainter(
        layout: layout1,
        animationValue: 0.0,
        entryProgress: 1.0,
      );
      final painter2 = FamilyTreePainter(
        layout: layout2,
        animationValue: 0.0,
        entryProgress: 1.0,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns true when animation value changes', () {
      final layout = FamilyTreeLayout(
        nodes: [],
        edges: [],
        bounds: Rect.zero,
        userPosition: Offset.zero,
      );

      final painter1 = FamilyTreePainter(
        layout: layout,
        animationValue: 0.0,
        entryProgress: 1.0,
      );
      final painter2 = FamilyTreePainter(
        layout: layout,
        animationValue: 0.5,
        entryProgress: 1.0,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('constructor accepts required parameters', () {
      final layout = FamilyTreeLayout(
        nodes: [],
        edges: [],
        bounds: Rect.zero,
        userPosition: Offset.zero,
      );

      final painter = FamilyTreePainter(
        layout: layout,
        animationValue: 0.5,
        entryProgress: 1.0,
      );

      expect(painter, isNotNull);
    });
  });
}
```

**Step 2: Run test → fail. Step 3: Implement.**

Create `lib/features/family_tree/painters/family_tree_painter.dart`.

The painter:
1. In `paint()`, first draws all edges, then all nodes (nodes on top).
2. **Edge drawing**: For each `LayoutEdge`:
   - `parentOf`: Cubic bezier from `from` bottom-center to `to` top-center. Control points offset vertically by 40% of the distance. Solid green stroke if `isHealthy`, dashed red if not.
   - `spouseOf`: Short horizontal line between `from` and `to`. Gold color. Small ring icon at midpoint.
   - `siblingOf`: Horizontal bracket connector. Light green, thinner stroke.
3. **Node drawing**: For each `LayoutNode`:
   - Fill circle with gradient based on `healthColor` (green/amber/red). Blue ring for user node.
   - Draw emoji with `TextPainter` centered in circle.
   - Draw name text below circle (1 line, truncated with ellipsis).
   - Draw label text below name (smaller, semi-transparent).
   - If `streakDays > 0`, draw "🔥{n}" badge top-right.
4. **Breathing animation**: Read `animationValue` (0.0-1.0 continuous). For each node, compute phase = `(animationValue + node.generation * 0.1) % 1.0`. Scale node circle by `0.98 + 0.04 * sin(phase * 2π)`.
5. **Attention pulse**: If `node.needsAttention`, draw expanding ring using `animationValue` for phase.
6. **Entry animation**: Read `entryProgress` (0.0-1.0). Nodes with `|generation| * 0.2 > entryProgress` are not drawn yet. Otherwise, opacity = `((entryProgress - |generation| * 0.2) / 0.2).clamp(0.0, 1.0)`.

Parameters:
- `FamilyTreeLayout layout`
- `double animationValue` — continuous 0.0-1.0 for breathing/pulse
- `double entryProgress` — 0.0-1.0 for staggered entry animation

`shouldRepaint`: Return true if layout, animationValue, or entryProgress differ.

**Step 4: Run test → pass.**

**Step 5: Commit**

```bash
git add lib/features/family_tree/painters/family_tree_painter.dart test/unit/painters/family_tree_painter_test.dart
git commit -m "feat(tree): add CustomPainter for canvas-based family tree rendering"
```

---

## Task 4: Rewrite Family Tree Screen

Replace the old Widget-tree-based screen with CustomPainter + InteractiveViewer + overlay.

**Files:**
- Modify: `lib/features/family_tree/screens/family_tree_screen.dart`
- Keep: All existing locked state, header, zoom controls, screenshot detection, empty state, error state

**Step 1: Understand what to keep vs replace**

**Keep (copy verbatim):**
- `_buildLockedState()` and all its sub-methods (lines 947-1302) — premium gating
- `_buildHeader()` (lines 178-209) — back button + title
- `_buildZoomControls()` (lines 211-268) — zoom UI
- `_zoomIn()`, `_zoomOut()`, `_applyZoom()`, `_resetZoom()` (lines 1304-1342) — zoom logic
- `_buildEmptyState()` (lines 875-920) — empty tree prompt
- `_buildError()` (lines 922-945) — error state
- Screenshot detection setup (lines 50-75)
- `_PreviewNode` class and `_buildPreviewTree` (lines 1037-1099) — for locked state

**Delete (replace entirely):**
- `_buildTreeContent()` — replace with canvas version
- `_buildTreeData()` — replaced by `FamilyTreeLayoutService.computeLayout()`
- `_buildTreeLayout()` — replaced by `CustomPaint` widget
- `_buildGeneration()` — no longer needed
- `_buildSiblingRow()` — no longer needed
- `_isSpouseNode()` — no longer needed
- `_buildHorizontalConnection()` — no longer needed
- `_buildConnectionLines()` (except keep the one used in `_buildPreviewTree`)
- `_onNodeTap()` — replaced by canvas hit-testing
- `_showNodeDetails()` — replaced by overlay
- `_buildDetailRow()` — move to overlay

**Step 2: Implement the rewrite**

The new `_buildTreeContent()`:
1. Watch `familyGraphProvider(userId)` for graph data.
2. Compute `layout = FamilyTreeLayoutService.computeLayout(...)`.
3. Create `AnimationController` in `initState()` (duration: 3 seconds, repeat forever) for breathing.
4. Create separate `AnimationController` for entry (duration: 1.5 seconds, forward once on data load).
5. Render `InteractiveViewer` → `CustomPaint(painter: FamilyTreePainter(...), size: layout.bounds.size)`.
6. Wrap in `GestureDetector` for tap handling.
7. On tap: convert position via `_transformationController` matrix inverse → find node via `layout.findNodeAtPosition()` → show overlay.

The overlay (`_showNodeOverlay`):
- Create `OverlayEntry` positioned near the tapped node's screen position.
- Show: emoji + full name + label + last contact text + color indicator + call button + profile button.
- Triangle pointer toward node.
- Dismiss on tap outside (add a barrier `OverlayEntry` behind it).

**Step 3: Remove old imports**

Remove import of `tree_node_widget.dart` and `tree_node.dart` from the screen (no longer used here).

**Step 4: Run flutter analyze**

Run: `flutter analyze lib/features/family_tree/screens/family_tree_screen.dart`
Expected: No errors

**Step 5: Commit**

```bash
git add lib/features/family_tree/screens/family_tree_screen.dart
git commit -m "feat(tree): rewrite family tree screen with CustomPainter canvas"
```

---

## Task 5: Provider Wiring

Add a computed layout provider so the tree screen doesn't recompute on every frame.

**Files:**
- Modify: `lib/features/family_tree/providers/family_graph_providers.dart`

**Step 1: Add treeLayoutProvider**

```dart
/// Computed layout provider that recomputes only when relatives or edges change.
final treeLayoutProvider = Provider.autoDispose
    .family<FamilyTreeLayout?, ({String userId, String userName, Size canvasSize})>(
  (ref, params) {
    final relativesAsync = ref.watch(relativesStreamProvider(params.userId));
    final graph = ref.watch(familyGraphProvider(params.userId));

    return relativesAsync.whenData((relatives) {
      if (relatives.isEmpty) return null;
      final relativesMap = {for (final r in relatives) r.id: r};
      return FamilyTreeLayoutService.computeLayout(
        userId: params.userId,
        userName: params.userName,
        graph: graph,
        relatives: relatives,
        relativesMap: relativesMap,
        canvasSize: params.canvasSize,
      );
    }).valueOrNull;
  },
);
```

**Step 2: Commit**

```bash
git add lib/features/family_tree/providers/family_graph_providers.dart
git commit -m "feat(tree): add computed treeLayoutProvider for canvas rendering"
```

---

## Task 6: Cleanup and Test

Remove unused old files and ensure everything works together.

**Files:**
- Evaluate: `lib/features/family_tree/widgets/tree_node_widget.dart` — check if used elsewhere. If only used by old tree screen, delete.
- Evaluate: `lib/features/family_tree/models/tree_node.dart` — check if used elsewhere. If only used by old tree screen and old tests, delete.
- Update: `test/widget/family_tree/family_tree_screen_test.dart` — update tests for new canvas-based screen

**Step 1: Check for TreeNodeWidget/TreeNode usage outside tree screen**

Run: `grep -r "TreeNodeWidget\|tree_node_widget" lib/ --include="*.dart" -l`
Run: `grep -r "TreeNode\b" lib/ --include="*.dart" -l`

If only used in `family_tree_screen.dart` (which no longer imports them), delete both files.

**Step 2: Update existing widget tests**

The old `family_tree_screen_test.dart` tests TreeNode model and categorization logic — these are no longer relevant since the screen uses `FamilyTreeLayout` now. Update the tests to test the new behavior:
- Canvas renders correct number of nodes
- Tap triggers overlay
- Zoom controls work
- Premium gate works (keep existing locked state tests)

**Step 3: Run full test suite**

Run: `flutter test test/unit/services/family_graph_service_test.dart test/unit/models/tree_layout_test.dart test/unit/services/family_tree_layout_service_test.dart test/unit/painters/family_tree_painter_test.dart`
Expected: ALL PASS

Run: `flutter analyze`
Expected: No errors

**Step 4: Commit**

```bash
git add -A
git commit -m "refactor(tree): remove old tree node widget, update tests for canvas tree"
```

---

## Dependency Graph

```
Task 1 (data model) ──→ Task 2 (layout service) ──→ Task 3 (painter)
                                                          │
                                                          ↓
                                                    Task 4 (screen rewrite)
                                                          │
                                                          ↓
                                                    Task 5 (provider wiring)
                                                          │
                                                          ↓
                                                    Task 6 (cleanup + test)
```

All tasks are **sequential** — each depends on the previous.

## Execution Notes

- Run `flutter analyze` before each commit.
- Run `flutter test` for the specific test file after each implementation step.
- The existing `family_graph_service_test.dart` (1029 lines, all passing) MUST stay passing throughout — do not modify it.
- The `_buildLockedState()`, `_buildPreviewTree()`, header, zoom, empty, and error widgets are copied verbatim from the old screen — no changes needed.
- The `_buildConnectionLines()` method is still used by `_buildPreviewTree()` in the locked state — keep it.
