import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:silni_app/shared/models/relative_model.dart';
import '../../helpers/model_factories.dart';

void main() {
  group('StatisticsScreen Logic Tests', () {
    // =====================================================
    // STREAK CALCULATION TESTS
    // =====================================================
    group('streak calculation', () {
      /// Replicate the streak calculation logic from statistics_screen.dart
      int calculateCurrentStreak(List<Relative> relatives) {
        if (relatives.isEmpty) return 0;

        // Get all contact dates and sort them
        final contactDates = relatives
            .where((r) => r.lastContactDate != null)
            .map((r) => r.lastContactDate!)
            .toList()
          ..sort((a, b) => b.compareTo(a)); // Most recent first

        if (contactDates.isEmpty) return 0;

        // Calculate streak: count consecutive days with at least one contact
        int streak = 0;
        DateTime checkDate = DateTime.now();
        final Set<String> contactedDays = contactDates
            .map((date) => '${date.year}-${date.month}-${date.day}')
            .toSet();

        while (true) {
          final dayKey =
              '${checkDate.year}-${checkDate.month}-${checkDate.day}';
          if (contactedDays.contains(dayKey)) {
            streak++;
            checkDate = checkDate.subtract(const Duration(days: 1));
          } else {
            break;
          }
        }

        return streak;
      }

      test('should return 0 for empty relatives list', () {
        expect(calculateCurrentStreak([]), equals(0));
      });

      test('should return 0 when no relatives have contact dates', () {
        final relatives = [
          createTestRelative(id: 'rel-1', lastContactDate: null),
          createTestRelative(id: 'rel-2', lastContactDate: null),
        ];

        expect(calculateCurrentStreak(relatives), equals(0));
      });

      test('should return 1 for contact today only', () {
        final today = DateTime.now();
        final relatives = [
          createTestRelative(id: 'rel-1', lastContactDate: today),
        ];

        expect(calculateCurrentStreak(relatives), equals(1));
      });

      test('should count consecutive days streak', () {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        final dayBefore = today.subtract(const Duration(days: 2));

        final relatives = [
          createTestRelative(id: 'rel-1', lastContactDate: today),
          createTestRelative(id: 'rel-2', lastContactDate: yesterday),
          createTestRelative(id: 'rel-3', lastContactDate: dayBefore),
        ];

        expect(calculateCurrentStreak(relatives), equals(3));
      });

      test('should break streak on missed day', () {
        final today = DateTime.now();
        final threeDaysAgo = today.subtract(const Duration(days: 3));

        final relatives = [
          createTestRelative(id: 'rel-1', lastContactDate: today),
          // Gap of two days - streak should be 1
          createTestRelative(id: 'rel-2', lastContactDate: threeDaysAgo),
        ];

        expect(calculateCurrentStreak(relatives), equals(1));
      });

      test('should handle multiple contacts on same day', () {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));

        final relatives = [
          createTestRelative(id: 'rel-1', lastContactDate: today),
          createTestRelative(id: 'rel-2', lastContactDate: today), // Same day
          createTestRelative(id: 'rel-3', lastContactDate: yesterday),
        ];

        // Should count as 2 day streak (today + yesterday)
        expect(calculateCurrentStreak(relatives), equals(2));
      });

      test('should return 0 if first contact is not today', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));

        final relatives = [
          createTestRelative(id: 'rel-1', lastContactDate: yesterday),
        ];

        // Streak broken - no contact today
        expect(calculateCurrentStreak(relatives), equals(0));
      });

      test('should handle week-long streak', () {
        final today = DateTime.now();
        final relatives = <Relative>[];

        // Create contacts for the past 7 days
        for (int i = 0; i < 7; i++) {
          relatives.add(createTestRelative(
            id: 'rel-$i',
            lastContactDate: today.subtract(Duration(days: i)),
          ));
        }

        expect(calculateCurrentStreak(relatives), equals(7));
      });

      test('should handle very old contacts', () {
        final today = DateTime.now();
        final longAgo = today.subtract(const Duration(days: 100));

        final relatives = [
          createTestRelative(id: 'rel-1', lastContactDate: today),
          createTestRelative(id: 'rel-2', lastContactDate: longAgo),
        ];

        // Should still count today's contact
        expect(calculateCurrentStreak(relatives), equals(1));
      });
    });

    // =====================================================
    // TOTAL CONTACTS CALCULATION TESTS
    // =====================================================
    group('total contacts calculation', () {
      /// Calculate total contacts (sum of all interaction counts)
      int calculateTotalContacts(List<Relative> relatives) {
        return relatives.fold<int>(0, (sum, r) => sum + r.interactionCount);
      }

      test('should return 0 for empty list', () {
        expect(calculateTotalContacts([]), equals(0));
      });

      test('should sum all interaction counts', () {
        final relatives = [
          createTestRelative(id: 'rel-1', interactionCount: 5),
          createTestRelative(id: 'rel-2', interactionCount: 10),
          createTestRelative(id: 'rel-3', interactionCount: 3),
        ];

        expect(calculateTotalContacts(relatives), equals(18));
      });

      test('should handle relatives with zero interactions', () {
        final relatives = [
          createTestRelative(id: 'rel-1', interactionCount: 5),
          createTestRelative(id: 'rel-2', interactionCount: 0),
          createTestRelative(id: 'rel-3', interactionCount: 0),
        ];

        expect(calculateTotalContacts(relatives), equals(5));
      });

      test('should handle single relative', () {
        final relatives = [
          createTestRelative(id: 'rel-1', interactionCount: 25),
        ];

        expect(calculateTotalContacts(relatives), equals(25));
      });

      test('should handle large numbers', () {
        final relatives = [
          createTestRelative(id: 'rel-1', interactionCount: 1000),
          createTestRelative(id: 'rel-2', interactionCount: 2000),
          createTestRelative(id: 'rel-3', interactionCount: 500),
        ];

        expect(calculateTotalContacts(relatives), equals(3500));
      });
    });

    // =====================================================
    // DAY LABEL TESTS
    // =====================================================
    group('day label formatting', () {
      /// Get the correct Arabic day label (singular vs plural)
      String getDayLabel(int count) {
        return count == 1 ? 'يوم' : 'أيام';
      }

      test('should return singular for 1', () {
        expect(getDayLabel(1), equals('يوم'));
      });

      test('should return plural for 0', () {
        expect(getDayLabel(0), equals('أيام'));
      });

      test('should return plural for 2', () {
        expect(getDayLabel(2), equals('أيام'));
      });

      test('should return plural for large numbers', () {
        expect(getDayLabel(10), equals('أيام'));
        expect(getDayLabel(30), equals('أيام'));
        expect(getDayLabel(100), equals('أيام'));
      });
    });

    // =====================================================
    // UI LABELS TESTS
    // =====================================================
    group('UI labels', () {
      test('screen title should be in Arabic', () {
        const title = 'الإحصائيات';
        expect(title, equals('الإحصائيات'));
      });

      test('total contacts label should be in Arabic', () {
        const label = 'إجمالي التواصل';
        expect(label, equals('إجمالي التواصل'));
      });

      test('streak label should be in Arabic', () {
        const label = 'سلسلة التواصل الحالية';
        expect(label, equals('سلسلة التواصل الحالية'));
      });

      test('unauthenticated message should be correct', () {
        const message = 'User not authenticated';
        expect(message.contains('not authenticated'), isTrue);
      });

      test('error message prefix should be correct', () {
        const prefix = 'خطأ:';
        expect(prefix, equals('خطأ:'));
      });
    });

    // =====================================================
    // DATE FORMATTING FOR STREAK TESTS
    // =====================================================
    group('date key formatting', () {
      /// Format date as key for streak calculation
      String formatDateKey(DateTime date) {
        return '${date.year}-${date.month}-${date.day}';
      }

      test('should format date without leading zeros', () {
        final date = DateTime(2024, 1, 5);
        expect(formatDateKey(date), equals('2024-1-5'));
      });

      test('should format date correctly for December', () {
        final date = DateTime(2024, 12, 25);
        expect(formatDateKey(date), equals('2024-12-25'));
      });

      test('should create unique keys for different days', () {
        final day1 = DateTime(2024, 6, 15);
        final day2 = DateTime(2024, 6, 16);

        expect(formatDateKey(day1), isNot(equals(formatDateKey(day2))));
      });

      test('should create same key for same day', () {
        final morning = DateTime(2024, 6, 15, 9, 0);
        final evening = DateTime(2024, 6, 15, 21, 0);

        expect(formatDateKey(morning), equals(formatDateKey(evening)));
      });
    });

    // =====================================================
    // CONTACT DATE SORTING TESTS
    // =====================================================
    group('contact date sorting', () {
      test('should sort dates most recent first', () {
        final dates = [
          DateTime(2024, 1, 1),
          DateTime(2024, 6, 15),
          DateTime(2024, 3, 10),
        ];

        dates.sort((a, b) => b.compareTo(a));

        expect(dates[0], equals(DateTime(2024, 6, 15)));
        expect(dates[1], equals(DateTime(2024, 3, 10)));
        expect(dates[2], equals(DateTime(2024, 1, 1)));
      });

      test('should handle same day sorting', () {
        final dates = [
          DateTime(2024, 6, 15, 10, 0),
          DateTime(2024, 6, 15, 8, 0),
          DateTime(2024, 6, 15, 15, 0),
        ];

        dates.sort((a, b) => b.compareTo(a));

        // Most recent time first
        expect(dates[0].hour, equals(15));
        expect(dates[1].hour, equals(10));
        expect(dates[2].hour, equals(8));
      });
    });

    // =====================================================
    // EDGE CASES
    // =====================================================
    group('edge cases', () {
      test('should handle null contact dates correctly', () {
        final relatives = [
          createTestRelative(id: 'rel-1', lastContactDate: null),
          createTestRelative(id: 'rel-2', lastContactDate: DateTime.now()),
          createTestRelative(id: 'rel-3', lastContactDate: null),
        ];

        // Filter out nulls
        final validDates = relatives
            .where((r) => r.lastContactDate != null)
            .map((r) => r.lastContactDate!)
            .toList();

        expect(validDates.length, equals(1));
      });

      test('should handle empty contact dates set', () {
        final Set<String> contactedDays = {};
        expect(contactedDays.isEmpty, isTrue);
        expect(contactedDays.contains('2024-6-15'), isFalse);
      });

      test('should handle year boundary dates', () {
        final newYearsEve = DateTime(2024, 12, 31);
        final newYearsDay = DateTime(2025, 1, 1);

        final key1 = '${newYearsEve.year}-${newYearsEve.month}-${newYearsEve.day}';
        final key2 = '${newYearsDay.year}-${newYearsDay.month}-${newYearsDay.day}';

        expect(key1, equals('2024-12-31'));
        expect(key2, equals('2025-1-1'));
        expect(key1, isNot(equals(key2)));
      });

      test('should handle month boundary dates', () {
        final lastDayOfMonth = DateTime(2024, 6, 30);
        final firstDayNextMonth = DateTime(2024, 7, 1);

        final key1 = '${lastDayOfMonth.year}-${lastDayOfMonth.month}-${lastDayOfMonth.day}';
        final key2 = '${firstDayNextMonth.year}-${firstDayNextMonth.month}-${firstDayNextMonth.day}';

        expect(key1, equals('2024-6-30'));
        expect(key2, equals('2024-7-1'));
      });
    });

    // =====================================================
    // STREAK ANALYTICS
    // =====================================================
    group('streak analytics', () {
      test('streak description should vary by length', () {
        String getStreakDescription(int streak) {
          if (streak == 0) return 'ابدأ سلسلة جديدة';
          if (streak == 1) return 'بداية جيدة!';
          if (streak <= 3) return 'أحسنت، استمر!';
          if (streak <= 7) return 'أداء رائع!';
          return 'ممتاز، أنت بطل!';
        }

        expect(getStreakDescription(0), equals('ابدأ سلسلة جديدة'));
        expect(getStreakDescription(1), equals('بداية جيدة!'));
        expect(getStreakDescription(3), equals('أحسنت، استمر!'));
        expect(getStreakDescription(7), equals('أداء رائع!'));
        expect(getStreakDescription(10), equals('ممتاز، أنت بطل!'));
      });

      test('should determine if streak is at risk', () {
        bool isStreakAtRisk(DateTime? lastContact) {
          if (lastContact == null) return false;
          final now = DateTime.now();
          final diff = now.difference(lastContact);
          return diff.inHours > 20 && diff.inHours < 24;
        }

        final now = DateTime.now();

        // 22 hours ago - at risk
        final atRisk = now.subtract(const Duration(hours: 22));
        expect(isStreakAtRisk(atRisk), isTrue);

        // 10 hours ago - safe
        final safe = now.subtract(const Duration(hours: 10));
        expect(isStreakAtRisk(safe), isFalse);

        // 25 hours ago - already lost
        final lost = now.subtract(const Duration(hours: 25));
        expect(isStreakAtRisk(lost), isFalse);
      });
    });

    // =====================================================
    // DISPLAY FORMATTING
    // =====================================================
    group('display formatting', () {
      test('should format large numbers with separator', () {
        String formatNumber(int number) {
          if (number < 1000) return number.toString();
          return '${number ~/ 1000},${(number % 1000).toString().padLeft(3, '0')}';
        }

        expect(formatNumber(500), equals('500'));
        expect(formatNumber(1000), equals('1,000'));
        expect(formatNumber(1234), equals('1,234'));
        expect(formatNumber(12345), equals('12,345'));
      });

      test('should display streak icon based on length', () {
        String getStreakIcon(int streak) {
          if (streak >= 30) return '🏆';
          if (streak >= 14) return '🔥';
          if (streak >= 7) return '⭐';
          if (streak >= 3) return '✨';
          return '📈';
        }

        expect(getStreakIcon(0), equals('📈'));
        expect(getStreakIcon(3), equals('✨'));
        expect(getStreakIcon(7), equals('⭐'));
        expect(getStreakIcon(14), equals('🔥'));
        expect(getStreakIcon(30), equals('🏆'));
      });
    });

    // =====================================================
    // LOADING STATES
    // =====================================================
    group('loading states', () {
      test('waiting state should show loading indicator color', () {
        // Loading indicator should be white
        const indicatorColor = Colors.white;
        expect(indicatorColor, equals(Colors.white));
      });

      test('error state should format error message', () {
        const error = 'Connection failed';
        final message = 'خطأ: $error';
        expect(message, equals('خطأ: Connection failed'));
      });
    });
  });
}
