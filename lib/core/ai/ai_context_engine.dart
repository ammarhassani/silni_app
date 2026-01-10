import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/interaction_model.dart';
import '../../shared/models/relative_model.dart';
import '../models/relative_streak_model.dart';
import 'ai_models.dart';

/// Central AI Context Engine for Silni App
///
/// Aggregates ALL user data for AI features, providing a unified context
/// that any AI touch point can use. This ensures AI has full awareness
/// of the user's family relationships, interactions, and patterns.
///
/// Usage:
/// ```dart
/// final context = await AIContextEngine.instance.buildContext(
///   focusRelative: selectedRelative,
///   featureContext: 'home',
/// );
/// ```
class AIContextEngine {
  AIContextEngine._();
  static final AIContextEngine instance = AIContextEngine._();

  final _supabase = Supabase.instance.client;

  // Cached data
  List<Relative>? _relativesCache;
  List<Interaction>? _interactionsCache;
  Map<String, RelativeStreak>? _streaksCache;
  List<AIMemory>? _memoriesCache;
  GamificationStats? _gamificationCache;
  DateTime? _lastFetchTime;

  // Cache duration (5 minutes)
  static const Duration _cacheDuration = Duration(minutes: 5);

  bool get _isCacheValid {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
  }

  /// Clear all cached data
  void clearCache() {
    _relativesCache = null;
    _interactionsCache = null;
    _streaksCache = null;
    _memoriesCache = null;
    _gamificationCache = null;
    _lastFetchTime = null;
  }

  /// Build AI context for a specific feature/screen
  ///
  /// [focusRelative] - If provided, prioritizes this relative in context
  /// [featureContext] - The screen/feature requesting context (e.g., 'home', 'relative_detail')
  /// [tokenBudget] - Maximum estimated tokens for context (helps trim data)
  Future<AIContext> buildContext({
    Relative? focusRelative,
    String? featureContext,
    int tokenBudget = 2000,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return AIContext.empty();
    }

    // Refresh cache if needed
    if (!_isCacheValid) {
      await _refreshCache(userId);
    }

    // Build context based on feature needs
    return AIContext(
      userId: userId,
      focusRelative: focusRelative,
      relatives: _relativesCache ?? [],
      recentInteractions: _getRecentInteractions(focusRelative?.id),
      streaks: _streaksCache ?? {},
      gamification: _gamificationCache ?? GamificationStats.empty(),
      memories: _getRelevantMemories(focusRelative?.id),
      upcomingOccasions: _getUpcomingOccasions(),
      healthSummary: _buildHealthSummary(),
      featureContext: featureContext,
    );
  }

  /// Refresh all cached data from Supabase
  Future<void> _refreshCache(String userId) async {
    debugPrint('[AIContextEngine] Refreshing cache for user: $userId');

    try {
      await Future.wait([
        _fetchRelatives(userId),
        _fetchInteractions(userId),
        _fetchStreaks(userId),
        _fetchMemories(userId),
        _fetchGamification(userId),
      ]);
      _lastFetchTime = DateTime.now();
      debugPrint('[AIContextEngine] Cache refreshed successfully');
    } catch (e) {
      debugPrint('[AIContextEngine] Error refreshing cache: $e');
    }
  }

