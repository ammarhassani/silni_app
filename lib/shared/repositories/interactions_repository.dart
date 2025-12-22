import 'dart:async';
import 'package:uuid/uuid.dart';

import '../models/interaction_model.dart';
import '../models/offline_operation.dart';
import '../services/interactions_service.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/offline_queue_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/cache/cache_config.dart';
import '../../core/services/app_logger_service.dart';

/// Repository that orchestrates cache and network for interactions.
/// Implements cache-first reads and offline-capable writes.
class InteractionsRepository {
  final InteractionsService _service;
  final CacheService _cache;
  final OfflineQueueService _queue;
  final SyncService _sync;
  final ConnectivityService _connectivity;
  final Uuid _uuid;
  final AppLoggerService _logger = AppLoggerService();

  InteractionsRepository({
    InteractionsService? service,
    CacheService? cache,
    OfflineQueueService? queue,
    SyncService? sync,
    ConnectivityService? connectivity,
  })  : _service = service ?? InteractionsService(),
        _cache = cache ?? CacheService.instance,
        _queue = queue ?? OfflineQueueService.instance,
        _sync = sync ?? SyncService.instance,
        _connectivity = connectivity ?? connectivityService,
        _uuid = const Uuid();

  // ============================================================
  // READ OPERATIONS (Cache-first)
  // ============================================================

  /// Watch interactions for a specific relative.
  Stream<List<Interaction>> watchRelativeInteractions(String relativeId) async* {
    // 1. Always emit cached data first (even if empty)
    final cached = _cache.getInteractions(relativeId);
    yield cached;

    // 2. If online and cache is stale, sync
    final cacheKey = CacheConfig.lastSyncInteractionsKey(relativeId);
    if (_connectivity.isOnline && _cache.isCacheStale(cacheKey)) {
      try {
        await _sync.syncInteractionsForRelative(relativeId);
        final updated = _cache.getInteractions(relativeId);
        yield updated;
      } catch (e) {
        // Sync failed, continue with cached data but log for visibility
        _logger.warning(
          'Sync failed for interactions, using cached data',
          category: LogCategory.database,
          tag: 'InteractionsRepository',
          metadata: {'relativeId': relativeId, 'error': e.toString()},
        );
      }
    }

    // 3. Always stream remote updates - Supabase handles reconnection
    try {
      await for (final serverData
          in _service.getRelativeInteractionsStream(relativeId)) {
        // Take only the most recent based on limit
        final limited = serverData.take(CacheConfig.maxInteractionsPerRelative).toList();
        await _cache.putInteractions(limited);
        yield limited;
      }
    } catch (e) {
      // Stream error - already have cached data, log for visibility
      _logger.warning(
        'Stream error for relative interactions, using cached data',
        category: LogCategory.database,
        tag: 'InteractionsRepository',
        metadata: {'relativeId': relativeId, 'error': e.toString()},
      );
    }
  }

  /// Watch all interactions for a user.
  Stream<List<Interaction>> watchUserInteractions(String userId) async* {
    // Always emit cached first (even if empty)
    final cached = _cache.getAllInteractions(userId);
    yield cached;

    // Always stream remote updates - Supabase handles reconnection
    try {
      await for (final serverData in _service.getInteractionsStream(userId)) {
        await _cache.putInteractions(serverData);
        yield serverData;
      }
    } catch (e) {
      // Stream error - already have cached data, log for visibility
      _logger.warning(
        'Stream error for user interactions, using cached data',
        category: LogCategory.database,
        tag: 'InteractionsRepository',
        metadata: {'userId': userId, 'error': e.toString()},
      );
    }
  }

  /// Watch today's interactions for a user.
  Stream<List<Interaction>> watchTodayInteractions(String userId) async* {
    // Always emit cached first (even if empty)
    final cached = _cache.getTodayInteractions(userId);
    yield cached;

    // Always stream remote updates - Supabase handles reconnection
    try {
      await for (final serverData
          in _service.getTodayInteractionsStream(userId)) {
        await _cache.putInteractions(serverData);
        yield serverData;
      }
    } catch (e) {
      // Stream error - already have cached data, log for visibility
      _logger.warning(
        'Stream error for today interactions, using cached data',
        category: LogCategory.database,
        tag: 'InteractionsRepository',
        metadata: {'userId': userId, 'error': e.toString()},
      );
    }
  }

