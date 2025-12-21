/// Configuration constants for the local cache system.
class CacheConfig {
  CacheConfig._();

  // Box names
  static const String relativesBox = 'relatives';
  static const String interactionsBox = 'interactions';
  static const String reminderSchedulesBox = 'reminder_schedules';
  static const String offlineQueueBox = 'offline_queue';
  static const String syncMetadataBox = 'sync_metadata';

  // Type IDs for Hive adapters
  // Core models: 0-9
  static const int relativeTypeId = 0;
  static const int interactionTypeId = 1;
  static const int reminderScheduleTypeId = 2;

  // Enums: 10-19
  static const int relationshipTypeTypeId = 10;
  static const int genderTypeId = 11;
  static const int avatarTypeTypeId = 12;
  static const int interactionTypeTypeId = 13;
  static const int reminderFrequencyTypeId = 14;
  static const int operationTypeTypeId = 15;

  // Cache models: 20-29
  static const int offlineOperationTypeId = 20;
  static const int syncMetadataTypeId = 21;

  // Cache limits
  static const int maxInteractionsPerRelative = 100;

  // Sync settings
  static const Duration staleCacheThreshold = Duration(minutes: 5);
  static const Duration backgroundSyncInterval = Duration(minutes: 5);

  // Retry settings
  static const int maxRetryAttempts = 5;
  static const Duration initialRetryDelay = Duration(seconds: 1);
  static const double retryBackoffMultiplier = 2.0;

  // Sync metadata keys
  static const String lastSyncRelativesKey = 'lastSync_relatives';
  static const String lastSyncRemindersKey = 'lastSync_reminders';
  static String lastSyncInteractionsKey(String relativeId) =>
      'lastSync_interactions_$relativeId';
}
