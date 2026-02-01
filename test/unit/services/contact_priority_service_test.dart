import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/core/services/contact_priority_service.dart';
import 'package:silni_app/shared/models/relative_model.dart';

/// Helper to create a test Relative with minimal required fields
Relative _makeRelative(
  String id,
  String name,
  RelationshipType type,
  int priority, {
  required int daysSince,
}) {
  return Relative(
    id: id,
    userId: 'test-user',
    fullName: name,
    relationshipType: type,
    priority: priority,
    lastContactDate:
        daysSince >= 0 ? DateTime.now().subtract(Duration(days: daysSince)) : null,
    createdAt: DateTime.now().subtract(const Duration(days: 365)),
  );
}

/// Helper to create a Relative with null lastContactDate
Relative _makeRelativeNeverContacted(
  String id,
  String name,
  RelationshipType type,
  int priority,
) {
  return Relative(
    id: id,
    userId: 'test-user',
    fullName: name,
    relationshipType: type,
    priority: priority,
    createdAt: DateTime.now().subtract(const Duration(days: 365)),
  );
}

void main() {
  group('ContactPriorityService', () {
    // =====================================================
    // getTodayPriority TESTS
    // =====================================================
    group('getTodayPriority', () {
      test('should return empty list for empty relatives', () {
        final result = ContactPriorityService.getTodayPriority([]);
        expect(result, isEmpty);
      });

      test('should rank uncle with 20-day gap higher than mother with 2-day gap', () {
        // uncle: priority 3, expected freq = 14 days, score = 20/14 * 3 = ~4.29
        // mother: priority 1, expected freq = 2 days, score = 2/2 * 1 = 1.0
        final relatives = [
          _makeRelative('1', 'أمي', RelationshipType.mother, 1, daysSince: 2),
          _makeRelative('2', 'عمي', RelationshipType.uncle, 3, daysSince: 20),
        ];

        final result = ContactPriorityService.getTodayPriority(relatives);
        expect(result.length, 2);
        expect(result.first.id, '2'); // uncle should be first (higher score)
      });

      test('should place never-contacted relatives first (score 999)', () {
        final relatives = [
          _makeRelative('1', 'أبي', RelationshipType.father, 1, daysSince: 1),
          _makeRelativeNeverContacted('2', 'جدي', RelationshipType.grandfather, 1),
        ];

        final result = ContactPriorityService.getTodayPriority(relatives);
        expect(result.first.id, '2'); // never-contacted should be first
      });

      test('should respect limit parameter', () {
        final relatives = [
          _makeRelative('1', 'أبي', RelationshipType.father, 1, daysSince: 5),
          _makeRelative('2', 'أمي', RelationshipType.mother, 1, daysSince: 3),
          _makeRelative('3', 'أخي', RelationshipType.brother, 2, daysSince: 10),
          _makeRelative('4', 'عمي', RelationshipType.uncle, 3, daysSince: 20),
          _makeRelative('5', 'خالي', RelationshipType.uncle, 3, daysSince: 15),
        ];

        final result = ContactPriorityService.getTodayPriority(relatives, limit: 3);
        expect(result.length, 3);
      });

      test('should default to limit of 5', () {
        final relatives = List.generate(
          10,
          (i) => _makeRelative(
            '$i',
            'قريب $i',
            RelationshipType.cousin,
            3,
            daysSince: i + 1,
          ),
        );

        final result = ContactPriorityService.getTodayPriority(relatives);
        expect(result.length, 5);
      });

      test('should filter out archived relatives', () {
        final relatives = [
          _makeRelative('1', 'أبي', RelationshipType.father, 1, daysSince: 10),
          Relative(
            id: '2',
            userId: 'test-user',
            fullName: 'عمي المؤرشف',
            relationshipType: RelationshipType.uncle,
            priority: 3,
            lastContactDate: DateTime.now().subtract(const Duration(days: 30)),
            isArchived: true,
            createdAt: DateTime.now().subtract(const Duration(days: 365)),
          ),
        ];

        final result = ContactPriorityService.getTodayPriority(relatives);
        expect(result.length, 1);
        expect(result.first.id, '1');
      });

      test('should sort by priority score descending', () {
        // father: priority 1, 10 days, score = 10/2 * 1 = 5.0
        // brother: priority 2, 14 days, score = 14/7 * 2 = 4.0
        // cousin: priority 3, 28 days, score = 28/14 * 3 = 6.0
        final relatives = [
          _makeRelative('1', 'أبي', RelationshipType.father, 1, daysSince: 10),
          _makeRelative('2', 'أخي', RelationshipType.brother, 2, daysSince: 14),
          _makeRelative('3', 'ابن عمي', RelationshipType.cousin, 3, daysSince: 28),
        ];

        final result = ContactPriorityService.getTodayPriority(relatives);
        expect(result[0].id, '3'); // cousin: 6.0
        expect(result[1].id, '1'); // father: 5.0
        expect(result[2].id, '2'); // brother: 4.0
      });
    });

    // =====================================================
    // getQuickLogSuggestions TESTS
    // =====================================================
    group('getQuickLogSuggestions', () {
      test('should return empty list for empty relatives', () {
        final result = ContactPriorityService.getQuickLogSuggestions([]);
        expect(result, isEmpty);
      });

      test('should default to limit of 3', () {
        final relatives = List.generate(
          10,
          (i) => _makeRelative(
            '$i',
            'قريب $i',
            RelationshipType.cousin,
            3,
            daysSince: i + 1,
          ),
        );

        final result = ContactPriorityService.getQuickLogSuggestions(relatives);
        expect(result.length, 3);
      });

      test('should return most overdue relatives', () {
        final relatives = [
          _makeRelative('1', 'أبي', RelationshipType.father, 1, daysSince: 1),
          _makeRelative('2', 'عمي', RelationshipType.uncle, 3, daysSince: 30),
          _makeRelative('3', 'أمي', RelationshipType.mother, 1, daysSince: 5),
        ];

        final result = ContactPriorityService.getQuickLogSuggestions(relatives, limit: 2);
        expect(result.length, 2);
        // uncle (30/14*3=6.43) and mother (5/2*1=2.5) should be top 2
        expect(result[0].id, '2');
        expect(result[1].id, '3');
      });

      test('should respect custom limit', () {
        final relatives = [
          _makeRelative('1', 'أبي', RelationshipType.father, 1, daysSince: 5),
          _makeRelative('2', 'أخي', RelationshipType.brother, 2, daysSince: 10),
        ];

        final result = ContactPriorityService.getQuickLogSuggestions(relatives, limit: 1);
        expect(result.length, 1);
      });
    });

    // =====================================================
    // getFamilyPulse TESTS
    // =====================================================
    group('getFamilyPulse', () {
      test('should return 0.0 for empty relatives', () {
        final result = ContactPriorityService.getFamilyPulse([]);
        expect(result, 0.0);
      });

      test('should return value between 0.0 and 1.0', () {
        final relatives = [
          _makeRelative('1', 'أبي', RelationshipType.father, 1, daysSince: 1),
          _makeRelative('2', 'أمي', RelationshipType.mother, 1, daysSince: 3),
          _makeRelative('3', 'أخي', RelationshipType.brother, 2, daysSince: 5),
        ];

        final result = ContactPriorityService.getFamilyPulse(relatives);
        expect(result, greaterThanOrEqualTo(0.0));
        expect(result, lessThanOrEqualTo(1.0));
      });

      test('should return 1.0 when all relatives were contacted today', () {
        final relatives = [
          _makeRelative('1', 'أبي', RelationshipType.father, 1, daysSince: 0),
          _makeRelative('2', 'أمي', RelationshipType.mother, 1, daysSince: 0),
        ];

        final result = ContactPriorityService.getFamilyPulse(relatives);
        expect(result, 1.0);
      });

      test('should return lower value when relatives are overdue', () {
        final freshRelatives = [
          _makeRelative('1', 'أبي', RelationshipType.father, 1, daysSince: 0),
          _makeRelative('2', 'أمي', RelationshipType.mother, 1, daysSince: 0),
        ];

        final overdueRelatives = [
          _makeRelative('1', 'أبي', RelationshipType.father, 1, daysSince: 10),
          _makeRelative('2', 'أمي', RelationshipType.mother, 1, daysSince: 10),
        ];

        final freshPulse = ContactPriorityService.getFamilyPulse(freshRelatives);
        final overduePulse = ContactPriorityService.getFamilyPulse(overdueRelatives);

        expect(freshPulse, greaterThan(overduePulse));
      });

      test('should treat null lastContactDate as overdue (score 0)', () {
        final relatives = [
          _makeRelative('1', 'أبي', RelationshipType.father, 1, daysSince: 0),
          _makeRelativeNeverContacted('2', 'جدي', RelationshipType.grandfather, 1),
        ];

        final result = ContactPriorityService.getFamilyPulse(relatives);
        // One fresh (score 1.0) and one overdue (score 0.0) → average 0.5 → pulse = 0.5
        expect(result, closeTo(0.5, 0.01));
      });

      test('should return 0.0 when all relatives have null lastContactDate', () {
        final relatives = [
          _makeRelativeNeverContacted('1', 'أبي', RelationshipType.father, 1),
          _makeRelativeNeverContacted('2', 'أمي', RelationshipType.mother, 1),
        ];

        final result = ContactPriorityService.getFamilyPulse(relatives);
        expect(result, 0.0);
      });

      test('should filter out archived relatives', () {
        final relatives = [
          _makeRelative('1', 'أبي', RelationshipType.father, 1, daysSince: 0),
          Relative(
            id: '2',
            userId: 'test-user',
            fullName: 'عمي المؤرشف',
            relationshipType: RelationshipType.uncle,
            priority: 3,
            lastContactDate: DateTime.now().subtract(const Duration(days: 100)),
            isArchived: true,
            createdAt: DateTime.now().subtract(const Duration(days: 365)),
          ),
        ];

        final result = ContactPriorityService.getFamilyPulse(relatives);
        // Only non-archived relative (father, 0 days) → pulse = 1.0
        expect(result, 1.0);
      });
    });
  });
}
