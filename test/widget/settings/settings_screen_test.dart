import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:silni_app/features/settings/screens/settings_screen.dart';
import 'package:silni_app/features/auth/providers/auth_provider.dart';
import 'package:silni_app/core/router/app_routes.dart';

import '../../helpers/test_helpers.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  group('SettingsScreen Widget Tests', () {
    late GoRouter router;

    setUp(() {
      router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Profile Screen')),
            ),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Notifications Screen')),
            ),
          ),
          GoRoute(
            path: AppRoutes.login,
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Login Screen')),
            ),
          ),
        ],
      );
    });

    tearDown(() {
      router.dispose();
    });

    Widget createTestWidget() {
      final mockUser = createTestUser(id: 'test-user-id');

      return ProviderScope(
        overrides: [
          // Include theme overrides to avoid Supabase dependency
          ...defaultThemeOverrides,
          currentUserProvider.overrideWithValue(mockUser),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget());
      // Pump frames to advance animations (can't use pumpAndSettle due to continuous animations)
      // Also need to pump enough time for GyroscopeService timer (2 seconds)
      await tester.pump(const Duration(seconds: 3));
    }

    Future<void> pumpAfterAction(WidgetTester tester) async {
      // Pump multiple frames to let validation errors appear
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('should render settings header', (tester) async {
      await pumpScreen(tester);

      expect(find.text('الإعدادات'), findsOneWidget);
    });

    testWidgets('should render theme section', (tester) async {
      await pumpScreen(tester);

      expect(find.text('المظهر'), findsOneWidget);
      expect(find.text('اختر المظهر المفضل لديك'), findsOneWidget);
      expect(find.byIcon(Icons.palette), findsWidgets);
    });

    testWidgets('should render theme grid with all themes', (tester) async {
      await pumpScreen(tester);

      // Check for GridView
      expect(find.byType(GridView), findsOneWidget);

      // Check for theme names (from AppThemeType)
      expect(find.text('صِلني'), findsOneWidget);
    });

    testWidgets('should render profile option', (tester) async {
      await pumpScreen(tester);

      expect(find.text('الملف الشخصي'), findsOneWidget);
      // Icons.person appears in profile option and potentially in user badge
      expect(find.byIcon(Icons.person), findsWidgets);
    });

    testWidgets('should render notifications option', (tester) async {
      await pumpScreen(tester);

      expect(find.text('الإشعارات'), findsOneWidget);
      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });

    testWidgets('should render logout option', (tester) async {
      await pumpScreen(tester);

      expect(find.text('تسجيل الخروج'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('should navigate to profile when profile option is tapped', (tester) async {
      await pumpScreen(tester);

      final profileOption = find.text('الملف الشخصي');
      await tester.tap(profileOption);
      await pumpAfterAction(tester);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Profile Screen'), findsOneWidget);
    });

    testWidgets('should navigate to notifications when notifications option is tapped', (tester) async {
      await pumpScreen(tester);

      final notificationsOption = find.text('الإشعارات');
      await tester.tap(notificationsOption);
      await pumpAfterAction(tester);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Notifications Screen'), findsOneWidget);
    });

    testWidgets('should have scrollable settings list', (tester) async {
      await pumpScreen(tester);

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should show selected theme with indicator', (tester) async {
      await pumpScreen(tester);

      // Each theme card has a 'مُختار' (Selected) text widget (visibility controlled by AnimatedOpacity)
      // The mock provides 2 themes, so there are 2 Text widgets in the tree (one visible, one hidden)
      expect(find.text('مُختار'), findsNWidgets(2));
    });

    testWidgets('should render navigation arrows for options', (tester) async {
      await pumpScreen(tester);

      // Profile, Notifications, and Change Password options have forward arrows
      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsNWidgets(3));
    });
  });
}
