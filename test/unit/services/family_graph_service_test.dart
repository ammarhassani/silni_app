import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/features/family_tree/models/family_graph.dart';
import 'package:silni_app/features/family_tree/services/family_graph_service.dart';
import 'package:silni_app/shared/models/relative_model.dart';

/// Unit tests for FamilyGraphService and FamilyGraph.
///
/// Tests cover:
/// 1. Graph construction (buildGraph)
/// 2. Edge inference (inferEdges)
/// 3. Generation computation (getGeneration)
/// 4. Perspective-shifting labels (getLabelForViewer)
void main() {
  // -------------------------------------------------------------------------
  // Shared test IDs
  // -------------------------------------------------------------------------
  const userId = 'user-1';
  const fatherId = 'father-1';
  const motherId = 'mother-1';
  const brotherId = 'brother-1';
  const sisterId = 'sister-1';
  const sonId = 'son-1';
  const daughterId = 'daughter-1';
  const husbandId = 'husband-1';
  const wifeId = 'wife-1';
  const grandfatherId = 'grandfather-1';
  const grandmotherId = 'grandmother-1';
  const uncleId = 'uncle-1';
  const auntId = 'aunt-1';

  // -------------------------------------------------------------------------
  // Helper: create a Relative with minimal fields
  // -------------------------------------------------------------------------
  Relative makeRelative({
    required String id,
    required RelationshipType type,
    Gender? gender,
    String? fullName,
  }) {
    return Relative(
      id: id,
      userId: userId,
      fullName: fullName ?? 'Test ${type.arabicName}',
      relationshipType: type,
      gender: gender ?? (type == RelationshipType.mother ||
              type == RelationshipType.sister ||
              type == RelationshipType.daughter ||
              type == RelationshipType.wife ||
              type == RelationshipType.grandmother ||
              type == RelationshipType.aunt ||
              type == RelationshipType.niece
          ? Gender.female
          : Gender.male),
      createdAt: DateTime(2025, 1, 1),
    );
  }

  // -------------------------------------------------------------------------
  // Helper: create a FamilyEdge with deterministic id
  // -------------------------------------------------------------------------
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

  // =========================================================================
  // 1. buildGraph tests
  // =========================================================================
  group('FamilyGraphService.buildGraph', () {
    test('should build empty graph from no edges', () {
      final graph = FamilyGraphService.buildGraph(
        userId: userId,
        edges: [],
      );

      expect(graph.userId, userId);
      expect(graph.edges, isEmpty);
      expect(graph.getParents(userId), isEmpty);
      expect(graph.getChildren(userId), isEmpty);
      expect(graph.getSiblings(userId), isEmpty);
      expect(graph.getSpouse(userId), isNull);
    });

    test('should populate forward adjacency for parentOf edges', () {
      final edges = [
        makeEdge(fromId: fatherId, toId: userId, type: EdgeType.parentOf),
        makeEdge(fromId: motherId, toId: userId, type: EdgeType.parentOf),
      ];

      final graph = FamilyGraphService.buildGraph(
        userId: userId,
        edges: edges,
      );

      // Forward: fatherId -> [parentOf userId]
      expect(graph.getChildren(fatherId), contains(userId));
      expect(graph.getChildren(motherId), contains(userId));

      // Reverse: userId's parents
      expect(graph.getParents(userId), containsAll([fatherId, motherId]));
    });

    test('should populate sibling edges bidirectionally', () {
      final edges = [
        makeEdge(fromId: brotherId, toId: userId, type: EdgeType.siblingOf),
      ];

      final graph = FamilyGraphService.buildGraph(
        userId: userId,
        edges: edges,
      );

      // brotherId has an outgoing siblingOf to userId
      expect(graph.getSiblings(brotherId), contains(userId));
      // userId has an incoming siblingOf from brotherId
      expect(graph.getSiblings(userId), contains(brotherId));
    });

    test('should populate spouse edges bidirectionally', () {
      final edges = [
        makeEdge(fromId: userId, toId: wifeId, type: EdgeType.spouseOf),
      ];

      final graph = FamilyGraphService.buildGraph(
        userId: userId,
        edges: edges,
      );

      expect(graph.getSpouse(userId), wifeId);
      expect(graph.getSpouse(wifeId), userId);
    });

    test('should handle a full family graph', () {
      final edges = [
        // Parents
        makeEdge(fromId: fatherId, toId: userId, type: EdgeType.parentOf),
        makeEdge(fromId: motherId, toId: userId, type: EdgeType.parentOf),
        // Siblings
        makeEdge(fromId: brotherId, toId: userId, type: EdgeType.siblingOf),
        makeEdge(fromId: sisterId, toId: userId, type: EdgeType.siblingOf),
        // Children
        makeEdge(fromId: userId, toId: sonId, type: EdgeType.parentOf),
        makeEdge(fromId: userId, toId: daughterId, type: EdgeType.parentOf),
        // Spouse
        makeEdge(fromId: userId, toId: wifeId, type: EdgeType.spouseOf),
        // Grandparents
        makeEdge(
            fromId: grandfatherId, toId: fatherId, type: EdgeType.parentOf),
        // Uncle (father's sibling)
        makeEdge(fromId: uncleId, toId: fatherId, type: EdgeType.siblingOf),
      ];

      final graph = FamilyGraphService.buildGraph(
        userId: userId,
        edges: edges,
      );

      expect(graph.getParents(userId), hasLength(2));
      expect(graph.getSiblings(userId), hasLength(2));
      expect(graph.getChildren(userId), hasLength(2));
      expect(graph.getSpouse(userId), wifeId);
      expect(graph.getParents(fatherId), contains(grandfatherId));
      expect(graph.getSiblings(fatherId), contains(uncleId));
    });

    test('should make edges list unmodifiable', () {
      final edges = [
        makeEdge(fromId: fatherId, toId: userId, type: EdgeType.parentOf),
      ];

      final graph = FamilyGraphService.buildGraph(
        userId: userId,
        edges: edges,
      );

      expect(
        () => graph.edges.add(
          makeEdge(fromId: motherId, toId: userId, type: EdgeType.parentOf),
        ),
        throwsUnsupportedError,
      );
    });
  });

  // =========================================================================
  // 2. inferEdges tests
  // =========================================================================
  group('FamilyGraphService.inferEdges', () {
    test('should infer parentOf edge when adding father', () {
      final edges = FamilyGraphService.inferEdges(
        userId: userId,
        newRelativeId: fatherId,
        relationshipType: RelationshipType.father,
        existingEdges: [],
        existingRelatives: [],
      );

      expect(edges, hasLength(1));
      expect(edges.first.fromId, fatherId);
      expect(edges.first.toId, userId);
      expect(edges.first.type, EdgeType.parentOf);
    });

    test('should infer parentOf edge when adding mother', () {
      final edges = FamilyGraphService.inferEdges(
        userId: userId,
        newRelativeId: motherId,
        relationshipType: RelationshipType.mother,
        existingEdges: [],
        existingRelatives: [],
      );

      expect(edges, hasLength(1));
      expect(edges.first.fromId, motherId);
      expect(edges.first.toId, userId);
      expect(edges.first.type, EdgeType.parentOf);
    });

    test('should infer siblingOf edge when adding brother', () {
      final edges = FamilyGraphService.inferEdges(
        userId: userId,
        newRelativeId: brotherId,
        relationshipType: RelationshipType.brother,
        existingEdges: [],
        existingRelatives: [],
      );

      expect(edges, hasLength(1));
      expect(edges.first.fromId, brotherId);
      expect(edges.first.toId, userId);
      expect(edges.first.type, EdgeType.siblingOf);
    });

    test('should infer siblingOf edge when adding sister', () {
      final edges = FamilyGraphService.inferEdges(
        userId: userId,
        newRelativeId: sisterId,
        relationshipType: RelationshipType.sister,
        existingEdges: [],
        existingRelatives: [],
      );

      expect(edges, hasLength(1));
      expect(edges.first.type, EdgeType.siblingOf);
    });

    test('should infer parentOf edge from user when adding son', () {
      final edges = FamilyGraphService.inferEdges(
        userId: userId,
        newRelativeId: sonId,
        relationshipType: RelationshipType.son,
        existingEdges: [],
        existingRelatives: [],
      );

      expect(edges, hasLength(1));
      expect(edges.first.fromId, userId);
      expect(edges.first.toId, sonId);
      expect(edges.first.type, EdgeType.parentOf);
    });

    test('should infer parentOf edge from user when adding daughter', () {
      final edges = FamilyGraphService.inferEdges(
        userId: userId,
        newRelativeId: daughterId,
        relationshipType: RelationshipType.daughter,
        existingEdges: [],
        existingRelatives: [],
      );

      expect(edges, hasLength(1));
      expect(edges.first.fromId, userId);
      expect(edges.first.toId, daughterId);
      expect(edges.first.type, EdgeType.parentOf);
    });

    test('should infer spouseOf edge when adding wife', () {
      final edges = FamilyGraphService.inferEdges(
        userId: userId,
        newRelativeId: wifeId,
        relationshipType: RelationshipType.wife,
        existingEdges: [],
        existingRelatives: [],
      );

      expect(edges, hasLength(1));
      expect(edges.first.fromId, userId);
      expect(edges.first.toId, wifeId);
      expect(edges.first.type, EdgeType.spouseOf);
    });

    test('should infer spouseOf edge when adding husband', () {
      final edges = FamilyGraphService.inferEdges(
        userId: userId,
        newRelativeId: husbandId,
        relationshipType: RelationshipType.husband,
        existingEdges: [],
        existingRelatives: [],
      );

      expect(edges, hasLength(1));
      expect(edges.first.fromId, userId);
      expect(edges.first.toId, husbandId);
      expect(edges.first.type, EdgeType.spouseOf);
    });

    test('should infer parentOf edge from grandfather to father', () {
      final father = makeRelative(
        id: fatherId,
        type: RelationshipType.father,
      );

      final edges = FamilyGraphService.inferEdges(
        userId: userId,
        newRelativeId: grandfatherId,
        relationshipType: RelationshipType.grandfather,
        existingEdges: [],
        existingRelatives: [father],
      );

      expect(edges, hasLength(1));
      expect(edges.first.fromId, grandfatherId);
      expect(edges.first.toId, fatherId);
      expect(edges.first.type, EdgeType.parentOf);
    });

    test('should infer parentOf edge from grandmother to mother when maternal side', () {
      final mother = makeRelative(
        id: motherId,
        type: RelationshipType.mother,
      );

      final edges = FamilyGraphService.inferEdges(
        userId: userId,
        newRelativeId: grandmotherId,
        relationshipType: RelationshipType.grandmother,
        side: FamilySide.maternal,
        existingEdges: [],
        existingRelatives: [mother],
      );

      expect(edges, hasLength(1));
      expect(edges.first.fromId, grandmotherId);
      expect(edges.first.toId, motherId);
      expect(edges.first.type, EdgeType.parentOf);
    });

    test('should NOT link maternal grandmother to father when mother is missing', () {
      // Regression: maternal grandmother used to fall back to father
      // when the mother hadn't been added yet.
      final father = makeRelative(
        id: fatherId,
        type: RelationshipType.father,
      );

      final edges = FamilyGraphService.inferEdges(
        userId: userId,
        newRelativeId: grandmotherId,
        relationshipType: RelationshipType.grandmother,
        side: FamilySide.maternal,
        existingEdges: [],
        existingRelatives: [father], // only father, no mother
      );

      // Should return empty — not incorrectly link to father.
      expect(edges, isEmpty);
    });

    test('should NOT link paternal grandfather to mother when father is missing', () {
      final mother = makeRelative(
        id: motherId,
        type: RelationshipType.mother,
      );

      final edges = FamilyGraphService.inferEdges(
        userId: userId,
        newRelativeId: grandfatherId,
        relationshipType: RelationshipType.grandfather,
        side: FamilySide.paternal,
        existingEdges: [],
        existingRelatives: [mother], // only mother, no father
      );

      expect(edges, isEmpty);
    });

    test('should return empty edges for grandfather when no parent exists', () {
      final edges = FamilyGraphService.inferEdges(
        userId: userId,
        newRelativeId: grandfatherId,
        relationshipType: RelationshipType.grandfather,
        existingEdges: [],
        existingRelatives: [],
      );

      expect(edges, isEmpty);
    });

    test('should infer siblingOf edge between uncle and father (paternal)', () {
      final father = makeRelative(
        id: fatherId,
        type: RelationshipType.father,
      );

      final edges = FamilyGraphService.inferEdges(
        userId: userId,
        newRelativeId: uncleId,
        relationshipType: RelationshipType.uncle,
        side: FamilySide.paternal,
        existingEdges: [],
        existingRelatives: [father],
      );

      expect(edges, hasLength(1));
      expect(edges.first.fromId, uncleId);
      expect(edges.first.toId, fatherId);
      expect(edges.first.type, EdgeType.siblingOf);
    });

    test('should infer siblingOf edge between aunt and mother (maternal)', () {
      final mother = makeRelative(
        id: motherId,
        type: RelationshipType.mother,
      );

      final edges = FamilyGraphService.inferEdges(
        userId: userId,
        newRelativeId: auntId,
        relationshipType: RelationshipType.aunt,
        side: FamilySide.maternal,
        existingEdges: [],
        existingRelatives: [mother],
      );

      expect(edges, hasLength(1));
      expect(edges.first.fromId, auntId);
      expect(edges.first.toId, motherId);
      expect(edges.first.type, EdgeType.siblingOf);
    });

    test('should return empty edges for uncle when no father exists (paternal)', () {
      final edges = FamilyGraphService.inferEdges(
        userId: userId,
        newRelativeId: uncleId,
        relationshipType: RelationshipType.uncle,
        side: FamilySide.paternal,
        existingEdges: [],
        existingRelatives: [],
      );

      expect(edges, isEmpty);
    });

    test('should return empty edges for RelationshipType.other', () {
      final edges = FamilyGraphService.inferEdges(
        userId: userId,
        newRelativeId: 'other-1',
        relationshipType: RelationshipType.other,
        existingEdges: [],
        existingRelatives: [],
      );

      expect(edges, isEmpty);
    });

    test('should infer nephew as child of sibling', () {
      final brother = makeRelative(
        id: brotherId,
        type: RelationshipType.brother,
      );

      final edges = FamilyGraphService.inferEdges(
        userId: userId,
        newRelativeId: 'nephew-1',
        relationshipType: RelationshipType.nephew,
        existingEdges: [],
        existingRelatives: [brother],
      );

      expect(edges, hasLength(1));
      expect(edges.first.fromId, brotherId);
      expect(edges.first.toId, 'nephew-1');
      expect(edges.first.type, EdgeType.parentOf);
    });

    test('should infer cousin as child of uncle/aunt', () {
      final uncle = makeRelative(
        id: uncleId,
        type: RelationshipType.uncle,
      );

      final edges = FamilyGraphService.inferEdges(
        userId: userId,
        newRelativeId: 'cousin-1',
        relationshipType: RelationshipType.cousin,
        existingEdges: [],
        existingRelatives: [uncle],
      );

      expect(edges, hasLength(1));
      expect(edges.first.fromId, uncleId);
      expect(edges.first.toId, 'cousin-1');
      expect(edges.first.type, EdgeType.parentOf);
    });
  });

  // =========================================================================
  // 3. getGeneration tests
  // =========================================================================
  group('FamilyGraph.getGeneration', () {
    test('should return 0 for the user', () {
      final graph = FamilyGraphService.buildGraph(
        userId: userId,
        edges: [],
      );

      expect(graph.getGeneration(userId), 0);
    });

    test('should return -1 for parents', () {
      final edges = [
        makeEdge(fromId: fatherId, toId: userId, type: EdgeType.parentOf),
        makeEdge(fromId: motherId, toId: userId, type: EdgeType.parentOf),
      ];

      final graph = FamilyGraphService.buildGraph(
        userId: userId,
        edges: edges,
      );

      expect(graph.getGeneration(fatherId), -1);
      expect(graph.getGeneration(motherId), -1);
    });

    test('should return -2 for grandparents', () {
      final edges = [
        makeEdge(fromId: fatherId, toId: userId, type: EdgeType.parentOf),
        makeEdge(
            fromId: grandfatherId, toId: fatherId, type: EdgeType.parentOf),
      ];

      final graph = FamilyGraphService.buildGraph(
        userId: userId,
        edges: edges,
      );

      expect(graph.getGeneration(grandfatherId), -2);
    });

    test('should return +1 for children', () {
      final edges = [
        makeEdge(fromId: userId, toId: sonId, type: EdgeType.parentOf),
        makeEdge(fromId: userId, toId: daughterId, type: EdgeType.parentOf),
      ];

      final graph = FamilyGraphService.buildGraph(
        userId: userId,
        edges: edges,
      );

      expect(graph.getGeneration(sonId), 1);
      expect(graph.getGeneration(daughterId), 1);
    });

    test('should return 0 for siblings', () {
      final edges = [
        makeEdge(fromId: brotherId, toId: userId, type: EdgeType.siblingOf),
      ];

      final graph = FamilyGraphService.buildGraph(
        userId: userId,
        edges: edges,
      );

      expect(graph.getGeneration(brotherId), 0);
    });

    test('should return 0 for spouse', () {
      final edges = [
        makeEdge(fromId: userId, toId: wifeId, type: EdgeType.spouseOf),
      ];

      final graph = FamilyGraphService.buildGraph(
        userId: userId,
        edges: edges,
      );

      expect(graph.getGeneration(wifeId), 0);
    });

    test('should return -1 for uncle (father\'s sibling)', () {
      final edges = [
        makeEdge(fromId: fatherId, toId: userId, type: EdgeType.parentOf),
        makeEdge(fromId: uncleId, toId: fatherId, type: EdgeType.siblingOf),
      ];

      final graph = FamilyGraphService.buildGraph(
        userId: userId,
        edges: edges,
      );

      // Uncle is sibling of father, so same generation as father = -1
      expect(graph.getGeneration(uncleId), -1);
    });

    test('should return 0 for unreachable nodes (defensive)', () {
      final edges = [
        makeEdge(fromId: fatherId, toId: userId, type: EdgeType.parentOf),
      ];

      final graph = FamilyGraphService.buildGraph(
        userId: userId,
        edges: edges,
      );

      // 'stranger' has no edges connecting it to the graph
      expect(graph.getGeneration('stranger'), 0);
    });

    test('should handle deep genealogy (great-grandparent)', () {
      const greatGrandfatherId = 'great-grandfather-1';
      final edges = [
        makeEdge(fromId: fatherId, toId: userId, type: EdgeType.parentOf),
        makeEdge(
            fromId: grandfatherId, toId: fatherId, type: EdgeType.parentOf),
        makeEdge(
            fromId: greatGrandfatherId,
            toId: grandfatherId,
            type: EdgeType.parentOf),
      ];

      final graph = FamilyGraphService.buildGraph(
        userId: userId,
        edges: edges,
      );

      expect(graph.getGeneration(greatGrandfatherId), -3);
    });

    test('should handle grandchildren (generation +2)', () {
      const grandsonId = 'grandson-1';
      final edges = [
        makeEdge(fromId: userId, toId: sonId, type: EdgeType.parentOf),
        makeEdge(fromId: sonId, toId: grandsonId, type: EdgeType.parentOf),
      ];

      final graph = FamilyGraphService.buildGraph(
        userId: userId,
        edges: edges,
      );

      expect(graph.getGeneration(grandsonId), 2);
    });
  });

  // =========================================================================
  // 4. getLabelForViewer tests
  // =========================================================================
  group('FamilyGraphService.getLabelForViewer', () {
    late FamilyGraph graph;
    late Map<String, Relative> relativesMap;

    setUp(() {
      final edges = [
        // Parents
        makeEdge(fromId: fatherId, toId: userId, type: EdgeType.parentOf),
        makeEdge(fromId: motherId, toId: userId, type: EdgeType.parentOf),
        // Siblings
        makeEdge(fromId: brotherId, toId: userId, type: EdgeType.siblingOf),
        makeEdge(fromId: sisterId, toId: userId, type: EdgeType.siblingOf),
        // Children
        makeEdge(fromId: userId, toId: sonId, type: EdgeType.parentOf),
        makeEdge(fromId: userId, toId: daughterId, type: EdgeType.parentOf),
        // Spouse
        makeEdge(fromId: userId, toId: wifeId, type: EdgeType.spouseOf),
        // Grandparent
        makeEdge(
            fromId: grandfatherId, toId: fatherId, type: EdgeType.parentOf),
        // Uncle (father's sibling)
        makeEdge(fromId: uncleId, toId: fatherId, type: EdgeType.siblingOf),
        // Aunt (mother's sibling)
        makeEdge(fromId: auntId, toId: motherId, type: EdgeType.siblingOf),
      ];

      graph = FamilyGraphService.buildGraph(userId: userId, edges: edges);

      final father = makeRelative(
        id: fatherId,
        type: RelationshipType.father,
        gender: Gender.male,
        fullName: 'الأب',
      );
      final mother = makeRelative(
        id: motherId,
        type: RelationshipType.mother,
        gender: Gender.female,
        fullName: 'الأم',
      );
      final brother = makeRelative(
        id: brotherId,
        type: RelationshipType.brother,
        gender: Gender.male,
        fullName: 'الأخ',
      );
      final sister = makeRelative(
        id: sisterId,
        type: RelationshipType.sister,
        gender: Gender.female,
        fullName: 'الأخت',
      );
      final son = makeRelative(
        id: sonId,
        type: RelationshipType.son,
        gender: Gender.male,
        fullName: 'الابن',
      );
      final daughter = makeRelative(
        id: daughterId,
        type: RelationshipType.daughter,
        gender: Gender.female,
        fullName: 'الابنة',
      );
      final wife = makeRelative(
        id: wifeId,
        type: RelationshipType.wife,
        gender: Gender.female,
        fullName: 'الزوجة',
      );
      final grandfather = makeRelative(
        id: grandfatherId,
        type: RelationshipType.grandfather,
        gender: Gender.male,
        fullName: 'الجد',
      );
      final uncle = makeRelative(
        id: uncleId,
        type: RelationshipType.uncle,
        gender: Gender.male,
        fullName: 'العم',
      );
      final aunt = makeRelative(
        id: auntId,
        type: RelationshipType.aunt,
        gender: Gender.female,
        fullName: 'الخالة',
      );

      relativesMap = {
        fatherId: father,
        motherId: mother,
        brotherId: brother,
        sisterId: sister,
        sonId: son,
        daughterId: daughter,
        wifeId: wife,
        grandfatherId: grandfather,
        uncleId: uncle,
        auntId: aunt,
      };
    });

    test('viewer is target -> "أنا"', () {
      final label = FamilyGraphService.getLabelForViewer(
        graph: graph,
        viewerId: userId,
        targetId: userId,
        relativesMap: relativesMap,
      );
      expect(label, 'أنا');
    });

    test('viewer\'s father -> "أبي"', () {
      final label = FamilyGraphService.getLabelForViewer(
        graph: graph,
        viewerId: userId,
        targetId: fatherId,
        relativesMap: relativesMap,
      );
      expect(label, 'أبي');
    });

    test('viewer\'s mother -> "أمي"', () {
      final label = FamilyGraphService.getLabelForViewer(
        graph: graph,
        viewerId: userId,
        targetId: motherId,
        relativesMap: relativesMap,
      );
      expect(label, 'أمي');
    });

    test('viewer\'s brother -> "أخوي"', () {
      final label = FamilyGraphService.getLabelForViewer(
        graph: graph,
        viewerId: userId,
        targetId: brotherId,
        relativesMap: relativesMap,
      );
      expect(label, 'أخوي');
    });

    test('viewer\'s sister -> "أختي"', () {
      final label = FamilyGraphService.getLabelForViewer(
        graph: graph,
        viewerId: userId,
        targetId: sisterId,
        relativesMap: relativesMap,
      );
      expect(label, 'أختي');
    });

    test('viewer\'s son -> "ابني"', () {
      final label = FamilyGraphService.getLabelForViewer(
        graph: graph,
        viewerId: userId,
        targetId: sonId,
        relativesMap: relativesMap,
      );
      expect(label, 'ابني');
    });

    test('viewer\'s daughter -> "ابنتي"', () {
      final label = FamilyGraphService.getLabelForViewer(
        graph: graph,
        viewerId: userId,
        targetId: daughterId,
        relativesMap: relativesMap,
      );
      expect(label, 'ابنتي');
    });

    test('viewer\'s wife -> "زوجتي"', () {
      final label = FamilyGraphService.getLabelForViewer(
        graph: graph,
        viewerId: userId,
        targetId: wifeId,
        relativesMap: relativesMap,
      );
      expect(label, 'زوجتي');
    });

    test('viewer\'s paternal uncle (father\'s brother) -> "عمي"', () {
      final label = FamilyGraphService.getLabelForViewer(
        graph: graph,
        viewerId: userId,
        targetId: uncleId,
        relativesMap: relativesMap,
      );
      expect(label, 'عمي');
    });

    test('viewer\'s maternal aunt (mother\'s sister) -> "خالتي"', () {
      final label = FamilyGraphService.getLabelForViewer(
        graph: graph,
        viewerId: userId,
        targetId: auntId,
        relativesMap: relativesMap,
      );
      expect(label, 'خالتي');
    });

    test('viewer\'s grandfather -> "جدي"', () {
      final label = FamilyGraphService.getLabelForViewer(
        graph: graph,
        viewerId: userId,
        targetId: grandfatherId,
        relativesMap: relativesMap,
      );
      expect(label, 'جدي');
    });

    test('perspective shift: from son\'s perspective, user is "أبي"', () {
      // We need the user in the relativesMap as a male relative
      final userRelative = Relative(
        id: userId,
        userId: userId,
        fullName: 'أنا',
        relationshipType: RelationshipType.other,
        gender: Gender.male,
        createdAt: DateTime(2025, 1, 1),
      );
      final mapWithUser = {...relativesMap, userId: userRelative};

      final label = FamilyGraphService.getLabelForViewer(
        graph: graph,
        viewerId: sonId,
        targetId: userId,
        relativesMap: mapWithUser,
      );
      expect(label, 'أبي');
    });

    test('perspective shift: from son\'s perspective, brother is "عمي" (paternal uncle)', () {
      // Son's view: father (userId) has a sibling (brotherId)
      // -> brotherId is son's paternal uncle
      // We need userId to be male in the map
      final userRelative = Relative(
        id: userId,
        userId: userId,
        fullName: 'أنا',
        relationshipType: RelationshipType.other,
        gender: Gender.male,
        createdAt: DateTime(2025, 1, 1),
      );
      final mapWithUser = {...relativesMap, userId: userRelative};

      final label = FamilyGraphService.getLabelForViewer(
        graph: graph,
        viewerId: sonId,
        targetId: brotherId,
        relativesMap: mapWithUser,
      );
      // brotherId is sibling of userId, and userId is parent of sonId
      // userId is male, so brotherId from son's perspective is عمي (paternal uncle)
      expect(label, 'عمي');
    });

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

    test('fallback: returns empty string for unknown target', () {
      final label = FamilyGraphService.getLabelForViewer(
        graph: graph,
        viewerId: userId,
        targetId: 'unknown',
        relativesMap: relativesMap,
      );
      expect(label, '');
    });
  });

  // =========================================================================
  // 5. FamilyEdge model tests
  // =========================================================================
  group('FamilyEdge', () {
    test('equality is based on fromId, toId, and type', () {
      final edge1 = FamilyEdge(
        id: 'id-1',
        userId: userId,
        fromId: fatherId,
        toId: userId,
        type: EdgeType.parentOf,
        createdAt: DateTime(2025, 1, 1),
      );
      final edge2 = FamilyEdge(
        id: 'id-2', // different id
        userId: userId,
        fromId: fatherId,
        toId: userId,
        type: EdgeType.parentOf,
        createdAt: DateTime(2025, 6, 1), // different date
      );

      expect(edge1, equals(edge2));
      expect(edge1.hashCode, equals(edge2.hashCode));
    });

    test('edges with different types are not equal', () {
      final edge1 = makeEdge(
          fromId: fatherId, toId: userId, type: EdgeType.parentOf);
      final edge2 = makeEdge(
          fromId: fatherId, toId: userId, type: EdgeType.siblingOf);

      expect(edge1, isNot(equals(edge2)));
    });

    test('fromJson and toJson round-trip', () {
      final original = FamilyEdge(
        id: 'test-id',
        userId: userId,
        fromId: fatherId,
        toId: userId,
        type: EdgeType.parentOf,
        createdAt: DateTime.utc(2025, 1, 15, 10, 30),
      );

      final json = original.toJson();
      final restored = FamilyEdge.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.fromId, original.fromId);
      expect(restored.toId, original.toId);
      expect(restored.type, original.type);
      expect(restored.createdAt, original.createdAt);
    });

    test('create factory generates a UUID', () {
      final edge = FamilyEdge.create(
        userId: userId,
        fromId: fatherId,
        toId: userId,
        type: EdgeType.parentOf,
      );

      expect(edge.id, isNotEmpty);
      expect(edge.id.length, 36); // UUID v4 format
      expect(edge.userId, userId);
    });
  });

  // =========================================================================
  // 6. EdgeType tests
  // =========================================================================
  group('EdgeType', () {
    test('fromString returns correct enum value', () {
      expect(EdgeType.fromString('parent_of'), EdgeType.parentOf);
      expect(EdgeType.fromString('sibling_of'), EdgeType.siblingOf);
      expect(EdgeType.fromString('spouse_of'), EdgeType.spouseOf);
    });

    test('fromString returns parentOf as fallback for unknown values', () {
      expect(EdgeType.fromString('unknown'), EdgeType.parentOf);
    });

    test('value matches expected string', () {
      expect(EdgeType.parentOf.value, 'parent_of');
      expect(EdgeType.siblingOf.value, 'sibling_of');
      expect(EdgeType.spouseOf.value, 'spouse_of');
    });
  });

  // =========================================================================
  // 7. FamilyGraph.containsNode tests
  // =========================================================================
  group('FamilyGraph.containsNode', () {
    test('returns true for nodes in the graph', () {
      final edges = [
        makeEdge(fromId: fatherId, toId: userId, type: EdgeType.parentOf),
      ];

      final graph = FamilyGraphService.buildGraph(
        userId: userId,
        edges: edges,
      );

      expect(graph.containsNode(fatherId), isTrue);
      expect(graph.containsNode(userId), isTrue);
    });

    test('returns false for nodes not in the graph', () {
      final graph = FamilyGraphService.buildGraph(
        userId: userId,
        edges: [],
      );

      expect(graph.containsNode('stranger'), isFalse);
    });
  });

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
      // Grandpa→Dad, Grandma→Dad (both parents), Grandpa↔Grandma (spouse), Uncle↔Dad (sibling)
      // Expected: Grandpa→Uncle AND Grandma→Uncle
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
}
