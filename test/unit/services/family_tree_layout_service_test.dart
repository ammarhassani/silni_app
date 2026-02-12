import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/features/family_tree/models/family_graph.dart';
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
    FamilySide? familySide,
  }) {
    return Relative(
      id: id,
      userId: userId,
      fullName: 'Test ${type.arabicName}',
      relationshipType: type,
      gender: gender ?? Gender.male,
      priority: priority,
      familySide: familySide,
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
      expect(fatherNode.position.dy, closeTo(motherNode.position.dy, 7));
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

      // Same generation = same y (within organic jitter tolerance)
      expect(uncleNode.position.dy, closeTo(fatherNode.position.dy, 7));
    });

    test('uncle positioned close to father (sibling cohesion)', () {
      // When father is centered over his children (user + siblings),
      // uncle (father's sibling with no children) should be pulled
      // adjacent to father, not stranded far away.
      final brother1Id = 'brother-1';
      final brother2Id = 'brother-2';
      final edges = [
        makeEdge(fromId: fatherId, toId: userId, type: EdgeType.parentOf),
        makeEdge(fromId: fatherId, toId: brother1Id, type: EdgeType.parentOf),
        makeEdge(fromId: fatherId, toId: brother2Id, type: EdgeType.parentOf),
        makeEdge(fromId: uncleId, toId: fatherId, type: EdgeType.siblingOf),
      ];
      final father =
          makeRelative(id: fatherId, type: RelationshipType.father);
      final uncle = makeRelative(id: uncleId, type: RelationshipType.uncle);
      final bro1 =
          makeRelative(id: brother1Id, type: RelationshipType.brother);
      final bro2 =
          makeRelative(id: brother2Id, type: RelationshipType.brother);
      final graph =
          FamilyGraphService.buildGraph(userId: userId, edges: edges);

      final layout = FamilyTreeLayoutService.computeLayout(
        userId: userId,
        userName: 'محمد',
        graph: graph,
        relatives: [father, uncle, bro1, bro2],
        relativesMap: {
          fatherId: father,
          uncleId: uncle,
          brother1Id: bro1,
          brother2Id: bro2,
        },
        canvasSize: const Size(600, 800),
        horizontalSpacing: 105,
      );

      final fatherNode = layout.nodes.firstWhere((n) => n.id == fatherId);
      final uncleNode = layout.nodes.firstWhere((n) => n.id == uncleId);

      // Uncle should be within 2x horizontalSpacing of father
      final distance =
          (uncleNode.position.dx - fatherNode.position.dx).abs();
      expect(distance, lessThanOrEqualTo(210)); // 2 * 105
    });

    test('paternal uncle goes LEFT of father, maternal aunt goes RIGHT of mother',
        () {
      final auntId = 'aunt-1';
      final edges = [
        makeEdge(fromId: fatherId, toId: userId, type: EdgeType.parentOf),
        makeEdge(fromId: motherId, toId: userId, type: EdgeType.parentOf),
        makeEdge(fromId: fatherId, toId: motherId, type: EdgeType.spouseOf),
        makeEdge(fromId: uncleId, toId: fatherId, type: EdgeType.siblingOf),
        makeEdge(fromId: auntId, toId: motherId, type: EdgeType.siblingOf),
      ];
      final father =
          makeRelative(id: fatherId, type: RelationshipType.father);
      final mother = makeRelative(
          id: motherId, type: RelationshipType.mother, gender: Gender.female);
      final uncle = makeRelative(
          id: uncleId,
          type: RelationshipType.uncle,
          familySide: FamilySide.paternal);
      final aunt = makeRelative(
          id: auntId,
          type: RelationshipType.aunt,
          gender: Gender.female,
          familySide: FamilySide.maternal);
      final graph =
          FamilyGraphService.buildGraph(userId: userId, edges: edges);

      final layout = FamilyTreeLayoutService.computeLayout(
        userId: userId,
        userName: 'محمد',
        graph: graph,
        relatives: [father, mother, uncle, aunt],
        relativesMap: {
          fatherId: father,
          motherId: mother,
          uncleId: uncle,
          auntId: aunt,
        },
        canvasSize: const Size(400, 600),
      );

      final fatherNode = layout.nodes.firstWhere((n) => n.id == fatherId);
      final motherNode = layout.nodes.firstWhere((n) => n.id == motherId);
      final uncleNode = layout.nodes.firstWhere((n) => n.id == uncleId);
      final auntNode = layout.nodes.firstWhere((n) => n.id == auntId);

      // Paternal uncle should be to the LEFT of father
      expect(uncleNode.position.dx, lessThan(fatherNode.position.dx));
      // Maternal aunt should be to the RIGHT of mother
      expect(auntNode.position.dx, greaterThan(motherNode.position.dx));
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

      // Same generation = same y (within organic jitter tolerance)
      expect(cousinNode.position.dy, closeTo(userNode.position.dy, 7));
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

      expect(wifeNode.position.dy, closeTo(userNode.position.dy, 7));
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

    // -----------------------------------------------------------------------
    // Placeholder positioning tests
    // -----------------------------------------------------------------------

    test('empty tree layout includes father + mother + spouse placeholders', () {
      final layout = FamilyTreeLayoutService.computeLayout(
        userId: userId,
        userName: 'أحمد',
        graph: null,
        relatives: [],
        relativesMap: {},
        canvasSize: const Size(400, 600),
        userGender: Gender.male,
      );

      // father, mother, wife placeholders
      expect(layout.placeholders, hasLength(3));
      final types = layout.placeholders.map((p) => p.type).toSet();
      expect(types, contains(RelationshipType.father));
      expect(types, contains(RelationshipType.mother));
      expect(types, contains(RelationshipType.wife));
    });

    test('parent placeholders positioned above user', () {
      final layout = FamilyTreeLayoutService.computeLayout(
        userId: userId,
        userName: 'أحمد',
        graph: null,
        relatives: [],
        relativesMap: {},
        canvasSize: const Size(400, 600),
        userGender: Gender.male,
      );

      final userNode = layout.nodes.first;
      final fatherPh = layout.placeholders
          .firstWhere((p) => p.type == RelationshipType.father);
      final motherPh = layout.placeholders
          .firstWhere((p) => p.type == RelationshipType.mother);

      // Parents above user
      expect(fatherPh.position.dy, lessThan(userNode.position.dy));
      expect(motherPh.position.dy, lessThan(userNode.position.dy));
    });

    test('spouse placeholder at same y as user', () {
      final layout = FamilyTreeLayoutService.computeLayout(
        userId: userId,
        userName: 'أحمد',
        graph: null,
        relatives: [],
        relativesMap: {},
        canvasSize: const Size(400, 600),
        userGender: Gender.male,
      );

      final userNode = layout.nodes.first;
      final wifePh = layout.placeholders
          .firstWhere((p) => p.type == RelationshipType.wife);

      expect(wifePh.position.dy, closeTo(userNode.position.dy, 1));
    });

    test('adding father spawns positioned paternal branch placeholders', () {
      final father = makeRelative(id: fatherId, type: RelationshipType.father);
      final edges = [
        makeEdge(fromId: fatherId, toId: userId, type: EdgeType.parentOf),
      ];
      final graph =
          FamilyGraphService.buildGraph(userId: userId, edges: edges);

      final layout = FamilyTreeLayoutService.computeLayout(
        userId: userId,
        userName: 'أحمد',
        graph: graph,
        relatives: [father],
        relativesMap: {fatherId: father},
        canvasSize: const Size(600, 800),
        userGender: Gender.male,
      );

      // Should have: mother, sibling, paternal grandparents,
      // paternal uncle, paternal aunt, spouse
      final types = layout.placeholders.map((p) => p.type).toList();
      expect(types, contains(RelationshipType.mother));
      expect(types, contains(RelationshipType.grandfather));
      expect(types, contains(RelationshipType.grandmother));
      expect(types, contains(RelationshipType.uncle));

      // All placeholders should have non-zero positions
      for (final ph in layout.placeholders) {
        expect(ph.position, isNot(Offset.zero));
      }
    });

    test('placeholder bounds include placeholder positions', () {
      final layout = FamilyTreeLayoutService.computeLayout(
        userId: userId,
        userName: 'أحمد',
        graph: null,
        relatives: [],
        relativesMap: {},
        canvasSize: const Size(400, 600),
        userGender: Gender.male,
      );

      // Bounds should encompass all placeholder positions
      for (final ph in layout.placeholders) {
        expect(layout.bounds.contains(ph.position), isTrue);
      }
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

    test('shared tree: no duplicate node when userId matches a relative', () {
      // Simulates a shared tree where the viewer's relative_id_in_tree
      // matches one of the relatives in the shared list.
      const viewerId = 'viewer-node';
      const siblingId = 'sibling-node';

      final edges = [
        makeEdge(fromId: fatherId, toId: viewerId, type: EdgeType.parentOf),
        makeEdge(fromId: motherId, toId: viewerId, type: EdgeType.parentOf),
        makeEdge(fromId: fatherId, toId: siblingId, type: EdgeType.parentOf),
        makeEdge(fromId: motherId, toId: siblingId, type: EdgeType.parentOf),
        makeEdge(
            fromId: viewerId, toId: siblingId, type: EdgeType.siblingOf),
      ];

      final viewerRelative = makeRelative(
        id: viewerId,
        type: RelationshipType.brother,
      );
      final sibling = makeRelative(
        id: siblingId,
        type: RelationshipType.brother,
      );
      final father =
          makeRelative(id: fatherId, type: RelationshipType.father);
      final mother = makeRelative(
        id: motherId,
        type: RelationshipType.mother,
        gender: Gender.female,
      );

      // Include the viewer's own relative record in the list (shared tree)
      final relatives = [viewerRelative, sibling, father, mother];
      final relativesMap = {for (final r in relatives) r.id: r};

      final graph =
          FamilyGraphService.buildGraph(userId: viewerId, edges: edges);

      final layout = FamilyTreeLayoutService.computeLayout(
        userId: viewerId,
        userName: 'Viewer',
        graph: graph,
        relatives: relatives,
        relativesMap: relativesMap,
        canvasSize: const Size(400, 600),
      );

      // Only ONE node for the viewer (isUser: true), no duplicate
      final viewerNodes =
          layout.nodes.where((n) => n.id == viewerId).toList();
      expect(viewerNodes, hasLength(1));
      expect(viewerNodes.first.isUser, true);
      expect(viewerNodes.first.label, 'أنا');

      // Sibling node exists and is not the user
      final siblingNodes =
          layout.nodes.where((n) => n.id == siblingId).toList();
      expect(siblingNodes, hasLength(1));
      expect(siblingNodes.first.isUser, false);

      // Total: user + sibling + father + mother = 4
      expect(layout.nodes, hasLength(4));
    });

    test('isLinkedMember is set correctly from linkedMemberNodeIds', () {
      const viewerId = 'viewer-node';
      const siblingId = 'sibling-node';
      final edges = [
        makeEdge(fromId: fatherId, toId: viewerId, type: EdgeType.parentOf),
        makeEdge(fromId: motherId, toId: viewerId, type: EdgeType.parentOf),
        makeEdge(fromId: fatherId, toId: siblingId, type: EdgeType.parentOf),
        makeEdge(fromId: motherId, toId: siblingId, type: EdgeType.parentOf),
        makeEdge(fromId: viewerId, toId: siblingId, type: EdgeType.siblingOf),
      ];

      final relatives = [
        makeRelative(id: viewerId, type: RelationshipType.other),
        makeRelative(id: siblingId, type: RelationshipType.brother),
        makeRelative(id: fatherId, type: RelationshipType.father),
        makeRelative(id: motherId, type: RelationshipType.mother, gender: Gender.female),
      ];

      final graph = FamilyGraphService.buildGraph(userId: viewerId, edges: edges);
      final relativesMap = {for (final r in relatives) r.id: r};

      // Both viewerId and siblingId are linked members (real users)
      final linkedIds = {viewerId, siblingId};

      final layout = FamilyTreeLayoutService.computeLayout(
        userId: viewerId,
        userName: 'Viewer',
        graph: graph,
        relatives: relatives,
        relativesMap: relativesMap,
        canvasSize: const Size(400, 600),
        linkedMemberNodeIds: linkedIds,
      );

      // Viewer node should be isLinkedMember
      final viewerNode = layout.nodes.firstWhere((n) => n.id == viewerId);
      expect(viewerNode.isLinkedMember, true);
      expect(viewerNode.isUser, true);

      // Sibling should be isLinkedMember
      final siblingNode = layout.nodes.firstWhere((n) => n.id == siblingId);
      expect(siblingNode.isLinkedMember, true);
      expect(siblingNode.isUser, false);

      // Father and mother are NOT linked members
      final fatherNode = layout.nodes.firstWhere((n) => n.id == fatherId);
      expect(fatherNode.isLinkedMember, false);

      final motherNode = layout.nodes.firstWhere((n) => n.id == motherId);
      expect(motherNode.isLinkedMember, false);
    });

    test('isLinkedMember defaults to false when linkedMemberNodeIds is empty', () {
      final edges = [
        makeEdge(fromId: fatherId, toId: userId, type: EdgeType.parentOf),
      ];

      final relatives = [
        makeRelative(id: fatherId, type: RelationshipType.father),
      ];

      final graph = FamilyGraphService.buildGraph(userId: userId, edges: edges);
      final relativesMap = {for (final r in relatives) r.id: r};

      final layout = FamilyTreeLayoutService.computeLayout(
        userId: userId,
        userName: 'User',
        graph: graph,
        relatives: relatives,
        relativesMap: relativesMap,
        canvasSize: const Size(400, 600),
        // linkedMemberNodeIds not passed — defaults to empty
      );

      // All nodes should have isLinkedMember = false
      for (final node in layout.nodes) {
        expect(node.isLinkedMember, false, reason: 'Node ${node.id} should not be linked');
      }
    });
  });
}
