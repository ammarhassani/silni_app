# Perspective Engine Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement directional BFS scoping, global sibling enrichment, and path-based Arabic kinship labels so each family member sees only their blood relatives with correct perspective labels.

**Architecture:** Three new static methods on `FamilyGraphService` (`enrichAllSiblingEdges`, `computeRahimScope`, extended `getLabelForViewer`), a one-line layout service update, and a scope filter in the tree screen for shared trees.

**Tech Stack:** Dart/Flutter, pure static functions (no Supabase), Riverpod providers for wiring.

---

### Task 1: Add `enrichAllSiblingEdges` — tests

**Files:**
- Modify: `test/unit/services/family_graph_service_test.dart`

**Step 1: Write the failing test**

Add this group after the existing `FamilyGraph.containsNode` group (before the closing `}`):

```dart
  // =========================================================================
  // 8. enrichAllSiblingEdges tests
  // =========================================================================
  group('FamilyGraphService.enrichAllSiblingEdges', () {
    test('propagates parentOf from sibling A\'s parents to sibling B', () {
      // Setup: Grandpa→Dad (parentOf), Uncle↔Dad (siblingOf)
      // Expected: Grandpa→Uncle (parentOf) is added
      final edges = [
        makeEdge(fromId: grandfatherId, toId: fatherId, type: EdgeType.parentOf),
        makeEdge(fromId: uncleId, toId: fatherId, type: EdgeType.siblingOf),
      ];
      final graph = FamilyGraphService.buildGraph(userId: userId, edges: edges);

      final enriched = FamilyGraphService.enrichAllSiblingEdges(graph);

      // Grandpa should now be parent of Uncle
      expect(enriched.getParents(uncleId), contains(grandfatherId));
      // Original edges still present
      expect(enriched.getParents(fatherId), contains(grandfatherId));
      expect(enriched.getSiblings(fatherId), contains(uncleId));
    });

    test('propagates in both directions for sibling pairs', () {
      // Setup: Grandpa→Uncle (parentOf), Uncle↔Dad (siblingOf)
      // Expected: Grandpa→Dad (parentOf) is added
      final edges = [
        makeEdge(fromId: grandfatherId, toId: uncleId, type: EdgeType.parentOf),
        makeEdge(fromId: uncleId, toId: fatherId, type: EdgeType.siblingOf),
      ];
      final graph = FamilyGraphService.buildGraph(userId: userId, edges: edges);

      final enriched = FamilyGraphService.enrichAllSiblingEdges(graph);

      expect(enriched.getParents(fatherId), contains(grandfatherId));
    });

    test('does not duplicate existing parentOf edges', () {
      final edges = [
        makeEdge(fromId: grandfatherId, toId: fatherId, type: EdgeType.parentOf),
        makeEdge(fromId: grandfatherId, toId: uncleId, type: EdgeType.parentOf),
        makeEdge(fromId: uncleId, toId: fatherId, type: EdgeType.siblingOf),
      ];
      final graph = FamilyGraphService.buildGraph(userId: userId, edges: edges);

      final enriched = FamilyGraphService.enrichAllSiblingEdges(graph);

      // Count parentOf edges from grandfather
      final gpEdges = enriched.edges.where(
        (e) => e.fromId == grandfatherId && e.type == EdgeType.parentOf,
      );
      expect(gpEdges.length, 2); // exactly 2, no duplicates
    });

    test('returns same graph when no sibling edges exist', () {
      final edges = [
        makeEdge(fromId: fatherId, toId: userId, type: EdgeType.parentOf),
      ];
      final graph = FamilyGraphService.buildGraph(userId: userId, edges: edges);

      final enriched = FamilyGraphService.enrichAllSiblingEdges(graph);

      expect(enriched.edges.length, graph.edges.length);
    });

    test('propagates spouse parents to sibling too', () {
      // Grandpa→Dad, Grandma↔Grandpa (spouse), Uncle↔Dad (sibling)
      // Expected: Grandpa→Uncle AND Grandma→Uncle
      // Note: spouse-propagation is a stretch — this test documents
      // that enrichAllSiblingEdges only propagates from DIRECT parents,
      // not from spouses of parents. Grandma→Dad must exist explicitly.
      final edges = [
        makeEdge(fromId: grandfatherId, toId: fatherId, type: EdgeType.parentOf),
        makeEdge(fromId: grandmotherId, toId: fatherId, type: EdgeType.parentOf),
        makeEdge(fromId: grandfatherId, toId: grandmotherId, type: EdgeType.spouseOf),
        makeEdge(fromId: uncleId, toId: fatherId, type: EdgeType.siblingOf),
      ];
      final graph = FamilyGraphService.buildGraph(userId: userId, edges: edges);

      final enriched = FamilyGraphService.enrichAllSiblingEdges(graph);

      expect(enriched.getParents(uncleId), contains(grandfatherId));
      expect(enriched.getParents(uncleId), contains(grandmotherId));
    });
  });
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/services/family_graph_service_test.dart`
Expected: FAIL — `FamilyGraphService.enrichAllSiblingEdges` does not exist yet.

