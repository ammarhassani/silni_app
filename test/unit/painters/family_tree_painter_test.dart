import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/features/family_tree/models/tree_layout.dart';
import 'package:silni_app/features/family_tree/painters/family_tree_painter.dart';

void main() {
  group('FamilyTreePainter', () {
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

      final painter1 = FamilyTreePainter(
        layout: layout1,
        animationValue: 0.0,
        entryProgress: 1.0,
      );
      final painter2 = FamilyTreePainter(
        layout: layout2,
        animationValue: 0.0,
        entryProgress: 1.0,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns true when animation value changes', () {
      final layout = FamilyTreeLayout(
        nodes: [],
        edges: [],
        bounds: Rect.zero,
        userPosition: Offset.zero,
      );

      final painter1 = FamilyTreePainter(
        layout: layout,
        animationValue: 0.0,
        entryProgress: 1.0,
      );
      final painter2 = FamilyTreePainter(
        layout: layout,
        animationValue: 0.5,
        entryProgress: 1.0,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns false when nothing changes', () {
      final layout = FamilyTreeLayout(
        nodes: [],
        edges: [],
        bounds: Rect.zero,
        userPosition: Offset.zero,
      );

      final painter1 = FamilyTreePainter(
        layout: layout,
        animationValue: 0.0,
        entryProgress: 1.0,
      );
      final painter2 = FamilyTreePainter(
        layout: layout,
        animationValue: 0.0,
        entryProgress: 1.0,
      );

      expect(painter1.shouldRepaint(painter2), isFalse);
    });

    test('constructor accepts required parameters', () {
      final layout = FamilyTreeLayout(
        nodes: [],
        edges: [],
        bounds: Rect.zero,
        userPosition: Offset.zero,
      );

      final painter = FamilyTreePainter(
        layout: layout,
        animationValue: 0.5,
        entryProgress: 1.0,
      );

      expect(painter, isNotNull);
    });
  });
}
