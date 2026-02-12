import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/models/interaction_model.dart';
import '../../../shared/models/reminder_schedule_model.dart';
import '../../../shared/services/hadith_service.dart';
import '../../../core/providers/cache_provider.dart';
import '../../../core/config/supabase_config.dart';
import '../../family_tree/providers/family_graph_providers.dart';

/// Provider for HadithService
final hadithServiceProvider = Provider((ref) {
  return HadithService();
});

/// Cache duration for stream providers - keeps data alive for 5 minutes
/// after the last listener is removed to avoid excessive re-fetches
const _cacheTimeout = Duration(minutes: 5);

/// Stream provider for relatives list (cache-first via repository)
/// Uses autoDispose with timed cache to prevent memory leaks
final relativesStreamProvider =
    StreamProvider.autoDispose.family<List<Relative>, String>((
  ref,
  userId,
) {
  // Keep alive for 5 minutes after last listener removed
  final link = ref.keepAlive();
  Timer? timer;

  ref.onDispose(() {
    timer?.cancel();
  });

  ref.onCancel(() {
    // Start countdown when no listeners
    timer = Timer(_cacheTimeout, () {
      link.close();
    });
  });

  ref.onResume(() {
    // Cancel countdown if listener re-attaches
    timer?.cancel();
  });

  final repository = ref.watch(relativesRepositoryProvider);
  return repository.watchRelatives(userId);
});

/// Provider that returns relatives appropriate for the current user context.
///
/// - **Group mode**: shared group relatives filtered by rahim scope
///   (only blood-connected relatives visible) with viewer's self-node excluded.
/// - **Personal mode**: all personal relatives (no rahim filtering needed).
///
/// This is the **single gateway** for relatives display across the app.
/// Every screen / widget that shows a list of relatives should consume this
/// provider rather than watching [groupRelativesStreamProvider] directly.
final viewerFilteredRelativesProvider =
    Provider.autoDispose<AsyncValue<List<Relative>>>((ref) {
  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) return const AsyncValue.data([]);

  final groupInfo = ref.watch(userFamilyGroupProvider).valueOrNull;

  final rawAsync = groupInfo != null
      ? ref.watch(groupRelativesStreamProvider(groupInfo.groupId))
      : ref.watch(relativesStreamProvider(user.id));

  final viewerNodeId = groupInfo?.nodeId;
  final rahimScope = ref.watch(rahimVisibleRelativeIdsProvider);

  return rawAsync.whenData((relatives) {
    var visible = relatives;
    // In group mode, apply rahim scope when available
    if (rahimScope != null) {
      visible = visible.where((r) => rahimScope.contains(r.id)).toList();
    }
    // Exclude viewer's own self-node
    if (viewerNodeId != null) {
      visible = visible.where((r) => r.id != viewerNodeId).toList();
    }
    return visible;
  });
});

/// Stream provider for today's interactions (cache-first via repository)
/// Uses autoDispose with timed cache to prevent memory leaks
final todayInteractionsStreamProvider =
    StreamProvider.autoDispose.family<List<Interaction>, String>((ref, userId) {
  // Keep alive for 5 minutes after last listener removed
  final link = ref.keepAlive();
  Timer? timer;

  ref.onDispose(() {
    timer?.cancel();
  });

  ref.onCancel(() {
    timer = Timer(_cacheTimeout, () {
      link.close();
    });
  });

  ref.onResume(() {
    timer?.cancel();
  });

  final repository = ref.watch(interactionsRepositoryProvider);
  return repository.watchTodayInteractions(userId);
});

