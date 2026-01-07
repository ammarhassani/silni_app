import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/badge_prestige.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../screens/badges_screen.dart';

/// Grid widget showcasing user achievements/badges
class AchievementsShowcase extends ConsumerWidget {
  const AchievementsShowcase({
    super.key,
    required this.achievements,
  });

  final List<Map<String, dynamic>> achievements;

  static const int _maxDisplayed = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    if (achievements.isEmpty) {
      return GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: themeColors.textOnGradient.withValues(alpha: 0.54),
                size: 48,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'لا توجد إنجازات بعد',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: themeColors.textOnGradient.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hasMore = achievements.length > _maxDisplayed;
    final displayedAchievements = achievements.take(_maxDisplayed).toList();
    final remainingCount = achievements.length - _maxDisplayed;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'إنجازاتي',
                  style: AppTypography.titleLarge.copyWith(
                    color: themeColors.textOnGradient,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: themeColors.secondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    'آخر ${achievements.length} إنجازات',
                    style: AppTypography.labelMedium.copyWith(
                      color: themeColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              children: displayedAchievements.map((achievement) {
                final badgeId = achievement['id'] as String? ?? achievement['name'] as String? ?? '';
                final badgeInfo = BadgePrestige.getBadgeInfo(badgeId);
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [badgeInfo.color, badgeInfo.color.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: badgeInfo.color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        badgeInfo.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          badgeInfo.name,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: themeColors.textOnGradient,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            if (hasMore) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const BadgesScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                  label: Text(
                    'عرض $remainingCount إنجازات أخرى',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: themeColors.secondary,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
