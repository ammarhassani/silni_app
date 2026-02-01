import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/core/services/auto_reminder_service.dart';
import 'package:silni_app/shared/models/relative_model.dart';
import 'package:silni_app/shared/models/reminder_schedule_model.dart';

void main() {
  group('AutoReminderService', () {
    group('suggestReminder', () {
      // =====================================================
      // Priority 1 (daily): father, mother, husband, wife, son, daughter
      // =====================================================
      test('should suggest daily reminder for father', () {
        final suggestion =
            AutoReminderService.suggestReminder(RelationshipType.father);
        expect(suggestion.frequency, ReminderFrequency.daily);
        expect(suggestion.time, '09:00');
      });

      test('should suggest daily reminder for mother', () {
        final suggestion =
            AutoReminderService.suggestReminder(RelationshipType.mother);
        expect(suggestion.frequency, ReminderFrequency.daily);
        expect(suggestion.time, '09:00');
      });

      test('should suggest daily reminder for husband', () {
        final suggestion =
            AutoReminderService.suggestReminder(RelationshipType.husband);
        expect(suggestion.frequency, ReminderFrequency.daily);
        expect(suggestion.time, '09:00');
      });

      test('should suggest daily reminder for wife', () {
        final suggestion =
            AutoReminderService.suggestReminder(RelationshipType.wife);
        expect(suggestion.frequency, ReminderFrequency.daily);
        expect(suggestion.time, '09:00');
      });

      test('should suggest daily reminder for son', () {
        final suggestion =
            AutoReminderService.suggestReminder(RelationshipType.son);
        expect(suggestion.frequency, ReminderFrequency.daily);
        expect(suggestion.time, '09:00');
      });

      test('should suggest daily reminder for daughter', () {
        final suggestion =
            AutoReminderService.suggestReminder(RelationshipType.daughter);
        expect(suggestion.frequency, ReminderFrequency.daily);
        expect(suggestion.time, '09:00');
      });

      // =====================================================
      // Priority 2 (weekly): grandfather, grandmother, brother, sister,
      //                       uncle, aunt
      // =====================================================
      test('should suggest weekly reminder for grandfather', () {
        final suggestion =
            AutoReminderService.suggestReminder(RelationshipType.grandfather);
        expect(suggestion.frequency, ReminderFrequency.weekly);
        expect(suggestion.time, '10:00');
      });

      test('should suggest weekly reminder for grandmother', () {
        final suggestion =
            AutoReminderService.suggestReminder(RelationshipType.grandmother);
        expect(suggestion.frequency, ReminderFrequency.weekly);
        expect(suggestion.time, '10:00');
      });

      test('should suggest weekly reminder for brother', () {
        final suggestion =
            AutoReminderService.suggestReminder(RelationshipType.brother);
        expect(suggestion.frequency, ReminderFrequency.weekly);
        expect(suggestion.time, '10:00');
      });

      test('should suggest weekly reminder for sister', () {
        final suggestion =
            AutoReminderService.suggestReminder(RelationshipType.sister);
        expect(suggestion.frequency, ReminderFrequency.weekly);
        expect(suggestion.time, '10:00');
      });

      test('should suggest weekly reminder for uncle', () {
        final suggestion =
            AutoReminderService.suggestReminder(RelationshipType.uncle);
        expect(suggestion.frequency, ReminderFrequency.weekly);
        expect(suggestion.time, '10:00');
      });

      test('should suggest weekly reminder for aunt', () {
        final suggestion =
            AutoReminderService.suggestReminder(RelationshipType.aunt);
        expect(suggestion.frequency, ReminderFrequency.weekly);
        expect(suggestion.time, '10:00');
      });

      // =====================================================
      // Priority 3 (monthly): cousin, nephew, niece, other
      // =====================================================
      test('should suggest monthly reminder for cousin', () {
        final suggestion =
            AutoReminderService.suggestReminder(RelationshipType.cousin);
        expect(suggestion.frequency, ReminderFrequency.monthly);
        expect(suggestion.time, '11:00');
      });

      test('should suggest monthly reminder for nephew', () {
        final suggestion =
            AutoReminderService.suggestReminder(RelationshipType.nephew);
        expect(suggestion.frequency, ReminderFrequency.monthly);
        expect(suggestion.time, '11:00');
      });

      test('should suggest monthly reminder for niece', () {
        final suggestion =
            AutoReminderService.suggestReminder(RelationshipType.niece);
        expect(suggestion.frequency, ReminderFrequency.monthly);
        expect(suggestion.time, '11:00');
      });

      test('should suggest monthly reminder for other', () {
        final suggestion =
            AutoReminderService.suggestReminder(RelationshipType.other);
        expect(suggestion.frequency, ReminderFrequency.monthly);
        expect(suggestion.time, '11:00');
      });

      // =====================================================
      // Edge cases
      // =====================================================
      test('should return a valid ReminderSuggestion for all relationship types',
          () {
        for (final type in RelationshipType.values) {
          final suggestion = AutoReminderService.suggestReminder(type);
          expect(suggestion.frequency, isNotNull);
          expect(suggestion.time, matches(RegExp(r'^\d{2}:\d{2}$')));
        }
      });
    });
  });
}