---

### Task 2: Implement `enrichAllSiblingEdges`

**Files:**
- Modify: `lib/features/family_tree/services/family_graph_service.dart` (add method after `buildGraph`, around line 36)

**Step 3: Write minimal implementation**

Add this static method to `FamilyGraphService`, after the `buildGraph` method (after line 36, before the `inferEdges` comment block):

```dart
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
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/unit/services/family_graph_service_test.dart`
Expected: All `enrichAllSiblingEdges` tests PASS.

**Step 5: Commit**

```bash
git add lib/features/family_tree/services/family_graph_service.dart test/unit/services/family_graph_service_test.dart
git commit -m "feat: add enrichAllSiblingEdges for global sibling edge propagation"
```

---

### Task 3: Add `computeRahimScope` — tests

**Files:**
- Modify: `test/unit/services/family_graph_service_test.dart`

**Step 6: Write the failing tests**

Add this group after the `enrichAllSiblingEdges` group:

```dart
  // =========================================================================
  // 9. computeRahimScope tests
  // =========================================================================
  group('FamilyGraphService.computeRahimScope', () {
    // Build the canonical family tree from the bible:
    //
    //       Pat.Grandpa ── Pat.Grandma         Mat.Grandpa ── Mat.Grandma
    //              │                                  │
    //      ┌───────┼────────┐              ┌──────────┼────────┐
    //      │       │        │              │          │        │
    //  Pat.Uncle  Dad    Pat.Aunt      Mat.Uncle    Mom    Mat.Aunt
    //              │                                  │
    //              Dad ══════════════════════ Mom
    //                           │
    //               ┌───────────┼───────────┐
    //               │           │           │
    //            Brother     User A       Sister
    //               │           │           │
    //            Nephew    User A ══ Spouse  Niece
    //                           │
    //                      ┌────┼────┐
    //                      │         │
    //                     Son    Daughter

    const patGrandpaId = 'pat-grandpa';
    const patGrandmaId = 'pat-grandma';
    const matGrandpaId = 'mat-grandpa';
    const matGrandmaId = 'mat-grandma';
    const patUncleId = 'pat-uncle';
    const patAuntId = 'pat-aunt';
    const matUncleId = 'mat-uncle';
    const matAuntId = 'mat-aunt';
    const dadId = 'dad';
    const momId = 'mom';
    const userAId = 'user-a';
    const bro = 'brother';
    const sis = 'sister';
    const son = 'son';
    const dau = 'daughter';
    const spouse = 'spouse';
    const nephew = 'nephew';
    const niece = 'niece';
    const patCousM = 'pat-cous-m';
    const matCousF = 'mat-cous-f';

    late FamilyGraph fullGraph;

    setUp(() {
      final edges = [
        // Grandparents → Parents
        makeEdge(fromId: patGrandpaId, toId: dadId, type: EdgeType.parentOf),
        makeEdge(fromId: patGrandmaId, toId: dadId, type: EdgeType.parentOf),
        makeEdge(fromId: matGrandpaId, toId: momId, type: EdgeType.parentOf),
        makeEdge(fromId: matGrandmaId, toId: momId, type: EdgeType.parentOf),
        // Grandparent spouses
        makeEdge(fromId: patGrandpaId, toId: patGrandmaId, type: EdgeType.spouseOf),
        makeEdge(fromId: matGrandpaId, toId: matGrandmaId, type: EdgeType.spouseOf),
        // Parents → User
        makeEdge(fromId: dadId, toId: userAId, type: EdgeType.parentOf),
        makeEdge(fromId: momId, toId: userAId, type: EdgeType.parentOf),
        // Parent spouse
        makeEdge(fromId: dadId, toId: momId, type: EdgeType.spouseOf),
        // Siblings
        makeEdge(fromId: bro, toId: userAId, type: EdgeType.siblingOf),
        makeEdge(fromId: sis, toId: userAId, type: EdgeType.siblingOf),
        // Uncle/aunt siblings
        makeEdge(fromId: patUncleId, toId: dadId, type: EdgeType.siblingOf),
        makeEdge(fromId: patAuntId, toId: dadId, type: EdgeType.siblingOf),
        makeEdge(fromId: matUncleId, toId: momId, type: EdgeType.siblingOf),
        makeEdge(fromId: matAuntId, toId: momId, type: EdgeType.siblingOf),
        // User → Children
        makeEdge(fromId: userAId, toId: son, type: EdgeType.parentOf),
        makeEdge(fromId: userAId, toId: dau, type: EdgeType.parentOf),
        // Spouse
        makeEdge(fromId: userAId, toId: spouse, type: EdgeType.spouseOf),
        // Sibling → children
        makeEdge(fromId: bro, toId: nephew, type: EdgeType.parentOf),
        makeEdge(fromId: sis, toId: niece, type: EdgeType.parentOf),
        // Cousin children
        makeEdge(fromId: patUncleId, toId: patCousM, type: EdgeType.parentOf),
        makeEdge(fromId: matAuntId, toId: matCousF, type: EdgeType.parentOf),
      ];

      // Enrich first (propagates parentOf across all sibling pairs)
      final raw = FamilyGraphService.buildGraph(userId: userAId, edges: edges);
      fullGraph = FamilyGraphService.enrichAllSiblingEdges(raw);
    });

    test('User A sees everyone (center of tree)', () {
      final scope = FamilyGraphService.computeRahimScope(
        viewerId: userAId,
        graph: fullGraph,
      );

      // User A is connected to everything via blood
      expect(scope, contains(dadId));
      expect(scope, contains(momId));
      expect(scope, contains(bro));
      expect(scope, contains(sis));
      expect(scope, contains(son));
      expect(scope, contains(dau));
      expect(scope, contains(patGrandpaId));
      expect(scope, contains(matGrandpaId));
      expect(scope, contains(patUncleId));
      expect(scope, contains(matUncleId));
      expect(scope, contains(nephew));
      expect(scope, contains(niece));
      expect(scope, contains(patCousM));
      expect(scope, contains(matCousF));
      // Spouse is added as 1-hop
      expect(scope, contains(spouse));
    });

    test('Pat.Uncle does NOT see Mom or maternal side', () {
      final scope = FamilyGraphService.computeRahimScope(
        viewerId: patUncleId,
        graph: fullGraph,
      );

      // Pat.Uncle sees: self, grandparents, dad, pat.aunt, user, bro, sis, patCousM
      expect(scope, contains(patGrandpaId));
      expect(scope, contains(patGrandmaId));
      expect(scope, contains(dadId));
      expect(scope, contains(patAuntId));
      expect(scope, contains(userAId));
      expect(scope, contains(bro));
      expect(scope, contains(sis));
      expect(scope, contains(patCousM));

      // Does NOT see maternal side (only reachable through Mom, who is Dad's spouse)
      expect(scope, isNot(contains(momId)));
      expect(scope, isNot(contains(matGrandpaId)));
      expect(scope, isNot(contains(matGrandmaId)));
      expect(scope, isNot(contains(matUncleId)));
      expect(scope, isNot(contains(matAuntId)));
      expect(scope, isNot(contains(matCousF)));
    });

    test('Dad does NOT see maternal side', () {
      final scope = FamilyGraphService.computeRahimScope(
        viewerId: dadId,
        graph: fullGraph,
      );

      // Dad sees his parents, siblings, children, grandchildren
      expect(scope, contains(patGrandpaId));
      expect(scope, contains(patGrandmaId));
      expect(scope, contains(patUncleId));
      expect(scope, contains(patAuntId));
      expect(scope, contains(userAId));
      expect(scope, contains(bro));
      expect(scope, contains(sis));
      expect(scope, contains(son));
      expect(scope, contains(nephew));
      // Spouse is added
      expect(scope, contains(momId));

      // Does NOT see maternal grandparents, uncles, cousins
      expect(scope, isNot(contains(matGrandpaId)));
      expect(scope, isNot(contains(matGrandmaId)));
      expect(scope, isNot(contains(matUncleId)));
      expect(scope, isNot(contains(matAuntId)));
      expect(scope, isNot(contains(matCousF)));
    });

    test('Spouse sees only User A (no blood connections)', () {
      final scope = FamilyGraphService.computeRahimScope(
        viewerId: spouse,
        graph: fullGraph,
      );

      // Spouse has no parentOf/siblingOf edges, only spouseOf to User A
      expect(scope, contains(userAId)); // direct spouse
      // Nobody else is blood-reachable
      expect(scope, isNot(contains(dadId)));
      expect(scope, isNot(contains(momId)));
      expect(scope, isNot(contains(son))); // no parentOf from spouse→son
    });

    test('Son sees User A\'s siblings as uncles but not User A\'s spouse', () {
      final scope = FamilyGraphService.computeRahimScope(
        viewerId: son,
        graph: fullGraph,
      );

      expect(scope, contains(userAId));
      expect(scope, contains(dau)); // sibling
      expect(scope, contains(dadId)); // grandparent
      expect(scope, contains(momId)); // grandparent
      expect(scope, contains(bro)); // parent's sibling
      expect(scope, contains(sis)); // parent's sibling
      expect(scope, contains(patGrandpaId)); // great-grandparent
      // Does NOT see spouse (not blood)
      expect(scope, isNot(contains(spouse)));
    });

    test('scope always includes the viewer', () {
      final scope = FamilyGraphService.computeRahimScope(
        viewerId: nephew,
        graph: fullGraph,
      );
      expect(scope, contains(nephew));
    });
  });
```

