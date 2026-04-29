import 'package:hive_flutter/hive_flutter.dart';

import '../../shared/models/offline_operation.dart';
import '../../shared/models/sync_metadata.dart';

import 'adapters/enum_adapters.dart';
import 'adapters/offline_operation_adapter.dart';
import 'adapters/sync_metadata_adapter.dart';
import 'cache_config.dart';

/// Initializes Hive for the offline write queue + sync metadata.
///
/// Phase 9.X.D.B Tier 2: read-cache boxes (relatives, interactions, reminder
/// schedules) and their model adapters were removed. Reads now stream straight
/// from Supabase realtime — single source of truth, no stale-data bugs.
///
/// What stays:
///   - `offlineQueueBox` — pending writes when offline. Replayed on reconnect.
///     Survives app kill (durability layer the user actually relies on).
///   - `syncMetadataBox` — last-sync timestamps the queue replayer consults.
///
/// Init is now deferred from `main()` phase1 to `_initDeferredServices`
/// (post-runApp), saving ~770ms of cold-start preamble.
class HiveInitializer {
  HiveInitializer._();

  static bool _initialized = false;

  /// Initialize Hive and register the kept adapters.
  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await Hive.initFlutter();
    _registerAdapters();
    await _openBoxes();

    _initialized = true;
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(CacheConfig.operationTypeTypeId)) {
      Hive.registerAdapter(OperationTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(CacheConfig.offlineOperationTypeId)) {
      Hive.registerAdapter(OfflineOperationAdapter());
    }
    if (!Hive.isAdapterRegistered(CacheConfig.syncMetadataTypeId)) {
      Hive.registerAdapter(SyncMetadataAdapter());
    }
  }

  static Future<void> _openBoxes() async {
    await _openBoxSafely<OfflineOperation>(CacheConfig.offlineQueueBox);
    await _openBoxSafely<SyncMetadata>(CacheConfig.syncMetadataBox);
  }

  /// Open a box safely with corruption recovery.
  static Future<Box<T>> _openBoxSafely<T>(String boxName) async {
    try {
      return await Hive.openBox<T>(boxName);
    } catch (e) {
      try {
        await Hive.deleteBoxFromDisk(boxName);
        return await Hive.openBox<T>(boxName);
      } catch (deleteError) {
        rethrow;
      }
    }
  }

  /// Close all Hive boxes (call on app dispose if needed).
  static Future<void> close() async {
    await Hive.close();
    _initialized = false;
  }

  /// Clear all kept boxes (useful for logout or reset).
  static Future<void> clearAll() async {
    final queueBox = Hive.box<OfflineOperation>(CacheConfig.offlineQueueBox);
    final metadataBox = Hive.box<SyncMetadata>(CacheConfig.syncMetadataBox);

    await Future.wait([
      queueBox.clear(),
      metadataBox.clear(),
    ]);
  }

  /// Get a typed box (convenience getter).
  static Box<OfflineOperation> get offlineQueueBox =>
      Hive.box<OfflineOperation>(CacheConfig.offlineQueueBox);

  static Box<SyncMetadata> get syncMetadataBox =>
      Hive.box<SyncMetadata>(CacheConfig.syncMetadataBox);
}
