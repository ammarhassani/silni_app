import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/hadith_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/skeleton_loader.dart';

/// Daily hadith or Islamic reminder widget
class IslamicReminderWidget extends ConsumerWidget {
  const IslamicReminderWidget({
    super.key,
    required this.hadith,
    required this.isLoading,
  });

  final Hadith? hadith;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    if (isLoading) {
      return GlassCard(
        gradient: LinearGradient(
          colors: [
            themeColors.primary.withValues(alpha: 0.2),
            AppColors.premiumGold.withValues(alpha: 0.1),
          ],
        ),
        child: const HadithSkeletonLoader(),
      );
    }

    if (hadith == null) {
      return const SizedBox.shrink();
    }

    return Semantics(
      label: hadith!.type == HadithType.hadith ? 'حديث اليوم' : 'قول العلماء',
      child: GlassCard(
        gradient: LinearGradient(
          colors: [
            themeColors.primary.withValues(alpha: 0.3),
            AppColors.premiumGold.withValues(alpha: 0.2),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: themeColors.goldenGradient,
                  ),
                  child: const Center(
                    child: Text('📿', style: TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hadith!.type == HadithType.hadith
                            ? 'حديث اليوم'
                            : 'قول العلماء',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.premiumGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (hadith!.formattedSource.isNotEmpty)
                        Text(
                          hadith!.formattedSource,
                          style: AppTypography.labelSmall.copyWith(
                            color: themeColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Hadith text
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: themeColors.glassBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColors.premiumGold.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                hadith!.arabicText,
                style: AppTypography.titleMedium.copyWith(
                  color: themeColors.textPrimary,
                  height: 1.8,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.justify,
              ),
            ),

            // Reference
            if (hadith!.reference.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.book,
                    size: 14,
                    color: themeColors.textHint,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      hadith!.reference,
                      style: AppTypography.labelSmall.copyWith(
                        color: themeColors.textHint,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    )
        .animate(delay: AppAnimations.fast)
        .fadeIn(duration: AppAnimations.normal)
        .slideX(begin: 0.2, end: 0);
  }
}
