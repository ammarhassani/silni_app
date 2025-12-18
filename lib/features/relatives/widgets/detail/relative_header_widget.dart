import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_themes.dart';
import '../../../../shared/widgets/relative_avatar.dart';
import '../../../../shared/models/relative_model.dart';

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
    final priorityColor = relative.priority == 1
        ? Colors.red
        : relative.priority == 2
            ? Colors.orange
            : Colors.blue;
    final priorityLabel = relative.priority == 1
        ? 'عالية'
        : relative.priority == 2
            ? 'متوسطة'
            : 'منخفضة';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Back button and action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                ),
                onPressed: () => context.pop(),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Colors.white),
                    onPressed: () {
                      context.push('${AppRoutes.editRelative}/${relative.id}');
                    },
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    icon: const Icon(Icons.delete_rounded, color: Colors.red),
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
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: AppSpacing.xs),

          // Relationship
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
              style: AppTypography.titleMedium.copyWith(color: Colors.white),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Favorite badge
          if (relative.isFavorite)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                border: Border.all(color: Colors.amber),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'مفضل',
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.sm),

          // Priority indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.priority_high, color: priorityColor, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'أولوية $priorityLabel',
                style: AppTypography.labelMedium.copyWith(color: priorityColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
