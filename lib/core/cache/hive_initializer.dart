import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../shared/models/relative_model.dart';
import '../../shared/models/interaction_model.dart';
import '../../shared/models/reminder_schedule_model.dart';
import '../../shared/models/offline_operation.dart';
import '../../shared/models/sync_metadata.dart';

import 'adapters/enum_adapters.dart';
import 'adapters/relative_adapter.dart';
import 'adapters/interaction_adapter.dart';
import 'adapters/reminder_schedule_adapter.dart';
import 'adapters/offline_operation_adapter.dart';
import 'adapters/sync_metadata_adapter.dart';
import 'cache_config.dart';

/// Initializes Hive for local caching.
class HiveInitializer {
  HiveInitializer._();

  static bool _initialized = false;

  /// Initialize Hive and register all adapters.
  /// Call this before runApp() in main.dart.
  static Future<void> initialize() async {
    if (_initialized) {
      debugPrint('[HiveInitializer] Already initialized, skipping');
      return;
    }

    debugPrint('[HiveInitializer] Initializing Hive...');

    // Initialize Hive with Flutter
    await Hive.initFlutter();

    // Register enum adapters first (they're used by model adapters)
    _registerEnumAdapters();

    // Register model adapters
    _registerModelAdapters();

    // Open boxes with error recovery
    await _openBoxes();

    _initialized = true;
    debugPrint('[HiveInitializer] Hive initialization complete');
  }

  /// Register all enum adapters.
  static void _registerEnumAdapters() {
    if (!Hive.isAdapterRegistered(CacheConfig.relationshipTypeTypeId)) {
      Hive.registerAdapter(RelationshipTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(CacheConfig.genderTypeId)) {
      Hive.registerAdapter(GenderAdapter());
    }
    if (!Hive.isAdapterRegistered(CacheConfig.avatarTypeTypeId)) {
      Hive.registerAdapter(AvatarTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(CacheConfig.interactionTypeTypeId)) {
      Hive.registerAdapter(InteractionTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(CacheConfig.reminderFrequencyTypeId)) {
      Hive.registerAdapter(ReminderFrequencyAdapter());
    }
    if (!Hive.isAdapterRegistered(CacheConfig.operationTypeTypeId)) {
      Hive.registerAdapter(OperationTypeAdapter());
    }
    debugPrint('[HiveInitializer] Enum adapters registered');
  }

  /// Register all model adapters.
  static void _registerModelAdapters() {
    if (!Hive.isAdapterRegistered(CacheConfig.relativeTypeId)) {
      Hive.registerAdapter(RelativeAdapter());
    }
    if (!Hive.isAdapterRegistered(CacheConfig.interactionTypeId)) {
      Hive.registerAdapter(InteractionAdapter());
    }
    if (!Hive.isAdapterRegistered(CacheConfig.reminderScheduleTypeId)) {
      Hive.registerAdapter(ReminderScheduleAdapter());
    }
    if (!Hive.isAdapterRegistered(CacheConfig.offlineOperationTypeId)) {
      Hive.registerAdapter(OfflineOperationAdapter());
    }
    if (!Hive.isAdapterRegistered(CacheConfig.syncMetadataTypeId)) {
      Hive.registerAdapter(SyncMetadataAdapter());
    }
    debugPrint('[HiveInitializer] Model adapters registered');
  }

  /// Open all Hive boxes with error recovery.
  static Future<void> _openBoxes() async {
    await _openBoxSafely<Relative>(CacheConfig.relativesBox);
    await _openBoxSafely<Interaction>(CacheConfig.interactionsBox);
    await _openBoxSafely<ReminderSchedule>(CacheConfig.reminderSchedulesBox);
    await _openBoxSafely<OfflineOperation>(CacheConfig.offlineQueueBox);
    await _openBoxSafely<SyncMetadata>(CacheConfig.syncMetadataBox);
    debugPrint('[HiveInitializer] All boxes opened');
  }

  /// Open a box safely with corruption recovery.
  static Future<Box<T>> _openBoxSafely<T>(String boxName) async {
    try {
      return await Hive.openBox<T>(boxName);
    } catch (e) {
      debugPrint('[HiveInitializer] Error opening box "$boxName": $e');
      debugPrint('[HiveInitializer] Attempting recovery by deleting corrupt box...');

      try {
        await Hive.deleteBoxFromDisk(boxName);
        return await Hive.openBox<T>(boxName);
      } catch (deleteError) {
        debugPrint('[HiveInitializer] Failed to recover box "$boxName": $deleteError');
        rethrow;
      }
    }
  }

  /// Close all Hive boxes (call on app dispose if needed).
  static Future<void> close() async {
    await Hive.close();
    _initialized = false;
    debugPrint('[HiveInitializer] Hive closed');
  }

  /// Clear all cached data (useful for logout or reset).
  static Future<void> clearAll() async {
    final relativesBox = Hive.box<Relative>(CacheConfig.relativesBox);
    final interactionsBox = Hive.box<Interaction>(CacheConfig.interactionsBox);
    final schedulesBox = Hive.box<ReminderSchedule>(CacheConfig.reminderSchedulesBox);
    final queueBox = Hive.box<OfflineOperation>(CacheConfig.offlineQueueBox);
    final metadataBox = Hive.box<SyncMetadata>(CacheConfig.syncMetadataBox);

    await Future.wait([
      relativesBox.clear(),
      interactionsBox.clear(),
      schedulesBox.clear(),
      queueBox.clear(),
      metadataBox.clear(),
    ]);

    debugPrint('[HiveInitializer] All caches cleared');
  }

  /// Get a typed box (convenience getter).
  static Box<Relative> get relativesBox =>
      Hive.box<Relative>(CacheConfig.relativesBox);

  static Box<Interaction> get interactionsBox =>
      Hive.box<Interaction>(CacheConfig.interactionsBox);

  static Box<ReminderSchedule> get reminderSchedulesBox =>
      Hive.box<ReminderSchedule>(CacheConfig.reminderSchedulesBox);

  static Box<OfflineOperation> get offlineQueueBox =>
      Hive.box<OfflineOperation>(CacheConfig.offlineQueueBox);

  static Box<SyncMetadata> get syncMetadataBox =>
      Hive.box<SyncMetadata>(CacheConfig.syncMetadataBox);
}
