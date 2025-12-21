import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/badge_prestige.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Grid widget showcasing user achievements/badges
class AchievementsShowcase extends StatelessWidget {
  const AchievementsShowcase({
    super.key,
    required this.achievements,
  });

  final List<Map<String, dynamic>> achievements;

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) {
      return GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: Colors.white54,
                size: 48,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'لا توجد إنجازات بعد',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إنجازاتي',
              style: AppTypography.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              children: achievements.take(6).map((achievement) {
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
                            color: Colors.white,
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
          ],
        ),
      ),
    );
  }
}
