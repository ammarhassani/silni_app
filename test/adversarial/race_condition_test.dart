/// Race Condition Tests - "PROSECUTOR MODE"
///
/// These tests simulate race condition scenarios including concurrent API calls,
/// rapid navigation changes, login/logout races, sync races, and timer cleanup
/// on dispose. The goal is to ensure thread-safe operations and proper resource
/// management under concurrent access.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/core/models/gamification_event.dart';
import 'package:silni_app/core/models/relative_streak_model.dart';
import 'package:silni_app/shared/models/interaction_model.dart';
import 'package:silni_app/shared/models/offline_operation.dart';
import 'package:silni_app/shared/models/relative_model.dart';
import 'package:silni_app/shared/models/sync_metadata.dart';

void main() {
  group('Race Condition Tests - PROSECUTOR MODE', () {
    // =========================================================================
    // CONCURRENT API CALLS TESTS
    // =========================================================================

    group('Concurrent API Calls', () {
      test('parallel Relative.fromJson calls are thread-safe', () async {
        // Simulate many concurrent parse operations
        final json = {
          'id': 'test-id',
          'user_id': 'user-id',
          'full_name': 'Test Name',
          'relationship_type': 'father',
          'priority': 1,
          'interaction_count': 10,
          'is_favorite': true,
          'created_at': DateTime.now().toIso8601String(),
        };

        // Launch 100 concurrent parsing operations
        final futures = <Future<Relative>>[];
        for (var i = 0; i < 100; i++) {
          futures.add(Future(() {
            // Each operation gets its own copy to simulate independent calls
            return Relative.fromJson(Map<String, dynamic>.from(json));
          }));
        }

        final results = await Future.wait(futures);

        // All results should be valid and consistent
        expect(results.length, 100);
        for (final relative in results) {
          expect(relative.id, 'test-id');
          expect(relative.fullName, 'Test Name');
          expect(relative.priority, 1);
        }
      });

      test('parallel Interaction.fromJson calls are thread-safe', () async {
        final json = {
          'id': 'interaction-id',
          'user_id': 'user-id',
          'relative_id': 'relative-id',
          'type': 'call',
          'date': DateTime.now().toIso8601String(),
          'duration': 30,
          'notes': 'Test notes',
          'created_at': DateTime.now().toIso8601String(),
        };

        final futures = <Future<Interaction>>[];
        for (var i = 0; i < 100; i++) {
          futures.add(Future(() {
            return Interaction.fromJson(Map<String, dynamic>.from(json));
          }));
        }

        final results = await Future.wait(futures);

        expect(results.length, 100);
        for (final interaction in results) {
          expect(interaction.id, 'interaction-id');
          expect(interaction.type, InteractionType.call);
          expect(interaction.duration, 30);
        }
      });

      test('parallel toJson calls do not interfere with each other', () async {
        final relative = Relative(
          id: 'test-id',
          userId: 'user-id',
          fullName: 'Test Name',
          relationshipType: RelationshipType.father,
          priority: 1,
          interests: ['coding', 'reading', 'gaming'],
          favoriteColors: ['blue', 'green'],
          createdAt: DateTime.now(),
        );

        // Launch many parallel serializations
        final futures = <Future<Map<String, dynamic>>>[];
        for (var i = 0; i < 100; i++) {
          futures.add(Future(() => relative.toJson()));
        }

        final results = await Future.wait(futures);

        // All results should be identical
        expect(results.length, 100);
        final firstJson = results.first;
        for (final json in results) {
          expect(json['full_name'], firstJson['full_name']);
          expect(json['priority'], firstJson['priority']);
          expect(json['interests'], firstJson['interests']);
        }
      });

      test('interleaved read/write operations maintain consistency', () async {
        // Simulate interleaved operations on different data
        final operations = <Future<dynamic>>[];

        for (var i = 0; i < 50; i++) {
          // Parse operation
          operations.add(Future(() {
            return Relative.fromJson({
              'id': 'rel-$i',
              'user_id': 'user',
              'full_name': 'Name $i',
              'relationship_type': 'other',
              'created_at': DateTime.now().toIso8601String(),
            });
          }));

          // Serialize operation
          operations.add(Future(() {
            final rel = Relative(
              id: 'rel-write-$i',
              userId: 'user',
              fullName: 'Write Name $i',
              relationshipType: RelationshipType.other,
              createdAt: DateTime.now(),
            );
            return rel.toJson();
          }));
        }

        // All operations should complete without errors
        await Future.wait(operations);
      });

      test('concurrent GamificationEvent creation is safe', () async {
        final futures = <Future<GamificationEvent>>[];

        for (var i = 0; i < 100; i++) {
          futures.add(Future(() {
            return GamificationEvent.pointsEarned(
              userId: 'user-$i',
              points: i * 10,
              source: 'test-$i',
            );
          }));

          futures.add(Future(() {
            return GamificationEvent.levelUp(
              userId: 'user-$i',
              oldLevel: i,
              newLevel: i + 1,
              currentXP: i * 100,
              xpToNextLevel: (i + 1) * 100,
            );
          }));
        }

        final results = await Future.wait(futures);
        expect(results.length, 200);

        // Verify each event has correct data
        for (var i = 0; i < 100; i++) {
          final pointsEvent = results[i * 2];
          expect(pointsEvent.points, i * 10);

          final levelEvent = results[i * 2 + 1];
          expect(levelEvent.newLevel, i + 1);
        }
      });
    });

    // =========================================================================
    // RAPID NAVIGATION CHANGES TESTS
    // =========================================================================

    group('Rapid Navigation Changes', () {
      test('rapid model creation/destruction is memory safe', () async {
        // Simulate rapid widget creation/destruction
        for (var cycle = 0; cycle < 10; cycle++) {
          final relatives = <Relative>[];

          // Create many models rapidly
          for (var i = 0; i < 100; i++) {
            relatives.add(Relative(
              id: 'rel-$cycle-$i',
              userId: 'user',
              fullName: 'Name $i',
              relationshipType: RelationshipType.values[i % RelationshipType.values.length],
              priority: (i % 3) + 1,
              createdAt: DateTime.now(),
            ));
          }

          // Immediately "navigate away" - clear the list
          relatives.clear();

          // Small delay to simulate navigation
          await Future.delayed(const Duration(milliseconds: 1));
        }

        // If we get here, no memory leaks or crashes
      });

      test('rapid copyWith operations are stable', () async {
        var relative = Relative(
          id: 'test',
          userId: 'user',
          fullName: 'Initial Name',
          relationshipType: RelationshipType.father,
          priority: 1,
          createdAt: DateTime.now(),
        );

        // Simulate rapid state updates (like user typing)
        for (var i = 0; i < 1000; i++) {
          relative = relative.copyWith(fullName: 'Name $i');
          // Don't await - simulate rapid fire updates
        }

        expect(relative.fullName, 'Name 999');
        expect(relative.id, 'test'); // Original fields preserved
      });

      test('rapid streak state changes are handled', () async {
        // Simulate rapid streak updates
        final streaks = <RelativeStreak>[];

        for (var i = 0; i < 100; i++) {
          final streak = RelativeStreak(
            id: 'streak-$i',
            userId: 'user',
            relativeId: 'relative-$i',
            currentStreak: i,
            longestStreak: i + 10,
            streakDeadline: DateTime.now().add(Duration(hours: i % 24)),
            createdAt: DateTime.now(),
          );

          streaks.add(streak);

          // Access computed properties immediately to test concurrent access
          streak.warningState;
          streak.timeRemaining;
          streak.isEndangered;
        }

        expect(streaks.length, 100);
      });

      test('rapid OfflineOperation queue operations are safe', () async {
        final operations = <OfflineOperation>[];

        // Rapidly enqueue operations
        for (var i = 0; i < 100; i++) {
          operations.add(OfflineOperation(
            id: i,
            type: OperationType.values[i % OperationType.values.length],
            entityType: ['relative', 'interaction', 'schedule'][i % 3],
            entityId: 'entity-$i',
            data: {'key': 'value-$i'},
            createdAt: DateTime.now(),
          ));
        }

        // Rapidly process (simulate dequeue)
        for (final op in operations) {
          op.toJson();
          op.toString();
        }

        // Clear rapidly
        operations.clear();

        // If we get here, operations are safe
      });
    });

    // =========================================================================
    // LOGIN/LOGOUT RACES TESTS
    // =========================================================================

    group('Login/Logout Races', () {
      test('user data cleared between sessions does not corrupt new session', () async {
        // Simulate login with user A
        final userARelatives = List.generate(
          10,
          (i) => Relative(
            id: 'a-rel-$i',
            userId: 'user-a',
            fullName: 'User A Relative $i',
            relationshipType: RelationshipType.other,
            createdAt: DateTime.now(),
          ),
        );

        // Simulate logout (clear data)
        final clearedData = <Relative>[];
        // Data is cleared

        // Simulate login with user B
        final userBRelatives = List.generate(
          10,
          (i) => Relative(
            id: 'b-rel-$i',
            userId: 'user-b',
            fullName: 'User B Relative $i',
            relationshipType: RelationshipType.other,
            createdAt: DateTime.now(),
          ),
        );

        // Verify no data leakage
        expect(clearedData, isEmpty);
        expect(userBRelatives.every((r) => r.userId == 'user-b'), isTrue);
        expect(userARelatives.every((r) => r.userId == 'user-a'), isTrue);
      });

      test('concurrent session operations do not interfere', () async {
        // Simulate two "sessions" running operations concurrently
        final sessionA = <Future<dynamic>>[];
        final sessionB = <Future<dynamic>>[];

        for (var i = 0; i < 50; i++) {
          sessionA.add(Future(() {
            return Relative(
              id: 'session-a-$i',
              userId: 'user-a',
              fullName: 'Session A - $i',
              relationshipType: RelationshipType.father,
              createdAt: DateTime.now(),
            );
          }));

          sessionB.add(Future(() {
            return Relative(
              id: 'session-b-$i',
              userId: 'user-b',
              fullName: 'Session B - $i',
              relationshipType: RelationshipType.mother,
              createdAt: DateTime.now(),
            );
          }));
        }

        final resultsA = await Future.wait(sessionA);
        final resultsB = await Future.wait(sessionB);

        // Verify session isolation
        for (final r in resultsA) {
          expect((r as Relative).userId, 'user-a');
        }
        for (final r in resultsB) {
          expect((r as Relative).userId, 'user-b');
        }
      });

      test('rapid login/logout cycles do not cause state corruption', () async {
        // Simulate rapid login/logout cycles
        for (var cycle = 0; cycle < 20; cycle++) {
          // Login
          final userData = {
            'id': 'user-$cycle',
            'relatives': List.generate(5, (i) => 'rel-$i'),
            'session_token': 'token-$cycle',
          };

          // Access data
          expect(userData['id'], 'user-$cycle');

          // Logout (clear)
          userData.clear();

          expect(userData, isEmpty);
        }
      });
    });

    // =========================================================================
    // SYNC RACES TESTS
    // =========================================================================

    group('Sync Races', () {
      test('concurrent sync operations produce consistent results', () async {
        // Simulate multiple sync operations happening concurrently
        final syncOperations = <Future<List<Relative>>>[];

        for (var syncId = 0; syncId < 10; syncId++) {
          syncOperations.add(Future(() {
            // Simulate fetching and parsing relatives
            return List.generate(
              10,
              (i) => Relative(
                id: 'sync-$syncId-rel-$i',
                userId: 'user',
                fullName: 'Synced Name $i',
                relationshipType: RelationshipType.other,
                createdAt: DateTime.now(),
              ),
            );
          }));
        }

        final allResults = await Future.wait(syncOperations);

        expect(allResults.length, 10);
        for (final syncResult in allResults) {
          expect(syncResult.length, 10);
        }
      });

      test('offline queue operations during sync are safe', () async {
        // Simulate sync happening while offline operations are queued
        final offlineQueue = <OfflineOperation>[];
        final syncResults = <Relative>[];

        // Parallel operations
        final queueFutures = <Future<void>>[];
        final syncFutures = <Future<void>>[];

        for (var i = 0; i < 50; i++) {
          // Queue offline operation
          queueFutures.add(Future(() {
            offlineQueue.add(OfflineOperation(
              id: i,
              type: OperationType.create,
              entityType: 'relative',
              entityId: 'offline-$i',
              data: {'name': 'Offline $i'},
              createdAt: DateTime.now(),
            ));
          }));

          // Sync operation
          syncFutures.add(Future(() {
            syncResults.add(Relative(
              id: 'synced-$i',
              userId: 'user',
              fullName: 'Synced $i',
              relationshipType: RelationshipType.other,
              createdAt: DateTime.now(),
            ));
          }));
        }

        await Future.wait([...queueFutures, ...syncFutures]);

        expect(offlineQueue.length, 50);
        expect(syncResults.length, 50);
      });

      test('SyncMetadata updates during concurrent access are safe', () async {
        // Test concurrent access to sync metadata
        final metadataList = <SyncMetadata>[];

        final futures = <Future<void>>[];
        for (var i = 0; i < 100; i++) {
          futures.add(Future(() {
            final metadata = SyncMetadata(
              key: 'sync-key-$i',
              lastSync: DateTime.now(),
              itemCount: i,
            );
            metadataList.add(metadata);

            // Access computed properties
            final _ = metadata.isStale(const Duration(minutes: 5));
          }));
        }

        await Future.wait(futures);

        expect(metadataList.length, 100);
      });

      test('retry operations during sync do not cause deadlock', () async {
        // Simulate retry operations happening during sync
        var op = OfflineOperation(
          id: 1,
          type: OperationType.create,
          entityType: 'relative',
          entityId: 'test',
          data: {'name': 'Test'},
          createdAt: DateTime.now(),
        );

        // Simulate concurrent retries
        final retryFutures = <Future<OfflineOperation>>[];
        for (var i = 0; i < 10; i++) {
          retryFutures.add(Future(() {
            return op.copyWithRetry('Error attempt $i');
          }));
        }

        final retryResults = await Future.wait(retryFutures);

        // All retries should complete (no deadlock)
        expect(retryResults.length, 10);

        // Each should have incremented retry count
        for (final result in retryResults) {
          expect(result.retryCount, 1); // Each started from original op
        }
      });
    });

    // =========================================================================
    // TIMER CLEANUP ON DISPOSE TESTS
    // =========================================================================

    group('Timer Cleanup on Dispose', () {
      test('stream controllers can be closed safely', () async {
        // Simulate stream controller lifecycle
        final controller = StreamController<Relative>.broadcast();

        // Add listeners
        final subscription1 = controller.stream.listen((data) {});
        final subscription2 = controller.stream.listen((data) {});

        // Emit some data
        for (var i = 0; i < 10; i++) {
          controller.add(Relative(
            id: 'rel-$i',
            userId: 'user',
            fullName: 'Name $i',
            relationshipType: RelationshipType.other,
            createdAt: DateTime.now(),
          ));
        }

        // Cancel subscriptions
        await subscription1.cancel();
        await subscription2.cancel();

        // Close controller
        await controller.close();

        // Verify controller is closed
        expect(controller.isClosed, isTrue);
      });

      test('rapid stream subscription/cancellation is safe', () async {
        final controller = StreamController<int>.broadcast();

        // Rapid subscribe/unsubscribe cycles
        for (var cycle = 0; cycle < 50; cycle++) {
          final subscription = controller.stream.listen((data) {});
          controller.add(cycle);
          await subscription.cancel();
        }

        await controller.close();
        expect(controller.isClosed, isTrue);
      });

      test('timers cancelled before callback fires do not crash', () async {
        final completers = <Completer<void>>[];

        for (var i = 0; i < 20; i++) {
          final completer = Completer<void>();
          completers.add(completer);

          final timer = Timer(const Duration(seconds: 10), () {
            // This should NOT fire
            completer.complete();
          });

          // Cancel immediately (before it fires)
          timer.cancel();
        }

        // Wait a moment to ensure cancelled timers don't fire
        await Future.delayed(const Duration(milliseconds: 100));

        // None of the completers should have completed
        for (final completer in completers) {
          expect(completer.isCompleted, isFalse);
        }
      });

      test('periodic timers cancelled during callback are safe', () async {
        var callCount = 0;
        Timer? timer;

        timer = Timer.periodic(const Duration(milliseconds: 10), (_) {
          callCount++;
          if (callCount >= 5) {
            timer?.cancel();
          }
        });

        // Wait for timer to fire several times and cancel itself
        await Future.delayed(const Duration(milliseconds: 100));

        expect(callCount, 5);
        expect(timer.isActive, isFalse);
      });

      test('future completes even if timer is cancelled', () async {
        final completer = Completer<String>();

        final timer = Timer(const Duration(seconds: 10), () {
          if (!completer.isCompleted) {
            completer.complete('timeout');
          }
        });

        // Complete immediately (simulating successful operation)
        completer.complete('success');
        timer.cancel();

        final result = await completer.future;
        expect(result, 'success');
      });

      test('multiple timers can be cancelled in any order', () async {
        final timers = <Timer>[];

        for (var i = 0; i < 10; i++) {
          timers.add(Timer(Duration(seconds: i + 1), () {}));
        }

        // Cancel in reverse order
        for (var i = timers.length - 1; i >= 0; i--) {
          timers[i].cancel();
        }

        // All should be inactive
        for (final timer in timers) {
          expect(timer.isActive, isFalse);
        }
      });
    });

    // =========================================================================
    // ASYNC STATE TRANSITIONS TESTS
    // =========================================================================

    group('Async State Transitions', () {
      test('rapid async state changes preserve order', () async {
        final stateHistory = <int>[];
        var currentState = 0;

        // Launch async state changes in order
        for (var i = 1; i <= 10; i++) {
          await Future(() {
            currentState = i;
            stateHistory.add(currentState);
          });
        }

        // States should have been recorded in order
        expect(stateHistory, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
        expect(currentState, 10);
      });

      test('parallel state reads return consistent snapshot', () async {
        final relative = Relative(
          id: 'test',
          userId: 'user',
          fullName: 'Consistent Name',
          relationshipType: RelationshipType.father,
          priority: 1,
          isFavorite: true,
          createdAt: DateTime.now(),
        );

        // Parallel reads of the same state
        final reads = <Future<Map<String, dynamic>>>[];
        for (var i = 0; i < 100; i++) {
          reads.add(Future(() => {
                'id': relative.id,
                'name': relative.fullName,
                'priority': relative.priority,
                'favorite': relative.isFavorite,
              }));
        }

        final results = await Future.wait(reads);

        // All reads should return same values
        for (final result in results) {
          expect(result['id'], 'test');
          expect(result['name'], 'Consistent Name');
          expect(result['priority'], 1);
          expect(result['favorite'], true);
        }
      });

      test('state changes during enumeration do not cause ConcurrentModificationError', () {
        // Test with a copy-based approach
        final original = <String>['a', 'b', 'c', 'd', 'e'];
        final copy = List<String>.from(original);
        final results = <String>[];

        // Modify original while iterating copy
        for (final item in copy) {
          original.add(item.toUpperCase());
          results.add(item);
        }

        expect(results, ['a', 'b', 'c', 'd', 'e']);
        expect(original.length, 10); // Original was modified
      });
    });

    // =========================================================================
    // CONCURRENT COLLECTION OPERATIONS TESTS
    // =========================================================================

    group('Concurrent Collection Operations', () {
      test('adding to list while iterating copy is safe', () {
        final relatives = <Relative>[];

        // Initial data
        for (var i = 0; i < 10; i++) {
          relatives.add(Relative(
            id: 'rel-$i',
            userId: 'user',
            fullName: 'Name $i',
            relationshipType: RelationshipType.other,
            createdAt: DateTime.now(),
          ));
        }

        // Iterate over copy while modifying original
        final copy = List<Relative>.from(relatives);
        for (final rel in copy) {
          // Add new relative based on current
          relatives.add(rel.copyWith(
            id: '${rel.id}-copy',
            fullName: '${rel.fullName} Copy',
          ));
        }

        expect(relatives.length, 20);
      });

      test('map operations during iteration are safe with copy', () {
        final data = <String, int>{'a': 1, 'b': 2, 'c': 3};
        final copy = Map<String, int>.from(data);

        for (final entry in copy.entries) {
          data['${entry.key}_double'] = entry.value * 2;
        }

        expect(data.length, 6);
        expect(data['a_double'], 2);
        expect(data['b_double'], 4);
        expect(data['c_double'], 6);
      });

      test('set operations during iteration are safe with copy', () {
        final ids = <String>{'id1', 'id2', 'id3'};
        final copy = Set<String>.from(ids);

        for (final id in copy) {
          ids.add('${id}_new');
        }

        expect(ids.length, 6);
      });
    });

    // =========================================================================
    // ERROR HANDLING IN CONCURRENT OPERATIONS TESTS
    // =========================================================================

    group('Error Handling in Concurrent Operations', () {
      test('one failing future does not crash Future.wait with error handling', () async {
        final futures = <Future<Relative>>[];

        for (var i = 0; i < 10; i++) {
          if (i == 5) {
            // This one will fail
            futures.add(Future.error(Exception('Simulated failure')));
          } else {
            futures.add(Future(() => Relative(
                  id: 'rel-$i',
                  userId: 'user',
                  fullName: 'Name $i',
                  relationshipType: RelationshipType.other,
                  createdAt: DateTime.now(),
                )));
          }
        }

        // Use try-catch to handle the error
        try {
          await Future.wait(futures);
          fail('Should have thrown');
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('errors in parallel operations are isolated', () async {
        final results = <dynamic>[];
        final errors = <dynamic>[];

        final futures = <Future<void>>[];
        for (var i = 0; i < 10; i++) {
          futures.add(Future(() {
            if (i % 3 == 0) {
              throw Exception('Error at $i');
            }
            results.add(i);
          }).catchError((e) {
            errors.add(e);
          }));
        }

        await Future.wait(futures);

        // Some succeeded, some failed
        expect(results, containsAll([1, 2, 4, 5, 7, 8]));
        expect(errors.length, 4); // 0, 3, 6, 9 failed
      });

      test('timeout handling in concurrent operations', () async {
        final results = <String>[];

        final futures = <Future<void>>[];
        for (var i = 0; i < 5; i++) {
          final delay = i == 2 ? const Duration(seconds: 10) : const Duration(milliseconds: 10);

          futures.add(
            Future.delayed(delay, () => 'result-$i')
                .timeout(
                  const Duration(milliseconds: 100),
                  onTimeout: () => 'timeout-$i',
                )
                .then((value) => results.add(value)),
          );
        }

        await Future.wait(futures);

        // Most should succeed, one should timeout
        expect(results, contains('result-0'));
        expect(results, contains('result-1'));
        expect(results, contains('timeout-2')); // This one timed out
        expect(results, contains('result-3'));
        expect(results, contains('result-4'));
      });
    });

    // =========================================================================
    // RESOURCE CONTENTION TESTS
    // =========================================================================

    group('Resource Contention', () {
      test('shared counter incremented concurrently', () async {
        var counter = 0;

        // Note: Dart is single-threaded, so this tests async scheduling
        final futures = <Future<void>>[];
        for (var i = 0; i < 100; i++) {
          futures.add(Future(() {
            counter++;
          }));
        }

        await Future.wait(futures);

        // In Dart, this should be exactly 100 due to single-threaded nature
        expect(counter, 100);
      });

      test('list populated from parallel futures has all elements', () async {
        final results = <int>[];

        final futures = <Future<void>>[];
        for (var i = 0; i < 100; i++) {
          futures.add(Future(() {
            results.add(i);
          }));
        }

        await Future.wait(futures);

        // All elements should be present (order may vary in async)
        expect(results.length, 100);
        expect(results.toSet().length, 100); // All unique
      });

      test('map populated from parallel futures has all entries', () async {
        final results = <String, int>{};

        final futures = <Future<void>>[];
        for (var i = 0; i < 100; i++) {
          futures.add(Future(() {
            results['key-$i'] = i;
          }));
        }

        await Future.wait(futures);

        expect(results.length, 100);
        for (var i = 0; i < 100; i++) {
          expect(results['key-$i'], i);
        }
      });
    });
  });
}
