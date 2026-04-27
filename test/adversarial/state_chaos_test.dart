/// State Chaos Tests - "PROSECUTOR MODE"
///
/// These tests simulate state corruption scenarios including corrupted cache data,
/// missing cache keys, type mismatches, malformed offline operations, provider
/// state corruption, and concurrent modifications.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/core/models/relative_streak_model.dart';
import 'package:silni_app/core/models/streak_freeze_model.dart';
import 'package:silni_app/shared/models/interaction_model.dart';
import 'package:silni_app/shared/models/offline_operation.dart';
import 'package:silni_app/shared/models/relative_model.dart';
import 'package:silni_app/shared/models/sync_metadata.dart';

import 'adversarial_test_harness.dart';

void main() {
  group('State Chaos Tests - PROSECUTOR MODE', () {
    // =========================================================================
    // CORRUPTED CACHE DATA TESTS
    // =========================================================================

    group('Corrupted Cache Data', () {
      test('Relative fromJson survives corrupted fullName field', () {
        // Simulate cache corruption where fullName becomes non-string
        final corruptedJsons = [
          {'id': 'test', 'user_id': 'user', 'full_name': 12345},
          {'id': 'test', 'user_id': 'user', 'full_name': null},
          {'id': 'test', 'user_id': 'user', 'full_name': true},
          {'id': 'test', 'user_id': 'user', 'full_name': ['array']},
          {'id': 'test', 'user_id': 'user', 'full_name': {'nested': 'map'}},
        ];

        for (final json in corruptedJsons) {
          try {
            final relative = Relative.fromJson(json);
            // If parsing succeeds, verify model is in valid state
            expect(relative, isNotNull);
            // fullName should be coerced or defaulted
            expect(relative.fullName, isA<String>());
          } catch (e) {
            // TypeError is acceptable - model enforces type safety
            expect(e, isA<TypeError>());
          }
        }
      });

      test('Relative fromJson survives corrupted priority field', () {
        final corruptedPriorities = [
          'high', // Should be int
          null,
          true,
          double.infinity,
          double.nan,
          {'complex': 'object'},
          [1, 2, 3],
          '999999999999999999999', // Overflow
        ];

        for (final priority in corruptedPriorities) {
          final json = {
            'id': 'test',
            'user_id': 'user',
            'full_name': 'Test Name',
            'relationship_type': 'other',
            'priority': priority,
          };

          try {
            final relative = Relative.fromJson(json);
            expect(relative, isNotNull);
            // Priority should be int or default
            expect(relative.priority, isA<int>());
          } catch (e) {
            // Type errors are acceptable
            expect(e, anyOf(isA<TypeError>(), isA<FormatException>()));
          }
        }
      });

      test('Relative fromJson survives corrupted boolean fields', () {
        final corruptedBools = [
          'true', // String instead of bool
          'false',
          1,
          0,
          'yes',
          'no',
          null,
          {'complex': 'object'},
        ];

        for (final boolVal in corruptedBools) {
          final json = {
            'id': 'test',
            'user_id': 'user',
            'full_name': 'Test',
            'relationship_type': 'other',
            'is_favorite': boolVal,
            'is_archived': boolVal,
          };

          try {
            final relative = Relative.fromJson(json);
            expect(relative, isNotNull);
            expect(relative.isFavorite, isA<bool>());
            expect(relative.isArchived, isA<bool>());
          } catch (e) {
            expect(e, isA<TypeError>());
          }
        }
      });

      test('Interaction fromJson survives corrupted date fields', () {
        final corruptedDates = [
          null,
          12345, // Int instead of string
          true,
          'not-a-date',
          {'nested': 'object'},
          '9999-99-99T99:99:99',
          '',
          '   ',
        ];

        for (final dateVal in corruptedDates) {
          final json = {
            'id': 'test',
            'user_id': 'user',
            'relative_id': 'relative',
            'type': 'call',
            'date': dateVal,
            'created_at': dateVal,
          };

          try {
            final interaction = Interaction.fromJson(json);
            expect(interaction, isNotNull);
            expect(interaction.date, isA<DateTime>());
          } catch (e) {
            // Format and type errors are acceptable
            expect(e, anyOf(isA<FormatException>(), isA<TypeError>()));
          }
        }
      });

      test('RelativeStreak fromJson survives corrupted streak counts', () {
        final corruptedCounts = [
          null,
          'many', // String instead of int
          true,
          double.infinity,
          double.nan,
          {'nested': 'object'},
          999999999999999999, // Potential overflow
        ];

        for (final count in corruptedCounts) {
          final json = {
            'id': 'test',
            'user_id': 'user',
            'relative_id': 'relative',
            'current_streak': count,
            'longest_streak': count,
          };

          try {
            final streak = RelativeStreak.fromJson(json);
            expect(streak, isNotNull);
            expect(streak.currentStreak, isA<int>());
          } catch (e) {
            expect(e, anyOf(isA<TypeError>(), isA<FormatException>()));
          }
        }
      });

      test('FreezeInventory fromJson survives corrupted freeze counts', () {
        final corruptedCounts = [
          null,
          'five',
          true,
          -999999999999,
          double.maxFinite,
        ];

        for (final count in corruptedCounts) {
          final json = {
            'id': 'test',
            'user_id': 'user',
            'freeze_count': count,
            'freezes_used_total': count,
          };

          try {
            final inventory = FreezeInventory.fromJson(json);
            expect(inventory, isNotNull);
            expect(inventory.freezeCount, isA<int>());
          } catch (e) {
            expect(e, anyOf(isA<TypeError>(), isA<FormatException>()));
          }
        }
      });

      test('SyncMetadata constructor handles edge cases', () {
        // SyncMetadata doesn't have fromJson, test constructor directly
        final testCases = [
          SyncMetadata(
            key: '',
            lastSync: DateTime.now(),
            itemCount: 0,
          ),
          SyncMetadata(
            key: 'test-key',
            lastSync: DateTime(1970, 1, 1),
            itemCount: -1,
          ),
          SyncMetadata(
            key: MaliciousInputs.sqlInjection.first,
            lastSync: DateTime.now(),
            itemCount: 2147483647,
          ),
        ];

        for (final metadata in testCases) {
          expect(metadata, isNotNull);
          expect(metadata.key, isA<String>());
          expect(metadata.lastSync, isA<DateTime>());
          expect(() => metadata.isStale(const Duration(hours: 1)), returnsNormally);
          expect(() => metadata.toJson(), returnsNormally);
        }
      });
    });

    // =========================================================================
    // MISSING CACHE KEYS TESTS
    // =========================================================================

    group('Missing Cache Keys', () {
      test('Relative fromJson handles completely missing required fields', () {
        final incompleteJsons = <Map<String, dynamic>>[
          {}, // Completely empty
          {'id': 'test'}, // Only ID
          {'user_id': 'user'}, // Only user_id
          {'full_name': 'Name'}, // Only name
          {'id': 'test', 'user_id': 'user'}, // Missing name and type
        ];

        for (final json in incompleteJsons) {
          try {
            final relative = Relative.fromJson(json);
            // Model should provide defaults for missing fields
            expect(relative, isNotNull);
            expect(relative.id, isA<String>());
            expect(relative.userId, isA<String>());
            expect(relative.fullName, isA<String>());
            expect(relative.relationshipType, isA<RelationshipType>());
          } catch (e) {
            // Some implementations may require certain fields
            expect(e, anyOf(isA<TypeError>(), isA<ArgumentError>()));
          }
        }
      });

      test('Interaction fromJson handles missing required fields', () {
        final incompleteJsons = <Map<String, dynamic>>[
          {},
          {'id': 'test'},
          {'id': 'test', 'user_id': 'user'},
          {'id': 'test', 'user_id': 'user', 'relative_id': 'relative'},
          // Missing type, date
        ];

        for (final json in incompleteJsons) {
          try {
            final interaction = Interaction.fromJson(json);
            expect(interaction, isNotNull);
            expect(interaction.type, isA<InteractionType>());
          } catch (e) {
            expect(e, anyOf(isA<TypeError>(), isA<FormatException>()));
          }
        }
      });

      test('RelativeStreak fromJson handles missing streak values', () {
        final json = {
          'id': 'test',
          'user_id': 'user',
          'relative_id': 'relative',
          // current_streak and longest_streak missing
        };

        try {
          final streak = RelativeStreak.fromJson(json);
          expect(streak, isNotNull);
          // Should default to 0
          expect(streak.currentStreak, greaterThanOrEqualTo(0));
          expect(streak.longestStreak, greaterThanOrEqualTo(0));
        } catch (e) {
          expect(e, anyOf(isA<TypeError>(), isA<ArgumentError>()));
        }
      });

      test('OfflineOperation handles missing data gracefully', () {
        // Test OfflineOperation construction with minimal data
        final op = OfflineOperation(
          id: 1,
          type: OperationType.create,
          entityType: 'relative',
          entityId: 'test-id',
          data: {}, // Empty data map
          createdAt: DateTime.now(),
        );

        expect(op, isNotNull);
        expect(op.data, isEmpty);
        expect(op.retryCount, 0);
        expect(op.isDeadLetter, isFalse);

        // toJson should work
        expect(() => op.toJson(), returnsNormally);
      });

      test('SyncMetadata handles edge case keys', () {
        // Test with various key values
        final keys = ['', ' ', 'normal-key', MaliciousInputs.sqlInjection.first];

        for (final key in keys) {
          final metadata = SyncMetadata(
            key: key,
            lastSync: DateTime.now(),
          );

          expect(metadata, isNotNull);
          expect(metadata.key, key);
          expect(() => metadata.copyWith(), returnsNormally);
        }
      });
    });

    // =========================================================================
    // TYPE MISMATCH IN CACHE TESTS
    // =========================================================================

    group('Type Mismatches in Cache', () {
      test('handles list where map expected', () {
        // JSON parsing where we expect a Map but get a List
        final listInsteadOfMap = <Map<String, String>>[
          {'id': 'test1'},
          {'id': 'test2'},
        ];

        // This should fail gracefully when trying to parse as single Relative
        // The list cannot be cast to Map, so this tests type safety
        expect(listInsteadOfMap, isA<List>());
        expect(listInsteadOfMap, isNot(isA<Map<String, dynamic>>()));

        // Each element can be parsed individually
        for (final item in listInsteadOfMap) {
          try {
            Relative.fromJson(item);
          } catch (e) {
            // Expected - incomplete data
          }
        }
      });

      test('handles string where list expected for interests', () {
        final json = {
          'id': 'test',
          'user_id': 'user',
          'full_name': 'Test',
          'relationship_type': 'other',
          'interests': 'coding, reading, gaming', // String instead of list
        };

        try {
          final relative = Relative.fromJson(json);
          expect(relative, isNotNull);
          // interests should handle gracefully
          expect(relative.interests, anyOf(isNull, isA<List<String>>()));
        } catch (e) {
          expect(e, isA<TypeError>());
        }
      });

      test('handles int where string expected for IDs', () {
        final json = {
          'id': 12345, // Int instead of string
          'user_id': 67890,
          'relative_id': 11111,
          'type': 'call',
          'date': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        };

        try {
          final interaction = Interaction.fromJson(json);
          expect(interaction, isNotNull);
          // IDs should be strings
          expect(interaction.id, isA<String>());
        } catch (e) {
          expect(e, isA<TypeError>());
        }
      });

      test('handles double where int expected for counts', () {
        final json = {
          'id': 'test',
          'user_id': 'user',
          'full_name': 'Test',
          'relationship_type': 'other',
          'priority': 1.5, // Double instead of int
          'interaction_count': 10.7,
        };

        try {
          final relative = Relative.fromJson(json);
          expect(relative, isNotNull);
          // Should handle double gracefully
          expect(relative.priority, isA<int>());
        } catch (e) {
          expect(e, isA<TypeError>());
        }
      });

      test('handles nested map corruption', () {
        // Simulate corrupted nested data
        final json = {
          'id': 'test',
          'user_id': 'user',
          'full_name': 'Test',
          'relationship_type': 'other',
          'metadata': {
            'corrupted': {
              'deeply': {
                'nested': null,
              },
            },
          },
        };

        try {
          final relative = Relative.fromJson(json);
          expect(relative, isNotNull);
        } catch (e) {
          // Depending on implementation, may throw or handle gracefully
        }
      });
    });

    // =========================================================================
    // MALFORMED OFFLINE OPERATIONS TESTS
    // =========================================================================

    group('Malformed Offline Operations', () {
      test('OfflineOperation handles invalid entity types', () {
        final invalidEntityTypes = [
          '', // Empty
          'unknown_entity',
          'RELATIVE', // Wrong case
          'user', // Not supported
          '../../../etc/passwd', // Path traversal attempt
          '<script>alert("xss")</script>',
          MaliciousInputs.kiloLong, // Very long
        ];

        for (final entityType in invalidEntityTypes) {
          // Should not crash when constructing
          final op = OfflineOperation(
            id: 1,
            type: OperationType.create,
            entityType: entityType,
            entityId: 'test',
            data: {'key': 'value'},
            createdAt: DateTime.now(),
          );

          expect(op.entityType, entityType);
          expect(() => op.toJson(), returnsNormally);
          expect(() => op.toString(), returnsNormally);
        }
      });

      test('OfflineOperation handles corrupted data map', () {
        // Test with various corrupted data maps
        final corruptedDataMaps = <Map<String, dynamic>>[
          {}, // Empty
          {'null_value': null},
          {'circular_like': 'CIRCULAR_REF_PLACEHOLDER'},
          StateChaos.randomChaosMap(depth: 5, breadth: 10),
          StateChaos.corruptMap({'key': 'value'}),
          {'very_long': MaliciousInputs.kiloLong},
          {'sql_injection': MaliciousInputs.sqlInjection.first},
          {'xss': MaliciousInputs.xssPayloads.first},
        ];

        for (final data in corruptedDataMaps) {
          final op = OfflineOperation(
            id: 1,
            type: OperationType.update,
            entityType: 'relative',
            entityId: 'test',
            data: data,
            createdAt: DateTime.now(),
          );

          // Should not crash
          expect(() => op.toJson(), returnsNormally);
          expect(() => op.toString(), returnsNormally);
          expect(() => op.copyWith(), returnsNormally);
          expect(() => op.copyWithRetry('error'), returnsNormally);
          expect(() => op.copyAsDeadLetter(), returnsNormally);
        }
      });

      test('OfflineOperation handles extreme retry counts', () {
        final extremeRetryCounts = [0, 1, 10, 100, 1000, -1, -100, 2147483647, -2147483648];

        for (final count in extremeRetryCounts) {
          final op = OfflineOperation(
            id: 1,
            type: OperationType.delete,
            entityType: 'interaction',
            entityId: 'test',
            data: {},
            createdAt: DateTime.now(),
            retryCount: count,
          );

          expect(op.retryCount, count);
          expect(() => op.copyWithRetry('error'), returnsNormally);

          // After copy, retry count should increment (but may overflow)
          final copied = op.copyWithRetry('error');
          expect(copied.retryCount, count + 1);
        }
      });

      test('OfflineOperation handles malicious error messages', () {
        for (final malicious in MaliciousInputs.sqlInjection) {
          final op = OfflineOperation(
            id: 1,
            type: OperationType.create,
            entityType: 'relative',
            entityId: 'test',
            data: {},
            createdAt: DateTime.now(),
            lastError: malicious,
          );

          expect(op.lastError, malicious);
          expect(() => op.toJson(), returnsNormally);
          expect(() => op.toString(), returnsNormally);
        }
      });

      test('OfflineOperation handles extreme dates', () {
        for (final extremeDate in MaliciousDates.extremeDates) {
          final op = OfflineOperation(
            id: 1,
            type: OperationType.create,
            entityType: 'schedule',
            entityId: 'test',
            data: {'date': extremeDate.toIso8601String()},
            createdAt: extremeDate,
          );

          expect(op.createdAt, extremeDate);
          expect(() => op.toJson(), returnsNormally);
        }
      });
    });

    // =========================================================================
    // PROVIDER STATE CORRUPTION TESTS
    // =========================================================================

    group('Provider State Corruption', () {
      test('RelativeStreak computed properties survive corrupted state', () {
        // Test boundary conditions for computed properties
        final testCases = [
          // Null deadline
          RelativeStreak(
            id: 'test',
            userId: 'user',
            relativeId: 'relative',
            currentStreak: 0,
            longestStreak: 0,
            streakDeadline: null,
            createdAt: DateTime.now(),
          ),
          // Past deadline
          RelativeStreak(
            id: 'test',
            userId: 'user',
            relativeId: 'relative',
            currentStreak: 5,
            longestStreak: 10,
            streakDeadline: DateTime.now().subtract(const Duration(days: 1)),
            createdAt: DateTime.now(),
          ),
          // Far future deadline
          RelativeStreak(
            id: 'test',
            userId: 'user',
            relativeId: 'relative',
            currentStreak: 100,
            longestStreak: 200,
            streakDeadline: DateTime.now().add(const Duration(days: 365)),
            createdAt: DateTime.now(),
          ),
          // Extreme streak values
          RelativeStreak(
            id: 'test',
            userId: 'user',
            relativeId: 'relative',
            currentStreak: 2147483647,
            longestStreak: 2147483647,
            createdAt: DateTime.now(),
          ),
          // Negative streaks (invalid but should not crash)
          RelativeStreak(
            id: 'test',
            userId: 'user',
            relativeId: 'relative',
            currentStreak: -1,
            longestStreak: -1,
            createdAt: DateTime.now(),
          ),
        ];

        for (final streak in testCases) {
          // All computed properties should not crash
          expect(() => streak.timeRemaining, returnsNormally);
          expect(() => streak.warningState, returnsNormally);
          expect(() => streak.isEndangered, returnsNormally);
          expect(() => streak.formattedTimeRemaining, returnsNormally);
          expect(() => streak.toJson(), returnsNormally);
          expect(() => streak.copyWith(), returnsNormally);
        }
      });

      test('FreezeInventory computed properties handle edge cases', () {
        final testCases = [
          FreezeInventory(
            id: 'test',
            userId: 'user',
            freezeCount: 0,
            freezesUsedTotal: 0,
            createdAt: DateTime.now(),
          ),
          FreezeInventory(
            id: 'test',
            userId: 'user',
            freezeCount: -1, // Invalid but should not crash
            freezesUsedTotal: 100,
            createdAt: DateTime.now(),
          ),
          FreezeInventory(
            id: 'test',
            userId: 'user',
            freezeCount: 2147483647,
            freezesUsedTotal: 2147483647,
            createdAt: DateTime.now(),
          ),
        ];

        for (final inventory in testCases) {
          expect(() => inventory.hasFreeze, returnsNormally);
          expect(() => inventory.copyWith(), returnsNormally);
        }
      });
    });

    // =========================================================================
    // CONCURRENT MODIFICATIONS TESTS
    // =========================================================================

    group('Concurrent Modifications', () {
      test('Relative copyWith during iteration does not corrupt data', () {
        final relatives = List.generate(
          100,
          (i) => Relative(
            id: 'rel-$i',
            userId: 'user',
            fullName: 'Relative $i',
            relationshipType: RelationshipType.other,
            priority: i % 3 + 1,
            createdAt: DateTime.now(),
          ),
        );

        // Simulate concurrent modifications during iteration
        final results = <Relative>[];
        for (final relative in relatives) {
          // Create copy while iterating
          final copy = relative.copyWith(
            fullName: '${relative.fullName} - Modified',
            priority: relative.priority + 1,
          );
          results.add(copy);
        }

        expect(results.length, 100);
        for (var i = 0; i < results.length; i++) {
          expect(results[i].fullName, contains('Modified'));
          expect(results[i].id, 'rel-$i');
        }
      });

      test('parallel JSON serialization does not corrupt state', () async {
        final relative = Relative(
          id: 'test',
          userId: 'user',
          fullName: 'Test Name',
          relationshipType: RelationshipType.father,
          priority: 1,
          interests: ['coding', 'reading'],
          createdAt: DateTime.now(),
        );

        // Serialize in parallel multiple times
        final futures = List.generate(100, (_) async {
          final json = relative.toJson();
          // Small delay to increase chance of race conditions
          await Future.delayed(Duration(microseconds: 1));
          return jsonEncode(json);
        });

        final results = await Future.wait(futures);

        // All results should be identical
        final first = results.first;
        for (final result in results) {
          expect(result, first);
        }
      });

      test('parallel Relative.fromJson calls do not interfere', () async {
        final json = {
          'id': 'test',
          'user_id': 'user',
          'full_name': 'Test Name',
          'relationship_type': 'father',
          'priority': 1,
          'interests': ['coding', 'reading'],
          'created_at': DateTime.now().toIso8601String(),
        };

        // Parse in parallel
        final futures = List.generate(100, (_) async {
          await Future.delayed(Duration(microseconds: 1));
          return Relative.fromJson(Map<String, dynamic>.from(json));
        });

        final results = await Future.wait(futures);

        // All results should be equivalent
        for (final result in results) {
          expect(result.id, 'test');
          expect(result.fullName, 'Test Name');
          expect(result.priority, 1);
        }
      });

      test('OfflineOperation copyWith chain does not lose data', () {
        var op = OfflineOperation(
          id: 1,
          type: OperationType.create,
          entityType: 'relative',
          entityId: 'test',
          data: {'key': 'value'},
          createdAt: DateTime.now(),
        );

        // Chain multiple copyWith calls
        for (var i = 0; i < 100; i++) {
          op = op.copyWithRetry('error $i');
        }

        // Should have accumulated all retries
        expect(op.retryCount, 100);
        expect(op.lastError, 'error 99');
        expect(op.entityId, 'test');
        expect(op.data['key'], 'value');
      });

      test('SyncMetadata isStale calculation is consistent', () {
        final now = DateTime.now();
        final metadata = SyncMetadata(
          key: 'test',
          lastSync: now.subtract(const Duration(hours: 1)),
          itemCount: 10,
        );

        // Call isStale multiple times in quick succession
        final results = <bool>[];
        for (var i = 0; i < 100; i++) {
          results.add(metadata.isStale(const Duration(minutes: 30)));
        }

        // All results should be the same
        final first = results.first;
        for (final result in results) {
          expect(result, first);
        }
      });

    });

    // =========================================================================
    // STATE CONSISTENCY TESTS
    // =========================================================================

    group('State Consistency', () {
      test('Relative maintains consistency after multiple modifications', () {
        var relative = Relative(
          id: 'test',
          userId: 'user',
          fullName: 'Original Name',
          relationshipType: RelationshipType.father,
          priority: 1,
          isFavorite: false,
          isArchived: false,
          interactionCount: 0,
          createdAt: DateTime.now(),
        );

        // Apply many modifications
        for (var i = 0; i < 100; i++) {
          relative = relative.copyWith(
            fullName: 'Name $i',
            priority: (i % 3) + 1,
            isFavorite: i % 2 == 0,
            interactionCount: i,
          );
        }

        // Final state should reflect last modification
        expect(relative.fullName, 'Name 99');
        expect(relative.priority, 1); // 99 % 3 + 1 = 1
        expect(relative.isFavorite, isFalse); // 99 % 2 != 0
        expect(relative.interactionCount, 99);
        // Original fields should be preserved
        expect(relative.id, 'test');
        expect(relative.userId, 'user');
        expect(relative.relationshipType, RelationshipType.father);
      });

      test('JSON round-trip preserves all fields after modifications', () {
        final original = Relative(
          id: 'test-id',
          userId: 'user-id',
          fullName: 'Test Name',
          relationshipType: RelationshipType.brother,
          gender: Gender.male,
          priority: 2,
          isFavorite: true,
          isArchived: false,
          interactionCount: 50,
          interests: ['coding', 'reading'],
          favoriteColors: ['blue', 'green'],
          createdAt: DateTime(2024, 1, 1),
        );

        // Multiple round trips
        var current = original;
        for (var i = 0; i < 10; i++) {
          final json = current.toJson();
          json['id'] = current.id;
          json['created_at'] = current.createdAt.toIso8601String();
          current = Relative.fromJson(json);
        }

        // Should still match original
        expect(current.id, original.id);
        expect(current.fullName, original.fullName);
        expect(current.relationshipType, original.relationshipType);
        expect(current.gender, original.gender);
        expect(current.priority, original.priority);
        expect(current.isFavorite, original.isFavorite);
        expect(current.interests, original.interests);
      });

      test('OfflineOperation maintains consistency through all states', () {
        // Create -> retry multiple times -> dead letter
        var op = OfflineOperation(
          id: 1,
          type: OperationType.create,
          entityType: 'relative',
          entityId: 'test',
          data: {'key': 'value', 'nested': {'deep': 'data'}},
          createdAt: DateTime.now(),
        );

        // Simulate retries
        for (var i = 0; i < 5; i++) {
          op = op.copyWithRetry('Error attempt $i');
        }

        // Convert to dead letter
        final deadLetter = op.copyAsDeadLetter();

        // Verify all original data is preserved
        expect(deadLetter.id, 1);
        expect(deadLetter.type, OperationType.create);
        expect(deadLetter.entityType, 'relative');
        expect(deadLetter.entityId, 'test');
        expect(deadLetter.data['key'], 'value');
        expect(deadLetter.data['nested']['deep'], 'data');
        expect(deadLetter.retryCount, 5);
        expect(deadLetter.isDeadLetter, isTrue);
        expect(deadLetter.lastError, 'Error attempt 4');
      });
    });
  });
}
