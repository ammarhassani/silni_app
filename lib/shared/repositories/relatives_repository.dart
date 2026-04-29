import 'dart:async';
import 'package:uuid/uuid.dart';

import '../models/relative_model.dart';
import '../models/offline_operation.dart';
import '../services/relatives_service.dart';
import '../../core/services/offline_queue_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/app_logger_service.dart';

/// Repository for relatives data.
///
/// Phase 9.X.D.B Tier 2: read-cache (Hive `relativesBox`) removed. Reads now
/// go straight to the Supabase realtime stream, which is the single source of
/// truth and reactively pushes deletes/updates within ~100ms. Writes go to
/// the network when online; if offline, they enqueue on the offline queue
/// (the durability layer that wasn't touched). Source of stale-data bugs
/// (cache returning a relative the server already deleted) is gone.
class RelativesRepository {
  final RelativesService _service;
  final OfflineQueueService _queue;
  final ConnectivityService _connectivity;
  final Uuid _uuid;
  final AppLoggerService _logger = AppLoggerService();

  RelativesRepository({
    RelativesService? service,
    OfflineQueueService? queue,
    ConnectivityService? connectivity,
  })  : _service = service ?? RelativesService(),
        _queue = queue ?? OfflineQueueService.instance,
        _connectivity = connectivity ?? connectivityService,
        _uuid = const Uuid();

  // ============================================================
  // READ OPERATIONS (Supabase stream is single source of truth)
  // ============================================================

  /// Watch relatives — pure Supabase realtime stream.
  Stream<List<Relative>> watchRelatives(String userId) async* {
    try {
      await for (final serverData in _service.getRelativesStream(userId)) {
        yield _sortRelatives(serverData);
      }
    } catch (e) {
      _logger.warning(
        'Stream error for relatives',
        category: LogCategory.database,
        tag: 'RelativesRepository',
        metadata: {'userId': userId, 'error': e.toString()},
      );
    }
  }

  /// Get a single relative — direct fetch.
  Future<Relative?> getRelative(String relativeId) async {
    if (!_connectivity.isOnline) return null;
    return _service.getRelative(relativeId);
  }

  /// Watch a single relative — pure Supabase realtime stream.
  Stream<Relative?> watchRelative(String relativeId) async* {
    try {
      await for (final remote in _service.getRelativeStream(relativeId)) {
        yield remote;
      }
    } catch (e) {
      _logger.warning(
        'Stream error for single relative',
        category: LogCategory.database,
        tag: 'RelativesRepository',
        metadata: {'relativeId': relativeId, 'error': e.toString()},
      );
    }
  }

  // ============================================================
  // WRITE OPERATIONS (Server-first, queue on offline)
  // ============================================================

  /// Create a new relative.
  Future<String> createRelative(Relative relative) async {
    final id = relative.id.isEmpty ? _uuid.v4() : relative.id;
    final now = DateTime.now();
    final newRelative = relative.copyWith(
      id: id,
      createdAt: now,
      updatedAt: now,
    );

    if (_connectivity.isOnline) {
      try {
        return await _service.createRelative(newRelative);
      } catch (e) {
        await _queueOperation(
            OperationType.create, 'relative', id, newRelative);
        return id;
      }
    } else {
      await _queueOperation(OperationType.create, 'relative', id, newRelative);
      return id;
    }
  }

  /// Update an existing relative.
  Future<void> updateRelative(
      String relativeId, Map<String, dynamic> updates) async {
    if (_connectivity.isOnline) {
      try {
        await _service.updateRelative(relativeId, updates);
      } catch (e) {
        await _queueOperation(
            OperationType.update, 'relative', relativeId, null, updates);
      }
    } else {
      await _queueOperation(
          OperationType.update, 'relative', relativeId, null, updates);
    }
  }

  /// Permanently delete a relative (hard delete).
  ///
  /// On server failure, the Supabase stream re-emits the unchanged record
  /// shortly after — UI consistency restored automatically. No cache rollback
  /// snapshot needed (used to be required when cache was the source of truth).
  Future<void> permanentlyDeleteRelative(String relativeId) async {
    if (_connectivity.isOnline) {
      try {
        await _service.permanentlyDeleteRelative(relativeId);
      } catch (e) {
        _logger.warning(
          'Failed to permanently delete relative',
          category: LogCategory.database,
          tag: 'RelativesRepository',
          metadata: {'relativeId': relativeId, 'error': e.toString()},
        );
        rethrow;
      }
    } else {
      await _queueOperation(
          OperationType.delete, 'relative', relativeId, null);
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Future<void> _queueOperation(
    OperationType type,
    String entityType,
    String entityId,
    Relative? relative, [
    Map<String, dynamic>? updates,
  ]) async {
    final data = relative != null
        ? {
            ...relative.toJson(),
            'id': relative.id,
            'created_at': relative.createdAt.toUtc().toIso8601String(),
            if (relative.updatedAt != null)
              'updated_at': relative.updatedAt!.toUtc().toIso8601String(),
          }
        : updates ?? {};

    final operation = OfflineOperation(
      id: 0, // Will be assigned by queue
      type: type,
      entityType: entityType,
      entityId: entityId,
      data: data,
      createdAt: DateTime.now(),
    );

    await _queue.enqueue(operation);
  }

  List<Relative> _sortRelatives(List<Relative> relatives) {
    return relatives
      ..sort((a, b) {
        final priorityCompare = a.priority.compareTo(b.priority);
        if (priorityCompare != 0) return priorityCompare;
        return a.fullName.compareTo(b.fullName);
      });
  }
}
