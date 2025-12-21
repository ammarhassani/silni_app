import 'dart:async';

import '../../shared/models/offline_operation.dart';
import '../cache/hive_initializer.dart';
import '../cache/cache_config.dart';
import 'connectivity_service.dart';
import 'app_logger_service.dart';

/// Service for managing offline operation queue.
/// Operations are queued when offline and processed when back online.
class OfflineQueueService {
  OfflineQueueService._();
  static final OfflineQueueService instance = OfflineQueueService._();

  final ConnectivityService _connectivity = connectivityService;
  final AppLoggerService _logger = AppLoggerService();

  // Stream controller for pending count updates
  final _pendingCountController = StreamController<int>.broadcast();
  Stream<int> get pendingCountStream => _pendingCountController.stream;

  // Stream controller for dead letter count updates
  final _deadLetterCountController = StreamController<int>.broadcast();
  Stream<int> get deadLetterCountStream => _deadLetterCountController.stream;

  bool _isProcessing = false;
  int _nextId = 0;

  /// Initialize the service and get next available ID.
  Future<void> initialize() async {
    final box = HiveInitializer.offlineQueueBox;
    if (box.isNotEmpty) {
      _nextId = box.keys.cast<int>().reduce((a, b) => a > b ? a : b) + 1;
    }
    _emitCounts();
    _logger.info(
      'Initialized offline queue',
      category: LogCategory.service,
      tag: 'OfflineQueueService',
      metadata: {'nextId': _nextId},
    );
  }

  /// Enqueue an operation for later sync.
  Future<int> enqueue(OfflineOperation operation) async {
    final id = _nextId++;
    final op = operation.copyWith(id: id);

    await HiveInitializer.offlineQueueBox.put(id, op);
    _emitCounts();

    _logger.info(
      'Enqueued operation',
      category: LogCategory.service,
      tag: 'OfflineQueueService',
      metadata: {'type': op.type.name, 'entityType': op.entityType, 'entityId': op.entityId},
    );

    // Try to process immediately if online
    if (_connectivity.isOnline && !_isProcessing) {
      unawaited(processQueue().catchError((e) {
        _logger.error(
          'Queue processing error: $e',
          category: LogCategory.service,
          tag: 'OfflineQueueService',
        );
        return 0;
      }));
    }

    return id;
  }

  /// Get the next operation without removing it.
  OfflineOperation? peek() {
    final box = HiveInitializer.offlineQueueBox;
    final pendingOps = box.values.where((op) => !op.isDeadLetter).toList();
    if (pendingOps.isEmpty) return null;

    // Sort by ID (FIFO order)
    pendingOps.sort((a, b) => a.id.compareTo(b.id));
    return pendingOps.first;
  }

  /// Remove an operation from the queue.
  Future<void> dequeue(int operationId) async {
    await HiveInitializer.offlineQueueBox.delete(operationId);
    _emitCounts();
    _logger.debug(
      'Dequeued operation',
      category: LogCategory.service,
      tag: 'OfflineQueueService',
      metadata: {'operationId': operationId},
    );
  }

