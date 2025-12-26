/// Warning state for a streak's deadline
enum StreakWarningState {
  safe,     // More than 4 hours remaining
  warning,  // 1-4 hours remaining
  critical, // Less than 1 hour remaining
  expired,  // Deadline has passed
}

/// Model for tracking per-relative streaks
class RelativeStreak {
  final String id;
  final String userId;
  final String relativeId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? streakDeadline;
  final DateTime? streakDayStart;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RelativeStreak({
    required this.id,
    required this.userId,
    required this.relativeId,
    required this.currentStreak,
    required this.longestStreak,
    this.streakDeadline,
    this.streakDayStart,
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if streak is endangered (less than 4 hours remaining)
  bool get isEndangered {
    if (streakDeadline == null) return false;
    final remaining = timeRemaining;
    if (remaining == null) return false;
    return !remaining.isNegative && remaining.inHours < 4;
  }

  /// Get time remaining until deadline
  Duration? get timeRemaining {
    if (streakDeadline == null) return null;
    return streakDeadline!.difference(DateTime.now().toUtc());
  }

  /// Get the warning state based on time remaining
  StreakWarningState get warningState {
    if (streakDeadline == null) return StreakWarningState.safe;
    final remaining = timeRemaining!;
    if (remaining.isNegative) return StreakWarningState.expired;
    if (remaining.inMinutes <= 60) return StreakWarningState.critical;
    if (remaining.inHours <= 4) return StreakWarningState.warning;
    return StreakWarningState.safe;
  }

  /// Format time remaining as a readable string (Arabic)
  String get formattedTimeRemaining {
    final remaining = timeRemaining;
    if (remaining == null) return '';
    if (remaining.isNegative) return 'انتهى الوقت';

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;

    if (hours > 0) {
      return '${hours}س ${minutes}د';
    }
    return '${minutes}د';
  }

  /// Create from Supabase JSON
  factory RelativeStreak.fromJson(Map<String, dynamic> json) {
    return RelativeStreak(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      relativeId: json['relative_id'] as String,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      streakDeadline: json['streak_deadline'] != null
          ? DateTime.parse(json['streak_deadline'] as String).toUtc()
          : null,
      streakDayStart: json['streak_day_start'] != null
          ? DateTime.parse(json['streak_day_start'] as String).toUtc()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON for database operations
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'relative_id': relativeId,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'streak_deadline': streakDeadline?.toIso8601String(),
      'streak_day_start': streakDayStart?.toIso8601String(),
    };
  }

  /// Copy with method for immutability
  RelativeStreak copyWith({
    String? id,
    String? userId,
    String? relativeId,
    int? currentStreak,
    int? longestStreak,
    DateTime? streakDeadline,
    DateTime? streakDayStart,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RelativeStreak(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      relativeId: relativeId ?? this.relativeId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      streakDeadline: streakDeadline ?? this.streakDeadline,
      streakDayStart: streakDayStart ?? this.streakDayStart,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'RelativeStreak(relativeId: $relativeId, streak: $currentStreak, warning: $warningState)';
  }
}
