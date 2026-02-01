import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/leaderboard_service.dart';

/// Cache duration for leaderboard data (matches other group providers).
const _cacheTimeout = Duration(minutes: 5);

/// Provider for the weekly leaderboard of a family group.
///
/// Accepts a groupId and returns a ranked list of [LeaderboardEntry].
/// Uses autoDispose with a 5-minute timed cache to balance freshness
/// and performance, matching the pattern used by other group providers.
final weeklyLeaderboardProvider =
    FutureProvider.autoDispose.family<List<LeaderboardEntry>, String>(
  (ref, groupId) {
    final link = ref.keepAlive();
    Timer? timer;

    ref.onDispose(() => timer?.cancel());
    ref.onCancel(() {
      timer = Timer(_cacheTimeout, () => link.close());
    });
    ref.onResume(() => timer?.cancel());

    return LeaderboardService.getWeeklyLeaderboard(groupId);
  },
);
