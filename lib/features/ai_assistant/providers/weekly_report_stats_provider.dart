import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../shared/models/interaction_model.dart';
import '../../auth/providers/auth_provider.dart';

/// Aggregated stats consumed by the Weekly Report screen.
///
/// Reads streak + interaction-count aggregates only — Phase 9.1 cut the
/// gamification stack so badges/points/level are no longer fetched.
class DetailedStats {
  final Map<String, dynamic> userStats;
  final Map<InteractionType, int> interactionCounts;
  final List<Map<String, dynamic>> recentActivity;
  final List<Map<String, dynamic>> monthlyData;
  final List<Map<String, dynamic>> topRelatives;
  final Map<String, int> timePatterns;

  const DetailedStats({
    required this.userStats,
    required this.interactionCounts,
    required this.recentActivity,
    required this.monthlyData,
    required this.topRelatives,
    required this.timePatterns,
  });

  static const empty = DetailedStats(
    userStats: {},
    interactionCounts: {},
    recentActivity: [],
    monthlyData: [],
    topRelatives: [],
    timePatterns: {},
  );
}

/// Provider for loading detailed statistics for the Weekly Report.
final detailedStatsProvider =
    FutureProvider.autoDispose<DetailedStats>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return DetailedStats.empty;

  final userResponse = await SupabaseConfig.client
      .from('users')
      .select('current_streak, longest_streak, total_interactions')
      .eq('id', user.id)
      .single();

  final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
  final interactionsResponse = await SupabaseConfig.client
      .from('interactions')
      .select('type, relative_id, date')
      .eq('user_id', user.id)
      .gte('date', sixMonthsAgo.toIso8601String());

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

  final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
  final recentResponse = await SupabaseConfig.client
      .from('interactions')
      .select('date, type')
      .eq('user_id', user.id)
      .gte('date', sevenDaysAgo.toIso8601String())
      .order('date', ascending: true);

  final monthlyResponse = await SupabaseConfig.client
      .from('interactions')
      .select('date')
      .eq('user_id', user.id)
      .gte('date', sixMonthsAgo.toIso8601String())
      .order('date', ascending: true);

  final Map<String, int> monthlyCounts = {};
  for (final row in (monthlyResponse as List)) {
    final date = DateTime.parse(row['date'] as String);
    final monthKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}';
    monthlyCounts[monthKey] = (monthlyCounts[monthKey] ?? 0) + 1;
  }

  final topRelativesData = <Map<String, dynamic>>[];
  if (relativeCounts.isNotEmpty) {
    final sortedRelatives = relativeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topRelativeIds =
        sortedRelatives.take(5).map((e) => e.key).toList();

    if (topRelativeIds.isNotEmpty) {
      // Phase 9.X.D.A.fix Bug 1: exclude self-node from top-relatives weekly
      // report. Self-node has 0 interactions today so unlikely to surface,
      // but defense-in-depth in case future code logs interactions to self.
      final relativesResponse = await SupabaseConfig.client
          .from('relatives')
          .select('id, full_name')
          .eq('user_id', user.id)
          .eq('is_self', false)
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
  );
});
