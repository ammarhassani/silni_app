import '../../shared/models/sync_metadata.dart';
import '../cache/hive_initializer.dart';
import '../cache/cache_config.dart';

/// Service for managing local cache operations.
///
/// Phase 9.X.D.B Tier 2: read-cache methods (relatives, interactions, reminder
/// schedules) removed. Repositories now read straight from Supabase realtime.
/// What remains is only the sync-metadata helpers used by the offline queue
/// replayer.
class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

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
      'offlineQueue': HiveInitializer.offlineQueueBox.length,
      'syncMetadata': HiveInitializer.syncMetadataBox.length,
    };
  }
}
