import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/relative_streak_model.dart';
import '../../../../core/theme/theme_provider.dart';

/// Provider for fetching a relative's streak
final relativeStreakProvider = FutureProvider.family<RelativeStreak?, String>((ref, relativeId) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) {
    return null;
  }

  final data = await supabase
      .from('relative_streaks')
      .select()
      .eq('user_id', userId)
      .eq('relative_id', relativeId)
      .maybeSingle();

  if (data == null) return null;
  return RelativeStreak.fromJson(data);
});

/// Compact streak badge using theme colors
class RelativeStreakBadge extends ConsumerWidget {
  const RelativeStreakBadge({
    super.key,
    required this.relativeId,
  });

  final String relativeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final streakAsync = ref.watch(relativeStreakProvider(relativeId));

    return streakAsync.when(
      data: (streak) {
        if (streak == null || streak.currentStreak == 0) {
          return _buildNoStreak(themeColors);
        }
        return _buildStreakDisplay(streak, themeColors);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildNoStreak(dynamic themeColors) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: themeColors.glassBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: themeColors.glassBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.flame,
            color: themeColors.textSecondary,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            'لا شعلة',
            style: AppTypography.labelSmall.copyWith(
              color: themeColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakDisplay(RelativeStreak streak, dynamic themeColors) {
    final warningState = streak.warningState;
    final isUrgent = warningState == StreakWarningState.critical ||
        warningState == StreakWarningState.warning;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: themeColors.streakFire,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.flame,
            color: themeColors.onPrimary,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${streak.currentStreak}',
            style: AppTypography.labelMedium.copyWith(
              color: themeColors.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isUrgent && streak.formattedTimeRemaining.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              '• ${streak.formattedTimeRemaining}',
              style: AppTypography.labelSmall.copyWith(
                color: themeColors.onPrimary.withValues(alpha: 0.9),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
