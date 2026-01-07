import '../../shared/models/relative_model.dart';
import '../../shared/models/interaction_model.dart';
import '../../shared/models/reminder_schedule_model.dart';
import '../../shared/models/sync_metadata.dart';
import '../cache/hive_initializer.dart';
import '../cache/cache_config.dart';
import 'app_logger_service.dart';

/// Service for managing local cache operations.
class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

  final AppLoggerService _logger = AppLoggerService();

  // ============================================================
  // RELATIVES CACHE
  // ============================================================

  /// Get all cached relatives for a user.
  List<Relative> getRelatives(String userId) {
    try {
      return HiveInitializer.relativesBox.values
          .where((r) => r.userId == userId && !r.isArchived)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get a single cached relative by ID.
  Relative? getRelative(String relativeId) {
    try {
      return HiveInitializer.relativesBox.get(relativeId);
    } catch (e) {
      return null;
    }
  }

  /// Cache a single relative.
  Future<void> putRelative(Relative relative) async {
    try {
      await HiveInitializer.relativesBox.put(relative.id, relative);
    } catch (e) {
      _logger.warning(
        'Cache write failed for relative',
        category: LogCategory.database,
        tag: 'Cache',
        metadata: {'relativeId': relative.id, 'error': e.toString()},
      );
    }
  }

  /// Cache multiple relatives.
  Future<void> putRelatives(List<Relative> relatives) async {
    try {
      final Map<String, Relative> entries = {
        for (final r in relatives) r.id: r,
      };
      await HiveInitializer.relativesBox.putAll(entries);
    } catch (e) {
      _logger.warning(
        'Cache batch write failed for relatives',
        category: LogCategory.database,
        tag: 'Cache',
        metadata: {'count': relatives.length, 'error': e.toString()},
      );
    }
  }

  /// Delete a relative from cache.
  Future<void> deleteRelative(String relativeId) async {
    try {
      await HiveInitializer.relativesBox.delete(relativeId);
    } catch (e) {
      _logger.warning(
        'Cache delete failed for relative',
        category: LogCategory.database,
        tag: 'Cache',
        metadata: {'relativeId': relativeId, 'error': e.toString()},
      );
    }
  }

  /// Clear all relatives from cache.
  Future<void> clearRelatives() async {
    try {
      await HiveInitializer.relativesBox.clear();
    } catch (e) {
      _logger.warning(
        'Cache clear failed for relatives',
        category: LogCategory.database,
        tag: 'Cache',
        metadata: {'error': e.toString()},
      );
    }
  }

  // ============================================================
  // INTERACTIONS CACHE
  // ============================================================

  /// Get cached interactions for a relative (limited to maxInteractionsPerRelative).
  List<Interaction> getInteractions(String relativeId) {
    try {
      return HiveInitializer.interactionsBox.values
          .where((i) => i.relativeId == relativeId)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)); // Most recent first
    } catch (e) {
      return [];
    }
  }

  /// Get all cached interactions for a user.
  List<Interaction> getAllInteractions(String userId) {
    try {
      return HiveInitializer.interactionsBox.values
          .where((i) => i.userId == userId)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      return [];
    }
  }

  /// Get today's interactions for a user.
  List<Interaction> getTodayInteractions(String userId) {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      return HiveInitializer.interactionsBox.values
          .where((i) =>
              i.userId == userId &&
              i.date.isAfter(startOfDay) &&
              i.date.isBefore(endOfDay))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      return [];
    }
  }

  /// Get a single cached interaction by ID.
  Interaction? getInteraction(String interactionId) {
    try {
      return HiveInitializer.interactionsBox.get(interactionId);
    } catch (e) {
      return null;
    }
  }

  /// Cache a single interaction with limit enforcement.
  Future<void> putInteraction(Interaction interaction) async {
    try {
      await HiveInitializer.interactionsBox.put(interaction.id, interaction);
      await _enforceInteractionLimit(interaction.relativeId);
    } catch (e) {
      // Silently fail - cache is not critical
    }
  }

  /// Cache multiple interactions with limit enforcement.
  Future<void> putInteractions(List<Interaction> interactions) async {
    try {
      final Map<String, Interaction> entries = {
        for (final i in interactions) i.id: i,
      };
      await HiveInitializer.interactionsBox.putAll(entries);

      // Enforce limit per relative
      final relativeIds = interactions.map((i) => i.relativeId).toSet();
      for (final relativeId in relativeIds) {
        await _enforceInteractionLimit(relativeId);
      }
    } catch (e) {
      // Silently fail - cache is not critical
    }
  }

  /// Enforce the interaction limit per relative (keep most recent 100).
  Future<void> _enforceInteractionLimit(String relativeId) async {
    final interactions = getInteractions(relativeId);
    if (interactions.length > CacheConfig.maxInteractionsPerRelative) {
      // Remove oldest interactions beyond the limit
      final toRemove = interactions
          .skip(CacheConfig.maxInteractionsPerRelative)
          .map((i) => i.id);
      for (final id in toRemove) {
        await HiveInitializer.interactionsBox.delete(id);
      }
    }
  }

  /// Delete an interaction from cache.
  Future<void> deleteInteraction(String interactionId) async {
    try {
      await HiveInitializer.interactionsBox.delete(interactionId);
    } catch (e) {
      // Silently fail - cache is not critical
    }
  }

  /// Clear all interactions from cache.
  Future<void> clearInteractions() async {
    try {
      await HiveInitializer.interactionsBox.clear();
    } catch (e) {
      // Silently fail - cache is not critical
    }
  }

  // ============================================================
  // REMINDER SCHEDULES CACHE
  // ============================================================

  /// Get all cached reminder schedules for a user.
  List<ReminderSchedule> getReminderSchedules(String userId) {
    try {
      return HiveInitializer.reminderSchedulesBox.values
          .where((s) => s.userId == userId)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get active reminder schedules for a user.
  List<ReminderSchedule> getActiveReminderSchedules(String userId) {
    try {
      return HiveInitializer.reminderSchedulesBox.values
          .where((s) => s.userId == userId && s.isActive)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get a single cached reminder schedule by ID.
  ReminderSchedule? getReminderSchedule(String scheduleId) {
    try {
      return HiveInitializer.reminderSchedulesBox.get(scheduleId);
    } catch (e) {
      return null;
    }
  }

  /// Cache a single reminder schedule.
  Future<void> putReminderSchedule(ReminderSchedule schedule) async {
    try {
      await HiveInitializer.reminderSchedulesBox.put(schedule.id, schedule);
    } catch (e) {
      // Silently fail - cache is not critical
    }
  }

  /// Cache multiple reminder schedules.
  Future<void> putReminderSchedules(List<ReminderSchedule> schedules) async {
    try {
      final Map<String, ReminderSchedule> entries = {
        for (final s in schedules) s.id: s,
      };
      await HiveInitializer.reminderSchedulesBox.putAll(entries);
    } catch (e) {
      // Silently fail - cache is not critical
    }
  }

  /// Delete a reminder schedule from cache.
  Future<void> deleteReminderSchedule(String scheduleId) async {
    try {
      await HiveInitializer.reminderSchedulesBox.delete(scheduleId);
    } catch (e) {
      // Silently fail - cache is not critical
    }
  }

  /// Clear all reminder schedules from cache.
  Future<void> clearReminderSchedules() async {
    try {
      await HiveInitializer.reminderSchedulesBox.clear();
    } catch (e) {
      // Silently fail - cache is not critical
    }
  }

  // ============================================================
  // SYNC METADATA
  // ============================================================

  /// Get sync metadata for a key.
  SyncMetadata? getSyncMetadata(String key) {
    try {
      return HiveInitializer.syncMetadataBox.get(key);
    } catch (e) {
      return null;
    }
  }

  /// Update sync metadata.
  Future<void> putSyncMetadata(SyncMetadata metadata) async {
    try {
      await HiveInitializer.syncMetadataBox.put(metadata.key, metadata);
    } catch (e) {
      // Silently fail - cache is not critical
    }
  }

  /// Check if cache is stale.
  bool isCacheStale(String key) {
    final metadata = getSyncMetadata(key);
    if (metadata == null) return true;
    return metadata.isStale(CacheConfig.staleCacheThreshold);
  }

  /// Get last sync time for a key.
  DateTime? getLastSyncTime(String key) {
    return getSyncMetadata(key)?.lastSync;
  }

  /// Update last sync time.
  Future<void> updateLastSyncTime(String key, {int itemCount = 0}) async {
    final metadata = SyncMetadata(
      key: key,
      lastSync: DateTime.now(),
      itemCount: itemCount,
    );
    await putSyncMetadata(metadata);
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  /// Clear all caches.
  Future<void> clearAll() async {
    await HiveInitializer.clearAll();
  }

  /// Get cache statistics for debugging.
  Map<String, int> getCacheStats() {
    return {
      'relatives': HiveInitializer.relativesBox.length,
      'interactions': HiveInitializer.interactionsBox.length,
      'reminderSchedules': HiveInitializer.reminderSchedulesBox.length,
      'offlineQueue': HiveInitializer.offlineQueueBox.length,
      'syncMetadata': HiveInitializer.syncMetadataBox.length,
    };
  }
}