  Future<void> _fetchRelatives(String userId) async {
    try {
      final response = await _supabase
          .from('relatives')
          .select()
          .eq('user_id', userId)
          .eq('is_archived', false)
          .order('priority');
      _relativesCache = (response as List)
          .map((json) => Relative.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('[AIContextEngine] Error fetching relatives: $e');
    }
  }

  Future<void> _fetchInteractions(String userId) async {
    try {
      // Get last 30 days of interactions
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final response = await _supabase
          .from('interactions')
          .select()
          .eq('user_id', userId)
          .gte('date', thirtyDaysAgo.toIso8601String())
          .order('date', ascending: false)
          .limit(100);
      _interactionsCache = (response as List)
          .map((json) => Interaction.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('[AIContextEngine] Error fetching interactions: $e');
    }
  }

  Future<void> _fetchStreaks(String userId) async {
    try {
      final response = await _supabase
          .from('relative_streaks')
          .select()
          .eq('user_id', userId);
      final streaks = (response as List)
          .map((json) => RelativeStreak.fromJson(json))
          .toList();
      _streaksCache = {for (var s in streaks) s.relativeId: s};
    } catch (e) {
      debugPrint('[AIContextEngine] Error fetching streaks: $e');
    }
  }

  Future<void> _fetchMemories(String userId) async {
    try {
      final response = await _supabase
          .from('ai_memories')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('importance', ascending: false)
          .limit(50);
      _memoriesCache = (response as List)
          .map((json) => AIMemory.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('[AIContextEngine] Error fetching memories: $e');
    }
  }

  Future<void> _fetchGamification(String userId) async {
    try {
      final response = await _supabase
          .from('gamification_stats')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        _gamificationCache = GamificationStats.fromJson(response);
      } else {
        _gamificationCache = GamificationStats.empty();
      }
    } catch (e) {
      debugPrint('[AIContextEngine] Error fetching gamification: $e');
      _gamificationCache = GamificationStats.empty();
    }
  }

  /// Get recent interactions, optionally filtered by relative
  List<Interaction> _getRecentInteractions(String? relativeId) {
    if (_interactionsCache == null) return [];
    if (relativeId != null) {
      return _interactionsCache!
          .where((i) => i.relativeId == relativeId)
          .take(20)
          .toList();
    }
    return _interactionsCache!.take(30).toList();
  }

  /// Get relevant memories, optionally filtered by relative
  List<AIMemory> _getRelevantMemories(String? relativeId) {
    if (_memoriesCache == null) return [];
    if (relativeId != null) {
      // Prioritize memories about this relative, then general memories
      final relativeMemories = _memoriesCache!
          .where((m) => m.relativeId == relativeId)
          .toList();
      final generalMemories = _memoriesCache!
          .where((m) => m.relativeId == null)
          .take(10)
          .toList();
      return [...relativeMemories, ...generalMemories].take(20).toList();
    }
    return _memoriesCache!.take(20).toList();
  }

  /// Get upcoming occasions (birthdays, etc.) in next 30 days
  List<UpcomingOccasion> _getUpcomingOccasions() {
    if (_relativesCache == null) return [];

    final now = DateTime.now();
    final occasions = <UpcomingOccasion>[];

    for (final relative in _relativesCache!) {
      if (relative.dateOfBirth != null) {
        // Calculate this year's birthday
        final birthday = DateTime(
          now.year,
          relative.dateOfBirth!.month,
          relative.dateOfBirth!.day,
        );

        // If birthday has passed this year, check next year
        final targetBirthday = birthday.isBefore(now)
            ? DateTime(now.year + 1, relative.dateOfBirth!.month, relative.dateOfBirth!.day)
            : birthday;

        final daysUntil = targetBirthday.difference(now).inDays;

        if (daysUntil <= 30) {
          occasions.add(UpcomingOccasion(
            relativeId: relative.id,
            relativeName: relative.fullName,
            occasionType: 'birthday',
            date: targetBirthday,
            daysUntil: daysUntil,
          ));
        }
      }
    }

    // Sort by days until
    occasions.sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
    return occasions;
  }

  /// Build health summary statistics
  HealthSummary _buildHealthSummary() {
    if (_relativesCache == null) {
      return HealthSummary.empty();
    }

    int healthy = 0;
    int needsAttention = 0;
    int atRisk = 0;
    final atRiskRelatives = <String>[];

    for (final relative in _relativesCache!) {
      final status = relative.healthStatus2;
      switch (status) {
        case RelationshipHealthStatus.healthy:
          healthy++;
          break;
        case RelationshipHealthStatus.needsAttention:
          needsAttention++;
          break;
        case RelationshipHealthStatus.atRisk:
          atRisk++;
          atRiskRelatives.add(relative.fullName);
          break;
        case RelationshipHealthStatus.unknown:
          break;
      }
    }

    return HealthSummary(
      totalRelatives: _relativesCache!.length,
      healthyCount: healthy,
      needsAttentionCount: needsAttention,
      atRiskCount: atRisk,
      atRiskNames: atRiskRelatives,
    );
  }

  /// Get relatives sorted by priority for AI recommendations
  List<Relative> getRelativesByPriority() {
    if (_relativesCache == null) return [];

    // Sort by: at-risk first, then by priority, then by days since contact
    final sorted = List<Relative>.from(_relativesCache!);
    sorted.sort((a, b) {
      // At-risk relatives first
      if (a.healthStatus2 == RelationshipHealthStatus.atRisk &&
          b.healthStatus2 != RelationshipHealthStatus.atRisk) {
        return -1;
      }
      if (b.healthStatus2 == RelationshipHealthStatus.atRisk &&
          a.healthStatus2 != RelationshipHealthStatus.atRisk) {
        return 1;
      }

      // Then by priority
      if (a.priority != b.priority) {
        return a.priority.compareTo(b.priority);
      }

      // Then by days since contact (more days = higher priority)
      final aDays = a.daysSinceLastContact ?? 999;
      final bDays = b.daysSinceLastContact ?? 999;
      return bDays.compareTo(aDays);
    });

    return sorted;
  }

  /// Get endangered streaks (warning or critical state)
  List<RelativeStreak> getEndangeredStreaks() {
    if (_streaksCache == null) return [];

    return _streaksCache!.values
        .where((s) => s.warningState == StreakWarningState.warning ||
                      s.warningState == StreakWarningState.critical)
        .toList();
  }
}

/// Complete AI context for a request
class AIContext {
  final String userId;
  final Relative? focusRelative;
  final List<Relative> relatives;
  final List<Interaction> recentInteractions;
  final Map<String, RelativeStreak> streaks;
  final GamificationStats gamification;
  final List<AIMemory> memories;
  final List<UpcomingOccasion> upcomingOccasions;
  final HealthSummary healthSummary;
  final String? featureContext;

  AIContext({
    required this.userId,
    this.focusRelative,
    required this.relatives,
    required this.recentInteractions,
    required this.streaks,
    required this.gamification,
    required this.memories,
    required this.upcomingOccasions,
    required this.healthSummary,
    this.featureContext,
  });

  factory AIContext.empty() {
    return AIContext(
      userId: '',
      relatives: [],
      recentInteractions: [],
      streaks: {},
      gamification: GamificationStats.empty(),
      memories: [],
      upcomingOccasions: [],
      healthSummary: HealthSummary.empty(),
    );
  }

  /// Get streak for a specific relative
  RelativeStreak? getStreakFor(String relativeId) => streaks[relativeId];

  /// Check if there are any endangered streaks
  bool get hasEndangeredStreaks => streaks.values.any(
    (s) => s.warningState == StreakWarningState.warning ||
           s.warningState == StreakWarningState.critical,
  );

  /// Get total active streak count
  int get totalActiveStreaks => streaks.values
      .where((s) => s.currentStreak > 0)
      .length;

  /// Format context as a summary string for AI prompts
  String toPromptSummary() {
    final buffer = StringBuffer();

    buffer.writeln('## معلومات المستخدم');
    buffer.writeln('- عدد الأقارب: ${relatives.length}');
    buffer.writeln('- المستوى: ${gamification.level}');
    buffer.writeln('- النقاط: ${gamification.totalPoints}');
    buffer.writeln('- الشعلات النشطة: $totalActiveStreaks');

    buffer.writeln('\n## صحة العلاقات');
    buffer.writeln('- صحية: ${healthSummary.healthyCount}');
    buffer.writeln('- تحتاج اهتمام: ${healthSummary.needsAttentionCount}');
    buffer.writeln('- معرضة للخطر: ${healthSummary.atRiskCount}');

    if (healthSummary.atRiskNames.isNotEmpty) {
      buffer.writeln('- أقارب معرضون للخطر: ${healthSummary.atRiskNames.join(", ")}');
    }

    if (upcomingOccasions.isNotEmpty) {
      buffer.writeln('\n## مناسبات قادمة');
      for (final occasion in upcomingOccasions.take(5)) {
        buffer.writeln('- ${occasion.relativeName}: ${occasion.occasionType} بعد ${occasion.daysUntil} يوم');
      }
    }

    if (focusRelative != null) {
      buffer.writeln('\n## القريب المحدد: ${focusRelative!.fullName}');
      buffer.writeln('- العلاقة: ${focusRelative!.relationshipType.arabicName}');
      buffer.writeln('- الأولوية: ${focusRelative!.priority}');
      if (focusRelative!.interests?.isNotEmpty == true) {
        buffer.writeln('- الاهتمامات: ${focusRelative!.interests!.join(", ")}');
      }
      if (focusRelative!.personalityType != null) {
        buffer.writeln('- نوع الشخصية: ${focusRelative!.personalityType}');
      }
      final streak = getStreakFor(focusRelative!.id);
      if (streak != null && streak.currentStreak > 0) {
        buffer.writeln('- الشعلة الحالية: ${streak.currentStreak} يوم');
      }
    }

    if (memories.isNotEmpty) {
      buffer.writeln('\n## ذكريات مهمة');
      for (final memory in memories.take(5)) {
        buffer.writeln('- ${memory.content}');
      }
    }

    return buffer.toString();
  }
}

/// Gamification statistics for a user
class GamificationStats {
  final int totalPoints;
  final int level;
  final List<String> badges;
  final int totalInteractions;

  GamificationStats({
    required this.totalPoints,
    required this.level,
    required this.badges,
    required this.totalInteractions,
  });

  factory GamificationStats.fromJson(Map<String, dynamic> json) {
    return GamificationStats(
      totalPoints: json['total_points'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      badges: (json['badges'] as List?)?.cast<String>() ?? [],
      totalInteractions: json['total_interactions'] as int? ?? 0,
    );
  }

  factory GamificationStats.empty() {
    return GamificationStats(
      totalPoints: 0,
      level: 1,
      badges: [],
      totalInteractions: 0,
    );
  }
}

/// Upcoming occasion (birthday, anniversary, etc.)
class UpcomingOccasion {
  final String relativeId;
  final String relativeName;
  final String occasionType;
  final DateTime date;
  final int daysUntil;

  UpcomingOccasion({
    required this.relativeId,
    required this.relativeName,
    required this.occasionType,
    required this.date,
    required this.daysUntil,
  });
}

/// Summary of relationship health across all relatives
class HealthSummary {
  final int totalRelatives;
  final int healthyCount;
  final int needsAttentionCount;
  final int atRiskCount;
  final List<String> atRiskNames;

  HealthSummary({
    required this.totalRelatives,
    required this.healthyCount,
    required this.needsAttentionCount,
    required this.atRiskCount,
    required this.atRiskNames,
  });

  factory HealthSummary.empty() {
    return HealthSummary(
      totalRelatives: 0,
      healthyCount: 0,
      needsAttentionCount: 0,
      atRiskCount: 0,
      atRiskNames: [],
    );
  }

  /// Get overall health percentage
  double get healthPercentage {
    if (totalRelatives == 0) return 100;
    return (healthyCount / totalRelatives) * 100;
  }
}
