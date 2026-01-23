import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/interaction_model.dart';
import 'cache_config_service.dart';

/// Service for fetching gamification configuration from admin panel (Supabase)
/// Provides dynamic configuration for points, badges, levels, and streaks.
class GamificationConfigService {
  GamificationConfigService._();
  static final GamificationConfigService instance = GamificationConfigService._();

  // Use lazy initialization to avoid accessing Supabase before it's initialized
  SupabaseClient get _supabase => Supabase.instance.client;

  // Cached configs
  Map<String, PointsConfig>? _pointsConfigCache;
  List<BadgeConfig>? _badgesCache;
  List<LevelConfig>? _levelsCache;
  List<ChallengeConfig>? _challengesCache;
  StreakConfig? _streakConfigCache;
  DateTime? _lastFetchTime;

  // Cache duration from remote config
  final CacheConfigService _cacheConfig = CacheConfigService();
  static const String _serviceKey = 'gamification_config';

  bool get _isCacheValid {
    if (_lastFetchTime == null) return false;
    return !_cacheConfig.isCacheExpired(_serviceKey, _lastFetchTime);
  }

  /// Check if config is loaded
  bool get isLoaded => _lastFetchTime != null;

  /// Initialize and load all gamification configs
  Future<void> initialize() async {
    if (!_isCacheValid) {
      await refresh();
    }
  }

  /// Refresh all configs from server
  Future<void> refresh() async {
    try {
      await Future.wait([
        _fetchPointsConfig(),
        _fetchBadges(),
        _fetchLevels(),
        _fetchChallenges(),
        _fetchStreakConfig(),
      ]);
      _lastFetchTime = DateTime.now();
    } catch (_) {
      // Config refresh failed silently
    }
  }

  /// Clear cache
  void clearCache() {
    _pointsConfigCache = null;
    _badgesCache = null;
    _levelsCache = null;
    _challengesCache = null;
    _streakConfigCache = null;
    _lastFetchTime = null;
  }

  // ============ Points Config ============

  Future<void> _fetchPointsConfig() async {
    try {
      final response = await _supabase
          .from('admin_points_config')
          .select()
          .eq('is_active', true);
      final configs = (response as List)
          .map((json) => PointsConfig.fromJson(json))
          .toList();
      _pointsConfigCache = {for (var c in configs) c.interactionType: c};
    } catch (_) {
      // Points config fetch failed silently
    }
  }

  /// Get points config for an interaction type
  PointsConfig getPointsConfig(InteractionType type) {
    final typeStr = type.name;
    final config = _pointsConfigCache?[typeStr];
    if (config != null) {
      return config;
    }
    return PointsConfig.fallback(typeStr);
  }

  /// Get daily point cap (uses MAX of all interaction types for global cap)
  /// This ensures if any interaction type has a higher cap, that's used globally
  int get dailyPointCap {
    if (_pointsConfigCache == null || _pointsConfigCache!.isEmpty) {
      return 200;
    }
    // Use the MAX daily cap across all interaction types
    final maxCap = _pointsConfigCache!.values
        .map((c) => c.dailyCap)
        .reduce((a, b) => a > b ? a : b);
    return maxCap;
  }

  /// Get notes bonus (consistent across all types, use first)
  int get notesBonus {
    final bonus = _pointsConfigCache?.values.firstOrNull?.notesBonus ?? 5;
    return bonus;
  }

  /// Get photo bonus (consistent across all types, use first)
  int get photoBonus {
    final bonus = _pointsConfigCache?.values.firstOrNull?.photoBonus ?? 5;
    return bonus;
  }

  /// Get rating bonus (consistent across all types, use first)
  int get ratingBonus {
    final bonus = _pointsConfigCache?.values.firstOrNull?.ratingBonus ?? 3;
    return bonus;
  }

  // ============ Badges Config ============

