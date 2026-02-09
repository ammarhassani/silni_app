import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/features/family_tree/models/family_graph.dart';
import 'package:silni_app/features/family_tree/services/family_graph_service.dart';
import 'package:silni_app/shared/models/relative_model.dart';
import 'package:silni_app/shared/utils/relationship_label_helper.dart';

/// Unit tests for getRelationshipLabel helper.
///
/// Tests cover:
/// 1. Returns arabicName when graph is null
/// 2. Returns arabicName when relativesMap is null
/// 3. Returns graph label when graph data is available
/// 4. Falls back to arabicName when graph returns empty string
void main() {
  // ---------------------------------------------------------------------------
  // Shared test IDs
  // ---------------------------------------------------------------------------
  const userId = 'user-1';
  const fatherId = 'father-1';
  const unknownId = 'unknown-1';

  // ---------------------------------------------------------------------------
  // Helper: create a Relative with minimal fields
  // ---------------------------------------------------------------------------
  Relative makeRelative({
    required String id,
    required RelationshipType type,
    Gender? gender,
  }) {
    return Relative(
      id: id,
      userId: userId,
      fullName: 'Test ${type.arabicName}',
      relationshipType: type,
      gender: gender ??
          (type == RelationshipType.mother ||
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

  // ---------------------------------------------------------------------------
  // Helper: create a FamilyEdge with deterministic id
  // ---------------------------------------------------------------------------
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

  group('getRelationshipLabel', () {
    test('returns arabicName when graph is null', () {
      final father = makeRelative(
        id: fatherId,
        type: RelationshipType.father,
      );

      final result = getRelationshipLabel(
        relative: father,
        viewerId: userId,
        graph: null,
        relativesMap: {fatherId: father},
      );

      expect(result, equals(RelationshipType.father.arabicName));
    });

    test('returns arabicName when relativesMap is null', () {
      // Build a graph with one edge
      final edges = [
        makeEdge(
          fromId: fatherId,
          toId: userId,
          type: EdgeType.parentOf,
        ),
      ];
      final graph = FamilyGraphService.buildGraph(
        userId: userId,
        edges: edges,
      );

      final father = makeRelative(
        id: fatherId,
        type: RelationshipType.father,
      );

      final result = getRelationshipLabel(
        relative: father,
        viewerId: userId,
        graph: graph,
        relativesMap: null,
      );

      expect(result, equals(RelationshipType.father.arabicName));
    });

    test('returns graph label when graph data is available', () {
      final father = makeRelative(
        id: fatherId,
        type: RelationshipType.father,
        gender: Gender.male,
      );

      final edges = [
        makeEdge(
          fromId: fatherId,
          toId: userId,
          type: EdgeType.parentOf,
        ),
      ];
      final graph = FamilyGraphService.buildGraph(
        userId: userId,
        edges: edges,
      );

      final relativesMap = {fatherId: father};

      final result = getRelationshipLabel(
        relative: father,
        viewerId: userId,
        graph: graph,
        relativesMap: relativesMap,
      );

      // Graph-based label for a male parent should be the possessive form
      expect(result, equals('أبي'));
    });

    test('falls back to قريب when target is not in relativesMap', () {
      // Create a relative that is NOT in the graph at all
      final other = makeRelative(
        id: unknownId,
        type: RelationshipType.other,
      );

      // Build a graph with edges that don't involve unknownId
      final edges = [
        makeEdge(
          fromId: fatherId,
          toId: userId,
          type: EdgeType.parentOf,
        ),
      ];
      final graph = FamilyGraphService.buildGraph(
        userId: userId,
        edges: edges,
      );

      // relativesMap does NOT contain unknownId, so getLabelForViewer
      // will return 'قريب' for a target not found in the map
      final relativesMap = <String, Relative>{fatherId: makeRelative(
        id: fatherId,
        type: RelationshipType.father,
      )};

      final result = getRelationshipLabel(
        relative: other,
        viewerId: userId,
        graph: graph,
        relativesMap: relativesMap,
      );

      // getLabelForViewer returns 'قريب' for unknown targets
      expect(result, equals('قريب'));
    });

    test('returns graph label for mother (female parent)', () {
      final mother = makeRelative(
        id: 'mother-1',
        type: RelationshipType.mother,
        gender: Gender.female,
      );

      final edges = [
        makeEdge(
          fromId: 'mother-1',
          toId: userId,
          type: EdgeType.parentOf,
        ),
      ];
      final graph = FamilyGraphService.buildGraph(
        userId: userId,
        edges: edges,
      );

      final relativesMap = {'mother-1': mother};

      final result = getRelationshipLabel(
        relative: mother,
        viewerId: userId,
        graph: graph,
        relativesMap: relativesMap,
      );

      expect(result, equals('أمي'));
    });

    test('returns graph label for sibling', () {
      final brother = makeRelative(
        id: 'brother-1',
        type: RelationshipType.brother,
        gender: Gender.male,
      );

      final edges = [
        makeEdge(
          fromId: 'brother-1',
          toId: userId,
          type: EdgeType.siblingOf,
        ),
      ];
      final graph = FamilyGraphService.buildGraph(
        userId: userId,
        edges: edges,
      );

      final relativesMap = {'brother-1': brother};

      final result = getRelationshipLabel(
        relative: brother,
        viewerId: userId,
        graph: graph,
        relativesMap: relativesMap,
      );

      expect(result, equals('أخوي'));
    });

    test('returns both graph and relativesMap null gracefully', () {
      final father = makeRelative(
        id: fatherId,
        type: RelationshipType.father,
      );

      final result = getRelationshipLabel(
        relative: father,
        viewerId: userId,
        graph: null,
        relativesMap: null,
      );

      expect(result, equals(RelationshipType.father.arabicName));
    });
  });
}
