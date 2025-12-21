import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/shared/models/offline_operation.dart';
import 'package:silni_app/shared/models/sync_metadata.dart';
import 'package:silni_app/core/cache/cache_config.dart';

void main() {
  group('OfflineOperation', () {
    test('should create operation with default values', () {
      final operation = OfflineOperation(
        id: 1,
        type: OperationType.create,
        entityType: 'relative',
        entityId: 'rel-123',
        data: {'full_name': 'Test'},
        createdAt: DateTime.now(),
      );

      expect(operation.id, equals(1));
      expect(operation.type, equals(OperationType.create));
      expect(operation.entityType, equals('relative'));
      expect(operation.retryCount, equals(0));
      expect(operation.lastError, isNull);
      expect(operation.isDeadLetter, isFalse);
    });

    test('copyWithRetry should increment retry count', () {
      final operation = OfflineOperation(
        id: 1,
        type: OperationType.update,
        entityType: 'interaction',
        entityId: 'int-456',
        data: {},
        createdAt: DateTime.now(),
      );

      final retried = operation.copyWithRetry('Network error');

      expect(retried.retryCount, equals(1));
      expect(retried.lastError, equals('Network error'));
      expect(retried.isDeadLetter, isFalse);
    });

    test('copyWithRetry should accumulate retry count', () {
      var operation = OfflineOperation(
        id: 1,
        type: OperationType.delete,
        entityType: 'schedule',
        entityId: 'sch-789',
        data: {},
        createdAt: DateTime.now(),
      );

      operation = operation.copyWithRetry('Error 1');
      operation = operation.copyWithRetry('Error 2');
      operation = operation.copyWithRetry('Error 3');

      expect(operation.retryCount, equals(3));
      expect(operation.lastError, equals('Error 3'));
    });

    test('copyAsDeadLetter should mark as dead letter', () {
      final operation = OfflineOperation(
        id: 1,
        type: OperationType.create,
        entityType: 'relative',
        entityId: 'rel-123',
        data: {},
        createdAt: DateTime.now(),
        retryCount: 5,
        lastError: 'Final error',
      );

      final deadLetter = operation.copyAsDeadLetter();

      expect(deadLetter.isDeadLetter, isTrue);
      expect(deadLetter.retryCount, equals(5));
      expect(deadLetter.lastError, equals('Final error'));
    });

    test('toJson should return correct map', () {
      final now = DateTime.now();
      final operation = OfflineOperation(
        id: 42,
        type: OperationType.update,
        entityType: 'relative',
        entityId: 'rel-123',
        data: {'full_name': 'Updated Name'},
        createdAt: now,
        retryCount: 2,
        lastError: 'Test error',
        isDeadLetter: true,
      );

      final json = operation.toJson();

      expect(json['id'], equals(42));
      expect(json['type'], equals('update'));
      expect(json['entity_type'], equals('relative'));
      expect(json['entity_id'], equals('rel-123'));
      expect(json['retry_count'], equals(2));
      expect(json['last_error'], equals('Test error'));
      expect(json['is_dead_letter'], isTrue);
    });

    test('copyWith should preserve unmodified fields', () {
      final original = OfflineOperation(
        id: 1,
        type: OperationType.create,
        entityType: 'relative',
        entityId: 'rel-123',
        data: {'key': 'value'},
        createdAt: DateTime(2024, 1, 1),
        retryCount: 3,
        lastError: 'error',
        isDeadLetter: true,
      );

      final modified = original.copyWith(retryCount: 5);

      expect(modified.id, equals(original.id));
      expect(modified.type, equals(original.type));
      expect(modified.entityType, equals(original.entityType));
      expect(modified.entityId, equals(original.entityId));
      expect(modified.retryCount, equals(5)); // Modified
      expect(modified.lastError, equals(original.lastError));
      expect(modified.isDeadLetter, equals(original.isDeadLetter));
    });
  });

  group('SyncMetadata', () {
    test('should create metadata with default values', () {
      final metadata = SyncMetadata(
        key: 'lastSync_relatives',
        lastSync: DateTime.now(),
      );

      expect(metadata.key, equals('lastSync_relatives'));
      expect(metadata.itemCount, equals(0));
      expect(metadata.lastError, isNull);
    });

    test('isStale should return true when threshold exceeded', () {
      final oldSync = SyncMetadata(
        key: 'test',
        lastSync: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      expect(oldSync.isStale(const Duration(minutes: 5)), isTrue);
      expect(oldSync.isStale(const Duration(minutes: 15)), isFalse);
    });

    test('isStale should return false for recent sync', () {
      final recentSync = SyncMetadata(
        key: 'test',
        lastSync: DateTime.now().subtract(const Duration(minutes: 2)),
      );

      expect(recentSync.isStale(CacheConfig.staleCacheThreshold), isFalse);
    });

    test('copyWith should update fields correctly', () {
      final original = SyncMetadata(
        key: 'original',
        lastSync: DateTime(2024, 1, 1),
        itemCount: 10,
      );

      final updated = original.copyWith(
        itemCount: 20,
        lastError: 'new error',
      );

      expect(updated.key, equals(original.key));
      expect(updated.lastSync, equals(original.lastSync));
      expect(updated.itemCount, equals(20));
      expect(updated.lastError, equals('new error'));
    });

    test('toJson should return correct map', () {
      final now = DateTime(2024, 6, 15, 10, 30);
      final metadata = SyncMetadata(
        key: 'test_key',
        lastSync: now,
        itemCount: 42,
        lastError: 'test error',
      );

      final json = metadata.toJson();

      expect(json['key'], equals('test_key'));
      expect(json['item_count'], equals(42));
      expect(json['last_error'], equals('test error'));
    });
  });

  group('OperationType', () {
    test('should have correct values', () {
      expect(OperationType.values.length, equals(3));
      expect(OperationType.values.contains(OperationType.create), isTrue);
      expect(OperationType.values.contains(OperationType.update), isTrue);
      expect(OperationType.values.contains(OperationType.delete), isTrue);
    });

    test('should have correct indices', () {
      expect(OperationType.create.index, equals(0));
      expect(OperationType.update.index, equals(1));
      expect(OperationType.delete.index, equals(2));
    });
  });

  group('CacheConfig', () {
    test('should have correct box names', () {
      expect(CacheConfig.relativesBox, equals('relatives'));
      expect(CacheConfig.interactionsBox, equals('interactions'));
      expect(CacheConfig.reminderSchedulesBox, equals('reminder_schedules'));
      expect(CacheConfig.offlineQueueBox, equals('offline_queue'));
      expect(CacheConfig.syncMetadataBox, equals('sync_metadata'));
    });

    test('should have correct type IDs', () {
      // Core models: 0-9
      expect(CacheConfig.relativeTypeId, equals(0));
      expect(CacheConfig.interactionTypeId, equals(1));
      expect(CacheConfig.reminderScheduleTypeId, equals(2));

      // Enums: 10-19
      expect(CacheConfig.relationshipTypeTypeId, equals(10));
      expect(CacheConfig.genderTypeId, equals(11));
      expect(CacheConfig.avatarTypeTypeId, equals(12));
      expect(CacheConfig.interactionTypeTypeId, equals(13));
      expect(CacheConfig.reminderFrequencyTypeId, equals(14));
      expect(CacheConfig.operationTypeTypeId, equals(15));

      // Cache models: 20-29
      expect(CacheConfig.offlineOperationTypeId, equals(20));
      expect(CacheConfig.syncMetadataTypeId, equals(21));
    });

    test('should have reasonable cache settings', () {
      expect(CacheConfig.maxInteractionsPerRelative, equals(100));
      expect(CacheConfig.staleCacheThreshold, equals(const Duration(minutes: 5)));
      expect(CacheConfig.maxRetryAttempts, equals(5));
    });

    test('lastSyncInteractionsKey should format correctly', () {
      expect(
        CacheConfig.lastSyncInteractionsKey('rel-123'),
        equals('lastSync_interactions_rel-123'),
      );
    });
  });
}
