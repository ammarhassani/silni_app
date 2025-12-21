import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../../shared/models/interaction_model.dart';
import '../models/gamification_event.dart';
import '../providers/gamification_events_provider.dart';
import 'analytics_service.dart';

/// Service for managing gamification features
/// Handles points, streaks, badges, and levels
class GamificationService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final AnalyticsService? _analytics;
  final GamificationEventsController? _eventsController;

  GamificationService({
    AnalyticsService? analytics,
    GamificationEventsController? eventsController,
  })  : _analytics = analytics,
        _eventsController = eventsController;

  // =====================================================
  // POINTS SYSTEM
  // =====================================================

  /// Point values for different interaction types
  static const Map<InteractionType, int> _pointsPerInteraction = {
    InteractionType.call: 10,
    InteractionType.visit: 20,
    InteractionType.message: 5,
    InteractionType.gift: 15,
    InteractionType.event: 25,
    InteractionType.other: 5,
  };

  /// Bonus points for adding notes/photos/ratings
  static const int _pointsForNotes = 5;
  static const int _pointsForPhoto = 5;
  static const int _pointsForRating = 3;

  /// Daily point cap to prevent gaming the system
  static const int _dailyPointCap = 200;

  /// Calculate points for an interaction
  int calculateInteractionPoints(Interaction interaction) {
    int points = _pointsPerInteraction[interaction.type] ?? 5;

    // Bonus for adding details
    if (interaction.notes != null && interaction.notes!.isNotEmpty) {
      points += _pointsForNotes;
    }
    if (interaction.photoUrls.isNotEmpty) {
      points += _pointsForPhoto;
    }
    if (interaction.rating != null) {
      points += _pointsForRating;
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

      // Apply daily cap
      if (pointsEarnedToday >= _dailyPointCap) {
        return;
      }

      final pointsToAward = (pointsEarnedToday + points > _dailyPointCap)
          ? _dailyPointCap - pointsEarnedToday
          : points;

      if (pointsToAward <= 0) return;

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
      if (kDebugMode) {
        print('❌ [Gamification] Failed to award points: $e');
      }
      rethrow;
    }
  }

  // =====================================================
  // STREAK TRACKING (24h-based, Snapchat-like)
  // =====================================================

  /// Update user's streak after an interaction
  ///
  /// Streak Logic (24h-based):
  /// - Timer resets to 24h on EVERY interaction
  /// - Streak increments once per 24h period (24-48h since last)
  /// - Streak breaks if > 48h pass without interaction
  Future<Map<String, dynamic>> updateStreak(String userId) async {
    try {
      // Get user's current streak data and last interaction timestamp
      final userData = await _supabase
          .from('users')
          .select('current_streak, longest_streak, last_interaction_at')
          .eq('id', userId)
          .single();

      final int currentStreak = userData['current_streak'] ?? 0;
      final int longestStreak = userData['longest_streak'] ?? 0;
      final String? lastInteractionAtStr = userData['last_interaction_at'];

      final now = DateTime.now();
      int newStreak;
      bool streakIncreased = false;

      if (lastInteractionAtStr == null) {
        // First interaction ever - start streak at 1
        newStreak = 1;
        streakIncreased = true;
      } else {
        final lastInteraction = DateTime.parse(lastInteractionAtStr);
        final hoursSinceLast = now.difference(lastInteraction).inHours;

        if (hoursSinceLast > 48) {
          // More than 48h passed - streak broken completely
          newStreak = 1;
          streakIncreased = true; // New streak starts
        } else if (hoursSinceLast >= 24) {
          // 24-48h window - new day earned, increment streak
          newStreak = currentStreak + 1;
          streakIncreased = true;
        } else {
          // Within 24h - same period, no increment (but timer resets)
          newStreak = currentStreak;
          streakIncreased = false;
        }
      }

      // Update longest streak if necessary
      final newLongestStreak = newStreak > longestStreak ? newStreak : longestStreak;

      // ALWAYS update last_interaction_at (resets the 24h timer display)
      await _supabase.from('users').update({
        'current_streak': newStreak,
        'longest_streak': newLongestStreak,
        'last_interaction_at': now.toUtc().toIso8601String(), // Full timestamp
      }).eq('id', userId);

      // Emit streak events
      if (streakIncreased) {
        _eventsController?.emit(GamificationEvent.streakIncreased(
          userId: userId,
          currentStreak: newStreak,
          longestStreak: newLongestStreak,
        ));

        // Check for milestone
        if (GamificationEvent.isStreakMilestone(newStreak)) {
          _eventsController?.emit(GamificationEvent.streakMilestone(
            userId: userId,
            streak: newStreak,
          ));
          _analytics?.logStreakMilestone(newStreak);
        }
      }

      return {
        'current_streak': newStreak,
        'longest_streak': newLongestStreak,
        'streak_increased': streakIncreased,
        'last_interaction_at': now.toUtc().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Gamification] Failed to update streak: $e');
      }
      rethrow;
    }
  }

  // =====================================================
  // BADGE SYSTEM
  // =====================================================

  /// Check and award new badges to user
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

      final List<String> newBadges = [];

      // Get all user interactions for analysis
      final interactions = await _supabase
          .from('interactions')
          .select('*')
          .eq('user_id', userId);

      // Check consistency badges
      if (totalInteractions >= 1 && !currentBadges.contains('first_interaction')) {
        newBadges.add('first_interaction');
      }
      if (currentStreak >= 7 && !currentBadges.contains('streak_7')) {
        newBadges.add('streak_7');
      }
      if (currentStreak >= 30 && !currentBadges.contains('streak_30')) {
        newBadges.add('streak_30');
      }
      if (currentStreak >= 100 && !currentBadges.contains('streak_100')) {
        newBadges.add('streak_100');
      }
      if (currentStreak >= 365 && !currentBadges.contains('streak_365')) {
        newBadges.add('streak_365');
      }

      // Check volume badges
      if (totalInteractions >= 10 && !currentBadges.contains('interactions_10')) {
        newBadges.add('interactions_10');
      }
      if (totalInteractions >= 50 && !currentBadges.contains('interactions_50')) {
        newBadges.add('interactions_50');
      }
      if (totalInteractions >= 100 && !currentBadges.contains('interactions_100')) {
        newBadges.add('interactions_100');
      }
      if (totalInteractions >= 500 && !currentBadges.contains('interactions_500')) {
        newBadges.add('interactions_500');
      }
      if (totalInteractions >= 1000 && !currentBadges.contains('interactions_1000')) {
        newBadges.add('interactions_1000');
      }

      // Check variety badges
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

      if (uniqueTypes.length >= 6 && !currentBadges.contains('all_interaction_types')) {
        newBadges.add('all_interaction_types');
      }
      if (uniqueRelatives.length >= 10 && !currentBadges.contains('social_butterfly')) {
        newBadges.add('social_butterfly');
      }

      // Check special badges
      if (giftCount >= 10 && !currentBadges.contains('generous_giver')) {
        newBadges.add('generous_giver');
      }
      if (eventCount >= 10 && !currentBadges.contains('family_gatherer')) {
        newBadges.add('family_gatherer');
      }
      if (callCount >= 50 && !currentBadges.contains('frequent_caller')) {
        newBadges.add('frequent_caller');
      }
      if (visitCount >= 25 && !currentBadges.contains('devoted_visitor')) {
        newBadges.add('devoted_visitor');
      }

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
      if (kDebugMode) {
        print('❌ [Gamification] Failed to check badges: $e');
      }
      rethrow;
    }
  }

  /// Get display name for a badge (in Arabic)
  String _getBadgeDisplayName(String badgeId) {
    const Map<String, String> badgeNames = {
      'first_interaction': 'أول تفاعل',
      'streak_7': 'أسبوع متواصل',
      'streak_30': 'شهر متواصل',
      'streak_100': '100 يوم',
      'streak_365': 'سنة متواصلة',
      'interactions_10': '10 تفاعلات',
      'interactions_50': '50 تفاعل',
      'interactions_100': '100 تفاعل',
      'interactions_500': '500 تفاعل',
      'interactions_1000': '1000 تفاعل',
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
    return badgeNames[badgeId] ?? badgeId;
  }

  /// Get description for a badge (in Arabic)
  String _getBadgeDescription(String badgeId) {
    const Map<String, String> badgeDescriptions = {
      'first_interaction': 'سجلت أول تفاعل لك',
      'streak_7': 'تفاعلت لمدة 7 أيام متتالية',
      'streak_30': 'تفاعلت لمدة 30 يوم متتالي',
      'streak_100': 'تفاعلت لمدة 100 يوم متتالي',
      'streak_365': 'تفاعلت لمدة سنة كاملة',
      'interactions_10': 'أكملت 10 تفاعلات',
      'interactions_50': 'أكملت 50 تفاعل',
      'interactions_100': 'أكملت 100 تفاعل',
      'interactions_500': 'أكملت 500 تفاعل',
      'interactions_1000': 'أكملت 1000 تفاعل',
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
    return badgeDescriptions[badgeId] ?? 'وسام خاص';
  }

  // =====================================================
  // LEVEL SYSTEM
  // =====================================================

  /// XP required for each level (exponential growth)
  static const List<int> _xpPerLevel = [
    0, // Level 1
    100, // Level 2
    250, // Level 3
    500, // Level 4
    1000, // Level 5
    2000, // Level 6
    3500, // Level 7
    5500, // Level 8
    8000, // Level 9
    12000, // Level 10
  ];

  /// Calculate level from total points
  int calculateLevel(int points) {
    for (int i = _xpPerLevel.length - 1; i >= 0; i--) {
      if (points >= _xpPerLevel[i]) {
        return i + 1;
      }
    }
    return 1;
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

        // Calculate XP to next level
        final int xpToNextLevel = newLevel < _xpPerLevel.length
            ? _xpPerLevel[newLevel] - points
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
      if (kDebugMode) {
        print('❌ [Gamification] Failed to check level: $e');
      }
      rethrow;
    }
  }

  /// Get progress to next level (0.0 - 1.0)
  Future<double> getLevelProgress(String userId) async {
    try {
      final userData = await _supabase
          .from('users')
          .select('level, points')
          .eq('id', userId)
          .single();

      final int level = userData['level'] ?? 1;
      final int points = userData['points'] ?? 0;

      if (level >= _xpPerLevel.length) {
        return 1.0; // Max level
      }

      final int currentLevelXP = _xpPerLevel[level - 1];
      final int nextLevelXP = _xpPerLevel[level];

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
      if (kDebugMode) {
        print('❌ [Gamification] Failed to process: $e');
      }
      rethrow;
    }
  }
}
