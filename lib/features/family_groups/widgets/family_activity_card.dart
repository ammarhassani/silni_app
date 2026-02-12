import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/glass_card.dart';

/// Cache duration for family stats (matches other group providers).
const _statsCacheTimeout = Duration(minutes: 5);

/// Provider for family activity stats by group ID.
///
/// Uses autoDispose with timed cache to avoid re-fetching on every rebuild
/// while still cleaning up when the widget is disposed.
final _familyStatsProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, groupId) {
    final link = ref.keepAlive();
    Timer? timer;

    ref.onDispose(() => timer?.cancel());
    ref.onCancel(() {
      timer = Timer(_statsCacheTimeout, () => link.close());
    });
    ref.onResume(() => timer?.cancel());

    return _fetchFamilyStats(groupId);
  },
);

Future<Map<String, dynamic>> _fetchFamilyStats(String groupId) async {
  final client = SupabaseConfig.client;
  final now = DateTime.now();
  final monthStart =
      DateTime(now.year, now.month, 1).toUtc().toIso8601String();

  // Get all member user IDs
  final members = await client
      .from('family_group_members')
      .select('user_id')
      .eq('group_id', groupId);

  final memberIds = members.map((m) => m['user_id'] as String).toList();
  if (memberIds.isEmpty) return {'total': 0, 'active': 0};

  // Count interactions by group members this month
  final interactions = await client
      .from('interactions')
      .select('id, user_id')
      .inFilter('user_id', memberIds)
      .gte('interaction_date', monthStart);

  final uniqueActiveMembers =
      interactions.map((i) => i['user_id'] as String).toSet().length;

  return {
    'total': interactions.length,
    'active': uniqueActiveMembers,
  };
}

/// Displays collective family stats: total interactions this month,
/// active members count.
class FamilyActivityCard extends ConsumerWidget {
  final String groupId;
  final String familyName;

  const FamilyActivityCard({
    super.key,
    required this.groupId,
    required this.familyName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final statsAsync = ref.watch(_familyStatsProvider(groupId));

    return statsAsync.when(
      data: (stats) {
        final totalInteractions = stats['total'] as int? ?? 0;
        final activeMembers = stats['active'] as int? ?? 0;

        if (totalInteractions == 0) return const SizedBox.shrink();

        return GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'نشاط العائلة هالشهر',
                style: AppTypography.titleSmall.copyWith(
                  color: themeColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '$familyName تواصلوا $totalInteractions مرة هالشهر',
                style: AppTypography.bodyMedium.copyWith(
                  color: themeColors.onSurface,
                ),
              ),
              if (activeMembers > 0)
                Text(
                  '$activeMembers أعضاء نشطين',
                  style: AppTypography.bodySmall.copyWith(
                    color: themeColors.onSurface.withValues(alpha: 0.7),
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
}
