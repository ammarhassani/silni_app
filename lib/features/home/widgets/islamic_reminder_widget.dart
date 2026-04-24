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
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Gold accent bar
              Container(
                width: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.premiumGold,
                      AppColors.premiumGoldDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.premiumGold.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            hadith!.type == HadithType.hadith
                                ? 'حديث اليوم'
                                : 'قول العلماء',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.premiumGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        if (hadith!.formattedSource.isNotEmpty) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              hadith!.formattedSource,
                              style: AppTypography.labelSmall.copyWith(
                                color: themeColors.textSecondary,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      hadith!.arabicText,
                      style: AppTypography.bodySmall.copyWith(
                        color: themeColors.textPrimary,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.justify,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: AppAnimations.fast)
        .fadeIn(duration: AppAnimations.normal)
        .slideX(begin: 0.2, end: 0);
  }
}
