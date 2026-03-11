import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/deepseek_ai_service.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/providers/cache_provider.dart';
import '../../../shared/models/interaction_model.dart';
import '../../home/providers/home_providers.dart';
import '../models/monthly_wrapped_model.dart';
import '../models/yearly_wrapped_model.dart';
import '../services/wrapped_ai_cache_service.dart';
import '../services/wrapped_generator_service.dart';

/// Builds a stats context map for the AI personality prompt.
Map<String, dynamic> _buildStatsContext({
  required int totalInteractions,
  required int uniqueRelativesContacted,
  required double relativesCoverage,
  required int longestStreak,
  required String personalityLabel,
  required String? mostContactedRelativeName,
  required int? mostContactedRelativeCount,
  required InteractionType? mostUsedInteractionType,
  required Map<InteractionType, int> interactionBreakdown,
  int? totalActiveDays,
  int? peakMonth,
  int? peakMonthCount,
}) {
  final map = <String, dynamic>{
    'إجمالي التواصلات': totalInteractions,
    'عدد الأقارب': uniqueRelativesContacted,
    'نسبة التغطية': '${(relativesCoverage * 100).round()}%',
    'أطول سلسلة تواصل': '$longestStreak يوم',
    'التصنيف الحالي': personalityLabel,
  };

  if (mostContactedRelativeName != null) {
    map['أكثر قريب تواصلاً'] = mostContactedRelativeName;
    map['عدد تواصلاته'] = mostContactedRelativeCount;
  }

  if (mostUsedInteractionType != null) {
    map['أكثر نوع تواصل'] = mostUsedInteractionType.arabicName;
  }

  final breakdownSummary = interactionBreakdown.entries
      .where((e) => e.value > 0)
      .map((e) => '${e.key.arabicName}: ${e.value}')
      .join('، ');
  if (breakdownSummary.isNotEmpty) {
    map['توزيع التواصلات'] = breakdownSummary;
  }

  if (totalActiveDays != null) {
    map['أيام نشطة'] = totalActiveDays;
  }
  if (peakMonth != null && peakMonth >= 1 && peakMonth <= 12) {
    map['أكثر شهر نشاطاً'] = MonthlyWrapped.arabicMonthNames[peakMonth];
    map['تواصلات الشهر الأكثر'] = peakMonthCount;
  }

  return map;
}

/// Provides a [MonthlyWrapped] for the given calendar month.
///
/// Fetches interactions, generates deterministic stats, then attempts
/// to load or generate an AI personality title (cached via SharedPreferences).
final monthlyWrappedProvider =
    FutureProvider.autoDispose.family<MonthlyWrapped, DateTime>(
  (ref, month) async {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final interactionsRepo = ref.read(interactionsRepositoryProvider);
    final interactions =
        await interactionsRepo.watchUserInteractions(userId).first;
    final relativesAsync = ref.read(viewerFilteredRelativesProvider);
    final relatives = relativesAsync.valueOrNull ?? [];

    var wrapped = WrappedGeneratorService.generate(
      interactions: interactions,
      relatives: relatives,
      month: month,
    );

    // AI personality title: cache-first, then generate, fallback to deterministic.
    try {
      final firstOfMonth = DateTime(month.year, month.month, 1);
      final cached = await WrappedAICacheService.getMonthlyTitle(
        userId,
        firstOfMonth.year,
        firstOfMonth.month,
      );

      if (cached != null) {
        wrapped = wrapped.copyWith(
          aiPersonalityTitle: cached.title,
          aiPersonalityEmoji: cached.emoji,
        );
      } else if (wrapped.totalInteractions > 0) {
        final result = await DeepSeekAIService().generateWrappedPersonality(
          stats: _buildStatsContext(
            totalInteractions: wrapped.totalInteractions,
            uniqueRelativesContacted: wrapped.uniqueRelativesContacted,
            relativesCoverage: wrapped.relativesCoverage,
            longestStreak: wrapped.longestStreak,
            personalityLabel: wrapped.personalityLabel,
            mostContactedRelativeName: wrapped.mostContactedRelativeName,
            mostContactedRelativeCount: wrapped.mostContactedRelativeCount,
            mostUsedInteractionType: wrapped.mostUsedInteractionType,
            interactionBreakdown: wrapped.interactionBreakdown,
          ),
        );
        await WrappedAICacheService.putMonthlyTitle(
          userId,
          firstOfMonth.year,
          firstOfMonth.month,
          result.title,
          result.emoji,
        );
        wrapped = wrapped.copyWith(
          aiPersonalityTitle: result.title,
          aiPersonalityEmoji: result.emoji,
        );
      }
    } catch (_) {
      // AI failed silently; deterministic fallback is already in wrapped.
    }

    return wrapped;
  },
);

