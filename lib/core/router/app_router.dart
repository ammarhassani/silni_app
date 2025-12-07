import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/relatives/screens/relatives_screen.dart';
import '../../features/relatives/screens/relative_detail_screen.dart';
import '../../features/relatives/screens/add_relative_screen.dart';
import '../../features/relatives/screens/edit_relative_screen.dart';
import '../../features/reminders/screens/reminders_screen.dart';
import '../../features/family_tree/screens/family_tree_screen.dart';
import '../../features/statistics/screens/statistics_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/contacts/screens/contact_import_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/gamification/screens/gaming_center_screen.dart';
import '../../features/gamification/screens/badges_screen.dart';
import '../../features/gamification/screens/detailed_stats_screen.dart';
import '../../features/gamification/screens/leaderboard_screen.dart';
import 'app_routes.dart';
import 'navigation_service.dart';
import '../../../shared/widgets/persistent_bottom_nav.dart';

/// Custom navigator observer for logging navigation events
class _AppNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (kDebugMode) {
      debugPrint('');
      debugPrint('🧭 [NAVIGATION] didPush');
      debugPrint('   - New route: ${route.settings.name ?? '(unnamed)'}');
      debugPrint(
        '   - Previous route: ${previousRoute?.settings.name ?? '(none)'}',
      );
      debugPrint('');
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (kDebugMode) {
      debugPrint('');
      debugPrint('🧭 [NAVIGATION] didPop');
      debugPrint('   - Popped route: ${route.settings.name ?? '(unnamed)'}');
      debugPrint(
        '   - Back to route: ${previousRoute?.settings.name ?? '(none)'}',
      );
      debugPrint('');
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (kDebugMode) {
      debugPrint('');
      debugPrint('🧭 [NAVIGATION] didRemove');
      debugPrint('   - Removed route: ${route.settings.name ?? '(unnamed)'}');
      debugPrint(
        '   - Previous route: ${previousRoute?.settings.name ?? '(none)'}',
      );
      debugPrint('');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (kDebugMode) {
      debugPrint('');
      debugPrint('🧭 [NAVIGATION] didReplace');
      debugPrint('   - New route: ${newRoute?.settings.name ?? '(unnamed)'}');
      debugPrint('   - Old route: ${oldRoute?.settings.name ?? '(none)'}');
      debugPrint('');
    }
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: NavigationService.navigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true, // GoRouter's built-in logging
    observers: [_AppNavigatorObserver()], // Custom logging observer
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const SplashScreen()),
      ),

      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const OnboardingScreen()),
      ),

      // Auth Routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const SignUpScreen()),
      ),

      // Main App Routes
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) =>
            _buildPageWithNavigation(context, state, const HomeScreen()),
      ),

      // Relatives Routes
      GoRoute(
        path: AppRoutes.relatives,
        name: 'relatives',
        pageBuilder: (context, state) =>
            _buildPageWithNavigation(context, state, const RelativesScreen()),
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
      GoRoute(
        path: AppRoutes.addRelative,
        name: 'addRelative',
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const AddRelativeScreen()),
      ),
      GoRoute(
        path: '${AppRoutes.editRelative}/:id',
        name: 'editRelative',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _buildPageWithTransition(
            context,
            state,
            EditRelativeScreen(relativeId: id),
          );
        },
      ),

      // Achievements Route
      GoRoute(
        path: AppRoutes.achievements,
        name: 'achievements',
        pageBuilder: (context, state) => _buildPageWithNavigation(
          context,
          state,
          const GamingCenterScreen(),
        ),
      ),

      // Reminders Routes
      GoRoute(
        path: AppRoutes.reminders,
        name: 'reminders',
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const RemindersScreen()),
      ),

      // Family Tree Routes
      GoRoute(
        path: AppRoutes.familyTree,
        name: 'familyTree',
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const FamilyTreeScreen()),
      ),

      // Statistics Routes
      GoRoute(
        path: AppRoutes.statistics,
        name: 'statistics',
        pageBuilder: (context, state) =>
            _buildPageWithNavigation(context, state, const StatisticsScreen()),
      ),

      // Settings Routes
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) =>
            _buildPageWithNavigation(context, state, const SettingsScreen()),
      ),

      // Profile Routes
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        pageBuilder: (context, state) =>
            _buildPageWithNavigation(context, state, const ProfileScreen()),
      ),

      // Import Contacts Routes
      GoRoute(
        path: AppRoutes.importContacts,
        name: 'importContacts',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const ContactImportScreen(),
        ),
      ),

      // Notifications Routes
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const NotificationsScreen(),
        ),
      ),

      // Gamification Routes
      GoRoute(
        path: AppRoutes.badges,
        name: 'badges',
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const BadgesScreen()),
      ),
      GoRoute(
        path: AppRoutes.detailedStats,
        name: 'detailedStats',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const DetailedStatsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.leaderboard,
        name: 'leaderboard',
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const LeaderboardScreen()),
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

      final tween = Tween(
        begin: begin,
        end: end,
      ).chain(CurveTween(curve: curve));
      final fadeAnimation = animation.drive(tween);

      final scaleTween = Tween(
        begin: 0.95,
        end: 1.0,
      ).chain(CurveTween(curve: curve));
      final scaleAnimation = animation.drive(scaleTween);

      return FadeTransition(
        opacity: fadeAnimation,
        child: ScaleTransition(scale: scaleAnimation, child: child),
      );
    },
  );
}

/// Build page with global navigation for main app routes
Page<dynamic> _buildPageWithNavigation(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: _NavigationWrapper(child: child),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Dramatic fade + scale transition
      const begin = 0.0;
      const end = 1.0;
      const curve = Curves.easeInOutCubic;

      final tween = Tween(
        begin: begin,
        end: end,
      ).chain(CurveTween(curve: curve));
      final fadeAnimation = animation.drive(tween);

      final scaleTween = Tween(
        begin: 0.95,
        end: 1.0,
      ).chain(CurveTween(curve: curve));
      final scaleAnimation = animation.drive(scaleTween);

      return FadeTransition(
        opacity: fadeAnimation,
        child: ScaleTransition(scale: scaleAnimation, child: child),
      );
    },
  );
}

/// Wrapper widget that combines page content with persistent navigation
class _NavigationWrapper extends StatelessWidget {
  const _NavigationWrapper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        Positioned.fill(child: child),
        // Navigation bar at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              decoration: const BoxDecoration(color: Colors.transparent),
              child: PersistentBottomNav(
                onNavTapped: (route) {
                  context.push(route);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