  Future<void> _fetchBadges() async {
    try {
      final response = await _supabase
          .from('admin_badges')
          .select()
          .eq('is_active', true)
          .order('sort_order');
      _badgesCache = (response as List)
          .map((json) => BadgeConfig.fromJson(json))
          .toList();
    } catch (_) {
      // Badges fetch failed silently
    }
  }

  /// Get badges config - uses fallback if cache is empty or null
  List<BadgeConfig> get badges {
    if (_badgesCache == null || _badgesCache!.isEmpty) {
      return BadgeConfig.fallbackBadges();
    }
    return _badgesCache!;
  }

  /// Get badge by key
  BadgeConfig? getBadge(String badgeKey) {
    return badges.cast<BadgeConfig?>().firstWhere(
          (b) => b?.badgeKey == badgeKey,
          orElse: () => null,
        );
  }

  /// Get badges by category
  List<BadgeConfig> getBadgesByCategory(String category) {
    return badges.where((b) => b.category == category).toList();
  }

  /// Get streak badges (sorted by threshold)
  List<BadgeConfig> get streakBadges {
    return badges
        .where((b) => b.thresholdType == 'streak_days')
        .toList()
      ..sort((a, b) => a.thresholdValue.compareTo(b.thresholdValue));
  }

  /// Get volume badges (sorted by threshold)
  List<BadgeConfig> get volumeBadges {
    return badges
        .where((b) => b.thresholdType == 'total_interactions')
        .toList()
      ..sort((a, b) => a.thresholdValue.compareTo(b.thresholdValue));
  }

