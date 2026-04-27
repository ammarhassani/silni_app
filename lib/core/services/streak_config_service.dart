import 'package:supabase_flutter/supabase_flutter.dart';

import 'cache_config_service.dart';

/// Streak configuration loaded from the admin panel (`admin_streak_config`).
///
/// Streak mechanism (deadlines, endangered/critical thresholds, grace
/// period, freeze awards, celebration milestones) is the core product
/// engagement loop. Gamification (points, badges, levels) was cut in
/// Phase 9.1; this service replaces the streak slice that used to live
/// inside GamificationConfigService.
class StreakConfigService {
  StreakConfigService._();
  static final StreakConfigService instance = StreakConfigService._();

  SupabaseClient get _supabase => Supabase.instance.client;

  StreakConfig? _cache;
  DateTime? _lastFetchTime;

  final CacheConfigService _cacheConfig = CacheConfigService();
  static const String _serviceKey = 'streak_config';

  bool get _isCacheValid {
    if (_lastFetchTime == null) return false;
    return !_cacheConfig.isCacheExpired(_serviceKey, _lastFetchTime);
  }

  bool get isLoaded => _lastFetchTime != null;

  Future<void> initialize() async {
    if (!_isCacheValid) {
      await refresh();
    }
  }

  Future<void> refresh() async {
    try {
      final response = await _supabase
          .from('admin_streak_config')
          .select()
          .eq('is_active', true)
          .single();
      _cache = StreakConfig.fromJson(response);
      _lastFetchTime = DateTime.now();
    } catch (_) {
      // Streak config fetch failed silently — fall back to defaults.
    }
  }

  void clearCache() {
    _cache = null;
    _lastFetchTime = null;
  }

  StreakConfig get streakConfig => _cache ?? StreakConfig.fallback();
}

/// Streak configuration (deadlines, thresholds, milestone lists).
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
      freezeAwardMilestones:
          (json['freeze_award_milestones'] as List<dynamic>?)
                  ?.map((e) => e as int)
                  .toList() ??
              [7, 30, 100],
      celebrationMilestones:
          (json['celebration_milestones'] as List<dynamic>?)
                  ?.map((e) => e as int)
                  .toList() ??
              [3, 7, 10, 14, 21, 30, 50, 100, 200, 365, 500],
      maxFreezes: json['max_freezes'] as int? ?? 3,
      freezeCostPoints: json['freeze_cost_points'] as int? ?? 0,
      streakRestoreEnabled: json['streak_restore_enabled'] as bool? ?? false,
      streakRestoreCostPoints:
          json['streak_restore_cost_points'] as int? ?? 500,
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

  bool isFreezeAwardMilestone(int streak) =>
      freezeAwardMilestones.contains(streak);

  bool isCelebrationMilestone(int streak) =>
      celebrationMilestones.contains(streak);
}