**Step 7: Run test to verify it fails**

Run: `flutter test test/unit/services/family_graph_service_test.dart`
Expected: FAIL — `FamilyGraphService.computeRahimScope` does not exist yet.

---

### Task 4: Implement `computeRahimScope`

**Files:**
- Modify: `lib/features/family_tree/services/family_graph_service.dart` (add method after `enrichAllSiblingEdges`)

**Step 8: Write minimal implementation**

Add this method right after `enrichAllSiblingEdges`:

```dart
  // ---------------------------------------------------------------------------
  // Rahim scope (directional BFS)
  // ---------------------------------------------------------------------------

  /// Compute the set of node IDs visible from [viewerId]'s perspective.
  ///
  /// Uses directional BFS where the direction a node was reached from
  /// determines which edges can be traversed next:
  /// - **START** (viewer): UP + SIDEWAYS + DOWN
  /// - **VIA UP** (ancestor): UP + SIDEWAYS (not DOWN — prevents leaking)
  /// - **VIA SIDEWAYS** (sibling of ancestor): DOWN only
  /// - **VIA DOWN** (descendant): DOWN only
  ///
  /// Additionally, the viewer's direct spouse is added (1-hop, not traversed from).
  static Set<String> computeRahimScope({
    required String viewerId,
    required FamilyGraph graph,
  }) {
    final scope = <String>{viewerId};

    // BFS queue: (nodeId, direction it was reached by)
    // Direction enum: start, up, sideways, down
    final queue = <(String, _BfsDirection)>[(viewerId, _BfsDirection.start)];
    final visited = <String>{viewerId};

    while (queue.isNotEmpty) {
      final (nodeId, direction) = queue.removeAt(0);

      // Determine allowed traversals based on direction
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
        for (final siblingId in graph.getSiblings(nodeId)) {
          if (visited.add(siblingId)) {
            scope.add(siblingId);
            queue.add((siblingId, _BfsDirection.sideways));
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
```

