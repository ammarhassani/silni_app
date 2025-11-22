import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/reminder_schedule_model.dart';

class ReminderSchedulesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reminder_schedules';

  /// Create a new reminder schedule
  Future<String> createSchedule(Map<String, dynamic> scheduleData) async {
    try {
      if (kDebugMode) {
        print('🔔 [SCHEDULES] Creating schedule...');
      }

      final docRef = await _firestore.collection(_collection).add(scheduleData);

      if (kDebugMode) {
        print('✅ [SCHEDULES] Schedule created: ${docRef.id}');
      }

      return docRef.id;
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

      return _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        final schedules = snapshot.docs
            .map((doc) => ReminderSchedule.fromFirestore(doc))
            .toList();

        if (kDebugMode) {
          print('📋 [SCHEDULES] Loaded ${schedules.length} schedules');
        }

        return schedules;
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

      return _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ReminderSchedule.fromFirestore(doc))
            .toList();
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

      final doc = await _firestore.collection(_collection).doc(scheduleId).get();

      if (!doc.exists) {
        if (kDebugMode) {
          print('⚠️ [SCHEDULES] Schedule not found: $scheduleId');
        }
        return null;
      }

      return ReminderSchedule.fromFirestore(doc);
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

      // Add updated timestamp
      data['updatedAt'] = Timestamp.now();

      await _firestore.collection(_collection).doc(scheduleId).update(data);

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

      await _firestore.collection(_collection).doc(scheduleId).delete();

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

      await updateSchedule(scheduleId, {'isActive': isActive});
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

      await updateSchedule(scheduleId, {'relativeIds': updatedRelativeIds});

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

      await updateSchedule(scheduleId, {'relativeIds': updatedRelativeIds});

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

      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      final allSchedules = snapshot.docs
          .map((doc) => ReminderSchedule.fromFirestore(doc))
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

      return _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('frequency', isEqualTo: frequency)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ReminderSchedule.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SCHEDULES] Frequency stream error: $e');
      }
      rethrow;
    }
  }
}
