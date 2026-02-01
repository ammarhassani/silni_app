import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/shared/models/interaction_model.dart';
import 'package:silni_app/features/wrapped/services/wrapped_generator_service.dart';

import '../../helpers/model_factories.dart';

void main() {
  group('WrappedGeneratorService.generateYearly', () {
    const year = 2025;

    // Helper to create interactions in the target year
    Interaction inYear(
      InteractionType type,
      String relativeId, {
      int month = 6,
      int day = 10,
      int hour = 12,
    }) {
      return createTestInteraction(
        id: '${type.value}-$relativeId-$month-$day-$hour',
        type: type,
        relativeId: relativeId,
        date: DateTime(year, month, day, hour),
      );
    }

    // =====================================================
    // EMPTY INTERACTIONS
    // =====================================================

    test('empty interactions returns zero stats', () {
      final relatives = [
        createTestRelative(id: 'r1', fullName: '\u0623\u062D\u0645\u062F'),
      ];

      final wrapped = WrappedGeneratorService.generateYearly(
        interactions: [],
        relatives: relatives,
        year: year,
      );

      expect(wrapped.year, year);
      expect(wrapped.totalInteractions, 0);
      expect(wrapped.uniqueRelativesContacted, 0);
      expect(wrapped.relativesCoverage, 0.0);
      expect(wrapped.mostContactedRelativeName, isNull);
      expect(wrapped.mostContactedRelativeCount, isNull);
      expect(wrapped.longestStreak, 0);
      expect(wrapped.personalityLabel, '\u0648\u0635\u0651\u0627\u0644 \u0627\u0644\u0631\u062D\u0645'); // وصّال الرحم
      expect(wrapped.personalityEmoji, '\u{1F49A}');
      expect(wrapped.totalActiveDays, 0);
      expect(wrapped.monthlyTotals, isEmpty);
    });

    // =====================================================
    // YEAR FILTERING
    // =====================================================

    test('filters interactions to the target year only', () {
      final relatives = [
        createTestRelative(id: 'r1', fullName: '\u0623\u062D\u0645\u062F'),
      ];

      final interactions = [
        // Previous year (2024)
        createTestInteraction(
          id: 'prev-1',
          type: InteractionType.call,
          relativeId: 'r1',
          date: DateTime(2024, 12, 25),
        ),
        // Target year (2025)
        inYear(InteractionType.call, 'r1', month: 3, day: 10),
        inYear(InteractionType.visit, 'r1', month: 7, day: 15),
        // Next year (2026)
        createTestInteraction(
          id: 'next-1',
          type: InteractionType.call,
          relativeId: 'r1',
          date: DateTime(2026, 1, 5),
        ),
      ];

      final wrapped = WrappedGeneratorService.generateYearly(
        interactions: interactions,
        relatives: relatives,
        year: year,
      );

      expect(wrapped.totalInteractions, 2); // Only 2025 interactions
    });

    // =====================================================
    // BASIC STATS COMPUTATION
    // =====================================================

    test('computes basic stats: total interactions, unique relatives, coverage', () {
      final relatives = [
        createTestRelative(id: 'r1', fullName: '\u0623\u062D\u0645\u062F'),
        createTestRelative(id: 'r2', fullName: '\u0641\u0627\u0637\u0645\u0629'),
        createTestRelative(id: 'r3', fullName: '\u062E\u0627\u0644\u062F'),
        createTestRelative(id: 'r4', fullName: '\u0633\u0627\u0631\u0629'),
        createTestRelative(id: 'r5', fullName: '\u0639\u0645\u0631'),
      ];

      final interactions = [
        inYear(InteractionType.call, 'r1', month: 1, day: 1),
        inYear(InteractionType.visit, 'r2', month: 3, day: 2),
        inYear(InteractionType.message, 'r3', month: 5, day: 3),
        inYear(InteractionType.call, 'r1', month: 7, day: 4),
      ];

      final wrapped = WrappedGeneratorService.generateYearly(
        interactions: interactions,
        relatives: relatives,
        year: year,
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
        createTestRelative(id: 'r1', fullName: '\u0623\u062D\u0645\u062F'),
        createTestRelative(id: 'r2', fullName: '\u0641\u0627\u0637\u0645\u0629'),
      ];

      final interactions = [
        inYear(InteractionType.call, 'r1', month: 1, day: 1),
        inYear(InteractionType.call, 'r1', month: 2, day: 2),
        inYear(InteractionType.call, 'r1', month: 3, day: 3),
        inYear(InteractionType.visit, 'r2', month: 4, day: 4),
      ];

      final wrapped = WrappedGeneratorService.generateYearly(
        interactions: interactions,
        relatives: relatives,
        year: year,
      );

      expect(wrapped.mostContactedRelativeName, '\u0623\u062D\u0645\u062F'); // أحمد
      expect(wrapped.mostContactedRelativeCount, 3);
    });

    // =====================================================
    // LONGEST STREAK CALCULATION
    // =====================================================

    test('calculates longest consecutive days streak across year', () {
      final relatives = [
        createTestRelative(id: 'r1', fullName: '\u0623\u062D\u0645\u062F'),
      ];

      final interactions = [
        // Streak of 3: Jan 5, 6, 7
        inYear(InteractionType.call, 'r1', month: 1, day: 5),
        inYear(InteractionType.call, 'r1', month: 1, day: 6),
        inYear(InteractionType.call, 'r1', month: 1, day: 7),
        // Gap
        // Streak of 5: Mar 10, 11, 12, 13, 14
        inYear(InteractionType.visit, 'r1', month: 3, day: 10),
        inYear(InteractionType.call, 'r1', month: 3, day: 11),
        inYear(InteractionType.message, 'r1', month: 3, day: 12),
        inYear(InteractionType.call, 'r1', month: 3, day: 13),
        inYear(InteractionType.visit, 'r1', month: 3, day: 14),
      ];

      final wrapped = WrappedGeneratorService.generateYearly(
        interactions: interactions,
        relatives: relatives,
        year: year,
      );

      expect(wrapped.longestStreak, 5);
    });

    // =====================================================
    // TOTAL ACTIVE DAYS
    // =====================================================

    test('calculates totalActiveDays correctly', () {
      final relatives = [
        createTestRelative(id: 'r1', fullName: '\u0623\u062D\u0645\u062F'),
      ];

      final interactions = [
        // 3 unique days (two interactions on Jan 5)
        inYear(InteractionType.call, 'r1', month: 1, day: 5, hour: 9),
        inYear(InteractionType.visit, 'r1', month: 1, day: 5, hour: 15),
        inYear(InteractionType.call, 'r1', month: 3, day: 10),
        inYear(InteractionType.call, 'r1', month: 7, day: 20),
      ];

      final wrapped = WrappedGeneratorService.generateYearly(
        interactions: interactions,
        relatives: relatives,
        year: year,
      );

      expect(wrapped.totalActiveDays, 3); // Jan 5, Mar 10, Jul 20
    });

    // =====================================================
    // MONTHLY TOTALS
    // =====================================================

    test('computes monthlyTotals correctly', () {
      final relatives = [
        createTestRelative(id: 'r1', fullName: '\u0623\u062D\u0645\u062F'),
      ];

      final interactions = [
        inYear(InteractionType.call, 'r1', month: 1, day: 1),
        inYear(InteractionType.call, 'r1', month: 1, day: 5),
        inYear(InteractionType.visit, 'r1', month: 3, day: 10),
        inYear(InteractionType.call, 'r1', month: 3, day: 15),
        inYear(InteractionType.call, 'r1', month: 3, day: 20),
        inYear(InteractionType.message, 'r1', month: 12, day: 25),
      ];

      final wrapped = WrappedGeneratorService.generateYearly(
        interactions: interactions,
        relatives: relatives,
        year: year,
      );

      expect(wrapped.monthlyTotals[1], 2); // January
      expect(wrapped.monthlyTotals[3], 3); // March
      expect(wrapped.monthlyTotals[12], 1); // December
      expect(wrapped.monthlyTotals[6], isNull); // June — no interactions
    });

    // =====================================================
    // INTERACTION BREAKDOWN
    // =====================================================

    test('computes interaction type breakdown', () {
      final relatives = [
        createTestRelative(id: 'r1', fullName: '\u0623\u062D\u0645\u062F'),
      ];

      final interactions = [
        inYear(InteractionType.call, 'r1', month: 1, day: 1),
        inYear(InteractionType.call, 'r1', month: 2, day: 2),
        inYear(InteractionType.visit, 'r1', month: 3, day: 3),
        inYear(InteractionType.message, 'r1', month: 4, day: 4),
        inYear(InteractionType.gift, 'r1', month: 5, day: 5),
        inYear(InteractionType.gift, 'r1', month: 6, day: 6),
      ];

      final wrapped = WrappedGeneratorService.generateYearly(
        interactions: interactions,
        relatives: relatives,
        year: year,
      );

      expect(wrapped.interactionBreakdown[InteractionType.call], 2);
      expect(wrapped.interactionBreakdown[InteractionType.visit], 1);
      expect(wrapped.interactionBreakdown[InteractionType.message], 1);
      expect(wrapped.interactionBreakdown[InteractionType.gift], 2);
    });

    // =====================================================
    // PERSONALITY LABELS (reuses same rules as monthly)
    // =====================================================

    test('personality label: visitor (50%+ visits)', () {
      final relatives = [
        createTestRelative(id: 'r1', fullName: '\u0623\u062D\u0645\u062F'),
      ];

      final interactions = [
        inYear(InteractionType.visit, 'r1', month: 1, day: 1),
        inYear(InteractionType.visit, 'r1', month: 3, day: 2),
        inYear(InteractionType.visit, 'r1', month: 5, day: 3),
        inYear(InteractionType.call, 'r1', month: 7, day: 4),
      ];

      final wrapped = WrappedGeneratorService.generateYearly(
        interactions: interactions,
        relatives: relatives,
        year: year,
      );

      expect(wrapped.personalityLabel, '\u0645\u0644\u0643 \u0627\u0644\u0632\u064A\u0627\u0631\u0627\u062A'); // ملك الزيارات
      expect(wrapped.personalityEmoji, '\u{1F3E0}');
    });

    test('personality label: generous (50%+ gifts)', () {
      final relatives = [
        createTestRelative(id: 'r1', fullName: '\u0623\u062D\u0645\u062F'),
      ];

      final interactions = [
        inYear(InteractionType.gift, 'r1', month: 1, day: 1),
        inYear(InteractionType.gift, 'r1', month: 3, day: 2),
        inYear(InteractionType.gift, 'r1', month: 5, day: 3),
        inYear(InteractionType.call, 'r1', month: 7, day: 4),
      ];

      final wrapped = WrappedGeneratorService.generateYearly(
        interactions: interactions,
        relatives: relatives,
        year: year,
      );

      expect(wrapped.personalityLabel, '\u0627\u0644\u0643\u0631\u064A\u0645'); // الكريم
      expect(wrapped.personalityEmoji, '\u{1F381}');
    });

    test('personality label: family connector (80%+ coverage)', () {
      final relatives = [
        createTestRelative(id: 'r1', fullName: '\u0623\u062D\u0645\u062F'),
        createTestRelative(id: 'r2', fullName: '\u0641\u0627\u0637\u0645\u0629'),
        createTestRelative(id: 'r3', fullName: '\u062E\u0627\u0644\u062F'),
        createTestRelative(id: 'r4', fullName: '\u0633\u0627\u0631\u0629'),
        createTestRelative(id: 'r5', fullName: '\u0639\u0645\u0631'),
      ];

      // Contact 4/5 = 80%, mixed types so no single type dominates
      final interactions = [
        inYear(InteractionType.call, 'r1', month: 1, day: 1),
        inYear(InteractionType.visit, 'r2', month: 3, day: 2),
        inYear(InteractionType.message, 'r3', month: 5, day: 3),
        inYear(InteractionType.gift, 'r4', month: 7, day: 4),
      ];

      final wrapped = WrappedGeneratorService.generateYearly(
        interactions: interactions,
        relatives: relatives,
        year: year,
      );

      expect(wrapped.personalityLabel, '\u0648\u0627\u0635\u0644 \u0627\u0644\u0639\u0627\u0626\u0644\u0629'); // واصل العائلة
      expect(wrapped.personalityEmoji, '\u{1F91D}');
    });

    test('personality label: default for mixed interactions', () {
      final relatives = List.generate(
        10,
        (i) => createTestRelative(id: 'r$i', fullName: 'Relative $i'),
      );

      // Mixed types, low coverage, daytime hours
      final interactions = [
        inYear(InteractionType.call, 'r0', month: 1, day: 1, hour: 12),
        inYear(InteractionType.visit, 'r1', month: 2, day: 2, hour: 14),
        inYear(InteractionType.message, 'r2', month: 3, day: 3, hour: 16),
        inYear(InteractionType.gift, 'r0', month: 4, day: 4, hour: 11),
        inYear(InteractionType.event, 'r1', month: 5, day: 5, hour: 13),
        inYear(InteractionType.other, 'r2', month: 6, day: 6, hour: 15),
      ];

      final wrapped = WrappedGeneratorService.generateYearly(
        interactions: interactions,
        relatives: relatives,
        year: year,
      );

      expect(wrapped.personalityLabel, '\u0648\u0635\u0651\u0627\u0644 \u0627\u0644\u0631\u062D\u0645'); // وصّال الرحم
      expect(wrapped.personalityEmoji, '\u{1F49A}');
    });

    // =====================================================
    // YEAR FIELD
    // =====================================================

    test('year field is set correctly', () {
      final relatives = [
        createTestRelative(id: 'r1', fullName: '\u0623\u062D\u0645\u062F'),
      ];

      final wrapped = WrappedGeneratorService.generateYearly(
        interactions: [],
        relatives: relatives,
        year: 2025,
      );

      expect(wrapped.year, 2025);
    });

    // =====================================================
    // FULL YEAR SPAN
    // =====================================================

    test('handles interactions spanning full year (Jan to Dec)', () {
      final relatives = [
        createTestRelative(id: 'r1', fullName: '\u0623\u062D\u0645\u062F'),
      ];

      // One interaction per month
      final interactions = List.generate(12, (i) {
        return inYear(
          InteractionType.call,
          'r1',
          month: i + 1,
          day: 15,
        );
      });

      final wrapped = WrappedGeneratorService.generateYearly(
        interactions: interactions,
        relatives: relatives,
        year: year,
      );

      expect(wrapped.totalInteractions, 12);
      expect(wrapped.totalActiveDays, 12);
      expect(wrapped.monthlyTotals.length, 12);

      // Each month should have exactly 1
      for (int m = 1; m <= 12; m++) {
        expect(wrapped.monthlyTotals[m], 1);
      }
    });

    // =====================================================
    // EMPTY RELATIVES LIST
    // =====================================================

    test('handles empty relatives list without errors', () {
      final interactions = [
        inYear(InteractionType.call, 'r1', month: 1, day: 1),
      ];

      final wrapped = WrappedGeneratorService.generateYearly(
        interactions: interactions,
        relatives: [],
        year: year,
      );

      expect(wrapped.totalInteractions, 1);
      expect(wrapped.relativesCoverage, 0.0);
      expect(wrapped.mostContactedRelativeName, isNull); // no matching relative
      expect(wrapped.mostContactedRelativeCount, 1);
    });
  });
}