Also add the enum at the bottom of the file, **outside** the `FamilyGraphService` class but before the existing `_IterableExtension`:

```dart
/// BFS direction for Rahim scope traversal.
enum _BfsDirection { start, up, sideways, down }
```

**Step 9: Run test to verify it passes**

Run: `flutter test test/unit/services/family_graph_service_test.dart`
Expected: All `computeRahimScope` tests PASS.

**Step 10: Commit**

```bash
git add lib/features/family_tree/services/family_graph_service.dart test/unit/services/family_graph_service_test.dart
git commit -m "feat: add computeRahimScope directional BFS for blood-relative scoping"
```

---

### Task 5: Add extended `getLabelForViewer` — tests

**Files:**
- Modify: `test/unit/services/family_graph_service_test.dart`

**Step 11: Write the failing tests**

Add these tests inside the existing `FamilyGraphService.getLabelForViewer` group, after the `'fallback: returns empty string for unknown target'` test:

```dart
    // --- Extended perspective labels ---

    test('sibling\'s child: uncle→nephew = "ابن أخوي"', () {
      // Need: brother→nephew (parentOf)
      const nephewId = 'nephew-1';
      final extraEdges = [
        ...graph.edges,
        makeEdge(fromId: brotherId, toId: nephewId, type: EdgeType.parentOf),
      ];
      final extGraph = FamilyGraphService.buildGraph(userId: userId, edges: extraEdges);
      final nephewRelative = makeRelative(
        id: nephewId,
        type: RelationshipType.nephew,
        gender: Gender.male,
        fullName: 'ابن الأخ',
      );
      final mapWithNephew = {...relativesMap, nephewId: nephewRelative};

      final label = FamilyGraphService.getLabelForViewer(
        graph: extGraph,
        viewerId: userId,
        targetId: nephewId,
        relativesMap: mapWithNephew,
      );
      expect(label, 'ابن أخوي');
    });

    test('sibling\'s child: sister\'s daughter = "بنت أختي"', () {
      const nieceId = 'niece-1';
      final extraEdges = [
        ...graph.edges,
        makeEdge(fromId: sisterId, toId: nieceId, type: EdgeType.parentOf),
      ];
      final extGraph = FamilyGraphService.buildGraph(userId: userId, edges: extraEdges);
      final nieceRelative = makeRelative(
        id: nieceId,
        type: RelationshipType.niece,
        gender: Gender.female,
        fullName: 'بنت الأخت',
      );
      final mapWithNiece = {...relativesMap, nieceId: nieceRelative};

      final label = FamilyGraphService.getLabelForViewer(
        graph: extGraph,
        viewerId: userId,
        targetId: nieceId,
        relativesMap: mapWithNiece,
      );
      expect(label, 'بنت أختي');
    });

    test('grandchild: son\'s son = "حفيدي"', () {
      const grandsonId = 'grandson-1';
      final extraEdges = [
        ...graph.edges,
        makeEdge(fromId: sonId, toId: grandsonId, type: EdgeType.parentOf),
      ];
      final extGraph = FamilyGraphService.buildGraph(userId: userId, edges: extraEdges);
      final grandsonRelative = makeRelative(
        id: grandsonId,
        type: RelationshipType.son,
        gender: Gender.male,
        fullName: 'الحفيد',
      );
      final mapWithGrandson = {...relativesMap, grandsonId: grandsonRelative};

      final label = FamilyGraphService.getLabelForViewer(
        graph: extGraph,
        viewerId: userId,
        targetId: grandsonId,
        relativesMap: mapWithGrandson,
      );
      expect(label, 'حفيدي');
    });

    test('great-grandparent: parent→parent→parent (male) = "جدي الأكبر"', () {
      const greatGpId = 'great-gp-1';
      final extraEdges = [
        ...graph.edges,
        makeEdge(fromId: greatGpId, toId: grandfatherId, type: EdgeType.parentOf),
      ];
      final extGraph = FamilyGraphService.buildGraph(userId: userId, edges: extraEdges);
      final greatGpRelative = makeRelative(
        id: greatGpId,
        type: RelationshipType.grandfather,
        gender: Gender.male,
        fullName: 'الجد الأكبر',
      );
      final mapWithGreatGp = {...relativesMap, greatGpId: greatGpRelative};

      final label = FamilyGraphService.getLabelForViewer(
        graph: extGraph,
        viewerId: userId,
        targetId: greatGpId,
        relativesMap: mapWithGreatGp,
      );
      expect(label, 'جدي الأكبر');
    });

    test('great-grandparent: parent→parent→parent (female) = "جدتي الكبرى"', () {
      const greatGmId = 'great-gm-1';
      final extraEdges = [
        ...graph.edges,
        makeEdge(fromId: greatGmId, toId: grandfatherId, type: EdgeType.parentOf),
      ];
      final extGraph = FamilyGraphService.buildGraph(userId: userId, edges: extraEdges);
      final greatGmRelative = makeRelative(
        id: greatGmId,
        type: RelationshipType.grandmother,
        gender: Gender.female,
        fullName: 'الجدة الكبرى',
      );
      final mapWithGreatGm = {...relativesMap, greatGmId: greatGmRelative};

      final label = FamilyGraphService.getLabelForViewer(
        graph: extGraph,
        viewerId: userId,
        targetId: greatGmId,
        relativesMap: mapWithGreatGm,
      );
      expect(label, 'جدتي الكبرى');
    });

    test('paternal cousin: parent(♂)→sibling(♂)→child(♂) = "ابن عمي"', () {
      // Dad(♂) → uncle(♂) → cousinM(♂) = ابن عمي
      const cousinMId = 'pat-cousin-m';
      final extraEdges = [
        ...graph.edges,
        makeEdge(fromId: uncleId, toId: cousinMId, type: EdgeType.parentOf),
      ];
      final extGraph = FamilyGraphService.buildGraph(userId: userId, edges: extraEdges);
      final cousinM = makeRelative(
        id: cousinMId,
        type: RelationshipType.cousin,
        gender: Gender.male,
        fullName: 'ابن العم',
      );
      final mapWithCousin = {...relativesMap, cousinMId: cousinM};

      final label = FamilyGraphService.getLabelForViewer(
        graph: extGraph,
        viewerId: userId,
        targetId: cousinMId,
        relativesMap: mapWithCousin,
      );
      expect(label, 'ابن عمي');
    });

    test('maternal cousin: parent(♀)→sibling(♀)→child(♀) = "بنت خالتي"', () {
      // Mom(♀) → aunt(♀ maternal) → cousinF(♀) = بنت خالتي
      const cousinFId = 'mat-cousin-f';
      final extraEdges = [
        ...graph.edges,
        makeEdge(fromId: auntId, toId: cousinFId, type: EdgeType.parentOf),
      ];
      final extGraph = FamilyGraphService.buildGraph(userId: userId, edges: extraEdges);
      final cousinF = makeRelative(
        id: cousinFId,
        type: RelationshipType.cousin,
        gender: Gender.female,
        fullName: 'بنت الخالة',
      );
      final mapWithCousin = {...relativesMap, cousinFId: cousinF};

      final label = FamilyGraphService.getLabelForViewer(
        graph: extGraph,
        viewerId: userId,
        targetId: cousinFId,
        relativesMap: mapWithCousin,
      );
      expect(label, 'بنت خالتي');
    });

    test('paternal aunt\'s son: parent(♂)→sibling(♀)→child(♂) = "ابن عمتي"', () {
      // Dad(♂) has a sister (pat.aunt) who has a son
      const patAuntId = 'pat-aunt-1';
      const patAuntSonId = 'pat-aunt-son';
      final extraEdges = [
        ...graph.edges,
        makeEdge(fromId: patAuntId, toId: fatherId, type: EdgeType.siblingOf),
        makeEdge(fromId: patAuntId, toId: patAuntSonId, type: EdgeType.parentOf),
      ];
      final extGraph = FamilyGraphService.buildGraph(userId: userId, edges: extraEdges);
      final patAunt = makeRelative(
        id: patAuntId,
        type: RelationshipType.aunt,
        gender: Gender.female,
        fullName: 'العمة',
      );
      final patAuntSon = makeRelative(
        id: patAuntSonId,
        type: RelationshipType.cousin,
        gender: Gender.male,
        fullName: 'ابن العمة',
      );
      final mapExt = {...relativesMap, patAuntId: patAunt, patAuntSonId: patAuntSon};

      final label = FamilyGraphService.getLabelForViewer(
        graph: extGraph,
        viewerId: userId,
        targetId: patAuntSonId,
        relativesMap: mapExt,
      );
      expect(label, 'ابن عمتي');
    });

    test('maternal uncle\'s daughter: parent(♀)→sibling(♂)→child(♀) = "بنت خالي"', () {
      // Mom(♀) has a brother (mat.uncle) who has a daughter
      const matUncleId = 'mat-uncle-1';
      const matUncleDauId = 'mat-uncle-dau';
      final extraEdges = [
        ...graph.edges,
        makeEdge(fromId: matUncleId, toId: motherId, type: EdgeType.siblingOf),
        makeEdge(fromId: matUncleId, toId: matUncleDauId, type: EdgeType.parentOf),
      ];
      final extGraph = FamilyGraphService.buildGraph(userId: userId, edges: extraEdges);
      final matUncle = makeRelative(
        id: matUncleId,
        type: RelationshipType.uncle,
        gender: Gender.male,
        fullName: 'الخال',
      );
      final matUncleDau = makeRelative(
        id: matUncleDauId,
        type: RelationshipType.cousin,
        gender: Gender.female,
        fullName: 'بنت الخال',
      );
      final mapExt = {...relativesMap, matUncleId: matUncle, matUncleDauId: matUncleDau};

      final label = FamilyGraphService.getLabelForViewer(
        graph: extGraph,
        viewerId: userId,
        targetId: matUncleDauId,
        relativesMap: mapExt,
      );
      expect(label, 'بنت خالي');
    });

    test('fallback returns fullName instead of arabicName', () {
      // For an unknown relationship path, should return fullName not arabicName
      final strangerRelative = Relative(
        id: 'stranger-1',
        userId: userId,
        fullName: 'أحمد',
        relationshipType: RelationshipType.other,
        gender: Gender.male,
        createdAt: DateTime(2025, 1, 1),
      );
      final mapWithStranger = {...relativesMap, 'stranger-1': strangerRelative};

      final label = FamilyGraphService.getLabelForViewer(
        graph: graph,
        viewerId: userId,
        targetId: 'stranger-1',
        relativesMap: mapWithStranger,
      );
      // Should return fullName 'أحمد', not arabicName 'أخرى'
      expect(label, 'أحمد');
    });
```

