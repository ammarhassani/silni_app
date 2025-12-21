import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../shared/models/interaction_model.dart';
import '../../auth/providers/auth_provider.dart';

/// Model for detailed statistics data
class DetailedStats {
  final Map<String, dynamic> userStats;
  final Map<InteractionType, int> interactionCounts;
  final List<Map<String, dynamic>> recentActivity;
  final List<Map<String, dynamic>> monthlyData;
  final List<Map<String, dynamic>> topRelatives;
  final Map<String, int> timePatterns;
  final List<Map<String, dynamic>> achievements;

  const DetailedStats({
    required this.userStats,
    required this.interactionCounts,
    required this.recentActivity,
    required this.monthlyData,
    required this.topRelatives,
    required this.timePatterns,
    required this.achievements,
  });

  static const empty = DetailedStats(
    userStats: {},
    interactionCounts: {},
    recentActivity: [],
    monthlyData: [],
    topRelatives: [],
    timePatterns: {},
    achievements: [],
  );
}

/// Parse badges from database (can be strings or maps)
List<Map<String, dynamic>> _parseBadges(dynamic badges) {
  if (badges == null) return [];
  if (badges is! List) return [];

  return badges.map((badge) {
    if (badge is Map<String, dynamic>) {
      return badge;
    } else if (badge is String) {
      return {'name': badge, 'id': badge};
    } else {
      return {'name': badge.toString(), 'id': badge.toString()};
    }
  }).toList();
}

/// Provider for loading detailed statistics
final detailedStatsProvider = FutureProvider.autoDispose<DetailedStats>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return DetailedStats.empty;

  // Load user stats
  final userResponse = await SupabaseConfig.client
      .from('users')
      .select(
        'points, level, current_streak, longest_streak, badges, total_interactions',
      )
      .eq('id', user.id)
      .single();

  // Load interaction counts by type
  final interactionsResponse = await SupabaseConfig.client
      .from('interactions')
      .select('type, relative_id, date')
      .eq('user_id', user.id);

  final Map<InteractionType, int> counts = {};
  final Map<String, int> relativeCounts = {};
  final Map<String, int> hourlyPatterns = {};

  for (final row in (interactionsResponse as List)) {
    final type = InteractionType.fromString(row['type'] as String);
    counts[type] = (counts[type] ?? 0) + 1;

    final relativeId = row['relative_id'] as String?;
    if (relativeId != null) {
      relativeCounts[relativeId] = (relativeCounts[relativeId] ?? 0) + 1;
    }

    final date = DateTime.parse(row['date'] as String);
    final hour = date.hour.toString();
    hourlyPatterns[hour] = (hourlyPatterns[hour] ?? 0) + 1;
  }

  // Load recent activity (last 7 days)
  final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
  final recentResponse = await SupabaseConfig.client
      .from('interactions')
      .select('date, type')
      .eq('user_id', user.id)
      .gte('date', sevenDaysAgo.toIso8601String())
      .order('date', ascending: true);

  // Load monthly data (last 6 months)
  final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
  final monthlyResponse = await SupabaseConfig.client
      .from('interactions')
      .select('date')
      .eq('user_id', user.id)
      .gte('date', sixMonthsAgo.toIso8601String())
      .order('date', ascending: true);

  // Process monthly data
  final Map<String, int> monthlyCounts = {};
  for (final row in (monthlyResponse as List)) {
    final date = DateTime.parse(row['date'] as String);
    final monthKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}';
    monthlyCounts[monthKey] = (monthlyCounts[monthKey] ?? 0) + 1;
  }

  // Get top relatives with names
  final topRelativesData = <Map<String, dynamic>>[];
  if (relativeCounts.isNotEmpty) {
    final sortedRelatives = relativeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topRelativeIds = sortedRelatives
        .take(5)
        .map((e) => e.key)
        .toList();

    if (topRelativeIds.isNotEmpty) {
      final relativesResponse = await SupabaseConfig.client
          .from('relatives')
          .select('id, full_name')
          .eq('user_id', user.id)
          .filter('id', 'in', topRelativeIds);

      for (final relative in (relativesResponse as List)) {
        final relativeId = relative['id'] as String;
        topRelativesData.add({
          'id': relativeId,
          'name': relative['full_name'] as String,
          'count': relativeCounts[relativeId] ?? 0,
        });
      }

      topRelativesData.sort(
        (a, b) => (b['count'] as int).compareTo(a['count'] as int),
      );
    }
  }

  return DetailedStats(
    userStats: userResponse,
    interactionCounts: counts,
    recentActivity: List<Map<String, dynamic>>.from(recentResponse as List),
    monthlyData: monthlyCounts.entries
        .map((e) => {'month': e.key, 'count': e.value})
        .toList(),
    topRelatives: topRelativesData,
    timePatterns: hourlyPatterns,
    achievements: _parseBadges(userResponse['badges']),
  );
});
