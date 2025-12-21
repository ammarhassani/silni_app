import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/cache_service.dart';
import '../services/offline_queue_service.dart';
import '../services/sync_service.dart';
import '../services/gamification_service.dart';
import '../../shared/repositories/relatives_repository.dart';
import '../../shared/repositories/interactions_repository.dart';
import '../../shared/repositories/reminder_schedules_repository.dart';
import '../../shared/services/interactions_service.dart';
import 'gamification_events_provider.dart';

/// Provider for the CacheService singleton.
final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService.instance;
});

/// Provider for the OfflineQueueService singleton.
final offlineQueueServiceProvider = Provider<OfflineQueueService>((ref) {
  return OfflineQueueService.instance;
});

/// Provider for the SyncService singleton.
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService.instance;
});

/// Provider for RelativesRepository.
final relativesRepositoryProvider = Provider<RelativesRepository>((ref) {
  return RelativesRepository();
});

/// Provider for InteractionsRepository with gamification support.
final interactionsRepositoryProvider = Provider<InteractionsRepository>((ref) {
  final eventsController = ref.watch(gamificationEventsControllerProvider);
  final gamificationService = GamificationService(
    eventsController: eventsController,
  );
  final interactionsService = InteractionsService(
    gamificationService: gamificationService,
  );
  return InteractionsRepository(service: interactionsService);
});

/// Provider for ReminderSchedulesRepository.
final reminderSchedulesRepositoryProvider =
    Provider<ReminderSchedulesRepository>((ref) {
  return ReminderSchedulesRepository();
});

/// Stream provider for pending offline operations count.
final pendingOperationsCountProvider = StreamProvider<int>((ref) {
  final queueService = ref.watch(offlineQueueServiceProvider);
  return queueService.pendingCountStream;
});

/// Stream provider for dead letter operations count.
final deadLetterCountProvider = StreamProvider<int>((ref) {
  final queueService = ref.watch(offlineQueueServiceProvider);
  return queueService.deadLetterCountStream;
});

/// Provider for current pending count (non-stream).
final currentPendingCountProvider = Provider<int>((ref) {
  final queueService = ref.watch(offlineQueueServiceProvider);
  return queueService.getPendingCount();
});

/// Provider for current dead letter count (non-stream).
final currentDeadLetterCountProvider = Provider<int>((ref) {
  final queueService = ref.watch(offlineQueueServiceProvider);
  return queueService.getDeadLetterCount();
});
