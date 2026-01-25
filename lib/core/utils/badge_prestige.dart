import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Badge display info for UI rendering
class BadgeDisplayInfo {
  final String emoji;
  final String name;
  final Color color;

  const BadgeDisplayInfo({
    required this.emoji,
    required this.name,
    required this.color,
  });
}

/// Badge prestige ranking utility
/// Used to determine which badge to display when showing user's "best" badge
class BadgePrestige {
  BadgePrestige._();

  /// Prestige order from highest to lowest
  /// Streak badges are most prestigious, followed by interaction milestones
  static const List<String> prestigeOrder = [
    // Streak badges (highest prestige)
    'streak_365', // 1 year - Crown
    'streak_100', // 100 days
    'streak_30', // 1 month
    'streak_7', // 1 week

    // Interaction milestone badges
    'interactions_1000',
    'interactions_500',
    'interactions_100',
    'interactions_50',
    'interactions_10',

    // Special activity badges
    'all_interaction_types',
    'variety_10',
    'variety_3',
    'social_butterfly',

    // Specific activity badges
    'generous_giver',
    'family_gatherer',
    'frequent_caller',
    'devoted_visitor',

    // Time-based badges
    'early_bird',
    'night_owl',
    'weekend_warrior',

    // Starter badge (lowest prestige)
    'first_interaction',
  ];

  /// Get the highest prestige badge from a list of user badges
  static String? getHighestPrestigeBadge(List<String> userBadges) {
    if (userBadges.isEmpty) return null;

    for (final badge in prestigeOrder) {
      if (userBadges.contains(badge)) {
        return badge;
      }
    }

    // Fallback: return first badge if not in prestige list
    return userBadges.first;
  }

  /// Get badge display info (emoji, name, color) for a badge ID
  static BadgeDisplayInfo getBadgeInfo(String badgeId) {
    return _badgeInfoMap[badgeId] ??
        BadgeDisplayInfo(
          emoji: '🏅',
          name: badgeId,
          color: AppColors.premiumGold,
        );
  }

  static const Map<String, BadgeDisplayInfo> _badgeInfoMap = {
    // Streak badges
    'streak_365': BadgeDisplayInfo(
      emoji: '👑',
      name: 'سنة متواصلة',
      color: AppColors.premiumGold,
    ),
    'streak_100': BadgeDisplayInfo(
      emoji: '💯',
      name: '100 يوم',
      color: AppColors.energeticRed,
    ),
    'streak_30': BadgeDisplayInfo(
      emoji: '⚡',
      name: 'شهر متواصل',
      color: AppColors.energeticRed,
    ),
    'streak_7': BadgeDisplayInfo(
      emoji: '🔥',
      name: 'أسبوع متواصل',
      color: AppColors.energeticRed,
    ),

    // Interaction milestones
    'interactions_1000': BadgeDisplayInfo(
      emoji: '🎖️',
      name: '1000 تفاعل',
      color: AppColors.premiumGold,
    ),
    'interactions_500': BadgeDisplayInfo(
      emoji: '🏆',
      name: '500 تفاعل',
      color: AppColors.premiumGold,
    ),
    'interactions_100': BadgeDisplayInfo(
      emoji: '💫',
      name: '100 تفاعل',
      color: AppColors.islamicGreenPrimary,
    ),
    'interactions_50': BadgeDisplayInfo(
      emoji: '🌟',
      name: '50 تفاعل',
      color: AppColors.islamicGreenPrimary,
    ),
    'interactions_10': BadgeDisplayInfo(
      emoji: '✨',
      name: '10 تفاعلات',
      color: AppColors.islamicGreenPrimary,
    ),

    // Special badges
    'all_interaction_types': BadgeDisplayInfo(
      emoji: '🎨',
      name: 'متنوع',
      color: AppColors.emotionalPurple,
    ),
    'variety_3': BadgeDisplayInfo(
      emoji: '🎨',
      name: 'منوع',
      color: AppColors.calmBlue,
    ),
    'variety_10': BadgeDisplayInfo(
      emoji: '🌐',
      name: 'شبكة علاقات',
      color: AppColors.calmBlue,
    ),
    'social_butterfly': BadgeDisplayInfo(
      emoji: '🦋',
      name: 'اجتماعي',
      color: AppColors.calmBlue,
    ),

    // Activity badges
    'generous_giver': BadgeDisplayInfo(
      emoji: '🎁',
      name: 'كريم',
      color: AppColors.joyfulOrange,
    ),
    'family_gatherer': BadgeDisplayInfo(
      emoji: '👨‍👩‍👧‍👦',
      name: 'جامع العائلة',
      color: AppColors.islamicGreenPrimary,
    ),
    'frequent_caller': BadgeDisplayInfo(
      emoji: '📞',
      name: 'كثير الاتصال',
      color: AppColors.calmBlue,
    ),
    'devoted_visitor': BadgeDisplayInfo(
      emoji: '🏠',
      name: 'زائر مخلص',
      color: AppColors.islamicGreenPrimary,
    ),

    // Time-based badges
    'early_bird': BadgeDisplayInfo(
      emoji: '🌅',
      name: 'طائر الصباح',
      color: AppColors.joyfulOrange,
    ),
    'night_owl': BadgeDisplayInfo(
      emoji: '🦉',
      name: 'بومة الليل',
      color: AppColors.calmBlue,
    ),
    'weekend_warrior': BadgeDisplayInfo(
      emoji: '⚔️',
      name: 'محارب نهاية الأسبوع',
      color: AppColors.emotionalPurple,
    ),

    // Starter badge
    'first_interaction': BadgeDisplayInfo(
      emoji: '🎯',
      name: 'أول تفاعل',
      color: AppColors.islamicGreenPrimary,
    ),
  };
}
