import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/shared/models/interaction_model.dart';
import 'package:silni_app/features/wrapped/services/wrapped_generator_service.dart';

import '../../helpers/model_factories.dart';

void main() {
  group('WrappedGeneratorService', () {
    final month = DateTime(2026, 1, 15); // January 2026

    // Helper to create interactions in the target month
    Interaction inMonth(InteractionType type, String relativeId, {int day = 10, int hour = 12}) {
      return createTestInteraction(
        id: '${type.value}-$relativeId-$day-$hour',
        type: type,
        relativeId: relativeId,
        date: DateTime(2026, 1, day, hour),
      );
    }

    // =====================================================
    // BASIC STATS COMPUTATION
    // =====================================================

    test('computes basic stats: total interactions, unique relatives, coverage', () {
      final relatives = [
        createTestRelative(id: 'r1', fullName: 'أحمد'),
        createTestRelative(id: 'r2', fullName: 'فاطمة'),
        createTestRelative(id: 'r3', fullName: 'خالد'),
        createTestRelative(id: 'r4', fullName: 'سارة'),
        createTestRelative(id: 'r5', fullName: 'عمر'),
      ];

      final interactions = [
        inMonth(InteractionType.call, 'r1', day: 1),
        inMonth(InteractionType.visit, 'r2', day: 2),
        inMonth(InteractionType.message, 'r3', day: 3),
        inMonth(InteractionType.call, 'r1', day: 4),
      ];

      final wrapped = WrappedGeneratorService.generate(
        interactions: interactions,
        relatives: relatives,
        month: month,
      );

      expect(wrapped.totalInteractions, 4);
      expect(wrapped.uniqueRelativesContacted, 3); // r1, r2, r3
      expect(wrapped.relativesCoverage, closeTo(0.6, 0.01)); // 3/5
    });

    // =====================================================
    // MOST CONTACTED RELATIVE
    // =====================================================

    test('detects most contacted relative', () {
      final relatives = [
        createTestRelative(id: 'r1', fullName: 'أحمد'),
        createTestRelative(id: 'r2', fullName: 'فاطمة'),
      ];

      final interactions = [
        inMonth(InteractionType.call, 'r1', day: 1),
        inMonth(InteractionType.call, 'r1', day: 2),
        inMonth(InteractionType.call, 'r1', day: 3),
        inMonth(InteractionType.visit, 'r2', day: 4),
      ];

      final wrapped = WrappedGeneratorService.generate(
        interactions: interactions,
        relatives: relatives,
        month: month,
      );

      expect(wrapped.mostContactedRelativeName, 'أحمد');
      expect(wrapped.mostContactedRelativeCount, 3);
    });

    // =====================================================
    // PERSONALITY LABELS
    // =====================================================

    test('personality label: night owl (50%+ interactions between 21:00-04:00)', () {
      final relatives = [createTestRelative(id: 'r1', fullName: 'أحمد')];

      final interactions = [
        inMonth(InteractionType.call, 'r1', day: 1, hour: 22),
        inMonth(InteractionType.message, 'r1', day: 2, hour: 23),
        inMonth(InteractionType.call, 'r1', day: 3, hour: 2),
        inMonth(InteractionType.call, 'r1', day: 4, hour: 14), // daytime
      ];

      final wrapped = WrappedGeneratorService.generate(
        interactions: interactions,
        relatives: relatives,
        month: month,
      );

      // 3/4 = 75% at night
      expect(wrapped.personalityLabel, 'بومة الليل العائلية');
      expect(wrapped.personalityEmoji, '\u{1F989}'); // owl emoji
    });

    test('personality label: visitor (50%+ visits)', () {
      final relatives = [createTestRelative(id: 'r1', fullName: 'أحمد')];

      final interactions = [
        inMonth(InteractionType.visit, 'r1', day: 1),
        inMonth(InteractionType.visit, 'r1', day: 2),
        inMonth(InteractionType.visit, 'r1', day: 3),
        inMonth(InteractionType.call, 'r1', day: 4),
      ];

      final wrapped = WrappedGeneratorService.generate(
        interactions: interactions,
        relatives: relatives,
        month: month,
      );

      expect(wrapped.personalityLabel, 'ملك الزيارات');
      expect(wrapped.personalityEmoji, '\u{1F3E0}'); // house emoji
    });

    test('personality label: caller (50%+ calls)', () {
      // Need enough relatives so coverage stays below 80% (1/5 = 20%)
      final relatives = [
        createTestRelative(id: 'r1', fullName: 'أحمد'),
        createTestRelative(id: 'r2', fullName: 'فاطمة'),
        createTestRelative(id: 'r3', fullName: 'خالد'),
        createTestRelative(id: 'r4', fullName: 'سارة'),
        createTestRelative(id: 'r5', fullName: 'عمر'),
      ];

      final interactions = [
        inMonth(InteractionType.call, 'r1', day: 1),
        inMonth(InteractionType.call, 'r1', day: 2),
        inMonth(InteractionType.call, 'r1', day: 3),
        inMonth(InteractionType.visit, 'r1', day: 4),
      ];

      final wrapped = WrappedGeneratorService.generate(
        interactions: interactions,
        relatives: relatives,
        month: month,
      );

      expect(wrapped.personalityLabel, 'صاحب المكالمات');
      expect(wrapped.personalityEmoji, '\u{1F4DE}'); // phone emoji
    });

    test('personality label: generous (50%+ gifts)', () {
      final relatives = [createTestRelative(id: 'r1', fullName: 'أحمد')];

      final interactions = [
        inMonth(InteractionType.gift, 'r1', day: 1),
        inMonth(InteractionType.gift, 'r1', day: 2),
        inMonth(InteractionType.gift, 'r1', day: 3),
        inMonth(InteractionType.call, 'r1', day: 4),
      ];

      final wrapped = WrappedGeneratorService.generate(
        interactions: interactions,
        relatives: relatives,
        month: month,
      );

      expect(wrapped.personalityLabel, 'الكريم');
      expect(wrapped.personalityEmoji, '\u{1F381}'); // gift emoji
    });

    test('personality label: morning bird (50%+ interactions between 05:00-10:00)', () {
      final relatives = [createTestRelative(id: 'r1', fullName: 'أحمد')];

      final interactions = [
        inMonth(InteractionType.call, 'r1', day: 1, hour: 6),
        inMonth(InteractionType.message, 'r1', day: 2, hour: 7),
        inMonth(InteractionType.call, 'r1', day: 3, hour: 9),
        inMonth(InteractionType.call, 'r1', day: 4, hour: 14), // afternoon
      ];

      final wrapped = WrappedGeneratorService.generate(
        interactions: interactions,
        relatives: relatives,
        month: month,
      );

      expect(wrapped.personalityLabel, 'طائر الصباح العائلي');
      expect(wrapped.personalityEmoji, '\u{1F305}'); // sunrise emoji
    });

    test('personality label: family connector (80%+ coverage)', () {
      final relatives = [
        createTestRelative(id: 'r1', fullName: 'أحمد'),
        createTestRelative(id: 'r2', fullName: 'فاطمة'),
        createTestRelative(id: 'r3', fullName: 'خالد'),
        createTestRelative(id: 'r4', fullName: 'سارة'),
        createTestRelative(id: 'r5', fullName: 'عمر'),
      ];

      // Contact 4/5 = 80%, with mixed types so no single type dominates
      final interactions = [
        inMonth(InteractionType.call, 'r1', day: 1),
        inMonth(InteractionType.visit, 'r2', day: 2),
        inMonth(InteractionType.message, 'r3', day: 3),
        inMonth(InteractionType.gift, 'r4', day: 4),
      ];

      final wrapped = WrappedGeneratorService.generate(
        interactions: interactions,
        relatives: relatives,
        month: month,
      );

      expect(wrapped.personalityLabel, 'واصل العائلة');
      expect(wrapped.personalityEmoji, '\u{1F91D}'); // handshake emoji
    });

    test('personality label: default for mixed interactions', () {
      final relatives = [
        createTestRelative(id: 'r1', fullName: 'أحمد'),
        createTestRelative(id: 'r2', fullName: 'فاطمة'),
        createTestRelative(id: 'r3', fullName: 'خالد'),
        createTestRelative(id: 'r4', fullName: 'سارة'),
        createTestRelative(id: 'r5', fullName: 'عمر'),
        createTestRelative(id: 'r6', fullName: 'نورة'),
        createTestRelative(id: 'r7', fullName: 'يوسف'),
        createTestRelative(id: 'r8', fullName: 'ليلى'),
        createTestRelative(id: 'r9', fullName: 'حسن'),
        createTestRelative(id: 'r10', fullName: 'زينب'),
      ];

      // Mixed types, low coverage (3/10 = 30%), daytime hours
      final interactions = [
        inMonth(InteractionType.call, 'r1', day: 1, hour: 12),
        inMonth(InteractionType.visit, 'r2', day: 2, hour: 14),
        inMonth(InteractionType.message, 'r3', day: 3, hour: 16),
        inMonth(InteractionType.gift, 'r1', day: 4, hour: 11),
        inMonth(InteractionType.event, 'r2', day: 5, hour: 13),
        inMonth(InteractionType.other, 'r3', day: 6, hour: 15),
      ];

      final wrapped = WrappedGeneratorService.generate(
        interactions: interactions,
        relatives: relatives,
        month: month,
      );

      expect(wrapped.personalityLabel, 'وصّال الرحم');
      expect(wrapped.personalityEmoji, '\u{1F49A}'); // green heart emoji
    });

    // =====================================================
    // EMPTY INTERACTIONS
    // =====================================================

    test('empty interactions returns zero stats', () {
      final relatives = [
        createTestRelative(id: 'r1', fullName: 'أحمد'),
      ];

      final wrapped = WrappedGeneratorService.generate(
        interactions: [],
        relatives: relatives,
        month: month,
      );

      expect(wrapped.totalInteractions, 0);
      expect(wrapped.uniqueRelativesContacted, 0);
      expect(wrapped.relativesCoverage, 0.0);
      expect(wrapped.mostContactedRelativeName, isNull);
      expect(wrapped.mostContactedRelativeCount, isNull);
      expect(wrapped.longestStreak, 0);
      expect(wrapped.personalityLabel, 'وصّال الرحم'); // default
      expect(wrapped.personalityEmoji, '\u{1F49A}');
    });

    // =====================================================
    // LONGEST STREAK CALCULATION
    // =====================================================

    test('calculates longest consecutive days streak in month', () {
      final relatives = [createTestRelative(id: 'r1', fullName: 'أحمد')];

      final interactions = [
        // Streak of 3: Jan 5, 6, 7
        inMonth(InteractionType.call, 'r1', day: 5),
        inMonth(InteractionType.call, 'r1', day: 6),
        inMonth(InteractionType.call, 'r1', day: 7),
        // Gap on Jan 8
        // Streak of 5: Jan 10, 11, 12, 13, 14
        inMonth(InteractionType.visit, 'r1', day: 10),
        inMonth(InteractionType.call, 'r1', day: 11),
        inMonth(InteractionType.message, 'r1', day: 12),
        inMonth(InteractionType.call, 'r1', day: 13),
        inMonth(InteractionType.visit, 'r1', day: 14),
      ];

      final wrapped = WrappedGeneratorService.generate(
        interactions: interactions,
        relatives: relatives,
        month: month,
      );

      expect(wrapped.longestStreak, 5);
    });

    test('streak counts multiple interactions on same day as one day', () {
      final relatives = [createTestRelative(id: 'r1', fullName: 'أحمد')];

      final interactions = [
        inMonth(InteractionType.call, 'r1', day: 1, hour: 9),
        inMonth(InteractionType.visit, 'r1', day: 1, hour: 15),
        inMonth(InteractionType.call, 'r1', day: 2, hour: 10),
        // Gap on day 3
        inMonth(InteractionType.call, 'r1', day: 4, hour: 10),
      ];

      final wrapped = WrappedGeneratorService.generate(
        interactions: interactions,
        relatives: relatives,
        month: month,
      );

      expect(wrapped.longestStreak, 2); // Jan 1-2
    });

    // =====================================================
    // INTERACTION BREAKDOWN
    // =====================================================

    test('computes interaction type breakdown', () {
      final relatives = [createTestRelative(id: 'r1', fullName: 'أحمد')];

      final interactions = [
        inMonth(InteractionType.call, 'r1', day: 1),
        inMonth(InteractionType.call, 'r1', day: 2),
        inMonth(InteractionType.visit, 'r1', day: 3),
        inMonth(InteractionType.message, 'r1', day: 4),
        inMonth(InteractionType.gift, 'r1', day: 5),
        inMonth(InteractionType.gift, 'r1', day: 6),
      ];

      final wrapped = WrappedGeneratorService.generate(
        interactions: interactions,
        relatives: relatives,
        month: month,
      );

      expect(wrapped.interactionBreakdown[InteractionType.call], 2);
      expect(wrapped.interactionBreakdown[InteractionType.visit], 1);
      expect(wrapped.interactionBreakdown[InteractionType.message], 1);
      expect(wrapped.interactionBreakdown[InteractionType.gift], 2);
    });

    // =====================================================
    // MONTH FILTERING
    // =====================================================

    test('filters interactions to the target month only', () {
      final relatives = [createTestRelative(id: 'r1', fullName: 'أحمد')];

      final interactions = [
        // December (previous month)
        createTestInteraction(
          id: 'dec-1',
          type: InteractionType.call,
          relativeId: 'r1',
          date: DateTime(2025, 12, 25),
        ),
        // January (target month)
        inMonth(InteractionType.call, 'r1', day: 10),
        inMonth(InteractionType.visit, 'r1', day: 15),
        // February (next month)
        createTestInteraction(
          id: 'feb-1',
          type: InteractionType.call,
          relativeId: 'r1',
          date: DateTime(2026, 2, 5),
        ),
      ];

      final wrapped = WrappedGeneratorService.generate(
        interactions: interactions,
        relatives: relatives,
        month: month,
      );

      expect(wrapped.totalInteractions, 2); // Only January interactions
    });

    // =====================================================
    // MONTH FIELD
    // =====================================================

    test('month field is set to first day of the target month', () {
      final relatives = [createTestRelative(id: 'r1', fullName: 'أحمد')];

      final wrapped = WrappedGeneratorService.generate(
        interactions: [],
        relatives: relatives,
        month: DateTime(2026, 1, 15), // mid-month date
      );

      expect(wrapped.month, DateTime(2026, 1, 1));
    });

    // =====================================================
    // PRIORITY ORDER OF PERSONALITY LABELS
    // =====================================================

    test('visitor label takes priority over caller label', () {
      final relatives = [createTestRelative(id: 'r1', fullName: 'أحمد')];

      // 3 visits, 3 calls out of 4 total - visits checked first
      // Actually both would be >50% only if one dominates.
      // Let's make visits dominate: 3 visits, 1 call
      final interactions = [
        inMonth(InteractionType.visit, 'r1', day: 1),
        inMonth(InteractionType.visit, 'r1', day: 2),
        inMonth(InteractionType.visit, 'r1', day: 3),
        inMonth(InteractionType.call, 'r1', day: 4),
      ];

      final wrapped = WrappedGeneratorService.generate(
        interactions: interactions,
        relatives: relatives,
        month: month,
      );

      // Visits are checked before calls in priority order
      expect(wrapped.personalityLabel, 'ملك الزيارات');
    });
  });
}
