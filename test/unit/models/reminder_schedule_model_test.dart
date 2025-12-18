import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/shared/models/reminder_schedule_model.dart';

import '../../helpers/model_factories.dart';

void main() {
  group('ReminderSchedule Model', () {
    // =====================================================
    // JSON SERIALIZATION TESTS
    // =====================================================
    group('JSON Serialization', () {
      test('should create ReminderSchedule from valid JSON', () {
        final json = createTestReminderScheduleJson(
          id: 'schedule-123',
          userId: 'user-456',
          frequency: 'daily',
          relativeIds: ['relative-1', 'relative-2'],
          time: '09:00',
          isActive: true,
        );

        final schedule = ReminderSchedule.fromJson(json);

        expect(schedule.id, equals('schedule-123'));
        expect(schedule.userId, equals('user-456'));
        expect(schedule.frequency, equals(ReminderFrequency.daily));
        expect(schedule.relativeIds, equals(['relative-1', 'relative-2']));
        expect(schedule.time, equals('09:00'));
        expect(schedule.isActive, isTrue);
      });

      test('should convert ReminderSchedule to JSON', () {
        final schedule = createTestReminderSchedule(
          userId: 'user-789',
          frequency: ReminderFrequency.weekly,
          relativeIds: ['relative-3'],
          time: '10:30',
          isActive: false,
          customDays: [1, 3, 5],
        );

        final json = schedule.toJson();

        expect(json['user_id'], equals('user-789'));
        expect(json['frequency'], equals('weekly'));
        expect(json['relative_ids'], equals(['relative-3']));
        expect(json['time'], equals('10:30'));
        expect(json['is_active'], isFalse);
        expect(json['custom_days'], equals([1, 3, 5]));
      });

      test('should handle null optional fields in JSON', () {
        final json = {
          'id': 'test-id',
          'user_id': 'test-user',
          'frequency': 'daily',
          'relative_ids': null,
          'time': '08:00',
          'is_active': null,
          'custom_days': null,
          'day_of_month': null,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': null,
        };

        final schedule = ReminderSchedule.fromJson(json);

        expect(schedule.relativeIds, isEmpty);
        expect(schedule.isActive, isTrue); // Defaults to true
        expect(schedule.customDays, isNull);
        expect(schedule.dayOfMonth, isNull);
        expect(schedule.updatedAt, isNull);
      });

      test('should round-trip JSON serialization correctly', () {
        final original = createTestReminderSchedule(
          frequency: ReminderFrequency.monthly,
          dayOfMonth: 15,
          time: '14:00',
          relativeIds: ['r1', 'r2', 'r3'],
        );

        final json = original.toJson();
        // Add required fields for fromJson that toJson doesn't include
        json['id'] = original.id;
        json['created_at'] = original.createdAt.toIso8601String();

        final restored = ReminderSchedule.fromJson(json);

        expect(restored.frequency, equals(original.frequency));
        expect(restored.dayOfMonth, equals(original.dayOfMonth));
        expect(restored.time, equals(original.time));
        expect(restored.relativeIds, equals(original.relativeIds));
      });
    });

    // =====================================================
    // FREQUENCY ENUM TESTS
    // =====================================================
    group('ReminderFrequency Enum', () {
      test('should parse daily frequency', () {
        expect(ReminderFrequency.fromString('daily'), equals(ReminderFrequency.daily));
      });

      test('should parse weekly frequency', () {
        expect(ReminderFrequency.fromString('weekly'), equals(ReminderFrequency.weekly));
      });

      test('should parse monthly frequency', () {
        expect(ReminderFrequency.fromString('monthly'), equals(ReminderFrequency.monthly));
      });

      test('should parse friday frequency', () {
        expect(ReminderFrequency.fromString('friday'), equals(ReminderFrequency.friday));
      });

      test('should parse custom frequency', () {
        expect(ReminderFrequency.fromString('custom'), equals(ReminderFrequency.custom));
      });

      test('should default to custom for unknown frequency', () {
        expect(ReminderFrequency.fromString('unknown'), equals(ReminderFrequency.custom));
        expect(ReminderFrequency.fromString('invalid'), equals(ReminderFrequency.custom));
        expect(ReminderFrequency.fromString(''), equals(ReminderFrequency.custom));
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

      test('should have emoji representations', () {
        expect(ReminderFrequency.daily.emoji, equals('📅'));
        expect(ReminderFrequency.weekly.emoji, equals('📆'));
        expect(ReminderFrequency.monthly.emoji, equals('📋'));
        expect(ReminderFrequency.friday.emoji, equals('🕌'));
        expect(ReminderFrequency.custom.emoji, equals('⚙️'));
      });
    });

    // =====================================================
    // SHOULD FIRE TODAY TESTS
    // =====================================================
    group('shouldFireToday()', () {
      group('Daily Frequency', () {
        test('daily schedule should always fire', () {
          final schedule = createTestReminderSchedule(
            frequency: ReminderFrequency.daily,
          );
          expect(schedule.shouldFireToday(), isTrue);
        });

        test('daily schedule should fire regardless of customDays', () {
          final schedule = createTestReminderSchedule(
            frequency: ReminderFrequency.daily,
            customDays: [1, 2, 3], // Should be ignored for daily
          );
          expect(schedule.shouldFireToday(), isTrue);
        });
      });

      group('Weekly Frequency', () {
        test('weekly schedule without customDays should fire every day', () {
          final schedule = createTestReminderSchedule(
            frequency: ReminderFrequency.weekly,
            customDays: null,
          );
          expect(schedule.shouldFireToday(), isTrue);
        });

        test('weekly schedule with empty customDays should fire every day', () {
          final schedule = createTestReminderSchedule(
            frequency: ReminderFrequency.weekly,
            customDays: [],
          );
          expect(schedule.shouldFireToday(), isTrue);
        });

        test('weekly schedule should fire on customDays matching today', () {
          final today = DateTime.now().weekday; // 1 = Monday, 7 = Sunday
          final schedule = createTestReminderSchedule(
            frequency: ReminderFrequency.weekly,
            customDays: [today],
          );
          expect(schedule.shouldFireToday(), isTrue);
        });

        test('weekly schedule should not fire on days not in customDays', () {
          final today = DateTime.now().weekday;
          // Create list of all days except today
          final otherDays = List.generate(7, (i) => i + 1).where((d) => d != today).toList();

          if (otherDays.isNotEmpty) {
            final schedule = createTestReminderSchedule(
              frequency: ReminderFrequency.weekly,
              customDays: otherDays,
            );
            expect(schedule.shouldFireToday(), isFalse);
          }
        });

        test('weekly schedule with all days should always fire', () {
          final schedule = createTestReminderSchedule(
            frequency: ReminderFrequency.weekly,
            customDays: [1, 2, 3, 4, 5, 6, 7],
          );
          expect(schedule.shouldFireToday(), isTrue);
        });
      });

      group('Monthly Frequency', () {
        test('monthly schedule should fire on matching dayOfMonth', () {
          final today = DateTime.now().day;
          final schedule = createTestReminderSchedule(
            frequency: ReminderFrequency.monthly,
            dayOfMonth: today,
          );
          expect(schedule.shouldFireToday(), isTrue);
        });

        test('monthly schedule should not fire on non-matching dayOfMonth', () {
          final today = DateTime.now().day;
          // Pick a day that's definitely not today (handle edge cases)
          final otherDay = today == 1 ? 15 : 1;
          final schedule = createTestReminderSchedule(
            frequency: ReminderFrequency.monthly,
            dayOfMonth: otherDay,
          );
          expect(schedule.shouldFireToday(), isFalse);
        });

        test('monthly schedule without dayOfMonth should not fire', () {
          final schedule = createTestReminderSchedule(
            frequency: ReminderFrequency.monthly,
            dayOfMonth: null,
          );
          expect(schedule.shouldFireToday(), isFalse);
        });
      });

      group('Friday Frequency', () {
        test('friday schedule behavior depends on current day', () {
          final schedule = createTestReminderSchedule(
            frequency: ReminderFrequency.friday,
          );
          final today = DateTime.now().weekday;

          if (today == 5) {
            expect(schedule.shouldFireToday(), isTrue);
          } else {
            expect(schedule.shouldFireToday(), isFalse);
          }
        });

        test('friday weekday value is 5', () {
          // Verify Friday is weekday 5 in Dart
          expect(DateTime(2024, 1, 5).weekday, equals(5)); // Jan 5, 2024 is Friday
        });
      });

      group('Custom Frequency', () {
        test('custom schedule should never fire automatically', () {
          final schedule = createTestReminderSchedule(
            frequency: ReminderFrequency.custom,
          );
          expect(schedule.shouldFireToday(), isFalse);
        });

        test('custom schedule should not fire even with customDays', () {
          final today = DateTime.now().weekday;
          final schedule = createTestReminderSchedule(
            frequency: ReminderFrequency.custom,
            customDays: [today],
          );
          expect(schedule.shouldFireToday(), isFalse);
        });

        test('custom schedule should not fire even with dayOfMonth', () {
          final today = DateTime.now().day;
          final schedule = createTestReminderSchedule(
            frequency: ReminderFrequency.custom,
            dayOfMonth: today,
          );
          expect(schedule.shouldFireToday(), isFalse);
        });
      });
    });

    // =====================================================
    // DESCRIPTION TESTS
    // =====================================================
    group('description', () {
      test('daily description should include time', () {
        final schedule = createTestReminderSchedule(
          frequency: ReminderFrequency.daily,
          time: '09:00',
        );
        expect(schedule.description, contains('09:00'));
        expect(schedule.description, contains('كل يوم'));
      });

      test('weekly description with customDays should list days', () {
        final schedule = createTestReminderSchedule(
          frequency: ReminderFrequency.weekly,
          customDays: [1, 5], // Monday and Friday
          time: '10:00',
        );
        expect(schedule.description, contains('الاثنين'));
        expect(schedule.description, contains('الجمعة'));
        expect(schedule.description, contains('10:00'));
      });

      test('weekly description without customDays should be generic', () {
        final schedule = createTestReminderSchedule(
          frequency: ReminderFrequency.weekly,
          customDays: null,
          time: '11:00',
        );
        expect(schedule.description, contains('كل أسبوع'));
        expect(schedule.description, contains('11:00'));
      });

      test('monthly description should include day of month', () {
        final schedule = createTestReminderSchedule(
          frequency: ReminderFrequency.monthly,
          dayOfMonth: 15,
          time: '14:00',
        );
        expect(schedule.description, contains('15'));
        expect(schedule.description, contains('14:00'));
      });

      test('monthly description without dayOfMonth should be generic', () {
        final schedule = createTestReminderSchedule(
          frequency: ReminderFrequency.monthly,
          dayOfMonth: null,
          time: '15:00',
        );
        expect(schedule.description, contains('كل شهر'));
        expect(schedule.description, contains('15:00'));
      });

      test('friday description should mention Friday', () {
        final schedule = createTestReminderSchedule(
          frequency: ReminderFrequency.friday,
          time: '16:00',
        );
        expect(schedule.description, contains('جمعة'));
        expect(schedule.description, contains('16:00'));
      });

      test('custom description should be generic', () {
        final schedule = createTestReminderSchedule(
          frequency: ReminderFrequency.custom,
          time: '17:00',
        );
        expect(schedule.description, equals('مخصص'));
      });
    });

    // =====================================================
    // COPYWITH TESTS
    // =====================================================
    group('copyWith', () {
      test('should copy with new frequency', () {
        final original = createTestReminderSchedule(
          frequency: ReminderFrequency.daily,
        );
        final copied = original.copyWith(frequency: ReminderFrequency.weekly);

        expect(copied.frequency, equals(ReminderFrequency.weekly));
        expect(copied.id, equals(original.id));
        expect(copied.userId, equals(original.userId));
      });

      test('should copy with new time', () {
        final original = createTestReminderSchedule(time: '09:00');
        final copied = original.copyWith(time: '15:00');

        expect(copied.time, equals('15:00'));
        expect(copied.frequency, equals(original.frequency));
      });

      test('should copy with new isActive', () {
        final original = createTestReminderSchedule(isActive: true);
        final copied = original.copyWith(isActive: false);

        expect(copied.isActive, isFalse);
        expect(original.isActive, isTrue);
      });

      test('should copy with new relativeIds', () {
        final original = createTestReminderSchedule(
          relativeIds: ['relative-1'],
        );
        final copied = original.copyWith(
          relativeIds: ['relative-1', 'relative-2', 'relative-3'],
        );

        expect(copied.relativeIds.length, equals(3));
        expect(original.relativeIds.length, equals(1));
      });

      test('should copy with new customDays', () {
        final original = createTestReminderSchedule(customDays: [1, 2]);
        final copied = original.copyWith(customDays: [5, 6, 7]);

        expect(copied.customDays, equals([5, 6, 7]));
        expect(original.customDays, equals([1, 2]));
      });

      test('should copy with new dayOfMonth', () {
        final original = createTestReminderSchedule(dayOfMonth: 1);
        final copied = original.copyWith(dayOfMonth: 28);

        expect(copied.dayOfMonth, equals(28));
        expect(original.dayOfMonth, equals(1));
      });

      test('should preserve all fields when copying with no changes', () {
        final original = createTestReminderSchedule(
          id: 'test-id',
          userId: 'test-user',
          frequency: ReminderFrequency.weekly,
          relativeIds: ['r1', 'r2'],
          time: '12:00',
          isActive: true,
          customDays: [1, 3, 5],
          dayOfMonth: 15,
        );
        final copied = original.copyWith();

        expect(copied.id, equals(original.id));
        expect(copied.userId, equals(original.userId));
        expect(copied.frequency, equals(original.frequency));
        expect(copied.relativeIds, equals(original.relativeIds));
        expect(copied.time, equals(original.time));
        expect(copied.isActive, equals(original.isActive));
        expect(copied.customDays, equals(original.customDays));
        expect(copied.dayOfMonth, equals(original.dayOfMonth));
      });
    });

    // =====================================================
    // DAY NAME MAPPING TESTS
    // =====================================================
    group('Day Name Mapping', () {
      test('should have correct Arabic day names in description', () {
        // Test all days 1-7
        final dayNames = {
          1: 'الاثنين',
          2: 'الثلاثاء',
          3: 'الأربعاء',
          4: 'الخميس',
          5: 'الجمعة',
          6: 'السبت',
          7: 'الأحد',
        };

        for (final entry in dayNames.entries) {
          final schedule = createTestReminderSchedule(
            frequency: ReminderFrequency.weekly,
            customDays: [entry.key],
            time: '09:00',
          );
          expect(
            schedule.description,
            contains(entry.value),
            reason: 'Day ${entry.key} should be ${entry.value}',
          );
        }
      });
    });

    // =====================================================
    // DUE RELATIVE WITH FREQUENCIES TESTS
    // =====================================================
    group('DueRelativeWithFrequencies', () {
      test('hasFridayReminder returns true when friday is in frequencies', () {
        final dueRelative = DueRelativeWithFrequencies(
          relative: createTestRelative(),
          frequencies: {ReminderFrequency.daily, ReminderFrequency.friday},
        );
        expect(dueRelative.hasFridayReminder, isTrue);
      });

      test('hasFridayReminder returns false when friday is not in frequencies', () {
        final dueRelative = DueRelativeWithFrequencies(
          relative: createTestRelative(),
          frequencies: {ReminderFrequency.daily, ReminderFrequency.weekly},
        );
        expect(dueRelative.hasFridayReminder, isFalse);
      });

      test('sortedFrequencies puts friday first', () {
        final dueRelative = DueRelativeWithFrequencies(
          relative: createTestRelative(),
          frequencies: {
            ReminderFrequency.daily,
            ReminderFrequency.weekly,
            ReminderFrequency.friday,
          },
        );
        final sorted = dueRelative.sortedFrequencies;
        expect(sorted.first, equals(ReminderFrequency.friday));
      });

      test('sortedFrequencies works without friday', () {
        final dueRelative = DueRelativeWithFrequencies(
          relative: createTestRelative(),
          frequencies: {
            ReminderFrequency.weekly,
            ReminderFrequency.daily,
          },
        );
        final sorted = dueRelative.sortedFrequencies;
        expect(sorted.length, equals(2));
        // Should be sorted alphabetically by Arabic name
      });
    });

    // =====================================================
    // REMINDER TEMPLATE TESTS
    // =====================================================
    group('ReminderTemplate', () {
      test('should have 4 predefined templates', () {
        expect(ReminderTemplate.templates.length, equals(4));
      });

      test('templates should cover main frequency types', () {
        final frequencies = ReminderTemplate.templates.map((t) => t.frequency).toSet();
        expect(frequencies.contains(ReminderFrequency.daily), isTrue);
        expect(frequencies.contains(ReminderFrequency.weekly), isTrue);
        expect(frequencies.contains(ReminderFrequency.monthly), isTrue);
        expect(frequencies.contains(ReminderFrequency.friday), isTrue);
      });

      test('daily template should have correct properties', () {
        final daily = ReminderTemplate.templates.firstWhere(
          (t) => t.frequency == ReminderFrequency.daily,
        );
        expect(daily.title, equals('تذكير يومي'));
        expect(daily.defaultTime, equals('09:00'));
      });

      test('friday template should have correct properties', () {
        final friday = ReminderTemplate.templates.firstWhere(
          (t) => t.frequency == ReminderFrequency.friday,
        );
        expect(friday.title, equals('تذكير يوم الجمعة'));
        expect(friday.defaultTime, equals('16:00')); // After Jummah prayer
      });
    });
  });
}
