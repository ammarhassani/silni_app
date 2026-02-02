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
