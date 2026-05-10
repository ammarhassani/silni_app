import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/features/family_groups/services/family_sharing_service.dart';
import 'package:silni_app/features/family_tree/models/family_graph.dart';
import 'package:silni_app/shared/models/relative_model.dart';

/// Unit tests for FamilySharingService.generateSharedEdges.
///
/// Only the pure static method is tested here — initializeSharedTree
/// requires Supabase and is tested via integration tests.
void main() {
  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------
  const selfNodeId = 'self-node-1';
  const groupId = 'group-1';

  // ---------------------------------------------------------------------------
  // Helper: create a Relative with minimal required fields
  // ---------------------------------------------------------------------------
  Relative makeRelative(
    String id,
    String name,
    RelationshipType type,
    Gender gender, {
    FamilySide? familySide,
  }) {
    return Relative(
      id: id,
      userId: 'user-1',
      fullName: name,
      relationshipType: type,
      gender: gender,
      priority: type.priority,
      lastContactDate: DateTime.now(),
      avatarType: AvatarType.adultMan,
      createdAt: DateTime.now(),
      familySide: familySide,
    );
  }

  // ===========================================================================
  // Tests
  // ===========================================================================

  group('FamilySharingService.generateSharedEdges', () {
    test('creates parentOf edges from mom and dad to self node', () {
      final relatives = [
        makeRelative('dad-1', 'Dad', RelationshipType.father, Gender.male),
        makeRelative('mom-1', 'Mom', RelationshipType.mother, Gender.female),
      ];

      final edges = FamilySharingService.generateSharedEdges(
        authUserId: 'user-1',
        selfNodeId: selfNodeId,
        relatives: relatives,
        groupId: groupId,
      );

      // Father -> selfNode (parentOf)
      final fatherEdge = edges.where(
        (e) =>
            e.fromId == 'dad-1' &&
            e.toId == selfNodeId &&
            e.type == EdgeType.parentOf,
      );
      expect(fatherEdge, hasLength(1));

      // Mother -> selfNode (parentOf)
      final motherEdge = edges.where(
        (e) =>
            e.fromId == 'mom-1' &&
            e.toId == selfNodeId &&
            e.type == EdgeType.parentOf,
      );
      expect(motherEdge, hasLength(1));
    });

    test('infers spouse edge between parents', () {
      final relatives = [
        makeRelative('dad-1', 'Dad', RelationshipType.father, Gender.male),
        makeRelative('mom-1', 'Mom', RelationshipType.mother, Gender.female),
      ];

      final edges = FamilySharingService.generateSharedEdges(
        authUserId: 'user-1',
        selfNodeId: selfNodeId,
        relatives: relatives,
        groupId: groupId,
      );

      // When mother is added after father, inferEdges auto-links them as spouses
      final spouseEdge = edges.where(
        (e) => e.type == EdgeType.spouseOf,
      );
      expect(spouseEdge, hasLength(1));

      final spouse = spouseEdge.first;
      // The spouse edge should connect mom and dad (in either direction)
      final involvesBoth = (spouse.fromId == 'mom-1' && spouse.toId == 'dad-1') ||
          (spouse.fromId == 'dad-1' && spouse.toId == 'mom-1');
      expect(involvesBoth, isTrue);
    });

    test('creates sibling edges for brothers and sisters', () {
      final relatives = [
        makeRelative(
            'bro-1', 'Brother', RelationshipType.brother, Gender.male),
        makeRelative(
            'sis-1', 'Sister', RelationshipType.sister, Gender.female),
      ];

      final edges = FamilySharingService.generateSharedEdges(
        authUserId: 'user-1',
        selfNodeId: selfNodeId,
        relatives: relatives,
        groupId: groupId,
      );

      // Brother -> selfNode (siblingOf)
      final brotherEdge = edges.where(
        (e) =>
            e.fromId == 'bro-1' &&
            e.toId == selfNodeId &&
            e.type == EdgeType.siblingOf,
      );
      expect(brotherEdge, hasLength(1));

      // Sister -> selfNode (siblingOf)
      final sisterEdge = edges.where(
        (e) =>
            e.fromId == 'sis-1' &&
            e.toId == selfNodeId &&
            e.type == EdgeType.siblingOf,
      );
      expect(sisterEdge, hasLength(1));
    });

    test('handles paternal uncle (sibling of father)', () {
      final relatives = [
        makeRelative('dad-1', 'Dad', RelationshipType.father, Gender.male),
        makeRelative(
          'uncle-1',
          'Uncle',
          RelationshipType.uncle,
          Gender.male,
          familySide: FamilySide.paternal,
        ),
      ];

      final edges = FamilySharingService.generateSharedEdges(
        authUserId: 'user-1',
        selfNodeId: selfNodeId,
        relatives: relatives,
        groupId: groupId,
      );

      // Uncle -> Dad (siblingOf)
      final uncleEdge = edges.where(
        (e) =>
            e.fromId == 'uncle-1' &&
            e.toId == 'dad-1' &&
            e.type == EdgeType.siblingOf,
      );
      expect(uncleEdge, hasLength(1));
    });

    test('all edges have familyGroupId set', () {
      final relatives = [
        makeRelative('dad-1', 'Dad', RelationshipType.father, Gender.male),
        makeRelative('mom-1', 'Mom', RelationshipType.mother, Gender.female),
        makeRelative(
            'bro-1', 'Brother', RelationshipType.brother, Gender.male),
        makeRelative(
          'uncle-1',
          'Uncle',
          RelationshipType.uncle,
          Gender.male,
          familySide: FamilySide.paternal,
        ),
      ];

      final edges = FamilySharingService.generateSharedEdges(
        authUserId: 'user-1',
        selfNodeId: selfNodeId,
        relatives: relatives,
        groupId: groupId,
      );

      expect(edges, isNotEmpty);
      for (final edge in edges) {
        expect(edge.familyGroupId, groupId,
            reason: 'Edge ${edge.fromId}->${edge.toId} missing familyGroupId');
      }
    });

    test('returns empty list when no relatives provided', () {
      final edges = FamilySharingService.generateSharedEdges(
        authUserId: 'user-1',
        selfNodeId: selfNodeId,
        relatives: [],
        groupId: groupId,
      );

      expect(edges, isEmpty);
    });

    test('generateSharedEdges is idempotent (same input = same output)', () {
      final relatives = [
        makeRelative('dad-1', 'Dad', RelationshipType.father, Gender.male),
        makeRelative('mom-1', 'Mom', RelationshipType.mother, Gender.female),
        makeRelative('bro-1', 'Brother', RelationshipType.brother, Gender.male),
      ];

      final edges1 = FamilySharingService.generateSharedEdges(
        authUserId: 'user-1',
        selfNodeId: selfNodeId,
        relatives: relatives,
        groupId: groupId,
      );

      final edges2 = FamilySharingService.generateSharedEdges(
        authUserId: 'user-1',
        selfNodeId: selfNodeId,
        relatives: relatives,
        groupId: groupId,
      );

      // Same number of edges
      expect(edges1.length, edges2.length);

      // Same edge keys (fromId|toId|type)
      final keys1 = edges1
          .map((e) => '${e.fromId}|${e.toId}|${e.type.name}')
          .toSet();
      final keys2 = edges2
          .map((e) => '${e.fromId}|${e.toId}|${e.type.name}')
          .toSet();
      expect(keys1, keys2);
    });

    test('sibling edges include shared parent edges when parents exist', () {
      // When a brother is added AND parents exist, the brother should get
      // parentOf edges from both parents (not just a siblingOf to self).
      final relatives = [
        makeRelative('dad-1', 'Dad', RelationshipType.father, Gender.male),
        makeRelative('mom-1', 'Mom', RelationshipType.mother, Gender.female),
        makeRelative('bro-1', 'Brother', RelationshipType.brother, Gender.male),
      ];

      final edges = FamilySharingService.generateSharedEdges(
        authUserId: 'user-1',
        selfNodeId: selfNodeId,
        relatives: relatives,
        groupId: groupId,
      );

      // Brother should have parentOf edges from both parents
      final dadToBro = edges.where(
        (e) =>
            e.fromId == 'dad-1' &&
            e.toId == 'bro-1' &&
            e.type == EdgeType.parentOf,
      );
      expect(dadToBro, hasLength(1),
          reason: 'Father should have parentOf edge to brother');

      final momToBro = edges.where(
        (e) =>
            e.fromId == 'mom-1' &&
            e.toId == 'bro-1' &&
            e.type == EdgeType.parentOf,
      );
      expect(momToBro, hasLength(1),
          reason: 'Mother should have parentOf edge to brother');
    });

    // -----------------------------------------------------------------------
    // Phase δ.fix / δ.fix.2 — orphan recovery in shared-tree generation
    // -----------------------------------------------------------------------
    // generateSharedEdges loops relatives in list order. Even if the list
    // puts an orphan-prone relative (aunt) BEFORE its anchor (father), the
    // forward-bug fix in inferEdges + the order-independent `existingRelatives`
    // (full list visible from the start) means every edge that should exist
    // does exist after the loop. These tests pin that property.

    test('aunt-before-father order still yields aunt↔father siblingOf edge', () {
      // List order intentionally puts the aunt BEFORE the father — this is
      // the bug-prone order from the personal-tree founder repro, replayed
      // here for the shared-tree path.
      final relatives = [
        makeRelative(
          'aunt-1',
          'Aunt',
          RelationshipType.aunt,
          Gender.female,
          familySide: FamilySide.paternal,
        ),
        makeRelative('dad-1', 'Dad', RelationshipType.father, Gender.male),
      ];

      final edges = FamilySharingService.generateSharedEdges(
        authUserId: 'user-1',
        selfNodeId: selfNodeId,
        relatives: relatives,
        groupId: groupId,
      );

      // siblingOf aunt↔father must exist regardless of list order.
      final auntToDad = edges.where((e) =>
          e.type == EdgeType.siblingOf &&
          ((e.fromId == 'aunt-1' && e.toId == 'dad-1') ||
              (e.fromId == 'dad-1' && e.toId == 'aunt-1')));
      expect(auntToDad, isNotEmpty,
          reason: 'Aunt-before-father order must still produce siblingOf edge');
    });

    test('grandfather-before-father order yields grandfather→father parentOf', () {
      final relatives = [
        makeRelative(
          'gf-1',
          'Grandfather',
          RelationshipType.grandfather,
          Gender.male,
          familySide: FamilySide.paternal,
        ),
        makeRelative('dad-1', 'Dad', RelationshipType.father, Gender.male),
      ];

      final edges = FamilySharingService.generateSharedEdges(
        authUserId: 'user-1',
        selfNodeId: selfNodeId,
        relatives: relatives,
        groupId: groupId,
      );

      // parentOf grandfather→father must exist regardless of list order.
      final gfToDad = edges.where((e) =>
          e.type == EdgeType.parentOf &&
          e.fromId == 'gf-1' &&
          e.toId == 'dad-1');
      expect(gfToDad, isNotEmpty,
          reason:
              'Grandfather-before-father order must still produce parentOf');
    });

    test('cousin-before-uncle order yields uncle→cousin parentOf', () {
      final relatives = [
        makeRelative('cousin-1', 'Cousin', RelationshipType.cousin, Gender.male),
        makeRelative(
          'uncle-1',
          'Uncle',
          RelationshipType.uncle,
          Gender.male,
          familySide: FamilySide.paternal,
        ),
      ];

      final edges = FamilySharingService.generateSharedEdges(
        authUserId: 'user-1',
        selfNodeId: selfNodeId,
        relatives: relatives,
        groupId: groupId,
      );

      final uncleToCousin = edges.where((e) =>
          e.type == EdgeType.parentOf &&
          e.fromId == 'uncle-1' &&
          e.toId == 'cousin-1');
      expect(uncleToCousin, isNotEmpty,
          reason: 'Cousin-before-uncle order must still produce parentOf');
    });

    test('nephew-before-brother order yields brother→nephew parentOf', () {
      final relatives = [
        makeRelative('nephew-1', 'Nephew', RelationshipType.nephew, Gender.male),
        makeRelative('bro-1', 'Brother', RelationshipType.brother, Gender.male),
      ];

      final edges = FamilySharingService.generateSharedEdges(
        authUserId: 'user-1',
        selfNodeId: selfNodeId,
        relatives: relatives,
        groupId: groupId,
      );

      final broToNephew = edges.where((e) =>
          e.type == EdgeType.parentOf &&
          e.fromId == 'bro-1' &&
          e.toId == 'nephew-1');
      expect(broToNephew, isNotEmpty,
          reason: 'Nephew-before-brother order must still produce parentOf');
    });

    test('full founder repro: aunt + father + grandfather in worst order', () {
      // Paternal aunt added before father, then grandfather. The full chain
      // for layout placement: grandfather→aunt + grandfather→father + aunt↔father
      // all need to exist in the final edges list.
      final relatives = [
        makeRelative(
          'aunt-1',
          'Aunt Fatima',
          RelationshipType.aunt,
          Gender.female,
          familySide: FamilySide.paternal,
        ),
        makeRelative(
          'gf-1',
          'Grandfather',
          RelationshipType.grandfather,
          Gender.male,
          familySide: FamilySide.paternal,
        ),
        makeRelative('dad-1', 'Dad', RelationshipType.father, Gender.male),
      ];

      final edges = FamilySharingService.generateSharedEdges(
        authUserId: 'user-1',
        selfNodeId: selfNodeId,
        relatives: relatives,
        groupId: groupId,
      );

      final hasAuntDadSibling = edges.any((e) =>
          e.type == EdgeType.siblingOf &&
          ((e.fromId == 'aunt-1' && e.toId == 'dad-1') ||
              (e.fromId == 'dad-1' && e.toId == 'aunt-1')));
      final hasGfDadParent = edges.any((e) =>
          e.type == EdgeType.parentOf &&
          e.fromId == 'gf-1' &&
          e.toId == 'dad-1');
      final hasGfAuntParent = edges.any((e) =>
          e.type == EdgeType.parentOf &&
          e.fromId == 'gf-1' &&
          e.toId == 'aunt-1');

      expect(hasAuntDadSibling, isTrue, reason: 'aunt↔father siblingOf missing');
      expect(hasGfDadParent, isTrue, reason: 'grandfather→father parentOf missing');
      expect(hasGfAuntParent, isTrue, reason: 'grandfather→aunt parentOf missing');
    });
  });
}
