import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/subscription_tier.dart';
import '../../../core/providers/ai_touch_point_provider.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../subscription/screens/paywall_screen.dart';

/// AI-powered daily insight card (MAX subscription only)
///
/// Uses admin-configured touch point to generate daily insights
/// about family patterns based on:
/// - Interaction trends
/// - Streak patterns
/// - Relationship health over time
/// - Upcoming opportunities
class AIInsightCard extends ConsumerWidget {
  const AIInsightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMax = ref.watch(isMaxProvider);

    // Show blurred teaser for non-MAX users
    if (!isMax) {
      return const _AIInsightBlurredTeaser();
    }

    return const _AIInsightCardContent();
  }
}

class _AIInsightCardContent extends ConsumerWidget {
  const _AIInsightCardContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    // Request AI insight from touch point service
    final request = const AITouchPointRequest(
      screenKey: 'home',
      touchPointKey: 'insight',
    );
    final resultAsync = ref.watch(aiTouchPointProvider(request));

    return resultAsync.when(
      data: (result) {
        if (!result.success || result.content == null || result.content!.isEmpty) {
          return const SizedBox.shrink();
        }

        return GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          themeColors.primary,
                          themeColors.primaryLight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      LucideIcons.lightbulb,
                      color: themeColors.onPrimary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'رؤية اليوم',
                          style: AppTypography.titleSmall.copyWith(
                            color: themeColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    themeColors.primary,
                                    themeColors.primaryLight,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.sparkles,
                                    size: 10,
                                    color: themeColors.onPrimary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'AI',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: themeColors.onPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (result.fromCache) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Icon(
                                LucideIcons.clock,
                                size: 10,
                                color: themeColors.textSecondary,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Insight content
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: themeColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: themeColors.primary.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  result.content!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: themeColors.textPrimary,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: AppAnimations.normal)
            .slideY(begin: 0.1, end: 0);
      },
      loading: () => _buildLoadingSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildLoadingSkeleton() {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonLoader(width: 36, height: 36, borderRadius: 10),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonLoader(width: 80, height: 16, borderRadius: 4),
                    SizedBox(height: 4),
                    SkeletonLoader(width: 60, height: 12, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SkeletonLoader(
            width: double.infinity,
            height: 60,
            borderRadius: 12,
          ),
        ],
      ),
    );
  }
}

/// Blurred teaser card shown to non-MAX users to entice subscription
class _AIInsightBlurredTeaser extends ConsumerWidget {
  const _AIInsightBlurredTeaser();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PaywallScreen(
              featureToUnlock: FeatureIds.relationshipAnalysis,
              contextHeadline: PaywallContext.headlineForFeature(
                FeatureIds.relationshipAnalysis,
              ),
            ),
          ),
        );
      },
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row (matches real card)
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        themeColors.primary,
                        themeColors.primaryLight,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    LucideIcons.lightbulb,
                    color: themeColors.onPrimary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'رؤية اليوم',
                        style: AppTypography.titleSmall.copyWith(
                          color: themeColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              themeColors.primary,
                              themeColors.primaryLight,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.sparkles,
                              size: 10,
                              color: themeColors.onPrimary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'AI',
                              style: AppTypography.labelSmall.copyWith(
                                color: themeColors.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Blurred fake insight text with overlay
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Fake insight text behind blur
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: themeColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: themeColors.primary.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'بناءً على تحليل تواصلك الأخير مع عائلتك، ننصحك بالتواصل مع أقاربك الذين لم تتواصل معهم منذ فترة. هناك ٣ أشخاص يحتاجون اهتمامك...',
                      style: AppTypography.bodyMedium.copyWith(
                        color: themeColors.textPrimary,
                        height: 1.6,
                      ),
                    ),
                  ),

                  // Blur filter
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        color: themeColors.glassBackground.withValues(alpha: 0.1),
                      ),
                    ),
                  ),

                  // Lock overlay
                  Positioned.fill(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.lock,
                            color: AppColors.premiumGold,
                            size: 24,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'اشترك لقراءة التحليل',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.premiumGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: AppAnimations.normal)
        .slideY(begin: 0.1, end: 0);
  }
}