**Step 12: Run test to verify failures**

Run: `flutter test test/unit/services/family_graph_service_test.dart`
Expected: FAIL — missing sibling's child, cousin, great-grandparent label logic.

---

### Task 6: Extend `getLabelForViewer` with new label paths

**Files:**
- Modify: `lib/features/family_tree/services/family_graph_service.dart` — the `getLabelForViewer` method (lines 245–371)

**Step 13: Write the implementation**

Replace the `getLabelForViewer` method body. The key changes:
1. Add **sibling's child** check (priority 10-11) after uncle/aunt check
2. Add **cousin (4-way)** check (priority 14-17) after grandchild check
3. Add **great-grandparent** check (priority 18) after cousin check
4. **Fix fallback**: return `relative?.fullName ?? 'قريب'` instead of `target.relationshipType.arabicName`

Replace the entire `getLabelForViewer` method (lines 245–371) with:

```dart
  static String getLabelForViewer({
    required FamilyGraph graph,
    required String viewerId,
    required String targetId,
    required Map<String, Relative> relativesMap,
  }) {
    if (viewerId == targetId) return 'أنا';

    final target = relativesMap[targetId];
    final targetGender = target?.gender;

    // Check direct relationships first

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

    // Is target a parent's sibling? (uncle/aunt from viewer's perspective)
    for (final parentId in viewerParents) {
      final parentSiblings = graph.getSiblings(parentId);
      if (parentSiblings.contains(targetId)) {
        final parent = relativesMap[parentId];
        if (target != null && parent != null) {
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

    // Is target a sibling's child? (nephew/niece from viewer's perspective)
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

    // Is target a grandparent of viewer? (parent's parent)
    for (final parentId in viewerParents) {
      final grandparents = graph.getParents(parentId);
      if (grandparents.contains(targetId)) {
        if (targetGender == Gender.male) return 'جدي';
        if (targetGender == Gender.female) return 'جدتي';
        return 'جدي';
      }
    }

    // Is target a grandchild of viewer? (child's child)
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
          // 4-way: parentGender × parentSibGender
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
          // Fallback if genders unknown
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
```

