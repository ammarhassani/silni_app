import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:silni_app/core/constants/app_animations.dart';
import 'package:silni_app/core/constants/app_spacing.dart';
import 'package:silni_app/core/constants/app_typography.dart';
import 'package:silni_app/core/router/app_routes.dart';
import 'package:silni_app/core/theme/theme_provider.dart';
import 'package:silni_app/features/ai_assistant/services/occasion_message_service.dart';
import 'package:silni_app/shared/widgets/glass_card.dart';

/// Home screen card that appears when an occasion is within 7 days.
///
/// Uses [OccasionMessageService.getUpcomingOccasion] to check for upcoming
/// occasions. Returns [SizedBox.shrink] when nothing is upcoming.
class OccasionCard extends ConsumerWidget {
  const OccasionCard({super.key, required this.userId});

  final String userId;

  String _occasionEmoji(OccasionType occasion) {
    switch (occasion) {
      case OccasionType.eidAlFitr:
        return '🌙';
      case OccasionType.eidAlAdha:
        return '🐑';
      case OccasionType.ramadan:
        return '🕌';
      case OccasionType.nationalDay:
        return '🇸🇦';
    }
  }

  String _occasionSubtitle(OccasionType occasion) {
    switch (occasion) {
      case OccasionType.eidAlFitr:
      case OccasionType.eidAlAdha:
        return 'رسائل العيد جاهزة لأقاربك ✉️';
      case OccasionType.ramadan:
        return 'رسائل رمضان جاهزة لأقاربك ✉️';
      case OccasionType.nationalDay:
        return 'رسائل اليوم الوطني جاهزة لأقاربك ✉️';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final occasion = OccasionMessageService.getUpcomingOccasion();

    if (occasion == null) {
      return const SizedBox.shrink();
    }

    final themeColors = ref.watch(themeColorsProvider);

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () {
        context.push(
          '${AppRoutes.occasionMessages}?occasion=${occasion.key}',
        );
      },
      semanticsLabel: _occasionSubtitle(occasion),
      child: Row(
        children: [
          Text(
            _occasionEmoji(occasion),
            style: AppTypography.headlineSmall,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  occasion.arabicName,
                  style: AppTypography.labelMedium.copyWith(
                    color: themeColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _occasionSubtitle(occasion),
                  style: AppTypography.titleSmall.copyWith(
                    color: themeColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: AppSpacing.iconSm,
            color: themeColors.textSecondary,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: AppAnimations.normal)
        .slideY(begin: 0.1, end: 0);
  }
}
