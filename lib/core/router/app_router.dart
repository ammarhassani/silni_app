import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/gradient_background.dart';
import '../../shared/widgets/error_widgets.dart';
import '../config/supabase_config.dart';
import '../providers/connectivity_provider.dart';
import '../providers/stream_recovery_provider.dart';
import '../providers/realtime_provider.dart';
import '../providers/subscription_provider.dart';
import '../models/subscription_tier.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/email_verification_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/relatives/screens/relatives_screen.dart';
import '../../features/relatives/screens/relative_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/onboarding_wizard/onboarding_wizard_screen.dart';
import '../../features/relatives/screens/add_relative_screen.dart';
import '../../features/relatives/screens/edit_relative_screen.dart';
import '../../features/reminders/screens/reminders_screen.dart';
import '../../features/reminders/screens/reminders_due_screen.dart';
import '../../features/family_tree/screens/family_tree_screen.dart';
import '../../features/ai_assistant/screens/ai_hub_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/contacts/screens/contact_import_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/notifications/screens/notification_history_screen.dart';
import '../../features/family_groups/screens/create_group_screen.dart';
import '../../features/family_groups/screens/family_group_screen.dart';
import '../../features/family_groups/screens/join_group_screen.dart';
import '../../features/wrapped/screens/monthly_wrapped_screen.dart';
import '../../features/ai_assistant/screens/ai_chat_screen.dart';
import '../../features/ai_assistant/screens/communication_scripts_screen.dart';
import '../../features/ai_assistant/screens/occasion_messages_screen.dart';
import '../../features/ai_assistant/screens/weekly_report_screen.dart';
import '../../features/ai_assistant/services/occasion_message_service.dart';
import 'app_routes.dart';
import 'navigation_service.dart';
import '../services/analytics.dart';
import 'performance_navigator_observer.dart';
import '../../shared/widgets/persistent_bottom_nav.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: NavigationService.navigatorKey,
    initialLocation: AppRoutes.splash,
    observers: [
      AnalyticsService.observer,
      PerformanceNavigatorObserver(),
    ],
    // Comprehensive auth middleware for all routes
    redirect: (context, state) {
      // Strip deep link schemes so GoRouter can match paths.
      // Custom scheme: com.silni.app://join/CODE → /join/CODE
      // HTTPS link: https://silniapp.com/join/CODE → /join/CODE
      final fullLocation = state.uri.toString();
      if (fullLocation.startsWith('com.silni.app://')) {
        final uri = Uri.parse(fullLocation);
        final hostPart = uri.host; // e.g. "join"
        final pathPart = uri.path; // e.g. "/CODE"
        final cleanPath = '/$hostPart$pathPart';
        return uri.query.isNotEmpty ? '$cleanPath?${uri.query}' : cleanPath;
      }
      if (fullLocation.startsWith('https://silniapp.com/')) {
        final uri = Uri.parse(fullLocation);
        final cleanPath = uri.path; // e.g. "/join/CODE"
        return uri.query.isNotEmpty ? '$cleanPath?${uri.query}' : cleanPath;
      }

      final isAuthenticated =
          SupabaseConfig.isInitialized && SupabaseConfig.currentUser != null;
      final currentPath = state.matchedLocation;
      final isPublicRoute = AppRoutes.isPublicRoute(currentPath);

      // Case 1: User on splash - let splash screen handle session initialization
      // Don't redirect automatically to avoid race condition with session restoration
      if (currentPath == AppRoutes.splash) {
        return null; // Let splash screen complete initialization and navigate
      }

      // Case 2: Authenticated user on auth routes (login/signup) - redirect
      // to home OR to wizard if first-run setup not yet complete
      if (isAuthenticated &&
          (currentPath == AppRoutes.login || currentPath == AppRoutes.signup)) {
        return _setupCompletePathForAuthed(ref);
      }

      // Case 2b: Authenticated user landing on home but setup not done →
      // wizard. Reads SharedPreferences synchronously via the cached value
      // written by main.dart's auth listener. Defensive: if cache is missing
      // (first cold-launch with a stale prefs), still allows /home — the
      // splash + login flows backfill the cache.
      if (isAuthenticated &&
          currentPath == AppRoutes.home &&
          _setupNotComplete(ref)) {
        return AppRoutes.onboardingWizard;
      }

      // Case 3: Unauthenticated user on protected route - redirect to login
      if (!isAuthenticated && !isPublicRoute) {
        // Save intended destination for post-login redirect.
        // Include query parameters so they survive the redirect.
        final fullPath = state.uri.query.isNotEmpty
            ? '${state.matchedLocation}?${state.uri.query}'
            : state.matchedLocation;
        final redirectPath = Uri.encodeComponent(fullPath);
        return '${AppRoutes.login}?redirect=$redirectPath';
      }

      // Case 4: Free user on premium route - redirect to home
      if (isAuthenticated && AppRoutes.isPremiumRoute(currentPath)) {
        final tier = ref.read(subscriptionTierProvider);
        if (tier != SubscriptionTier.max) {
          return AppRoutes.home;
        }
      }

      return null; // No redirect needed
    },
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const SplashScreen()),
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
      GoRoute(
        path: AppRoutes.emailVerification,
        name: 'emailVerification',
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const EmailVerificationScreen()),
      ),
      // Phone-verification screen cut from v1 launch (Phase 6.0,
      // 2026-04-27). It was the only English-leakage 🔴 surface in the
      // content audit and no flow routed to it. Screen file deleted;
      // route + AppRoutes.phoneVerification constant removed.

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
        pageBuilder: (context, state) {
          // Phase 9.X.D.B Task B4: ?wizard=householdOnly|extendedOnly query
          // param locks the category picker. Used by the onboarding wizard's
          // step 2/3 push.
          final wizardParam = state.uri.queryParameters['wizard'];
          final mode = switch (wizardParam) {
            'householdOnly' => WizardMode.householdOnly,
            'extendedOnly' => WizardMode.extendedOnly,
            _ => null,
          };
          return _buildPageWithTransition(
            context,
            state,
            AddRelativeScreen(wizardMode: mode),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.onboardingWizard,
        name: 'onboardingWizard',
        pageBuilder: (context, state) => _buildPageWithTransition(
            context, state, const OnboardingWizardScreen()),
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

      // Reminders Routes
      GoRoute(
        path: AppRoutes.reminders,
        name: 'reminders',
        pageBuilder: (context, state) =>
            _buildPageWithNavigation(context, state, const RemindersScreen()),
      ),
      GoRoute(
        path: AppRoutes.remindersDue,
        name: 'remindersDue',
        pageBuilder: (context, state) {
          // Parse relative IDs from query parameters if provided
          final idsParam = state.uri.queryParameters['ids'];
          final relativeIds = idsParam?.split(',').where((id) => id.isNotEmpty).toList();
          return _buildPageWithTransition(
            context,
            state,
            RemindersDueScreen(relativeIds: relativeIds),
          );
        },
      ),

      // Notification History Route
      GoRoute(
        path: AppRoutes.notificationHistory,
        name: 'notificationHistory',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const NotificationHistoryScreen(),
        ),
      ),

      // Family Tree Routes
      GoRoute(
        path: AppRoutes.familyTree,
        name: 'familyTree',
        pageBuilder: (context, state) =>
            _buildPageWithNavigation(context, state, const FamilyTreeScreen()),
      ),

      // /statistics is a legacy alias for the AI Hub — kept for deep links
      // referenced by notification handlers (notification_history, FCM, etc.).
      GoRoute(
        path: AppRoutes.statistics,
        name: 'statistics',
        pageBuilder: (context, state) =>
            _buildPageWithNavigation(context, state, const AIHubScreen()),
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
        pageBuilder: (context, state) => _buildPageWithNavigation(
          context,
          state,
          const NotificationsScreen(),
        ),
      ),

      // Wrapped Routes
      GoRoute(
        path: AppRoutes.monthlyWrapped,
        name: 'monthlyWrapped',
        pageBuilder: (context, state) {
          final monthParam = state.uri.queryParameters['month'];
          DateTime? month;
          if (monthParam != null) {
            month = DateTime.tryParse(monthParam);
          }
          return _buildPageWithTransition(
            context,
            state,
            MonthlyWrappedScreen(month: month),
          );
        },
      ),

      // Family Group Routes
      GoRoute(
        path: AppRoutes.createFamilyGroup,
        name: 'createFamilyGroup',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const CreateGroupScreen(),
        ),
      ),
      GoRoute(
        path: '${AppRoutes.familyGroupDetail}/:id',
        name: 'familyGroupDetail',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _buildPageWithTransition(
            context,
            state,
            FamilyGroupScreen(groupId: id),
          );
        },
      ),
      GoRoute(
        path: '${AppRoutes.joinFamilyGroup}/:code',
        name: 'joinFamilyGroup',
        pageBuilder: (context, state) {
          final code = state.pathParameters['code']!;
          return _buildPageWithTransition(
            context,
            state,
            JoinGroupScreen(inviteCode: code),
          );
        },
      ),
      // Phone-invite detail route was cut from v1 launch (CTO 2026-04-26).
      // Any stale notification or deep-link to /invitation/:id falls
      // through to the catch-all and routes the user to home.

      // Short alias for deep link: silni.app/join/<code>
      GoRoute(
        path: '/join/:code',
        pageBuilder: (context, state) {
          final code = state.pathParameters['code']!;
          return _buildPageWithTransition(
            context,
            state,
            JoinGroupScreen(inviteCode: code),
          );
        },
      ),

      // AI Routes
      GoRoute(
        path: AppRoutes.aiHub,
        name: 'aiHub',
        pageBuilder: (context, state) =>
            _buildPageWithNavigation(context, state, const AIHubScreen()),
      ),
      GoRoute(
        path: AppRoutes.aiChat,
        name: 'aiChat',
        pageBuilder: (context, state) {
          final relativeId = state.uri.queryParameters['relativeId'];
          return _buildPageWithTransition(
            context,
            state,
            AIChatScreen(relativeId: relativeId),
          );
        },
      ),
      // Communication Scripts Route
      GoRoute(
        path: AppRoutes.aiScripts,
        name: 'aiScripts',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const CommunicationScriptsScreen(),
        ),
      ),
      // Weekly Report Route
      GoRoute(
        path: AppRoutes.aiReport,
        name: 'aiReport',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const WeeklyReportScreen(),
        ),
      ),

      // Occasion Messages Route
      GoRoute(
        path: AppRoutes.occasionMessages,
        name: 'occasionMessages',
        pageBuilder: (context, state) {
          final occasionKey =
              state.uri.queryParameters['occasion'] ?? 'eid_al_fitr';
          final occasion = OccasionType.values.firstWhere(
            (o) => o.key == occasionKey,
            orElse: () => OccasionType.eidAlFitr,
          );
          return _buildPageWithTransition(
            context,
            state,
            OccasionMessagesScreen(occasion: occasion),
          );
        },
      ),
    ],
  );
});

