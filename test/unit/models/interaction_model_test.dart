import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/shared/models/interaction_model.dart';

import '../../helpers/model_factories.dart';

void main() {
  group('Interaction Model', () {
    // =====================================================
    // JSON SERIALIZATION TESTS
    // =====================================================
    group('JSON Serialization', () {
      test('should create Interaction from valid JSON', () {
        final json = createTestInteractionJson(
          id: 'interaction-123',
          userId: 'user-456',
          relativeId: 'relative-789',
          type: 'call',
          duration: 30,
          notes: 'Great conversation',
          rating: 5,
        );

        final interaction = Interaction.fromJson(json);

        expect(interaction.id, equals('interaction-123'));
        expect(interaction.userId, equals('user-456'));
        expect(interaction.relativeId, equals('relative-789'));
        expect(interaction.type, equals(InteractionType.call));
        expect(interaction.duration, equals(30));
        expect(interaction.notes, equals('Great conversation'));
        expect(interaction.rating, equals(5));
      });

      test('should convert Interaction to JSON', () {
        final interaction = createTestInteraction(
          userId: 'user-abc',
          relativeId: 'relative-def',
          type: InteractionType.visit,
          duration: 120,
          location: 'منزل العائلة',
          notes: 'زيارة عائلية رائعة',
          mood: 'happy',
          rating: 5,
        );

        final json = interaction.toJson();

        expect(json['user_id'], equals('user-abc'));
        expect(json['relative_id'], equals('relative-def'));
        expect(json['type'], equals('visit'));
        expect(json['duration'], equals(120));
        expect(json['location'], equals('منزل العائلة'));
        expect(json['notes'], equals('زيارة عائلية رائعة'));
        expect(json['mood'], equals('happy'));
        expect(json['rating'], equals(5));
      });

      test('should handle null optional fields in JSON', () {
        final json = {
          'id': 'test-id',
          'user_id': 'test-user',
          'relative_id': 'test-relative',
          'type': 'call',
          'date': DateTime.now().toIso8601String(),
          'duration': null,
          'location': null,
          'notes': null,
          'mood': null,
          'photo_urls': null,
          'audio_note_url': null,
          'tags': null,
          'rating': null,
          'is_recurring': null,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': null,
        };

        final interaction = Interaction.fromJson(json);

        expect(interaction.duration, isNull);
        expect(interaction.location, isNull);
        expect(interaction.notes, isNull);
        expect(interaction.mood, isNull);
        expect(interaction.photoUrls, isEmpty);
        expect(interaction.audioNoteUrl, isNull);
        expect(interaction.tags, isEmpty);
        expect(interaction.rating, isNull);
        expect(interaction.isRecurring, isFalse);
      });

      test('should round-trip JSON serialization correctly', () {
        final original = createTestInteraction(
          type: InteractionType.gift,
          notes: 'هدية عيد ميلاد',
          photoUrls: ['photo1.jpg', 'photo2.jpg'],
          tags: ['عيد ميلاد', 'هدية'],
          rating: 4,
        );

        final json = original.toJson();
        json['id'] = original.id;
        json['created_at'] = original.createdAt.toIso8601String();

        final restored = Interaction.fromJson(json);

        expect(restored.type, equals(original.type));
        expect(restored.notes, equals(original.notes));
        expect(restored.photoUrls, equals(original.photoUrls));
        expect(restored.tags, equals(original.tags));
        expect(restored.rating, equals(original.rating));
      });
    });

    // =====================================================
    // INTERACTION TYPE ENUM TESTS
    // =====================================================
    group('InteractionType Enum', () {
      test('should parse all interaction types correctly', () {
        expect(InteractionType.fromString('call'), equals(InteractionType.call));
        expect(InteractionType.fromString('visit'), equals(InteractionType.visit));
        expect(InteractionType.fromString('message'), equals(InteractionType.message));
        expect(InteractionType.fromString('gift'), equals(InteractionType.gift));
        expect(InteractionType.fromString('event'), equals(InteractionType.event));
        expect(InteractionType.fromString('other'), equals(InteractionType.other));
      });

      test('should default to other for unknown interaction type', () {
        expect(InteractionType.fromString('unknown'), equals(InteractionType.other));
        expect(InteractionType.fromString(''), equals(InteractionType.other));
        expect(InteractionType.fromString('video_call'), equals(InteractionType.other));
      });

      test('should have correct values', () {
        expect(InteractionType.call.value, equals('call'));
        expect(InteractionType.visit.value, equals('visit'));
        expect(InteractionType.message.value, equals('message'));
        expect(InteractionType.gift.value, equals('gift'));
        expect(InteractionType.event.value, equals('event'));
        expect(InteractionType.other.value, equals('other'));
      });

      test('should have Arabic names', () {
        expect(InteractionType.call.arabicName, equals('اتصال'));
        expect(InteractionType.visit.arabicName, equals('زيارة'));
        expect(InteractionType.message.arabicName, equals('رسالة'));
        expect(InteractionType.gift.arabicName, equals('هدية'));
        expect(InteractionType.event.arabicName, equals('مناسبة'));
        expect(InteractionType.other.arabicName, equals('أخرى'));
      });

      test('should have emoji representations', () {
        expect(InteractionType.call.emoji, equals('📞'));
        expect(InteractionType.visit.emoji, equals('🏠'));
        expect(InteractionType.message.emoji, equals('💬'));
        expect(InteractionType.gift.emoji, equals('🎁'));
        expect(InteractionType.event.emoji, equals('🎉'));
        expect(InteractionType.other.emoji, equals('📝'));
      });

      test('should have 6 interaction types', () {
        expect(InteractionType.values.length, equals(6));
      });
    });

    // =====================================================
    // FORMATTED DURATION TESTS
    // =====================================================
    group('formattedDuration', () {
      test('should return empty string when duration is null', () {
        final interaction = createTestInteraction(duration: null);
        expect(interaction.formattedDuration, isEmpty);
      });

      test('should format minutes only', () {
        final interaction = createTestInteraction(duration: 30);
        expect(interaction.formattedDuration, equals('30 دقيقة'));
      });

      test('should format single minute', () {
        final interaction = createTestInteraction(duration: 1);
        expect(interaction.formattedDuration, equals('1 دقيقة'));
      });

      test('should format hours only', () {
        final interaction = createTestInteraction(duration: 60);
        expect(interaction.formattedDuration, equals('1 ساعة'));
      });

      test('should format multiple hours', () {
        final interaction = createTestInteraction(duration: 120);
        expect(interaction.formattedDuration, equals('2 ساعة'));
      });

      test('should format hours and minutes', () {
        final interaction = createTestInteraction(duration: 90);
        expect(interaction.formattedDuration, equals('1 ساعة و 30 دقيقة'));
      });

      test('should format complex duration', () {
        final interaction = createTestInteraction(duration: 150);
        expect(interaction.formattedDuration, equals('2 ساعة و 30 دقيقة'));
      });

      test('should handle zero duration', () {
        final interaction = createTestInteraction(duration: 0);
        expect(interaction.formattedDuration, equals('0 دقيقة'));
      });
    });

    // =====================================================
    // RELATIVE TIME TESTS
    // =====================================================
    group('relativeTime', () {
      test('should return "الآن" for current time', () {
        final interaction = createTestInteraction(
          date: DateTime.now(),
        );
        // Due to test timing, might be 0 minutes
        final result = interaction.relativeTime;
        expect(result, anyOf(equals('الآن'), contains('دقيقة')));
      });

      test('should return minutes for recent interactions', () {
        final interaction = createTestInteraction(
          date: DateTime.now().subtract(const Duration(minutes: 15)),
        );
        expect(interaction.relativeTime, contains('دقيقة'));
      });

      test('should return hours for same day interactions', () {
        final interaction = createTestInteraction(
          date: DateTime.now().subtract(const Duration(hours: 3)),
        );
        expect(interaction.relativeTime, contains('ساعة'));
      });

      test('should return "منذ يوم واحد" for yesterday', () {
        final interaction = createTestInteraction(
          date: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(interaction.relativeTime, equals('منذ يوم واحد'));
      });

      test('should return "منذ يومين" for 2 days ago', () {
        final interaction = createTestInteraction(
          date: DateTime.now().subtract(const Duration(days: 2)),
        );
        expect(interaction.relativeTime, equals('منذ يومين'));
      });

      test('should return days for recent past', () {
        final interaction = createTestInteraction(
          date: DateTime.now().subtract(const Duration(days: 5)),
        );
        expect(interaction.relativeTime, equals('منذ 5 أيام'));
      });

      test('should return weeks for older interactions', () {
        final interaction = createTestInteraction(
          date: DateTime.now().subtract(const Duration(days: 14)),
        );
        expect(interaction.relativeTime, equals('منذ 2 أسابيع'));
      });

      test('should return "منذ أسبوع" for 1 week', () {
        final interaction = createTestInteraction(
          date: DateTime.now().subtract(const Duration(days: 7)),
        );
        expect(interaction.relativeTime, equals('منذ أسبوع'));
      });

      test('should return months for older interactions', () {
        final interaction = createTestInteraction(
          date: DateTime.now().subtract(const Duration(days: 60)),
        );
        expect(interaction.relativeTime, equals('منذ 2 أشهر'));
      });

      test('should return "منذ شهر" for 1 month', () {
        final interaction = createTestInteraction(
          date: DateTime.now().subtract(const Duration(days: 30)),
        );
        expect(interaction.relativeTime, equals('منذ شهر'));
      });

      test('should return years for very old interactions', () {
        final interaction = createTestInteraction(
          date: DateTime.now().subtract(const Duration(days: 730)),
        );
        expect(interaction.relativeTime, equals('منذ 2 سنوات'));
      });

      test('should return "منذ سنة" for 1 year', () {
        final interaction = createTestInteraction(
          date: DateTime.now().subtract(const Duration(days: 365)),
        );
        expect(interaction.relativeTime, equals('منذ سنة'));
      });
    });

    // =====================================================
    // COPYWITH TESTS
    // =====================================================
    group('copyWith', () {
      test('should copy with new type', () {
        final original = createTestInteraction(type: InteractionType.call);
        final copied = original.copyWith(type: InteractionType.visit);

        expect(copied.type, equals(InteractionType.visit));
        expect(original.type, equals(InteractionType.call));
      });

      test('should copy with new date', () {
        final original = createTestInteraction();
        final newDate = DateTime(2024, 1, 1);
        final copied = original.copyWith(date: newDate);

        expect(copied.date, equals(newDate));
      });

      test('should copy with new duration', () {
        final original = createTestInteraction(duration: 30);
        final copied = original.copyWith(duration: 60);

        expect(copied.duration, equals(60));
        expect(original.duration, equals(30));
      });

      test('should copy with new notes', () {
        final original = createTestInteraction(notes: 'Original notes');
        final copied = original.copyWith(notes: 'New notes');

        expect(copied.notes, equals('New notes'));
        expect(original.notes, equals('Original notes'));
      });

      test('should copy with new rating', () {
        final original = createTestInteraction(rating: 3);
        final copied = original.copyWith(rating: 5);

        expect(copied.rating, equals(5));
        expect(original.rating, equals(3));
      });

      test('should copy with new photoUrls', () {
        final original = createTestInteraction(photoUrls: ['photo1.jpg']);
        final copied = original.copyWith(photoUrls: ['photo1.jpg', 'photo2.jpg', 'photo3.jpg']);

        expect(copied.photoUrls.length, equals(3));
        expect(original.photoUrls.length, equals(1));
      });

      test('should copy with new tags', () {
        final original = createTestInteraction(tags: ['tag1']);
        final copied = original.copyWith(tags: ['tag1', 'tag2']);

        expect(copied.tags.length, equals(2));
        expect(original.tags.length, equals(1));
      });

      test('should preserve all fields when copying with no changes', () {
        final original = createTestInteraction(
          id: 'test-id',
          userId: 'test-user',
          relativeId: 'test-relative',
          type: InteractionType.visit,
          duration: 60,
          location: 'Test location',
          notes: 'Test notes',
          mood: 'happy',
          photoUrls: ['photo.jpg'],
          tags: ['tag'],
          rating: 4,
          isRecurring: true,
        );
        final copied = original.copyWith();

        expect(copied.id, equals(original.id));
        expect(copied.userId, equals(original.userId));
        expect(copied.relativeId, equals(original.relativeId));
        expect(copied.type, equals(original.type));
        expect(copied.duration, equals(original.duration));
        expect(copied.location, equals(original.location));
        expect(copied.notes, equals(original.notes));
        expect(copied.mood, equals(original.mood));
        expect(copied.photoUrls, equals(original.photoUrls));
        expect(copied.tags, equals(original.tags));
        expect(copied.rating, equals(original.rating));
        expect(copied.isRecurring, equals(original.isRecurring));
      });
    });

    // =====================================================
    // PHOTO URLS TESTS
    // =====================================================
    group('photoUrls', () {
      test('should support empty list', () {
        final interaction = createTestInteraction(photoUrls: []);
        expect(interaction.photoUrls, isEmpty);
      });

      test('should support single photo', () {
        final interaction = createTestInteraction(
          photoUrls: ['https://example.com/photo.jpg'],
        );
        expect(interaction.photoUrls.length, equals(1));
      });

      test('should support multiple photos', () {
        final interaction = createTestInteraction(
          photoUrls: [
            'https://example.com/photo1.jpg',
            'https://example.com/photo2.jpg',
            'https://example.com/photo3.jpg',
          ],
        );
        expect(interaction.photoUrls.length, equals(3));
      });
    });

    // =====================================================
    // RATING TESTS
    // =====================================================
    group('rating', () {
      test('should support null rating', () {
        final interaction = createTestInteraction(rating: null);
        expect(interaction.rating, isNull);
      });

      test('should support rating 1-5', () {
        for (int i = 1; i <= 5; i++) {
          final interaction = createTestInteraction(rating: i);
          expect(interaction.rating, equals(i));
        }
      });
    });
  });
}
