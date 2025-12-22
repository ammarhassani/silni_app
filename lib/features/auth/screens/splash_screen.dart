import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silni_app/core/constants/app_typography.dart';
import 'package:silni_app/core/router/app_routes.dart';
import 'package:silni_app/core/theme/theme_provider.dart';
import 'package:silni_app/shared/widgets/gradient_background.dart';
import 'package:silni_app/features/auth/providers/auth_provider.dart';
import 'package:silni_app/core/config/supabase_config.dart';
import 'package:universal_html/html.dart' as html;

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  bool _fontLoaded = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _loadFontAndNavigate();
  }

  Future<void> _loadFontAndNavigate() async {
    // Preload the fonts
    await GoogleFonts.pendingFonts([
      GoogleFonts.reemKufiFun(),
      GoogleFonts.cairo(),
    ]);

    if (mounted) {
      setState(() => _fontLoaded = true);
    }

    // Wait for animations to play
    await Future.delayed(const Duration(seconds: 3));
    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;

    // For web: Check if this is an OAuth callback (URL contains auth code)
    // Supabase processes the code during initialization, so user may already be logged in
    if (kIsWeb) {
      final uri = Uri.parse(html.window.location.href);
      final hasAuthCode = uri.queryParameters.containsKey('code');

      if (hasAuthCode) {
        // Supabase has already processed the OAuth callback during initialization
        // Check if user is already authenticated
        final currentUser = SupabaseConfig.currentUser;

        if (currentUser != null) {
          // User is already logged in from OAuth callback
          // Clear the URL params to prevent re-processing on refresh
          html.window.history.replaceState(null, '', '/');
          if (mounted) context.go(AppRoutes.home);
          return;
        }

        // If not yet authenticated, wait briefly for the auth state to settle
        // (in case Supabase is still processing)
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        final userAfterWait = SupabaseConfig.currentUser;
        if (userAfterWait != null) {
          html.window.history.replaceState(null, '', '/');
          context.go(AppRoutes.home);
          return;
        }
      }
    }

    // IMPORTANT: First try to restore persistent session
    // This calls checkPersistentSession() which handles session recovery after app kill
    final sessionRestored = await ref.read(sessionInitializationProvider.future);

    if (!mounted) return;

    // Check if user is authenticated (after session restoration attempt)
    final isAuthenticated = sessionRestored || ref.read(isAuthenticatedProvider);

    if (isAuthenticated) {
      if (mounted) context.go(AppRoutes.home);
    } else {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('onboarding_completed') ?? false;

      if (!mounted) return;

      if (hasSeenOnboarding) {
        context.go(AppRoutes.login);
      } else {
        context.go(AppRoutes.onboarding);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);

    return Scaffold(
      body: GradientBackground(
        animated: true,
        child: Center(
          child: AnimatedOpacity(
            opacity: _fontLoaded ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Name with animated glow - using Reem Kufi Fun
                AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  final glowValue = _glowController.value;
                  return Text(
                    'صِـلْـنِـي',
                    style: GoogleFonts.reemKufiFun(
                      fontSize: 80,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: themeColors.secondary.withValues(alpha: 0.6 + glowValue * 0.4),
                          blurRadius: 25 + glowValue * 30,
                        ),
                        Shadow(
                          color: themeColors.primary.withValues(alpha: 0.4 + glowValue * 0.4),
                          blurRadius: 50 + glowValue * 35,
                        ),
                        Shadow(
                          color: themeColors.accent.withValues(alpha: 0.3 + glowValue * 0.3),
                          blurRadius: 80 + glowValue * 25,
                        ),
                      ],
                    ),
                  );
                },
              )
                  .animate()
                  // Blur to clear reveal
                  .blur(begin: const Offset(20, 20), end: Offset.zero, duration: 600.ms, curve: Curves.easeOut)
                  .fadeIn(duration: 400.ms)
                  // Scale with bounce
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1, 1),
                    duration: 800.ms,
                    curve: Curves.elasticOut,
                  )
                  // Slight float up
                  .moveY(begin: 30, end: 0, duration: 600.ms, curve: Curves.easeOutCubic)
                  .then(delay: 200.ms)
                  // Shimmer sweep
                  .shimmer(
                    duration: 2000.ms,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),

              const SizedBox(height: 48),

              // Tagline with app font (Cairo)
              Text(
                'صِلْ رَحِمَكَ بِحُبٍّ',
                style: AppTypography.titleLarge.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              )
                  .animate(delay: 900.ms)
                  // Typewriter-like letter spacing animation
                  .fadeIn(duration: 500.ms)
                  .blur(begin: const Offset(8, 0), end: Offset.zero, duration: 500.ms)
                  .slideY(begin: 0.5, end: 0, duration: 600.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 100),

              // Loading with pulse
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    themeColors.secondary.withValues(alpha: 0.8),
                  ),
                  strokeWidth: 2.5,
                ),
              )
                  .animate(delay: 1500.ms)
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0, 0), end: const Offset(1, 1), duration: 500.ms, curve: Curves.easeOutBack)
                  .then()
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 800.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
