import 'dart:async';
import 'package:uuid/uuid.dart';

import '../models/reminder_schedule_model.dart';
import '../models/offline_operation.dart';
import '../services/reminder_schedules_service.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/offline_queue_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/cache/cache_config.dart';
import '../../core/services/app_logger_service.dart';

/// Repository that orchestrates cache and network for reminder schedules.
/// Implements cache-first reads and offline-capable writes.
class ReminderSchedulesRepository {
  final ReminderSchedulesService _service;
  final CacheService _cache;
  final OfflineQueueService _queue;
  final SyncService _sync;
  final ConnectivityService _connectivity;
  final Uuid _uuid;
  final AppLoggerService _logger = AppLoggerService();

  ReminderSchedulesRepository({
    ReminderSchedulesService? service,
    CacheService? cache,
    OfflineQueueService? queue,
    SyncService? sync,
    ConnectivityService? connectivity,
  })  : _service = service ?? ReminderSchedulesService(),
        _cache = cache ?? CacheService.instance,
        _queue = queue ?? OfflineQueueService.instance,
        _sync = sync ?? SyncService.instance,
        _connectivity = connectivity ?? connectivityService,
        _uuid = const Uuid();

  // ============================================================
  // READ OPERATIONS (Cache-first)
  // ============================================================

  /// Watch all reminder schedules for a user.
  Stream<List<ReminderSchedule>> watchSchedules(String userId) async* {
    // 1. Always emit cached data first (even if empty)
    final cached = _cache.getReminderSchedules(userId);
    yield _sortSchedules(cached);

    // 2. If online and cache is stale, sync
    if (_connectivity.isOnline &&
        _cache.isCacheStale(CacheConfig.lastSyncRemindersKey)) {
      try {
        await _sync.syncReminderSchedules(userId);
        final updated = _cache.getReminderSchedules(userId);
        yield _sortSchedules(updated);
      } catch (e) {
        // Sync failed, continue with cached data but log for visibility
        _logger.warning(
          'Sync failed for reminder schedules, using cached data',
          category: LogCategory.database,
          tag: 'ReminderSchedulesRepository',
          metadata: {'userId': userId, 'error': e.toString()},
        );
      }
    }

    // 3. Always stream remote updates - Supabase handles reconnection
    try {
      await for (final serverData in _service.getSchedulesStream(userId)) {
        await _cache.putReminderSchedules(serverData);
        yield _sortSchedules(serverData);
      }
    } catch (e) {
      // Stream error - already have cached data, log for visibility
      _logger.warning(
        'Stream error for reminder schedules, using cached data',
        category: LogCategory.database,
        tag: 'ReminderSchedulesRepository',
        metadata: {'userId': userId, 'error': e.toString()},
      );
    }
  }

  /// Watch active schedules only.
  Stream<List<ReminderSchedule>> watchActiveSchedules(String userId) async* {
    // Always emit cached active schedules first (even if empty)
    final cached = _cache.getActiveReminderSchedules(userId);
    yield _sortSchedules(cached);

    // Always stream remote updates - Supabase handles reconnection
    try {
      await for (final serverData
          in _service.getActiveSchedulesStream(userId)) {
        await _cache.putReminderSchedules(serverData);
        yield _sortSchedules(serverData);
      }
    } catch (e) {
      // Stream error - already have cached data, log for visibility
      _logger.warning(
        'Stream error for active schedules, using cached data',
        category: LogCategory.database,
        tag: 'ReminderSchedulesRepository',
        metadata: {'userId': userId, 'error': e.toString()},
      );
    }
  }

  /// Get a single schedule.
  Future<ReminderSchedule?> getSchedule(String scheduleId) async {
    // Try cache first
    final cached = _cache.getReminderSchedule(scheduleId);
    if (cached != null) return cached;

    // If not in cache and online, fetch from server
    if (_connectivity.isOnline) {
      final remote = await _service.getSchedule(scheduleId);
      if (remote != null) {
        await _cache.putReminderSchedule(remote);
      }
      return remote;
    }

    return null;
  }

  /// Get today's schedules (that should fire today).
  Future<List<ReminderSchedule>> getTodaySchedules(String userId) async {
    // Get all active schedules from cache
    final schedules = _cache.getActiveReminderSchedules(userId);
    final today = schedules.where((s) => s.shouldFireToday()).toList();

    if (today.isNotEmpty) return today;

    // If cache empty and online, fetch from server
    if (_connectivity.isOnline) {
      return await _service.getTodaySchedules(userId);
    }

    return [];
  }

  /// Get schedules by frequency.
  List<ReminderSchedule> getSchedulesByFrequency(
    String userId,
    ReminderFrequency frequency,
  ) {
    return _cache
        .getReminderSchedules(userId)
        .where((s) => s.frequency == frequency)
        .toList();
  }

  // ============================================================
  // WRITE OPERATIONS (Optimistic with queue)
  // ============================================================