/// Provides a [YearlyWrapped] for the given calendar year.
///
/// Fetches interactions, generates deterministic stats, then attempts
/// to load or generate an AI personality title (cached via SharedPreferences).
final yearlyWrappedProvider =
    FutureProvider.autoDispose.family<YearlyWrapped, int>(
  (ref, year) async {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final interactionsRepo = ref.read(interactionsRepositoryProvider);
    final interactions =
        await interactionsRepo.watchUserInteractions(userId).first;
    final relativesAsync = ref.read(viewerFilteredRelativesProvider);
    final relatives = relativesAsync.valueOrNull ?? [];

    var wrapped = WrappedGeneratorService.generateYearly(
      interactions: interactions,
      relatives: relatives,
      year: year,
    );

    // AI personality title: cache-first, then generate, fallback to deterministic.
    try {
      final cached = await WrappedAICacheService.getYearlyTitle(userId, year);

      if (cached != null) {
        wrapped = wrapped.copyWith(
          aiPersonalityTitle: cached.title,
          aiPersonalityEmoji: cached.emoji,
        );
      } else if (wrapped.totalInteractions > 0) {
        final result = await DeepSeekAIService().generateWrappedPersonality(
          stats: _buildStatsContext(
            totalInteractions: wrapped.totalInteractions,
            uniqueRelativesContacted: wrapped.uniqueRelativesContacted,
            relativesCoverage: wrapped.relativesCoverage,
            longestStreak: wrapped.longestStreak,
            personalityLabel: wrapped.personalityLabel,
            mostContactedRelativeName: wrapped.mostContactedRelativeName,
            mostContactedRelativeCount: wrapped.mostContactedRelativeCount,
            mostUsedInteractionType: wrapped.mostUsedInteractionType,
            interactionBreakdown: wrapped.interactionBreakdown,
            totalActiveDays: wrapped.totalActiveDays,
            peakMonth: wrapped.peakMonth,
            peakMonthCount: wrapped.peakMonthCount,
          ),
        );
        await WrappedAICacheService.putYearlyTitle(
          userId,
          year,
          result.title,
          result.emoji,
        );
        wrapped = wrapped.copyWith(
          aiPersonalityTitle: result.title,
          aiPersonalityEmoji: result.emoji,
        );
      }
    } catch (_) {
      // AI failed silently; deterministic fallback is already in wrapped.
    }

    return wrapped;
  },
);

/// Model for family wrapped stats.
class FamilyWrappedStats {
  final int totalFamilyInteractions;
  final int familyMembersActive;
  final String? topContributorName;
  final int topContributorCount;
  final String? mostContactedByFamily;
  final int mostContactedByFamilyCount;

  const FamilyWrappedStats({
    required this.totalFamilyInteractions,
    required this.familyMembersActive,
    this.topContributorName,
    required this.topContributorCount,
    this.mostContactedByFamily,
    required this.mostContactedByFamilyCount,
  });
}

/// Provides family aggregate wrapped stats for a given month.
///
/// Only available when user is in a family group.
/// Shows combined stats across all family members.
final familyMonthlyWrappedProvider =
    FutureProvider.autoDispose.family<FamilyWrappedStats?, ({DateTime month, String groupId})>(
  (ref, params) async {
    final month = params.month;
    final groupId = params.groupId;

    // Get start and end of month
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    // Get all group members
    final membersResponse = await SupabaseConfig.client
        .from('family_group_members')
        .select('user_id, users!inner(full_name)')
        .eq('group_id', groupId);

    final members = membersResponse as List;
    if (members.isEmpty) return null;

    // Get group relative IDs to filter interactions to shared tree only
    final groupRelativesResponse = await SupabaseConfig.client
        .from('relatives')
        .select('id')
        .eq('family_group_id', groupId);
    final groupRelativeIds = (groupRelativesResponse as List)
        .map((r) => r['id'] as String)
        .toSet();

    // Get all interactions from group members for this month
    final memberUserIds = members.map((m) => m['user_id'] as String).toSet();
    final interactionsResponse = await SupabaseConfig.client
        .from('interactions')
        .select('id, user_id, relative_id, date')
        .gte('date', startOfMonth.toUtc().toIso8601String())
        .lte('date', endOfMonth.toUtc().toIso8601String())
        .order('date');

    final interactions = interactionsResponse as List;

    // Filter to only interactions by group members for group relatives
    final familyInteractions = interactions
        .where((i) =>
            memberUserIds.contains(i['user_id'] as String) &&
            groupRelativeIds.contains(i['relative_id'] as String))
        .toList();

    final totalFamilyInteractions = familyInteractions.length;

    // Count interactions per member
    final memberCounts = <String, int>{};
    final memberNames = <String, String>{};

    for (final member in members) {
      final userId = member['user_id'] as String;
      memberNames[userId] = (member['users'] as Map?)?['full_name'] as String? ?? 'عضو';
      memberCounts[userId] = 0;
    }

    for (final interaction in familyInteractions) {
      final userId = interaction['user_id'] as String;
      memberCounts[userId] = (memberCounts[userId] ?? 0) + 1;
    }

    // Find top contributor
    String? topContributorName;
    int topContributorCount = 0;
    int familyMembersActive = 0;

    memberCounts.forEach((userId, count) {
      if (count > 0) familyMembersActive++;
      if (count > topContributorCount) {
        topContributorCount = count;
        topContributorName = memberNames[userId];
      }
    });

    // Count interactions per relative to find most contacted
    final relativeCounts = <String, int>{};
    for (final interaction in familyInteractions) {
      final relativeId = interaction['relative_id'] as String?;
      if (relativeId != null) {
        relativeCounts[relativeId] = (relativeCounts[relativeId] ?? 0) + 1;
      }
    }

    String? mostContactedByFamily;
    int mostContactedByFamilyCount = 0;

    if (relativeCounts.isNotEmpty) {
      final topRelativeId = relativeCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      mostContactedByFamilyCount = relativeCounts[topRelativeId]!;

      // Get relative name
      final relativeResponse = await SupabaseConfig.client
          .from('relatives')
          .select('full_name')
          .eq('id', topRelativeId)
          .maybeSingle();

      mostContactedByFamily = relativeResponse?['full_name'] as String?;
    }

    return FamilyWrappedStats(
      totalFamilyInteractions: totalFamilyInteractions,
      familyMembersActive: familyMembersActive,
      topContributorName: topContributorName,
      topContributorCount: topContributorCount,
      mostContactedByFamily: mostContactedByFamily,
      mostContactedByFamilyCount: mostContactedByFamilyCount,
    );
  },
);
