import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Wait for dramatic animation
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Check if user is authenticated
    final isAuthenticated = ref.read(isAuthenticatedProvider);

    if (isAuthenticated) {
      context.go(AppRoutes.home);
    } else {
      // Check if user has seen onboarding
      // TODO: Add shared preferences to check onboarding status
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        animated: true,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with dramatic entrance
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.goldenGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.premiumGold.withOpacity(0.5),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.people_alt_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              )
                  .animate()
                  .scale(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: const Duration(milliseconds: 400))
                  .shimmer(
                    duration: const Duration(seconds: 2),
                    color: Colors.white.withOpacity(0.5),
                  ),

              const SizedBox(height: 40),

              // App Name - Arabic
              Text(
                'صِلْني',
                style: AppTypography.hero.copyWith(
                  color: Colors.white,
                  fontSize: 64,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                ),
              )
                  .animate(delay: const Duration(milliseconds: 400))
                  .fadeIn(duration: const Duration(milliseconds: 600))
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

              const SizedBox(height: 16),

              // Tagline
              Text(
                'صِلْ رَحِمَك بِحُبّ',
                style: AppTypography.titleLarge.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              )
                  .animate(delay: const Duration(milliseconds: 800))
                  .fadeIn(duration: const Duration(milliseconds: 600))
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

              const SizedBox(height: 60),

              // Loading indicator with glow
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
                  ),
                  strokeWidth: 3,
                ),
              )
                  .animate(
                    onPlay: (controller) => controller.repeat(),
                  )
                  .fadeIn(
                    delay: const Duration(milliseconds: 1200),
                    duration: const Duration(milliseconds: 400),
                  )
                  .shimmer(
                    duration: const Duration(seconds: 1),
                    color: Colors.white.withOpacity(0.3),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
