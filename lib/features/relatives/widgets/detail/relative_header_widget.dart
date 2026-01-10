import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_themes.dart';
import '../../../../shared/widgets/relative_avatar.dart';
import '../../../../shared/models/relative_model.dart';
import '../../../ai_assistant/widgets/health_badge.dart';
import 'relative_streak_badge.dart';

/// Header widget displaying relative avatar, name, and relationship
class RelativeHeaderWidget extends ConsumerWidget {
  const RelativeHeaderWidget({
    super.key,
    required this.relative,
    required this.themeColors,
    required this.onDelete,
  });

  final Relative relative;
  final ThemeColors themeColors;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Back button and action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_forward_rounded,
                  color: themeColors.textPrimary,
                ),
                onPressed: () => context.pop(),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_rounded, color: themeColors.textPrimary),
                    onPressed: () {
                      context.push('${AppRoutes.editRelative}/${relative.id}');
                    },
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    icon: Icon(Icons.delete_rounded, color: themeColors.accent),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Avatar with Hero animation
          RelativeAvatar(
            relative: relative,
            size: RelativeAvatar.sizeXLarge,
            heroTag: 'avatar-${relative.id}',
            showNeedsAttentionBadge: false,
            showFavoriteBadge: false,
            gradient: themeColors.primaryGradient,
          ),

          const SizedBox(height: AppSpacing.md),

          // Name
          Text(
            relative.fullName,
            style: AppTypography.headlineLarge.copyWith(
              color: themeColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: AppSpacing.xs),

          // Relationship badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              gradient: themeColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Text(
              relative.relationshipType.arabicName,
              style: AppTypography.titleMedium.copyWith(color: themeColors.onPrimary),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Compact row: Favorite + Health + Streak + Priority
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              // Favorite badge (if applicable)
              if (relative.isFavorite)
                Container(
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
                      Icon(Icons.star, color: themeColors.onPrimary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'مفضل',
                        style: AppTypography.labelSmall.copyWith(
                          color: themeColors.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              // Health badge
              HealthBadge(
                relative: relative,
                showLabel: true,
                showScore: false,
              ),

              // Streak badge
              RelativeStreakBadge(relativeId: relative.id),

              // Priority badge
              _PriorityBadge(priority: relative.priority, themeColors: themeColors),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact priority badge using theme gradients
class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({
    required this.priority,
    required this.themeColors,
  });

  final int priority;
  final ThemeColors themeColors;

  @override
  Widget build(BuildContext context) {
    // Use theme gradients and differentiate with icons
    IconData icon;
    String label;

    switch (priority) {
      case 1: // High
        icon = LucideIcons.chevronsUp;
        label = 'عالية';
        break;
      case 2: // Medium
        icon = LucideIcons.minus;
        label = 'متوسطة';
        break;
      default: // Low
        icon = LucideIcons.chevronsDown;
        label = 'منخفضة';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: themeColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: themeColors.onPrimary, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: themeColors.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
