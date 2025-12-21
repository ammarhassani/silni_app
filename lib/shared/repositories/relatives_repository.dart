import 'dart:async';
import 'package:uuid/uuid.dart';

import '../models/relative_model.dart';
import '../models/offline_operation.dart';
import '../services/relatives_service.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/offline_queue_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/cache/cache_config.dart';
import '../../core/services/app_logger_service.dart';

/// Repository that orchestrates cache and network for relatives.
/// Implements cache-first reads and offline-capable writes.
class RelativesRepository {
  final RelativesService _service;
  final CacheService _cache;
  final OfflineQueueService _queue;
  final SyncService _sync;
  final ConnectivityService _connectivity;
  final Uuid _uuid;
  final AppLoggerService _logger = AppLoggerService();

  RelativesRepository({
    RelativesService? service,
    CacheService? cache,
    OfflineQueueService? queue,
    SyncService? sync,
    ConnectivityService? connectivity,
  })  : _service = service ?? RelativesService(),
        _cache = cache ?? CacheService.instance,
        _queue = queue ?? OfflineQueueService.instance,
        _sync = sync ?? SyncService.instance,
        _connectivity = connectivity ?? connectivityService,
        _uuid = const Uuid();

  // ============================================================
  // READ OPERATIONS (Cache-first)
  // ============================================================

  /// Watch relatives with cache-first strategy.
  /// Emits cached data immediately, then syncs and emits updates.
  Stream<List<Relative>> watchRelatives(String userId) async* {
    // 1. Always emit cached data first (even if empty for loading state)
    final cached = _cache.getRelatives(userId);
    yield _sortRelatives(cached);

    // 2. If online and cache is stale, sync
    if (_connectivity.isOnline &&
        _cache.isCacheStale(CacheConfig.lastSyncRelativesKey)) {
      try {
        await _sync.syncRelatives(userId);
        final updated = _cache.getRelatives(userId);
        yield _sortRelatives(updated);
      } catch (e) {
        // Sync failed, continue with cached data but log for visibility
        _logger.warning(
          'Sync failed for relatives, using cached data',
          category: LogCategory.database,
          tag: 'RelativesRepository',
          metadata: {'userId': userId, 'error': e.toString()},
        );
      }
    }

    // 3. Always stream remote updates - Supabase handles reconnection
    // This ensures data loads even when connectivity is still initializing
    try {
      await for (final serverData in _service.getRelativesStream(userId)) {
        // Update cache with server data
        await _cache.putRelatives(serverData);
        yield _sortRelatives(serverData);
      }
    } catch (e) {
      // Stream error - already have cached data, log for visibility
      _logger.warning(
        'Stream error for relatives, using cached data',
        category: LogCategory.database,
        tag: 'RelativesRepository',
        metadata: {'userId': userId, 'error': e.toString()},
      );
    }
  }

  /// Get a single relative (cache-first).
  Future<Relative?> getRelative(String relativeId) async {
    // Try cache first
    final cached = _cache.getRelative(relativeId);
    if (cached != null) return cached;

    // If not in cache and online, fetch from server
    if (_connectivity.isOnline) {
      final remote = await _service.getRelative(relativeId);
      if (remote != null) {
        await _cache.putRelative(remote);
      }
      return remote;
    }

    return null;
  }

  /// Watch a single relative.
  Stream<Relative?> watchRelative(String relativeId) async* {
    // Emit cached first
    final cached = _cache.getRelative(relativeId);
    yield cached;

    // Always stream remote updates - Supabase handles reconnection
    try {
      await for (final remote in _service.getRelativeStream(relativeId)) {
        if (remote != null) {
          await _cache.putRelative(remote);
        }
        yield remote;
      }
    } catch (e) {
      // Stream error - already have cached data, log for visibility
      _logger.warning(
        'Stream error for single relative, using cached data',
        category: LogCategory.database,
        tag: 'RelativesRepository',
        metadata: {'relativeId': relativeId, 'error': e.toString()},
      );
    }
  }

  /// Get relatives count.
  Future<int> getRelativesCount(String userId) async {
    // Try cache first
    final cached = _cache.getRelatives(userId);
    if (cached.isNotEmpty) return cached.length;

    // If cache empty and online, fetch from server
    if (_connectivity.isOnline) {
      return await _service.getRelativesCount(userId);
    }

    return 0;
  }

  /// Get favorites (from cache).
  List<Relative> getFavorites(String userId) {
    return _cache
        .getRelatives(userId)
        .where((r) => r.isFavorite)
        .toList();
  }

