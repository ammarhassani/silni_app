import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/glass_card.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.people_alt_rounded,
      title: 'رحلة الصلة',
      description: 'قرّب قلبك من عائلتك وأحبائك\nبطريقة جميلة وممتعة',
      gradient: AppColors.primaryGradient,
    ),
    OnboardingPage(
      icon: Icons.notifications_active_rounded,
      title: 'التذكيرات السحرية',
      description: 'لن تنسى التواصل مع أحبائك بعد اليوم\nتذكيرات ذكية وشخصية',
      gradient: AppColors.goldenGradient,
    ),
    OnboardingPage(
      icon: Icons.emoji_events_rounded,
      title: 'احتفل بإنجازاتك',
      description: 'كسب النقاط والشارات والإنجازات\nمع كل تواصل مع عائلتك',
      gradient: AppColors.streakFire,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    // Save onboarding completion status
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);

    return Scaffold(
      body: Semantics(
        label: 'شاشة التعريف بالتطبيق',
        child: GradientBackground(
          animated: true,
          child: SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Semantics(
                      label: 'تخطي التعريف',
                      button: true,
                      child: TextButton(
                        onPressed: _finish,
                        child: Text(
                          'تخطي',
                          style: AppTypography.labelLarge.copyWith(
                            color: themeColors.textOnGradient.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Page view
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index], index, themeColors);
                    },
                  ),
                ),

                // Page indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => _buildPageIndicator(index, themeColors),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Next/Finish button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xl,
                  ),
                  child: GradientButton(
                    text: _currentPage == _pages.length - 1 ? 'ابدأ الآن' : 'التالي',
                    onPressed: _nextPage,
                    dramatic: true,
                    icon: _currentPage == _pages.length - 1
                        ? Icons.rocket_launch_rounded
                        : Icons.arrow_back_rounded,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, int index, dynamic themeColors) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.xl),
            // Icon with dramatic animation
            DramaticGlassCard(
              width: 160,
              height: 160,
              child: Container(
                decoration: BoxDecoration(
                  gradient: page.gradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    page.icon,
                    size: 80,
                    color: themeColors.textOnGradient,
                  )
                      .animate(
                        onPlay: (controller) => controller.repeat(reverse: true),
                      )
                      .scale(
                        duration: AppAnimations.loop,
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.1, 1.1),
                      ),
                ),
              ),
            )
              .animate()
              .scale(
                delay: Duration(milliseconds: 100 * index),
                duration: AppAnimations.dramatic,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: AppAnimations.normal),

          const SizedBox(height: AppSpacing.xxl),

          // Title
          Text(
            page.title,
            style: AppTypography.dramatic.copyWith(
              color: themeColors.textOnGradient,
              fontSize: 32,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          )
              .animate(delay: Duration(milliseconds: 200 + (100 * index)))
              .fadeIn(duration: AppAnimations.dramatic)
              .slideY(begin: 0.3, end: 0, curve: AppAnimations.enterCurve),

          const SizedBox(height: AppSpacing.md),

          // Description
          Text(
            page.description,
            style: AppTypography.bodyLarge.copyWith(
              color: themeColors.textOnGradient.withValues(alpha: 0.9),
              height: 1.8,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          )
              .animate(delay: Duration(milliseconds: 400 + (100 * index)))
              .fadeIn(duration: AppAnimations.dramatic)
              .slideY(begin: 0.3, end: 0, curve: AppAnimations.enterCurve),
          const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int index, dynamic themeColors) {
    final isActive = index == _currentPage;

    return AnimatedContainer(
      duration: AppAnimations.normal,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? themeColors.textOnGradient
            : themeColors.textOnGradient.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
      ),
    )
        .animate()
        .scale(
          duration: AppAnimations.normal,
          curve: AppAnimations.toggleCurve,
        )
        .fadeIn();
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Gradient gradient;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}
