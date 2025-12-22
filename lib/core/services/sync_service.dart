import 'dart:async';

import '../../shared/models/relative_model.dart';
import '../../shared/models/interaction_model.dart';
import '../../shared/models/offline_operation.dart';
import '../../shared/services/relatives_service.dart';
import '../../shared/services/interactions_service.dart';
import '../../shared/services/reminder_schedules_service.dart';
import '../cache/cache_config.dart';
import 'cache_service.dart';
import 'offline_queue_service.dart';
import 'connectivity_service.dart';
import 'app_logger_service.dart';
import 'gamification_service.dart';
import '../providers/gamification_events_provider.dart';
import '../errors/app_errors.dart';

/// Status of the sync process.
enum SyncStatus {
  idle,
  syncing,
  error,
}

/// Service for synchronizing local cache with remote Supabase.
class SyncService {
  SyncService._() {
    // Initialize interactions service with gamification support
    _interactionsService = InteractionsService(
      gamificationService: _gamificationService,
    );
  }
  static final SyncService instance = SyncService._();

  final CacheService _cache = CacheService.instance;
  final OfflineQueueService _queue = OfflineQueueService.instance;
  final ConnectivityService _connectivity = connectivityService;
  final AppLoggerService _logger = AppLoggerService();

  // Services for remote operations
  final RelativesService _relativesService = RelativesService();
  late InteractionsService _interactionsService;
  final ReminderSchedulesService _schedulesService = ReminderSchedulesService();
  GamificationService _gamificationService = GamificationService();

  // Stream controllers
  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  SyncStatus _currentStatus = SyncStatus.idle;
  SyncStatus get currentStatus => _currentStatus;

  String? _lastError;
  String? get lastError => _lastError;

  Timer? _backgroundSyncTimer;
  bool _isSyncing = false;

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

    // Clear dead letter operations - they've failed too many times
    if (deadLetterCount > 0) {
      _logger.info(
        'Clearing $deadLetterCount dead letter operations',
        category: LogCategory.service,
        tag: 'Sync',
      );
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

  /// Set the gamification events controller for UI event emission.
  /// Call this after Riverpod is initialized to enable gamification UI feedback.
  void setEventsController(GamificationEventsController controller) {
    _gamificationService = GamificationService(eventsController: controller);
    _interactionsService = InteractionsService(
      gamificationService: _gamificationService,
    );
    _logger.info(
      'SyncService gamification events controller configured',
      category: LogCategory.service,
      tag: 'Sync',
    );
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

  /// Background sync check.
  Future<void> _backgroundSync() async {
    if (!_connectivity.isOnline) return;
    if (_isSyncing) return;

    // Only sync if cache is stale
    if (_cache.isCacheStale(CacheConfig.lastSyncRelativesKey)) {
      _logger.debug(
        'Background sync triggered (cache stale)',
        category: LogCategory.service,
        tag: 'Sync',
      );
      // We don't have userId here, so just process the queue
      await processOfflineQueue();
    }
  }

  /// Full sync for a user - pull from server and push pending changes.
  Future<void> fullSync(String userId) async {
    if (_isSyncing) {
      _logger.debug(
        'Sync already in progress, skipping',
        category: LogCategory.service,
        tag: 'Sync',
      );
      return;
    }

    if (!_connectivity.isOnline) {
      _logger.debug(
        'Offline, skipping sync',
        category: LogCategory.service,
        tag: 'Sync',
      );
      return;
    }

    _isSyncing = true;
    _setStatus(SyncStatus.syncing);

    try {
      _logger.info(
        'Starting full sync for user',
        category: LogCategory.service,
        tag: 'Sync',
        metadata: {'userId': userId},
      );

      // 1. Process offline queue first (push local changes)
      await processOfflineQueue();

      // 2. Pull latest data from server
      await syncRelatives(userId);
      await syncReminderSchedules(userId);
      // Note: Interactions are synced per-relative when needed

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
    }
  }

  /// Sync relatives from server to cache.
  Future<void> syncRelatives(String userId) async {
    try {
      _logger.debug(
        'Syncing relatives...',
        category: LogCategory.service,
        tag: 'Sync',
      );

      // Fetch all relatives from server
      final relatives = await _relativesService.getRelativesStream(userId).first;

      // Update cache
      await _cache.putRelatives(relatives);

      // Update sync metadata
      await _cache.updateLastSyncTime(
        CacheConfig.lastSyncRelativesKey,
        itemCount: relatives.length,
      );

      _logger.info(
        'Synced ${relatives.length} relatives',
        category: LogCategory.service,
        tag: 'Sync',
      );
    } catch (e) {
      _logger.error(
        'Failed to sync relatives: $e',
        category: LogCategory.service,
        tag: 'Sync',
      );
      rethrow;
    }
  }

  /// Sync interactions for a specific relative.
  Future<void> syncInteractionsForRelative(String relativeId) async {
    try {
      _logger.debug(
        'Syncing interactions for relative: $relativeId',
        category: LogCategory.service,
        tag: 'Sync',
      );

      // Fetch interactions from server
      final interactions = await _interactionsService
          .getRelativeInteractionsStream(relativeId)
          .first;

      // Take only the most recent ones based on limit
      final limitedInteractions = interactions
          .take(CacheConfig.maxInteractionsPerRelative)
          .toList();

      // Update cache
      await _cache.putInteractions(limitedInteractions);

      // Update sync metadata
      await _cache.updateLastSyncTime(
        CacheConfig.lastSyncInteractionsKey(relativeId),
        itemCount: limitedInteractions.length,
      );

      _logger.info(
        'Synced ${limitedInteractions.length} interactions for relative',
        category: LogCategory.service,
        tag: 'Sync',
        metadata: {'relativeId': relativeId},
      );
    } catch (e) {
      _logger.error(
        'Failed to sync interactions for $relativeId: $e',
        category: LogCategory.service,
        tag: 'Sync',
      );
      rethrow;
    }
  }

  /// Sync reminder schedules from server to cache.
  Future<void> syncReminderSchedules(String userId) async {
    try {
      _logger.debug(
        'Syncing reminder schedules...',
        category: LogCategory.service,
        tag: 'Sync',
      );

      // Fetch all schedules from server
      final schedules = await _schedulesService.getSchedulesStream(userId).first;

      // Update cache
      await _cache.putReminderSchedules(schedules);

      // Update sync metadata
      await _cache.updateLastSyncTime(
        CacheConfig.lastSyncRemindersKey,
        itemCount: schedules.length,
      );

      _logger.info(
        'Synced ${schedules.length} reminder schedules',
        category: LogCategory.service,
        tag: 'Sync',
      );
    } catch (e) {
      _logger.error(
        'Failed to sync reminder schedules: $e',
        category: LogCategory.service,
        tag: 'Sync',
      );
      rethrow;
    }
  }

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
    _statusController.add(status);
  }

  /// Dispose resources.
  void dispose() {
    _backgroundSyncTimer?.cancel();
    _statusController.close();
    _queue.dispose();
  }
}
