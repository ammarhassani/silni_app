import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/models/interaction_model.dart';
import '../../../shared/models/reminder_schedule_model.dart';
import '../../../shared/services/hadith_service.dart';
import '../../../core/providers/cache_provider.dart';
import '../../../core/config/supabase_config.dart';

/// Provider for HadithService
final hadithServiceProvider = Provider((ref) {
  return HadithService();
});

/// Stream provider for relatives list (cache-first via repository)
final relativesStreamProvider = StreamProvider.family<List<Relative>, String>((
  ref,
  userId,
) {
  ref.keepAlive();
  final repository = ref.watch(relativesRepositoryProvider);
  return repository.watchRelatives(userId);
});

/// Stream provider for today's interactions (cache-first via repository)
final todayInteractionsStreamProvider =
    StreamProvider.family<List<Interaction>, String>((ref, userId) {
      ref.keepAlive();
      final repository = ref.watch(interactionsRepositoryProvider);
      return repository.watchTodayInteractions(userId);
    });

/// Stream provider for reminder schedules (cache-first via repository)
final reminderSchedulesStreamProvider =
    StreamProvider.family<List<ReminderSchedule>, String>((ref, userId) {
      ref.keepAlive();
      final repository = ref.watch(reminderSchedulesRepositoryProvider);
      return repository.watchSchedules(userId);
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

/// Stream provider for user gamification data (streak, badges)
/// Used by StreakBadgeBar for live updates
final userGamificationDataProvider =
    StreamProvider.family<Map<String, dynamic>, String>((ref, userId) {
  ref.keepAlive();
  return SupabaseConfig.client
      .from('users')
      .stream(primaryKey: ['id'])
      .eq('id', userId)
      .map((data) => data.isNotEmpty ? data.first : <String, dynamic>{});
});
