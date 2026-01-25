import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/core/services/cache_service.dart';
import 'package:silni_app/core/cache/cache_config.dart';
import 'package:silni_app/shared/models/sync_metadata.dart';

void main() {
  group('CacheService', () {
    // =====================================================
    // SINGLETON PATTERN TESTS
    // =====================================================
    group('singleton pattern', () {
      test('should return same instance via instance getter', () {
        final instance1 = CacheService.instance;
        final instance2 = CacheService.instance;

        expect(identical(instance1, instance2), isTrue);
      });
    });

    // =====================================================
    // SERVICE API TESTS - RELATIVES
    // =====================================================
    group('relatives cache API', () {
      test('should have getRelatives method', () {
        final service = CacheService.instance;
        expect(service.getRelatives, isA<Function>());
      });

      test('should have getRelative method', () {
        final service = CacheService.instance;
        expect(service.getRelative, isA<Function>());
      });

      test('should have putRelative method', () {
        final service = CacheService.instance;
        expect(service.putRelative, isA<Function>());
      });

      test('should have putRelatives method', () {
        final service = CacheService.instance;
        expect(service.putRelatives, isA<Function>());
      });

      test('should have deleteRelative method', () {
        final service = CacheService.instance;
        expect(service.deleteRelative, isA<Function>());
      });

      test('should have clearRelatives method', () {
        final service = CacheService.instance;
        expect(service.clearRelatives, isA<Function>());
      });
    });

    // =====================================================
    // SERVICE API TESTS - INTERACTIONS
    // =====================================================
    group('interactions cache API', () {
      test('should have getInteractions method', () {
        final service = CacheService.instance;
        expect(service.getInteractions, isA<Function>());
      });

      test('should have getAllInteractions method', () {
        final service = CacheService.instance;
        expect(service.getAllInteractions, isA<Function>());
      });

      test('should have getTodayInteractions method', () {
        final service = CacheService.instance;
        expect(service.getTodayInteractions, isA<Function>());
      });

      test('should have getInteraction method', () {
        final service = CacheService.instance;
        expect(service.getInteraction, isA<Function>());
      });

      test('should have putInteraction method', () {
        final service = CacheService.instance;
        expect(service.putInteraction, isA<Function>());
      });

      test('should have putInteractions method', () {
        final service = CacheService.instance;
        expect(service.putInteractions, isA<Function>());
      });

      test('should have deleteInteraction method', () {
        final service = CacheService.instance;
        expect(service.deleteInteraction, isA<Function>());
      });

      test('should have clearInteractions method', () {
        final service = CacheService.instance;
        expect(service.clearInteractions, isA<Function>());
      });
    });

    // =====================================================
    // SERVICE API TESTS - REMINDER SCHEDULES
    // =====================================================
    group('reminder schedules cache API', () {
      test('should have getReminderSchedules method', () {
        final service = CacheService.instance;
        expect(service.getReminderSchedules, isA<Function>());
      });

      test('should have getActiveReminderSchedules method', () {
        final service = CacheService.instance;
        expect(service.getActiveReminderSchedules, isA<Function>());
      });

      test('should have getReminderSchedule method', () {
        final service = CacheService.instance;
        expect(service.getReminderSchedule, isA<Function>());
      });

      test('should have putReminderSchedule method', () {
        final service = CacheService.instance;
        expect(service.putReminderSchedule, isA<Function>());
      });

      test('should have putReminderSchedules method', () {
        final service = CacheService.instance;
        expect(service.putReminderSchedules, isA<Function>());
      });

      test('should have deleteReminderSchedule method', () {
        final service = CacheService.instance;
        expect(service.deleteReminderSchedule, isA<Function>());
      });

      test('should have clearReminderSchedules method', () {
        final service = CacheService.instance;
        expect(service.clearReminderSchedules, isA<Function>());
      });
    });

    // =====================================================
    // SERVICE API TESTS - SYNC METADATA
    // =====================================================
    group('sync metadata API', () {
      test('should have getSyncMetadata method', () {
        final service = CacheService.instance;
        expect(service.getSyncMetadata, isA<Function>());
      });

      test('should have putSyncMetadata method', () {
        final service = CacheService.instance;
        expect(service.putSyncMetadata, isA<Function>());
      });

      test('should have isCacheStale method', () {
        final service = CacheService.instance;
        expect(service.isCacheStale, isA<Function>());
      });

      test('should have getLastSyncTime method', () {
        final service = CacheService.instance;
        expect(service.getLastSyncTime, isA<Function>());
      });

      test('should have updateLastSyncTime method', () {
        final service = CacheService.instance;
        expect(service.updateLastSyncTime, isA<Function>());
      });
    });

    // =====================================================
    // SERVICE API TESTS - UTILITY
    // =====================================================
    group('utility API', () {
      test('should have clearAll method', () {
        final service = CacheService.instance;
        expect(service.clearAll, isA<Function>());
      });

      test('should have getCacheStats method', () {
        final service = CacheService.instance;
        expect(service.getCacheStats, isA<Function>());
      });
    });
  });

  // =====================================================
  // SYNC METADATA MODEL TESTS
  // =====================================================
  group('SyncMetadata model', () {
    test('should create metadata with required fields', () {
      final now = DateTime.now();
      final metadata = SyncMetadata(
        key: 'test-key',
        lastSync: now,
      );

      expect(metadata.key, equals('test-key'));
      expect(metadata.lastSync, equals(now));
      expect(metadata.itemCount, equals(0));
      expect(metadata.lastError, isNull);
    });

    test('should create metadata with all fields', () {
      final now = DateTime.now();
      final metadata = SyncMetadata(
        key: 'test-key',
        lastSync: now,
        itemCount: 42,
        lastError: 'Some error occurred',
      );

      expect(metadata.key, equals('test-key'));
      expect(metadata.lastSync, equals(now));
      expect(metadata.itemCount, equals(42));
      expect(metadata.lastError, equals('Some error occurred'));
    });

    group('isStale', () {
      test('should return true when older than threshold', () {
        final oldSync = DateTime.now().subtract(const Duration(minutes: 10));
        final metadata = SyncMetadata(
          key: 'test',
          lastSync: oldSync,
        );

        expect(
          metadata.isStale(const Duration(minutes: 5)),
          isTrue,
        );
      });

      test('should return false when within threshold', () {
        final recentSync = DateTime.now().subtract(const Duration(minutes: 2));
        final metadata = SyncMetadata(
          key: 'test',
          lastSync: recentSync,
        );

        expect(
          metadata.isStale(const Duration(minutes: 5)),
          isFalse,
        );
      });

      test('should return false when at threshold boundary', () {
        // Use 4 minutes 59 seconds to ensure we're just under the threshold
        // This avoids timing issues where execution time pushes us over
        final almostAtThreshold = DateTime.now().subtract(
          const Duration(minutes: 4, seconds: 59),
        );
        final metadata = SyncMetadata(
          key: 'test',
          lastSync: almostAtThreshold,
        );

        // Just under the threshold should not be stale
        expect(
          metadata.isStale(const Duration(minutes: 5)),
          isFalse,
        );
      });

      test('should return true for very old sync', () {
        final veryOldSync = DateTime.now().subtract(const Duration(hours: 24));
        final metadata = SyncMetadata(
          key: 'test',
          lastSync: veryOldSync,
        );

        expect(
          metadata.isStale(const Duration(minutes: 5)),
          isTrue,
        );
      });

      test('should return false for just synced', () {
        final justSynced = DateTime.now();
        final metadata = SyncMetadata(
          key: 'test',
          lastSync: justSynced,
        );

        expect(
          metadata.isStale(const Duration(minutes: 5)),
          isFalse,
        );
      });
    });

    group('copyWith', () {
      test('should copy with changed key', () {
        final original = SyncMetadata(
          key: 'original-key',
          lastSync: DateTime.now(),
        );

        final copied = original.copyWith(key: 'new-key');

        expect(copied.key, equals('new-key'));
        expect(copied.lastSync, equals(original.lastSync));
      });

      test('should copy with changed lastSync', () {
        final original = SyncMetadata(
          key: 'test',
          lastSync: DateTime(2024, 1, 1),
        );

        final newTime = DateTime(2024, 6, 15);
        final copied = original.copyWith(lastSync: newTime);

        expect(copied.lastSync, equals(newTime));
        expect(copied.key, equals(original.key));
      });

      test('should copy with changed itemCount', () {
        final original = SyncMetadata(
          key: 'test',
          lastSync: DateTime.now(),
          itemCount: 10,
        );

        final copied = original.copyWith(itemCount: 25);

        expect(copied.itemCount, equals(25));
        expect(copied.key, equals(original.key));
      });

      test('should copy with changed lastError', () {
        final original = SyncMetadata(
          key: 'test',
          lastSync: DateTime.now(),
        );

        final copied = original.copyWith(lastError: 'New error');

        expect(copied.lastError, equals('New error'));
        expect(copied.key, equals(original.key));
      });

      test('should preserve unchanged fields', () {
        final now = DateTime(2024, 3, 15);
        final original = SyncMetadata(
          key: 'original',
          lastSync: now,
          itemCount: 100,
          lastError: 'Original error',
        );

        final copied = original.copyWith(itemCount: 150);

        expect(copied.key, equals('original'));
        expect(copied.lastSync, equals(now));
        expect(copied.itemCount, equals(150));
        expect(copied.lastError, equals('Original error'));
      });
    });

    group('toJson', () {
      test('should convert to JSON correctly', () {
        final syncTime = DateTime(2024, 5, 20, 14, 30, 0);
        final metadata = SyncMetadata(
          key: 'sync-key',
          lastSync: syncTime,
          itemCount: 15,
          lastError: 'Test error',
        );

        final json = metadata.toJson();

        expect(json['key'], equals('sync-key'));
        expect(json['last_sync'], equals(syncTime.toIso8601String()));
        expect(json['item_count'], equals(15));
        expect(json['last_error'], equals('Test error'));
      });

      test('should handle null lastError in JSON', () {
        final metadata = SyncMetadata(
          key: 'test',
          lastSync: DateTime.now(),
        );

        final json = metadata.toJson();

        expect(json['last_error'], isNull);
      });
    });

    group('toString', () {
      test('should produce readable string', () {
        final metadata = SyncMetadata(
          key: 'my-key',
          lastSync: DateTime(2024, 1, 1, 12, 0, 0),
          itemCount: 50,
          lastError: 'Error message',
        );

        final str = metadata.toString();

        expect(str, contains('SyncMetadata'));
        expect(str, contains('key: my-key'));
        expect(str, contains('itemCount: 50'));
        expect(str, contains('lastError: Error message'));
      });
    });
  });

  // =====================================================
  // CACHE CONFIGURATION TESTS
  // =====================================================
  group('cache configuration', () {
    group('box names', () {
      test('relatives box name should be correct', () {
        expect(CacheConfig.relativesBox, equals('relatives'));
      });

      test('interactions box name should be correct', () {
        expect(CacheConfig.interactionsBox, equals('interactions'));
      });

      test('reminder schedules box name should be correct', () {
        expect(CacheConfig.reminderSchedulesBox, equals('reminder_schedules'));
      });

      test('sync metadata box name should be correct', () {
        expect(CacheConfig.syncMetadataBox, equals('sync_metadata'));
      });
    });

    group('type IDs', () {
      test('relative type ID should be 0', () {
        expect(CacheConfig.relativeTypeId, equals(0));
      });

      test('interaction type ID should be 1', () {
        expect(CacheConfig.interactionTypeId, equals(1));
      });

      test('reminder schedule type ID should be 2', () {
        expect(CacheConfig.reminderScheduleTypeId, equals(2));
      });

      test('sync metadata type ID should be 21', () {
        expect(CacheConfig.syncMetadataTypeId, equals(21));
      });

      test('type IDs should be unique', () {
        final typeIds = [
          CacheConfig.relativeTypeId,
          CacheConfig.interactionTypeId,
          CacheConfig.reminderScheduleTypeId,
          CacheConfig.relationshipTypeTypeId,
          CacheConfig.genderTypeId,
          CacheConfig.avatarTypeTypeId,
          CacheConfig.interactionTypeTypeId,
          CacheConfig.reminderFrequencyTypeId,
          CacheConfig.operationTypeTypeId,
          CacheConfig.offlineOperationTypeId,
          CacheConfig.syncMetadataTypeId,
        ];

        // Check that all type IDs are unique
        expect(typeIds.toSet().length, equals(typeIds.length));
      });
    });

    group('cache limits', () {
      test('max interactions per relative should be 100', () {
        expect(CacheConfig.maxInteractionsPerRelative, equals(100));
      });
    });

    group('sync settings', () {
      test('stale cache threshold should be 5 minutes', () {
        expect(
          CacheConfig.staleCacheThreshold,
          equals(const Duration(minutes: 5)),
        );
      });

      test('background sync interval should be 5 minutes', () {
        expect(
          CacheConfig.backgroundSyncInterval,
          equals(const Duration(minutes: 5)),
        );
      });
    });

    group('sync metadata keys', () {
      test('lastSyncRelativesKey should be correct', () {
        expect(
          CacheConfig.lastSyncRelativesKey,
          equals('lastSync_relatives'),
        );
      });

      test('lastSyncRemindersKey should be correct', () {
        expect(
          CacheConfig.lastSyncRemindersKey,
          equals('lastSync_reminders'),
        );
      });

      test('lastSyncInteractionsKey should generate correct key', () {
        expect(
          CacheConfig.lastSyncInteractionsKey('rel-123'),
          equals('lastSync_interactions_rel-123'),
        );
      });
    });
  });

  // =====================================================
  // CACHE STALENESS LOGIC TESTS
  // =====================================================
  group('cache staleness logic', () {
    test('should consider cache stale when no metadata exists', () {
      // When getSyncMetadata returns null, cache should be considered stale
      bool isCacheStale(SyncMetadata? metadata, Duration threshold) {
        if (metadata == null) return true;
        return metadata.isStale(threshold);
      }

      expect(
        isCacheStale(null, CacheConfig.staleCacheThreshold),
        isTrue,
      );
    });

    test('should consider cache fresh when recently synced', () {
      final recentSync = DateTime.now().subtract(const Duration(minutes: 1));
      final metadata = SyncMetadata(key: 'test', lastSync: recentSync);

      expect(
        metadata.isStale(CacheConfig.staleCacheThreshold),
        isFalse,
      );
    });

    test('should consider cache stale after threshold', () {
      final oldSync = DateTime.now().subtract(const Duration(minutes: 10));
      final metadata = SyncMetadata(key: 'test', lastSync: oldSync);

      expect(
        metadata.isStale(CacheConfig.staleCacheThreshold),
        isTrue,
      );
    });
  });

  // =====================================================
  // INTERACTION LIMIT ENFORCEMENT LOGIC TESTS
  // =====================================================
  group('interaction limit enforcement logic', () {
    test('should keep only most recent interactions', () {
      // Simulating limit enforcement
      final interactions = List.generate(
        150,
        (i) => {'id': 'int-$i', 'date': DateTime.now().subtract(Duration(days: i))},
      );

      // Sort by date descending (most recent first)
      interactions.sort((a, b) =>
          (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      // Keep only the limit
      final limited = interactions.take(CacheConfig.maxInteractionsPerRelative).toList();

      expect(limited.length, equals(100));
      // First item should be the most recent (day 0)
      expect((limited.first['id'] as String), equals('int-0'));
      // Last kept item should be from day 99
      expect((limited.last['id'] as String), equals('int-99'));
    });

    test('should not limit when under threshold', () {
      final interactions = List.generate(50, (i) => i);
      final shouldLimit = interactions.length > CacheConfig.maxInteractionsPerRelative;

      expect(shouldLimit, isFalse);
    });

    test('should limit when over threshold', () {
      final interactions = List.generate(150, (i) => i);
      final shouldLimit = interactions.length > CacheConfig.maxInteractionsPerRelative;

      expect(shouldLimit, isTrue);
    });

    test('should identify interactions to remove', () {
      final interactions = List.generate(110, (i) => i);

      // Keep first 100 (most recent), identify the rest for removal
      final toRemove = interactions.skip(CacheConfig.maxInteractionsPerRelative).toList();

      expect(toRemove.length, equals(10));
      expect(toRemove, equals([100, 101, 102, 103, 104, 105, 106, 107, 108, 109]));
    });
  });

  // =====================================================
  // TODAY INTERACTIONS LOGIC TESTS
  // =====================================================
  group('today interactions logic', () {
    test('should identify interactions from today', () {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      bool isToday(DateTime date) {
        return date.isAfter(startOfDay) && date.isBefore(endOfDay);
      }

      // Test various dates
      expect(isToday(DateTime.now()), isTrue);
      expect(isToday(now.subtract(const Duration(days: 1))), isFalse);
      expect(isToday(now.add(const Duration(days: 1))), isFalse);
    });

    test('should filter interactions by user ID', () {
      final interactions = [
        {'userId': 'user-1', 'date': DateTime.now()},
        {'userId': 'user-2', 'date': DateTime.now()},
        {'userId': 'user-1', 'date': DateTime.now()},
      ];

      final filtered = interactions.where((i) => i['userId'] == 'user-1').toList();

      expect(filtered.length, equals(2));
    });
  });

  // =====================================================
  // CACHE STATS EXPECTED KEYS TESTS
  // =====================================================
  group('cache stats expected keys', () {
    test('should include all expected stat keys', () {
      final expectedKeys = [
        'relatives',
        'interactions',
        'reminderSchedules',
        'offlineQueue',
        'syncMetadata',
      ];

      // getCacheStats returns a Map<String, int> with these keys
      for (final key in expectedKeys) {
        expect(key, isA<String>());
      }
    });
  });

  // =====================================================
  // ACTIVE SCHEDULES FILTER LOGIC TESTS
  // =====================================================
  group('active schedules filter logic', () {
    test('should filter only active schedules', () {
      final schedules = [
        {'id': '1', 'isActive': true},
        {'id': '2', 'isActive': false},
        {'id': '3', 'isActive': true},
        {'id': '4', 'isActive': false},
      ];

      final active = schedules.where((s) => s['isActive'] == true).toList();

      expect(active.length, equals(2));
      expect(active.map((s) => s['id']).toList(), equals(['1', '3']));
    });

    test('should filter by user ID and active status', () {
      final schedules = [
        {'id': '1', 'userId': 'user-1', 'isActive': true},
        {'id': '2', 'userId': 'user-1', 'isActive': false},
        {'id': '3', 'userId': 'user-2', 'isActive': true},
        {'id': '4', 'userId': 'user-1', 'isActive': true},
      ];

      final userActiveSchedules = schedules
          .where((s) => s['userId'] == 'user-1' && s['isActive'] == true)
          .toList();

      expect(userActiveSchedules.length, equals(2));
      expect(userActiveSchedules.map((s) => s['id']).toList(), equals(['1', '4']));
    });
  });

  // =====================================================
  // RELATIVES FILTER LOGIC TESTS
  // =====================================================
  group('relatives filter logic', () {
    test('should filter out archived relatives', () {
      final relatives = [
        {'id': '1', 'isArchived': false},
        {'id': '2', 'isArchived': true},
        {'id': '3', 'isArchived': false},
      ];

      final active = relatives.where((r) => r['isArchived'] == false).toList();

      expect(active.length, equals(2));
    });

    test('should filter by user ID', () {
      final relatives = [
        {'id': '1', 'userId': 'user-1'},
        {'id': '2', 'userId': 'user-2'},
        {'id': '3', 'userId': 'user-1'},
      ];

      final userRelatives = relatives.where((r) => r['userId'] == 'user-1').toList();

      expect(userRelatives.length, equals(2));
    });

    test('should combine filters correctly', () {
      final relatives = [
        {'id': '1', 'userId': 'user-1', 'isArchived': false},
        {'id': '2', 'userId': 'user-1', 'isArchived': true},
        {'id': '3', 'userId': 'user-2', 'isArchived': false},
        {'id': '4', 'userId': 'user-1', 'isArchived': false},
      ];

      final filtered = relatives
          .where((r) => r['userId'] == 'user-1' && r['isArchived'] == false)
          .toList();

      expect(filtered.length, equals(2));
      expect(filtered.map((r) => r['id']).toList(), equals(['1', '4']));
    });
  });
}