  /// Get special badges (custom threshold types, excludes first_interaction which is in achievementBadges)
  List<BadgeConfig> get specialBadges {
    return badges
        .where((b) => !['streak_days', 'total_interactions', 'first_interaction'].contains(b.thresholdType))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Check if a badge should be awarded based on user stats
  /// Returns list of badge keys that should be awarded
  List<String> checkBadgeEligibility({
    required List<String> currentBadges,
    required int totalInteractions,
    required int currentStreak,
    int uniqueTypesCount = 0,
    int uniqueRelativesCount = 0,
    int giftCount = 0,
    int eventCount = 0,
    int callCount = 0,
    int visitCount = 0,
  }) {
    final List<String> eligibleBadges = [];

    for (final badge in badges) {
      // Skip if already has this badge
      if (currentBadges.contains(badge.badgeKey)) continue;

      // Check based on threshold type
      bool shouldAward = false;

      switch (badge.thresholdType) {
        case 'streak_days':
          shouldAward = currentStreak >= badge.thresholdValue;
          break;
        case 'total_interactions':
          shouldAward = totalInteractions >= badge.thresholdValue;
          break;
        case 'unique_interaction_types':
          shouldAward = uniqueTypesCount >= badge.thresholdValue;
          break;
        case 'unique_relatives':
          shouldAward = uniqueRelativesCount >= badge.thresholdValue;
          break;
        case 'gift_count':
          shouldAward = giftCount >= badge.thresholdValue;
          break;
        case 'event_count':
          shouldAward = eventCount >= badge.thresholdValue;
          break;
        case 'call_count':
          shouldAward = callCount >= badge.thresholdValue;
          break;
        case 'visit_count':
          shouldAward = visitCount >= badge.thresholdValue;
          break;
        case 'first_interaction':
          shouldAward = totalInteractions >= 1;
          break;
        default:
          // Custom/unknown threshold type - don't auto-award
          break;
      }

      if (shouldAward) {
        eligibleBadges.add(badge.badgeKey);
      }
    }

    return eligibleBadges;
  }

  // ============ Levels Config ============

  Future<void> _fetchLevels() async {
    try {
      final response = await _supabase
          .from('admin_levels')
          .select()
          .order('level');
      _levelsCache = (response as List)
          .map((json) => LevelConfig.fromJson(json))
          .toList()
        // Ensure levels are sorted ASCENDING by level number (required for calculateLevel)
        ..sort((a, b) => a.level.compareTo(b.level));
    } catch (_) {
      // Levels fetch failed silently
    }
  }

  /// Get levels config - uses fallback if cache is empty or null
  List<LevelConfig> get levels {
    if (_levelsCache == null || _levelsCache!.isEmpty) {
      return LevelConfig.fallbackLevels();
    }
    return _levelsCache!;
  }

  /// Get level config by level number
  LevelConfig? getLevel(int level) {
    return levels.cast<LevelConfig?>().firstWhere(
          (l) => l?.level == level,
          orElse: () => null,
        );
  }

  /// Calculate level from total XP
  /// Iterates from highest level to lowest, returns first level where xp >= xpRequired
  int calculateLevel(int xp) {
    final lvls = levels;
    // Iterate from highest level to lowest
    for (int i = lvls.length - 1; i >= 0; i--) {
      if (xp >= lvls[i].xpRequired) {
        return lvls[i].level;
      }
    }
    return 1;
  }

  /// Get XP required for a specific level
  int getXpForLevel(int level) {
    return getLevel(level)?.xpRequired ?? 0;
  }

  /// Get max level
  int get maxLevel => levels.isNotEmpty ? levels.last.level : 10;

  // ============ Streak Config ============

  Future<void> _fetchStreakConfig() async {
    try {
      final response = await _supabase
          .from('admin_streak_config')
          .select()
          .eq('is_active', true)
          .single();
      _streakConfigCache = StreakConfig.fromJson(response);
    } catch (_) {
      // Streak config fetch failed silently
    }
  }

  StreakConfig get streakConfig => _streakConfigCache ?? StreakConfig.fallback();

  // ============ Challenges Config ============

  Future<void> _fetchChallenges() async {
    try {
      final now = DateTime.now();
      final response = await _supabase
          .from('admin_challenges')
          .select()
          .eq('is_active', true)
          .order('sort_order');

      _challengesCache = (response as List)
          .map((json) => ChallengeConfig.fromJson(json))
          .where((c) => c.isAvailable(now))
          .toList();
    } catch (_) {
      // Challenges fetch failed silently
    }
  }

  /// Get all active challenges
  List<ChallengeConfig> get challenges {
    if (_challengesCache == null || _challengesCache!.isEmpty) {
      return ChallengeConfig.fallbackChallenges();
    }
    return _challengesCache!;
  }

  /// Get challenges by type (daily, weekly, monthly, special, seasonal)
  List<ChallengeConfig> getChallengesByType(String type) {
    return challenges.where((c) => c.type == type).toList();
  }

  /// Get daily challenges
  List<ChallengeConfig> get dailyChallenges => getChallengesByType('daily');

  /// Get weekly challenges
  List<ChallengeConfig> get weeklyChallenges => getChallengesByType('weekly');

  /// Get monthly challenges
  List<ChallengeConfig> get monthlyChallenges => getChallengesByType('monthly');

  /// Get special/seasonal challenges
  List<ChallengeConfig> get specialChallenges {
    return challenges.where((c) => c.type == 'special' || c.type == 'seasonal').toList();
  }

  /// Get challenge by key
  ChallengeConfig? getChallenge(String challengeKey) {
    return challenges.cast<ChallengeConfig?>().firstWhere(
          (c) => c?.challengeKey == challengeKey,
          orElse: () => null,
        );
  }

  /// Check challenge progress
  /// Returns progress percentage (0.0 to 1.0)
  double checkChallengeProgress({
    required ChallengeConfig challenge,
    required int currentValue,
  }) {
    if (challenge.requirementValue <= 0) return 1.0;
    return (currentValue / challenge.requirementValue).clamp(0.0, 1.0);
  }

  /// Check if challenge is completed
  bool isChallengeCompleted({
    required ChallengeConfig challenge,
    required int currentValue,
  }) {
    return currentValue >= challenge.requirementValue;
  }
}

// ============ Config Models ============

class PointsConfig {
  final String interactionType;
  final String displayNameAr;
  final String? displayNameEn;
  final int basePoints;
  final int notesBonus;
  final int photoBonus;
  final int ratingBonus;
  final double firstOfDayMultiplier;
  final int dailyCap;
  final String icon;
  final String colorHex;

