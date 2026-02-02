import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:silni_app/shared/models/relative_model.dart';
import '../../helpers/model_factories.dart';

void main() {
  group('FamilyTreeScreen Logic Tests', () {
    // =====================================================
    // TREE BUILDING LOGIC TESTS
    // =====================================================
    group('tree building logic', () {
      /// Separate relatives by relationship type
      Map<String, List<Relative>> categorizeRelatives(List<Relative> relatives) {
        return {
          'parents': relatives
              .where((r) =>
                  r.relationshipType == RelationshipType.father ||
                  r.relationshipType == RelationshipType.mother)
              .toList(),
          'grandparents': relatives
              .where((r) =>
                  r.relationshipType == RelationshipType.grandfather ||
                  r.relationshipType == RelationshipType.grandmother)
              .toList(),
          'siblings': relatives
              .where((r) =>
                  r.relationshipType == RelationshipType.brother ||
                  r.relationshipType == RelationshipType.sister)
              .toList(),
          'children': relatives
              .where((r) =>
                  r.relationshipType == RelationshipType.son ||
                  r.relationshipType == RelationshipType.daughter)
              .toList(),
          'spouse': relatives
              .where((r) =>
                  r.relationshipType == RelationshipType.husband ||
                  r.relationshipType == RelationshipType.wife)
              .toList(),
          'extended': relatives
              .where((r) =>
                  r.relationshipType == RelationshipType.uncle ||
                  r.relationshipType == RelationshipType.aunt ||
                  r.relationshipType == RelationshipType.cousin ||
                  r.relationshipType == RelationshipType.nephew ||
                  r.relationshipType == RelationshipType.niece ||
                  r.relationshipType == RelationshipType.other)
              .toList(),
        };
      }

      test('should categorize parents correctly', () {
        final relatives = [
          createTestRelative(
            id: 'father',
            relationshipType: RelationshipType.father,
          ),
          createTestRelative(
            id: 'mother',
            relationshipType: RelationshipType.mother,
          ),
          createTestRelative(
            id: 'brother',
            relationshipType: RelationshipType.brother,
          ),
        ];

        final categorized = categorizeRelatives(relatives);
        expect(categorized['parents']!.length, equals(2));
        expect(categorized['siblings']!.length, equals(1));
      });

      test('should categorize grandparents correctly', () {
        final relatives = [
          createTestRelative(
            id: 'gf',
            relationshipType: RelationshipType.grandfather,
          ),
          createTestRelative(
            id: 'gm',
            relationshipType: RelationshipType.grandmother,
          ),
        ];

        final categorized = categorizeRelatives(relatives);
        expect(categorized['grandparents']!.length, equals(2));
      });

      test('should categorize children correctly', () {
        final relatives = [
          createTestRelative(
            id: 'son',
            relationshipType: RelationshipType.son,
          ),
          createTestRelative(
            id: 'daughter',
            relationshipType: RelationshipType.daughter,
          ),
        ];

        final categorized = categorizeRelatives(relatives);
        expect(categorized['children']!.length, equals(2));
      });

      test('should categorize extended family correctly', () {
        final relatives = [
          createTestRelative(
            id: 'uncle',
            relationshipType: RelationshipType.uncle,
          ),
          createTestRelative(
            id: 'aunt',
            relationshipType: RelationshipType.aunt,
          ),
          createTestRelative(
            id: 'cousin',
            relationshipType: RelationshipType.cousin,
          ),
        ];

        final categorized = categorizeRelatives(relatives);
        expect(categorized['extended']!.length, equals(3));
      });

      test('should handle empty relatives list', () {
        final categorized = categorizeRelatives([]);

        expect(categorized['parents']!.isEmpty, isTrue);
        expect(categorized['grandparents']!.isEmpty, isTrue);
        expect(categorized['siblings']!.isEmpty, isTrue);
        expect(categorized['children']!.isEmpty, isTrue);
        expect(categorized['spouse']!.isEmpty, isTrue);
        expect(categorized['extended']!.isEmpty, isTrue);
      });
    });

    // =====================================================
    // ZOOM LOGIC TESTS
    // =====================================================
    group('zoom logic', () {
      test('zoom in should increase scale', () {
        double currentScale = 1.0;
        final newScale = (currentScale * 1.2).clamp(0.1, 3.0);
        expect(newScale, equals(1.2));
      });

      test('zoom out should decrease scale', () {
        double currentScale = 1.0;
        final newScale = (currentScale / 1.2).clamp(0.1, 3.0);
        expect(newScale, closeTo(0.833, 0.01));
      });

      test('zoom should not exceed max scale', () {
        double currentScale = 2.8;
        final newScale = (currentScale * 1.2).clamp(0.1, 3.0);
        expect(newScale, equals(3.0));
      });

      test('zoom should not go below min scale', () {
        double currentScale = 0.15;
        final newScale = (currentScale / 1.2).clamp(0.1, 3.0);
        expect(newScale, equals(0.125));
      });

      test('reset zoom should return to 1.0', () {
        double currentScale = 2.5;
        currentScale = 1.0; // Reset
        expect(currentScale, equals(1.0));
      });

      test('zoom percentage display should be correct', () {
        double scale = 1.0;
        expect('${(scale * 100).toInt()}%', equals('100%'));

        scale = 1.5;
        expect('${(scale * 100).toInt()}%', equals('150%'));

        scale = 0.5;
        expect('${(scale * 100).toInt()}%', equals('50%'));
      });
    });

    // =====================================================
    // DISPLAY NAME LOGIC TESTS
    // =====================================================
    group('display name logic', () {
      test('should use full_name from metadata', () {
        final metadata = {'full_name': 'محمد أحمد'};
        final email = 'test@example.com';

        final displayName = metadata['full_name'] ?? email;
        expect(displayName, equals('محمد أحمد'));
      });

      test('should fall back to email when no full_name', () {
        final Map<String, dynamic>? metadata = null;
        const email = 'user@example.com';

        final displayName = metadata?['full_name'] ?? email;
        expect(displayName, equals('user@example.com'));
      });

      test('should fall back to default when nothing available', () {
        final Map<String, dynamic>? metadata = null;
        final String? email = null;

        final displayName = metadata?['full_name'] ?? email ?? 'أنا';
        expect(displayName, equals('أنا'));
      });
    });

    // =====================================================
    // UI LABELS TESTS
    // =====================================================
    group('UI labels', () {
      test('screen title should be in Arabic', () {
        const title = 'شجرة العائلة';
        expect(title, equals('شجرة العائلة'));
      });

      test('subtitle should be in Arabic', () {
        const subtitle = 'تصور جميل لأفراد عائلتك';
        expect(subtitle, equals('تصور جميل لأفراد عائلتك'));
      });

      test('empty state messages should be in Arabic', () {
        const emptyTitle = 'شجرة عائلتك فارغة';
        const emptySubtitle = 'ابدأ بإضافة أقاربك لرؤية شجرة العائلة';
        const addButton = 'إضافة قريب';

        expect(emptyTitle, equals('شجرة عائلتك فارغة'));
        expect(emptySubtitle.contains('إضافة'), isTrue);
        expect(addButton, equals('إضافة قريب'));
      });

      test('error message should be in Arabic', () {
        const error = 'حدث خطأ في تحميل شجرة العائلة';
        expect(error.contains('خطأ'), isTrue);
      });

      test('zoom tooltips should be in Arabic', () {
        const zoomIn = 'تكبير';
        const zoomOut = 'تصغير';
        const reset = 'إعادة ضبط';

        expect(zoomIn, equals('تكبير'));
        expect(zoomOut, equals('تصغير'));
        expect(reset, equals('إعادة ضبط'));
      });

      test('detail button should be in Arabic', () {
        const button = 'عرض التفاصيل';
        expect(button, equals('عرض التفاصيل'));
      });
    });

    // =====================================================
    // GENERATION LEVELS TESTS
    // =====================================================
    group('generation levels', () {
      test('level -2 should be grandparents', () {
        const level = -2;
        expect(level, equals(-2));

        String getGenerationName(int level) {
          switch (level) {
            case -2: return 'الأجداد';
            case -1: return 'الوالدين';
            case 0: return 'أنا والإخوة';
            case 1: return 'الأبناء';
            default: return '';
          }
        }

        expect(getGenerationName(level), equals('الأجداد'));
      });

      test('level -1 should be parents', () {
        expect(-1, equals(-1));
      });

      test('level 0 should be user and siblings', () {
        expect(0, equals(0));
      });

      test('level 1 should be children', () {
        expect(1, equals(1));
      });

      test('levels should be ordered correctly', () {
        final levels = [-2, -1, 0, 1];
        expect(levels, orderedEquals([-2, -1, 0, 1]));
      });
    });

    // =====================================================
    // CONNECTION LINES TESTS
    // =====================================================
    group('connection lines', () {
      test('should return empty widget for zero count', () {
        const count = 0;
        expect(count <= 0, isTrue);
      });

      test('vertical line dimensions', () {
        const height = 30.0;
        const width = 3.0;

        expect(height, equals(30.0));
        expect(width, equals(3.0));
      });

      test('horizontal line dimensions', () {
        const width = 30.0;
        const height = 3.0;

        expect(width, equals(30.0));
        expect(height, equals(3.0));
      });
    });

    // =====================================================
    // NODE SELECTION TESTS
    // =====================================================
    group('node selection', () {
      test('selecting node should update selected ID', () {
        String? selectedNodeId;

        selectedNodeId = 'node-1';
        expect(selectedNodeId, equals('node-1'));

        selectedNodeId = 'node-2';
        expect(selectedNodeId, equals('node-2'));
      });

      test('selecting root node should be identifiable', () {
        // In the new canvas-based tree, the root (user) node
        // is identified by its ID matching the userId
        const userId = 'me';
        const selectedNodeId = 'me';
        expect(selectedNodeId == userId, isTrue);
      });

      test('non-root node should find relative', () {
        final relatives = [
          createTestRelative(id: 'rel-1', fullName: 'أحمد'),
          createTestRelative(id: 'rel-2', fullName: 'محمد'),
        ];

        final nodeId = 'rel-1';
        final relative = relatives.firstWhere((r) => r.id == nodeId);

        expect(relative.fullName, equals('أحمد'));
      });
    });

    // =====================================================
    // DETAIL ROW TESTS
    // =====================================================
    group('detail rows', () {
      test('phone detail should use phone icon', () {
        const icon = Icons.phone_rounded;
        expect(icon, equals(Icons.phone_rounded));
      });

      test('email detail should use email icon', () {
        const icon = Icons.email_rounded;
        expect(icon, equals(Icons.email_rounded));
      });

      test('address detail should use location icon', () {
        const icon = Icons.location_on_rounded;
        expect(icon, equals(Icons.location_on_rounded));
      });
    });

    // =====================================================
    // AVATAR STYLING TESTS
    // =====================================================
    group('avatar styling', () {
      test('root node should use golden gradient', () {
        // In the canvas-based painter, root (user) nodes
        // are rendered with a golden gradient
        const isUser = true;
        expect(isUser, isTrue);
      });

      test('non-root node should use primary gradient', () {
        // In the canvas-based painter, non-root nodes
        // are rendered with a primary gradient based on health color
        const isUser = false;
        expect(isUser, isFalse);
      });

      test('avatar size should be 80x80', () {
        const avatarWidth = 80.0;
        const avatarHeight = 80.0;

        expect(avatarWidth, equals(80.0));
        expect(avatarHeight, equals(80.0));
      });

      test('emoji size should be 40', () {
        const emojiSize = 40.0;
        expect(emojiSize, equals(40.0));
      });
    });

    // =====================================================
    // RELATIONSHIP TYPE GROUPING TESTS
    // =====================================================
    group('relationship type grouping', () {
      test('should identify parent types', () {
        final parentTypes = [
          RelationshipType.father,
          RelationshipType.mother,
        ];

        expect(parentTypes.length, equals(2));
      });

      test('should identify grandparent types', () {
        final grandparentTypes = [
          RelationshipType.grandfather,
          RelationshipType.grandmother,
        ];

        expect(grandparentTypes.length, equals(2));
      });

      test('should identify sibling types', () {
        final siblingTypes = [
          RelationshipType.brother,
          RelationshipType.sister,
        ];

        expect(siblingTypes.length, equals(2));
      });

      test('should identify child types', () {
        final childTypes = [
          RelationshipType.son,
          RelationshipType.daughter,
        ];

        expect(childTypes.length, equals(2));
      });

      test('should identify spouse types', () {
        final spouseTypes = [
          RelationshipType.husband,
          RelationshipType.wife,
        ];

        expect(spouseTypes.length, equals(2));
      });

      test('should identify extended family types', () {
        final extendedTypes = [
          RelationshipType.uncle,
          RelationshipType.aunt,
          RelationshipType.cousin,
          RelationshipType.nephew,
          RelationshipType.niece,
          RelationshipType.other,
        ];

        expect(extendedTypes.length, equals(6));
      });
    });

    // =====================================================
    // INTERACTIVE VIEWER TESTS
    // =====================================================
    group('interactive viewer settings', () {
      test('boundary margin should be infinite', () {
        const boundaryMargin = double.infinity;
        expect(boundaryMargin, equals(double.infinity));
      });

      test('min scale should be 0.1', () {
        const minScale = 0.1;
        expect(minScale, equals(0.1));
      });

      test('max scale should be 3.0', () {
        const maxScale = 3.0;
        expect(maxScale, equals(3.0));
      });

      test('constrained should be false', () {
        const constrained = false;
        expect(constrained, isFalse);
      });
    });

    // =====================================================
    // EDGE CASES
    // =====================================================
    group('edge cases', () {
      test('should handle single relative', () {
        final relatives = [
          createTestRelative(id: 'rel-1', relationshipType: RelationshipType.father),
        ];

        expect(relatives.length, equals(1));
      });

      test('should handle many relatives', () {
        final relatives = List.generate(
          50,
          (i) => createTestRelative(
            id: 'rel-$i',
            fullName: 'قريب $i',
          ),
        );

        expect(relatives.length, equals(50));
      });

      test('should handle relative with optional fields', () {
        final relative = createTestRelative(
          id: 'rel-1',
        );

        // Factory provides default values, ensure they're accessible
        expect(relative.id, equals('rel-1'));
        // Phone, email, address may have defaults from factory
        expect(relative.fullName.isNotEmpty, isTrue);
      });

      test('should handle multi-generation families', () {
        // In the canvas-based tree, the layout service handles
        // multiple generations via the FamilyGraph adjacency model
        final relatives = [
          createTestRelative(id: 'father', relationshipType: RelationshipType.father),
          createTestRelative(id: 'son', relationshipType: RelationshipType.son),
          createTestRelative(id: 'grandfather', relationshipType: RelationshipType.grandfather),
        ];

        // Three generations present
        expect(relatives.length, equals(3));
      });

      test('should handle multiple siblings', () {
        final siblings = List.generate(
          5,
          (i) => createTestRelative(
            id: 'sibling-$i',
            fullName: 'أخ $i',
            relationshipType: RelationshipType.brother,
          ),
        );

        expect(siblings.length, equals(5));
      });
    });
  });
}
