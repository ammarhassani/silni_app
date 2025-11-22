import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/relatives/screens/relatives_screen.dart';
import '../../features/relatives/screens/relative_detail_screen.dart';
import '../../features/statistics/screens/statistics_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import 'app_routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const SplashScreen(),
        ),
      ),

      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const OnboardingScreen(),
        ),
      ),

      // Auth Routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const SignUpScreen(),
        ),
      ),

      // Main App Routes
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const HomeScreen(),
        ),
      ),

      // Relatives Routes
      GoRoute(
        path: AppRoutes.relatives,
        name: 'relatives',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const RelativesScreen(),
        ),
      ),
      GoRoute(
        path: '${AppRoutes.relativeDetail}/:id',
        name: 'relativeDetail',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _buildPageWithTransition(
            context,
            state,
            RelativeDetailScreen(relativeId: id),
          );
        },
      ),

      // Statistics Routes
      GoRoute(
        path: AppRoutes.statistics,
        name: 'statistics',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const StatisticsScreen(),
        ),
      ),

      // Settings Routes
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const SettingsScreen(),
        ),
      ),
    ],
  );
});

/// Build page with custom transition animation
Page<dynamic> _buildPageWithTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Dramatic fade + scale transition
      const begin = 0.0;
      const end = 1.0;
      const curve = Curves.easeInOutCubic;

      final tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: curve),
      );
      final fadeAnimation = animation.drive(tween);

      final scaleTween = Tween(begin: 0.95, end: 1.0).chain(
        CurveTween(curve: curve),
      );
      final scaleAnimation = animation.drive(scaleTween);

      return FadeTransition(
        opacity: fadeAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: child,
        ),
      );
    },
  );
}
