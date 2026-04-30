/// Configuration constants for what's left of the local cache system.
///
/// Phase 9.X.D.B Tier 2 stripped the read-cache (relatives / interactions /
/// reminderSchedules boxes + their type IDs + per-resource sync keys). What
/// remains: the offline write queue + sync metadata, plus a single tunable
/// for capping interaction-list rendering per relative.
class CacheConfig {
  CacheConfig._();

  // Box names — only the ones still opened by HiveInitializer.
  static const String offlineQueueBox = 'offline_queue';
  static const String syncMetadataBox = 'sync_metadata';

  // Type IDs for Hive adapters — only the ones still registered.
  static const int operationTypeTypeId = 15;
  static const int offlineOperationTypeId = 20;
  static const int syncMetadataTypeId = 21;

  // Render tunable — used by InteractionsRepository to cap the per-relative
  // interaction list before yielding to the UI.
  static const int maxInteractionsPerRelative = 100;

  // Retry settings used by the offline queue replayer.
  static const int maxRetryAttempts = 5;
  static const Duration initialRetryDelay = Duration(seconds: 1);
  static const double retryBackoffMultiplier = 2.0;

  // Background sync polling interval.
  static const Duration backgroundSyncInterval = Duration(minutes: 5);

  // Stale-cache threshold — preserved for any future use, currently unread.
  static const Duration staleCacheThreshold = Duration(minutes: 5);
}
