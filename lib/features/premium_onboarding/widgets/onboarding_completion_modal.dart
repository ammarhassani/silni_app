import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../constants/onboarding_content.dart';
import '../models/onboarding_step.dart';
import 'animated_feature_icon.dart';

/// Celebration modal shown when onboarding is completed
class OnboardingCompletionModal extends ConsumerStatefulWidget {
  const OnboardingCompletionModal({super.key});

  /// Show the completion modal
  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.islamicGreenDark.withValues(alpha: 0.9),
      transitionDuration: AppAnimations.modal,
      pageBuilder: (context, animation, secondaryAnimation) {
        return const OnboardingCompletionModal();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  @override
  ConsumerState<OnboardingCompletionModal> createState() =>
      _OnboardingCompletionModalState();
}

class _OnboardingCompletionModalState
    extends ConsumerState<OnboardingCompletionModal> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Trigger haptic and confetti
    HapticFeedback.heavyImpact();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _navigateToFeature(String route) {
    Navigator.of(context).pop();
    context.push(route);
  }

  void _close() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti from top
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2, // Down
              emissionFrequency: 0.05,
              numberOfParticles: 25,
              gravity: 0.2,
              colors: const [
                AppColors.premiumGold,
                AppColors.premiumGoldLight,
                AppColors.islamicGreenLight,
                AppColors.islamicGreenPrimary,
                Colors.white,
              ],
            ),
          ),

          // Modal content
          DramaticGlassCard(
            gradient: LinearGradient(
              colors: [
                AppColors.premiumGold.withValues(alpha: 0.3),
                AppColors.premiumGoldDark.withValues(alpha: 0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Trophy icon with glow
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.goldenGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.premiumGold.withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
                  )
                      .animate(
                        onPlay: (controller) => controller.repeat(reverse: true),
                      )
                      .scale(
                        begin: const Offset(0.95, 0.95),
                        end: const Offset(1.05, 1.05),
                        duration: AppAnimations.celebration,
                      ),

                  const SizedBox(height: AppSpacing.lg),

                  // Title
                  Text(
                    OnboardingContent.completionTitle,
                    style: AppTypography.dramatic.copyWith(
                      color: AppColors.premiumGold,
                      fontSize: 32,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: AppAnimations.normal)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: AppSpacing.sm),

                  // Subtitle
                  Text(
                    OnboardingContent.completionSubtitle,
                    style: AppTypography.bodyLarge.copyWith(
                      color: themeColors.textOnGradient.withValues(alpha: 0.85),
                      height: 1.8,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: AppAnimations.normal),

                  const SizedBox(height: AppSpacing.xl),

                  // Quick action title
                  Text(
                    OnboardingContent.quickActionsTitle,
                    style: AppTypography.labelLarge.copyWith(
                      color: themeColors.textOnGradient.withValues(alpha: 0.7),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: AppAnimations.normal),

                  const SizedBox(height: AppSpacing.md),

                  // Quick action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      _QuickActionButton(
                        step: OnboardingSteps.aiFeatures[0], // AI Counselor
                        onTap: () => _navigateToFeature(AppRoutes.aiChat),
                      ),
                      _QuickActionButton(
                        step: OnboardingSteps.aiFeatures[1], // Message Composer
                        onTap: () => _navigateToFeature(AppRoutes.aiMessages),
                      ),
                      _QuickActionButton(
                        step: OnboardingSteps.aiFeatures[2], // Scripts
                        onTap: () => _navigateToFeature(AppRoutes.aiScripts),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 600.ms, duration: AppAnimations.normal)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: AppSpacing.xl),

                  // Close button
                  GradientButton(
                    text: OnboardingContent.completionCta,
                    onPressed: _close,
                    dramatic: true,
                    icon: Icons.rocket_launch_rounded,
                  )
                      .animate()
                      .fadeIn(delay: 800.ms, duration: AppAnimations.normal)
                      .slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(duration: AppAnimations.normal)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                duration: AppAnimations.modal,
                curve: Curves.easeOut,
              ),
        ],
      ),
    );
  }
}

/// Quick action button for completion modal
class _QuickActionButton extends StatelessWidget {
  final OnboardingStep step;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.step,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SmallFeatureIcon(
            icon: step.icon,
            gradient: step.gradient,
            size: 44,
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: 56,
            child: Text(
              step.titleArabic.split(' ').first, // First word only
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
