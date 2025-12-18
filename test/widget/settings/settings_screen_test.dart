import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:silni_app/features/settings/screens/settings_screen.dart';
import 'package:silni_app/features/auth/providers/auth_provider.dart';
import 'package:silni_app/core/router/app_routes.dart';

import '../../helpers/test_helpers.dart';

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
          currentUserProvider.overrideWithValue(mockUser),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 400));
    }

    Future<void> pumpAfterAction(WidgetTester tester) async {
      await tester.pump(const Duration(milliseconds: 100));
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
      expect(find.byIcon(Icons.person), findsOneWidget);
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

    testWidgets('should show selected theme with checkmark', (tester) async {
      await pumpScreen(tester);

      // The selected theme should have a check_circle icon
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should render navigation arrows for options', (tester) async {
      await pumpScreen(tester);

      // Profile and Notifications options should have forward arrows
      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsNWidgets(2));
    });
  });
}
