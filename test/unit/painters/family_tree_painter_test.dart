import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/features/family_tree/models/tree_layout.dart';
import 'package:silni_app/features/family_tree/painters/family_tree_painter.dart';

void main() {
  group('FamilyTreeEdgePainter', () {
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
            emoji: '\u{1F464}',
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

      final painter1 = FamilyTreeEdgePainter(layout: layout1);
      final painter2 = FamilyTreeEdgePainter(layout: layout2);

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns false when layout is the same', () {
      final layout = FamilyTreeLayout(
        nodes: [],
        edges: [],
        bounds: Rect.zero,
        userPosition: Offset.zero,
      );

      final painter1 = FamilyTreeEdgePainter(layout: layout);
      final painter2 = FamilyTreeEdgePainter(layout: layout);

      expect(painter1.shouldRepaint(painter2), isFalse);
    });

    test('shouldRepaint returns true when boundsOrigin changes', () {
      final layout = FamilyTreeLayout(
        nodes: [],
        edges: [],
        bounds: Rect.zero,
        userPosition: Offset.zero,
      );

      final painter1 = FamilyTreeEdgePainter(layout: layout);
      final painter2 = FamilyTreeEdgePainter(
        layout: layout,
        boundsOrigin: const Offset(10, 20),
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

      final painter = FamilyTreeEdgePainter(layout: layout);

      expect(painter, isNotNull);
      expect(painter.boundsOrigin, Offset.zero);
    });
  });
}
