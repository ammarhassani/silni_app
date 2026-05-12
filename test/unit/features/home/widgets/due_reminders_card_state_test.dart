import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/features/home/widgets/due_reminders_card_state.dart';

void main() {
  group('decideDueRemindersCardState', () {
    test('zero relatives → noRelatives (takes priority over noReminders)', () {
      final state = decideDueRemindersCardState(
        totalRelatives: 0,
        totalSchedules: 0,
        totalDueToday: 0,
        contactedToday: 0,
        unscheduledCount: 0,
      );
      expect(state, DueRemindersCardState.noRelatives);
    });

    test('zero relatives but schedules exist → still noRelatives', () {
      // Edge case: user had schedules pointing to relatives that got deleted.
      final state = decideDueRemindersCardState(
        totalRelatives: 0,
        totalSchedules: 3,
        totalDueToday: 0,
        contactedToday: 0,
        unscheduledCount: 0,
      );
      expect(state, DueRemindersCardState.noRelatives);
    });

    test('has relatives but no schedules → noReminders', () {
      final state = decideDueRemindersCardState(
        totalRelatives: 5,
        totalSchedules: 0,
        totalDueToday: 0,
        contactedToday: 0,
        unscheduledCount: 0,
      );
      expect(state, DueRemindersCardState.noReminders);
    });

    test('schedules exist, no due today, but unscheduled relatives → unscheduledNudge', () {
      final state = decideDueRemindersCardState(
        totalRelatives: 5,
        totalSchedules: 2,
        totalDueToday: 0,
        contactedToday: 0,
        unscheduledCount: 3,
      );
      expect(state, DueRemindersCardState.unscheduledNudge);
    });

    test('schedules cover everyone and nothing due today → allDone', () {
      final state = decideDueRemindersCardState(
        totalRelatives: 5,
        totalSchedules: 2,
        totalDueToday: 0,
        contactedToday: 0,
        unscheduledCount: 0,
      );
      expect(state, DueRemindersCardState.allDone);
    });

    test('all due today are contacted → celebration', () {
      final state = decideDueRemindersCardState(
        totalRelatives: 5,
        totalSchedules: 2,
        totalDueToday: 3,
        contactedToday: 3,
        unscheduledCount: 0,
      );
      expect(state, DueRemindersCardState.celebration);
    });

    test('some due today still pending → taskList', () {
      final state = decideDueRemindersCardState(
        totalRelatives: 5,
        totalSchedules: 2,
        totalDueToday: 3,
        contactedToday: 1,
        unscheduledCount: 0,
      );
      expect(state, DueRemindersCardState.taskList);
    });

    test('regression: deleting all relatives flips state from allDone → noRelatives', () {
      // Reproduces the reported bug. Before fix: this combo would land on
      // allDone ("you're on good contact"). After fix: noRelatives.
      final state = decideDueRemindersCardState(
        totalRelatives: 0,
        totalSchedules: 1,
        totalDueToday: 0,
        contactedToday: 0,
        unscheduledCount: 0,
      );
      expect(state, DueRemindersCardState.noRelatives);
    });
  });
}
