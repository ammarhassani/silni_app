import '../../../core/config/supabase_config.dart';
import '../services/family_group_service.dart';

/// A single entry in the weekly family group leaderboard.
///
/// Tracks how many interactions a member logged and how many unique
/// relatives they contacted during the current week.
class LeaderboardEntry {
  final String userId;
  final String? displayName;
  final int interactionCount;
  final int uniqueRelatives;
  final int rank;

  const LeaderboardEntry({
    required this.userId,
    this.displayName,
    required this.interactionCount,
    required this.uniqueRelatives,
    required this.rank,
  });

  /// Create a copy with optional field overrides.
  LeaderboardEntry copyWith({
    String? userId,
    String? displayName,
    int? interactionCount,
    int? uniqueRelatives,
    int? rank,
  }) {
    return LeaderboardEntry(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      interactionCount: interactionCount ?? this.interactionCount,
      uniqueRelatives: uniqueRelatives ?? this.uniqueRelatives,
      rank: rank ?? this.rank,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaderboardEntry &&
        other.userId == userId &&
        other.rank == rank &&
        other.interactionCount == interactionCount &&
        other.uniqueRelatives == uniqueRelatives;
  }

  @override
  int get hashCode => Object.hash(userId, rank, interactionCount, uniqueRelatives);

  @override
  String toString() =>
      'LeaderboardEntry(userId: $userId, rank: $rank, '
      'interactions: $interactionCount, uniqueRelatives: $uniqueRelatives)';
}

/// Static service for computing weekly leaderboard rankings.
///
/// Follows the project convention of private constructor + static methods.
/// Queries interactions for all group members in the current Saudi week
/// (Saturday to Friday) and ranks them by interaction count.
class LeaderboardService {
  LeaderboardService._();

  /// Get weekly leaderboard for a family group.
  ///
  /// Queries interactions for all group members in the current week
  /// (Saturday to Friday, matching Saudi week). Returns entries sorted
  /// by interaction count (descending), then by unique relatives contacted.
  ///
  /// The N+1 query pattern is acceptable here since family groups are
  /// typically small (5-20 members).
  static Future<List<LeaderboardEntry>> getWeeklyLeaderboard(
    String groupId,
  ) async {
    final client = SupabaseConfig.client;

    // Get group members
    final members = await FamilyGroupService.getGroupMembers(groupId);
    if (members.isEmpty) return [];

    // Calculate current week bounds (Saturday start for Saudi Arabia)
    final now = DateTime.now();
    final weekStart = getSaturdayStart(now);
    final weekEnd = weekStart.add(const Duration(days: 7));

    // For each member, count their interactions this week
    final entries = <LeaderboardEntry>[];
    for (final member in members) {
      final data = await client
          .from('interactions')
          .select('id, relative_id')
          .eq('user_id', member.userId)
          .gte('date', weekStart.toUtc().toIso8601String())
          .lt('date', weekEnd.toUtc().toIso8601String());

      final interactions = data as List<dynamic>;
      final uniqueRelativeIds =
          interactions.map((i) => i['relative_id']).toSet();

      entries.add(LeaderboardEntry(
        userId: member.userId,
        displayName: null, // Resolved in UI or via profile lookup
        interactionCount: interactions.length,
        uniqueRelatives: uniqueRelativeIds.length,
        rank: 0, // Assigned after sorting
      ));
    }

    // Sort and assign ranks
    return assignRanks(entries);
  }

  /// Sort entries by interaction count (descending), then by unique relatives
  /// (descending), and assign 1-based ranks.
  ///
  /// Exposed as a public static method for testability.
  static List<LeaderboardEntry> assignRanks(List<LeaderboardEntry> entries) {
    if (entries.isEmpty) return [];

    // Sort by interaction count (descending), then by unique relatives
    final sorted = List<LeaderboardEntry>.from(entries);
    sorted.sort((a, b) {
      final cmp = b.interactionCount.compareTo(a.interactionCount);
      if (cmp != 0) return cmp;
      return b.uniqueRelatives.compareTo(a.uniqueRelatives);
    });

    // Assign 1-based ranks
    return sorted.asMap().entries.map((e) {
      return e.value.copyWith(rank: e.key + 1);
    }).toList();
  }

  /// Get the Saturday that starts the current Saudi week.
  ///
  /// In Dart's DateTime: Monday=1, Tuesday=2, ..., Saturday=6, Sunday=7.
  /// Returns midnight of the most recent Saturday (including today if Saturday).
  ///
  /// Exposed as a public static method for testability.
  static DateTime getSaturdayStart(DateTime date) {
    // DateTime.saturday == 6
    int daysSinceSaturday = (date.weekday - DateTime.saturday) % 7;
    if (daysSinceSaturday < 0) daysSinceSaturday += 7;
    final saturday = date.subtract(Duration(days: daysSinceSaturday));
    return DateTime(saturday.year, saturday.month, saturday.day);
  }
}