**Step 14: Run test to verify it passes**

Run: `flutter test test/unit/services/family_graph_service_test.dart`
Expected: All new label tests PASS.

**Important:** The existing fallback test (`'fallback: returns arabicName for unknown graph path'`) will now fail because we changed the fallback from `arabicName` to `fullName`. Update it:

Find this test:
```dart
    test('fallback: returns arabicName for unknown graph path', () {
      final label = FamilyGraphService.getLabelForViewer(
        graph: graph,
        viewerId: 'stranger',
        targetId: fatherId,
        relativesMap: relativesMap,
      );
      // stranger has no edges, so falls back to father's relationshipType.arabicName
      expect(label, 'أب');
    });
```

Replace with:
```dart
    test('fallback: returns fullName for unknown graph path', () {
      final label = FamilyGraphService.getLabelForViewer(
        graph: graph,
        viewerId: 'stranger',
        targetId: fatherId,
        relativesMap: relativesMap,
      );
      // stranger has no edges, so falls back to father's fullName
      expect(label, 'الأب');
    });
```

**Step 15: Run tests again**

Run: `flutter test test/unit/services/family_graph_service_test.dart`
Expected: ALL tests PASS.

**Step 16: Commit**

```bash
git add lib/features/family_tree/services/family_graph_service.dart test/unit/services/family_graph_service_test.dart
git commit -m "feat: extend getLabelForViewer with cousin/nephew/great-grandparent labels and fix fallback"
```

