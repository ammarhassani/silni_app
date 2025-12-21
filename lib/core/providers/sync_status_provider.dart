import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/sync_service.dart';
import 'cache_provider.dart';
import 'connectivity_provider.dart';

/// Combined data status for UI display.
class DataStatus {
  final bool isOnline;
  final SyncStatus syncStatus;
  final int pendingOperations;
  final int deadLetterOperations;
  final bool hasUnsyncedChanges;

  const DataStatus({
    required this.isOnline,
    required this.syncStatus,
    required this.pendingOperations,
    required this.deadLetterOperations,
  }) : hasUnsyncedChanges = pendingOperations > 0 || deadLetterOperations > 0;

  /// Whether to show the sync indicator.
  bool get shouldShowIndicator => !isOnline || hasUnsyncedChanges;

  /// Get status text for display.
  String get statusText {
    if (!isOnline) return 'غير متصل';
    if (syncStatus == SyncStatus.syncing) return 'جاري المزامنة...';
    if (deadLetterOperations > 0) return 'فشل مزامنة $deadLetterOperations';
    if (pendingOperations > 0) return '$pendingOperations في الانتظار';
    return 'تمت المزامنة';
  }

  /// Get Arabic status text.
  String get arabicStatusText => statusText;
}

/// Stream provider for sync status.
final syncStatusStreamProvider = StreamProvider<SyncStatus>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.statusStream;
});

/// Provider for current sync status.
final currentSyncStatusProvider = Provider<SyncStatus>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.currentStatus;
});

/// Provider for combined data status.
final dataStatusProvider = Provider<DataStatus>((ref) {
  final isOnline = ref.watch(isOnlineProvider);
  final syncStatus = ref.watch(currentSyncStatusProvider);
  final pendingCount = ref.watch(currentPendingCountProvider);
  final deadLetterCount = ref.watch(currentDeadLetterCountProvider);

  return DataStatus(
    isOnline: isOnline,
    syncStatus: syncStatus,
    pendingOperations: pendingCount,
    deadLetterOperations: deadLetterCount,
  );
});

/// Notifier for triggering sync operations.
class SyncNotifier extends StateNotifier<AsyncValue<void>> {
  final SyncService _syncService;

  SyncNotifier(this._syncService) : super(const AsyncValue.data(null));

  /// Trigger a full sync for a user.
  Future<void> sync(String userId) async {
    state = const AsyncValue.loading();
    try {
      await _syncService.fullSync(userId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Process the offline queue.
  Future<int> processQueue() async {
    return await _syncService.processOfflineQueue();
  }
}

/// Provider for the sync notifier.
final syncNotifierProvider =
    StateNotifierProvider<SyncNotifier, AsyncValue<void>>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return SyncNotifier(syncService);
});
