/// Input Fuzzing Tests - "PROSECUTOR MODE"
///
/// These tests actively try to break the app by feeding malicious inputs
/// to models and parsers. The goal is to ensure the app handles bad data
/// gracefully without crashing or exposing security vulnerabilities.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/core/models/streak_event.dart';
import 'package:silni_app/core/models/relative_streak_model.dart';
import 'package:silni_app/core/models/streak_freeze_model.dart';
import 'package:silni_app/shared/models/interaction_model.dart';
import 'package:silni_app/shared/models/relative_model.dart';

import 'adversarial_test_harness.dart';

void main() {
  group('Input Fuzzing Tests - PROSECUTOR MODE', () {
    // =========================================================================
    // RELATIVE MODEL FUZZING
    // =========================================================================

    group('Relative Model Fuzzing', () {
      test('survives SQL injection in fullName field', () {
        for (final injection in MaliciousInputs.sqlInjection) {
          // Should not throw - just store the string as-is
          final relative = Relative(
            id: 'test-id',
            userId: 'test-user',
            fullName: injection,
            relationshipType: RelationshipType.other,
            createdAt: DateTime.now(),
          );

          // Model should accept the input without crashing
          expect(relative.fullName, injection);

          // toJson should not crash
          expect(() => relative.toJson(), returnsNormally);

          // The JSON should contain the exact input (not executed)
          final json = relative.toJson();
          expect(json['full_name'], injection);
        }
      });

      test('survives XSS payloads in all string fields', () {
        for (final xss in MaliciousInputs.xssPayloads) {
          final relative = Relative(
            id: xss,
            userId: xss,
            fullName: xss,
            relationshipType: RelationshipType.other,
            phoneNumber: xss,
            email: xss,
            address: xss,
            city: xss,
            country: xss,
            notes: xss,
            islamicImportance: xss,
            preferredContactMethod: xss,
            bestTimeToContact: xss,
            healthStatus: xss,
            contactId: xss,
            createdAt: DateTime.now(),
          );

          // Should store XSS as plain text, not execute it
          expect(relative.fullName, xss);
          expect(relative.notes, xss);
          expect(() => relative.toJson(), returnsNormally);
        }
      });

      test('survives unicode edge cases in name field', () {
        for (final unicode in MaliciousInputs.unicodeEdgeCases) {
          final relative = Relative(
            id: 'test-id',
            userId: 'test-user',
            fullName: unicode,
            relationshipType: RelationshipType.other,
            createdAt: DateTime.now(),
          );

          expect(relative.fullName, unicode);
          expect(() => relative.toJson(), returnsNormally);
        }
      });

      test('survives extreme length strings', () {
        // Test with increasingly long strings
        final lengths = [0, 1, 100, 1000, 10000, 100000];

        for (final length in lengths) {
          final longString = MaliciousInputs.veryLong(length);

          final relative = Relative(
            id: 'test-id',
            userId: 'test-user',
            fullName: longString,
            relationshipType: RelationshipType.other,
            notes: longString,
            createdAt: DateTime.now(),
          );

          expect(relative.fullName.length, length);
          expect(() => relative.toJson(), returnsNormally);
        }
      });

      test('survives special characters in all fields', () {
        for (final special in MaliciousInputs.specialCharacters) {
          final relative = Relative(
            id: 'test-id',
            userId: 'test-user',
            fullName: special,
            relationshipType: RelationshipType.other,
            notes: special,
            address: special,
            createdAt: DateTime.now(),
          );

          expect(relative.fullName, special);
          expect(() => relative.toJson(), returnsNormally);
        }
      });

      test('fromJson handles missing required fields gracefully', () {
        // Completely empty JSON - should use defaults
        final emptyRelative = Relative.fromJson({});
        expect(emptyRelative.id, '');
        expect(emptyRelative.userId, '');
        expect(emptyRelative.fullName, '');
        expect(emptyRelative.relationshipType, RelationshipType.other);
      });

      test('fromJson handles null values in required fields', () {
        final nullJson = {
          'id': null,
          'user_id': null,
          'full_name': null,
          'relationship_type': null,
          'created_at': null,
        };

        final relative = Relative.fromJson(nullJson);
        expect(relative.id, '');
        expect(relative.userId, '');
        expect(relative.fullName, '');
        expect(relative.relationshipType, RelationshipType.other);
      });

      test('fromJson handles wrong types gracefully', () {
        // This tests type coercion resilience
        final wrongTypes = {
          'id': 12345, // Should be string
          'user_id': true, // Should be string
          'full_name': ['array', 'of', 'strings'], // Should be string
          'relationship_type': 999, // Should be string
          'priority': 'high', // Should be int
          'interaction_count': 'many', // Should be int
          'is_archived': 'yes', // Should be bool
          'is_favorite': 1, // Should be bool
          'created_at': 12345, // Should be string date
        };

        // This may throw or handle gracefully - both are acceptable
        // The key is it shouldn't cause undefined behavior
        try {
          final relative = Relative.fromJson(wrongTypes);
          // If it succeeds, verify it didn't crash
          expect(relative, isNotNull);
        } catch (e) {
          // Type errors are acceptable - they indicate proper type checking
          expect(e, isA<TypeError>());
        }
      });

      test('fromJson handles malicious JSON structures', () {
        // Deeply nested structure
        final deeplyNested = {
          'id': 'test',
          'user_id': 'test',
          'full_name': 'test',
          'relationship_type': 'other',
          'notes': {
            'level1': {
              'level2': {
                'level3': {
                  'level4': {'level5': 'deep'},
                },
              },
            },
          },
        };

        // This should handle the map gracefully (likely as null or error)
        try {
          final relative = Relative.fromJson(deeplyNested);
          // notes field expects String?, so map should be converted or ignored
          expect(relative.notes, anyOf(isNull, isA<String>()));
        } catch (e) {
          // Type error is acceptable
          expect(e, isA<TypeError>());
        }
      });

      test('handles corrupted list fields', () {
        final corruptedLists = {
          'id': 'test',
          'user_id': 'test',
          'full_name': 'test',
          'relationship_type': 'other',
          'interests': 'not a list', // Should be List<String>?
          'favorite_colors': 12345, // Should be List<String>?
          'sensitive_topics': {'key': 'value'}, // Should be List<String>?
        };

        try {
          final relative = Relative.fromJson(corruptedLists);
          // Should handle gracefully
          expect(relative, isNotNull);
        } catch (e) {
          // Type errors are acceptable
          expect(e, anyOf(isA<TypeError>(), isA<FormatException>()));
        }
      });

      test('RelationshipType.fromString handles invalid values', () {
        final invalidTypes = [
          '',
          'invalid',
          'FATHER', // Wrong case
          'Father',
          'father123',
          "father'; DROP TABLE--",
          '<script>alert("xss")</script>',
          null.toString(),
          '   father   ', // Whitespace
        ];

        for (final invalidType in invalidTypes) {
          // Should default to 'other' rather than crash
          final type = RelationshipType.fromString(invalidType);
          expect(type, RelationshipType.other);
        }
      });

      test('Gender.fromString handles invalid values', () {
        final invalidGenders = [
          '',
          'invalid',
          'MALE',
          'Male',
          'male123',
          '<script>',
        ];

        for (final invalid in invalidGenders) {
          // Unknown values should return null (not silent default)
          final gender = Gender.fromString(invalid);
          expect(gender, isNull);
        }
      });

      test('AvatarType.fromString handles invalid values', () {
        final invalidAvatars = [
          '',
          'invalid',
          'ADULT_MAN',
          'adult man',
          'adult_man123',
        ];

        for (final invalid in invalidAvatars) {
          final avatar = AvatarType.fromString(invalid);
          expect(avatar, AvatarType.adultMan); // Default
        }
      });
    });

    // =========================================================================
    // INTERACTION MODEL FUZZING
    // =========================================================================

    group('Interaction Model Fuzzing', () {
      test('survives SQL injection in notes field', () {
        for (final injection in MaliciousInputs.sqlInjection) {
          final interaction = Interaction(
            id: 'test-id',
            userId: 'test-user',
            relativeId: 'test-relative',
            type: InteractionType.call,
            date: DateTime.now(),
            notes: injection,
            createdAt: DateTime.now(),
          );

          expect(interaction.notes, injection);
          expect(() => interaction.toJson(), returnsNormally);
        }
      });

      test('survives XSS in location and mood fields', () {
        for (final xss in MaliciousInputs.xssPayloads) {
          final interaction = Interaction(
            id: 'test-id',
            userId: 'test-user',
            relativeId: 'test-relative',
            type: InteractionType.visit,
            date: DateTime.now(),
            location: xss,
            mood: xss,
            notes: xss,
            createdAt: DateTime.now(),
          );

          expect(interaction.location, xss);
          expect(interaction.mood, xss);
          expect(() => interaction.toJson(), returnsNormally);
        }
      });

      test('InteractionType.fromString handles invalid values', () {
        final invalidTypes = [
          '',
          'invalid',
          'CALL',
          'Call',
          'phone_call',
          "call'; DROP TABLE--",
          '\x00call',
        ];

        for (final invalid in invalidTypes) {
          final type = InteractionType.fromString(invalid);
          expect(type, InteractionType.other); // Should default to other
        }
      });

      test('handles invalid duration values', () {
        // Test with dangerous numbers
        for (final num in MaliciousInputs.dangerousNumbers) {
          if (num is int) {
            final interaction = Interaction(
              id: 'test-id',
              userId: 'test-user',
              relativeId: 'test-relative',
              type: InteractionType.call,
              date: DateTime.now(),
              duration: num,
              createdAt: DateTime.now(),
            );

            expect(interaction.duration, num);
            // formattedDuration should not crash
            expect(() => interaction.formattedDuration, returnsNormally);
          }
        }
      });

      test('handles invalid rating values', () {
        final invalidRatings = [-1, 0, 6, 100, -100, 2147483647, -2147483648];

        for (final rating in invalidRatings) {
          final interaction = Interaction(
            id: 'test-id',
            userId: 'test-user',
            relativeId: 'test-relative',
            type: InteractionType.call,
            date: DateTime.now(),
            rating: rating,
            createdAt: DateTime.now(),
          );

          // Should store the value even if invalid (validation is UI's job)
          expect(interaction.rating, rating);
        }
      });

      test('handles photoUrls with malicious URLs', () {
        final maliciousUrls = [
          'javascript:alert("xss")',
          'data:text/html,<script>alert("xss")</script>',
          'file:///etc/passwd',
          '../../../etc/passwd',
          'http://evil.com/"><script>alert("xss")</script>',
          '',
          ' ',
          'not-a-url',
        ];

        final interaction = Interaction(
          id: 'test-id',
          userId: 'test-user',
          relativeId: 'test-relative',
          type: InteractionType.visit,
          date: DateTime.now(),
          photoUrls: maliciousUrls,
          createdAt: DateTime.now(),
        );

        expect(interaction.photoUrls, maliciousUrls);
        expect(() => interaction.toJson(), returnsNormally);
      });

      test('fromJson handles corrupted date strings', () {
        for (final invalidDate in MaliciousDates.invalidDateStrings) {
          final json = {
            'id': 'test',
            'user_id': 'test',
            'relative_id': 'test',
            'type': 'call',
            'date': invalidDate,
            'created_at': invalidDate,
          };

          try {
            final interaction = Interaction.fromJson(json);
            // If it succeeds, dates should be fallback values
            expect(interaction, isNotNull);
          } catch (e) {
            // FormatException is acceptable for invalid dates
            expect(e, isA<FormatException>());
          }
        }
      });

      test('relativeTime handles extreme dates', () {
        for (final extremeDate in MaliciousDates.extremeDates) {
          final interaction = Interaction(
            id: 'test-id',
            userId: 'test-user',
            relativeId: 'test-relative',
            type: InteractionType.call,
            date: extremeDate,
            createdAt: DateTime.now(),
          );

          // relativeTime should not crash, even with extreme dates
          expect(() => interaction.relativeTime, returnsNormally);
          expect(interaction.relativeTime, isA<String>());
        }
      });
    });

    // =========================================================================
    // RELATIVE STREAK MODEL FUZZING
    // =========================================================================

    group('RelativeStreak Model Fuzzing', () {
      test('survives malicious IDs', () {
        for (final malicious in MaliciousInputs.sqlInjection) {
          final streak = RelativeStreak(
            id: malicious,
            userId: malicious,
            relativeId: malicious,
            currentStreak: 5,
            longestStreak: 10,
            createdAt: DateTime.now(),
          );

          expect(streak.id, malicious);
          expect(() => streak.toJson(), returnsNormally);
        }
      });

      test('handles extreme streak values', () {
        final extremeStreaks = [
          0,
          -1,
          -100,
          1,
          7,
          30,
          100,
          365,
          1000,
          10000,
          2147483647, // Max int32
          -2147483648, // Min int32
        ];

        for (final streakValue in extremeStreaks) {
          final streak = RelativeStreak(
            id: 'test',
            userId: 'test',
            relativeId: 'test',
            currentStreak: streakValue,
            longestStreak: streakValue,
            createdAt: DateTime.now(),
          );

          expect(streak.currentStreak, streakValue);
          expect(streak.longestStreak, streakValue);
          expect(() => streak.warningState, returnsNormally);
          expect(() => streak.isEndangered, returnsNormally);
        }
      });

      test('handles extreme deadline dates', () {
        for (final extremeDate in MaliciousDates.extremeDates) {
          final streak = RelativeStreak(
            id: 'test',
            userId: 'test',
            relativeId: 'test',
            currentStreak: 5,
            longestStreak: 10,
            streakDeadline: extremeDate,
            createdAt: DateTime.now(),
          );

          // These should not crash
          expect(() => streak.timeRemaining, returnsNormally);
          expect(() => streak.warningState, returnsNormally);
          expect(() => streak.isEndangered, returnsNormally);
          expect(() => streak.formattedTimeRemaining, returnsNormally);
        }
      });

      test('fromJson handles corrupted data', () {
        final corruptedJsons = <Map<String, dynamic>>[
          {}, // Empty
          {'id': null, 'user_id': null, 'relative_id': null},
          {'id': 123, 'user_id': true, 'relative_id': <String>[]},
          {
            'id': 'test',
            'user_id': 'test',
            'relative_id': 'test',
            'current_streak': 'many',
            'longest_streak': 'lots',
          },
          {
            'id': 'test',
            'user_id': 'test',
            'relative_id': 'test',
            'streak_deadline': 'not-a-date',
          },
        ];

        for (final json in corruptedJsons) {
          try {
            final streak = RelativeStreak.fromJson(json);
            expect(streak, isNotNull);
          } catch (e) {
            // Type errors are acceptable
            expect(e, anyOf(isA<TypeError>(), isA<FormatException>()));
          }
        }
      });

      test('StreakWarningState enum is exhaustive', () {
        // Ensure all states are handled
        for (final state in StreakWarningState.values) {
          expect(state.toString(), isNotEmpty);
        }
      });
    });

    // =========================================================================
    // FREEZE INVENTORY MODEL FUZZING
    // =========================================================================

    group('FreezeInventory Model Fuzzing', () {
      test('handles extreme freeze counts', () {
        final extremeCounts = [0, -1, 1, 100, 1000, 2147483647, -2147483648];

        for (final count in extremeCounts) {
          final inventory = FreezeInventory(
            id: 'test',
            userId: 'test',
            freezeCount: count,
            freezesUsedTotal: count,
            createdAt: DateTime.now(),
          );

          expect(inventory.freezeCount, count);
          expect(() => inventory.hasFreeze, returnsNormally);
        }
      });

      test('FreezeType.fromString handles invalid values', () {
        final invalidTypes = [
          '',
          'invalid',
          'EARNED',
          'Earned',
          "earned'; DROP TABLE--",
        ];

        for (final invalid in invalidTypes) {
          final type = FreezeType.fromString(invalid);
          expect(type, FreezeType.earned); // Should default
        }
      });
    });

    // =========================================================================
    // STREAK EVENT FUZZING
    // =========================================================================

    group('StreakEvent Model Fuzzing', () {
      test('survives malicious data in events', () {
        for (final malicious in MaliciousInputs.sqlInjection) {
          final event = StreakEvent(
            type: StreakEventType.streakIncreased,
            userId: malicious,
            data: {
              'current_streak': 10,
              'longest_streak': 10,
              'extra': malicious,
            },
          );

          expect(event.userId, malicious);
          expect(event.data['extra'], malicious);
        }
      });

      test('isStreakMilestone handles edge cases', () {
        // Test all milestone values
        final milestones = [3, 7, 10, 14, 21, 30, 50, 100, 200, 365, 500];
        for (final milestone in milestones) {
          expect(StreakEvent.isStreakMilestone(milestone), isTrue);
        }

        // Test non-milestones
        final nonMilestones = [0, 1, 2, 4, 5, 6, 8, 9, 11, 99, 101, 999];
        for (final nonMilestone in nonMilestones) {
          expect(StreakEvent.isStreakMilestone(nonMilestone), isFalse);
        }

        // Test negative values
        expect(StreakEvent.isStreakMilestone(-1), isFalse);
        expect(StreakEvent.isStreakMilestone(-7), isFalse);
      });
    });

    // =========================================================================
    // JSON PARSING FUZZING
    // =========================================================================

    group('JSON Parsing Fuzzing', () {
      test('models survive corrupted JSON strings', () {
        final corruptedJsonStrings = [
          '', // Empty
          'null',
          'undefined',
          '[]', // Array instead of object
          '{"unclosed": "bracket"',
          '{"key": undefined}',
          '{"key": NaN}',
          '{"key": Infinity}',
          '{key: "unquoted"}',
          "{'single': 'quotes'}",
          '{"nested": {"deep": {"deeper": {"deepest": null}}}}',
          '{"array": [1, 2, 3, null, "mixed"]}',
          '{"unicode": "\\u0000\\u001f\\u007f"}',
          '{"escape": "\\n\\r\\t\\\\"}',
        ];

        for (final jsonString in corruptedJsonStrings) {
          try {
            final decoded = jsonDecode(jsonString);
            if (decoded is Map<String, dynamic>) {
              // Try to parse as Relative
              try {
                Relative.fromJson(decoded);
              } catch (e) {
                // Expected for most corrupted data
              }
            }
          } catch (e) {
            // JSON decode failure is expected for invalid JSON
            expect(e, isA<FormatException>());
          }
        }
      });

      test('state chaos generates survivable maps', () {
        // Test that StateChaos generates maps that models can attempt to parse
        for (var i = 0; i < 10; i++) {
          final chaosMap = StateChaos.randomChaosMap();

          // Should not crash, even if parsing fails
          try {
            Relative.fromJson(chaosMap);
          } catch (e) {
            // Errors are expected
          }

          try {
            Interaction.fromJson(chaosMap);
          } catch (e) {
            // Errors are expected
          }
        }
      });

      test('corrupted maps do not cause infinite loops', () {
        // Ensure corrupted data doesn't hang the app
        final startTime = DateTime.now();
        final timeout = const Duration(seconds: 5);

        for (var i = 0; i < 100; i++) {
          final corrupted = StateChaos.corruptMap({
            'id': 'test',
            'user_id': 'test',
            'full_name': 'test',
            'relationship_type': 'other',
            'created_at': DateTime.now().toIso8601String(),
          });

          try {
            Relative.fromJson(corrupted);
          } catch (e) {
            // Errors are fine
          }

          // Check we haven't timed out
          if (DateTime.now().difference(startTime) > timeout) {
            fail('Parsing corrupted data took too long - possible infinite loop');
          }
        }
      });
    });

    // =========================================================================
    // FUZZ TEST HELPER VERIFICATION
    // =========================================================================

    group('Fuzz Test Helper', () {
      test('fuzzTest captures all results correctly', () async {
        final result = await fuzzTest<String>(
          name: 'test fuzz',
          inputs: ['valid', '', null, 123],
          testFunction: (input) {
            if (input == null) throw ArgumentError('null not allowed');
            if (input is! String) throw TypeError();
            return input.toUpperCase();
          },
        );

        expect(result.totalTests, 4);
        expect(result.successCount, 2); // 'valid' and ''
        expect(result.failureCount, 2); // null and 123
      });

      test('MaliciousInputs.fuzz generates varied outputs', () {
        const validInput = 'normal_input';
        final fuzzedInputs = <String>{};

        // Generate many fuzzed inputs
        for (var i = 0; i < 100; i++) {
          fuzzedInputs.add(MaliciousInputs.fuzz(validInput));
        }

        // Should have variety (not all the same)
        expect(fuzzedInputs.length, greaterThan(5));
      });

      test('MaliciousInputs.randomMalicious returns varied inputs', () {
        final randomInputs = <String>{};

        for (var i = 0; i < 100; i++) {
          randomInputs.add(MaliciousInputs.randomMalicious());
        }

        // Should have significant variety
        expect(randomInputs.length, greaterThan(20));
      });

      test('NetworkChaos generates all failure types', () {
        final seenFailures = <NetworkFailure>{};

        // Should eventually see all failure types with enough iterations
        for (var i = 0; i < 1000; i++) {
          seenFailures.add(NetworkChaos.randomFailure());
        }

        // Should have seen most failure types
        expect(seenFailures.length, greaterThan(NetworkChaos.failures.length ~/ 2));
      });
    });
  });
}
