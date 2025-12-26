/// Types of gamification events that can occur
enum GamificationEventType {
  pointsEarned,
  badgeUnlocked,
  levelUp,
  streakIncreased,
  streakMilestone, // Special: 7, 14, 30, 50, 100 days
  streakWarning, // 4 hours remaining
  streakCritical, // 1 hour remaining
  freezeEarned, // Freeze awarded at milestone
  freezeUsed, // Freeze used to protect streak
}

/// Represents a gamification event that triggers UI feedback
class GamificationEvent {
  final GamificationEventType type;
  final String userId;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  GamificationEvent({
    required this.type,
    required this.userId,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create a points earned event
  factory GamificationEvent.pointsEarned({
    required String userId,
    required int points,
    required String source, // e.g., "call", "visit"
  }) {
    return GamificationEvent(
      type: GamificationEventType.pointsEarned,
      userId: userId,
      data: {
        'points': points,
        'source': source,
      },
    );
  }

  /// Create a badge unlocked event
  factory GamificationEvent.badgeUnlocked({
    required String userId,
    required String badgeId,
    required String badgeName,
    required String badgeDescription,
  }) {
    return GamificationEvent(
      type: GamificationEventType.badgeUnlocked,
      userId: userId,
      data: {
        'badge_id': badgeId,
        'badge_name': badgeName,
        'badge_description': badgeDescription,
      },
    );
  }

  /// Create a level up event
  factory GamificationEvent.levelUp({
    required String userId,
    required int oldLevel,
    required int newLevel,
    required int currentXP,
    required int xpToNextLevel,
  }) {
    return GamificationEvent(
      type: GamificationEventType.levelUp,
      userId: userId,
      data: {
        'old_level': oldLevel,
        'new_level': newLevel,
        'current_xp': currentXP,
        'xp_to_next_level': xpToNextLevel,
      },
    );
  }

  /// Create a streak increased event
  factory GamificationEvent.streakIncreased({
    required String userId,
    required int currentStreak,
    required int longestStreak,
  }) {
    return GamificationEvent(
      type: GamificationEventType.streakIncreased,
      userId: userId,
      data: {
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
      },
    );
  }

  /// Create a streak milestone event (7, 14, 30, 50, 100 days)
  factory GamificationEvent.streakMilestone({
    required String userId,
    required int streak,
  }) {
    return GamificationEvent(
      type: GamificationEventType.streakMilestone,
      userId: userId,
      data: {
        'streak': streak,
      },
    );
  }

  /// Create a streak warning event (4 hours remaining)
  factory GamificationEvent.streakWarning({
    required String userId,
    required int currentStreak,
    required Duration timeRemaining,
  }) {
    return GamificationEvent(
      type: GamificationEventType.streakWarning,
      userId: userId,
      data: {
        'current_streak': currentStreak,
        'hours_remaining': timeRemaining.inHours,
        'minutes_remaining': timeRemaining.inMinutes % 60,
      },
    );
  }

  /// Create a streak critical event (1 hour remaining)
  factory GamificationEvent.streakCritical({
    required String userId,
    required int currentStreak,
    required Duration timeRemaining,
  }) {
    return GamificationEvent(
      type: GamificationEventType.streakCritical,
      userId: userId,
      data: {
        'current_streak': currentStreak,
        'minutes_remaining': timeRemaining.inMinutes,
      },
    );
  }

  /// Create a freeze earned event
  factory GamificationEvent.freezeEarned({
    required String userId,
    required String source, // e.g., 'milestone_7', 'milestone_30'
  }) {
    return GamificationEvent(
      type: GamificationEventType.freezeEarned,
      userId: userId,
      data: {
        'source': source,
      },
    );
  }

  /// Create a freeze used event
  factory GamificationEvent.freezeUsed({
    required String userId,
    required int streakProtected,
    required bool autoUsed,
  }) {
    return GamificationEvent(
      type: GamificationEventType.freezeUsed,
      userId: userId,
      data: {
        'streak_protected': streakProtected,
        'auto_used': autoUsed,
      },
    );
  }

  /// Check if this streak qualifies as a milestone
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

  /// Check if this streak qualifies for a freeze award
  static bool isFreezeAwardMilestone(int streak) {
    return streak == 7 || streak == 30 || streak == 100;
  }

  /// Get points from a points earned event
  int? get points => data['points'] as int?;

  /// Get badge ID from a badge unlocked event
  String? get badgeId => data['badge_id'] as String?;

  /// Get badge name from a badge unlocked event
  String? get badgeName => data['badge_name'] as String?;

  /// Get badge description from a badge unlocked event
  String? get badgeDescription => data['badge_description'] as String?;

  /// Get new level from a level up event
  int? get newLevel => data['new_level'] as int?;

  /// Get old level from a level up event
  int? get oldLevel => data['old_level'] as int?;

  /// Get current XP from a level up event
  int? get currentXP => data['current_xp'] as int?;

  /// Get XP to next level from a level up event
  int? get xpToNextLevel => data['xp_to_next_level'] as int?;

  /// Get current streak from a streak event
  int? get currentStreak => data['current_streak'] as int? ?? data['streak'] as int?;

  /// Get streak from a streak milestone event (alias for currentStreak)
  int? get streak => currentStreak;

  @override
  String toString() {
    return 'GamificationEvent(type: $type, userId: $userId, data: $data, timestamp: $timestamp)';
  }
}
