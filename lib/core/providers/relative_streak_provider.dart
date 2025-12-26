import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/relative_streak_model.dart';
import '../services/relative_streak_service.dart';
import 'gamification_events_provider.dart';

/// Provider for the RelativeStreakService
final relativeStreakServiceProvider = Provider<RelativeStreakService>((ref) {
  final eventsController = ref.watch(gamificationEventsControllerProvider);
  return RelativeStreakService(
    eventsController: eventsController,
  );
});

/// Provider for a specific relative's streak
/// Usage: ref.watch(relativeStreakProvider((userId: 'xxx', relativeId: 'yyy')))
final relativeStreakProvider = FutureProvider.family<RelativeStreak?, ({String userId, String relativeId})>(
  (ref, params) async {
    final service = ref.watch(relativeStreakServiceProvider);
    return service.getRelativeStreak(
      userId: params.userId,
      relativeId: params.relativeId,
    );
  },
);

/// Stream provider for real-time updates to a relative's streak
final relativeStreakStreamProvider = StreamProvider.family<RelativeStreak?, ({String userId, String relativeId})>(
  (ref, params) {
    final service = ref.watch(relativeStreakServiceProvider);
    return service.watchRelativeStreak(
      userId: params.userId,
      relativeId: params.relativeId,
    );
  },
);

/// Provider for all relative streaks for a user
final allRelativeStreaksProvider = FutureProvider.family<List<RelativeStreak>, String>(
  (ref, userId) async {
    final service = ref.watch(relativeStreakServiceProvider);
    return service.getAllRelativeStreaks(userId);
  },
);

/// Stream provider for all relative streaks (real-time)
final allRelativeStreaksStreamProvider = StreamProvider.family<List<RelativeStreak>, String>(
  (ref, userId) {
    final service = ref.watch(relativeStreakServiceProvider);
    return service.watchAllRelativeStreaks(userId);
  },
);

/// Provider for endangered streaks (within 4 hours of deadline)
final endangeredStreaksProvider = FutureProvider.family<List<RelativeStreak>, String>(
  (ref, userId) async {
    final service = ref.watch(relativeStreakServiceProvider);
    return service.getEndangeredStreaks(userId);
  },
);

/// Get the warning state for a deadline
StreakWarningState getWarningState(DateTime? deadline) {
  if (deadline == null) return StreakWarningState.safe;
  final remaining = deadline.difference(DateTime.now().toUtc());
  if (remaining.isNegative) return StreakWarningState.expired;
  if (remaining.inMinutes <= 60) return StreakWarningState.critical;
  if (remaining.inHours <= 4) return StreakWarningState.warning;
  return StreakWarningState.safe;
}
