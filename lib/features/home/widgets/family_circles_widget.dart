import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/avatar_carousel.dart';

/// Family members avatar carousel widget
class FamilyCirclesWidget extends ConsumerWidget {
  const FamilyCirclesWidget({
    super.key,
    required this.relatives,
  });

  final List<Relative> relatives;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    if (relatives.isEmpty) {
      return _buildEmptyState(context, themeColors);
    }

    // Sort by creation date (oldest first) so newest appears on LEFT in RTL
    final sortedByDate = List<Relative>.from(relatives)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Show first 8 relatives in carousel
    final displayRelatives = sortedByDate.take(8).toList();

    return Semantics(
      label: 'قسم العائلة - ${relatives.length} قريب',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'عائلتك',
                style: AppTypography.headlineSmall.copyWith(
                  color: themeColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Semantics(
                label: 'عرض جميع الأقارب',
                button: true,
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.relatives),
                  child: Row(
                    children: [
                      Text(
                        'عرض الكل',
                        style: AppTypography.labelLarge.copyWith(
                          color: themeColors.textPrimary.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: themeColors.textPrimary.withValues(alpha: 0.9),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AvatarCarousel(
            relatives: displayRelatives,
            onAddRelative: () => context.push(AppRoutes.addRelative),
          ),
        ],
      ),
    )
        .animate(delay: AppAnimations.modal)
        .fadeIn(duration: AppAnimations.normal)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildEmptyState(BuildContext context, dynamic themeColors) {
    return Semantics(
      label: 'لا يوجد أقارب - ابدأ بإضافة أفراد عائلتك',
      child: GlassCard(
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: themeColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'ابدأ بإضافة أفراد عائلتك',
              style: AppTypography.titleMedium.copyWith(
                color: themeColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'أضف والديك، إخوتك، أجدادك وباقي أقاربك',
              style: AppTypography.bodySmall.copyWith(
                color: themeColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            GradientButton(
              text: 'إضافة أول قريب',
              onPressed: () => context.push(AppRoutes.addRelative),
              icon: Icons.person_add,
            ),
          ],
        ),
      ),
    );
  }
}
