import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/glass_card.dart';

/// Cache timeout for celebration stats.
const _celebrationCacheTimeout = Duration(minutes: 10);

/// Provider for family celebration stats by group ID.
final _familyCelebrationProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, groupId) {
    final link = ref.keepAlive();
    Timer? timer;

    ref.onDispose(() => timer?.cancel());
    ref.onCancel(() {
      timer = Timer(_celebrationCacheTimeout, () => link.close());
    });
    ref.onResume(() => timer?.cancel());

    return _fetchCelebrationStats(groupId);
  },
);

Future<Map<String, dynamic>> _fetchCelebrationStats(String groupId) async {
  final client = SupabaseConfig.client;
  final now = DateTime.now();

  // This week start (Saturday in many Arab countries, but using Monday for simplicity)
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekStartStr = DateTime(weekStart.year, weekStart.month, weekStart.day)
      .toUtc()
      .toIso8601String();

  final monthStart = DateTime(now.year, now.month, 1).toUtc().toIso8601String();

  // Get member user IDs
  final members = await client
      .from('family_group_members')
      .select('user_id')
      .eq('group_id', groupId);

  final memberIds = members.map((m) => m['user_id'] as String).toList();
  if (memberIds.isEmpty) {
    return {'weekActive': 0, 'monthTotal': 0, 'memberCount': 0};
  }

  // Count this week's active members
  final weekInteractions = await client
      .from('interactions')
      .select('user_id')
      .inFilter('user_id', memberIds)
      .gte('interaction_date', weekStartStr);

  final weekActiveMembers =
      weekInteractions.map((i) => i['user_id'] as String).toSet().length;

  // Count this month's total interactions
  final monthInteractions = await client
      .from('interactions')
      .select('id')
      .inFilter('user_id', memberIds)
      .gte('interaction_date', monthStart);

  return {
    'weekActive': weekActiveMembers,
    'monthTotal': monthInteractions.length,
    'memberCount': memberIds.length,
  };
}

/// Displays a collective family celebration card with warm stats.
/// No ranking, no individual scores — just collective warmth.
class FamilyCelebrationCard extends ConsumerWidget {
  final String groupId;

  const FamilyCelebrationCard({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final statsAsync = ref.watch(_familyCelebrationProvider(groupId));

    return statsAsync.when(
      data: (stats) {
        final weekActive = stats['weekActive'] as int? ?? 0;
        final monthTotal = stats['monthTotal'] as int? ?? 0;
        final memberCount = stats['memberCount'] as int? ?? 0;

        if (monthTotal == 0) return const SizedBox.shrink();

        // Calculate participation percentage
        final participationPercent =
            memberCount > 0 ? ((weekActive / memberCount) * 100).round() : 0;

        return GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Text('\u{1F389}', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '\u0627\u062D\u062A\u0641\u0627\u0644 \u0627\u0644\u0639\u0627\u0626\u0644\u0629',
                    style: AppTypography.titleSmall.copyWith(
                      color: themeColors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Main stat
              Text(
                '\u0639\u0627\u0626\u0644\u062A\u0643\u0645 \u062A\u0648\u0627\u0635\u0644\u062A $monthTotal \u0645\u0631\u0629 \u0647\u0630\u0627 \u0627\u0644\u0634\u0647\u0631',
                style: AppTypography.bodyMedium.copyWith(
                  color: themeColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Weekly participation
              Text(
                '$weekActive \u0645\u0646 $memberCount \u062A\u0648\u0627\u0635\u0644\u0648\u0627 \u0647\u0630\u0627 \u0627\u0644\u0623\u0633\u0628\u0648\u0639',
                style: AppTypography.bodySmall.copyWith(
                  color: themeColors.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Progress bar for weekly participation
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: memberCount > 0 ? weekActive / memberCount : 0,
                  backgroundColor: themeColors.onSurface.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    themeColors.primary,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Encouraging message based on participation
              Text(
                _getEncouragementMessage(participationPercent),
                style: AppTypography.labelSmall.copyWith(
                  color: themeColors.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  String _getEncouragementMessage(int percent) {
    if (percent >= 80) {
      return '\u0645\u0627 \u0634\u0627\u0621 \u0627\u0644\u0644\u0647! \u0639\u0627\u0626\u0644\u0629 \u0645\u062A\u0648\u0627\u0635\u0644\u0629 \u{1F90D}';
    }
    if (percent >= 50) {
      return '\u0623\u063A\u0644\u0628 \u0627\u0644\u0639\u0627\u0626\u0644\u0629 \u0645\u062A\u0648\u0627\u0635\u0644\u064A\u0646 \u2014 \u0623\u062D\u0633\u0646\u062A\u0645 \u{1F49B}';
    }
    if (percent >= 20) {
      return '\u0627\u0644\u0628\u062F\u0627\u064A\u0629 \u062D\u0644\u0648\u0629 \u2014 \u0648\u0627\u0635\u0644\u0648\u0627 \u{1F331}';
    }
    return '\u0643\u0644 \u062A\u0648\u0627\u0635\u0644 \u064A\u0642\u0631\u0651\u0628 \u0627\u0644\u0639\u0627\u0626\u0644\u0629 \u{1F90D}';
  }
}
