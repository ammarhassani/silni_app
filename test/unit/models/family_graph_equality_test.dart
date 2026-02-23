import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/features/family_tree/models/family_graph.dart';
import 'package:silni_app/features/family_tree/services/family_graph_service.dart';

void main() {
  group('FamilyGraph equality', () {
    final edges = [
      FamilyEdge.create(
        userId: 'user-1',
        fromId: 'user-1',
        toId: 'father-1',
        type: EdgeType.parentOf,
      ),
      FamilyEdge.create(
        userId: 'user-1',
        fromId: 'user-1',
        toId: 'mother-1',
        type: EdgeType.parentOf,
      ),
    ];

    test('same edges produce equal graphs', () {
      final g1 = FamilyGraphService.buildGraph(userId: 'user-1', edges: edges);
      final g2 = FamilyGraphService.buildGraph(userId: 'user-1', edges: edges);
      expect(g1, equals(g2));
      expect(g1.hashCode, equals(g2.hashCode));
    });

    test('different edges produce unequal graphs', () {
      final g1 = FamilyGraphService.buildGraph(userId: 'user-1', edges: edges);
      final g2 = FamilyGraphService.buildGraph(
        userId: 'user-1',
        edges: [edges.first], // fewer edges
      );
      expect(g1, isNot(equals(g2)));
    });

    test('same edges in different order produce equal graphs', () {
      final g1 = FamilyGraphService.buildGraph(userId: 'user-1', edges: edges);
      final g2 = FamilyGraphService.buildGraph(
        userId: 'user-1',
        edges: edges.reversed.toList(),
      );
      expect(g1, equals(g2));
      expect(g1.hashCode, equals(g2.hashCode));
    });

    test('different userId produces unequal graphs', () {
      final g1 = FamilyGraphService.buildGraph(userId: 'user-1', edges: edges);
      final g2 = FamilyGraphService.buildGraph(userId: 'user-2', edges: edges);
      expect(g1, isNot(equals(g2)));
    });
  });
}
