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
        selfNodeId: selfNodeId,
        relatives: [],
        groupId: groupId,
      );

      expect(edges, isEmpty);
    });

    test('generates invite link with relative ID', () {
      final link = FamilySharingService.generateInviteLink(
        inviteCode: 'ABC123',
        relativeId: 'rel-456',
      );

      expect(link, 'https://silni.app/join/ABC123?rid=rel-456');
    });
  });
}