  /// Search relatives (cache-first).
  List<Relative> searchRelatives(String userId, String query) {
    final relatives = _cache.getRelatives(userId);
    final lowerQuery = query.toLowerCase();

    return relatives.where((r) {
      return r.fullName.toLowerCase().contains(lowerQuery) ||
          r.relationshipType.arabicName.toLowerCase().contains(lowerQuery) ||
          (r.phoneNumber?.contains(query) ?? false) ||
          (r.email?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  // ============================================================
  // WRITE OPERATIONS (Optimistic with queue)
  // ============================================================

  /// Create a new relative.
  /// Saves to cache immediately and queues for sync if offline.
  Future<String> createRelative(Relative relative) async {
    // Generate client-side ID if not provided
    final id = relative.id.isEmpty ? _uuid.v4() : relative.id;
    final now = DateTime.now();

    final newRelative = relative.copyWith(
      id: id,
      createdAt: now,
      updatedAt: now,
    );

    // Save to cache immediately (optimistic)
    await _cache.putRelative(newRelative);

    if (_connectivity.isOnline) {
      // Online: sync immediately
      try {
        final serverId = await _service.createRelative(newRelative);
        // Update cache with server ID if different
        if (serverId != id) {
          await _cache.deleteRelative(id);
          final serverRelative = newRelative.copyWith(id: serverId);
          await _cache.putRelative(serverRelative);
          return serverId;
        }
        return id;
      } catch (e) {
        // Failed - queue for later
        await _queueOperation(OperationType.create, 'relative', id, newRelative);
        return id;
      }
    } else {
      // Offline: queue for later
      await _queueOperation(OperationType.create, 'relative', id, newRelative);
      return id;
    }
  }

  /// Update an existing relative.
  Future<void> updateRelative(String relativeId, Map<String, dynamic> updates) async {
    // Get current relative and apply updates locally
    final current = _cache.getRelative(relativeId);
    if (current != null) {
      // Apply updates to create updated relative
      final updated = _applyUpdates(current, updates);
      await _cache.putRelative(updated);
    }

    if (_connectivity.isOnline) {
      try {
        await _service.updateRelative(relativeId, updates);
      } catch (e) {
        // Failed - queue for later
        await _queueOperation(OperationType.update, 'relative', relativeId, null, updates);
      }
    } else {
      // Offline: queue for later
      await _queueOperation(OperationType.update, 'relative', relativeId, null, updates);
    }
  }

  /// Delete (archive) a relative.
  Future<void> deleteRelative(String relativeId) async {
    // Mark as archived in cache
    final current = _cache.getRelative(relativeId);
    if (current != null) {
      await _cache.putRelative(current.copyWith(isArchived: true));
    }

    if (_connectivity.isOnline) {
      try {
        await _service.deleteRelative(relativeId);
      } catch (e) {
        await _queueOperation(OperationType.delete, 'relative', relativeId, null);
      }
    } else {
      await _queueOperation(OperationType.delete, 'relative', relativeId, null);
    }
  }

  /// Toggle favorite status.
  Future<void> toggleFavorite(String relativeId, bool isFavorite) async {
    await updateRelative(relativeId, {'is_favorite': isFavorite});
  }

  /// Record an interaction (updates last contact date).
  Future<void> recordInteraction(String relativeId) async {
    final updates = {
      'last_contact_date': DateTime.now().toUtc().toIso8601String(),
    };
    await updateRelative(relativeId, updates);

    if (_connectivity.isOnline) {
      try {
        await _service.recordInteraction(relativeId);
      } catch (e) {
        // Already updated locally, queued update will handle it
        _logger.warning(
          'Failed to record interaction on server, queued for later',
          category: LogCategory.database,
          tag: 'RelativesRepository',
          metadata: {'relativeId': relativeId, 'error': e.toString()},
        );
      }
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Queue an operation for offline sync.
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

  /// Apply updates to a relative.
  Relative _applyUpdates(Relative relative, Map<String, dynamic> updates) {
    return relative.copyWith(
      fullName: updates['full_name'] as String? ?? relative.fullName,
      relationshipType: updates['relationship_type'] != null
          ? RelationshipType.fromString(updates['relationship_type'] as String)
          : relative.relationshipType,
      gender: updates['gender'] != null
          ? Gender.fromString(updates['gender'] as String)
          : relative.gender,
      avatarType: updates['avatar_type'] != null
          ? AvatarType.fromString(updates['avatar_type'] as String)
          : relative.avatarType,
      phoneNumber: updates['phone_number'] as String? ?? relative.phoneNumber,
      email: updates['email'] as String? ?? relative.email,
      notes: updates['notes'] as String? ?? relative.notes,
      priority: updates['priority'] as int? ?? relative.priority,
      isFavorite: updates['is_favorite'] as bool? ?? relative.isFavorite,
      isArchived: updates['is_archived'] as bool? ?? relative.isArchived,
      lastContactDate: updates['last_contact_date'] != null
          ? DateTime.parse(updates['last_contact_date'] as String)
          : relative.lastContactDate,
      updatedAt: DateTime.now(),
    );
  }

  /// Sort relatives by priority then name.
  List<Relative> _sortRelatives(List<Relative> relatives) {
    return relatives
      ..sort((a, b) {
        final priorityCompare = a.priority.compareTo(b.priority);
        if (priorityCompare != 0) return priorityCompare;
        return a.fullName.compareTo(b.fullName);
      });
  }
}
