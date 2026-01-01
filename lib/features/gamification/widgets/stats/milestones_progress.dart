import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/gamification_config_service.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Widget showing progress towards various milestones
class MilestonesProgress extends StatelessWidget {
  const MilestonesProgress({
    super.key,
    required this.userStats,
  });

  final Map<String, dynamic> userStats;

  /// Get XP required for next level using dynamic admin config
  int _getNextLevelPoints(int currentLevel) {
    final config = GamificationConfigService.instance;
    // Get XP required for the NEXT level (currentLevel + 1)
    final nextLevelXp = config.getXpForLevel(currentLevel + 1);
    // If we're at or past max level, return a high value
    if (nextLevelXp == 0 && currentLevel >= config.maxLevel) {
      return config.getXpForLevel(config.maxLevel) + 5000;
    }
    return nextLevelXp > 0 ? nextLevelXp : 15000; // Fallback
  }

  @override
  Widget build(BuildContext context) {
    final points = userStats['points'] ?? 0;
    final totalInteractions = userStats['total_interactions'] ?? 0;
    final currentStreak = userStats['current_streak'] ?? 0;
    // Recalculate correct level from points (in case DB is out of sync)
    final calculatedLevel = GamificationConfigService.instance.calculateLevel(points);

    final milestones = [
      _MilestoneData(
        title: 'المستوى التالي',
        current: points,
        target: _getNextLevelPoints(calculatedLevel),
        icon: Icons.workspace_premium_rounded,
        color: AppColors.premiumGold,
      ),
      _MilestoneData(
        title: 'سلسلة 7 أيام',
        current: currentStreak,
        target: 7,
        icon: Icons.local_fire_department_rounded,
        color: AppColors.energeticRed,
      ),
      _MilestoneData(
        title: '100 تفاعل',
        current: totalInteractions,
        target: 100,
        icon: Icons.touch_app_rounded,
        color: AppColors.islamicGreenPrimary,
      ),
    ];

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تقدم الإنجازات',
              style: AppTypography.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...milestones.map(
              (milestone) => _MilestoneProgressItem(milestone: milestone),
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneData {
  final String title;
  final int current;
  final int target;
  final IconData icon;
  final Color color;

  _MilestoneData({
    required this.title,
    required this.current,
    required this.target,
    required this.icon,
    required this.color,
  });
}

class _MilestoneProgressItem extends StatelessWidget {
  const _MilestoneProgressItem({
    required this.milestone,
  });

  final _MilestoneData milestone;

  @override
  Widget build(BuildContext context) {
    final progress = milestone.current / milestone.target;
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(milestone.icon, color: milestone.color, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                milestone.title,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${milestone.current}/${milestone.target}',
                style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: clampedProgress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(milestone.color),
              minHeight: 8,
            ),
          ),
          if (progress >= 1.0) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.check_circle, color: milestone.color, size: 16),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'مكتمل!',
                  style: AppTypography.bodySmall.copyWith(
                    color: milestone.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
