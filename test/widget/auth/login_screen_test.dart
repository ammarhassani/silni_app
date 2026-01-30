import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:silni_app/features/auth/screens/login_screen.dart';
import 'package:silni_app/core/router/app_routes.dart';

import '../../helpers/widget_test_helpers.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    late GoRouter router;

    setUp(() {
      // Create a mock router for testing navigation
      router = GoRouter(
        initialLocation: AppRoutes.login,
        routes: [
          GoRoute(
            path: AppRoutes.login,
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: AppRoutes.signup,
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Signup Screen')),
            ),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Home Screen')),
            ),
          ),
        ],
      );
    });

    tearDown(() {
      router.dispose();
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          // Include theme overrides to avoid Supabase dependency
          ...defaultThemeOverrides,
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    /// Helper to pump widget and advance animations properly.
    /// Sets a larger surface size to accommodate the full form.
    Future<void> pumpScreen(WidgetTester tester) async {
      // Set a larger surface size to fit the entire login form and avoid overflow
      await tester.binding.setSurfaceSize(const Size(500, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget());
      // Pump frames to advance animations (can't use pumpAndSettle due to continuous animations)
      // Also need to pump enough time for GyroscopeService timer (2 seconds)
      await tester.pump(const Duration(seconds: 3));
    }

    /// Helper to pump after an action (tap, enterText)
    Future<void> pumpAfterAction(WidgetTester tester) async {
      // Pump multiple frames to let validation errors appear
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    /// Helper to scroll to and tap a button by text
    Future<void> scrollToAndTap(WidgetTester tester, String text) async {
      final finder = find.text(text);
      await tester.ensureVisible(finder);
      // Pump frames for scroll animation
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.tap(finder, warnIfMissed: false);
      // Pump frames for validation errors
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('should render all login screen elements', (tester) async {
      await pumpScreen(tester);

      // Verify logo container exists
      expect(find.byIcon(Icons.people_alt_rounded), findsOneWidget);

      // Verify welcome text
      expect(find.text('مرحباً بعودتك'), findsOneWidget);
      expect(find.text('سجّل الدخول للمتابعة'), findsOneWidget);

      // Verify email field
      expect(find.byType(TextFormField), findsNWidgets(2));

      // Verify email field elements
      expect(find.text('البريد الإلكتروني'), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);

      // Verify password field elements
      expect(find.text('كلمة المرور'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);

      // Verify forgot password button
      expect(find.text('نسيت كلمة المرور؟'), findsOneWidget);

      // Verify login button
      expect(find.text('تسجيل الدخول'), findsOneWidget);

      // Verify signup link (changed from 'ليس لديك حساب؟' / 'سجّل الآن')
      expect(find.text('إنشاء حساب جديد'), findsOneWidget);
    });

    testWidgets('should show validation error for empty email', (tester) async {
      await pumpScreen(tester);

      // Find and tap login button without entering credentials
      await scrollToAndTap(tester, 'تسجيل الدخول');

      // Expect email validation error
      expect(find.text('الرجاء إدخال البريد الإلكتروني'), findsOneWidget);
    });

    testWidgets('should show validation error for invalid email format', (tester) async {
      await pumpScreen(tester);

      // Find email field and enter invalid email
      final emailFields = find.byType(TextFormField);
      await tester.enterText(emailFields.first, 'invalidemail');

      // Tap login button
      await scrollToAndTap(tester, 'تسجيل الدخول');

      // Expect email format validation error
      expect(find.text('البريد الإلكتروني غير صحيح'), findsOneWidget);
    });

    testWidgets('should show validation error for empty password', (tester) async {
      await pumpScreen(tester);

      // Enter valid email but no password
      final emailFields = find.byType(TextFormField);
      await tester.enterText(emailFields.first, 'test@example.com');

      // Tap login button
      await scrollToAndTap(tester, 'تسجيل الدخول');

      // Expect password validation error
      expect(find.text('الرجاء إدخال كلمة المرور'), findsOneWidget);
    });

    testWidgets('should accept short password on login (no length validation)', (tester) async {
      await pumpScreen(tester);

      // Enter valid email and short password
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'test@example.com');
      await tester.enterText(textFields.last, '12345'); // Less than 6 chars

      // Tap login button
      await scrollToAndTap(tester, 'تسجيل الدخول');

      // Login screen intentionally doesn't validate password length
      // (old users may have shorter passwords, Supabase validates)
      // So no validation error should appear
      expect(find.text('كلمة المرور يجب أن تكون 6 أحرف على الأقل'), findsNothing);
    });

    testWidgets('should toggle password visibility', (tester) async {
      await pumpScreen(tester);

      // Password should be obscured by default - verify visibility icon is shown
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

      // Find and tap visibility toggle button
      final visibilityButton = find.byIcon(Icons.visibility_outlined);
      await tester.tap(visibilityButton);
      await pumpAfterAction(tester);

      // Icon should change to visibility_off (password is now visible)
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);

      // Tap again to hide password
      final visibilityOffButton = find.byIcon(Icons.visibility_off_outlined);
      await tester.tap(visibilityOffButton);
      await pumpAfterAction(tester);

      // Icon should change back to visibility
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
    });

    testWidgets('should navigate to signup screen when signup link is tapped', (tester) async {
      await pumpScreen(tester);

      // Find and tap signup link (now called "إنشاء حساب جديد")
      final signupLink = find.text('إنشاء حساب جديد');
      expect(signupLink, findsOneWidget);

      await tester.ensureVisible(signupLink);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(signupLink);
      await pumpAfterAction(tester);
      await tester.pump(const Duration(milliseconds: 100));

      // Verify navigation to signup screen
      expect(find.text('Signup Screen'), findsOneWidget);
    });

    testWidgets('should show forgot password dialog when forgot password is tapped', (tester) async {
      await pumpScreen(tester);

      // Find and tap forgot password button
      await scrollToAndTap(tester, 'نسيت كلمة المرور؟');

      // Verify dialog is shown
      expect(find.text('إعادة تعيين كلمة المرور'), findsOneWidget);
      expect(find.text('سنرسل لك رابط لإعادة تعيين كلمة المرور'), findsOneWidget);

      // Verify dialog buttons
      expect(find.text('إلغاء'), findsOneWidget);
      expect(find.text('إرسال'), findsOneWidget);
    });

    testWidgets('should close forgot password dialog when cancel is tapped', (tester) async {
      await pumpScreen(tester);

      // Open forgot password dialog
      await scrollToAndTap(tester, 'نسيت كلمة المرور؟');

      // Tap cancel button
      final cancelButton = find.text('إلغاء');
      await tester.tap(cancelButton);
      await pumpAfterAction(tester);

      // Verify dialog is closed
      expect(find.text('إعادة تعيين كلمة المرور'), findsNothing);
    });

    testWidgets('should show validation error in forgot password dialog for empty email', (tester) async {
      await pumpScreen(tester);

      // Open forgot password dialog
      await scrollToAndTap(tester, 'نسيت كلمة المرور؟');

      // Tap send button without entering email
      final sendButton = find.text('إرسال');
      await tester.tap(sendButton);
      await pumpAfterAction(tester);

      // Verify validation error
      expect(find.text('يرجى إدخال البريد الإلكتروني'), findsOneWidget);
    });

    testWidgets('should show validation error in forgot password dialog for invalid email', (tester) async {
      await pumpScreen(tester);

      // Open forgot password dialog
      await scrollToAndTap(tester, 'نسيت كلمة المرور؟');

      // Enter invalid email
      final dialogEmailField = find.byType(TextFormField).last;
      await tester.enterText(dialogEmailField, 'invalidemail');

      // Tap send button
      final sendButton = find.text('إرسال');
      await tester.tap(sendButton);
      await pumpAfterAction(tester);

      // Verify validation error
      expect(find.text('يرجى إدخال بريد إلكتروني صحيح'), findsOneWidget);
    });

    testWidgets('should accept valid email and password input', (tester) async {
      await pumpScreen(tester);

      // Enter valid credentials
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'test@example.com');
      await tester.enterText(textFields.last, 'password123');
      await pumpAfterAction(tester);

      // Tap login button - should not show validation errors
      await scrollToAndTap(tester, 'تسجيل الدخول');

      // Verify no validation errors are shown
      expect(find.text('الرجاء إدخال البريد الإلكتروني'), findsNothing);
      expect(find.text('البريد الإلكتروني غير صحيح'), findsNothing);
      expect(find.text('الرجاء إدخال كلمة المرور'), findsNothing);
      expect(find.text('كلمة المرور يجب أن تكون 6 أحرف على الأقل'), findsNothing);
    });
  });
}
