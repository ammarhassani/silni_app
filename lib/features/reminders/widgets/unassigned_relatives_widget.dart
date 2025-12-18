import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/widgets/glass_card.dart';

/// Widget displaying unassigned relatives with drag support
class UnassignedRelativesWidget extends StatelessWidget {
  const UnassignedRelativesWidget({
    super.key,
    required this.unassignedRelatives,
  });

  final List<Relative> unassignedRelatives;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اسحب الأقارب لإضافتهم إلى تذكير',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: unassignedRelatives.map((relative) {
              return Draggable<Relative>(
                data: relative,
                feedback: Material(
                  color: Colors.transparent,
                  child: Opacity(
                    opacity: 0.8,
                    child: _RelativeAvatarCard(relative: relative),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: _RelativeAvatarCard(relative: relative),
                ),
                child: _RelativeAvatarCard(relative: relative),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RelativeAvatarCard extends ConsumerWidget {
  const _RelativeAvatarCard({required this.relative});

  final Relative relative;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: themeColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: themeColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(relative.displayEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: AppSpacing.sm),
          Text(
            relative.fullName,
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
