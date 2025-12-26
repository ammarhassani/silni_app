import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/streak_freeze_model.dart';
import '../services/streak_freeze_service.dart';
import 'gamification_events_provider.dart';

/// Provider for the StreakFreezeService
final streakFreezeServiceProvider = Provider<StreakFreezeService>((ref) {
  final eventsController = ref.watch(gamificationEventsControllerProvider);
  return StreakFreezeService(
    eventsController: eventsController,
  );
});

/// Provider for user's freeze inventory
final freezeInventoryProvider = FutureProvider.family<FreezeInventory, String>(
  (ref, userId) async {
    final service = ref.watch(streakFreezeServiceProvider);
    return service.getFreezeInventory(userId);
  },
);

/// Stream provider for real-time freeze inventory updates
final freezeInventoryStreamProvider = StreamProvider.family<FreezeInventory, String>(
  (ref, userId) {
    final service = ref.watch(streakFreezeServiceProvider);
    return service.watchFreezeInventory(userId);
  },
);

/// Provider for freeze usage history
final freezeHistoryProvider = FutureProvider.family<List<FreezeUsage>, String>(
  (ref, userId) async {
    final service = ref.watch(streakFreezeServiceProvider);
    return service.getFreezeHistory(userId);
  },
);

/// Provider for auto-freeze setting
final autoFreezeEnabledProvider = FutureProvider.family<bool, String>(
  (ref, userId) async {
    final service = ref.watch(streakFreezeServiceProvider);
    return service.isAutoFreezeEnabled(userId);
  },
);