---

### Task 7: Update `_enrichSiblingEdges` in layout service

**Files:**
- Modify: `lib/features/family_tree/services/family_tree_layout_service.dart` (lines 1019-1045)

**Step 17: Replace `_enrichSiblingEdges` body**

Replace the `_enrichSiblingEdges` method (lines 1019-1045) with a one-liner that delegates to the new global enrichment:

```dart
  /// Enrich sibling edges globally — delegates to FamilyGraphService.
  static FamilyGraph _enrichSiblingEdges(FamilyGraph graph, String userId) {
    return FamilyGraphService.enrichAllSiblingEdges(graph);
  }
```

**Step 18: Run full unit test suite**

Run: `flutter test test/unit/`
Expected: ALL tests PASS. The layout service tests should still work because `enrichAllSiblingEdges` is a superset of the old behavior.

**Step 19: Commit**

```bash
git add lib/features/family_tree/services/family_tree_layout_service.dart
git commit -m "refactor: delegate _enrichSiblingEdges to global FamilyGraphService.enrichAllSiblingEdges"
```

---

### Task 8: Add rahim scope filter in family tree screen

**Files:**
- Modify: `lib/features/family_tree/screens/family_tree_screen.dart` (inside `_buildTreeContent`, around line 665)

**Step 20: Add scope filtering for shared trees**

