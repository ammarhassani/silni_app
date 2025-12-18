import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/errors/app_errors.dart';
import '../models/reminder_schedule_model.dart';

/// Provider for the ReminderSchedules service
final reminderSchedulesServiceProvider = Provider<ReminderSchedulesService>((
  ref,
) {
  return ReminderSchedulesService();
});

class ReminderSchedulesService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  static const String _table = 'reminder_schedules';

  /// Create a new reminder schedule
  Future<String> createSchedule(Map<String, dynamic> scheduleData) async {
    try {
      final response = await _supabase
          .from(_table)
          .insert(scheduleData)
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SCHEDULES] Create error: $e');
      }
      rethrow;
    }
  }

  /// Get all schedules for a user as a stream
  Stream<List<ReminderSchedule>> getSchedulesStream(String userId) {
    try {
      return _supabase.from(_table).stream(primaryKey: ['id']).map((data) {
        // Filter for this user's schedules
        final filtered = data
            .where((json) => json['user_id'] == userId)
            .toList();

        List<ReminderSchedule> schedules;
        try {
          schedules = filtered.map((json) {
            return ReminderSchedule.fromJson(json);
          }).toList();
        } catch (e) {
          if (kDebugMode) {
            print('❌ [SCHEDULES] Model parsing error: $e');
          }
          rethrow;
        }

        // Sort by created_at descending (most recent first)
        schedules.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return schedules;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SCHEDULES] Stream setup error: $e');
      }
      rethrow;
    }
  }

  /// Get active schedules for a user
  Stream<List<ReminderSchedule>> getActiveSchedulesStream(String userId) {
    try {
      return _supabase.from(_table).stream(primaryKey: ['id']).map((data) {
        // Filter for this user's active schedules
        final filtered = data
            .where(
              (json) => json['user_id'] == userId && json['is_active'] == true,
            )
            .map((json) => ReminderSchedule.fromJson(json))
            .toList();

        // Sort by created_at descending (most recent first)
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return filtered;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SCHEDULES] Active stream error: $e');
      }
      rethrow;
    }
  }

  /// Get a specific schedule
  Future<ReminderSchedule?> getSchedule(String scheduleId) async {
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .eq('id', scheduleId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return ReminderSchedule.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SCHEDULES] Get error: $e');
      }
      rethrow;
    }
  }

  /// Update a schedule
  Future<void> updateSchedule(
    String scheduleId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Note: updated_at is automatically set by database trigger
      await _supabase.from(_table).update(data).eq('id', scheduleId);
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SCHEDULES] Update error: $e');
      }
      rethrow;
    }
  }

  /// Delete a schedule
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _supabase.from(_table).delete().eq('id', scheduleId);
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SCHEDULES] Delete error: $e');
      }
      rethrow;
    }
  }

  /// Toggle schedule active status
  Future<void> toggleScheduleStatus(String scheduleId, bool isActive) async {
    try {
      await updateSchedule(scheduleId, {'is_active': isActive});
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SCHEDULES] Toggle error: $e');
      }
      rethrow;
    }
  }

  /// Add relatives to a schedule
  Future<void> addRelativesToSchedule(
    String scheduleId,
    List<String> relativeIds,
  ) async {
    try {
      final schedule = await getSchedule(scheduleId);
      if (schedule == null) {
        throw NotFoundError(
          message: 'Schedule not found',
          arabicMessage: 'جدول التذكير غير موجود',
          resourceType: 'ReminderSchedule',
          resourceId: scheduleId,
        );
      }

      final updatedRelativeIds = [...schedule.relativeIds, ...relativeIds];

      await updateSchedule(scheduleId, {'relative_ids': updatedRelativeIds});
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SCHEDULES] Add relatives error: $e');
      }
      rethrow;
    }
  }

  /// Remove a relative from a schedule
  Future<void> removeRelativeFromSchedule(
    String scheduleId,
    String relativeId,
  ) async {
    try {
      final schedule = await getSchedule(scheduleId);
      if (schedule == null) {
        throw NotFoundError(
          message: 'Schedule not found',
          arabicMessage: 'جدول التذكير غير موجود',
          resourceType: 'ReminderSchedule',
          resourceId: scheduleId,
        );
      }

      final updatedRelativeIds = schedule.relativeIds
          .where((id) => id != relativeId)
          .toList();

      await updateSchedule(scheduleId, {'relative_ids': updatedRelativeIds});
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SCHEDULES] Remove relative error: $e');
      }
      rethrow;
    }
  }

  /// Get schedules that should fire today
  Future<List<ReminderSchedule>> getTodaySchedules(String userId) async {
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .eq('user_id', userId)
          .eq('is_active', true);

      final allSchedules = (response as List)
          .map((json) => ReminderSchedule.fromJson(json))
          .toList();

      // Filter schedules that should fire today
      final todaySchedules = allSchedules.where((schedule) {
        return schedule.shouldFireToday();
      }).toList();

      return todaySchedules;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SCHEDULES] Get today schedules error: $e');
      }
      rethrow;
    }
  }

  /// Get schedules by frequency
  Stream<List<ReminderSchedule>> getSchedulesByFrequency(
    String userId,
    String frequency,
  ) {
    try {
      return _supabase.from(_table).stream(primaryKey: ['id']).map((data) {
        // Filter for this user's schedules with specified frequency
        final filtered = data
            .where(
              (json) =>
                  json['user_id'] == userId && json['frequency'] == frequency,
            )
            .map((json) => ReminderSchedule.fromJson(json))
            .toList();

        // Sort by created_at descending (most recent first)
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return filtered;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SCHEDULES] Frequency stream error: $e');
      }
      rethrow;
    }
  }
}
