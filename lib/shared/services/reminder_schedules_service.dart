import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/reminder_schedule_model.dart';

class ReminderSchedulesService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  static const String _table = 'reminder_schedules';

  /// Create a new reminder schedule
  Future<String> createSchedule(Map<String, dynamic> scheduleData) async {
    try {
      if (kDebugMode) {
        print('🔔 [SCHEDULES] Creating schedule...');
      }

      final response = await _supabase
          .from(_table)
          .insert(scheduleData)
          .select('id')
          .single();

      final id = response['id'] as String;

      if (kDebugMode) {
        print('✅ [SCHEDULES] Schedule created: $id');
      }

      return id;
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
      if (kDebugMode) {
        print('📡 [SCHEDULES] Streaming schedules for user: $userId');
      }

      return _supabase
          .from(_table)
          .stream(primaryKey: ['id'])
          .map((data) {
        // Filter for this user's schedules
        final filtered = data
            .where((json) => json['user_id'] == userId)
            .map((json) => ReminderSchedule.fromJson(json))
            .toList();

        // Sort by created_at descending (most recent first)
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (kDebugMode) {
          print('📋 [SCHEDULES] Loaded ${filtered.length} schedules');
        }

        return filtered;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SCHEDULES] Stream error: $e');
      }
      rethrow;
    }
  }

  /// Get active schedules for a user
  Stream<List<ReminderSchedule>> getActiveSchedulesStream(String userId) {
    try {
      if (kDebugMode) {
        print('📡 [SCHEDULES] Streaming active schedules for user: $userId');
      }

      return _supabase
          .from(_table)
          .stream(primaryKey: ['id'])
          .map((data) {
        // Filter for this user's active schedules
        final filtered = data
            .where((json) =>
                json['user_id'] == userId &&
                json['is_active'] == true)
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
      if (kDebugMode) {
        print('🔍 [SCHEDULES] Getting schedule: $scheduleId');
      }

      final response = await _supabase
          .from(_table)
          .select()
          .eq('id', scheduleId)
          .maybeSingle();

      if (response == null) {
        if (kDebugMode) {
          print('⚠️ [SCHEDULES] Schedule not found: $scheduleId');
        }
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
  Future<void> updateSchedule(String scheduleId, Map<String, dynamic> data) async {
    try {
      if (kDebugMode) {
        print('✏️ [SCHEDULES] Updating schedule: $scheduleId');
      }

      // Note: updated_at is automatically set by database trigger
      await _supabase
          .from(_table)
          .update(data)
          .eq('id', scheduleId);

      if (kDebugMode) {
        print('✅ [SCHEDULES] Schedule updated successfully');
      }
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
      if (kDebugMode) {
        print('🗑️ [SCHEDULES] Deleting schedule: $scheduleId');
      }

      await _supabase
          .from(_table)
          .delete()
          .eq('id', scheduleId);

      if (kDebugMode) {
        print('✅ [SCHEDULES] Schedule deleted successfully');
      }
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
      if (kDebugMode) {
        print('🔄 [SCHEDULES] Toggling schedule status: $scheduleId to $isActive');
      }

      await updateSchedule(scheduleId, {'is_active': isActive});
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SCHEDULES] Toggle error: $e');
      }
      rethrow;
    }
  }

  /// Add relatives to a schedule
  Future<void> addRelativesToSchedule(String scheduleId, List<String> relativeIds) async {
    try {
      if (kDebugMode) {
        print('➕ [SCHEDULES] Adding relatives to schedule: $scheduleId');
      }

      final schedule = await getSchedule(scheduleId);
      if (schedule == null) {
        throw Exception('Schedule not found');
      }

      final updatedRelativeIds = [...schedule.relativeIds, ...relativeIds];

      await updateSchedule(scheduleId, {'relative_ids': updatedRelativeIds});

      if (kDebugMode) {
        print('✅ [SCHEDULES] Added ${relativeIds.length} relatives');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SCHEDULES] Add relatives error: $e');
      }
      rethrow;
    }
  }

  /// Remove a relative from a schedule
  Future<void> removeRelativeFromSchedule(String scheduleId, String relativeId) async {
    try {
      if (kDebugMode) {
        print('➖ [SCHEDULES] Removing relative from schedule: $scheduleId');
      }

      final schedule = await getSchedule(scheduleId);
      if (schedule == null) {
        throw Exception('Schedule not found');
      }

      final updatedRelativeIds = schedule.relativeIds.where((id) => id != relativeId).toList();

      await updateSchedule(scheduleId, {'relative_ids': updatedRelativeIds});

      if (kDebugMode) {
        print('✅ [SCHEDULES] Relative removed');
      }
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
      if (kDebugMode) {
        print('📅 [SCHEDULES] Getting today\'s schedules for user: $userId');
      }

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

      if (kDebugMode) {
        print('✅ [SCHEDULES] Found ${todaySchedules.length} schedules for today');
      }

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
      if (kDebugMode) {
        print('📡 [SCHEDULES] Streaming $frequency schedules for user: $userId');
      }

      return _supabase
          .from(_table)
          .stream(primaryKey: ['id'])
          .map((data) {
        // Filter for this user's schedules with specified frequency
        final filtered = data
            .where((json) =>
                json['user_id'] == userId &&
                json['frequency'] == frequency)
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
