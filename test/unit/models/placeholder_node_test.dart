import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/features/family_tree/models/placeholder_node.dart';
import 'package:silni_app/features/family_tree/models/family_graph.dart';
import 'package:silni_app/features/family_tree/models/tree_layout.dart';
import 'package:silni_app/shared/models/relative_model.dart';

void main() {
  group('PlaceholderNode', () {
    test('stores relationship metadata from tree position', () {
      final placeholder = PlaceholderNode(
        id: 'ph-father',
        type: RelationshipType.father,
        side: null,
        expectedGender: Gender.male,
        parentNodeId: null,
        label: 'أضف أبوك',
        generation: -1,
        position: const Offset(100, 50),
        radius: 30.0,
      );

      expect(placeholder.type, RelationshipType.father);
      expect(placeholder.expectedGender, Gender.male);
      expect(placeholder.side, isNull);
      expect(placeholder.label, 'أضف أبوك');
      expect(placeholder.generation, -1);
    });

    test('carries family side for extended family', () {
      final placeholder = PlaceholderNode(
        id: 'ph-uncle-pat',
        type: RelationshipType.uncle,
        side: FamilySide.paternal,
        expectedGender: Gender.male,
        parentNodeId: 'father-id',
        label: 'عم',
        generation: -1,
        position: const Offset(200, 50),
        radius: 30.0,
      );

      expect(placeholder.side, FamilySide.paternal);
      expect(placeholder.parentNodeId, 'father-id');
    });

    test('isCompact defaults to false', () {
      final placeholder = PlaceholderNode(
        id: 'ph-sibling',
        type: RelationshipType.brother,
        label: 'أضف أخوك',
        generation: 0,
        position: Offset.zero,
        radius: 30.0,
      );

      expect(placeholder.isCompact, false);
    });

    test('compact placeholder for additional siblings', () {
      final placeholder = PlaceholderNode(
        id: 'ph-sibling-plus',
        type: RelationshipType.brother,
        label: '+',
        generation: 0,
        position: Offset.zero,
        radius: 20.0,
        isCompact: true,
      );

      expect(placeholder.isCompact, true);
      expect(placeholder.label, '+');
    });

    test('copyWithPosition preserves all fields except position', () {
      final original = PlaceholderNode(
        id: 'ph-test',
        type: RelationshipType.aunt,
        side: FamilySide.maternal,
        expectedGender: Gender.female,
        parentNodeId: 'mother-id',
        label: 'خالة',
        generation: -1,
        position: const Offset(0, 0),
        radius: 30.0,
        isCompact: false,
      );

      final moved = original.copyWithPosition(const Offset(150, 75));

      expect(moved.id, original.id);
      expect(moved.type, original.type);
      expect(moved.side, original.side);
      expect(moved.expectedGender, original.expectedGender);
      expect(moved.parentNodeId, original.parentNodeId);
      expect(moved.label, original.label);
      expect(moved.generation, original.generation);
      expect(moved.radius, original.radius);
      expect(moved.isCompact, original.isCompact);
      expect(moved.position, const Offset(150, 75));
    });
  });

  group('FamilyTreeLayout placeholder hit-testing', () {
    test('findPlaceholderAtPosition returns placeholder within radius', () {
      final ph = PlaceholderNode(
        id: 'ph-1',
        type: RelationshipType.father,
        label: 'أضف أبوك',
        generation: -1,
        position: const Offset(100, 100),
        radius: 30.0,
      );

      final layout = FamilyTreeLayout(
        nodes: [
          LayoutNode(
            id: 'user',
            position: const Offset(100, 250),
            emoji: '👤',
            name: 'أحمد',
            label: 'أنت',
            generation: 0,
            isUser: true,
            healthRatio: 1.0,
            streakDays: 0,
            radius: 30.0,
          ),
        ],
        edges: [],
        placeholders: [ph],
        bounds: const Rect.fromLTWH(0, 0, 400, 600),
        userPosition: const Offset(100, 250),
      );

      // Tap exactly on placeholder
      expect(layout.findPlaceholderAtPosition(const Offset(100, 100))?.id,
          'ph-1');

      // Tap within radius + padding
      expect(layout.findPlaceholderAtPosition(const Offset(130, 100))?.id,
          'ph-1');

      // Tap outside radius + padding
      expect(
          layout.findPlaceholderAtPosition(const Offset(200, 200)), isNull);
    });

    test('findPlaceholderAtPosition returns null when no placeholders', () {
      final layout = FamilyTreeLayout(
        nodes: [],
        edges: [],
        bounds: const Rect.fromLTWH(0, 0, 400, 600),
        userPosition: const Offset(200, 300),
      );

      expect(
          layout.findPlaceholderAtPosition(const Offset(100, 100)), isNull);
    });
  });
}
