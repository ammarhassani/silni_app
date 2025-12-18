import 'package:flutter_test/flutter_test.dart';

import 'package:silni_app/shared/models/reminder_schedule_model.dart';
import '../../helpers/model_factories.dart';

void main() {
  group('ReminderSchedulesService Logic Tests', () {
    // =====================================================
    // SCHEDULE FILTERING TESTS
    // =====================================================
    group('schedule filtering', () {
      /// Filter schedules by user ID
      List<Map<String, dynamic>> filterByUserId(
        List<Map<String, dynamic>> data,
        String userId,
      ) {
        return data.where((json) => json['user_id'] == userId).toList();
      }

      test('should filter schedules by user ID', () {
        final data = [
          createTestReminderScheduleJson(id: 's1', userId: 'user-1'),
          createTestReminderScheduleJson(id: 's2', userId: 'user-2'),
          createTestReminderScheduleJson(id: 's3', userId: 'user-1'),
        ];

        final filtered = filterByUserId(data, 'user-1');
        expect(filtered.length, equals(2));
        expect(filtered.every((s) => s['user_id'] == 'user-1'), isTrue);
      });

      test('should return empty list when no matching user', () {
        final data = [
          createTestReminderScheduleJson(id: 's1', userId: 'user-1'),
          createTestReminderScheduleJson(id: 's2', userId: 'user-2'),
        ];

        final filtered = filterByUserId(data, 'user-3');
        expect(filtered.isEmpty, isTrue);
      });

      /// Filter active schedules
      List<Map<String, dynamic>> filterActiveSchedules(
        List<Map<String, dynamic>> data,
        String userId,
      ) {
        return data
            .where(
              (json) =>
                  json['user_id'] == userId && json['is_active'] == true,
            )
            .toList();
      }

      test('should filter only active schedules', () {
        final data = [
          createTestReminderScheduleJson(id: 's1', userId: 'user-1', isActive: true),
          createTestReminderScheduleJson(id: 's2', userId: 'user-1', isActive: false),
          createTestReminderScheduleJson(id: 's3', userId: 'user-1', isActive: true),
        ];

        final filtered = filterActiveSchedules(data, 'user-1');
        expect(filtered.length, equals(2));
        expect(filtered.every((s) => s['is_active'] == true), isTrue);
      });

      /// Filter by frequency
      List<Map<String, dynamic>> filterByFrequency(
        List<Map<String, dynamic>> data,
        String userId,
        String frequency,
      ) {
        return data
            .where(
              (json) =>
                  json['user_id'] == userId && json['frequency'] == frequency,
            )
            .toList();
      }

      test('should filter schedules by frequency', () {
        final data = [
          createTestReminderScheduleJson(id: 's1', userId: 'user-1', frequency: 'daily'),
          createTestReminderScheduleJson(id: 's2', userId: 'user-1', frequency: 'weekly'),
          createTestReminderScheduleJson(id: 's3', userId: 'user-1', frequency: 'daily'),
        ];

        final filtered = filterByFrequency(data, 'user-1', 'daily');
        expect(filtered.length, equals(2));
        expect(filtered.every((s) => s['frequency'] == 'daily'), isTrue);
      });
    });

    // =====================================================
    // SCHEDULE SORTING TESTS
    // =====================================================
    group('schedule sorting', () {
      test('should sort schedules by created_at descending', () {
        final schedules = [
          createTestReminderSchedule(
            id: 's1',
            createdAt: DateTime(2024, 1, 1),
          ),
          createTestReminderSchedule(
            id: 's2',
            createdAt: DateTime(2024, 6, 15),
          ),
          createTestReminderSchedule(
            id: 's3',
            createdAt: DateTime(2024, 3, 10),
          ),
        ];

        schedules.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        expect(schedules[0].id, equals('s2')); // June
        expect(schedules[1].id, equals('s3')); // March
        expect(schedules[2].id, equals('s1')); // January
      });

      test('should handle same creation date', () {
        final sameDate = DateTime(2024, 6, 15);
        final schedules = [
          createTestReminderSchedule(id: 's1', createdAt: sameDate),
          createTestReminderSchedule(id: 's2', createdAt: sameDate),
        ];

        schedules.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        expect(schedules.length, equals(2));
      });
    });

    // =====================================================
    // RELATIVE IDS MANAGEMENT TESTS
    // =====================================================
    group('relative IDs management', () {
      /// Add relatives to a schedule
      List<String> addRelatives(
        List<String> existing,
        List<String> newIds,
      ) {
        return [...existing, ...newIds];
      }

      test('should add relatives to empty list', () {
        final result = addRelatives([], ['rel-1', 'rel-2']);
        expect(result, equals(['rel-1', 'rel-2']));
      });

      test('should append new relatives to existing', () {
        final result = addRelatives(['rel-1'], ['rel-2', 'rel-3']);
        expect(result, equals(['rel-1', 'rel-2', 'rel-3']));
      });

      /// Remove relative from schedule
      List<String> removeRelative(List<String> existing, String relativeId) {
        return existing.where((id) => id != relativeId).toList();
      }

      test('should remove relative from list', () {
        final result = removeRelative(['rel-1', 'rel-2', 'rel-3'], 'rel-2');
        expect(result, equals(['rel-1', 'rel-3']));
      });

      test('should handle removing non-existent relative', () {
        final result = removeRelative(['rel-1', 'rel-2'], 'rel-3');
        expect(result, equals(['rel-1', 'rel-2']));
      });

      test('should handle removing from empty list', () {
        final result = removeRelative([], 'rel-1');
        expect(result.isEmpty, isTrue);
      });

      test('should handle removing all relatives', () {
        var result = ['rel-1', 'rel-2'];
        result = removeRelative(result, 'rel-1');
        result = removeRelative(result, 'rel-2');
        expect(result.isEmpty, isTrue);
      });
    });

    // =====================================================
    // SHOULD FIRE TODAY TESTS
    // =====================================================
    group('shouldFireToday logic', () {
      test('daily schedule should always fire', () {
        final schedule = createTestReminderSchedule(
          frequency: ReminderFrequency.daily,
        );
        expect(schedule.shouldFireToday(), isTrue);
      });

      test('weekly schedule without custom days should fire', () {
        final schedule = createTestReminderSchedule(
          frequency: ReminderFrequency.weekly,
          customDays: null,
        );
        expect(schedule.shouldFireToday(), isTrue);
      });

      test('weekly schedule with matching custom day should fire', () {
        final today = DateTime.now().weekday;
        final schedule = createTestReminderSchedule(
          frequency: ReminderFrequency.weekly,
          customDays: [today],
        );
        expect(schedule.shouldFireToday(), isTrue);
      });

      test('weekly schedule with non-matching custom day should not fire', () {
        final today = DateTime.now().weekday;
        final otherDay = today == 7 ? 1 : today + 1;
        final schedule = createTestReminderSchedule(
          frequency: ReminderFrequency.weekly,
          customDays: [otherDay],
        );
        expect(schedule.shouldFireToday(), isFalse);
      });

      test('monthly schedule on matching day should fire', () {
        final today = DateTime.now().day;
        final schedule = createTestReminderSchedule(
          frequency: ReminderFrequency.monthly,
          dayOfMonth: today,
        );
        expect(schedule.shouldFireToday(), isTrue);
      });

      test('monthly schedule on non-matching day should not fire', () {
        final today = DateTime.now().day;
        final otherDay = today == 28 ? 1 : today + 1;
        final schedule = createTestReminderSchedule(
          frequency: ReminderFrequency.monthly,
          dayOfMonth: otherDay,
        );
        expect(schedule.shouldFireToday(), isFalse);
      });

      test('monthly schedule without day should not fire', () {
        final schedule = createTestReminderSchedule(
          frequency: ReminderFrequency.monthly,
          dayOfMonth: null,
        );
        expect(schedule.shouldFireToday(), isFalse);
      });

      test('friday schedule should fire only on friday', () {
        final schedule = createTestReminderSchedule(
          frequency: ReminderFrequency.friday,
        );
        final isFriday = DateTime.now().weekday == 5;
        expect(schedule.shouldFireToday(), equals(isFriday));
      });

      test('custom schedule should never fire automatically', () {
        final schedule = createTestReminderSchedule(
          frequency: ReminderFrequency.custom,
        );
        expect(schedule.shouldFireToday(), isFalse);
      });
    });

    // =====================================================
    // REMINDER FREQUENCY TESTS
    // =====================================================
    group('ReminderFrequency enum', () {
      test('should parse frequency from string', () {
        expect(
          ReminderFrequency.fromString('daily'),
          equals(ReminderFrequency.daily),
        );
        expect(
          ReminderFrequency.fromString('weekly'),
          equals(ReminderFrequency.weekly),
        );
        expect(
          ReminderFrequency.fromString('monthly'),
          equals(ReminderFrequency.monthly),
        );
        expect(
          ReminderFrequency.fromString('friday'),
          equals(ReminderFrequency.friday),
        );
        expect(
          ReminderFrequency.fromString('custom'),
          equals(ReminderFrequency.custom),
        );
      });

      test('should default to custom for unknown string', () {
        expect(
          ReminderFrequency.fromString('unknown'),
          equals(ReminderFrequency.custom),
        );
        expect(
          ReminderFrequency.fromString(''),
          equals(ReminderFrequency.custom),
        );
      });

      test('should have correct values', () {
        expect(ReminderFrequency.daily.value, equals('daily'));
        expect(ReminderFrequency.weekly.value, equals('weekly'));
        expect(ReminderFrequency.monthly.value, equals('monthly'));
        expect(ReminderFrequency.friday.value, equals('friday'));
        expect(ReminderFrequency.custom.value, equals('custom'));
      });

      test('should have Arabic names', () {
        expect(ReminderFrequency.daily.arabicName, equals('يومي'));
        expect(ReminderFrequency.weekly.arabicName, equals('أسبوعي'));
        expect(ReminderFrequency.monthly.arabicName, equals('شهري'));
        expect(ReminderFrequency.friday.arabicName, equals('جمعة'));
        expect(ReminderFrequency.custom.arabicName, equals('مخصص'));
      });

      test('should have emojis', () {
        expect(ReminderFrequency.daily.emoji, equals('📅'));
        expect(ReminderFrequency.weekly.emoji, equals('📆'));
        expect(ReminderFrequency.monthly.emoji, equals('📋'));
        expect(ReminderFrequency.friday.emoji, equals('🕌'));
        expect(ReminderFrequency.custom.emoji, equals('⚙️'));
      });
    });

    // =====================================================
    // SCHEDULE DESCRIPTION TESTS
    // =====================================================
    group('schedule description', () {
      test('daily description should include time', () {
        final schedule = createTestReminderSchedule(
          frequency: ReminderFrequency.daily,
          time: '09:00',
        );
        expect(schedule.description, contains('كل يوم'));
        expect(schedule.description, contains('09:00'));
      });

      test('weekly description with custom days should list days', () {
        final schedule = createTestReminderSchedule(
          frequency: ReminderFrequency.weekly,
          customDays: [1, 3], // Monday, Wednesday
          time: '10:00',
        );
        expect(schedule.description, contains('الاثنين'));
        expect(schedule.description, contains('الأربعاء'));
      });

      test('weekly description without custom days', () {
        final schedule = createTestReminderSchedule(
          frequency: ReminderFrequency.weekly,
          customDays: null,
          time: '10:00',
        );
        expect(schedule.description, contains('كل أسبوع'));
      });

      test('monthly description should include day of month', () {
        final schedule = createTestReminderSchedule(
          frequency: ReminderFrequency.monthly,
          dayOfMonth: 15,
          time: '11:00',
        );
        expect(schedule.description, contains('يوم 15'));
        expect(schedule.description, contains('كل شهر'));
      });

      test('friday description', () {
        final schedule = createTestReminderSchedule(
          frequency: ReminderFrequency.friday,
          time: '16:00',
        );
        expect(schedule.description, contains('كل جمعة'));
        expect(schedule.description, contains('16:00'));
      });

      test('custom description', () {
        final schedule = createTestReminderSchedule(
          frequency: ReminderFrequency.custom,
        );
        expect(schedule.description, equals('مخصص'));
      });
    });

    // =====================================================
    // DAY NAME TESTS
    // =====================================================
    group('day name conversion', () {
      test('should return correct Arabic day names', () {
        final dayNames = {
          1: 'الاثنين',
          2: 'الثلاثاء',
          3: 'الأربعاء',
          4: 'الخميس',
          5: 'الجمعة',
          6: 'السبت',
          7: 'الأحد',
        };

        dayNames.forEach((day, expectedName) {
          final schedule = createTestReminderSchedule(
            frequency: ReminderFrequency.weekly,
            customDays: [day],
            time: '10:00',
          );
          expect(schedule.description, contains(expectedName));
        });
      });
    });

    // =====================================================
    // SCHEDULE JSON CONVERSION TESTS
    // =====================================================
    group('JSON conversion', () {
      test('should convert schedule to JSON correctly', () {
        final schedule = createTestReminderSchedule(
          userId: 'test-user-id',
          frequency: ReminderFrequency.daily,
          relativeIds: ['rel-1', 'rel-2'],
          time: '09:00',
          isActive: true,
        );

        final json = schedule.toJson();

        expect(json['user_id'], equals('test-user-id'));
        expect(json['frequency'], equals('daily'));
        expect(json['relative_ids'], equals(['rel-1', 'rel-2']));
        expect(json['time'], equals('09:00'));
        expect(json['is_active'], isTrue);
      });

      test('should parse schedule from JSON correctly', () {
        final json = createTestReminderScheduleJson(
          userId: 'test-user-id',
          frequency: 'weekly',
          relativeIds: ['rel-1'],
          time: '10:00',
          isActive: false,
        );

        final schedule = ReminderSchedule.fromJson(json);

        expect(schedule.userId, equals('test-user-id'));
        expect(schedule.frequency, equals(ReminderFrequency.weekly));
        expect(schedule.relativeIds, equals(['rel-1']));
        expect(schedule.time, equals('10:00'));
        expect(schedule.isActive, isFalse);
      });

      test('should handle null relative_ids in JSON', () {
        final json = {
          'id': 'test-id',
          'user_id': 'test-user-id',
          'frequency': 'daily',
          'relative_ids': null,
          'time': '09:00',
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
        };

        final schedule = ReminderSchedule.fromJson(json);
        expect(schedule.relativeIds, isEmpty);
      });
    });

    // =====================================================
    // COPY WITH TESTS
    // =====================================================
    group('copyWith', () {
      test('should copy with single field change', () {
        final original = createTestReminderSchedule(
          frequency: ReminderFrequency.daily,
          isActive: true,
        );

        final copy = original.copyWith(isActive: false);

        expect(copy.isActive, isFalse);
        expect(copy.frequency, equals(original.frequency));
        expect(copy.id, equals(original.id));
      });

      test('should copy with multiple field changes', () {
        final original = createTestReminderSchedule(
          frequency: ReminderFrequency.daily,
          time: '09:00',
        );

        final copy = original.copyWith(
          frequency: ReminderFrequency.weekly,
          time: '10:00',
        );

        expect(copy.frequency, equals(ReminderFrequency.weekly));
        expect(copy.time, equals('10:00'));
        expect(copy.id, equals(original.id));
      });

      test('should not modify original when copying', () {
        final original = createTestReminderSchedule(
          isActive: true,
        );

        original.copyWith(isActive: false);

        expect(original.isActive, isTrue);
      });
    });

    // =====================================================
    // REMINDER TEMPLATES TESTS
    // =====================================================
    group('ReminderTemplate', () {
      test('should have 4 predefined templates', () {
        expect(ReminderTemplate.templates.length, equals(4));
      });

      test('should have daily template', () {
        final daily = ReminderTemplate.templates
            .firstWhere((t) => t.frequency == ReminderFrequency.daily);
        expect(daily.title, equals('تذكير يومي'));
        expect(daily.defaultTime, equals('09:00'));
      });

      test('should have weekly template', () {
        final weekly = ReminderTemplate.templates
            .firstWhere((t) => t.frequency == ReminderFrequency.weekly);
        expect(weekly.title, equals('تذكير أسبوعي'));
        expect(weekly.defaultTime, equals('10:00'));
      });

      test('should have monthly template', () {
        final monthly = ReminderTemplate.templates
            .firstWhere((t) => t.frequency == ReminderFrequency.monthly);
        expect(monthly.title, equals('تذكير شهري'));
        expect(monthly.defaultTime, equals('11:00'));
      });

      test('should have friday template', () {
        final friday = ReminderTemplate.templates
            .firstWhere((t) => t.frequency == ReminderFrequency.friday);
        expect(friday.title, equals('تذكير يوم الجمعة'));
        expect(friday.defaultTime, equals('16:00'));
      });

      test('all templates should have descriptions', () {
        for (final template in ReminderTemplate.templates) {
          expect(template.description.isNotEmpty, isTrue);
          expect(template.suggestedRelationships.isNotEmpty, isTrue);
        }
      });
    });

    // =====================================================
    // DUE RELATIVE WITH FREQUENCIES TESTS
    // =====================================================
    group('DueRelativeWithFrequencies', () {
      test('should detect Friday reminder', () {
        final relative = createTestRelative(id: 'rel-1');
        final due = DueRelativeWithFrequencies(
          relative: relative,
          frequencies: {ReminderFrequency.friday, ReminderFrequency.daily},
        );

        expect(due.hasFridayReminder, isTrue);
      });

      test('should not detect Friday when not included', () {
        final relative = createTestRelative(id: 'rel-1');
        final due = DueRelativeWithFrequencies(
          relative: relative,
          frequencies: {ReminderFrequency.daily, ReminderFrequency.weekly},
        );

        expect(due.hasFridayReminder, isFalse);
      });

      test('should sort frequencies with Friday first', () {
        final relative = createTestRelative(id: 'rel-1');
        final due = DueRelativeWithFrequencies(
          relative: relative,
          frequencies: {
            ReminderFrequency.weekly,
            ReminderFrequency.friday,
            ReminderFrequency.daily,
          },
        );

        final sorted = due.sortedFrequencies;
        expect(sorted.first, equals(ReminderFrequency.friday));
      });
    });

    // =====================================================
    // TIME FORMAT TESTS
    // =====================================================
    group('time format', () {
      test('should accept valid time formats', () {
        final validTimes = ['00:00', '09:00', '12:30', '23:59'];

        for (final time in validTimes) {
          final schedule = createTestReminderSchedule(time: time);
          expect(schedule.time, equals(time));
        }
      });

      test('should validate time format pattern', () {
        bool isValidTimeFormat(String time) {
          final regex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
          return regex.hasMatch(time);
        }

        expect(isValidTimeFormat('09:00'), isTrue);
        expect(isValidTimeFormat('23:59'), isTrue);
        expect(isValidTimeFormat('25:00'), isFalse);
        expect(isValidTimeFormat('9:00'), isFalse);
        expect(isValidTimeFormat('12:60'), isFalse);
      });
    });

    // =====================================================
    // EDGE CASES
    // =====================================================
    group('edge cases', () {
      test('should handle empty relative IDs list', () {
        final schedule = createTestReminderSchedule(
          relativeIds: [],
        );
        expect(schedule.relativeIds.isEmpty, isTrue);
      });

      test('should handle many relative IDs', () {
        final manyIds = List.generate(100, (i) => 'rel-$i');
        final schedule = createTestReminderSchedule(
          relativeIds: manyIds,
        );
        expect(schedule.relativeIds.length, equals(100));
      });

      test('should handle empty custom days', () {
        final schedule = createTestReminderSchedule(
          frequency: ReminderFrequency.weekly,
          customDays: [],
        );
        // Empty custom days treated as fire every day for weekly
        expect(schedule.shouldFireToday(), isTrue);
      });

      test('should handle all days selected', () {
        final schedule = createTestReminderSchedule(
          frequency: ReminderFrequency.weekly,
          customDays: [1, 2, 3, 4, 5, 6, 7],
        );
        expect(schedule.shouldFireToday(), isTrue);
      });

      test('should handle last day of month', () {
        final schedule = createTestReminderSchedule(
          frequency: ReminderFrequency.monthly,
          dayOfMonth: 31,
        );
        final isLastDay = DateTime.now().day == 31;
        expect(schedule.shouldFireToday(), equals(isLastDay));
      });
    });
  });
}
