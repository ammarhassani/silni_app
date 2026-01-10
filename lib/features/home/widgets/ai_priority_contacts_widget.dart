import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/relative_avatar.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../providers/home_providers.dart';

/// AI-powered priority contacts widget (MAX subscription only)
///
/// Uses admin-configured touch point to show AI-ranked relatives
/// who need attention today based on:
/// - Relationship health status
/// - Days since last contact
/// - Upcoming occasions
/// - Streak risk
class AIPriorityContactsWidget extends ConsumerWidget {
  const AIPriorityContactsWidget({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMax = ref.watch(isMaxProvider);

    // Only show for MAX subscribers
    if (!isMax) {
      return const SizedBox.shrink();
    }

    return _AIPriorityContactsContent(userId: userId);
  }
}

class _AIPriorityContactsContent extends ConsumerWidget {
  const _AIPriorityContactsContent({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final relativesAsync = ref.watch(relativesStreamProvider(userId));

    return relativesAsync.when(
      data: (relatives) {
        if (relatives.isEmpty) {
          return const SizedBox.shrink();
        }

        // Get at-risk and needs-attention relatives
        final priorityRelatives = relatives.where((r) =>
            r.healthStatus2 == RelationshipHealthStatus.atRisk ||
            r.healthStatus2 == RelationshipHealthStatus.needsAttention).toList();

        if (priorityRelatives.isEmpty) {
          return const SizedBox.shrink();
        }

        // Sort by health status (at-risk first) then by days since contact
        priorityRelatives.sort((a, b) {
          if (a.healthStatus2 == RelationshipHealthStatus.atRisk &&
              b.healthStatus2 != RelationshipHealthStatus.atRisk) {
            return -1;
          }
          if (b.healthStatus2 == RelationshipHealthStatus.atRisk &&
              a.healthStatus2 != RelationshipHealthStatus.atRisk) {
            return 1;
          }
          final aDays = a.daysSinceLastContact ?? 999;
          final bDays = b.daysSinceLastContact ?? 999;
          return bDays.compareTo(aDays);
        });

        // Take top 3
        final topPriority = priorityRelatives.take(3).toList();

        return GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          themeColors.primary,
                          themeColors.primaryLight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      LucideIcons.users,
                      color: themeColors.onPrimary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'من يحتاجك اليوم',
                      style: AppTypography.titleSmall.copyWith(
                        color: themeColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          themeColors.primary,
                          themeColors.primaryLight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.sparkles,
                          size: 12,
                          color: themeColors.onPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'AI',
                          style: AppTypography.labelSmall.copyWith(
                            color: themeColors.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Priority contacts list
              ...topPriority.asMap().entries.map((entry) {
                final index = entry.key;
                final relative = entry.value;
                return _PriorityContactTile(
                  relative: relative,
                  themeColors: themeColors,
                ).animate(delay: Duration(milliseconds: 50 * index))
                    .fadeIn(duration: AppAnimations.fast)
                    .slideX(begin: 0.1, end: 0);
              }),
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
              SkeletonLoader(width: 32, height: 32, borderRadius: 8),
              const SizedBox(width: AppSpacing.sm),
              SkeletonLoader(width: 120, height: 18, borderRadius: 4),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...List.generate(2, (index) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                const CircleSkeletonLoader(size: 44),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonLoader(width: 100, height: 14, borderRadius: 4),
                      SizedBox(height: 4),
                      SkeletonLoader(width: 80, height: 12, borderRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _PriorityContactTile extends StatelessWidget {
  const _PriorityContactTile({
    required this.relative,
    required this.themeColors,
  });

  final Relative relative;
  final ThemeColors themeColors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('${AppRoutes.relativeDetail}/${relative.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: themeColors.glassBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeColors.glassBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar using RelativeAvatar
            RelativeAvatar(
              relative: relative,
              size: 44,
              showNeedsAttentionBadge: true,
              showFavoriteBadge: false,
              gradient: themeColors.primaryGradient,
            ),
            const SizedBox(width: AppSpacing.sm),

            // Name and reason
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    relative.fullName,
                    style: AppTypography.bodyMedium.copyWith(
                      color: themeColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getReasonText(),
                    style: AppTypography.labelSmall.copyWith(
                      color: themeColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              LucideIcons.chevronLeft,
              color: themeColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _getReasonText() {
    final days = relative.daysSinceLastContact;
    if (days == null) {
      return 'لم يتم التواصل بعد';
    }
    if (days == 0) {
      return 'تواصلت اليوم';
    }
    if (days == 1) {
      return 'منذ يوم واحد';
    }
    if (days < 7) {
      return 'منذ $days أيام';
    }
    if (days < 30) {
      final weeks = (days / 7).floor();
      return weeks == 1 ? 'منذ أسبوع' : 'منذ $weeks أسابيع';
    }
    final months = (days / 30).floor();
    return months == 1 ? 'منذ شهر' : 'منذ $months أشهر';
  }
}
