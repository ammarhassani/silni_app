import 'dart:math';

import '../../shared/models/relative_model.dart';

/// Pure static utility service for computing contact priority scores.
///
/// Scores each relative based on how overdue they are relative to their
/// expected contact frequency, weighted by their priority level.
///
/// Scoring formula: (daysSinceContact / expectedFrequency) * priorityWeight
/// - Expected frequency: priority 1 = 2 days, priority 2 = 7 days, priority 3 = 14 days
/// - Priority weight equals the priority number (1, 2, or 3)
/// - Null lastContactDate → score = 999 (maximum urgency)
class ContactPriorityService {
  ContactPriorityService._();

  /// Expected contact frequency in days based on priority level.
  /// Aligns with `Relative.needsContact` thresholds.
  static int _expectedFrequency(int priority) {
    switch (priority) {
      case 1:
        return 2; // parents, spouse
      case 2:
        return 7; // siblings, grandparents
      default:
        return 14; // extended family
    }
  }

  /// Compute the urgency score for a single relative.
  /// Higher score = more overdue / more urgent.
  static double _score(Relative relative) {
    if (relative.lastContactDate == null) return 999.0;
    final days = DateTime.now().difference(relative.lastContactDate!).inDays;
    final freq = _expectedFrequency(relative.priority);
    return (days / freq) * relative.priority;
  }

  /// Returns the top [limit] relatives ranked by contact urgency.
  ///
  /// Filters out archived relatives. Returns at most [limit] results
  /// sorted by descending urgency score.
  static List<Relative> getTodayPriority(
    List<Relative> relatives, {
    int limit = 5,
  }) {
    final active = relatives.where((r) => !r.isArchived).toList();
    active.sort((a, b) => _score(b).compareTo(_score(a)));
    return active.take(limit).toList();
  }

  /// Returns the top [limit] most overdue relatives for quick-logging.
  ///
  /// Uses the same scoring as [getTodayPriority] with a smaller default limit.
  static List<Relative> getQuickLogSuggestions(
    List<Relative> relatives, {
    int limit = 3,
  }) {
    return getTodayPriority(relatives, limit: limit);
  }

  /// Returns a family health pulse value between 0.0 and 1.0.
  ///
  /// 1.0 = everyone recently contacted (healthy)
  /// 0.0 = everyone very overdue or never contacted
  ///
  /// For each non-archived relative:
  /// - If lastContactDate is null → individual score = 0.0 (overdue)
  /// - Otherwise → individual score = 1.0 - min(1.0, daysSince / expectedFreq)
  ///
  /// The pulse is the average of all individual scores.
  static double getFamilyPulse(List<Relative> relatives) {
    final active = relatives.where((r) => !r.isArchived).toList();
    if (active.isEmpty) return 0.0;

    double totalHealth = 0.0;
    for (final relative in active) {
      if (relative.lastContactDate == null) {
        // Never contacted → score 0
        totalHealth += 0.0;
      } else {
        final days = DateTime.now().difference(relative.lastContactDate!).inDays;
        final freq = _expectedFrequency(relative.priority);
        final overdueRatio = min(1.0, days / freq);
        totalHealth += 1.0 - overdueRatio;
      }
    }

    return totalHealth / active.length;
  }
}
