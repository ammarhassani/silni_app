import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/theme_provider.dart';

/// Animated page indicator dots for onboarding carousel
class OnboardingPageIndicator extends ConsumerWidget {
  final int currentPage;
  final int totalPages;

  const OnboardingPageIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final isActive = index == currentPage;
        final isPast = index < currentPage;

        return AnimatedContainer(
          duration: AppAnimations.normal,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            gradient: isActive
                ? AppColors.goldenGradient
                : null,
            color: isActive
                ? null
                : isPast
                    ? themeColors.textOnGradient.withValues(alpha: 0.6)
                    : themeColors.textOnGradient.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.premiumGold.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        )
            .animate(target: isActive ? 1 : 0)
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.1, 1.1),
              duration: AppAnimations.normal,
              curve: AppAnimations.toggleCurve,
            );
      }),
    );
  }
}

/// Page indicator with numbers (alternative style)
class NumberedPageIndicator extends ConsumerWidget {
  final int currentPage;
  final int totalPages;

  const NumberedPageIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final isActive = index == currentPage;
        final isPast = index < currentPage;

        return AnimatedContainer(
          duration: AppAnimations.normal,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: isActive ? AppColors.goldenGradient : null,
            color: isActive
                ? null
                : isPast
                    ? themeColors.textOnGradient.withValues(alpha: 0.4)
                    : themeColors.textOnGradient.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.premiumGold.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isPast
                ? Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: isActive ? Colors.white : themeColors.textOnGradient,
                  )
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      color:
                          isActive ? Colors.white : themeColors.textOnGradient,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
          ),
        );
      }),
    );
  }
}