  PointsConfig({
    required this.interactionType,
    required this.displayNameAr,
    this.displayNameEn,
    required this.basePoints,
    required this.notesBonus,
    required this.photoBonus,
    required this.ratingBonus,
    required this.firstOfDayMultiplier,
    required this.dailyCap,
    required this.icon,
    required this.colorHex,
  });

  factory PointsConfig.fromJson(Map<String, dynamic> json) {
    return PointsConfig(
      interactionType: json['interaction_type'] as String,
      displayNameAr: json['display_name_ar'] as String,
      displayNameEn: json['display_name_en'] as String?,
      basePoints: json['base_points'] as int? ?? 10,
      notesBonus: json['notes_bonus'] as int? ?? 5,
      photoBonus: json['photo_bonus'] as int? ?? 5,
      ratingBonus: json['rating_bonus'] as int? ?? 3,
      firstOfDayMultiplier: (json['first_of_day_multiplier'] as num?)?.toDouble() ?? 1.5,
      dailyCap: json['daily_cap'] as int? ?? 200,
      icon: json['icon'] as String? ?? 'star',
      colorHex: json['color_hex'] as String? ?? '#D4AF37',
    );
  }

  factory PointsConfig.fallback(String type) {
    final defaults = {
      'call': (points: 10, name: 'مكالمة', icon: 'phone'),
      'visit': (points: 20, name: 'زيارة', icon: 'home'),
      'message': (points: 5, name: 'رسالة', icon: 'message-circle'),
      'gift': (points: 15, name: 'هدية', icon: 'gift'),
      'event': (points: 25, name: 'مناسبة', icon: 'calendar'),
      'other': (points: 5, name: 'أخرى', icon: 'more-horizontal'),
    };
    final config = defaults[type] ?? (points: 5, name: type, icon: 'star');

    return PointsConfig(
      interactionType: type,
      displayNameAr: config.name,
      basePoints: config.points,
      notesBonus: 5,
      photoBonus: 5,
      ratingBonus: 3,
      firstOfDayMultiplier: 1.5,
      dailyCap: 200,
      icon: config.icon,
      colorHex: '#D4AF37',
    );
  }
}

class BadgeConfig {
  final String badgeKey;
  final String displayNameAr;
  final String? displayNameEn;
  final String descriptionAr;
  final String? descriptionEn;
  final String emoji;
  final String category;
  final String thresholdType;
  final int thresholdValue;
  final int xpReward;
  final bool isSecret;
  final int sortOrder;

  BadgeConfig({
    required this.badgeKey,
    required this.displayNameAr,
    this.displayNameEn,
    required this.descriptionAr,
    this.descriptionEn,
    required this.emoji,
    required this.category,
    required this.thresholdType,
    required this.thresholdValue,
    required this.xpReward,
    required this.isSecret,
    required this.sortOrder,
  });