// =============================================================================
// Phase 9.X.D.B Track B3 — setupComplete redirect helpers
// =============================================================================
//
// The router redirect callback is synchronous; checking
// users.onboarding_metadata->>'setupComplete' requires a DB round-trip.
// We mirror the value into SharedPreferences (`setup_complete` bool) on
// every signin via main.dart's auth listener, so the router can read
// synchronously here.
//
// Cached value semantics:
//   • absent / false → wizard hasn't been finished → redirect to /onboarding-wizard
//   • true → wizard done OR pre-existing user (Phase 9.X.D.A6 backfill set
//     this for all 28 users that existed at backfill time)
//
// To avoid an async fetch in the redirect, we keep the value in a
// process-local cache (`_cachedSetupComplete`) that's hydrated once at
// app boot from SharedPreferences and updated by the auth listener +
// the wizard's finish callback.

bool? _cachedSetupComplete;

/// Synchronous read of the cached setupComplete flag. Returns null if
/// hydration hasn't completed yet — caller should treat null as "don't
/// block" (let the user proceed to home; the wizard route will catch
/// them on next router pass once the cache settles).
bool? cachedSetupComplete() => _cachedSetupComplete;

/// Hydrate the cache from SharedPreferences. Called from main.dart at
/// boot AND from the auth listener after a signin DB-roundtrip writes
/// the prefs key.
Future<void> hydrateSetupCompleteCache() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    _cachedSetupComplete = prefs.getBool('setup_complete');
  } catch (_) {
    _cachedSetupComplete = null;
  }
}