  /// Create a new reminder schedule.
  Future<String> createSchedule(Map<String, dynamic> scheduleData) async {
    // Generate client-side ID if not provided
    final id = scheduleData['id'] as String? ?? _uuid.v4();
    final now = DateTime.now();

    // Add metadata
    final data = {
      ...scheduleData,
      'id': id,
      'created_at': now.toUtc().toIso8601String(),
    };

    // Parse into model and cache
    final schedule = ReminderSchedule.fromJson(data);
    await _cache.putReminderSchedule(schedule);

    if (_connectivity.isOnline) {
      try {
        final serverId = await _service.createSchedule(scheduleData);
        // Update cache with server ID if different
        if (serverId != id) {
          await _cache.deleteReminderSchedule(id);
          final updated = schedule.copyWith(id: serverId);
          await _cache.putReminderSchedule(updated);
          return serverId;
        }
        return id;
      } catch (e) {
        await _queueOperation(OperationType.create, id, data);
        return id;
      }
    } else {
      await _queueOperation(OperationType.create, id, data);
      return id;
    }
  }

  /// Update an existing schedule.
  Future<void> updateSchedule(
    String scheduleId,
    Map<String, dynamic> updates,
  ) async {
    // Get current schedule and apply updates locally
    final current = _cache.getReminderSchedule(scheduleId);
    if (current != null) {
      final updated = _applyUpdates(current, updates);
      await _cache.putReminderSchedule(updated);
    }

    if (_connectivity.isOnline) {
      try {
        await _service.updateSchedule(scheduleId, updates);
      } catch (e) {
        await _queueOperation(OperationType.update, scheduleId, updates);
      }
    } else {
      await _queueOperation(OperationType.update, scheduleId, updates);
    }
  }

  /// Delete a schedule.
  Future<void> deleteSchedule(String scheduleId) async {
    // Remove from cache immediately
    await _cache.deleteReminderSchedule(scheduleId);

    if (_connectivity.isOnline) {
      try {
        await _service.deleteSchedule(scheduleId);
      } catch (e) {
        await _queueOperation(OperationType.delete, scheduleId, {});
      }
    } else {
      await _queueOperation(OperationType.delete, scheduleId, {});
    }
  }

  /// Toggle schedule active status.
  Future<void> toggleScheduleStatus(String scheduleId, bool isActive) async {
    await updateSchedule(scheduleId, {'is_active': isActive});
  }

  /// Add relatives to a schedule.
  Future<void> addRelativesToSchedule(
    String scheduleId,
    List<String> relativeIds,
  ) async {
    final current = _cache.getReminderSchedule(scheduleId);
    if (current != null) {
      final existingIds = Set<String>.from(current.relativeIds);
      existingIds.addAll(relativeIds);
      await updateSchedule(scheduleId, {
        'relative_ids': existingIds.toList(),
      });
    }

    if (_connectivity.isOnline) {
      try {
        await _service.addRelativesToSchedule(scheduleId, relativeIds);
      } catch (e) {
        // Already handled in updateSchedule
      }
    }
  }

  /// Remove a relative from a schedule.
  Future<void> removeRelativeFromSchedule(
    String scheduleId,
    String relativeId,
  ) async {
    final current = _cache.getReminderSchedule(scheduleId);
    if (current != null) {
      final updatedIds = current.relativeIds
          .where((id) => id != relativeId)
          .toList();
      await updateSchedule(scheduleId, {'relative_ids': updatedIds});
    }

    if (_connectivity.isOnline) {
      try {
        await _service.removeRelativeFromSchedule(scheduleId, relativeId);
      } catch (e) {
        // Already handled in updateSchedule
      }
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Queue an operation for offline sync.
  Future<void> _queueOperation(
    OperationType type,
    String entityId,
    Map<String, dynamic> data,
  ) async {
    final operation = OfflineOperation(
      id: 0,
      type: type,
      entityType: 'schedule',
      entityId: entityId,
      data: data,
      createdAt: DateTime.now(),
    );

    await _queue.enqueue(operation);
  }

  /// Apply updates to a schedule.
  ReminderSchedule _applyUpdates(
    ReminderSchedule schedule,
    Map<String, dynamic> updates,
  ) {
    return schedule.copyWith(
      frequency: updates['frequency'] != null
          ? ReminderFrequency.fromString(updates['frequency'] as String)
          : schedule.frequency,
      relativeIds: updates['relative_ids'] != null
          ? List<String>.from(updates['relative_ids'] as List)
          : schedule.relativeIds,
      time: updates['time'] as String? ?? schedule.time,
      isActive: updates['is_active'] as bool? ?? schedule.isActive,
      customDays: updates['custom_days'] != null
          ? List<int>.from(updates['custom_days'] as List)
          : schedule.customDays,
      dayOfMonth: updates['day_of_month'] as int? ?? schedule.dayOfMonth,
      updatedAt: DateTime.now(),
    );
  }

  /// Sort schedules by creation date (newest first).
  List<ReminderSchedule> _sortSchedules(List<ReminderSchedule> schedules) {
    return schedules..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
