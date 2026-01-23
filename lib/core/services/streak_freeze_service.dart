import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/streak_freeze_model.dart';
import '../models/gamification_event.dart';
import '../providers/gamification_events_provider.dart';

/// Result of using a freeze
class FreezeUseResult {
  final bool success;
  final String? message;
  final int remainingFreezes;

  FreezeUseResult({
    required this.success,
    this.message,
    required this.remainingFreezes,
  });
}

/// Service for managing streak freezes
class StreakFreezeService {
  // Use lazy initialization to avoid accessing Supabase before it's initialized
  SupabaseClient get _supabase => SupabaseConfig.client;
  final GamificationEventsController? _eventsController;

  StreakFreezeService({
    GamificationEventsController? eventsController,
  }) : _eventsController = eventsController;

  /// Get user's freeze inventory
  Future<FreezeInventory> getFreezeInventory(String userId) async {
    try {
      final data = await _supabase
          .from('streak_freezes')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) {
        // Create new inventory if not exists
        final newData = await _supabase
            .from('streak_freezes')
            .insert({'user_id': userId})
            .select()
            .single();
        return FreezeInventory.fromJson(newData);
      }

      return FreezeInventory.fromJson(data);
    } catch (e) {
      return FreezeInventory.empty(userId);
    }
  }

  /// Award a freeze for reaching a milestone
  Future<bool> awardMilestoneFreeze({
    required String userId,
    required int milestone,
  }) async {
    if (!FreezeMilestones.isFreezeAwardMilestone(milestone)) {
      return false;
    }

    try {
      // Get or create inventory
      final inventory = await getFreezeInventory(userId);

      // Update inventory
      await _supabase.from('streak_freezes').upsert({
        'user_id': userId,
        'freeze_count': inventory.freezeCount + 1,
        'last_earned_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');

      // Record history
      await _supabase.from('freeze_usage_history').insert({
        'user_id': userId,
        'freeze_type': FreezeType.earned.value,
        'streak_at_time': milestone,
        'source': FreezeMilestones.getSourceForMilestone(milestone),
      });

      // Emit event
      _eventsController?.emit(GamificationEvent.freezeEarned(
        userId: userId,
        source: 'milestone_$milestone',
      ));

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Use a freeze to protect a streak
  Future<FreezeUseResult> useFreeze({
    required String userId,
    required int currentStreak,
    String? relativeId,
    bool autoUse = false,
  }) async {
    try {
      final inventory = await getFreezeInventory(userId);

      if (!inventory.hasFreeze) {
        return FreezeUseResult(
          success: false,
          message: 'ليس لديك حماية شعلة متاحة',
          remainingFreezes: 0,
        );
      }

      // Decrement freeze count
      await _supabase.from('streak_freezes').update({
        'freeze_count': inventory.freezeCount - 1,
        'freezes_used_total': inventory.freezesUsedTotal + 1,
      }).eq('user_id', userId);

      // Record usage
      await _supabase.from('freeze_usage_history').insert({
        'user_id': userId,
        'freeze_type': autoUse ? FreezeType.autoUsed.value : FreezeType.manualUsed.value,
        'streak_at_time': currentStreak,
        'relative_id': relativeId,
      });

      // Emit event
      _eventsController?.emit(GamificationEvent.freezeUsed(
        userId: userId,
        streakProtected: currentStreak,
        autoUsed: autoUse,
      ));

      return FreezeUseResult(
        success: true,
        message: autoUse
            ? 'تم استخدام حماية الشعلة تلقائياً'
            : 'تم استخدام حماية الشعلة بنجاح',
        remainingFreezes: inventory.freezeCount - 1,
      );
    } catch (e) {
      return FreezeUseResult(
        success: false,
        message: 'حدث خطأ أثناء استخدام حماية الشعلة',
        remainingFreezes: 0,
      );
    }
  }

  /// Check if user has auto-freeze enabled
  Future<bool> isAutoFreezeEnabled(String userId) async {
    try {
      final data = await _supabase
          .from('users')
          .select('freeze_auto_use')
          .eq('id', userId)
          .single();
      return data['freeze_auto_use'] as bool? ?? true;
    } catch (e) {
      return true; // Default to enabled
    }
  }

  /// Toggle auto-freeze setting
  Future<void> setAutoFreeze(String userId, bool enabled) async {
    await _supabase.from('users').update({
      'freeze_auto_use': enabled,
    }).eq('id', userId);
  }

  /// Check if freeze should be auto-used for a streak about to break
  /// Returns true if freeze was used
  Future<bool> autoUseIfNeeded({
    required String userId,
    required int currentStreak,
    String? relativeId,
  }) async {
    // Only protect significant streaks (7+ days)
    if (currentStreak < 7) return false;

    final isEnabled = await isAutoFreezeEnabled(userId);
    if (!isEnabled) return false;

    final inventory = await getFreezeInventory(userId);
    if (!inventory.hasFreeze) return false;

    final result = await useFreeze(
      userId: userId,
      currentStreak: currentStreak,
      relativeId: relativeId,
      autoUse: true,
    );

    return result.success;
  }

  /// Get freeze usage history for a user
  Future<List<FreezeUsage>> getFreezeHistory(String userId, {int limit = 20}) async {
    try {
      final data = await _supabase
          .from('freeze_usage_history')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (data as List).map((json) => FreezeUsage.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Stream of freeze inventory updates
  Stream<FreezeInventory> watchFreezeInventory(String userId) {
    return _supabase
        .from('streak_freezes')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) {
          if (data.isEmpty) return FreezeInventory.empty(userId);
          return FreezeInventory.fromJson(data.first);
        });
  }
}
