import 'dart:async';
import 'package:uuid/uuid.dart';

import '../models/interaction_model.dart';
import '../models/offline_operation.dart';
import '../services/interactions_service.dart';
import '../../core/services/offline_queue_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/cache/cache_config.dart';
import '../../core/services/app_logger_service.dart';

/// Repository for interactions data.
///
/// Phase 9.X.D.B Tier 2: read-cache (Hive `interactionsBox`) removed. Reads
/// stream straight from Supabase realtime. Writes hit the network when
/// online, enqueue on the offline queue otherwise.
class InteractionsRepository {
  final InteractionsService _service;
  final OfflineQueueService _queue;
  final ConnectivityService _connectivity;
  final Uuid _uuid;
  final AppLoggerService _logger = AppLoggerService();

  InteractionsRepository({
    InteractionsService? service,
    OfflineQueueService? queue,
    ConnectivityService? connectivity,
  })  : _service = service ?? InteractionsService(),
        _queue = queue ?? OfflineQueueService.instance,
        _connectivity = connectivity ?? connectivityService,
        _uuid = const Uuid();

  // ============================================================
  // READ OPERATIONS (Supabase stream is single source of truth)
  // ============================================================

  /// Watch interactions for a specific relative.
  Stream<List<Interaction>> watchRelativeInteractions(
      String relativeId) async* {
    try {
      await for (final serverData
          in _service.getRelativeInteractionsStream(relativeId)) {
        yield serverData
            .take(CacheConfig.maxInteractionsPerRelative)
            .toList();
      }
    } catch (e) {
      _logger.warning(
        'Stream error for relative interactions',
        category: LogCategory.database,
        tag: 'InteractionsRepository',
        metadata: {'relativeId': relativeId, 'error': e.toString()},
      );
    }
  }

  /// Watch all interactions for a user.
  Stream<List<Interaction>> watchUserInteractions(String userId) async* {
    try {
      await for (final serverData in _service.getInteractionsStream(userId)) {
        yield serverData;
      }
    } catch (e) {
      _logger.warning(
        'Stream error for user interactions',
        category: LogCategory.database,
        tag: 'InteractionsRepository',
        metadata: {'userId': userId, 'error': e.toString()},
      );
    }
  }

  /// Watch today's interactions for a user.
  Stream<List<Interaction>> watchTodayInteractions(String userId) async* {
    try {
      await for (final serverData
          in _service.getTodayInteractionsStream(userId)) {
        yield serverData;
      }
    } catch (e) {
      _logger.warning(
        'Stream error for today interactions',
        category: LogCategory.database,
        tag: 'InteractionsRepository',
        metadata: {'userId': userId, 'error': e.toString()},
      );
    }
  }

  // ============================================================
  // WRITE OPERATIONS (Server-first, queue on offline)
  // ============================================================

  /// Create a new interaction.
  Future<String> createInteraction(Interaction interaction) async {
    final id = interaction.id.isEmpty ? _uuid.v4() : interaction.id;
    final now = DateTime.now();
    final newInteraction = interaction.copyWith(
      id: id,
      createdAt: now,
      updatedAt: now,
    );

    if (_connectivity.isOnline) {
      try {
        return await _service.createInteraction(newInteraction);
      } catch (e) {
        await _queueOperation(OperationType.create, id, newInteraction);
        return id;
      }
    } else {
      await _queueOperation(OperationType.create, id, newInteraction);
      return id;
    }
  }

  /// Update an existing interaction.
  Future<void> updateInteraction(
    String interactionId,
    Map<String, dynamic> updates,
  ) async {
    if (_connectivity.isOnline) {
      try {
        await _service.updateInteraction(interactionId, updates);
      } catch (e) {
        await _queueOperation(
            OperationType.update, interactionId, null, updates);
      }
    } else {
      await _queueOperation(
          OperationType.update, interactionId, null, updates);
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Future<void> _queueOperation(
    OperationType type,
    String entityId,
    Interaction? interaction, [
    Map<String, dynamic>? updates,
  ]) async {
    final data = interaction != null
        ? {
            ...interaction.toJson(),
            'id': interaction.id,
            'created_at': interaction.createdAt.toUtc().toIso8601String(),
            if (interaction.updatedAt != null)
              'updated_at': interaction.updatedAt!.toUtc().toIso8601String(),
          }
        : updates ?? {};

    final operation = OfflineOperation(
      id: 0,
      type: type,
      entityType: 'interaction',
      entityId: entityId,
      data: data,
      createdAt: DateTime.now(),
    );

    await _queue.enqueue(operation);
  }
}
