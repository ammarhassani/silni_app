import 'package:silni_app/shared/models/interaction_model.dart';
import 'package:silni_app/shared/models/relative_model.dart';
import 'package:silni_app/features/wrapped/models/monthly_wrapped_model.dart';
import 'package:silni_app/features/wrapped/models/yearly_wrapped_model.dart';

/// Pure static service that generates a [MonthlyWrapped] summary from raw data.
///
/// No network calls or side-effects — all computation is synchronous and
/// deterministic, making it easy to unit-test.
class WrappedGeneratorService {
  WrappedGeneratorService._();

  /// Generate a monthly wrapped summary.
  ///
  /// [interactions] may contain data from any time range; the method filters
  /// to the calendar month that contains [month].
  /// [relatives] is the user's full relatives list (used for coverage).
  static MonthlyWrapped generate({
    required List<Interaction> interactions,
    required List<Relative> relatives,
    required DateTime month,
  }) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final firstOfNextMonth = DateTime(month.year, month.month + 1, 1);

    // 1. Filter to target month
    final monthInteractions = interactions.where((i) {
      return !i.date.isBefore(firstOfMonth) && i.date.isBefore(firstOfNextMonth);
    }).toList();

    final totalInteractions = monthInteractions.length;

    // 2. Per-type breakdown
    final breakdown = <InteractionType, int>{};
    for (final i in monthInteractions) {
      breakdown[i.type] = (breakdown[i.type] ?? 0) + 1;
    }

    // 3. Unique relatives contacted
    final contactedRelativeIds = monthInteractions.map((i) => i.relativeId).toSet();
    final uniqueRelativesContacted = contactedRelativeIds.length;
    final relativesCoverage =
        relatives.isEmpty ? 0.0 : uniqueRelativesContacted / relatives.length;

    // 4. Most contacted relative
    String? mostContactedRelativeName;
    int? mostContactedRelativeCount;
    if (monthInteractions.isNotEmpty) {
      final countByRelative = <String, int>{};
      for (final i in monthInteractions) {
        countByRelative[i.relativeId] = (countByRelative[i.relativeId] ?? 0) + 1;
      }

      final topEntry = countByRelative.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );

