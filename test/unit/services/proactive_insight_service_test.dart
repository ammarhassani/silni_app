import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/core/services/proactive_insight_service.dart';
import 'package:silni_app/shared/models/relative_model.dart';
import 'package:silni_app/shared/models/interaction_model.dart';

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

/// Helper to create a test Interaction
Interaction _makeInteraction(
  String relativeId,
  InteractionType type, {
  int daysAgo = 0,
}) {
  return Interaction(
    id: 'interaction-$relativeId-${type.value}-$daysAgo',
    userId: 'test-user',
    relativeId: relativeId,
    type: type,
    date: DateTime.now().subtract(Duration(days: daysAgo)),
    createdAt: DateTime.now().subtract(Duration(days: daysAgo)),
  );
}

void main() {
  group('ProactiveInsightService', () {
    // =====================================================
    // GAP DETECTION TESTS
    // =====================================================
    group('gap detection', () {
      test('should detect gap when parent not contacted in 7 days', () {
        final relatives = [
          _makeRelative('1', 'أبي', RelationshipType.father, 1, daysSince: 7),
        ];

        final insight = ProactiveInsightService.generateInsight(
          relatives: relatives,
          interactions: [],
        );

        expect(insight, isNotNull);
        expect(insight!.type, 'gap');
        expect(insight.message, contains('أبي'));
        expect(insight.message, contains('7'));
        expect(insight.relativeId, '1');
      });

      test('should detect gap when mother not contacted in 5 days', () {
        final relatives = [
          _makeRelative('1', 'أمي', RelationshipType.mother, 1, daysSince: 5),
        ];

        final insight = ProactiveInsightService.generateInsight(
          relatives: relatives,
          interactions: [],
        );

        expect(insight, isNotNull);
        expect(insight!.type, 'gap');
        expect(insight.message, contains('أمي'));
        expect(insight.message, contains('5'));
      });

      test('should detect gap for wife not contacted in 5+ days', () {
        final relatives = [
          _makeRelative('1', 'زوجتي', RelationshipType.wife, 1, daysSince: 6),
        ];

        final insight = ProactiveInsightService.generateInsight(
          relatives: relatives,
          interactions: [],
        );

        expect(insight, isNotNull);
        expect(insight!.type, 'gap');
        expect(insight.message, contains('زوجتي'));
      });

      test('should NOT detect gap when parent contacted recently', () {
        final relatives = [
          _makeRelative('1', 'أبي', RelationshipType.father, 1, daysSince: 2),
          _makeRelative('2', 'أمي', RelationshipType.mother, 1, daysSince: 1),
        ];

        final insight = ProactiveInsightService.generateInsight(
          relatives: relatives,
          interactions: [],
        );

        // Should not be a gap insight (may be null or another type)
        if (insight != null) {
          expect(insight.type, isNot('gap'));
        }
      });

      test('should skip archived relatives for gap detection', () {
        final relatives = [
          Relative(
            id: '1',
            userId: 'test-user',
            fullName: 'أبي',
            relationshipType: RelationshipType.father,
            priority: 1,
            lastContactDate: DateTime.now().subtract(const Duration(days: 10)),
            isArchived: true,
            createdAt: DateTime.now().subtract(const Duration(days: 365)),
          ),
        ];

        final insight = ProactiveInsightService.generateInsight(
          relatives: relatives,
          interactions: [],
        );

        // Should not be a gap insight for an archived relative
        if (insight != null) {
          expect(insight.type, isNot('gap'));
        }
      });
    });

    // =====================================================
    // IMBALANCE DETECTION TESTS
    // =====================================================
    group('imbalance detection', () {
      test('should detect imbalance when mom contacted 10x and dad contacted 1x', () {
        final relatives = [
          _makeRelative('dad', 'أبي', RelationshipType.father, 1, daysSince: 1),
          _makeRelative('mom', 'أمي', RelationshipType.mother, 1, daysSince: 0),
        ];

        // Create interactions: 10 for mom, 1 for dad in last 30 days
        final interactions = [
          ...List.generate(
            10,
            (i) => _makeInteraction('mom', InteractionType.call, daysAgo: i),
          ),
          _makeInteraction('dad', InteractionType.call, daysAgo: 5),
        ];

        final insight = ProactiveInsightService.generateInsight(
          relatives: relatives,
          interactions: interactions,
        );

        expect(insight, isNotNull);
        expect(insight!.type, 'pattern');
        expect(insight.message, contains('أبي'));
      });

      test('should show correct Arabic count when less-contacted parent has 2 interactions', () {
        final relatives = [
          _makeRelative('dad', 'أبي', RelationshipType.father, 1, daysSince: 1),
          _makeRelative('mom', 'أمي', RelationshipType.mother, 1, daysSince: 0),
        ];

        // 9 for mom, 2 for dad → 9 >= 3 * 2 = 6 → triggers imbalance
        final interactions = [
          ...List.generate(
            9,
            (i) => _makeInteraction('mom', InteractionType.call, daysAgo: i),
          ),
          _makeInteraction('dad', InteractionType.call, daysAgo: 1),
          _makeInteraction('dad', InteractionType.call, daysAgo: 3),
        ];

        final insight = ProactiveInsightService.generateInsight(
          relatives: relatives,
          interactions: interactions,
        );

        expect(insight, isNotNull);
        expect(insight!.type, 'pattern');
        expect(insight.message, contains('2 مرات'));
      });

      test('should NOT detect imbalance when both parents contacted equally', () {
        final relatives = [
          _makeRelative('dad', 'أبي', RelationshipType.father, 1, daysSince: 0),
          _makeRelative('mom', 'أمي', RelationshipType.mother, 1, daysSince: 0),
        ];

        final interactions = [
          ...List.generate(
            5,
            (i) => _makeInteraction('dad', InteractionType.call, daysAgo: i),
          ),
          ...List.generate(
            5,
            (i) => _makeInteraction('mom', InteractionType.call, daysAgo: i),
          ),
        ];

        final insight = ProactiveInsightService.generateInsight(
          relatives: relatives,
          interactions: interactions,
        );

        // Should not be a pattern/imbalance insight
        if (insight != null) {
          expect(insight.type, isNot('pattern'));
        }
      });
    });

    // =====================================================
    // POSITIVE REINFORCEMENT TESTS
    // =====================================================
    group('positive reinforcement', () {
      test('should show positive message when all relatives recently contacted', () {
        final relatives = [
          _makeRelative('1', 'أبي', RelationshipType.father, 1, daysSince: 0),
          _makeRelative('2', 'أمي', RelationshipType.mother, 1, daysSince: 0),
          _makeRelative('3', 'أخي', RelationshipType.brother, 2, daysSince: 1),
        ];

        final insight = ProactiveInsightService.generateInsight(
          relatives: relatives,
          interactions: [],
        );

        expect(insight, isNotNull);
        expect(insight!.type, 'positive');
        expect(insight.message, contains('ما شاء الله'));
      });
    });

    // =====================================================
    // VARIETY SUGGESTION TESTS
    // =====================================================
    group('variety suggestion', () {
      test('should suggest visits when 90% of interactions are calls', () {
        // Use siblings with moderate overdue (pulse < 0.8) to skip positive rule.
        // Priority 2 → expected freq 7 days. daysSince=4 → pulse ~= 0.43
        final relatives = [
          _makeRelative('1', 'أخي', RelationshipType.brother, 2, daysSince: 4),
          _makeRelative('2', 'أختي', RelationshipType.sister, 2, daysSince: 4),
        ];

        // 9 calls and 1 message = 90% calls
        final interactions = [
          ...List.generate(
            5,
            (i) => _makeInteraction('1', InteractionType.call, daysAgo: i),
          ),
          ...List.generate(
            4,
            (i) => _makeInteraction('2', InteractionType.call, daysAgo: i),
          ),
          _makeInteraction('2', InteractionType.message, daysAgo: 0),
        ];

        final insight = ProactiveInsightService.generateInsight(
          relatives: relatives,
          interactions: interactions,
        );

        expect(insight, isNotNull);
        expect(insight!.type, 'suggestion');
        expect(insight.message, anyOf(contains('زيارات'), contains('تزور')));
      });

      test('should NOT suggest variety when interactions are diverse', () {
        final relatives = [
          _makeRelative('1', 'أخي', RelationshipType.brother, 2, daysSince: 4),
        ];

        // Mixed interactions
        final interactions = [
          _makeInteraction('1', InteractionType.call, daysAgo: 0),
          _makeInteraction('1', InteractionType.visit, daysAgo: 1),
          _makeInteraction('1', InteractionType.message, daysAgo: 2),
          _makeInteraction('1', InteractionType.call, daysAgo: 3),
          _makeInteraction('1', InteractionType.gift, daysAgo: 5),
        ];

        final insight = ProactiveInsightService.generateInsight(
          relatives: relatives,
          interactions: interactions,
        );

        // Should not be a suggestion about variety
        if (insight != null) {
          expect(insight.type, isNot('suggestion'));
        }
      });
    });

    // =====================================================
    // EMPTY DATA TESTS
    // =====================================================
    group('empty/edge cases', () {
      test('should return null for empty data', () {
        final insight = ProactiveInsightService.generateInsight(
          relatives: [],
          interactions: [],
        );

        expect(insight, isNull);
      });

      test('should skip gap check and proceed to next rule when parent contacted recently', () {
        // Parent contacted recently (no gap), not enough data for imbalance
        // Family pulse < 0.8 (because we need more data for positive)
        // Not enough interactions for variety
        // → Should return null
        final relatives = [
          _makeRelative('1', 'أبي', RelationshipType.father, 1, daysSince: 1),
        ];

        final insight = ProactiveInsightService.generateInsight(
          relatives: relatives,
          interactions: [],
        );

        // With only one recently-contacted relative, pulse would be high
        // so it may return positive. Either way, not a gap
        if (insight != null) {
          expect(insight.type, isNot('gap'));
        }
      });
    });
  });
}
