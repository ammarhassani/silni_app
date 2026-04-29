import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/reminder_schedule_model.dart';
import '../models/offline_operation.dart';
import '../services/reminder_schedules_service.dart';
import '../../core/errors/app_errors.dart';
import '../../core/services/offline_queue_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/app_logger_service.dart';

/// Repository for reminder schedules.
///
/// Phase 9.X.D.B Tier 2: read-cache (Hive `reminderSchedulesBox`) removed.
/// Reads stream straight from Supabase. Writes hit the network when online,
/// enqueue otherwise. Unused methods (watchActiveSchedules, getSchedule,
/// getTodaySchedules, deleteSchedule, toggleScheduleStatus, etc.) dropped.
class ReminderSchedulesRepository {
  final ReminderSchedulesService _service;
  final OfflineQueueService _queue;
  final ConnectivityService _connectivity;
  final Uuid _uuid;
  final AppLoggerService _logger = AppLoggerService();

  ReminderSchedulesRepository({
    ReminderSchedulesService? service,
    OfflineQueueService? queue,
    ConnectivityService? connectivity,
  })  : _service = service ?? ReminderSchedulesService(),
        _queue = queue ?? OfflineQueueService.instance,
        _connectivity = connectivity ?? connectivityService,
        _uuid = const Uuid();

  // ============================================================
  // READ OPERATIONS (Supabase stream is single source of truth)
  // ============================================================

  /// Watch all reminder schedules for a user.
  Stream<List<ReminderSchedule>> watchSchedules(String userId) async* {
    try {
      await for (final serverData in _service.getSchedulesStream(userId)) {
        yield _sortSchedules(serverData);
      }
    } catch (e) {
      _logger.warning(
        'Stream error for reminder schedules',
        category: LogCategory.database,
        tag: 'ReminderSchedulesRepository',
        metadata: {'userId': userId, 'error': e.toString()},
      );
    }
  }

  // ============================================================
  // WRITE OPERATIONS (Server-first, queue on offline)
  // ============================================================

  /// Create a new reminder schedule.
  Future<String> createSchedule(Map<String, dynamic> scheduleData) async {
    final id = scheduleData['id'] as String? ?? _uuid.v4();
    final now = DateTime.now();
    final data = {
      ...scheduleData,
      'id': id,
      'created_at': now.toUtc().toIso8601String(),
    };

    if (_connectivity.isOnline) {
      try {
        return await _service.createSchedule(scheduleData);
      } catch (e) {
        // Server-side rejections (trigger errors) — must NOT be queued.
        if (e is PostgrestException && (e.code ?? '').startsWith('P')) {
          throw ServerRejectionError(
            message: e.message,
            arabicMessage: 'تم الوصول للحد الأقصى من التذكيرات',
            originalError: e,
          );
        }
        // Network/transient error — safe to queue
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

  // ============================================================
  // HELPERS
  // ============================================================

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

  List<ReminderSchedule> _sortSchedules(List<ReminderSchedule> schedules) {
    return schedules..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
