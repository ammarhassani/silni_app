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
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../constants/onboarding_content.dart';
import '../models/onboarding_step.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/feature_showcase_card.dart';
import '../widgets/onboarding_completion_modal.dart';
import '../widgets/onboarding_page_indicator.dart';
import '../widgets/onboarding_progress_bar.dart';

/// Premium onboarding screen for MAX subscribers
/// Shows a carousel of AI features with animations
class PremiumOnboardingScreen extends ConsumerStatefulWidget {
  const PremiumOnboardingScreen({super.key});

  /// Show the onboarding screen as a modal overlay
  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PremiumOnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                ),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: AppAnimations.modal,
      ),
    );
  }

  @override
  ConsumerState<PremiumOnboardingScreen> createState() =>
      _PremiumOnboardingScreenState();
}

class _PremiumOnboardingScreenState
    extends ConsumerState<PremiumOnboardingScreen> {
  late PageController _pageController;
  late ConfettiController _confettiController;
  int _currentPage = 0;

  final List<OnboardingStep> _steps = OnboardingSteps.allSteps;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Start onboarding on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingProvider.notifier).startOnboarding();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    HapticFeedback.selectionClick();
    ref.read(onboardingProvider.notifier).viewStep(page);
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: AppAnimations.modal,
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _tryFeature() {
    HapticFeedback.mediumImpact();
    final step = _steps[_currentPage];
    ref.read(onboardingProvider.notifier).completeStep(_currentPage);
    Navigator.of(context).pop();
    context.push(step.routePath);
  }

  void _skipShowcase() {
    HapticFeedback.lightImpact();
    ref.read(onboardingProvider.notifier).skipShowcase();
    Navigator.of(context).pop();
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.heavyImpact();
    _confettiController.play();
    ref.read(onboardingProvider.notifier).completeOnboarding();

    // Show completion modal after short delay
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.of(context).pop();
      await OnboardingCompletionModal.show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);
    final progress = ref.watch(onboardingProgressProvider);
    final isLastPage = _currentPage == _steps.length - 1;

    // Allow skip only after viewing first 2 pages
    final canSkip = _currentPage >= 2;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background
          const GradientBackground(
            animated: true,
            child: SizedBox.expand(),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header with skip and progress
                _buildHeader(themeColors, progress, canSkip),

                // Page view carousel
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _steps.length,
                    itemBuilder: (context, index) {
                      return FeatureShowcaseCard(
                        step: _steps[index],
                        index: index,
                        isActive: index == _currentPage,
                      );
                    },
                  ),
                ),

                // Page indicators
                OnboardingPageIndicator(
                  currentPage: _currentPage,
                  totalPages: _steps.length,
                ),

                const SizedBox(height: AppSpacing.md),

                // Action buttons
                _buildActionButtons(themeColors, isLastPage),

                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),

          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
              colors: const [
                AppColors.premiumGold,
                AppColors.premiumGoldLight,
                AppColors.islamicGreenLight,
                AppColors.islamicGreenPrimary,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(dynamic themeColors, double progress, bool canSkip) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Skip button (only after first 2 pages)
          SizedBox(
            width: 60,
            child: canSkip
                ? TextButton(
                    onPressed: _skipShowcase,
                    child: Text(
                      OnboardingContent.skipButton,
                      style: AppTypography.labelMedium.copyWith(
                        color: themeColors.textOnGradient.withValues(alpha: 0.7),
                      ),
                    ),
                  )
                    .animate()
                    .fadeIn(duration: AppAnimations.normal)
                : const SizedBox.shrink(),
          ),

          // Progress bar
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: OnboardingProgressBar(
                progress: (_currentPage + 1) / _steps.length,
              ),
            ),
          ),

          // Step counter
          SizedBox(
            width: 60,
            child: Text(
              OnboardingContent.stepCounter(_currentPage + 1, _steps.length),
              style: AppTypography.labelMedium.copyWith(
                color: themeColors.textOnGradient.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(dynamic themeColors, bool isLastPage) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          // Primary action - Try feature or Complete
          GradientButton(
            text: isLastPage
                ? OnboardingContent.startJourneyButton
                : OnboardingContent.tryNowButton,
            onPressed: isLastPage ? _completeOnboarding : _tryFeature,
            dramatic: true,
            icon: isLastPage
                ? Icons.rocket_launch_rounded
                : Icons.play_arrow_rounded,
          )
              .animate()
              .fadeIn(duration: AppAnimations.normal)
              .slideY(begin: 0.2, end: 0),

          const SizedBox(height: AppSpacing.sm),

          // Secondary action - Next
          if (!isLastPage)
            OutlinedGradientButton(
              text: OnboardingContent.nextButton,
              onPressed: _nextPage,
              icon: Icons.arrow_back_rounded, // RTL - back arrow is "next"
            )
                .animate()
                .fadeIn(duration: AppAnimations.normal, delay: 100.ms)
                .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}
