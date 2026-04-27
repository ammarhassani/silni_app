/// Streak-related events.
///
/// Streak mechanism (current_streak, longest_streak, freezes, per-relative
/// streaks) is the product's core engagement measurement. Gamification
/// (points, badges, levels, challenges) was cut in Phase 9.1; events for
/// those types live nowhere in the app.
enum StreakEventType {
  streakIncreased,
  streakMilestone, // Celebration milestones (e.g. 7, 14, 30, 50, 100 days)
  streakWarning,   // ~4 hours remaining before streak break
  streakCritical,  // ~1 hour remaining before streak break
  freezeEarned,    // Streak freeze awarded at a milestone
  freezeUsed,      // Freeze used (auto or manual) to protect a streak
}

/// A streak event triggers UI feedback (modals, snackbars, notifications).
class StreakEvent {
  final StreakEventType type;
  final String userId;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  StreakEvent({
    required this.type,
    required this.userId,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory StreakEvent.streakIncreased({
    required String userId,
    required int currentStreak,
    required int longestStreak,
  }) {
    return StreakEvent(
      type: StreakEventType.streakIncreased,
      userId: userId,
      data: {
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
      },
    );
  }

  factory StreakEvent.streakMilestone({
    required String userId,
    required int streak,
  }) {
    return StreakEvent(
      type: StreakEventType.streakMilestone,
      userId: userId,
      data: {'streak': streak},
    );
  }

  factory StreakEvent.streakWarning({
    required String userId,
    required int currentStreak,
    required Duration timeRemaining,
  }) {
    return StreakEvent(
      type: StreakEventType.streakWarning,
      userId: userId,
      data: {
        'current_streak': currentStreak,
        'hours_remaining': timeRemaining.inHours,
        'minutes_remaining': timeRemaining.inMinutes % 60,
      },
    );
  }

  factory StreakEvent.streakCritical({
    required String userId,
    required int currentStreak,
    required Duration timeRemaining,
  }) {
    return StreakEvent(
      type: StreakEventType.streakCritical,
      userId: userId,
      data: {
        'current_streak': currentStreak,
        'minutes_remaining': timeRemaining.inMinutes,
      },
    );
  }

  factory StreakEvent.freezeEarned({
    required String userId,
    required String source,
  }) {
    return StreakEvent(
      type: StreakEventType.freezeEarned,
      userId: userId,
      data: {'source': source},
    );
  }

  factory StreakEvent.freezeUsed({
    required String userId,
    required int streakProtected,
    required bool autoUsed,
  }) {
    return StreakEvent(
      type: StreakEventType.freezeUsed,
      userId: userId,
      data: {
        'streak_protected': streakProtected,
        'auto_used': autoUsed,
      },
    );
  }

  /// Streak counts that trigger a celebration milestone.
  static bool isStreakMilestone(int streak) {
    return streak == 3 ||
        streak == 7 ||
        streak == 10 ||
        streak == 14 ||
        streak == 21 ||
        streak == 30 ||
        streak == 50 ||
        streak == 100 ||
        streak == 200 ||
        streak == 365 ||
        streak == 500;
  }

  /// Streak counts that grant a freeze award.
  static bool isFreezeAwardMilestone(int streak) {
    return streak == 7 || streak == 30 || streak == 100;
  }

  // ── Convenience getters ────────────────────────────────────────────────
  int? get currentStreak =>
      data['current_streak'] as int? ?? data['streak'] as int?;
  int? get streak => currentStreak;

  @override
  String toString() =>
      'StreakEvent(type: $type, userId: $userId, data: $data, ts: $timestamp)';
}
