import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../../shared/models/interaction_model.dart';
import '../models/gamification_event.dart';
import '../providers/gamification_events_provider.dart';
import 'analytics_service.dart';
import 'gamification_config_service.dart';

/// Service for managing gamification features
/// Handles points, streaks, badges, and levels
/// Uses dynamic configuration from admin panel via GamificationConfigService
class GamificationService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final AnalyticsService? _analytics;
  final GamificationEventsController? _eventsController;
  final GamificationConfigService _config = GamificationConfigService.instance;

  GamificationService({
    AnalyticsService? analytics,
    GamificationEventsController? eventsController,
  })  : _analytics = analytics,
        _eventsController = eventsController;

  // =====================================================
  // POINTS SYSTEM (Dynamic from admin panel)
  // =====================================================

  /// Calculate points for an interaction
  /// Uses dynamic config from admin panel
  int calculateInteractionPoints(Interaction interaction) {
    // Get base points from admin config
    final pointsConfig = _config.getPointsConfig(interaction.type);
    int points = pointsConfig.basePoints;

    // Bonus for adding details (from admin config)
    if (interaction.notes != null && interaction.notes!.isNotEmpty) {
      points += _config.notesBonus;
    }
    if (interaction.photoUrls.isNotEmpty) {
      points += _config.photoBonus;
    }
    if (interaction.rating != null) {
      points += _config.ratingBonus;
    }

    return points;
  }

  /// Award points to user after interaction
  Future<void> awardPoints({
    required String userId,
    required int points,
  }) async {
    try {
      // Get today's points to check against daily cap
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final todayInteractions = await _supabase
          .from('interactions')
          .select('*')
          .eq('user_id', userId)
          .gte('date', startOfDay.toIso8601String())
          .lt('date', startOfDay.add(const Duration(days: 1)).toIso8601String());

      // Calculate points earned today
      int pointsEarnedToday = 0;
      for (final interactionData in todayInteractions) {
        final interaction = Interaction.fromJson(interactionData);
        pointsEarnedToday += calculateInteractionPoints(interaction);
      }

      // Apply daily cap (from admin config)
      final dailyPointCap = _config.dailyPointCap;

      if (pointsEarnedToday >= dailyPointCap) {
        return;
      }

      final pointsToAward = (pointsEarnedToday + points > dailyPointCap)
          ? dailyPointCap - pointsEarnedToday
          : points;

      if (pointsToAward <= 0) {
        return;
      }

      // Update user points and total interactions
      await _supabase.rpc('award_points', params: {
        'p_user_id': userId,
        'p_points': pointsToAward,
      });

      // Emit points earned event
      _eventsController?.emit(GamificationEvent.pointsEarned(
        userId: userId,
        points: pointsToAward,
        source: 'interaction',
      ));
    } catch (e) {
      rethrow;
    }
  }

  // =====================================================
  // STREAK TRACKING (24h-based, Snapchat-like)
  // =====================================================

  /// Update user's streak after an interaction (Snapchat-style)
  ///
  /// Snapchat Streak Rules:
  /// - Every interaction resets the 24h deadline timer
  /// - Streak increments when entering a new "day" (24h since day_start)
  /// - Streak breaks if deadline passes without interaction
  Future<Map<String, dynamic>> updateStreak(String userId) async {
    try {
      // Get user's current streak data
      final userData = await _supabase
          .from('users')
          .select('current_streak, longest_streak, streak_deadline, streak_day_start')
          .eq('id', userId)
          .single();

      final int currentStreak = userData['current_streak'] ?? 0;
      final int longestStreak = userData['longest_streak'] ?? 0;
      final String? deadlineStr = userData['streak_deadline'];
      final String? dayStartStr = userData['streak_day_start'];

      // Use UTC for consistent timezone handling
      final now = DateTime.now().toUtc();
      // Deadline window from admin config (default 26 hours - gives grace period for daily interactions)
      final newDeadline = now.add(Duration(hours: _config.streakConfig.deadlineHours));

      int newStreak;
      DateTime newDayStart;
      bool streakIncreased = false;
      bool streakBroken = false;

      if (deadlineStr == null || dayStartStr == null) {
        // FIRST INTERACTION EVER - Start fresh streak
        newStreak = 1;
        newDayStart = now;
        streakIncreased = true;
      } else {
        final deadline = DateTime.parse(deadlineStr).toUtc();
        final dayStart = DateTime.parse(dayStartStr).toUtc();

        if (now.isAfter(deadline)) {
          // DEADLINE MISSED - Streak broken!
          newStreak = 1;
          newDayStart = now;
          streakIncreased = true;
          streakBroken = true;
        } else {
          // WITHIN DEADLINE - Streak is safe!
          // Check if we've entered a new "day" (24h since day_start)
          final hoursSinceDayStart = now.difference(dayStart).inHours;

          if (hoursSinceDayStart >= 24) {
            // NEW DAY - Increment streak!
            newStreak = currentStreak + 1;
            newDayStart = now;
            streakIncreased = true;
          } else {
            // SAME DAY - No increment, just extend deadline
            newStreak = currentStreak;
            newDayStart = dayStart; // Keep original day start
          }
        }
      }

      // Update longest streak if necessary
      final newLongestStreak = newStreak > longestStreak ? newStreak : longestStreak;

      // ALWAYS update database: streak values + deadline (timer always resets!)
      await _supabase.from('users').update({
        'current_streak': newStreak,
        'longest_streak': newLongestStreak,
        'streak_deadline': newDeadline.toIso8601String(),
        'streak_day_start': newDayStart.toIso8601String(),
        // Also update legacy field for backward compatibility
        'last_interaction_at': now.toIso8601String(),
      }).eq('id', userId);

      // Emit streak events
      if (streakIncreased && !streakBroken) {
        _eventsController?.emit(GamificationEvent.streakIncreased(
          userId: userId,
          currentStreak: newStreak,
          longestStreak: newLongestStreak,
        ));

        // Check for celebration milestone (dynamic from admin config)
        if (_config.streakConfig.isCelebrationMilestone(newStreak)) {
          _eventsController?.emit(GamificationEvent.streakMilestone(
            userId: userId,
            streak: newStreak,
          ));
          _analytics?.logStreakMilestone(newStreak);

          // Award freeze at freeze milestones (from admin config: default 7, 30, 100 days)
          if (_config.streakConfig.isFreezeAwardMilestone(newStreak)) {
            await _awardStreakFreeze(userId, newStreak);
          }
        }
      }

      return {
        'current_streak': newStreak,
        'longest_streak': newLongestStreak,
        'streak_increased': streakIncreased,
        'streak_broken': streakBroken,
        'streak_deadline': newDeadline.toIso8601String(),
        'streak_day_start': newDayStart.toIso8601String(),
      };
    } catch (e) {
      rethrow;
    }
  }

  // =====================================================
  // STREAK FREEZE AWARDS
  // =====================================================

  /// Award a streak freeze at milestone (7, 30, 100 days)
  Future<void> _awardStreakFreeze(String userId, int milestone) async {
    try {
      // Get or create freeze inventory
      final existingData = await _supabase
          .from('streak_freezes')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      final currentCount = existingData?['freeze_count'] as int? ?? 0;

      // Upsert freeze inventory
      await _supabase.from('streak_freezes').upsert({
        'user_id': userId,
        'freeze_count': currentCount + 1,
        'last_earned_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');

      // Record in history
      await _supabase.from('freeze_usage_history').insert({
        'user_id': userId,
        'freeze_type': 'earned',
        'streak_at_time': milestone,
        'source': 'milestone_$milestone',
      });

      // Emit freeze earned event
      _eventsController?.emit(GamificationEvent.freezeEarned(
        userId: userId,
        source: 'milestone_$milestone',
      ));
    } catch (e) {
      // Don't fail streak update if freeze award fails
      // Just log and continue
    }
  }

  // =====================================================
  // BADGE SYSTEM
  // =====================================================

  /// Check and award new badges to user
  /// Uses dynamic badge configuration from admin panel
  Future<List<String>> checkAndAwardBadges(String userId) async {
    try {
      // Get current badges
      final userData = await _supabase
          .from('users')
          .select('badges, total_interactions, current_streak')
          .eq('id', userId)
          .single();

      final List<String> currentBadges = List<String>.from(userData['badges'] ?? []);
      final int totalInteractions = userData['total_interactions'] ?? 0;
      final int currentStreak = userData['current_streak'] ?? 0;

      // Get all user interactions for analysis (needed for special badges)
      final interactions = await _supabase
          .from('interactions')
          .select('type, relative_id')
          .eq('user_id', userId);

      // Calculate stats from interactions
      final uniqueTypes = <String>{};
      final uniqueRelatives = <String>{};
      int giftCount = 0;
      int eventCount = 0;
      int callCount = 0;
      int visitCount = 0;

      for (final interactionData in interactions) {
        final type = interactionData['type'] as String;
        final relativeId = interactionData['relative_id'] as String;
        uniqueTypes.add(type);
        uniqueRelatives.add(relativeId);

        if (type == 'gift') giftCount++;
        if (type == 'event') eventCount++;
        if (type == 'call') callCount++;
        if (type == 'visit') visitCount++;
      }

      // Use dynamic config to check badge eligibility
      final newBadges = _config.checkBadgeEligibility(
        currentBadges: currentBadges,
        totalInteractions: totalInteractions,
        currentStreak: currentStreak,
        uniqueTypesCount: uniqueTypes.length,
        uniqueRelativesCount: uniqueRelatives.length,
        giftCount: giftCount,
        eventCount: eventCount,
        callCount: callCount,
        visitCount: visitCount,
      );

      // Award new badges
      if (newBadges.isNotEmpty) {
        final updatedBadges = [...currentBadges, ...newBadges];
        await _supabase.from('users').update({
          'badges': updatedBadges,
        }).eq('id', userId);

        // Emit badge unlock events and log analytics
        for (final badge in newBadges) {
          _eventsController?.emit(GamificationEvent.badgeUnlocked(
            userId: userId,
            badgeId: badge,
            badgeName: _getBadgeDisplayName(badge),
            badgeDescription: _getBadgeDescription(badge),
          ));
          _analytics?.logBadgeUnlocked(badge);
        }
      }

      return newBadges;
    } catch (e) {
      rethrow;
    }
  }

  /// Get display name for a badge (in Arabic)
  /// Uses dynamic config from admin panel with fallback
  String _getBadgeDisplayName(String badgeId) {
    final badge = _config.getBadge(badgeId);
    if (badge != null) {
      return badge.displayNameAr;
    }
    // Fallback for badges not in admin config
    const Map<String, String> fallbackNames = {
      'first_interaction': 'أول تفاعل',
      'all_interaction_types': 'متنوع',
      'social_butterfly': 'اجتماعي',
      'early_bird': 'طائر الصباح',
      'night_owl': 'بومة الليل',
      'weekend_warrior': 'محارب نهاية الأسبوع',
      'generous_giver': 'كريم',
      'family_gatherer': 'جامع العائلة',
      'frequent_caller': 'كثير الاتصال',
      'devoted_visitor': 'زائر مخلص',
    };
    return fallbackNames[badgeId] ?? badgeId;
  }

  /// Get description for a badge (in Arabic)
  /// Uses dynamic config from admin panel with fallback
  String _getBadgeDescription(String badgeId) {
    final badge = _config.getBadge(badgeId);
    if (badge != null) {
      return badge.descriptionAr;
    }
    // Fallback for badges not in admin config
    const Map<String, String> fallbackDescriptions = {
      'first_interaction': 'سجلت أول تفاعل لك',
      'all_interaction_types': 'استخدمت جميع أنواع التفاعل',
      'social_butterfly': 'تفاعلت مع 10 أقارب مختلفين',
      'early_bird': 'تفاعلت قبل 9 صباحاً',
      'night_owl': 'تفاعلت بعد 9 مساءً',
      'weekend_warrior': '5+ تفاعلات في عطلة نهاية الأسبوع',
      'generous_giver': 'قدمت 10+ هدايا',
      'family_gatherer': 'نظمت 10+ مناسبات عائلية',
      'frequent_caller': 'أجريت 50+ مكالمة',
      'devoted_visitor': 'قمت بـ 25+ زيارة',
    };
    return fallbackDescriptions[badgeId] ?? 'وسام خاص';
  }

  // =====================================================
  // LEVEL SYSTEM (Dynamic from admin panel)
  // =====================================================

  /// Calculate level from total points
  /// Uses dynamic config from admin panel
  int calculateLevel(int points) {
    return _config.calculateLevel(points);
  }

  /// Check if user leveled up and update
  Future<Map<String, dynamic>> checkAndUpdateLevel(String userId) async {
    try {
      // Get user's current level and points
      final userData = await _supabase
          .from('users')
          .select('level, points')
          .eq('id', userId)
          .single();

      final int currentLevel = userData['level'] ?? 1;
      final int points = userData['points'] ?? 0;

      final int newLevel = calculateLevel(points);

      if (newLevel > currentLevel) {
        // User leveled up!
        await _supabase.from('users').update({
          'level': newLevel,
        }).eq('id', userId);

        // Calculate XP to next level (from admin config)
        final int xpToNextLevel = newLevel < _config.maxLevel
            ? _config.getXpForLevel(newLevel + 1) - points
            : 0;

        // Emit level up event
        _eventsController?.emit(GamificationEvent.levelUp(
          userId: userId,
          oldLevel: currentLevel,
          newLevel: newLevel,
          currentXP: points,
          xpToNextLevel: xpToNextLevel,
        ));

        // Log analytics
        _analytics?.logLevelUp(newLevel);

        return {
          'leveled_up': true,
          'old_level': currentLevel,
          'new_level': newLevel,
        };
      }

      return {
        'leveled_up': false,
        'current_level': currentLevel,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Get progress to next level (0.0 - 1.0)
  /// Uses dynamic config from admin panel
  Future<double> getLevelProgress(String userId) async {
    try {
      final userData = await _supabase
          .from('users')
          .select('level, points')
          .eq('id', userId)
          .single();

      final int level = userData['level'] ?? 1;
      final int points = userData['points'] ?? 0;

      if (level >= _config.maxLevel) {
        return 1.0; // Max level
      }

      final int currentLevelXP = _config.getXpForLevel(level);
      final int nextLevelXP = _config.getXpForLevel(level + 1);

      if (nextLevelXP <= currentLevelXP) return 1.0;

      final progress = (points - currentLevelXP) / (nextLevelXP - currentLevelXP);
      return progress.clamp(0.0, 1.0);
    } catch (e) {
      return 0.0;
    }
  }

  // =====================================================
  // ALL-IN-ONE UPDATE
  // =====================================================

  /// Process all gamification updates after an interaction
  Future<Map<String, dynamic>> processInteractionGamification({
    required String userId,
    required Interaction interaction,
  }) async {
    try {
      // 1. Award points
      final points = calculateInteractionPoints(interaction);
      await awardPoints(userId: userId, points: points);

      // 2. Update streak
      final streakResult = await updateStreak(userId);

      // 3. Check badges
      final newBadges = await checkAndAwardBadges(userId);

      // 4. Check level
      final levelResult = await checkAndUpdateLevel(userId);

      return {
        'points_earned': points,
        'streak': streakResult,
        'new_badges': newBadges,
        'level': levelResult,
      };
    } catch (e) {
      rethrow;
    }
  }
}
