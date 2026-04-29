import 'dart:async';

import '../../shared/models/relative_model.dart';
import '../../shared/models/interaction_model.dart';
import '../../shared/models/offline_operation.dart';
import '../../shared/services/relatives_service.dart';
import '../../shared/services/interactions_service.dart';
import '../../shared/services/reminder_schedules_service.dart';
import '../cache/cache_config.dart';
import 'offline_queue_service.dart';
import 'connectivity_service.dart';
import 'app_logger_service.dart';
import '../errors/app_errors.dart';

/// Status of the sync process.
enum SyncStatus {
  idle,
  syncing,
  error,
}

/// Service for synchronizing local cache with remote Supabase.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final OfflineQueueService _queue = OfflineQueueService.instance;
  final ConnectivityService _connectivity = connectivityService;
  final AppLoggerService _logger = AppLoggerService();

  // Services for remote operations
  final RelativesService _relativesService = RelativesService();
  final InteractionsService _interactionsService = InteractionsService();
  final ReminderSchedulesService _schedulesService = ReminderSchedulesService();

  // Stream controllers
  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  SyncStatus _currentStatus = SyncStatus.idle;
  SyncStatus get currentStatus => _currentStatus;

  String? _lastError;
  String? get lastError => _lastError;

  Timer? _backgroundSyncTimer;
  bool _isSyncing = false;
  bool _isDisposed = false;
  Completer<void>? _syncCompleter;

  /// Initialize the sync service.
  Future<void> initialize() async {
    await _queue.initialize();

    // Log queue status
    final pendingCount = _queue.getPendingCount();
    final deadLetterCount = _queue.getDeadLetterCount();

    _logger.info(
      'Queue status: $pendingCount pending, $deadLetterCount dead letter',
      category: LogCategory.service,
      tag: 'Sync',
    );

    // Warn about dead letter operations - they've failed too many times
    // Don't auto-delete - user should be notified about failed syncs
    if (deadLetterCount > 0) {
      _logger.warning(
        'Found $deadLetterCount failed sync operations that could not be completed. '
        'Some changes may not have been saved to the server.',
        category: LogCategory.service,
        tag: 'Sync',
        metadata: {'deadLetterCount': deadLetterCount},
      );
      // Log the warning and clear them to prevent buildup. The user-facing
      // notification for failed syncs is tracked in V1_1_BACKLOG.md.
      await _queue.clearAllDeadLetters();
    }

    // Clear stale pending operations (older than 24 hours)
    await _clearStaleOperations();

    // Start background sync timer
    _startBackgroundSync();

    // Immediately try to process any remaining pending operations
    final remainingCount = _queue.getPendingCount();
    if (remainingCount > 0 && _connectivity.isOnline) {
      _logger.info(
        'Processing $remainingCount pending operations...',
        category: LogCategory.service,
        tag: 'Sync',
      );
      await processOfflineQueue();
    }

    _logger.info(
      'SyncService initialized',
      category: LogCategory.service,
      tag: 'Sync',
    );
  }

  /// Clear operations older than 24 hours (likely stale after app updates).
  Future<void> _clearStaleOperations() async {
    final pendingOps = _queue.getPendingOperations();
    final staleThreshold = DateTime.now().subtract(const Duration(hours: 24));
    int clearedCount = 0;

    for (final op in pendingOps) {
      if (op.createdAt.isBefore(staleThreshold)) {
        _logger.debug(
          'Clearing stale: ${op.type.name} ${op.entityType}/${op.entityId}',
          category: LogCategory.service,
          tag: 'Sync',
        );
        await _queue.dequeue(op.id);
        clearedCount++;
      }
    }

    if (clearedCount > 0) {
      _logger.info(
        'Cleared $clearedCount stale operations (older than 24h)',
        category: LogCategory.service,
        tag: 'Sync',
      );
    }
  }

  /// Start background sync timer.
  void _startBackgroundSync() {
    _backgroundSyncTimer?.cancel();
    _backgroundSyncTimer = Timer.periodic(
      CacheConfig.backgroundSyncInterval,
      (_) async {
        try {
          await _backgroundSync();
        } catch (e, stackTrace) {
          _logger.error(
            'Background sync error',
            category: LogCategory.service,
            tag: 'Sync',
            metadata: {'error': e.toString()},
            stackTrace: stackTrace,
          );
        }
      },
    );
  }

  /// Background sync — drains pending offline writes when online.
  /// Phase 9.X.D.B Tier 2: the read-cache staleness check was removed
  /// along with the read-cache itself. Just process the queue.
  Future<void> _backgroundSync() async {
    if (!_connectivity.isOnline) return;
    if (_isSyncing) return;
    await processOfflineQueue();
  }

  /// Full sync for a user - pull from server and push pending changes.
  Future<void> fullSync(String userId) async {
    // Use Completer to handle concurrent sync requests safely
    if (_syncCompleter != null) {
      _logger.debug(
        'Sync already in progress, waiting for completion',
        category: LogCategory.service,
        tag: 'Sync',
      );
      return _syncCompleter!.future;
    }

    if (!_connectivity.isOnline) {
      _logger.debug(
        'Offline, skipping sync',
        category: LogCategory.service,
        tag: 'Sync',
      );
      return;
    }

    _syncCompleter = Completer<void>();
    _isSyncing = true;
    _setStatus(SyncStatus.syncing);

    try {
      _logger.info(
        'Starting full sync for user',
        category: LogCategory.service,
        tag: 'Sync',
        metadata: {'userId': userId},
      );

      // Process offline queue (push pending local changes to the server).
      // Server-pull is no longer needed here — Supabase realtime streams
      // owned by each repository are the single source of truth post-Tier 2.
      await processOfflineQueue();

      _setStatus(SyncStatus.idle);
      _lastError = null;

      _logger.info(
        'Full sync completed successfully',
        category: LogCategory.service,
        tag: 'Sync',
      );
    } catch (e, st) {
      _setStatus(SyncStatus.error);
      _lastError = e.toString();

      _logger.error(
        'Full sync failed: $e',
        category: LogCategory.service,
        tag: 'Sync',
        stackTrace: st,
      );
    } finally {
      _isSyncing = false;
      _syncCompleter?.complete();
      _syncCompleter = null;
    }
  }

  // Phase 9.X.D.B Tier 2: syncRelatives / syncInteractionsForRelative /
  // syncReminderSchedules removed. Their job was to push server snapshots
  // into the read-cache boxes that no longer exist. The Supabase realtime
  // streams that the repositories subscribe to are now the single source
  // of truth — no separate "pull-and-cache" round trip needed.
  //
  // What the SyncService still does: replays the offline write queue when
  // connectivity returns. See processOfflineQueue() below.

  /// Process the offline queue, executing pending operations.
  Future<int> processOfflineQueue() async {
    if (!_connectivity.isOnline) return 0;

    return await _queue.processQueue(
      operationExecutor: _executeOperation,
    );
  }

  /// Execute a single offline operation.
  Future<void> _executeOperation(OfflineOperation operation) async {
    _logger.debug(
      'Executing operation: ${operation.type.name} ${operation.entityType}',
      category: LogCategory.service,
      tag: 'Sync',
      metadata: {'entityId': operation.entityId},
    );

    switch (operation.entityType) {
      case 'relative':
        await _executeRelativeOperation(operation);
        break;
      case 'interaction':
        await _executeInteractionOperation(operation);
        break;
      case 'schedule':
        await _executeScheduleOperation(operation);
        break;
      default:
        throw ValidationError(
          message: 'Unknown entity type: ${operation.entityType}',
          arabicMessage: 'نوع العملية غير معروف',
          field: 'entityType',
        );
    }
  }

  /// Execute a relative operation.
  Future<void> _executeRelativeOperation(OfflineOperation operation) async {
    switch (operation.type) {
      case OperationType.create:
        final relative = Relative.fromJson(operation.data);
        await _relativesService.createRelative(relative);
        break;
      case OperationType.update:
        await _relativesService.updateRelative(
          operation.entityId,
          operation.data,
        );
        break;
      case OperationType.delete:
        await _relativesService.deleteRelative(operation.entityId);
        break;
    }
  }

  /// Execute an interaction operation.
  Future<void> _executeInteractionOperation(OfflineOperation operation) async {
    switch (operation.type) {
      case OperationType.create:
        _logger.debug(
          'Creating interaction from queued data',
          category: LogCategory.service,
          tag: 'Sync',
          metadata: {'data': operation.data.toString()},
        );
        final interaction = Interaction.fromJson(operation.data);
        await _interactionsService.createInteraction(interaction);
        break;
      case OperationType.update:
        await _interactionsService.updateInteraction(
          operation.entityId,
          operation.data,
        );
        break;
      case OperationType.delete:
        await _interactionsService.deleteInteraction(operation.entityId);
        break;
    }
  }

  /// Execute a schedule operation.
  Future<void> _executeScheduleOperation(OfflineOperation operation) async {
    switch (operation.type) {
      case OperationType.create:
        await _schedulesService.createSchedule(operation.data);
        break;
      case OperationType.update:
        await _schedulesService.updateSchedule(
          operation.entityId,
          operation.data,
        );
        break;
      case OperationType.delete:
        await _schedulesService.deleteSchedule(operation.entityId);
        break;
    }
  }

  /// Set and broadcast sync status.
  void _setStatus(SyncStatus status) {
    _currentStatus = status;
    // Guard against adding to closed controller
    if (!_isDisposed) {
      _statusController.add(status);
    }
  }

  /// Dispose resources.
  void dispose() {
    _isDisposed = true;
    _backgroundSyncTimer?.cancel();
    _statusController.close();
    _queue.dispose();
  }
}