/// Update the cache directly (e.g. when the wizard finishes — saves the
/// extra round-trip through SharedPreferences before the next redirect).
void setCachedSetupComplete(bool value) {
  _cachedSetupComplete = value;
}

bool _setupNotComplete(Ref ref) {
  // Treat null (uninitialized cache) as "not blocking" — let user reach /home
  // and the auth listener / wizard finish will hydrate on next nav. Only
  // false is a hard "show the wizard" signal.
  return _cachedSetupComplete == false;
}

String _setupCompletePathForAuthed(Ref ref) {
  return _setupNotComplete(ref) ? AppRoutes.onboardingWizard : AppRoutes.home;
}

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
class _NavigationWrapper extends ConsumerStatefulWidget {
  const _NavigationWrapper({required this.child});

  final Widget child;

  @override
  ConsumerState<_NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends ConsumerState<_NavigationWrapper> {
  final GlobalKey _childKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);

    // Enable stream recovery when connectivity changes
    ref.watch(streamRecoveryProvider);

    // Enable real-time subscriptions when authenticated
    // This ensures subscriptions are always active for logged-in users
    ref.watch(autoRealtimeSubscriptionsProvider);

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        // For now, we'll use a simpler approach with a global key
        // The auto-hide functionality will be implemented directly in the navigation wrapper
        return false; // Don't consume notification
      },
      child: GradientBackground(
        animated: true,
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  AnimatedOfflineBanner(
                    isOffline: !isOnline,
                    onTap: () => ref.read(connectivityServiceProvider).refresh(),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: KeyedSubtree(
                            key: _childKey, child: widget.child),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Navigation bar at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: PersistentBottomNav(
                  onNavTapped: (route) {
                    context.push(route);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
