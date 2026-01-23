import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/relative_streak_model.dart';
import '../models/gamification_event.dart';
import '../providers/gamification_events_provider.dart';
import 'gamification_config_service.dart';

/// Result of updating a relative streak
class RelativeStreakResult {
  final RelativeStreak streak;
  final bool streakIncreased;
  final bool streakBroken;
  final bool isNewStreak;

  RelativeStreakResult({
    required this.streak,
    required this.streakIncreased,
    required this.streakBroken,
    required this.isNewStreak,
  });
}

/// Service for managing per-relative streaks
class RelativeStreakService {
  // Use lazy initialization to avoid accessing Supabase before it's initialized
  SupabaseClient get _supabase => SupabaseConfig.client;
  final GamificationEventsController? _eventsController;

  RelativeStreakService({
    GamificationEventsController? eventsController,
  }) : _eventsController = eventsController;

  /// Update streak for a specific relative after interaction
  /// Uses same 26-hour window logic as global streak
  Future<RelativeStreakResult> updateRelativeStreak({
    required String userId,
    required String relativeId,
  }) async {
    try {
      // Try to get existing streak
      final existingData = await _supabase
          .from('relative_streaks')
          .select()
          .eq('user_id', userId)
          .eq('relative_id', relativeId)
          .maybeSingle();

      final now = DateTime.now().toUtc();
      // Get deadline hours from config (default 26)
      final deadlineHours = GamificationConfigService.instance.streakConfig.deadlineHours;
      final newDeadline = now.add(Duration(hours: deadlineHours));

      int newStreak;
      DateTime newDayStart;
      bool streakIncreased = false;
      bool streakBroken = false;
      bool isNewStreak = false;

      if (existingData == null) {
        // First interaction with this relative - create new streak
        newStreak = 1;
        newDayStart = now;
        streakIncreased = true;
        isNewStreak = true;

        final insertData = {
          'user_id': userId,
          'relative_id': relativeId,
          'current_streak': newStreak,
          'longest_streak': newStreak,
          'streak_deadline': newDeadline.toIso8601String(),
          'streak_day_start': newDayStart.toIso8601String(),
        };

        final result = await _supabase
            .from('relative_streaks')
            .insert(insertData)
            .select()
            .single();

        return RelativeStreakResult(
          streak: RelativeStreak.fromJson(result),
          streakIncreased: true,
          streakBroken: false,
          isNewStreak: true,
        );
      }

      // Existing streak - apply same logic as global
      final currentStreak = existingData['current_streak'] as int? ?? 0;
      final longestStreak = existingData['longest_streak'] as int? ?? 0;
      final deadlineStr = existingData['streak_deadline'] as String?;
      final dayStartStr = existingData['streak_day_start'] as String?;

      if (deadlineStr == null || dayStartStr == null) {
        // Missing data - start fresh
        newStreak = 1;
        newDayStart = now;
        streakIncreased = true;
      } else {
        final deadline = DateTime.parse(deadlineStr).toUtc();
        final dayStart = DateTime.parse(dayStartStr).toUtc();

        if (now.isAfter(deadline)) {
          // Deadline missed - streak broken
          newStreak = 1;
          newDayStart = now;
          streakIncreased = true;
          streakBroken = true;
        } else {
          // Within deadline - check if new day
          final hoursSinceDayStart = now.difference(dayStart).inHours;

          if (hoursSinceDayStart >= 24) {
            // New day - increment streak
            newStreak = currentStreak + 1;
            newDayStart = now;
            streakIncreased = true;
          } else {
            // Same day - extend deadline only
            newStreak = currentStreak;
            newDayStart = dayStart;
          }
        }
      }

      final newLongestStreak = newStreak > longestStreak ? newStreak : longestStreak;

      // Update database
      final result = await _supabase
          .from('relative_streaks')
          .update({
            'current_streak': newStreak,
            'longest_streak': newLongestStreak,
            'streak_deadline': newDeadline.toIso8601String(),
            'streak_day_start': newDayStart.toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('relative_id', relativeId)
          .select()
          .single();

      // Emit event if streak increased
      if (streakIncreased && !streakBroken) {
        _eventsController?.emit(GamificationEvent.streakIncreased(
          userId: userId,
          currentStreak: newStreak,
          longestStreak: newLongestStreak,
        ));

        // Check for celebration milestone (dynamic from admin config)
        if (GamificationConfigService.instance.streakConfig.isCelebrationMilestone(newStreak)) {
          _eventsController?.emit(GamificationEvent.streakMilestone(
            userId: userId,
            streak: newStreak,
          ));
        }
      }

      return RelativeStreakResult(
        streak: RelativeStreak.fromJson(result),
        streakIncreased: streakIncreased,
        streakBroken: streakBroken,
        isNewStreak: isNewStreak,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get streak for a specific relative
  Future<RelativeStreak?> getRelativeStreak({
    required String userId,
    required String relativeId,
  }) async {
    try {
      final data = await _supabase
          .from('relative_streaks')
          .select()
          .eq('user_id', userId)
          .eq('relative_id', relativeId)
          .maybeSingle();

      if (data == null) return null;
      return RelativeStreak.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Get all relative streaks for a user
  Future<List<RelativeStreak>> getAllRelativeStreaks(String userId) async {
    try {
      final data = await _supabase
          .from('relative_streaks')
          .select()
          .eq('user_id', userId)
          .order('current_streak', ascending: false);

      return (data as List)
          .map((json) => RelativeStreak.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get streaks that are endangered (within 4 hours of deadline)
  Future<List<RelativeStreak>> getEndangeredStreaks(String userId) async {
    try {
      final now = DateTime.now().toUtc();
      final fourHoursFromNow = now.add(const Duration(hours: 4));

      final data = await _supabase
          .from('relative_streaks')
          .select()
          .eq('user_id', userId)
          .gt('current_streak', 0)
          .gt('streak_deadline', now.toIso8601String())
          .lt('streak_deadline', fourHoursFromNow.toIso8601String())
          .order('streak_deadline', ascending: true);

      return (data as List)
          .map((json) => RelativeStreak.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Stream of a specific relative's streak (real-time updates)
  Stream<RelativeStreak?> watchRelativeStreak({
    required String userId,
    required String relativeId,
  }) {
    return _supabase
        .from('relative_streaks')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) {
          final match = data.where((row) => row['relative_id'] == relativeId);
          if (match.isEmpty) return null;
          return RelativeStreak.fromJson(match.first);
        });
  }

  /// Stream of all relative streaks for a user
  Stream<List<RelativeStreak>> watchAllRelativeStreaks(String userId) {
    return _supabase
        .from('relative_streaks')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.map((json) => RelativeStreak.fromJson(json)).toList());
  }
}
