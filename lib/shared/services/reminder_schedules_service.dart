import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
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
      if (kDebugMode) {
        print('🔔 [SCHEDULES] Creating schedule...');
        print(
          '🔔 [SCHEDULES] Schedule data keys: ${scheduleData.keys.toList()}',
        );
        print('🔔 [SCHEDULES] Schedule data: $scheduleData');
      }

      // Debug: Check if reminder_time key exists in data
      if (scheduleData.containsKey('reminder_time')) {
        if (kDebugMode) {
          print(
            '✅ [SCHEDULES] reminder_time key found: ${scheduleData['reminder_time']}',
          );
        }
      } else {
        if (kDebugMode) {
          print('❌ [SCHEDULES] reminder_time key MISSING in schedule data!');
        }
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
        print('❌ [SCHEDULES] Error type: ${e.runtimeType}');
        if (e is PostgrestException) {
          print('❌ [SCHEDULES] Postgrest details: ${e.details}');
          print('❌ [SCHEDULES] Postgrest hint: ${e.hint}');
          print('❌ [SCHEDULES] Postgrest code: ${e.code}');
        }
      }
      rethrow;
    }
  }

  /// Get all schedules for a user as a stream
  Stream<List<ReminderSchedule>> getSchedulesStream(String userId) {
    try {
      // Always log regardless of debug mode
      debugPrint('📡 [SCHEDULES] Streaming schedules for user: $userId');
      debugPrint('📡 [SCHEDULES] Table name: $_table');

      return _supabase.from(_table).stream(primaryKey: ['id']).map((data) {
        debugPrint('📊 [SCHEDULES] Raw data received: ${data.length} records');

        // Filter for this user's schedules
        final filtered = data
            .where((json) => json['user_id'] == userId)
            .toList();

        debugPrint(
          '🔍 [SCHEDULES] Filtered for user $userId: ${filtered.length} records',
        );

        List<ReminderSchedule> schedules;
        try {
          schedules = filtered.map((json) {
            debugPrint('🔄 [SCHEDULES] Parsing schedule: $json');
            return ReminderSchedule.fromJson(json);
          }).toList();
        } catch (e) {
          debugPrint('❌ [SCHEDULES] Model parsing error: $e');
          debugPrint('❌ [SCHEDULES] Problematic data: $filtered');
          rethrow;
        }

        // Sort by created_at descending (most recent first)
        schedules.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        debugPrint(
          '📋 [SCHEDULES] Successfully loaded ${schedules.length} schedules',
        );

        return schedules;
      });
    } catch (e) {
      debugPrint('❌ [SCHEDULES] Stream setup error: $e');
      debugPrint('❌ [SCHEDULES] Error type: ${e.runtimeType}');
      if (e is PostgrestException) {
        debugPrint('❌ [SCHEDULES] Postgrest details: ${e.details}');
        debugPrint('❌ [SCHEDULES] Postgrest hint: ${e.hint}');
        debugPrint('❌ [SCHEDULES] Postgrest code: ${e.code}');
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
  Future<void> updateSchedule(
    String scheduleId,
    Map<String, dynamic> data,
  ) async {
    try {
      if (kDebugMode) {
        print('✏️ [SCHEDULES] Updating schedule: $scheduleId');
      }

      // Note: updated_at is automatically set by database trigger
      await _supabase.from(_table).update(data).eq('id', scheduleId);

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

      await _supabase.from(_table).delete().eq('id', scheduleId);

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
        print(
          '🔄 [SCHEDULES] Toggling schedule status: $scheduleId to $isActive',
        );
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
  Future<void> addRelativesToSchedule(
    String scheduleId,
    List<String> relativeIds,
  ) async {
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
  Future<void> removeRelativeFromSchedule(
    String scheduleId,
    String relativeId,
  ) async {
    try {
      if (kDebugMode) {
        print('➖ [SCHEDULES] Removing relative from schedule: $scheduleId');
      }

      final schedule = await getSchedule(scheduleId);
      if (schedule == null) {
        throw Exception('Schedule not found');
      }

      final updatedRelativeIds = schedule.relativeIds
          .where((id) => id != relativeId)
          .toList();

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
        print(
          '✅ [SCHEDULES] Found ${todaySchedules.length} schedules for today',
        );
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
        print(
          '📡 [SCHEDULES] Streaming $frequency schedules for user: $userId',
        );
      }

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
