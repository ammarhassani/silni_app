import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Widget displaying overall user statistics in a grid
class OverallStatsWidget extends StatelessWidget {
  const OverallStatsWidget({
    super.key,
    required this.userStats,
  });

  final Map<String, dynamic> userStats;

  @override
  Widget build(BuildContext context) {
    final points = userStats['points'] ?? 0;
    final level = userStats['level'] ?? 1;
    final currentStreak = userStats['current_streak'] ?? 0;
    final longestStreak = userStats['longest_streak'] ?? 0;
    final totalInteractions = userStats['total_interactions'] ?? 0;
    final badgesCount = (userStats['badges'] as List?)?.length ?? 0;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'نظرة عامة',
              style: AppTypography.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.3,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              children: [
                _StatTile(
                  icon: Icons.star_rounded,
                  value: points.toString(),
                  label: 'النقاط',
                  color: AppColors.premiumGold,
                ),
                _StatTile(
                  icon: Icons.workspace_premium_rounded,
                  value: level.toString(),
                  label: 'المستوى',
                  color: AppColors.islamicGreenPrimary,
                ),
                _StatTile(
                  icon: Icons.local_fire_department_rounded,
                  value: currentStreak.toString(),
                  label: 'السلسلة الحالية',
                  color: AppColors.energeticRed,
                ),
                _StatTile(
                  icon: Icons.emoji_events_rounded,
                  value: badgesCount.toString(),
                  label: 'الأوسمة',
                  color: AppColors.joyfulOrange,
                ),
                _StatTile(
                  icon: Icons.trending_up_rounded,
                  value: longestStreak.toString(),
                  label: 'أطول سلسلة',
                  color: AppColors.calmBlue,
                ),
                _StatTile(
                  icon: Icons.touch_app_rounded,
                  value: totalInteractions.toString(),
                  label: 'مجموع التفاعلات',
                  color: AppColors.emotionalPurple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              value,
              style: AppTypography.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
