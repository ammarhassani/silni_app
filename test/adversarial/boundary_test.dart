/// Boundary Tests - "PROSECUTOR MODE"
///
/// These tests target boundary conditions, edge cases, and extreme values
/// that are often the source of bugs. Tests include empty lists, null handling,
/// maximum/minimum values, and integer overflow scenarios.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/core/models/gamification_event.dart';
import 'package:silni_app/core/models/relative_streak_model.dart';
import 'package:silni_app/core/models/streak_freeze_model.dart';
import 'package:silni_app/shared/models/interaction_model.dart';
import 'package:silni_app/shared/models/relative_model.dart';

import 'adversarial_test_harness.dart';

void main() {
  group('Boundary Tests - PROSECUTOR MODE', () {
    // =========================================================================
    // EMPTY LIST TESTS
    // =========================================================================

    group('Empty List Handling', () {
      test('Relative handles empty interests list', () {
        final relative = Relative(
          id: 'test',
          userId: 'test',
          fullName: 'Test',
          relationshipType: RelationshipType.other,
          createdAt: DateTime.now(),
          interests: [],
        );

        expect(relative.interests, isEmpty);
        expect(() => relative.toJson(), returnsNormally);
        final json = relative.toJson();
        expect(json['interests'], isEmpty);
      });

      test('Relative handles empty favoriteColors list', () {
        final relative = Relative(
          id: 'test',
          userId: 'test',
          fullName: 'Test',
          relationshipType: RelationshipType.other,
          createdAt: DateTime.now(),
          favoriteColors: [],
          favoriteFoods: [],
          dislikedGifts: [],
          wishlist: [],
          sensitiveTopics: [],
        );

        expect(relative.favoriteColors, isEmpty);
        expect(relative.favoriteFoods, isEmpty);
        expect(relative.dislikedGifts, isEmpty);
        expect(relative.wishlist, isEmpty);
        expect(relative.sensitiveTopics, isEmpty);
      });

      test('Interaction handles empty photoUrls list', () {
        final interaction = Interaction(
          id: 'test',
          userId: 'test',
          relativeId: 'test',
          type: InteractionType.call,
          date: DateTime.now(),
          photoUrls: [],
          createdAt: DateTime.now(),
        );

        expect(interaction.photoUrls, isEmpty);
        expect(() => interaction.toJson(), returnsNormally);
      });

      test('fromJson handles empty arrays correctly', () {
        final json = {
          'id': 'test',
          'user_id': 'test',
          'full_name': 'Test',
          'relationship_type': 'other',
          'created_at': DateTime.now().toIso8601String(),
          'interests': <String>[],
          'favorite_colors': <String>[],
        };

        final relative = Relative.fromJson(json);
        expect(relative.interests, isEmpty);
        expect(relative.favoriteColors, isEmpty);
      });
    });

    // =========================================================================
    // NULL VALUE TESTS
    // =========================================================================

    group('Null Value Handling', () {
      test('Relative handles all nullable fields as null', () {
        final relative = Relative(
          id: 'test',
          userId: 'test',
          fullName: 'Test',
          relationshipType: RelationshipType.other,
          createdAt: DateTime.now(),
          // All nullable fields explicitly null
          gender: null,
          avatarType: null,
          dateOfBirth: null,
          phoneNumber: null,
          email: null,
          address: null,
          city: null,
          country: null,
          photoUrl: null,
          notes: null,
          islamicImportance: null,
          preferredContactMethod: null,
          bestTimeToContact: null,
          lastContactDate: null,
          healthStatus: null,
          contactId: null,
          updatedAt: null,
          interests: null,
          favoriteColors: null,
          favoriteFoods: null,
          clothingSize: null,
          giftBudget: null,
          dislikedGifts: null,
          wishlist: null,
          personalityType: null,
          communicationStyle: null,
          sensitiveTopics: null,
          relationshipChallenges: null,
          relationshipStrengths: null,
          aiNotes: null,
          emotionalCloseness: null,
          communicationQuality: null,
          conflictHistory: null,
          supportLevel: null,
          lastMeaningfulInteraction: null,
        );

        // Should not crash when accessing null fields
        expect(relative.gender, isNull);
        expect(relative.dateOfBirth, isNull);
        expect(relative.daysSinceLastContact, isNull);
        expect(relative.healthScore, isNull);
        expect(() => relative.toJson(), returnsNormally);

        // displayEmoji should have fallback
        expect(relative.displayEmoji, isNotEmpty);

        // needsContact should handle null lastContactDate
        expect(relative.needsContact, isTrue);
      });

      test('Interaction handles all nullable fields as null', () {
        final interaction = Interaction(
          id: 'test',
          userId: 'test',
          relativeId: 'test',
          type: InteractionType.call,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          duration: null,
          location: null,
          notes: null,
          mood: null,
          rating: null,
          updatedAt: null,
        );

        expect(interaction.duration, isNull);
        expect(interaction.formattedDuration, isEmpty);
        expect(() => interaction.toJson(), returnsNormally);
      });

      test('RelativeStreak handles null deadline gracefully', () {
        final streak = RelativeStreak(
          id: 'test',
          userId: 'test',
          relativeId: 'test',
          currentStreak: 5,
          longestStreak: 10,
          streakDeadline: null,
          streakDayStart: null,
          createdAt: DateTime.now(),
          updatedAt: null,
        );

        expect(streak.streakDeadline, isNull);
        expect(streak.timeRemaining, isNull);
        expect(streak.isEndangered, isFalse);
        expect(streak.warningState, StreakWarningState.safe);
        expect(streak.formattedTimeRemaining, isEmpty);
      });

      test('fromJson handles explicit null values', () {
        final jsonWithNulls = {
          'id': 'test',
          'user_id': 'test',
          'full_name': 'Test',
          'relationship_type': 'other',
          'created_at': DateTime.now().toIso8601String(),
          'gender': null,
          'avatar_type': null,
          'date_of_birth': null,
          'phone_number': null,
          'notes': null,
          'interests': null,
        };

        final relative = Relative.fromJson(jsonWithNulls);
        // Note: Gender.fromString returns null for null input
        expect(relative.gender, isNull);
        // Note: AvatarType.fromString defaults to adultMan for null input
        // This is intentional behavior - the model provides a default avatar
        expect(relative.avatarType, AvatarType.adultMan);
        expect(relative.dateOfBirth, isNull);
        expect(relative.interests, isNull);
      });
    });

    // =========================================================================
    // MAXIMUM/MINIMUM VALUE TESTS
    // =========================================================================

    group('Maximum/Minimum Value Handling', () {
      test('Relative handles extreme priority values', () {
        for (final priority in BoundaryValues.priorities) {
          final relative = Relative(
            id: 'test',
            userId: 'test',
            fullName: 'Test',
            relationshipType: RelationshipType.other,
            priority: priority,
            createdAt: DateTime.now(),
          );

          expect(relative.priority, priority);
          expect(() => relative.needsContact, returnsNormally);
          expect(() => relative.toJson(), returnsNormally);
        }
      });

      test('Relative handles extreme interactionCount values', () {
        final extremeCounts = [0, 1, 100, 10000, 2147483647, -1, -100];

        for (final count in extremeCounts) {
          final relative = Relative(
            id: 'test',
            userId: 'test',
            fullName: 'Test',
            relationshipType: RelationshipType.other,
            interactionCount: count,
            createdAt: DateTime.now(),
          );

          expect(relative.interactionCount, count);
          expect(() => relative.toJson(), returnsNormally);
        }
      });

      test('Relative handles extreme AI score values', () {
        final extremeScores = [-100, -1, 0, 1, 3, 5, 6, 100, 2147483647];

        for (final score in extremeScores) {
          final relative = Relative(
            id: 'test',
            userId: 'test',
            fullName: 'Test',
            relationshipType: RelationshipType.other,
            createdAt: DateTime.now(),
            emotionalCloseness: score,
            communicationQuality: score,
            supportLevel: score,
          );

          // healthScore calculation should not crash
          expect(() => relative.healthScore, returnsNormally);
          expect(() => relative.healthStatus2, returnsNormally);
        }
      });

      test('Interaction handles extreme duration values', () {
        for (final duration in BoundaryValues.durations) {
          final interaction = Interaction(
            id: 'test',
            userId: 'test',
            relativeId: 'test',
            type: InteractionType.call,
            date: DateTime.now(),
            duration: duration,
            createdAt: DateTime.now(),
          );

          expect(interaction.duration, duration);
          expect(() => interaction.formattedDuration, returnsNormally);
          expect(() => interaction.toJson(), returnsNormally);
        }
      });

      test('Interaction handles extreme rating values', () {
        for (final rating in BoundaryValues.ratings) {
          final interaction = Interaction(
            id: 'test',
            userId: 'test',
            relativeId: 'test',
            type: InteractionType.call,
            date: DateTime.now(),
            rating: rating,
            createdAt: DateTime.now(),
          );

          expect(interaction.rating, rating);
          expect(() => interaction.toJson(), returnsNormally);
        }
      });

      test('RelativeStreak handles extreme streak values', () {
        for (final streakValue in BoundaryValues.streaks) {
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
          expect(() => streak.toJson(), returnsNormally);
        }
      });

      test('FreezeInventory handles extreme freeze counts', () {
        final extremeCounts = [0, 1, 100, 1000, 2147483647, -1, -2147483648];

        for (final count in extremeCounts) {
          final inventory = FreezeInventory(
            id: 'test',
            userId: 'test',
            freezeCount: count,
            freezesUsedTotal: count,
            createdAt: DateTime.now(),
          );

          expect(inventory.freezeCount, count);
          // hasFreeze should handle any value
          expect(() => inventory.hasFreeze, returnsNormally);
        }
      });

      test('GamificationEvent handles extreme point values', () {
        final extremePoints = [
          0,
          1,
          -1,
          100,
          -100,
          1000000,
          -1000000,
          2147483647,
          -2147483648,
        ];

        for (final points in extremePoints) {
          final event = GamificationEvent.pointsEarned(
            userId: 'test',
            points: points,
            source: 'test',
          );

          expect(event.points, points);
        }
      });

      test('GamificationEvent handles extreme XP values', () {
        final extremeXP = [0, 1, -1, 1000000, 2147483647, -2147483648];

        for (final xp in extremeXP) {
          final event = GamificationEvent.levelUp(
            userId: 'test',
            oldLevel: 1,
            newLevel: 2,
            currentXP: xp,
            xpToNextLevel: xp,
          );

          expect(event.currentXP, xp);
          expect(event.xpToNextLevel, xp);
        }
      });
    });

    // =========================================================================
    // INTEGER OVERFLOW TESTS
    // =========================================================================

    group('Integer Overflow Scenarios', () {
      test('Relative survives max int values', () {
        const maxInt = 2147483647;
        const minInt = -2147483648;

        final relative = Relative(
          id: 'test',
          userId: 'test',
          fullName: 'Test',
          relationshipType: RelationshipType.other,
          priority: maxInt,
          interactionCount: maxInt,
          emotionalCloseness: maxInt,
          communicationQuality: maxInt,
          supportLevel: maxInt,
          createdAt: DateTime.now(),
        );

        expect(relative.priority, maxInt);
        expect(relative.interactionCount, maxInt);

        // Test with min int
        final relativeMin = Relative(
          id: 'test',
          userId: 'test',
          fullName: 'Test',
          relationshipType: RelationshipType.other,
          priority: minInt,
          interactionCount: minInt,
          createdAt: DateTime.now(),
        );

        expect(relativeMin.priority, minInt);
        expect(relativeMin.interactionCount, minInt);
      });

      test('Interaction survives max duration', () {
        const maxInt = 2147483647;

        final interaction = Interaction(
          id: 'test',
          userId: 'test',
          relativeId: 'test',
          type: InteractionType.call,
          date: DateTime.now(),
          duration: maxInt,
          createdAt: DateTime.now(),
        );

        expect(interaction.duration, maxInt);
        // formattedDuration should handle large numbers
        expect(() => interaction.formattedDuration, returnsNormally);
        expect(interaction.formattedDuration, isNotEmpty);
      });

      test('RelativeStreak survives max streak values', () {
        const maxInt = 2147483647;
        const minInt = -2147483648;

        final streak = RelativeStreak(
          id: 'test',
          userId: 'test',
          relativeId: 'test',
          currentStreak: maxInt,
          longestStreak: maxInt,
          createdAt: DateTime.now(),
        );

        expect(streak.currentStreak, maxInt);
        expect(streak.longestStreak, maxInt);

        final streakMin = RelativeStreak(
          id: 'test',
          userId: 'test',
          relativeId: 'test',
          currentStreak: minInt,
          longestStreak: minInt,
          createdAt: DateTime.now(),
        );

        expect(streakMin.currentStreak, minInt);
      });

      test('fromJson handles numeric string overflow', () {
        // Test parsing very large numbers from JSON
        // Note: Using int32 max to avoid Dart compilation issues with large literals
        final jsonWithLargeNumbers = {
          'id': 'test',
          'user_id': 'test',
          'full_name': 'Test',
          'relationship_type': 'other',
          'created_at': DateTime.now().toIso8601String(),
          'priority': 2147483647, // int32 max
          'interaction_count': 2147483647, // int32 max
        };

        // This may succeed or fail depending on JSON parsing
        // The key is it shouldn't crash with an unhandled exception
        try {
          final relative = Relative.fromJson(jsonWithLargeNumbers);
          expect(relative, isNotNull);
          expect(relative.priority, 2147483647);
        } catch (e) {
          // Overflow errors are acceptable
          expect(e, anyOf(isA<TypeError>(), isA<FormatException>(), isA<RangeError>()));
        }
      });
    });

    // =========================================================================
    // DATE BOUNDARY TESTS
    // =========================================================================

    group('Date Boundary Handling', () {
      test('Relative handles extreme dates', () {
        for (final extremeDate in MaliciousDates.extremeDates) {
          final relative = Relative(
            id: 'test',
            userId: 'test',
            fullName: 'Test',
            relationshipType: RelationshipType.other,
            dateOfBirth: extremeDate,
            lastContactDate: extremeDate,
            lastMeaningfulInteraction: extremeDate,
            createdAt: extremeDate,
            updatedAt: extremeDate,
          );

          expect(() => relative.daysSinceLastContact, returnsNormally);
          expect(() => relative.needsContact, returnsNormally);
          expect(() => relative.toJson(), returnsNormally);
        }
      });

      test('Interaction handles extreme dates', () {
        for (final extremeDate in MaliciousDates.extremeDates) {
          final interaction = Interaction(
            id: 'test',
            userId: 'test',
            relativeId: 'test',
            type: InteractionType.call,
            date: extremeDate,
            createdAt: extremeDate,
            updatedAt: extremeDate,
          );

          expect(() => interaction.relativeTime, returnsNormally);
          expect(() => interaction.toJson(), returnsNormally);
        }
      });

      test('RelativeStreak handles extreme deadline dates', () {
        for (final extremeDate in MaliciousDates.extremeDates) {
          final streak = RelativeStreak(
            id: 'test',
            userId: 'test',
            relativeId: 'test',
            currentStreak: 5,
            longestStreak: 10,
            streakDeadline: extremeDate,
            streakDayStart: extremeDate,
            createdAt: extremeDate,
            updatedAt: extremeDate,
          );

          expect(() => streak.timeRemaining, returnsNormally);
          expect(() => streak.warningState, returnsNormally);
          expect(() => streak.isEndangered, returnsNormally);
          expect(() => streak.formattedTimeRemaining, returnsNormally);
          expect(() => streak.toJson(), returnsNormally);
        }
      });

      test('handles leap year dates', () {
        for (final leapDate in MaliciousDates.leapYearDates) {
          final relative = Relative(
            id: 'test',
            userId: 'test',
            fullName: 'Test',
            relationshipType: RelationshipType.other,
            dateOfBirth: leapDate,
            createdAt: leapDate,
          );

          expect(relative.dateOfBirth, leapDate);
          expect(() => relative.toJson(), returnsNormally);
        }
      });

      test('handles month boundary dates', () {
        for (final monthDate in MaliciousDates.monthBoundaryDates) {
          final interaction = Interaction(
            id: 'test',
            userId: 'test',
            relativeId: 'test',
            type: InteractionType.call,
            date: monthDate,
            createdAt: monthDate,
          );

          expect(interaction.date, monthDate);
          expect(() => interaction.relativeTime, returnsNormally);
        }
      });

      test('handles time boundary dates', () {
        for (final timeDate in MaliciousDates.timeBoundaryDates) {
          final interaction = Interaction(
            id: 'test',
            userId: 'test',
            relativeId: 'test',
            type: InteractionType.call,
            date: timeDate,
            createdAt: timeDate,
          );

          expect(interaction.date.hour, timeDate.hour);
          expect(interaction.date.minute, timeDate.minute);
        }
      });
    });

    // =========================================================================
    // STRING LENGTH BOUNDARY TESTS
    // =========================================================================

    group('String Length Boundary Handling', () {
      test('handles empty strings', () {
        final relative = Relative(
          id: '',
          userId: '',
          fullName: '',
          relationshipType: RelationshipType.other,
          phoneNumber: '',
          email: '',
          address: '',
          city: '',
          country: '',
          notes: '',
          createdAt: DateTime.now(),
        );

        expect(relative.id, isEmpty);
        expect(relative.fullName, isEmpty);
        expect(() => relative.toJson(), returnsNormally);
      });

      test('handles single character strings', () {
        final relative = Relative(
          id: 'a',
          userId: 'b',
          fullName: 'c',
          relationshipType: RelationshipType.other,
          phoneNumber: '1',
          notes: 'x',
          createdAt: DateTime.now(),
        );

        expect(relative.id, 'a');
        expect(relative.fullName, 'c');
        expect(() => relative.toJson(), returnsNormally);
      });

      test('handles VARCHAR boundary (255 chars)', () {
        final maxVarchar = 'a' * 255;

        final relative = Relative(
          id: maxVarchar,
          userId: maxVarchar,
          fullName: maxVarchar,
          relationshipType: RelationshipType.other,
          phoneNumber: maxVarchar,
          email: maxVarchar,
          notes: maxVarchar,
          createdAt: DateTime.now(),
        );

        expect(relative.fullName.length, 255);
        expect(() => relative.toJson(), returnsNormally);
      });

      test('handles TEXT boundary (65535 chars)', () {
        final maxText = 'a' * 65535;

        final relative = Relative(
          id: 'test',
          userId: 'test',
          fullName: 'Test',
          relationshipType: RelationshipType.other,
          notes: maxText,
          createdAt: DateTime.now(),
        );

        expect(relative.notes?.length, 65535);
        expect(() => relative.toJson(), returnsNormally);
      });

      test('handles very long strings (1MB)', () {
        final megaString = 'a' * 1000000;

        final relative = Relative(
          id: 'test',
          userId: 'test',
          fullName: 'Test',
          relationshipType: RelationshipType.other,
          notes: megaString,
          createdAt: DateTime.now(),
        );

        expect(relative.notes?.length, 1000000);
        // Should not crash, though may be slow
        expect(() => relative.toJson(), returnsNormally);
      });
    });

    // =========================================================================
    // ENUM BOUNDARY TESTS
    // =========================================================================

    group('Enum Boundary Handling', () {
      test('all RelationshipType values are valid', () {
        for (final type in RelationshipType.values) {
          final relative = Relative(
            id: 'test',
            userId: 'test',
            fullName: 'Test',
            relationshipType: type,
            createdAt: DateTime.now(),
          );

          expect(relative.relationshipType, type);
          expect(type.value, isNotEmpty);
          expect(type.arabicName, isNotEmpty);
          expect(type.priority, inInclusiveRange(1, 3));

          // suggestPriority should return valid priority
          final suggestedPriority = AvatarType.suggestPriority(type);
          expect(suggestedPriority, inInclusiveRange(1, 3));
        }
      });

      test('all InteractionType values are valid', () {
        for (final type in InteractionType.values) {
          final interaction = Interaction(
            id: 'test',
            userId: 'test',
            relativeId: 'test',
            type: type,
            date: DateTime.now(),
            createdAt: DateTime.now(),
          );

          expect(interaction.type, type);
          expect(type.value, isNotEmpty);
          expect(type.arabicName, isNotEmpty);
          expect(type.emoji, isNotEmpty);
        }
      });

      test('all Gender values are valid', () {
        for (final gender in Gender.values) {
          expect(gender.value, isNotEmpty);
          expect(gender.arabicName, isNotEmpty);

          // fromString should round-trip
          final parsed = Gender.fromString(gender.value);
          expect(parsed, gender);
        }
      });

      test('all AvatarType values are valid', () {
        for (final avatar in AvatarType.values) {
          expect(avatar.value, isNotEmpty);
          expect(avatar.arabicName, isNotEmpty);
          expect(avatar.emoji, isNotEmpty);

          // fromString should round-trip
          final parsed = AvatarType.fromString(avatar.value);
          expect(parsed, avatar);
        }
      });

      test('all FreezeType values are valid', () {
        for (final type in FreezeType.values) {
          expect(type.value, isNotEmpty);
          expect(type.arabicName, isNotEmpty);

          // fromString should round-trip
          final parsed = FreezeType.fromString(type.value);
          expect(parsed, type);
        }
      });

      test('all GamificationEventType values are valid', () {
        for (final type in GamificationEventType.values) {
          // Should be able to create event with each type
          final event = GamificationEvent(
            type: type,
            userId: 'test',
            data: {},
          );

          expect(event.type, type);
        }
      });

      test('all StreakWarningState values are handled', () {
        // Test that warningState getter can return all values
        final states = <StreakWarningState>{};

        // Safe state (deadline null)
        var streak = RelativeStreak(
          id: 'test',
          userId: 'test',
          relativeId: 'test',
          currentStreak: 5,
          longestStreak: 10,
          streakDeadline: null,
          createdAt: DateTime.now(),
        );
        states.add(streak.warningState);
        expect(streak.warningState, StreakWarningState.safe);

        // Safe state (far future deadline)
        streak = RelativeStreak(
          id: 'test',
          userId: 'test',
          relativeId: 'test',
          currentStreak: 5,
          longestStreak: 10,
          streakDeadline: DateTime.now().add(const Duration(hours: 24)),
          createdAt: DateTime.now(),
        );
        states.add(streak.warningState);

        // Warning state (1-4 hours)
        streak = RelativeStreak(
          id: 'test',
          userId: 'test',
          relativeId: 'test',
          currentStreak: 5,
          longestStreak: 10,
          streakDeadline: DateTime.now().add(const Duration(hours: 2)),
          createdAt: DateTime.now(),
        );
        states.add(streak.warningState);
        expect(streak.warningState, StreakWarningState.warning);

        // Critical state (<1 hour)
        streak = RelativeStreak(
          id: 'test',
          userId: 'test',
          relativeId: 'test',
          currentStreak: 5,
          longestStreak: 10,
          streakDeadline: DateTime.now().add(const Duration(minutes: 30)),
          createdAt: DateTime.now(),
        );
        states.add(streak.warningState);
        expect(streak.warningState, StreakWarningState.critical);

        // Expired state (past deadline)
        streak = RelativeStreak(
          id: 'test',
          userId: 'test',
          relativeId: 'test',
          currentStreak: 5,
          longestStreak: 10,
          streakDeadline: DateTime.now().subtract(const Duration(hours: 1)),
          createdAt: DateTime.now(),
        );
        states.add(streak.warningState);
        expect(streak.warningState, StreakWarningState.expired);

        // Verify we've covered all states
        expect(states, containsAll(StreakWarningState.values));
      });

      test('all RelationshipHealthStatus values exist', () {
        for (final status in RelationshipHealthStatus.values) {
          expect(status.value, isNotEmpty);
          expect(status.arabicName, isNotEmpty);
          expect(status.emoji, isNotEmpty);
        }
      });
    });

    // =========================================================================
    // COPY WITH BOUNDARY TESTS
    // =========================================================================

    group('copyWith Boundary Handling', () {
      test('Relative.copyWith preserves original on null params', () {
        final original = Relative(
          id: 'original-id',
          userId: 'original-user',
          fullName: 'Original Name',
          relationshipType: RelationshipType.father,
          priority: 1,
          interactionCount: 100,
          createdAt: DateTime(2024, 1, 1),
        );

        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.userId, original.userId);
        expect(copy.fullName, original.fullName);
        expect(copy.relationshipType, original.relationshipType);
        expect(copy.priority, original.priority);
        expect(copy.interactionCount, original.interactionCount);
      });

      test('Relative.copyWith replaces specified values', () {
        final original = Relative(
          id: 'original-id',
          userId: 'original-user',
          fullName: 'Original Name',
          relationshipType: RelationshipType.father,
          priority: 1,
          createdAt: DateTime(2024, 1, 1),
        );

        final copy = original.copyWith(
          fullName: 'New Name',
          priority: 3,
        );

        expect(copy.id, original.id); // Unchanged
        expect(copy.fullName, 'New Name'); // Changed
        expect(copy.priority, 3); // Changed
      });

      test('Interaction.copyWith preserves original on null params', () {
        final original = Interaction(
          id: 'original-id',
          userId: 'original-user',
          relativeId: 'original-relative',
          type: InteractionType.call,
          date: DateTime(2024, 1, 1),
          duration: 60,
          notes: 'Original notes',
          createdAt: DateTime(2024, 1, 1),
        );

        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.type, original.type);
        expect(copy.duration, original.duration);
        expect(copy.notes, original.notes);
      });

      test('RelativeStreak.copyWith preserves original on null params', () {
        final original = RelativeStreak(
          id: 'original-id',
          userId: 'original-user',
          relativeId: 'original-relative',
          currentStreak: 10,
          longestStreak: 20,
          createdAt: DateTime(2024, 1, 1),
        );

        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.currentStreak, original.currentStreak);
        expect(copy.longestStreak, original.longestStreak);
      });

      test('FreezeInventory.copyWith preserves original on null params', () {
        final original = FreezeInventory(
          id: 'original-id',
          userId: 'original-user',
          freezeCount: 5,
          freezesUsedTotal: 10,
          createdAt: DateTime(2024, 1, 1),
        );

        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.freezeCount, original.freezeCount);
        expect(copy.freezesUsedTotal, original.freezesUsedTotal);
      });
    });

    // =========================================================================
    // JSON ROUND-TRIP TESTS
    // =========================================================================

    group('JSON Round-Trip Boundary Tests', () {
      test('Relative round-trips through JSON correctly', () {
        final original = Relative(
          id: 'test-id',
          userId: 'test-user',
          fullName: 'Test Name',
          relationshipType: RelationshipType.brother,
          gender: Gender.male,
          priority: 2,
          interactionCount: 50,
          isFavorite: true,
          isArchived: false,
          createdAt: DateTime(2024, 1, 15, 10, 30, 0),
          interests: ['coding', 'reading'],
        );

        final json = original.toJson();

        // Add id and created_at which are typically added by DB
        json['id'] = original.id;
        json['created_at'] = original.createdAt.toIso8601String();

        final restored = Relative.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.fullName, original.fullName);
        expect(restored.relationshipType, original.relationshipType);
        expect(restored.gender, original.gender);
        expect(restored.priority, original.priority);
        expect(restored.interactionCount, original.interactionCount);
        expect(restored.isFavorite, original.isFavorite);
        expect(restored.interests, original.interests);
      });

      test('Interaction round-trips through JSON correctly', () {
        final original = Interaction(
          id: 'test-id',
          userId: 'test-user',
          relativeId: 'test-relative',
          type: InteractionType.visit,
          date: DateTime(2024, 1, 15, 14, 0, 0),
          duration: 120,
          location: 'Home',
          notes: 'Great visit',
          mood: 'happy',
          rating: 5,
          isRecurring: true,
          photoUrls: ['photo1.jpg', 'photo2.jpg'],
          createdAt: DateTime(2024, 1, 15, 10, 30, 0),
        );

        final json = original.toJson();
        json['id'] = original.id;
        json['created_at'] = original.createdAt.toIso8601String();

        final restored = Interaction.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.type, original.type);
        expect(restored.duration, original.duration);
        expect(restored.location, original.location);
        expect(restored.notes, original.notes);
        expect(restored.rating, original.rating);
        expect(restored.isRecurring, original.isRecurring);
        expect(restored.photoUrls, original.photoUrls);
      });

      test('RelativeStreak round-trips through JSON correctly', () {
        final deadline = DateTime(2024, 1, 16, 12, 0, 0);
        final dayStart = DateTime(2024, 1, 15, 0, 0, 0);

        final original = RelativeStreak(
          id: 'test-id',
          userId: 'test-user',
          relativeId: 'test-relative',
          currentStreak: 7,
          longestStreak: 14,
          streakDeadline: deadline,
          streakDayStart: dayStart,
          createdAt: DateTime(2024, 1, 1),
        );

        final json = original.toJson();
        json['id'] = original.id;
        json['created_at'] = original.createdAt.toIso8601String();

        final restored = RelativeStreak.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.currentStreak, original.currentStreak);
        expect(restored.longestStreak, original.longestStreak);
        // DateTime comparison (may need tolerance for timezone handling)
        expect(restored.streakDeadline?.toUtc(), original.streakDeadline?.toUtc());
        expect(restored.streakDayStart?.toUtc(), original.streakDayStart?.toUtc());
      });
    });
  });
}
