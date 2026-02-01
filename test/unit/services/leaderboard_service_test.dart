import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/features/family_groups/services/leaderboard_service.dart';

/// Unit tests for LeaderboardService and LeaderboardEntry.
///
/// Tests cover:
/// 1. getSaturdayStart — week boundary calculation for Saudi week (Sat–Fri)
/// 2. LeaderboardEntry model — copyWith, equality, toString
/// 3. assignRanks — sorting and 1-based rank assignment
/// 4. Edge cases — empty lists, ties, single entry
void main() {
  // ---------------------------------------------------------------------------
  // getSaturdayStart tests
  // ---------------------------------------------------------------------------
  group('LeaderboardService.getSaturdayStart', () {
    test('returns same day when date is Saturday', () {
      // Saturday 2026-02-07
      final saturday = DateTime(2026, 2, 7, 14, 30);
      final result = LeaderboardService.getSaturdayStart(saturday);

      expect(result, DateTime(2026, 2, 7));
      expect(result.weekday, DateTime.saturday);
    });

    test('returns previous Saturday for a Sunday', () {
      // Sunday 2026-02-08
      final sunday = DateTime(2026, 2, 8, 10, 0);
      final result = LeaderboardService.getSaturdayStart(sunday);

      expect(result, DateTime(2026, 2, 7));
      expect(result.weekday, DateTime.saturday);
    });

    test('returns previous Saturday for a Monday', () {
      // Monday 2026-02-02
      final monday = DateTime(2026, 2, 2, 9, 0);
      final result = LeaderboardService.getSaturdayStart(monday);

      expect(result, DateTime(2026, 1, 31));
      expect(result.weekday, DateTime.saturday);
    });

    test('returns previous Saturday for a Tuesday', () {
      // Tuesday 2026-02-03
      final tuesday = DateTime(2026, 2, 3);
      final result = LeaderboardService.getSaturdayStart(tuesday);

      expect(result, DateTime(2026, 1, 31));
      expect(result.weekday, DateTime.saturday);
    });

    test('returns previous Saturday for a Wednesday', () {
      // Wednesday 2026-02-04
      final wednesday = DateTime(2026, 2, 4);
      final result = LeaderboardService.getSaturdayStart(wednesday);

      expect(result, DateTime(2026, 1, 31));
      expect(result.weekday, DateTime.saturday);
    });

    test('returns previous Saturday for a Thursday', () {
      // Thursday 2026-02-05
      final thursday = DateTime(2026, 2, 5);
      final result = LeaderboardService.getSaturdayStart(thursday);

      expect(result, DateTime(2026, 1, 31));
      expect(result.weekday, DateTime.saturday);
    });

    test('returns previous Saturday for a Friday', () {
      // Friday 2026-02-06
      final friday = DateTime(2026, 2, 6, 23, 59);
      final result = LeaderboardService.getSaturdayStart(friday);

      expect(result, DateTime(2026, 1, 31));
      expect(result.weekday, DateTime.saturday);
    });

    test('returns midnight (no time component)', () {
      final dateWithTime = DateTime(2026, 2, 8, 14, 30, 45);
      final result = LeaderboardService.getSaturdayStart(dateWithTime);

      expect(result.hour, 0);
      expect(result.minute, 0);
      expect(result.second, 0);
    });

    test('handles year boundary (January 1 crossing back to December)', () {
      // Thursday 2026-01-01
      final newYear = DateTime(2026, 1, 1);
      final result = LeaderboardService.getSaturdayStart(newYear);

      // Previous Saturday is December 27, 2025
      expect(result, DateTime(2025, 12, 27));
      expect(result.weekday, DateTime.saturday);
    });
  });

  // ---------------------------------------------------------------------------
  // LeaderboardEntry model tests
  // ---------------------------------------------------------------------------
  group('LeaderboardEntry', () {
    test('creates instance with required fields', () {
      const entry = LeaderboardEntry(
        userId: 'user-1',
        interactionCount: 10,
        uniqueRelatives: 5,
        rank: 1,
      );

      expect(entry.userId, 'user-1');
      expect(entry.interactionCount, 10);
      expect(entry.uniqueRelatives, 5);
      expect(entry.rank, 1);
      expect(entry.displayName, isNull);
    });

    test('creates instance with display name', () {
      const entry = LeaderboardEntry(
        userId: 'user-1',
        displayName: 'طلال',
        interactionCount: 7,
        uniqueRelatives: 3,
        rank: 1,
      );

      expect(entry.displayName, 'طلال');
    });

    test('copyWith creates modified copy', () {
      const original = LeaderboardEntry(
        userId: 'user-1',
        interactionCount: 10,
        uniqueRelatives: 5,
        rank: 0,
      );

      final modified = original.copyWith(rank: 1, displayName: 'أحمد');

      expect(modified.rank, 1);
      expect(modified.displayName, 'أحمد');
      expect(modified.userId, 'user-1');
      expect(modified.interactionCount, 10);
      expect(modified.uniqueRelatives, 5);
    });

    test('copyWith with no changes returns equivalent object', () {
      const original = LeaderboardEntry(
        userId: 'user-1',
        interactionCount: 10,
        uniqueRelatives: 5,
        rank: 1,
      );

      final copy = original.copyWith();

      expect(copy, equals(original));
    });

    test('equality is based on userId, rank, interactionCount, uniqueRelatives',
        () {
      const entry1 = LeaderboardEntry(
        userId: 'user-1',
        interactionCount: 10,
        uniqueRelatives: 5,
        rank: 1,
      );

      const entry2 = LeaderboardEntry(
        userId: 'user-1',
        interactionCount: 10,
        uniqueRelatives: 5,
        rank: 1,
      );

      expect(entry1, equals(entry2));
      expect(entry1.hashCode, equals(entry2.hashCode));
    });

    test('different entries are not equal', () {
      const entry1 = LeaderboardEntry(
        userId: 'user-1',
        interactionCount: 10,
        uniqueRelatives: 5,
        rank: 1,
      );

      const entry2 = LeaderboardEntry(
        userId: 'user-2',
        interactionCount: 10,
        uniqueRelatives: 5,
        rank: 2,
      );

      expect(entry1, isNot(equals(entry2)));
    });

    test('toString returns readable representation', () {
      const entry = LeaderboardEntry(
        userId: 'user-1',
        interactionCount: 10,
        uniqueRelatives: 5,
        rank: 1,
      );

      final str = entry.toString();

      expect(str, contains('user-1'));
      expect(str, contains('rank: 1'));
      expect(str, contains('interactions: 10'));
      expect(str, contains('uniqueRelatives: 5'));
    });
  });

  // ---------------------------------------------------------------------------
  // assignRanks tests
  // ---------------------------------------------------------------------------
  group('LeaderboardService.assignRanks', () {
    test('empty list returns empty', () {
      final result = LeaderboardService.assignRanks([]);
      expect(result, isEmpty);
    });

    test('single entry gets rank 1', () {
      final entries = [
        const LeaderboardEntry(
          userId: 'user-1',
          interactionCount: 5,
          uniqueRelatives: 3,
          rank: 0,
        ),
      ];

      final result = LeaderboardService.assignRanks(entries);

      expect(result.length, 1);
      expect(result[0].rank, 1);
      expect(result[0].userId, 'user-1');
    });

    test('higher interaction count ranks first', () {
      final entries = [
        const LeaderboardEntry(
          userId: 'low',
          interactionCount: 3,
          uniqueRelatives: 2,
          rank: 0,
        ),
        const LeaderboardEntry(
          userId: 'high',
          interactionCount: 10,
          uniqueRelatives: 5,
          rank: 0,
        ),
        const LeaderboardEntry(
          userId: 'mid',
          interactionCount: 7,
          uniqueRelatives: 4,
          rank: 0,
        ),
      ];

      final result = LeaderboardService.assignRanks(entries);

      expect(result[0].userId, 'high');
      expect(result[0].rank, 1);
      expect(result[1].userId, 'mid');
      expect(result[1].rank, 2);
      expect(result[2].userId, 'low');
      expect(result[2].rank, 3);
    });

    test('same interaction count, higher unique relatives ranks first', () {
      final entries = [
        const LeaderboardEntry(
          userId: 'fewer-relatives',
          interactionCount: 10,
          uniqueRelatives: 3,
          rank: 0,
        ),
        const LeaderboardEntry(
          userId: 'more-relatives',
          interactionCount: 10,
          uniqueRelatives: 7,
          rank: 0,
        ),
      ];

      final result = LeaderboardService.assignRanks(entries);

      expect(result[0].userId, 'more-relatives');
      expect(result[0].rank, 1);
      expect(result[1].userId, 'fewer-relatives');
      expect(result[1].rank, 2);
    });

    test('ranks are 1-based sequential', () {
      final entries = [
        const LeaderboardEntry(
          userId: 'a',
          interactionCount: 10,
          uniqueRelatives: 5,
          rank: 0,
        ),
        const LeaderboardEntry(
          userId: 'b',
          interactionCount: 8,
          uniqueRelatives: 4,
          rank: 0,
        ),
        const LeaderboardEntry(
          userId: 'c',
          interactionCount: 6,
          uniqueRelatives: 3,
          rank: 0,
        ),
        const LeaderboardEntry(
          userId: 'd',
          interactionCount: 4,
          uniqueRelatives: 2,
          rank: 0,
        ),
        const LeaderboardEntry(
          userId: 'e',
          interactionCount: 2,
          uniqueRelatives: 1,
          rank: 0,
        ),
      ];

      final result = LeaderboardService.assignRanks(entries);

      for (var i = 0; i < result.length; i++) {
        expect(result[i].rank, i + 1);
      }
    });

    test('does not mutate original list', () {
      final entries = [
        const LeaderboardEntry(
          userId: 'low',
          interactionCount: 1,
          uniqueRelatives: 1,
          rank: 0,
        ),
        const LeaderboardEntry(
          userId: 'high',
          interactionCount: 10,
          uniqueRelatives: 5,
          rank: 0,
        ),
      ];

      LeaderboardService.assignRanks(entries);

      // Original list should be unchanged
      expect(entries[0].userId, 'low');
      expect(entries[1].userId, 'high');
    });

    test('preserves all entry data after ranking', () {
      final entries = [
        const LeaderboardEntry(
          userId: 'user-1',
          displayName: 'طلال',
          interactionCount: 10,
          uniqueRelatives: 5,
          rank: 0,
        ),
      ];

      final result = LeaderboardService.assignRanks(entries);

      expect(result[0].userId, 'user-1');
      expect(result[0].displayName, 'طلال');
      expect(result[0].interactionCount, 10);
      expect(result[0].uniqueRelatives, 5);
      expect(result[0].rank, 1);
    });

    test('handles entries with zero interactions', () {
      final entries = [
        const LeaderboardEntry(
          userId: 'active',
          interactionCount: 5,
          uniqueRelatives: 3,
          rank: 0,
        ),
        const LeaderboardEntry(
          userId: 'inactive',
          interactionCount: 0,
          uniqueRelatives: 0,
          rank: 0,
        ),
      ];

      final result = LeaderboardService.assignRanks(entries);

      expect(result[0].userId, 'active');
      expect(result[0].rank, 1);
      expect(result[1].userId, 'inactive');
      expect(result[1].rank, 2);
    });

    test('handles all entries with same count', () {
      final entries = [
        const LeaderboardEntry(
          userId: 'a',
          interactionCount: 5,
          uniqueRelatives: 3,
          rank: 0,
        ),
        const LeaderboardEntry(
          userId: 'b',
          interactionCount: 5,
          uniqueRelatives: 3,
          rank: 0,
        ),
        const LeaderboardEntry(
          userId: 'c',
          interactionCount: 5,
          uniqueRelatives: 3,
          rank: 0,
        ),
      ];

      final result = LeaderboardService.assignRanks(entries);

      // All get sequential ranks even if tied
      expect(result.length, 3);
      expect(result[0].rank, 1);
      expect(result[1].rank, 2);
      expect(result[2].rank, 3);
    });
  });
}