/// Stream provider for recent interactions (last 30 days) for insight generation.
/// Uses autoDispose with timed cache to prevent memory leaks.
final recentInteractionsStreamProvider =
    StreamProvider.autoDispose.family<List<Interaction>, String>((ref, userId) {
  // Keep alive for 5 minutes after last listener removed
  final link = ref.keepAlive();
  Timer? timer;

  ref.onDispose(() {
    timer?.cancel();
  });

  ref.onCancel(() {
    timer = Timer(_cacheTimeout, () {
      link.close();
    });
  });

  ref.onResume(() {
    timer?.cancel();
  });

  final repository = ref.watch(interactionsRepositoryProvider);
  final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
  return repository.watchUserInteractions(userId).map(
        (interactions) => interactions
            .where((i) => i.date.isAfter(thirtyDaysAgo))
            .toList(),
      );
});

/// Stream provider for reminder schedules (cache-first via repository)
/// Uses autoDispose with timed cache to prevent memory leaks
final reminderSchedulesStreamProvider =
    StreamProvider.autoDispose.family<List<ReminderSchedule>, String>((
  ref,
  userId,
) {
  // Keep alive for 5 minutes after last listener removed
  final link = ref.keepAlive();
  Timer? timer;

  ref.onDispose(() {
    timer?.cancel();
  });

  ref.onCancel(() {
    timer = Timer(_cacheTimeout, () {
      link.close();
    });
  });

  ref.onResume(() {
    timer?.cancel();
  });

  final repository = ref.watch(reminderSchedulesRepositoryProvider);
  return repository.watchSchedules(userId);
});

/// Stream provider for group-wide today's interactions.
///
/// Shows interactions logged by ANY group member for relatives in the family group.
/// Enables "family awareness" - see that your brother called Dad yesterday.
/// Requires the shared_interactions_rls migration to be applied.
final groupTodayInteractionsStreamProvider =
    StreamProvider.autoDispose.family<List<Interaction>, String>((ref, groupId) {
  final link = ref.keepAlive();
  Timer? timer;

  ref.onDispose(() => timer?.cancel());
  ref.onCancel(() {
    timer = Timer(_cacheTimeout, () => link.close());
  });
  ref.onResume(() => timer?.cancel());

  // Use rahim-scoped IDs when available, fall back to full group
  final rahimScope = ref.watch(rahimVisibleRelativeIdsProvider);
  final groupRelativeIds = rahimScope ?? (ref
      .watch(groupRelativesStreamProvider(groupId))
      .valueOrNull
      ?.map((r) => r.id)
      .toSet() ?? <String>{});

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);

  // Stream interactions visible via RLS, then filter to visible relatives
  return SupabaseConfig.client
      .from('interactions')
      .stream(primaryKey: ['id'])
      .gte('date', startOfDay.toUtc().toIso8601String())
      .order('date', ascending: false)
      .map((data) => data
          .map((json) => Interaction.fromJson(json))
          .where((i) => groupRelativeIds.contains(i.relativeId))
          .toList());
});

/// Stream provider for group-wide contacted relatives today.
///
/// Returns the set of relative IDs that have been contacted today by ANY group member.
final groupTodayContactedRelativesProvider =
    StreamProvider.autoDispose.family<Set<String>, String>((ref, groupId) {
  final link = ref.keepAlive();
  Timer? timer;

  ref.onDispose(() => timer?.cancel());
  ref.onCancel(() {
    timer = Timer(_cacheTimeout, () => link.close());
  });
  ref.onResume(() => timer?.cancel());

  // Use rahim-scoped IDs when available, fall back to full group
  final rahimScope = ref.watch(rahimVisibleRelativeIdsProvider);
  final groupRelativeIds = rahimScope ?? (ref
      .watch(groupRelativesStreamProvider(groupId))
      .valueOrNull
      ?.map((r) => r.id)
      .toSet() ?? <String>{});

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);

  return SupabaseConfig.client
      .from('interactions')
      .stream(primaryKey: ['id'])
      .gte('date', startOfDay.toUtc().toIso8601String())
      .map((data) {
        return data
            .map((i) => i['relative_id'] as String?)
            .where((id) => id != null && id.isNotEmpty && groupRelativeIds.contains(id))
            .cast<String>()
            .toSet();
      });
});

