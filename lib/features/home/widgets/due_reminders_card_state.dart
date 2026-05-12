/// Visual states the [DueRemindersCard] can show.
enum DueRemindersCardState {
  /// User has no relatives at all — prompt them to add some.
  noRelatives,

  /// User has relatives but hasn't created any reminder schedules.
  noReminders,

  /// User has unscheduled relatives — nudge them to schedule.
  unscheduledNudge,

  /// Schedules cover everyone and nothing is due today.
  allDone,

  /// All due-today relatives have been contacted — celebrate.
  celebration,

  /// Show the task list for today's outstanding contacts.
  taskList,
}

/// Pure decision function for which empty-state / list state the card shows.
///
/// `noRelatives` takes priority over every other check: a user who deleted
/// all their relatives must see "add relatives" copy, not "you're on good
/// contact" — which was the bug this function was extracted to fix.
DueRemindersCardState decideDueRemindersCardState({
  required int totalRelatives,
  required int totalSchedules,
  required int totalDueToday,
  required int contactedToday,
  required int unscheduledCount,
}) {
  if (totalRelatives == 0) return DueRemindersCardState.noRelatives;
  if (totalSchedules == 0) return DueRemindersCardState.noReminders;
  if (totalDueToday == 0) {
    if (unscheduledCount > 0) return DueRemindersCardState.unscheduledNudge;
    return DueRemindersCardState.allDone;
  }
  if (contactedToday == totalDueToday) return DueRemindersCardState.celebration;
  return DueRemindersCardState.taskList;
}
