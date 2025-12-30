import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../models/onboarding_step.dart';
import 'animated_feature_icon.dart';

/// Card displaying a single feature in the onboarding carousel
class FeatureShowcaseCard extends ConsumerWidget {
  final OnboardingStep step;
  final int index;
  final bool isActive;

  const FeatureShowcaseCard({
    super.key,
    required this.step,
    required this.index,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    // Extract gradient colors for glow effect
    final gradientColors = (step.gradient as LinearGradient).colors;
    final primaryColor = gradientColors.first;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.xl),

            // Animated feature icon
            AnimatedFeatureIcon(
              icon: step.icon,
              gradient: step.gradient,
              isActive: isActive,
            )
                .animate(target: isActive ? 1 : 0)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  duration: AppAnimations.dramatic,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: AppAnimations.normal),

            const SizedBox(height: AppSpacing.xl),

            // Title with dramatic styling and glow
            Text(
              step.titleArabic,
              style: AppTypography.dramatic.copyWith(
                color: themeColors.textOnGradient,
                fontSize: 32,
                shadows: [
                  Shadow(
                    blurRadius: 20,
                    color: primaryColor.withValues(alpha: 0.5),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            )
                .animate(delay: 100.ms)
                .fadeIn(duration: AppAnimations.normal)
                .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

            const SizedBox(height: AppSpacing.md),

            // Description
            Text(
              step.descriptionArabic,
              style: AppTypography.bodyLarge.copyWith(
                color: themeColors.textOnGradient.withValues(alpha: 0.85),
                height: 1.8,
              ),
              textAlign: TextAlign.center,
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: AppAnimations.normal)
                .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

            const SizedBox(height: AppSpacing.lg),

            // Bullet points
            ...step.bulletPoints.asMap().entries.map((entry) {
              return _BulletPoint(
                text: entry.value,
                index: entry.key,
                gradient: step.gradient,
                themeColors: themeColors,
              );
            }),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  final int index;
  final Gradient gradient;
  final dynamic themeColors;

  const _BulletPoint({
    required this.text,
    required this.index,
    required this.gradient,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Checkmark icon with gradient background
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (gradient as LinearGradient).colors.first.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Bullet text
          Flexible(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: themeColors.textOnGradient,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 400 + (index * 100)))
        .fadeIn(duration: AppAnimations.normal)
        .slideX(begin: 0.2, end: 0, curve: Curves.easeOut);
  }
}
