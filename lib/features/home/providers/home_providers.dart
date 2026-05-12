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

/// Address-book style: every relative the CURRENT USER owns — their
/// personal additions PLUS any personal-scope shadows projecting
/// relationships across groups. Filtered to `user_id = me` so a wife
/// who's a member of her husband's family group doesn't see her
/// admin-husband's extended kin in HER contact list — those are HIS
/// relatives, not hers.
///
/// Shadows (created by `approve_node_claim`) are owned by the claimant,
/// so they survive this filter. testprodjoiner sees her personal
/// shadow of testprod (full_name='testprod', relationship_type='husband')
/// — she gets her husband in her address book without inheriting his
/// entire family.
///
/// Used by the relatives list page and the home "عائلتك" carousel.
final addressBookRelativesProvider =
    StreamProvider.autoDispose<List<Relative>>((ref) {
  final link = ref.keepAlive();
  Timer? timer;
  ref.onDispose(() => timer?.cancel());
  ref.onCancel(() {
    timer = Timer(_cacheTimeout, () => link.close());
  });
  ref.onResume(() => timer?.cancel());

  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) {
    return Stream.value(const <Relative>[]);
  }

  // Filter to relatives the current user OWNS. Admin-owned rows in shared
  // groups are RLS-visible to members but not theirs to claim — they're
  // the admin's lineage. The user's view of those people comes through
  // their personal shadows (which they own) instead.
  return SupabaseConfig.client
      .from('relatives')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .map((rows) => rows
          .map((json) => Relative.fromJson(json))
          .where((r) => !r.isSelf && !r.isArchived)
          .toList());
});

/// Provider that returns relatives appropriate for the current user context.
///
/// - **Group mode**: shared group relatives filtered by rahim scope
///   (only blood-connected relatives visible) with viewer's self-node excluded.
/// - **Personal mode**: all personal relatives (no rahim filtering needed).
///
/// Used by the **family tree screen** (scope-aware).
/// For the relatives list page, use [addressBookRelativesProvider] instead.
final viewerFilteredRelativesProvider =
    Provider.autoDispose<AsyncValue<List<Relative>>>((ref) {
  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) return const AsyncValue.data([]);

  final groupInfo = ref.watch(activeFamilyGroupProvider).valueOrNull;

  // In group mode, merge the shared group relatives with the viewer's
  // OWN personal relatives (family_group_id IS NULL). Non-admin members
  // add into personal scope (Task A1/A2), so without this merge their
  // own additions are invisible from the group view. Other members never
  // see the viewer's personal rows — RLS filters by user_id.
  final rawAsync = groupInfo != null
      ? ref.watch(groupTreeRelativesProvider(groupInfo.groupId))
      : ref.watch(relativesStreamProvider(user.id));

  final viewerNodeId = groupInfo?.nodeId;
  final rahimScope = ref.watch(rahimVisibleRelativeIdsProvider);

  return rawAsync.whenData((relatives) {
    var visible = relatives;
    // In group mode, apply rahim scope when available
    if (rahimScope != null) {
      visible = visible.where((r) => rahimScope.contains(r.id)).toList();
    }
    // Always exclude the viewer's self-node — it's an internal anchor for the
    // family tree, not a "relative" the user wants to see in carousels, lists,
    // or AI counts. Phase 9.X.D.A4 began inserting self-nodes for solo users
    // (previously only group-joiners had one), which surfaced this leak.
    //
    // is_self is the canonical marker. The legacy viewerNodeId check remains
    // as defense-in-depth for stale data where is_self might be unset on a
    // claimed group node (handled by 20260206110000_fix_claimed_nodes_is_self
    // but worth keeping the belt + suspenders).
    visible = visible.where((r) => !r.isSelf).toList();
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

/// Base stream for group-wide today's interactions.
///
/// Single Supabase real-time subscription for all today's interactions visible
/// via RLS in this group. Both interaction list and contacted-set providers
/// derive from this, avoiding duplicate WebSocket channels.
final _groupTodayInteractionsBaseProvider =
    StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, groupId) {
  final link = ref.keepAlive();
  Timer? timer;

  ref.onDispose(() => timer?.cancel());
  ref.onCancel(() {
    timer = Timer(_cacheTimeout, () => link.close());
  });
  ref.onResume(() => timer?.cancel());

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);

  return SupabaseConfig.client
      .from('interactions')
      .stream(primaryKey: ['id'])
      .gte('date', startOfDay.toUtc().toIso8601String())
      .order('date', ascending: false);
});

/// Group today's interactions as typed models, filtered to rahim-visible relatives.
///
/// Derives from [_groupTodayInteractionsBaseProvider] to share a single
/// WebSocket subscription with [groupTodayContactedRelativesProvider].
final groupTodayInteractionsStreamProvider =
    Provider.autoDispose.family<AsyncValue<List<Interaction>>, String>((ref, groupId) {
  final rahimScope = ref.watch(rahimVisibleRelativeIdsProvider);
  final groupRelativeIds = rahimScope ?? (ref
      .watch(groupRelativesStreamProvider(groupId))
      .valueOrNull
      ?.map((r) => r.id)
      .toSet() ?? <String>{});

  return ref.watch(_groupTodayInteractionsBaseProvider(groupId)).whenData((data) {
    return data
        .map((json) => Interaction.fromJson(json))
        .where((i) => groupRelativeIds.contains(i.relativeId))
        .toList();
  });
});

/// Group today's contacted relative IDs, derived from the same base stream.
///
/// Returns the set of relative IDs that have been contacted today by ANY
/// group member. Shares the same WebSocket subscription as
/// [groupTodayInteractionsStreamProvider] via [_groupTodayInteractionsBaseProvider].
final groupTodayContactedRelativesProvider =
    Provider.autoDispose.family<AsyncValue<Set<String>>, String>((ref, groupId) {
  final rahimScope = ref.watch(rahimVisibleRelativeIdsProvider);
  final groupRelativeIds = rahimScope ?? (ref
      .watch(groupRelativesStreamProvider(groupId))
      .valueOrNull
      ?.map((r) => r.id)
      .toSet() ?? <String>{});

  return ref.watch(_groupTodayInteractionsBaseProvider(groupId)).whenData((data) {
    return data
        .map((i) => i['relative_id'] as String?)
        .where((id) => id != null && id.isNotEmpty && groupRelativeIds.contains(id))
        .cast<String>()
        .toSet();
  });
});

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
/// Used by StreakBadgeBar for live updates.
///
/// Non-autoDispose by design: the bar is mounted on every home page render
/// and disposing the underlying realtime stream on navigate-away led to
/// race conditions with the competing `subscribeToUserProfile` channel
/// (both watch the `users` table for the same userId). Re-attaching to a
/// torn-down stream surfaced as an error → the bar collapsed to nothing.
/// Memory cost is negligible (one row, one user) and the stream is
/// invalidated explicitly on logout via clearUserSession.
final userGamificationDataProvider =
    StreamProvider.family<Map<String, dynamic>, String>((ref, userId) {
  return SupabaseConfig.client
      .from('users')
      .stream(primaryKey: ['id'])
      .eq('id', userId)
      .map((data) => data.isNotEmpty ? data.first : <String, dynamic>{});
});