  factory BadgeConfig.fromJson(Map<String, dynamic> json) {
    return BadgeConfig(
      badgeKey: json['badge_key'] as String,
      displayNameAr: json['display_name_ar'] as String,
      displayNameEn: json['display_name_en'] as String?,
      descriptionAr: json['description_ar'] as String,
      descriptionEn: json['description_en'] as String?,
      emoji: json['emoji'] as String,
      category: json['category'] as String? ?? 'milestone',
      thresholdType: json['threshold_type'] as String? ?? 'custom',
      thresholdValue: json['threshold_value'] as int? ?? 0,
      xpReward: json['xp_reward'] as int? ?? 100,
      isSecret: json['is_secret'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  static List<BadgeConfig> fallbackBadges() {
    return [
      // First interaction badge (milestone)
      BadgeConfig(badgeKey: 'first_interaction', displayNameAr: 'أول تفاعل', descriptionAr: 'سجلت أول تفاعل لك', emoji: '🎯', category: 'milestone', thresholdType: 'first_interaction', thresholdValue: 1, xpReward: 25, isSecret: false, sortOrder: 0),
      // Streak badges
      BadgeConfig(badgeKey: 'streak_7', displayNameAr: 'أسبوع التواصل', descriptionAr: 'حافظ على التواصل لمدة 7 أيام', emoji: '🔥', category: 'streak', thresholdType: 'streak_days', thresholdValue: 7, xpReward: 100, isSecret: false, sortOrder: 1),
      BadgeConfig(badgeKey: 'streak_30', displayNameAr: 'شهر التواصل', descriptionAr: 'حافظ على التواصل لمدة 30 يوم', emoji: '💪', category: 'streak', thresholdType: 'streak_days', thresholdValue: 30, xpReward: 500, isSecret: false, sortOrder: 2),
      BadgeConfig(badgeKey: 'streak_100', displayNameAr: 'قرن التواصل', descriptionAr: 'حافظ على التواصل لمدة 100 يوم', emoji: '👑', category: 'streak', thresholdType: 'streak_days', thresholdValue: 100, xpReward: 2000, isSecret: false, sortOrder: 3),
      BadgeConfig(badgeKey: 'streak_365', displayNameAr: 'سنة التواصل', descriptionAr: 'حافظ على التواصل لمدة سنة', emoji: '🏆', category: 'streak', thresholdType: 'streak_days', thresholdValue: 365, xpReward: 10000, isSecret: false, sortOrder: 4),
      // Volume badges
      BadgeConfig(badgeKey: 'interactions_10', displayNameAr: 'بداية الطريق', descriptionAr: 'أكمل 10 تفاعلات', emoji: '🌱', category: 'volume', thresholdType: 'total_interactions', thresholdValue: 10, xpReward: 50, isSecret: false, sortOrder: 10),
      BadgeConfig(badgeKey: 'interactions_50', displayNameAr: 'واصل متمكن', descriptionAr: 'أكمل 50 تفاعل', emoji: '🌿', category: 'volume', thresholdType: 'total_interactions', thresholdValue: 50, xpReward: 200, isSecret: false, sortOrder: 11),
      BadgeConfig(badgeKey: 'interactions_100', displayNameAr: 'واصل محترف', descriptionAr: 'أكمل 100 تفاعل', emoji: '🌳', category: 'volume', thresholdType: 'total_interactions', thresholdValue: 100, xpReward: 500, isSecret: false, sortOrder: 12),
      BadgeConfig(badgeKey: 'interactions_500', displayNameAr: 'واصل خبير', descriptionAr: 'أكمل 500 تفاعل', emoji: '🏅', category: 'volume', thresholdType: 'total_interactions', thresholdValue: 500, xpReward: 2000, isSecret: false, sortOrder: 13),
      BadgeConfig(badgeKey: 'interactions_1000', displayNameAr: 'واصل أسطوري', descriptionAr: 'أكمل 1000 تفاعل', emoji: '🎖️', category: 'volume', thresholdType: 'total_interactions', thresholdValue: 1000, xpReward: 5000, isSecret: false, sortOrder: 14),
      // Special badges
      BadgeConfig(badgeKey: 'all_interaction_types', displayNameAr: 'متنوع', descriptionAr: 'استخدمت جميع أنواع التفاعل', emoji: '🎨', category: 'special', thresholdType: 'unique_interaction_types', thresholdValue: 6, xpReward: 300, isSecret: false, sortOrder: 20),
      BadgeConfig(badgeKey: 'social_butterfly', displayNameAr: 'اجتماعي', descriptionAr: 'تفاعلت مع 10 أقارب مختلفين', emoji: '🦋', category: 'special', thresholdType: 'unique_relatives', thresholdValue: 10, xpReward: 200, isSecret: false, sortOrder: 21),
      BadgeConfig(badgeKey: 'generous_giver', displayNameAr: 'كريم', descriptionAr: 'قدمت 10+ هدايا', emoji: '🎁', category: 'special', thresholdType: 'gift_count', thresholdValue: 10, xpReward: 150, isSecret: false, sortOrder: 22),
      BadgeConfig(badgeKey: 'family_gatherer', displayNameAr: 'جامع العائلة', descriptionAr: 'نظمت 10+ مناسبات عائلية', emoji: '👨‍👩‍👧‍👦', category: 'special', thresholdType: 'event_count', thresholdValue: 10, xpReward: 150, isSecret: false, sortOrder: 23),
      BadgeConfig(badgeKey: 'frequent_caller', displayNameAr: 'كثير الاتصال', descriptionAr: 'أجريت 50+ مكالمة', emoji: '📞', category: 'special', thresholdType: 'call_count', thresholdValue: 50, xpReward: 200, isSecret: false, sortOrder: 24),
      BadgeConfig(badgeKey: 'devoted_visitor', displayNameAr: 'زائر مخلص', descriptionAr: 'قمت بـ 25+ زيارة', emoji: '🏠', category: 'special', thresholdType: 'visit_count', thresholdValue: 25, xpReward: 200, isSecret: false, sortOrder: 25),
    ];
  }
}

class LevelConfig {
  final int level;
  final String titleAr;
  final String? titleEn;
  final int xpRequired;
  final int? xpToNext;
  final String? icon;
  final String? colorHex;
  final List<dynamic> perks;

  LevelConfig({
    required this.level,
    required this.titleAr,
    this.titleEn,
    required this.xpRequired,
    this.xpToNext,
    this.icon,
    this.colorHex,
    required this.perks,
  });

  factory LevelConfig.fromJson(Map<String, dynamic> json) {
    return LevelConfig(
      level: json['level'] as int,
      titleAr: json['title_ar'] as String,
      titleEn: json['title_en'] as String?,
      xpRequired: json['xp_required'] as int,
      xpToNext: json['xp_to_next'] as int?,
      icon: json['icon'] as String?,
      colorHex: json['color_hex'] as String?,
      perks: json['perks'] as List<dynamic>? ?? [],
    );
  }

  static List<LevelConfig> fallbackLevels() {
    return [
      LevelConfig(level: 1, titleAr: 'مبتدئ', titleEn: 'Beginner', xpRequired: 0, xpToNext: 100, perks: []),
      LevelConfig(level: 2, titleAr: 'متعلم', titleEn: 'Learner', xpRequired: 100, xpToNext: 150, perks: []),
      LevelConfig(level: 3, titleAr: 'متقدم', titleEn: 'Advanced', xpRequired: 250, xpToNext: 250, perks: []),
      LevelConfig(level: 4, titleAr: 'ماهر', titleEn: 'Skilled', xpRequired: 500, xpToNext: 500, perks: []),
      LevelConfig(level: 5, titleAr: 'محترف', titleEn: 'Professional', xpRequired: 1000, xpToNext: 1000, perks: []),
      LevelConfig(level: 6, titleAr: 'خبير', titleEn: 'Expert', xpRequired: 2000, xpToNext: 1500, perks: []),
      LevelConfig(level: 7, titleAr: 'أستاذ', titleEn: 'Master', xpRequired: 3500, xpToNext: 2000, perks: []),
      LevelConfig(level: 8, titleAr: 'عبقري', titleEn: 'Genius', xpRequired: 5500, xpToNext: 2500, perks: []),
      LevelConfig(level: 9, titleAr: 'أسطورة', titleEn: 'Legend', xpRequired: 8000, xpToNext: 4000, perks: []),
      LevelConfig(level: 10, titleAr: 'واصل', titleEn: 'Wasel', xpRequired: 12000, xpToNext: null, perks: []),
    ];
  }
}

class StreakConfig {
  final int deadlineHours;
  final int endangeredThresholdHours;
  final int criticalThresholdMinutes;
  final int gracePeriodHours;
  final List<int> freezeAwardMilestones;
  final List<int> celebrationMilestones;
  final int maxFreezes;
  final int freezeCostPoints;
  final bool streakRestoreEnabled;
  final int streakRestoreCostPoints;

  StreakConfig({
    required this.deadlineHours,
    required this.endangeredThresholdHours,
    required this.criticalThresholdMinutes,
    required this.gracePeriodHours,
    required this.freezeAwardMilestones,
    required this.celebrationMilestones,
    required this.maxFreezes,
    required this.freezeCostPoints,
    required this.streakRestoreEnabled,
    required this.streakRestoreCostPoints,
  });

  factory StreakConfig.fromJson(Map<String, dynamic> json) {
    return StreakConfig(
      deadlineHours: json['deadline_hours'] as int? ?? 26,
      endangeredThresholdHours: json['endangered_threshold_hours'] as int? ?? 4,
      criticalThresholdMinutes: json['critical_threshold_minutes'] as int? ?? 60,
      gracePeriodHours: json['grace_period_hours'] as int? ?? 2,
      freezeAwardMilestones: (json['freeze_award_milestones'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [7, 30, 100],
      celebrationMilestones: (json['celebration_milestones'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [3, 7, 10, 14, 21, 30, 50, 100, 200, 365, 500],
      maxFreezes: json['max_freezes'] as int? ?? 3,
      freezeCostPoints: json['freeze_cost_points'] as int? ?? 0,
      streakRestoreEnabled: json['streak_restore_enabled'] as bool? ?? false,
      streakRestoreCostPoints: json['streak_restore_cost_points'] as int? ?? 500,
    );
  }

  factory StreakConfig.fallback() {
    return StreakConfig(
      deadlineHours: 26,
      endangeredThresholdHours: 4,
      criticalThresholdMinutes: 60,
      gracePeriodHours: 2,
      freezeAwardMilestones: [7, 30, 100],
      celebrationMilestones: [3, 7, 10, 14, 21, 30, 50, 100, 200, 365, 500],
      maxFreezes: 3,
      freezeCostPoints: 0,
      streakRestoreEnabled: false,
      streakRestoreCostPoints: 500,
    );
  }

  /// Check if a streak count is a freeze award milestone
  bool isFreezeAwardMilestone(int streak) {
    return freezeAwardMilestones.contains(streak);
  }

  /// Check if a streak count is a celebration milestone (triggers notification/confetti)
  bool isCelebrationMilestone(int streak) {
    return celebrationMilestones.contains(streak);
  }
}

class ChallengeConfig {
  final String challengeKey;
  final String titleAr;
  final String? titleEn;
  final String descriptionAr;
  final String? descriptionEn;
  final String type; // daily, weekly, monthly, special, seasonal
  final String requirementType; // interaction_count, unique_relatives, specific_type, streak, custom
  final int requirementValue;
  final Map<String, dynamic> requirementMetadata;
  final int xpReward;
  final int pointsReward;
  final String? badgeReward;
  final String icon;
  final String colorHex;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isRecurring;
  final int sortOrder;

  ChallengeConfig({
    required this.challengeKey,
    required this.titleAr,
    this.titleEn,
    required this.descriptionAr,
    this.descriptionEn,
    required this.type,
    required this.requirementType,
    required this.requirementValue,
    required this.requirementMetadata,
    required this.xpReward,
    required this.pointsReward,
    this.badgeReward,
    required this.icon,
    required this.colorHex,
    this.startDate,
    this.endDate,
    required this.isRecurring,
    required this.sortOrder,
  });

  factory ChallengeConfig.fromJson(Map<String, dynamic> json) {
    return ChallengeConfig(
      challengeKey: json['challenge_key'] as String,
      titleAr: json['title_ar'] as String,
      titleEn: json['title_en'] as String?,
      descriptionAr: json['description_ar'] as String,
      descriptionEn: json['description_en'] as String?,
      type: json['type'] as String? ?? 'daily',
      requirementType: json['requirement_type'] as String? ?? 'interaction_count',
      requirementValue: json['requirement_value'] as int? ?? 1,
      requirementMetadata: (json['requirement_metadata'] as Map<String, dynamic>?) ?? {},
      xpReward: json['xp_reward'] as int? ?? 50,
      pointsReward: json['points_reward'] as int? ?? 0,
      badgeReward: json['badge_reward'] as String?,
      icon: json['icon'] as String? ?? 'target',
      colorHex: json['color_hex'] as String? ?? '#008080',
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
      isRecurring: json['is_recurring'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  /// Check if the challenge is currently available (within date range if specified)
  bool isAvailable(DateTime now) {
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  /// Get display title (Arabic or English based on locale)
  String getTitle({bool useArabic = true}) {
    if (useArabic) return titleAr;
    return titleEn ?? titleAr;
  }

  /// Get display description (Arabic or English based on locale)
  String getDescription({bool useArabic = true}) {
    if (useArabic) return descriptionAr;
    return descriptionEn ?? descriptionAr;
  }

  static List<ChallengeConfig> fallbackChallenges() {
    return [
      // Daily challenges
      ChallengeConfig(
        challengeKey: 'daily_interaction',
        titleAr: 'تفاعل اليوم',
        titleEn: 'Daily Interaction',
        descriptionAr: 'سجل تفاعلاً واحداً على الأقل اليوم',
        descriptionEn: 'Log at least one interaction today',
        type: 'daily',
        requirementType: 'interaction_count',
        requirementValue: 1,
        requirementMetadata: {},
        xpReward: 25,
        pointsReward: 10,
        icon: 'check-circle',
        colorHex: '#4CAF50',
        isRecurring: true,
        sortOrder: 0,
      ),
      ChallengeConfig(
        challengeKey: 'daily_call',
        titleAr: 'مكالمة اليوم',
        titleEn: 'Daily Call',
        descriptionAr: 'أجرِ مكالمة مع أحد أقاربك اليوم',
        descriptionEn: 'Make a call to a relative today',
        type: 'daily',
        requirementType: 'specific_type',
        requirementValue: 1,
        requirementMetadata: {'interaction_type': 'call'},
        xpReward: 30,
        pointsReward: 15,
        icon: 'phone',
        colorHex: '#2196F3',
        isRecurring: true,
        sortOrder: 1,
      ),
      // Weekly challenges
      ChallengeConfig(
        challengeKey: 'weekly_variety',
        titleAr: 'تنوع الأسبوع',
        titleEn: 'Weekly Variety',
        descriptionAr: 'استخدم 3 أنواع مختلفة من التفاعلات هذا الأسبوع',
        descriptionEn: 'Use 3 different interaction types this week',
        type: 'weekly',
        requirementType: 'unique_relatives',
        requirementValue: 3,
        requirementMetadata: {},
        xpReward: 100,
        pointsReward: 50,
        icon: 'shuffle',
        colorHex: '#9C27B0',
        isRecurring: true,
        sortOrder: 10,
      ),
      ChallengeConfig(
        challengeKey: 'weekly_streak',
        titleAr: 'سلسلة الأسبوع',
        titleEn: 'Weekly Streak',
        descriptionAr: 'حافظ على سلسلة 7 أيام متتالية',
        descriptionEn: 'Maintain a 7-day streak',
        type: 'weekly',
        requirementType: 'streak',
        requirementValue: 7,
        requirementMetadata: {},
        xpReward: 150,
        pointsReward: 75,
        icon: 'flame',
        colorHex: '#FF5722',
        isRecurring: true,
        sortOrder: 11,
      ),
      // Monthly challenge
      ChallengeConfig(
        challengeKey: 'monthly_champion',
        titleAr: 'بطل الشهر',
        titleEn: 'Monthly Champion',
        descriptionAr: 'أكمل 30 تفاعلاً هذا الشهر',
        descriptionEn: 'Complete 30 interactions this month',
        type: 'monthly',
        requirementType: 'interaction_count',
        requirementValue: 30,
        requirementMetadata: {},
        xpReward: 500,
        pointsReward: 200,
        icon: 'trophy',
        colorHex: '#FFD700',
        isRecurring: true,
        sortOrder: 20,
      ),
    ];
  }
}
