import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/shared/models/interaction_model.dart';

import '../../helpers/test_helpers.dart';

/// Unit tests for InteractionsService logic
///
/// NOTE: These tests focus on the business logic that can be tested
/// independently of the Supabase client (data transformation, filtering, sorting).
///
/// LIMITATION: InteractionsService uses SupabaseConfig.client (singleton), which
/// makes it difficult to mock database operations without dependency injection.
///
/// For full integration testing of database operations, consider:
/// 1. Refactoring InteractionsService to accept SupabaseClient via constructor
/// 2. Using integration tests with a test Supabase instance
/// 3. Using a service locator pattern (e.g., GetIt) for dependency injection

void main() {
  group('InteractionsService Logic Tests', () {
    group('Data transformation tests', () {
      test('should correctly transform JSON to Interaction model', () {
        // Arrange
        final interactionData = createTestInteractionMap(
          id: 'interaction-123',
          userId: 'user-456',
          relativeId: 'relative-789',
          type: 'call',
        );

        // Act
        final interaction = Interaction.fromJson(interactionData);

        // Assert
        expect(interaction.id, 'interaction-123');
        expect(interaction.userId, 'user-456');
        expect(interaction.relativeId, 'relative-789');
        expect(interaction.type, InteractionType.call);
        expect(interaction.date, isA<DateTime>());
        expect(interaction.notes, 'Test interaction notes');
        expect(interaction.mood, 'positive');
        expect(interaction.rating, 5);
      });

      test('should correctly transform Interaction model to JSON', () {
        // Arrange
        final interactionData = createTestInteractionMap(
          id: 'test-id',
          userId: 'user-123',
          relativeId: 'relative-456',
          type: 'visit',
        );
        final interaction = Interaction.fromJson(interactionData);

        // Act
        final json = interaction.toJson();

        // Assert
        expect(json, isA<Map<String, dynamic>>());
        // Note: id, created_at, updated_at are not included in toJson()
        expect(json['user_id'], 'user-123');
        expect(json['relative_id'], 'relative-456');
        expect(json['interaction_type'], 'visit'); // enum.value returns string
        expect(json['notes'], 'Test interaction notes');
        expect(json.containsKey('interaction_date'), true);
      });

      test('should handle different interaction types correctly', () {
        // Arrange & Act
        final call = Interaction.fromJson(
            createTestInteractionMap(type: 'call'));
        final visit = Interaction.fromJson(
            createTestInteractionMap(type: 'visit'));
        final message = Interaction.fromJson(
            createTestInteractionMap(type: 'message'));
        final gift = Interaction.fromJson(
            createTestInteractionMap(type: 'gift'));
        final event = Interaction.fromJson(
            createTestInteractionMap(type: 'event'));
        final other = Interaction.fromJson(
            createTestInteractionMap(type: 'other'));

        // Assert
        expect(call.type, InteractionType.call);
        expect(visit.type, InteractionType.visit);
        expect(message.type, InteractionType.message);
        expect(gift.type, InteractionType.gift);
        expect(event.type, InteractionType.event);
        expect(other.type, InteractionType.other);
      });

      test('should handle null optional fields correctly', () {
        // Arrange
        final minimalData = {
          'id': 'test-id',
          'user_id': 'user-id',
          'relative_id': 'relative-id',
          'interaction_type': 'call',
          'interaction_date': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        };

        // Act
        final interaction = Interaction.fromJson(minimalData);
        final json = interaction.toJson();

        // Assert
        expect(interaction.duration, isNull);
        expect(interaction.location, isNull);
        expect(interaction.notes, isNull);
        expect(interaction.mood, isNull);
        expect(interaction.audioNoteUrl, isNull);
        expect(interaction.rating, isNull);
        expect(json['duration'], isNull);
        expect(json['location'], isNull);
      });
    });

    group('Client-side filtering logic tests', () {
      test('should filter interactions by user ID', () {
        // Arrange
        final allInteractions = [
          createTestInteractionMap(id: '1', userId: 'user-1'),
          createTestInteractionMap(id: '2', userId: 'user-2'),
          createTestInteractionMap(id: '3', userId: 'user-1'),
          createTestInteractionMap(id: '4', userId: 'user-3'),
        ];

        // Act - Simulate the filtering logic from getInteractionsStream
        final filtered = allInteractions
            .where((json) => json['user_id'] == 'user-1')
            .map((json) => Interaction.fromJson(json))
            .toList();

        // Assert
        expect(filtered.length, 2);
        expect(filtered.every((i) => i.userId == 'user-1'), true);
      });

      test('should filter interactions by relative ID', () {
        // Arrange
        final allInteractions = [
          createTestInteractionMap(id: '1', relativeId: 'relative-1'),
          createTestInteractionMap(id: '2', relativeId: 'relative-2'),
          createTestInteractionMap(id: '3', relativeId: 'relative-1'),
        ];

        // Act - Simulate filtering from getRelativeInteractionsStream
        final filtered = allInteractions
            .where((json) => json['relative_id'] == 'relative-1')
            .map((json) => Interaction.fromJson(json))
            .toList();

        // Assert
        expect(filtered.length, 2);
        expect(filtered.every((i) => i.relativeId == 'relative-1'), true);
      });

      test('should filter interactions by date range (today)', () {
        // Arrange
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));
        final tomorrow = today.add(const Duration(days: 1));

        final allInteractions = [
          createTestInteractionMap(id: '1')
            ..['interaction_date'] = today.add(const Duration(hours: 10)).toIso8601String(),
          createTestInteractionMap(id: '2')
            ..['interaction_date'] = yesterday.toIso8601String(),
          createTestInteractionMap(id: '3')
            ..['interaction_date'] = today.add(const Duration(hours: 14)).toIso8601String(),
          createTestInteractionMap(id: '4')
            ..['interaction_date'] = tomorrow.toIso8601String(),
        ];

        // Act - Simulate filtering for today's interactions
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final filtered = allInteractions
            .where((json) {
              final date = DateTime.parse(json['interaction_date'] as String);
              return date.isAfter(startOfDay) && date.isBefore(endOfDay);
            })
            .map((json) => Interaction.fromJson(json))
            .toList();

        // Assert
        expect(filtered.length, 2);
        expect(filtered[0].id, '1');
        expect(filtered[1].id, '3');
      });

      test('should filter interactions by user AND date range', () {
        // Arrange
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));

        final allInteractions = [
          createTestInteractionMap(id: '1', userId: 'user-1')
            ..['interaction_date'] = today.add(const Duration(hours: 10)).toIso8601String(),
          createTestInteractionMap(id: '2', userId: 'user-2')
            ..['interaction_date'] = today.add(const Duration(hours: 12)).toIso8601String(),
          createTestInteractionMap(id: '3', userId: 'user-1')
            ..['interaction_date'] = yesterday.toIso8601String(),
        ];

        // Act
        const userId = 'user-1';
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final filtered = allInteractions
            .where((json) {
              if (json['user_id'] != userId) return false;
              final date = DateTime.parse(json['interaction_date'] as String);
              return date.isAfter(startOfDay) && date.isBefore(endOfDay);
            })
            .map((json) => Interaction.fromJson(json))
            .toList();

        // Assert
        expect(filtered.length, 1);
        expect(filtered[0].id, '1');
        expect(filtered[0].userId, 'user-1');
      });

      test('should filter interactions by type', () {
        // Arrange
        final allInteractions = [
          createTestInteractionMap(type: 'call'),
          createTestInteractionMap(type: 'visit'),
          createTestInteractionMap(type: 'call'),
          createTestInteractionMap(type: 'message'),
        ];

        // Act
        final filtered = allInteractions
            .map((json) => Interaction.fromJson(json))
            .where((i) => i.type == InteractionType.call)
            .toList();

        // Assert
        expect(filtered.length, 2);
        expect(filtered.every((i) => i.type == InteractionType.call), true);
      });
    });

    group('Sorting logic tests', () {
      test('should sort interactions by date descending (most recent first)', () {
        // Arrange
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        final tomorrow = now.add(const Duration(days: 1));

        final interactions = [
          Interaction.fromJson(createTestInteractionMap(id: '1')
            ..['interaction_date'] = yesterday.toIso8601String()),
          Interaction.fromJson(createTestInteractionMap(id: '2')
            ..['interaction_date'] = tomorrow.toIso8601String()),
          Interaction.fromJson(createTestInteractionMap(id: '3')
            ..['interaction_date'] = now.toIso8601String()),
        ];

        // Act - Simulate sorting logic from getInteractionsStream
        interactions.sort((a, b) => b.date.compareTo(a.date));

        // Assert - Most recent first
        expect(interactions[0].id, '2'); // tomorrow
        expect(interactions[1].id, '3'); // now
        expect(interactions[2].id, '1'); // yesterday
      });

      test('should handle empty list gracefully', () {
        // Arrange
        final interactions = <Interaction>[];

        // Act
        interactions.sort((a, b) => b.date.compareTo(a.date));

        // Assert
        expect(interactions, isEmpty);
      });

      test('should handle single item list', () {
        // Arrange
        final interactions = [
          Interaction.fromJson(createTestInteractionMap()),
        ];

        // Act
        interactions.sort((a, b) => b.date.compareTo(a.date));

        // Assert
        expect(interactions.length, 1);
      });
    });

    group('Interaction counting logic tests', () {
      test('should count interactions by type correctly', () {
        // Arrange
        final interactions = [
          Interaction.fromJson(createTestInteractionMap(type: 'call')),
          Interaction.fromJson(createTestInteractionMap(type: 'call')),
          Interaction.fromJson(createTestInteractionMap(type: 'visit')),
          Interaction.fromJson(createTestInteractionMap(type: 'call')),
          Interaction.fromJson(createTestInteractionMap(type: 'message')),
          Interaction.fromJson(createTestInteractionMap(type: 'visit')),
        ];

        // Act - Simulate getInteractionCountsByType logic
        final Map<InteractionType, int> counts = {};
        for (final interaction in interactions) {
          counts[interaction.type] = (counts[interaction.type] ?? 0) + 1;
        }

        // Assert
        expect(counts[InteractionType.call], 3);
        expect(counts[InteractionType.visit], 2);
        expect(counts[InteractionType.message], 1);
        expect(counts[InteractionType.gift], isNull);
      });

      test('should count interactions in date range correctly', () {
        // Arrange
        final startDate = DateTime(2025, 1, 1);
        final endDate = DateTime(2025, 1, 31);

        final allInteractions = [
          createTestInteractionMap()
            ..['interaction_date'] = DateTime(2025, 1, 15).toIso8601String(),
          createTestInteractionMap()
            ..['interaction_date'] = DateTime(2025, 1, 20).toIso8601String(),
          createTestInteractionMap()
            ..['interaction_date'] = DateTime(2024, 12, 25).toIso8601String(),
          createTestInteractionMap()
            ..['interaction_date'] = DateTime(2025, 2, 5).toIso8601String(),
        ];

        // Act - Simulate counting logic
        final filtered = allInteractions
            .where((json) {
              final date = DateTime.parse(json['interaction_date'] as String);
              return (date.isAfter(startDate) || date.isAtSameMomentAs(startDate)) &&
                     (date.isBefore(endDate) || date.isAtSameMomentAs(endDate));
            })
            .toList();

        // Assert
        expect(filtered.length, 2);
      });

      test('should identify if user has interacted today', () {
        // Arrange
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));

        final todayInteractions = [
          createTestInteractionMap()
            ..['interaction_date'] = today.add(const Duration(hours: 10)).toIso8601String(),
        ];

        final yesterdayInteractions = [
          createTestInteractionMap()
            ..['interaction_date'] = yesterday.toIso8601String(),
        ];

        // Act - Simulate hasInteractedToday logic
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final hasTodayInteraction = todayInteractions.any((json) {
          final date = DateTime.parse(json['interaction_date'] as String);
          return date.isAfter(startOfDay) && date.isBefore(endOfDay);
        });

        final hasYesterdayInteraction = yesterdayInteractions.any((json) {
          final date = DateTime.parse(json['interaction_date'] as String);
          return date.isAfter(startOfDay) && date.isBefore(endOfDay);
        });

        // Assert
        expect(hasTodayInteraction, true);
        expect(hasYesterdayInteraction, false);
      });
    });

    group('Combined operations tests', () {
      test('should filter by user, sort by date, and limit results', () {
        // Arrange
        final now = DateTime.now();
        final allInteractions = [
          createTestInteractionMap(id: '1', userId: 'user-1')
            ..['interaction_date'] = now.subtract(const Duration(days: 3)).toIso8601String(),
          createTestInteractionMap(id: '2', userId: 'user-2')
            ..['interaction_date'] = now.subtract(const Duration(days: 1)).toIso8601String(),
          createTestInteractionMap(id: '3', userId: 'user-1')
            ..['interaction_date'] = now.subtract(const Duration(days: 1)).toIso8601String(),
          createTestInteractionMap(id: '4', userId: 'user-1')
            ..['interaction_date'] = now.subtract(const Duration(days: 5)).toIso8601String(),
        ];

        const userId = 'user-1';
        const limit = 2;

        // Act - Simulate getRecentInteractions logic
        var filtered = allInteractions
            .where((json) => json['user_id'] == userId)
            .map((json) => Interaction.fromJson(json))
            .toList();

        // Sort by date descending
        filtered.sort((a, b) => b.date.compareTo(a.date));

        // Limit results
        if (filtered.length > limit) {
          filtered = filtered.sublist(0, limit);
        }

        // Assert
        expect(filtered.length, 2);
        expect(filtered[0].id, '3'); // Most recent
        expect(filtered[1].id, '1'); // Second most recent
        expect(filtered.every((i) => i.userId == 'user-1'), true);
      });

      test('should correctly identify recurring interactions', () {
        // Arrange
        final interactions = [
          Interaction.fromJson(createTestInteractionMap()
            ..['is_recurring'] = true),
          Interaction.fromJson(createTestInteractionMap()
            ..['is_recurring'] = false),
          Interaction.fromJson(createTestInteractionMap()
            ..['is_recurring'] = true),
        ];

        // Act
        final recurring = interactions.where((i) => i.isRecurring).toList();

        // Assert
        expect(recurring.length, 2);
        expect(recurring.every((i) => i.isRecurring), true);
      });

      test('should filter interactions by mood', () {
        // Arrange
        final interactions = [
          Interaction.fromJson(createTestInteractionMap()
            ..['mood'] = 'positive'),
          Interaction.fromJson(createTestInteractionMap()
            ..['mood'] = 'neutral'),
          Interaction.fromJson(createTestInteractionMap()
            ..['mood'] = 'positive'),
          Interaction.fromJson(createTestInteractionMap()
            ..['mood'] = 'negative'),
        ];

        // Act
        final positiveInteractions = interactions
            .where((i) => i.mood == 'positive')
            .toList();

        // Assert
        expect(positiveInteractions.length, 2);
      });

      test('should filter interactions by rating threshold', () {
        // Arrange
        final interactions = [
          Interaction.fromJson(createTestInteractionMap()
            ..['rating'] = 5),
          Interaction.fromJson(createTestInteractionMap()
            ..['rating'] = 3),
          Interaction.fromJson(createTestInteractionMap()
            ..['rating'] = 4),
          Interaction.fromJson(createTestInteractionMap()
            ..['rating'] = 2),
        ];

        // Act - Get interactions with rating >= 4
        final highRatedInteractions = interactions
            .where((i) => i.rating != null && i.rating! >= 4)
            .toList();

        // Assert
        expect(highRatedInteractions.length, 2);
        expect(highRatedInteractions.every((i) => i.rating! >= 4), true);
      });
    });

    group('Date and time logic tests', () {
      test('should correctly identify start and end of day', () {
        // Arrange
        final testDate = DateTime(2025, 6, 15, 14, 30, 45);

        // Act
        final startOfDay = DateTime(testDate.year, testDate.month, testDate.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        // Assert
        expect(startOfDay.hour, 0);
        expect(startOfDay.minute, 0);
        expect(startOfDay.second, 0);
        expect(endOfDay.day, 16);
        expect(endOfDay.hour, 0);
      });

      test('should correctly check if date is within range', () {
        // Arrange
        final startDate = DateTime(2025, 1, 1);
        final endDate = DateTime(2025, 1, 31);

        final dateInRange = DateTime(2025, 1, 15);
        final dateBeforeRange = DateTime(2024, 12, 25);
        final dateAfterRange = DateTime(2025, 2, 5);

        // Act & Assert
        expect(
          dateInRange.isAfter(startDate) && dateInRange.isBefore(endDate),
          true,
        );
        expect(
          dateBeforeRange.isAfter(startDate) && dateBeforeRange.isBefore(endDate),
          false,
        );
        expect(
          dateAfterRange.isAfter(startDate) && dateAfterRange.isBefore(endDate),
          false,
        );
      });

      test('should correctly identify date boundaries (inclusive)', () {
        // Arrange
        final startDate = DateTime(2025, 1, 1);
        final endDate = DateTime(2025, 1, 31);

        // Act & Assert - Boundaries should be inclusive
        expect(
          (startDate.isAfter(startDate) || startDate.isAtSameMomentAs(startDate)) &&
          (startDate.isBefore(endDate) || startDate.isAtSameMomentAs(endDate)),
          true,
        );
        expect(
          (endDate.isAfter(startDate) || endDate.isAtSameMomentAs(startDate)) &&
          (endDate.isBefore(endDate) || endDate.isAtSameMomentAs(endDate)),
          true,
        );
      });
    });
  });
}
