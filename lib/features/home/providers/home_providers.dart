import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/models/interaction_model.dart';
import '../../../shared/models/reminder_schedule_model.dart';
import '../../../shared/services/relatives_service.dart';
import '../../../shared/services/hadith_service.dart';
import '../../../shared/services/reminder_schedules_service.dart';
import '../../../shared/providers/interactions_provider.dart';

/// Provider for HadithService
final hadithServiceProvider = Provider((ref) {
  return HadithService();
});

/// Stream provider for relatives list
final relativesStreamProvider = StreamProvider.family<List<Relative>, String>((
  ref,
  userId,
) {
  ref.keepAlive();
  final service = ref.watch(relativesServiceProvider);
  return service.getRelativesStream(userId);
});

/// Stream provider for today's interactions
final todayInteractionsStreamProvider =
    StreamProvider.family<List<Interaction>, String>((ref, userId) {
      ref.keepAlive();
      final service = ref.watch(interactionsServiceProvider);
      return service.getTodayInteractionsStream(userId);
    });

/// Stream provider for reminder schedules
final reminderSchedulesStreamProvider =
    StreamProvider.family<List<ReminderSchedule>, String>((ref, userId) {
      ref.keepAlive();
      final service = ref.watch(reminderSchedulesServiceProvider);
      return service.getSchedulesStream(userId);
    });

/// Provider for today's due relatives based on reminder schedules
/// Returns relatives with ALL their applicable frequencies (e.g., daily + friday)
final todayDueRelativesProvider = Provider.family<List<DueRelativeWithFrequencies>, ({
  List<ReminderSchedule> schedules,
  List<Relative> relatives,
})>((ref, data) {
  final schedules = data.schedules;
  final relatives = data.relatives;

  // Map: relativeId -> Set<ReminderFrequency>
  final relativeFrequencies = <String, Set<ReminderFrequency>>{};

  for (final schedule in schedules) {
    if (schedule.isActive && schedule.shouldFireToday()) {
      for (final relativeId in schedule.relativeIds) {
        relativeFrequencies.putIfAbsent(relativeId, () => <ReminderFrequency>{});
        relativeFrequencies[relativeId]!.add(schedule.frequency);
      }
    }
  }

  return relatives
      .where((r) => relativeFrequencies.containsKey(r.id))
      .map((r) => DueRelativeWithFrequencies(
            relative: r,
            frequencies: relativeFrequencies[r.id]!,
          ))
      .toList();
});
