import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/features/family_tree/models/tree_layout.dart';
import 'package:silni_app/features/family_tree/models/family_graph.dart';

void main() {
  group('LayoutNode', () {
    test('should store position, label, and health data', () {
      final node = LayoutNode(
        id: 'father-1',
        position: const Offset(100, 200),
        emoji: '👨',
        name: 'سعيد',
        label: 'أبي',
        generation: -1,
        isUser: false,
        healthRatio: 0.8,
        streakDays: 5,
        radius: 30.0,
      );

      expect(node.id, 'father-1');
      expect(node.position, const Offset(100, 200));
      expect(node.label, 'أبي');
      expect(node.healthRatio, 0.8);
      expect(node.streakDays, 5);
      expect(node.isUser, false);
    });

    test('healthColor returns green for healthy ratio', () {
      final node = LayoutNode(
        id: 'n1',
        position: Offset.zero,
        emoji: '👤',
        name: 'Test',
        label: 'Test',
        generation: 0,
        isUser: false,
        healthRatio: 0.9,
        streakDays: 0,
        radius: 30.0,
      );
      // >= 0.7 is green
      expect(node.healthColor, HealthColor.green);
    });

    test('healthColor returns amber for moderate ratio', () {
      final node = LayoutNode(
        id: 'n1',
        position: Offset.zero,
        emoji: '👤',
        name: 'Test',
        label: 'Test',
        generation: 0,
        isUser: false,
        healthRatio: 0.5,
        streakDays: 0,
        radius: 30.0,
      );
      expect(node.healthColor, HealthColor.amber);
    });

    test('healthColor returns red for poor ratio', () {
      final node = LayoutNode(
        id: 'n1',
        position: Offset.zero,
        emoji: '👤',
        name: 'Test',
        label: 'Test',
        generation: 0,
        isUser: false,
        healthRatio: 0.2,
        streakDays: 0,
        radius: 30.0,
      );
      expect(node.healthColor, HealthColor.red);
    });
  });

  group('LayoutEdge', () {
    test('should store from/to positions and type', () {
      final edge = LayoutEdge(
        fromId: 'father-1',
        toId: 'user-1',
        from: const Offset(100, 200),
        to: const Offset(100, 400),
        type: EdgeType.parentOf,
        isHealthy: true,
      );

      expect(edge.fromId, 'father-1');
      expect(edge.type, EdgeType.parentOf);
      expect(edge.isHealthy, true);
    });
  });

  group('FamilyTreeLayout', () {
    test('should provide nodes, edges, and bounds', () {
      final layout = FamilyTreeLayout(
        nodes: [
          LayoutNode(
            id: 'me',
            position: const Offset(200, 300),
            emoji: '👤',
            name: 'أنا',
            label: 'أنا',
            generation: 0,
            isUser: true,
            healthRatio: 1.0,
            streakDays: 0,
            radius: 30.0,
          ),
        ],
        edges: [],
        bounds: const Rect.fromLTWH(0, 0, 400, 600),
        userPosition: const Offset(200, 300),
      );

      expect(layout.nodes, hasLength(1));
      expect(layout.edges, isEmpty);
      expect(layout.bounds.width, 400);
      expect(layout.userPosition, const Offset(200, 300));
    });

    test('findNodeAtPosition returns node when hit', () {
      final node = LayoutNode(
        id: 'me',
        position: const Offset(200, 300),
        emoji: '👤',
        name: 'أنا',
        label: 'أنا',
        generation: 0,
        isUser: true,
        healthRatio: 1.0,
        streakDays: 0,
        radius: 30.0,
      );
      final layout = FamilyTreeLayout(
        nodes: [node],
        edges: [],
        bounds: const Rect.fromLTWH(0, 0, 400, 600),
        userPosition: const Offset(200, 300),
      );

      // Tap within radius (30 + 10 padding = 40)
      expect(layout.findNodeAtPosition(const Offset(210, 305)), node);
      // Tap outside
      expect(layout.findNodeAtPosition(const Offset(0, 0)), isNull);
    });
  });
}