  /// Get a single interaction.
  Future<Interaction?> getInteraction(String interactionId) async {
    // Try cache first
    final cached = _cache.getInteraction(interactionId);
    if (cached != null) return cached;

    // Note: No direct getInteraction in service, would need to add
    return null;
  }

  /// Get recent interactions.
  Future<List<Interaction>> getRecentInteractions(
    String userId, {
    int limit = 10,
  }) async {
    // Try cache first
    final cached = _cache.getAllInteractions(userId);
    if (cached.isNotEmpty) {
      return cached.take(limit).toList();
    }

    // If cache empty and online, fetch from server
    if (_connectivity.isOnline) {
      return await _service.getRecentInteractions(userId, limit: limit);
    }

    return [];
  }

  /// Check if user has interacted today (cache-first).
  Future<bool> hasInteractedToday(String userId) async {
    final today = _cache.getTodayInteractions(userId);
    if (today.isNotEmpty) return true;

    if (_connectivity.isOnline) {
      return await _service.hasInteractedToday(userId);
    }

    return false;
  }

  // ============================================================
  // WRITE OPERATIONS (Optimistic with queue)
  // ============================================================

  /// Create a new interaction.
  Future<String> createInteraction(Interaction interaction) async {
    // Generate client-side ID if not provided
    final id = interaction.id.isEmpty ? _uuid.v4() : interaction.id;
    final now = DateTime.now();

    final newInteraction = interaction.copyWith(
      id: id,
      createdAt: now,
      updatedAt: now,
    );

    // Save to cache immediately (optimistic)
    await _cache.putInteraction(newInteraction);

    if (_connectivity.isOnline) {
      try {
        final serverId = await _service.createInteraction(newInteraction);
        // Update cache with server ID if different
        if (serverId != id) {
          await _cache.deleteInteraction(id);
          final serverInteraction = newInteraction.copyWith(id: serverId);
          await _cache.putInteraction(serverInteraction);
          return serverId;
        }
        return id;
      } catch (e) {
        // Failed - queue for later
        await _queueOperation(OperationType.create, id, newInteraction);
        return id;
      }
    } else {
      // Offline: queue for later
      await _queueOperation(OperationType.create, id, newInteraction);
      return id;
    }
  }

  /// Update an existing interaction.
  Future<void> updateInteraction(
    String interactionId,
    Map<String, dynamic> updates,
  ) async {
    // Get current interaction and apply updates locally
    final current = _cache.getInteraction(interactionId);
    if (current != null) {
      final updated = _applyUpdates(current, updates);
      await _cache.putInteraction(updated);
    }

    if (_connectivity.isOnline) {
      try {
        await _service.updateInteraction(interactionId, updates);
      } catch (e) {
        await _queueOperation(
          OperationType.update,
          interactionId,
          null,
          updates,
        );
      }
    } else {
      await _queueOperation(
        OperationType.update,
        interactionId,
        null,
        updates,
      );
    }
  }

  /// Delete an interaction.
  Future<void> deleteInteraction(String interactionId) async {
    // Remove from cache immediately
    await _cache.deleteInteraction(interactionId);

    if (_connectivity.isOnline) {
      try {
        await _service.deleteInteraction(interactionId);
      } catch (e) {
        await _queueOperation(OperationType.delete, interactionId, null);
      }
    } else {
      await _queueOperation(OperationType.delete, interactionId, null);
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Queue an operation for offline sync.
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

  /// Apply updates to an interaction.
  Interaction _applyUpdates(
    Interaction interaction,
    Map<String, dynamic> updates,
  ) {
    return interaction.copyWith(
      type: updates['type'] != null
          ? InteractionType.fromString(updates['type'] as String)
          : interaction.type,
      date: updates['date'] != null
          ? DateTime.parse(updates['date'] as String)
          : interaction.date,
      duration: updates['duration'] as int? ?? interaction.duration,
      location: updates['location'] as String? ?? interaction.location,
      notes: updates['notes'] as String? ?? interaction.notes,
      mood: updates['mood'] as String? ?? interaction.mood,
      rating: updates['rating'] as int? ?? interaction.rating,
      updatedAt: DateTime.now(),
    );
  }
}