      final matchingRelative = relatives.where((r) => r.id == topEntry.key);
      if (matchingRelative.isNotEmpty) {
        mostContactedRelativeName = matchingRelative.first.fullName;
      }
      mostContactedRelativeCount = topEntry.value;
    }

    // 5. Personality label (checked in priority order, first match wins)
    final (label, emoji) = _determinePersonality(
      monthInteractions: monthInteractions,
      totalInteractions: totalInteractions,
      breakdown: breakdown,
      relativesCoverage: relativesCoverage,
    );

    // 6. Longest consecutive-day streak
    final longestStreak = _calculateLongestStreak(monthInteractions);

    // 7. Additional stats
    final mostUsedType = _mostUsedInteractionType(breakdown);
    final busiestDay = _busiestDayOfWeek(monthInteractions);
    final daysInMonth = firstOfNextMonth.difference(firstOfMonth).inDays;
    final weeksInMonth = daysInMonth / 7.0;
    final avgPerWeek =
        weeksInMonth > 0 ? totalInteractions / weeksInMonth : 0.0;

    return MonthlyWrapped(
      month: firstOfMonth,
      totalInteractions: totalInteractions,
      uniqueRelativesContacted: uniqueRelativesContacted,
      relativesCoverage: relativesCoverage,
      mostContactedRelativeName: mostContactedRelativeName,
      mostContactedRelativeCount: mostContactedRelativeCount,
      longestStreak: longestStreak,
      personalityLabel: label,
      personalityEmoji: emoji,
      interactionBreakdown: breakdown,
      mostUsedInteractionType: mostUsedType,
      busiestDayOfWeek: busiestDay,
      averageInteractionsPerWeek: avgPerWeek,
    );
  }

  /// Determine personality label and emoji based on interaction patterns.
  ///
  /// Rules are checked in order; the first match wins:
  /// 1. 50%+ visits       -> ملك الزيارات 🏠
  /// 2. 50%+ gifts        -> الكريم 🎁
  /// 3. 50%+ night (21-04)-> بومة الليل العائلية 🦉
  /// 4. 50%+ morning (05-10) -> طائر الصباح العائلي 🌅
  /// 5. 80%+ coverage     -> واصل العائلة 🤝
  /// 6. 50%+ calls        -> صاحب المكالمات 📞
  /// 7. Default           -> وصّال الرحم 💚
  static (String label, String emoji) _determinePersonality({
    required List<Interaction> monthInteractions,
    required int totalInteractions,
    required Map<InteractionType, int> breakdown,
    required double relativesCoverage,
  }) {
    if (totalInteractions == 0) {
      return ('وصّال الرحم', '\u{1F49A}');
    }

    final half = totalInteractions / 2;

    // 1. Visitor
    if ((breakdown[InteractionType.visit] ?? 0) >= half) {
      return ('ملك الزيارات', '\u{1F3E0}');
    }

    // 2. Generous / gift-giver
    if ((breakdown[InteractionType.gift] ?? 0) >= half) {
      return ('الكريم', '\u{1F381}');
    }

    // 3. Night owl (21:00 - 03:59)
    final nightCount = monthInteractions.where((i) {
      final h = i.date.hour;
      return h >= 21 || h < 4;
    }).length;
    if (nightCount >= half) {
      return ('بومة الليل العائلية', '\u{1F989}');
    }

    // 4. Morning bird (05:00 - 09:59)
    final morningCount = monthInteractions.where((i) {
      final h = i.date.hour;
      return h >= 5 && h < 10;
    }).length;
    if (morningCount >= half) {
      return ('طائر الصباح العائلي', '\u{1F305}');
    }

    // 5. Family connector (80%+ coverage)
    if (relativesCoverage >= 0.8) {
      return ('واصل العائلة', '\u{1F91D}');
    }

    // 6. Caller
    if ((breakdown[InteractionType.call] ?? 0) >= half) {
      return ('صاحب المكالمات', '\u{1F4DE}');
    }

    // 7. Default
    return ('وصّال الرحم', '\u{1F49A}');
  }

  /// Generate a yearly wrapped summary.
  ///
  /// [interactions] may contain data from any time range; the method filters
  /// to the calendar year specified by [year].
  /// [relatives] is the user's full relatives list (used for coverage).
  static YearlyWrapped generateYearly({
    required List<Interaction> interactions,
    required List<Relative> relatives,
    required int year,
  }) {
    final yearStart = DateTime(year, 1, 1);
    final yearEnd = DateTime(year + 1, 1, 1);

    // 1. Filter to target year
    final yearInteractions = interactions.where((i) {
      return !i.date.isBefore(yearStart) && i.date.isBefore(yearEnd);
    }).toList();

    final totalInteractions = yearInteractions.length;

    // 2. Per-type breakdown
    final breakdown = <InteractionType, int>{};
    for (final i in yearInteractions) {
      breakdown[i.type] = (breakdown[i.type] ?? 0) + 1;
    }

    // 3. Unique relatives contacted
    final contactedRelativeIds =
        yearInteractions.map((i) => i.relativeId).toSet();
    final uniqueRelativesContacted = contactedRelativeIds.length;
    final relativesCoverage =
        relatives.isEmpty ? 0.0 : uniqueRelativesContacted / relatives.length;

    // 4. Most contacted relative
    String? mostContactedRelativeName;
    int? mostContactedRelativeCount;
    if (yearInteractions.isNotEmpty) {
      final countByRelative = <String, int>{};
      for (final i in yearInteractions) {
        countByRelative[i.relativeId] =
            (countByRelative[i.relativeId] ?? 0) + 1;
      }

      final topEntry = countByRelative.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );

      final matchingRelative = relatives.where((r) => r.id == topEntry.key);
      if (matchingRelative.isNotEmpty) {
        mostContactedRelativeName = matchingRelative.first.fullName;
      }
      mostContactedRelativeCount = topEntry.value;
    }

    // 5. Personality label
    final (label, emoji) = _determinePersonality(
      monthInteractions: yearInteractions,
      totalInteractions: totalInteractions,
      breakdown: breakdown,
      relativesCoverage: relativesCoverage,
    );

    // 6. Longest consecutive-day streak
    final longestStreak = _calculateLongestStreak(yearInteractions);

    // 7. Total active days (unique calendar days with interactions)
    final uniqueDays = yearInteractions
        .map((i) => DateTime(i.date.year, i.date.month, i.date.day))
        .toSet();
    final totalActiveDays = uniqueDays.length;

    // 8. Monthly totals
    final monthlyTotals = <int, int>{};
    for (final i in yearInteractions) {
      monthlyTotals[i.date.month] = (monthlyTotals[i.date.month] ?? 0) + 1;
    }

    // 9. Additional stats
    final mostUsedType = _mostUsedInteractionType(breakdown);
    final busiestDay = _busiestDayOfWeek(yearInteractions);
    final avgPerMonth = totalInteractions / 12.0;
    final peak = _peakMonth(monthlyTotals);

    return YearlyWrapped(
      year: year,
      totalInteractions: totalInteractions,
      uniqueRelativesContacted: uniqueRelativesContacted,
      relativesCoverage: relativesCoverage,
      mostContactedRelativeName: mostContactedRelativeName,
      mostContactedRelativeCount: mostContactedRelativeCount,
      longestStreak: longestStreak,
      personalityLabel: label,
      personalityEmoji: emoji,
      interactionBreakdown: breakdown,
      totalActiveDays: totalActiveDays,
      monthlyTotals: monthlyTotals,
      mostUsedInteractionType: mostUsedType,
      busiestDayOfWeek: busiestDay,
      averageInteractionsPerMonth: avgPerMonth,
      peakMonth: peak?.$1,
      peakMonthCount: peak?.$2,
    );
  }

  /// Returns the [InteractionType] with the highest count, or null if empty.
  static InteractionType? _mostUsedInteractionType(
      Map<InteractionType, int> breakdown) {
    if (breakdown.isEmpty) return null;
    return breakdown.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// Returns the weekday (1=Mon…7=Sun) with the most interactions, or null.
  static int? _busiestDayOfWeek(List<Interaction> interactions) {
    if (interactions.isEmpty) return null;
    final dayCount = <int, int>{};
    for (final i in interactions) {
      final dow = i.date.weekday;
      dayCount[dow] = (dayCount[dow] ?? 0) + 1;
    }
    return dayCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// Returns the peak month (number, count) from monthly totals, or null.
  static (int, int)? _peakMonth(Map<int, int> monthlyTotals) {
    if (monthlyTotals.isEmpty) return null;
    final peak =
        monthlyTotals.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return (peak.key, peak.value);
  }

  /// Calculate the longest run of consecutive calendar days with at least
  /// one interaction within the given list.
  static int _calculateLongestStreak(List<Interaction> interactions) {
    if (interactions.isEmpty) return 0;

    // Collect unique days (year-month-day)
    final uniqueDays = interactions
        .map((i) => DateTime(i.date.year, i.date.month, i.date.day))
        .toSet()
        .toList()
      ..sort();

    int longest = 1;
    int current = 1;

    for (int i = 1; i < uniqueDays.length; i++) {
      final diff = uniqueDays[i].difference(uniqueDays[i - 1]).inDays;
      if (diff == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }

    return longest;
  }
}