In `_buildTreeContent`, after computing `graph` (line 641) and before computing `relativesMap` (line 648), add the rahim scope filter. The modification replaces lines 648-675 approximately.

Find this block (around line 648):
```dart
    final relativesMap = {for (final r in relatives) r.id: r};
```

Replace with:
```dart
    // For shared trees, apply rahim scope filter so each viewer only
    // sees their blood relatives (plus direct spouse).
    final List<Relative> visibleRelatives;
    if (groupInfo != null && graph != null) {
      final enrichedGraph = FamilyGraphService.enrichAllSiblingEdges(graph);
      final rahimScope = FamilyGraphService.computeRahimScope(
        viewerId: effectiveUserId,
        graph: enrichedGraph,
      );
      visibleRelatives = relatives.where((r) => rahimScope.contains(r.id)).toList();
    } else {
      visibleRelatives = relatives;
    }

    final relativesMap = {for (final r in visibleRelatives) r.id: r};
```

Then update the `computeLayout` call to use `visibleRelatives` instead of `relatives` (line ~668):

Find:
```dart
          relatives: relatives,
```

Replace with:
```dart
          relatives: visibleRelatives,
```

**Step 21: Run full unit test suite**

Run: `flutter test test/unit/`
Expected: ALL tests PASS.

**Step 22: Commit**

```bash
git add lib/features/family_tree/screens/family_tree_screen.dart
git commit -m "feat: apply rahim scope filter for shared tree perspective rendering"
```

---

### Task 9: Full regression test

**Step 23: Run full unit test suite one final time**

Run: `flutter test test/unit/`
Expected: ALL tests PASS.

**Step 24: Final commit (if any fixups needed)**

If any tests failed in the final run and required fixups, commit those.

---

## Summary of Changes

| File | Change |
|------|--------|
| `lib/features/family_tree/services/family_graph_service.dart` | Add `enrichAllSiblingEdges()`, `computeRahimScope()`, extend `getLabelForViewer()` with 5 new label paths + fix fallback, add `_BfsDirection` enum |
| `lib/features/family_tree/services/family_tree_layout_service.dart` | Replace `_enrichSiblingEdges` body with delegation to `enrichAllSiblingEdges` |
| `lib/features/family_tree/screens/family_tree_screen.dart` | Add rahim scope filtering in `_buildTreeContent` for shared trees |
| `test/unit/services/family_graph_service_test.dart` | Add tests for `enrichAllSiblingEdges`, `computeRahimScope`, extended labels, fix fallback test |