/// Provider for family group leaderboard stats.
///
/// Fetches gamification stats (points, level, streak) for all members of a family group.
/// Used for the family leaderboard feature.
final familyLeaderboardProvider =
    FutureProvider.autoDispose.family<List<FamilyMemberStats>, String>((ref, groupId) async {
  final link = ref.keepAlive();
  Timer? timer;

  ref.onDispose(() => timer?.cancel());
  ref.onCancel(() {
    timer = Timer(_cacheTimeout, () => link.close());
  });
  ref.onResume(() => timer?.cancel());

  // Get all members of the group
  final membersResponse = await SupabaseConfig.client
      .from('family_group_members')
      .select('user_id')
      .eq('group_id', groupId);

  final memberUserIds = (membersResponse as List)
      .map((m) => m['user_id'] as String)
      .toList();

  if (memberUserIds.isEmpty) return [];

  // Get user stats for all members
  final statsResponse = await SupabaseConfig.client
      .from('users')
      .select('id, full_name, email, points, level, current_streak, total_interactions')
      .inFilter('id', memberUserIds);

  final stats = (statsResponse as List).map((json) {
    return FamilyMemberStats(
      userId: json['id'] as String,
      displayName: json['full_name'] as String? ?? json['email'] as String? ?? 'عضو',
      points: json['points'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      currentStreak: json['current_streak'] as int? ?? 0,
      totalInteractions: json['total_interactions'] as int? ?? 0,
    );
  }).toList();

  // Sort by points descending
  stats.sort((a, b) => b.points.compareTo(a.points));

  return stats;
});

/// Model for family member stats in leaderboard.
class FamilyMemberStats {
  final String userId;
  final String displayName;
  final int points;
  final int level;
  final int currentStreak;
  final int totalInteractions;

  const FamilyMemberStats({
    required this.userId,
    required this.displayName,
    required this.points,
    required this.level,
    required this.currentStreak,
    required this.totalInteractions,
  });
}

/// Provider for today's due relatives based on reminder schedules
/// Returns relatives with ALL their applicable frequencies (e.g., daily + friday)
final todayDueRelativesProvider = Provider.family<List<DueRelativeWithFrequencies>, ({
  List<ReminderSchedule> schedules,
  List<Relative> relatives,
})>((ref, data) {
  final schedules = data.schedules;
  final relatives = data.relatives;

  // Map: relativeId -> Set<ReminderFrequency>
  final relativeFrequencies = <String, Set<ReminderFrequency>>{};

  for (final schedule in schedules) {
    if (schedule.isActive && schedule.shouldFireToday()) {
      for (final relativeId in schedule.relativeIds) {
        relativeFrequencies.putIfAbsent(relativeId, () => <ReminderFrequency>{});
        relativeFrequencies[relativeId]!.add(schedule.frequency);
      }
    }
  }

  return relatives
      .where((r) => relativeFrequencies.containsKey(r.id))
      .map((r) => DueRelativeWithFrequencies(
            relative: r,
            frequencies: relativeFrequencies[r.id]!,
          ))
      .toList();
});

/// Stream provider for user gamification data (streak, badges)
/// Used by StreakBadgeBar for live updates
/// Uses autoDispose with timed cache to prevent memory leaks
final userGamificationDataProvider =
    StreamProvider.autoDispose.family<Map<String, dynamic>, String>((
  ref,
  userId,
) {
  // Keep alive for 5 minutes after last listener removed
  final link = ref.keepAlive();
  Timer? timer;

  ref.onDispose(() {
    timer?.cancel();
  });

  ref.onCancel(() {
    timer = Timer(_cacheTimeout, () {
      link.close();
    });
  });

  ref.onResume(() {
    timer?.cancel();
  });

  return SupabaseConfig.client
      .from('users')
      .stream(primaryKey: ['id'])
      .eq('id', userId)
      .map((data) => data.isNotEmpty ? data.first : <String, dynamic>{});
});
