import '../../shared/models/relative_model.dart';
import '../../shared/models/reminder_schedule_model.dart';
import '../../shared/repositories/reminder_schedules_repository.dart';
import 'app_logger_service.dart';

/// A suggestion for an auto-generated reminder based on relationship type.
class ReminderSuggestion {
  final ReminderFrequency frequency;
  final String time; // HH:mm format

  const ReminderSuggestion({
    required this.frequency,
    required this.time,
  });
}

/// Pure static service that auto-generates reminder suggestions and creates
/// reminder schedules when a new relative is added.
///
/// Follows the same pattern as [ContactPriorityService] — all methods are
/// static and the class cannot be instantiated.
class AutoReminderService {
  AutoReminderService._();

  static final AppLoggerService _logger = AppLoggerService();

  /// Suggest a reminder frequency and time based on relationship type.
  ///
  /// Mapping:
  /// - father/mother/husband/wife/son/daughter -> daily at 09:00
  /// - grandfather/grandmother/brother/sister/uncle/aunt -> weekly at 10:00
  /// - cousin/nephew/niece/other -> monthly at 11:00
  static ReminderSuggestion suggestReminder(RelationshipType relationshipType) {
    switch (relationshipType) {
      // Priority 1: Immediate family -> daily
      case RelationshipType.father:
      case RelationshipType.mother:
      case RelationshipType.husband:
      case RelationshipType.wife:
      case RelationshipType.son:
      case RelationshipType.daughter:
        return const ReminderSuggestion(
          frequency: ReminderFrequency.daily,
          time: '09:00',
        );

      // Priority 2: Extended close family -> weekly
      case RelationshipType.grandfather:
      case RelationshipType.grandmother:
      case RelationshipType.brother:
      case RelationshipType.sister:
      case RelationshipType.uncle:
      case RelationshipType.aunt:
        return const ReminderSuggestion(
          frequency: ReminderFrequency.weekly,
          time: '10:00',
        );

      // Priority 3: Distant family -> monthly
      case RelationshipType.cousin:
      case RelationshipType.nephew:
      case RelationshipType.niece:
      case RelationshipType.other:
        return const ReminderSuggestion(
          frequency: ReminderFrequency.monthly,
          time: '11:00',
        );
    }
  }

  /// Create an auto-generated reminder for a newly added relative.
  ///
  /// This method is designed to be called in a fire-and-forget manner after
  /// a relative is created. It will:
  /// 1. Get the suggested reminder for the relationship type
  /// 2. Check if a schedule with the same frequency already exists for the user
  /// 3. If yes, add the relative to the existing schedule
  /// 4. If no, create a new schedule
  ///
  /// Failures are logged but never thrown — this should never block the UI.
  static Future<void> createAutoReminder({
    required String userId,
    required String relativeId,
    required RelationshipType relationshipType,
    required ReminderSchedulesRepository remindersRepository,
  }) async {
    try {
      final suggestion = suggestReminder(relationshipType);

      // Check if a schedule with the same frequency already exists
      final existingSchedules = remindersRepository.getSchedulesByFrequency(
        userId,
        suggestion.frequency,
      );

      if (existingSchedules.isNotEmpty) {
        // Add the relative to the first matching schedule
        final schedule = existingSchedules.first;
        await remindersRepository.addRelativesToSchedule(
          schedule.id,
          [relativeId],
        );

        _logger.info(
          'Added relative to existing ${suggestion.frequency.value} schedule',
          category: LogCategory.service,
          tag: 'AutoReminderService',
          metadata: {
            'relativeId': relativeId,
            'scheduleId': schedule.id,
            'frequency': suggestion.frequency.value,
          },
        );
      } else {
        // Create a new schedule
        await remindersRepository.createSchedule({
          'user_id': userId,
          'frequency': suggestion.frequency.value,
          'time': suggestion.time,
          'relative_ids': [relativeId],
          'is_active': true,
        });

        _logger.info(
          'Created new ${suggestion.frequency.value} auto-reminder',
          category: LogCategory.service,
          tag: 'AutoReminderService',
          metadata: {
            'relativeId': relativeId,
            'frequency': suggestion.frequency.value,
            'time': suggestion.time,
            'relationshipType': relationshipType.value,
          },
        );
      }
    } catch (e, stackTrace) {
      // Never throw — log and move on
      _logger.error(
        'Failed to create auto-reminder: $e',
        category: LogCategory.service,
        tag: 'AutoReminderService',
        stackTrace: stackTrace,
        metadata: {
          'userId': userId,
          'relativeId': relativeId,
          'relationshipType': relationshipType.value,
        },
      );
    }
  }
}