  /// Get all pending operations (non-dead-letter).
  List<OfflineOperation> getPendingOperations() {
    return HiveInitializer.offlineQueueBox.values
        .where((op) => !op.isDeadLetter)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  /// Get all dead letter operations.
  List<OfflineOperation> getDeadLetterOperations() {
    return HiveInitializer.offlineQueueBox.values
        .where((op) => op.isDeadLetter)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  /// Get count of pending operations.
  int getPendingCount() {
    return HiveInitializer.offlineQueueBox.values
        .where((op) => !op.isDeadLetter)
        .length;
  }

  /// Get count of dead letter operations.
  int getDeadLetterCount() {
    return HiveInitializer.offlineQueueBox.values
        .where((op) => op.isDeadLetter)
        .length;
  }

  /// Process the queue, executing operations in FIFO order.
  /// Returns the number of successfully processed operations.
  Future<int> processQueue({
    Future<void> Function(OfflineOperation)? operationExecutor,
  }) async {
    if (_isProcessing) {
      _logger.debug('Already processing, skipping', category: LogCategory.service, tag: 'OfflineQueueService');
      return 0;
    }

    if (!_connectivity.isOnline) {
      _logger.debug('Offline, skipping queue processing', category: LogCategory.service, tag: 'OfflineQueueService');
      return 0;
    }

    _isProcessing = true;
    int processed = 0;

    try {
      _logger.info('Starting queue processing', category: LogCategory.service, tag: 'OfflineQueueService');

      while (_connectivity.isOnline) {
        final operation = peek();
        if (operation == null) {
          _logger.debug('Queue empty, done processing', category: LogCategory.service, tag: 'OfflineQueueService');
          break;
        }

        try {
          // Execute the operation
          if (operationExecutor != null) {
            await operationExecutor(operation);
          } else {
            // Default executor just logs (real implementation in SyncService)
            _logger.debug(
              'Would execute operation',
              category: LogCategory.service,
              tag: 'OfflineQueueService',
              metadata: {'type': operation.type.name, 'entityType': operation.entityType, 'entityId': operation.entityId},
            );
          }

          // Success - remove from queue
          await dequeue(operation.id);
          processed++;
          _logger.info(
            'Processed operation',
            category: LogCategory.service,
            tag: 'OfflineQueueService',
            metadata: {'type': operation.type.name, 'entityType': operation.entityType, 'entityId': operation.entityId},
          );
        } catch (e) {
          _logger.warning(
            'Operation failed: $e',
            category: LogCategory.service,
            tag: 'OfflineQueueService',
            metadata: {'entityType': operation.entityType, 'entityId': operation.entityId},
          );

          // Update retry count
          final updated = operation.copyWithRetry(e.toString());

          if (updated.retryCount >= CacheConfig.maxRetryAttempts) {
            // Move to dead letter queue
            await _moveToDeadLetter(updated);
            _logger.warning(
              'Moved to dead letter queue',
              category: LogCategory.service,
              tag: 'OfflineQueueService',
              metadata: {'entityType': operation.entityType, 'entityId': operation.entityId},
            );
          } else {
            // Update with error and wait before retry
            await HiveInitializer.offlineQueueBox.put(operation.id, updated);
            _emitCounts();

            // Calculate backoff delay
            final delay = _calculateBackoff(updated.retryCount);
            _logger.debug(
              'Scheduling retry',
              category: LogCategory.service,
              tag: 'OfflineQueueService',
              metadata: {'retryCount': updated.retryCount, 'maxRetries': CacheConfig.maxRetryAttempts, 'delaySeconds': delay.inSeconds},
            );

            await Future.delayed(delay);
          }
        }
      }
    } finally {
      _isProcessing = false;
      _emitCounts();
    }

    _logger.info('Queue processing complete', category: LogCategory.service, tag: 'OfflineQueueService', metadata: {'processed': processed});
    return processed;
  }

  /// Move an operation to the dead letter queue.
  Future<void> _moveToDeadLetter(OfflineOperation operation) async {
    final deadLetter = operation.copyAsDeadLetter();
    await HiveInitializer.offlineQueueBox.put(operation.id, deadLetter);
    _emitCounts();
  }

  /// Calculate exponential backoff delay.
  Duration _calculateBackoff(int retryCount) {
    final baseDelay = CacheConfig.initialRetryDelay.inMilliseconds;
    final multiplier = CacheConfig.retryBackoffMultiplier;

    // Calculate delay with exponential backoff
    var delayMs = baseDelay * (multiplier.toInt() << (retryCount - 1));

    // Add jitter (up to 25% of delay)
    final jitter = (delayMs * 0.25 * (DateTime.now().millisecond / 1000)).toInt();
    delayMs += jitter;

    // Cap at 30 seconds
    delayMs = delayMs.clamp(baseDelay, 30000);

    return Duration(milliseconds: delayMs);
  }

  /// Emit current counts to streams.
  void _emitCounts() {
    _pendingCountController.add(getPendingCount());
    _deadLetterCountController.add(getDeadLetterCount());
  }

  /// Retry a dead letter operation.
  Future<void> retryDeadLetter(int operationId) async {
    final box = HiveInitializer.offlineQueueBox;
    final operation = box.get(operationId);
    if (operation == null || !operation.isDeadLetter) return;

    // Reset retry count and dead letter status
    final retry = OfflineOperation(
      id: operation.id,
      type: operation.type,
      entityType: operation.entityType,
      entityId: operation.entityId,
      data: operation.data,
      createdAt: operation.createdAt,
      retryCount: 0,
      lastError: null,
      isDeadLetter: false,
    );

    await box.put(operationId, retry);
    _emitCounts();
    _logger.info('Retrying dead letter operation', category: LogCategory.service, tag: 'OfflineQueueService', metadata: {'operationId': operationId});

    // Try to process
    if (_connectivity.isOnline && !_isProcessing) {
      unawaited(processQueue().catchError((e) {
        _logger.error('Queue processing error: $e', category: LogCategory.service, tag: 'OfflineQueueService');
        return 0;
      }));
    }
  }

  /// Clear a dead letter operation (discard it).
  Future<void> clearDeadLetter(int operationId) async {
    final box = HiveInitializer.offlineQueueBox;
    final operation = box.get(operationId);
    if (operation == null || !operation.isDeadLetter) return;

    await box.delete(operationId);
    _emitCounts();
    _logger.info('Cleared dead letter', category: LogCategory.service, tag: 'OfflineQueueService', metadata: {'operationId': operationId});
  }

  /// Clear all dead letter operations.
  Future<void> clearAllDeadLetters() async {
    final deadLetters = getDeadLetterOperations();
    for (final op in deadLetters) {
      await HiveInitializer.offlineQueueBox.delete(op.id);
    }
    _emitCounts();
    _logger.info('Cleared all dead letters', category: LogCategory.service, tag: 'OfflineQueueService', metadata: {'count': deadLetters.length});
  }

  /// Clear entire queue (use with caution).
  Future<void> clearAll() async {
    await HiveInitializer.offlineQueueBox.clear();
    _nextId = 0;
    _emitCounts();
    _logger.warning('Cleared entire queue', category: LogCategory.service, tag: 'OfflineQueueService');
  }

  /// Dispose resources.
  void dispose() {
    _pendingCountController.close();
    _deadLetterCountController.close();
  }
}
