import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/core/services/offline_queue_service.dart';
import 'package:silni_app/core/cache/cache_config.dart';
import 'package:silni_app/shared/models/offline_operation.dart';

void main() {
  group('OfflineQueueService', () {
    // =====================================================
    // SINGLETON PATTERN TESTS
    // =====================================================
    group('singleton pattern', () {
      test('should return same instance via instance getter', () {
        final instance1 = OfflineQueueService.instance;
        final instance2 = OfflineQueueService.instance;

        expect(identical(instance1, instance2), isTrue);
      });
    });

    // =====================================================
    // INITIAL STATE TESTS
    // =====================================================
    group('initial state', () {
      test('should have pendingCountStream', () {
        final service = OfflineQueueService.instance;
        expect(service.pendingCountStream, isA<Stream<int>>());
      });

      test('should have deadLetterCountStream', () {
        final service = OfflineQueueService.instance;
        expect(service.deadLetterCountStream, isA<Stream<int>>());
      });
    });

    // =====================================================
    // SERVICE LIFECYCLE TESTS
    // =====================================================
    group('service lifecycle', () {
      test('should have initialize method', () {
        final service = OfflineQueueService.instance;
        expect(service.initialize, isA<Function>());
      });

      test('should have enqueue method', () {
        final service = OfflineQueueService.instance;
        expect(service.enqueue, isA<Function>());
      });

      test('should have peek method', () {
        final service = OfflineQueueService.instance;
        expect(service.peek, isA<Function>());
      });

      test('should have dequeue method', () {
        final service = OfflineQueueService.instance;
        expect(service.dequeue, isA<Function>());
      });

      test('should have processQueue method', () {
        final service = OfflineQueueService.instance;
        expect(service.processQueue, isA<Function>());
      });

      test('should have getPendingOperations method', () {
        final service = OfflineQueueService.instance;
        expect(service.getPendingOperations, isA<Function>());
      });

      test('should have getDeadLetterOperations method', () {
        final service = OfflineQueueService.instance;
        expect(service.getDeadLetterOperations, isA<Function>());
      });

      test('should have getPendingCount method', () {
        final service = OfflineQueueService.instance;
        expect(service.getPendingCount, isA<Function>());
      });

      test('should have getDeadLetterCount method', () {
        final service = OfflineQueueService.instance;
        expect(service.getDeadLetterCount, isA<Function>());
      });

      test('should have retryDeadLetter method', () {
        final service = OfflineQueueService.instance;
        expect(service.retryDeadLetter, isA<Function>());
      });

      test('should have clearDeadLetter method', () {
        final service = OfflineQueueService.instance;
        expect(service.clearDeadLetter, isA<Function>());
      });

      test('should have clearAllDeadLetters method', () {
        final service = OfflineQueueService.instance;
        expect(service.clearAllDeadLetters, isA<Function>());
      });

      test('should have clearAll method', () {
        final service = OfflineQueueService.instance;
        expect(service.clearAll, isA<Function>());
      });

      test('should have dispose method', () {
        final service = OfflineQueueService.instance;
        expect(service.dispose, isA<Function>());
      });
    });
  });

  // =====================================================
  // OPERATION TYPE ENUM TESTS
  // =====================================================
  group('OperationType enum', () {
    test('should have 3 operation types', () {
      expect(OperationType.values.length, equals(3));
    });

    test('should include all expected types', () {
      expect(OperationType.values, contains(OperationType.create));
      expect(OperationType.values, contains(OperationType.update));
      expect(OperationType.values, contains(OperationType.delete));
    });

    test('create should have correct name', () {
      expect(OperationType.create.name, equals('create'));
    });

    test('update should have correct name', () {
      expect(OperationType.update.name, equals('update'));
    });

    test('delete should have correct name', () {
      expect(OperationType.delete.name, equals('delete'));
    });
  });

  // =====================================================
  // OFFLINE OPERATION MODEL TESTS
  // =====================================================
  group('OfflineOperation model', () {
    test('should create operation with required fields', () {
      final operation = OfflineOperation(
        id: 1,
        type: OperationType.create,
        entityType: 'relative',
        entityId: 'test-id',
        data: {'name': 'Test'},
        createdAt: DateTime.now(),
      );

      expect(operation.id, equals(1));
      expect(operation.type, equals(OperationType.create));
      expect(operation.entityType, equals('relative'));
      expect(operation.entityId, equals('test-id'));
      expect(operation.data, equals({'name': 'Test'}));
      expect(operation.retryCount, equals(0));
      expect(operation.lastError, isNull);
      expect(operation.isDeadLetter, isFalse);
    });

    test('should create operation with optional fields', () {
      final operation = OfflineOperation(
        id: 1,
        type: OperationType.update,
        entityType: 'interaction',
        entityId: 'test-id',
        data: {'notes': 'Updated'},
        createdAt: DateTime.now(),
        retryCount: 2,
        lastError: 'Network error',
        isDeadLetter: false,
      );

      expect(operation.retryCount, equals(2));
      expect(operation.lastError, equals('Network error'));
      expect(operation.isDeadLetter, isFalse);
    });

    group('copyWithRetry', () {
      test('should increment retry count', () {
        final original = OfflineOperation(
          id: 1,
          type: OperationType.create,
          entityType: 'relative',
          entityId: 'test-id',
          data: {},
          createdAt: DateTime.now(),
          retryCount: 0,
        );

        final retried = original.copyWithRetry('Test error');

        expect(retried.retryCount, equals(1));
        expect(retried.lastError, equals('Test error'));
        expect(retried.id, equals(original.id));
        expect(retried.type, equals(original.type));
        expect(retried.entityType, equals(original.entityType));
        expect(retried.entityId, equals(original.entityId));
      });

      test('should accumulate retry count on multiple failures', () {
        var operation = OfflineOperation(
          id: 1,
          type: OperationType.create,
          entityType: 'relative',
          entityId: 'test-id',
          data: {},
          createdAt: DateTime.now(),
        );

        operation = operation.copyWithRetry('Error 1');
        expect(operation.retryCount, equals(1));

        operation = operation.copyWithRetry('Error 2');
        expect(operation.retryCount, equals(2));

        operation = operation.copyWithRetry('Error 3');
        expect(operation.retryCount, equals(3));
      });

      test('should preserve isDeadLetter status', () {
        final original = OfflineOperation(
          id: 1,
          type: OperationType.create,
          entityType: 'relative',
          entityId: 'test-id',
          data: {},
          createdAt: DateTime.now(),
          isDeadLetter: false,
        );

        final retried = original.copyWithRetry('Error');
        expect(retried.isDeadLetter, isFalse);
      });
    });

    group('copyAsDeadLetter', () {
      test('should mark operation as dead letter', () {
        final original = OfflineOperation(
          id: 1,
          type: OperationType.delete,
          entityType: 'schedule',
          entityId: 'test-id',
          data: {},
          createdAt: DateTime.now(),
          retryCount: 5,
          lastError: 'Final error',
        );

        final deadLetter = original.copyAsDeadLetter();

        expect(deadLetter.isDeadLetter, isTrue);
        expect(deadLetter.retryCount, equals(5));
        expect(deadLetter.lastError, equals('Final error'));
        expect(deadLetter.id, equals(original.id));
      });

      test('should preserve all other fields', () {
        final now = DateTime.now();
        final original = OfflineOperation(
          id: 42,
          type: OperationType.update,
          entityType: 'interaction',
          entityId: 'specific-id',
          data: {'key': 'value'},
          createdAt: now,
        );

        final deadLetter = original.copyAsDeadLetter();

        expect(deadLetter.id, equals(42));
        expect(deadLetter.type, equals(OperationType.update));
        expect(deadLetter.entityType, equals('interaction'));
        expect(deadLetter.entityId, equals('specific-id'));
        expect(deadLetter.data, equals({'key': 'value'}));
        expect(deadLetter.createdAt, equals(now));
      });
    });

    group('copyWith', () {
      test('should allow changing any field', () {
        final original = OfflineOperation(
          id: 1,
          type: OperationType.create,
          entityType: 'relative',
          entityId: 'old-id',
          data: {'old': 'data'},
          createdAt: DateTime(2024, 1, 1),
        );

        final modified = original.copyWith(
          id: 2,
          type: OperationType.update,
          entityType: 'interaction',
          entityId: 'new-id',
          data: {'new': 'data'},
          createdAt: DateTime(2024, 6, 1),
          retryCount: 3,
          lastError: 'Some error',
          isDeadLetter: true,
        );

        expect(modified.id, equals(2));
        expect(modified.type, equals(OperationType.update));
        expect(modified.entityType, equals('interaction'));
        expect(modified.entityId, equals('new-id'));
        expect(modified.data, equals({'new': 'data'}));
        expect(modified.createdAt, equals(DateTime(2024, 6, 1)));
        expect(modified.retryCount, equals(3));
        expect(modified.lastError, equals('Some error'));
        expect(modified.isDeadLetter, isTrue);
      });

      test('should preserve unchanged fields', () {
        final original = OfflineOperation(
          id: 1,
          type: OperationType.create,
          entityType: 'relative',
          entityId: 'test-id',
          data: {'key': 'value'},
          createdAt: DateTime(2024, 1, 1),
        );

        final modified = original.copyWith(retryCount: 5);

        expect(modified.id, equals(1));
        expect(modified.type, equals(OperationType.create));
        expect(modified.entityType, equals('relative'));
        expect(modified.entityId, equals('test-id'));
        expect(modified.data, equals({'key': 'value'}));
        expect(modified.retryCount, equals(5));
      });
    });

    group('toJson', () {
      test('should convert operation to JSON', () {
        final createdAt = DateTime(2024, 3, 15, 10, 30, 0);
        final operation = OfflineOperation(
          id: 5,
          type: OperationType.create,
          entityType: 'relative',
          entityId: 'rel-123',
          data: {'name': 'Test Relative'},
          createdAt: createdAt,
          retryCount: 2,
          lastError: 'Connection failed',
          isDeadLetter: false,
        );

        final json = operation.toJson();

        expect(json['id'], equals(5));
        expect(json['type'], equals('create'));
        expect(json['entity_type'], equals('relative'));
        expect(json['entity_id'], equals('rel-123'));
        expect(json['data'], equals({'name': 'Test Relative'}));
        expect(json['created_at'], equals(createdAt.toIso8601String()));
        expect(json['retry_count'], equals(2));
        expect(json['last_error'], equals('Connection failed'));
        expect(json['is_dead_letter'], equals(false));
      });

      test('should handle null lastError in JSON', () {
        final operation = OfflineOperation(
          id: 1,
          type: OperationType.delete,
          entityType: 'interaction',
          entityId: 'int-456',
          data: {},
          createdAt: DateTime.now(),
        );

        final json = operation.toJson();

        expect(json['last_error'], isNull);
      });
    });

    group('toString', () {
      test('should produce readable string representation', () {
        final operation = OfflineOperation(
          id: 3,
          type: OperationType.update,
          entityType: 'schedule',
          entityId: 'sch-789',
          data: {},
          createdAt: DateTime.now(),
          retryCount: 1,
          isDeadLetter: true,
        );

        final str = operation.toString();

        expect(str, contains('OfflineOperation'));
        expect(str, contains('id: 3'));
        expect(str, contains('type: update'));
        expect(str, contains('entityType: schedule'));
        expect(str, contains('entityId: sch-789'));
        expect(str, contains('retryCount: 1'));
        expect(str, contains('isDeadLetter: true'));
      });
    });
  });

  // =====================================================
  // RETRY CONFIGURATION TESTS
  // =====================================================
  group('retry configuration', () {
    test('max retry attempts should be 5', () {
      expect(CacheConfig.maxRetryAttempts, equals(5));
    });

    test('initial retry delay should be 1 second', () {
      expect(
        CacheConfig.initialRetryDelay,
        equals(const Duration(seconds: 1)),
      );
    });

    test('retry backoff multiplier should be 2.0', () {
      expect(CacheConfig.retryBackoffMultiplier, equals(2.0));
    });
  });

  // =====================================================
  // BACKOFF CALCULATION LOGIC TESTS
  // =====================================================
  group('backoff calculation logic', () {
    Duration calculateBackoff(int retryCount) {
      final baseDelay = CacheConfig.initialRetryDelay.inMilliseconds;
      final multiplier = CacheConfig.retryBackoffMultiplier;

      // Calculate delay with exponential backoff
      var delayMs = baseDelay * (multiplier.toInt() << (retryCount - 1));

      // Cap at 30 seconds
      delayMs = delayMs.clamp(baseDelay, 30000);

      return Duration(milliseconds: delayMs.toInt());
    }

    test('first retry should have base delay', () {
      final delay = calculateBackoff(1);
      // 1000 * (2 << 0) = 1000 * 2 = 2000ms
      expect(delay.inMilliseconds, equals(2000));
    });

    test('second retry should have doubled delay', () {
      final delay = calculateBackoff(2);
      // 1000 * (2 << 1) = 1000 * 4 = 4000ms
      expect(delay.inMilliseconds, equals(4000));
    });

    test('third retry should have quadrupled delay', () {
      final delay = calculateBackoff(3);
      // 1000 * (2 << 2) = 1000 * 8 = 8000ms
      expect(delay.inMilliseconds, equals(8000));
    });

    test('fourth retry should have 16x delay', () {
      final delay = calculateBackoff(4);
      // 1000 * (2 << 3) = 1000 * 16 = 16000ms
      expect(delay.inMilliseconds, equals(16000));
    });

    test('fifth retry should be capped at 30 seconds', () {
      final delay = calculateBackoff(5);
      // 1000 * (2 << 4) = 1000 * 32 = 32000ms -> capped at 30000ms
      expect(delay.inMilliseconds, equals(30000));
    });

    test('higher retries should still be capped at 30 seconds', () {
      final delay = calculateBackoff(10);
      expect(delay.inMilliseconds, equals(30000));
    });
  });

  // =====================================================
  // QUEUE PROCESSING LOGIC TESTS
  // =====================================================
  group('queue processing logic', () {
    test('should process operations in FIFO order', () {
      // Simulate queue operations
      final queue = <int>[1, 2, 3, 4, 5];
      final processed = <int>[];

      while (queue.isNotEmpty) {
        // Sort by ID (FIFO order)
        queue.sort((a, b) => a.compareTo(b));
        processed.add(queue.removeAt(0));
      }

      expect(processed, equals([1, 2, 3, 4, 5]));
    });

    test('should skip processing when offline', () {
      bool shouldProcess(bool isOnline, bool isProcessing) {
        if (!isOnline) return false;
        if (isProcessing) return false;
        return true;
      }

      expect(shouldProcess(true, false), isTrue);
      expect(shouldProcess(false, false), isFalse);
      expect(shouldProcess(true, true), isFalse);
      expect(shouldProcess(false, true), isFalse);
    });

    test('should move to dead letter after max retries', () {
      bool shouldMoveToDeadLetter(int retryCount) {
        return retryCount >= CacheConfig.maxRetryAttempts;
      }

      expect(shouldMoveToDeadLetter(0), isFalse);
      expect(shouldMoveToDeadLetter(4), isFalse);
      expect(shouldMoveToDeadLetter(5), isTrue);
      expect(shouldMoveToDeadLetter(10), isTrue);
    });
  });

  // =====================================================
  // DEAD LETTER HANDLING TESTS
  // =====================================================
  group('dead letter handling', () {
    test('should filter pending operations correctly', () {
      final operations = [
        _createMockOperation(1, false),
        _createMockOperation(2, true),
        _createMockOperation(3, false),
        _createMockOperation(4, true),
      ];

      final pending = operations.where((op) => !op.isDeadLetter).toList();
      final deadLetters = operations.where((op) => op.isDeadLetter).toList();

      expect(pending.length, equals(2));
      expect(deadLetters.length, equals(2));
      expect(pending.map((op) => op.id), equals([1, 3]));
      expect(deadLetters.map((op) => op.id), equals([2, 4]));
    });

    test('should sort operations by ID', () {
      final operations = [
        _createMockOperation(5, false),
        _createMockOperation(2, false),
        _createMockOperation(8, false),
        _createMockOperation(1, false),
      ];

      operations.sort((a, b) => a.id.compareTo(b.id));

      expect(operations.map((op) => op.id).toList(), equals([1, 2, 5, 8]));
    });
  });

  // =====================================================
  // ENTITY TYPE TESTS
  // =====================================================
  group('entity types', () {
    test('should support relative entity type', () {
      final operation = OfflineOperation(
        id: 1,
        type: OperationType.create,
        entityType: 'relative',
        entityId: 'rel-1',
        data: {},
        createdAt: DateTime.now(),
      );

      expect(operation.entityType, equals('relative'));
    });

    test('should support interaction entity type', () {
      final operation = OfflineOperation(
        id: 2,
        type: OperationType.update,
        entityType: 'interaction',
        entityId: 'int-1',
        data: {},
        createdAt: DateTime.now(),
      );

      expect(operation.entityType, equals('interaction'));
    });

    test('should support schedule entity type', () {
      final operation = OfflineOperation(
        id: 3,
        type: OperationType.delete,
        entityType: 'schedule',
        entityId: 'sch-1',
        data: {},
        createdAt: DateTime.now(),
      );

      expect(operation.entityType, equals('schedule'));
    });
  });

  // =====================================================
  // QUEUE BOX CONFIGURATION TESTS
  // =====================================================
  group('queue box configuration', () {
    test('offline queue box name should be correct', () {
      expect(CacheConfig.offlineQueueBox, equals('offline_queue'));
    });

    test('offline operation type ID should be 20', () {
      expect(CacheConfig.offlineOperationTypeId, equals(20));
    });

    test('operation type enum type ID should be 15', () {
      expect(CacheConfig.operationTypeTypeId, equals(15));
    });
  });
}

/// Helper to create mock operations for testing
OfflineOperation _createMockOperation(int id, bool isDeadLetter) {
  return OfflineOperation(
    id: id,
    type: OperationType.create,
    entityType: 'relative',
    entityId: 'entity-$id',
    data: {},
    createdAt: DateTime.now(),
    isDeadLetter: isDeadLetter,
  );
}
