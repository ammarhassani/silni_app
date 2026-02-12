import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'family_group_providers.dart';
import '../services/leaderboard_service.dart';

/// Cache duration for leaderboard data (matches other group providers).
const _cacheTimeout = Duration(minutes: 5);

/// Provider for the weekly leaderboard of a family group.
///
/// Accepts a groupId and returns a ranked list of [LeaderboardEntry].
/// Uses autoDispose with a 5-minute timed cache to balance freshness
/// and performance, matching the pattern used by other group providers.
///
/// Resolves display names from the group members stream so the leaderboard
/// shows member names instead of raw UUIDs.
final weeklyLeaderboardProvider =
    FutureProvider.autoDispose.family<List<LeaderboardEntry>, String>(
  (ref, groupId) async {
    final link = ref.keepAlive();
    Timer? timer;

    ref.onDispose(() => timer?.cancel());
    ref.onCancel(() {
      timer = Timer(_cacheTimeout, () => link.close());
    });
    ref.onResume(() => timer?.cancel());

    final entries = await LeaderboardService.getWeeklyLeaderboard(groupId);

    // Resolve display names from group members (which already enriches names)
    final members = ref.read(groupMembersProvider(groupId)).valueOrNull;
    if (members == null || members.isEmpty) return entries;

    final nameByUserId = <String, String>{
      for (final m in members)
        if (m.displayName != null) m.userId: m.displayName!,
    };

    return entries.map((e) {
      final name = nameByUserId[e.userId];
      return name != null ? e.copyWith(displayName: name) : e;
    }).toList();
  },
);
