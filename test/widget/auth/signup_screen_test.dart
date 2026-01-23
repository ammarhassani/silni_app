import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:silni_app/features/auth/screens/signup_screen.dart';
import 'package:silni_app/core/router/app_routes.dart';

import '../../helpers/widget_test_helpers.dart';

void main() {
  group('SignUpScreen Widget Tests', () {
    late GoRouter router;

    setUp(() {
      // Create a mock router for testing navigation
      router = GoRouter(
        initialLocation: AppRoutes.signup,
        routes: [
          GoRoute(
            path: AppRoutes.login,
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Login Screen')),
            ),
          ),
          GoRoute(
            path: AppRoutes.signup,
            builder: (context, state) => const SignUpScreen(),
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
      // Set a larger surface size to fit the entire signup form (iPhone 14 Pro Max dimensions)
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget());
      // Advance animations to let them settle
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 400));
    }

    /// Helper to pump after an action (tap, enterText)
    Future<void> pumpAfterAction(WidgetTester tester) async {
      await tester.pump(const Duration(milliseconds: 100));
    }

    /// Helper to scroll to and tap a button by text
    Future<void> scrollToAndTap(WidgetTester tester, String text) async {
      final finder = find.text(text);
      await tester.ensureVisible(finder);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(finder);
      await pumpAfterAction(tester);
    }

    testWidgets('should render all signup screen elements', (tester) async {
      await pumpScreen(tester);

      // Verify logo container exists
      expect(find.byIcon(Icons.person_add_rounded), findsOneWidget);

      // Verify welcome text
      expect(find.text('انضم إلينا'), findsOneWidget);
      expect(find.text('ابدأ رحلتك في صلة الرحم'), findsOneWidget);

      // Verify all form fields (name, email, password, confirm password)
      expect(find.byType(TextFormField), findsNWidgets(4));

      // Verify field labels
      expect(find.text('الاسم الكامل'), findsOneWidget);
      expect(find.text('البريد الإلكتروني'), findsOneWidget);
      expect(find.text('كلمة المرور'), findsOneWidget);
      expect(find.text('تأكيد كلمة المرور'), findsOneWidget);

      // Verify field icons
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsNWidgets(2)); // password + confirm

      // Verify signup button
      expect(find.text('إنشاء حساب'), findsOneWidget);

      // Verify login link
      expect(find.text('لديك حساب بالفعل؟'), findsOneWidget);
      expect(find.text('سجّل الدخول'), findsOneWidget);
    });

    testWidgets('should show validation error for empty name', (tester) async {
      await pumpScreen(tester);

      // Tap signup button without entering any data
      await scrollToAndTap(tester, 'إنشاء حساب');

      // Expect name validation error
      expect(find.text('الرجاء إدخال الاسم'), findsOneWidget);
    });

    testWidgets('should show validation error for short name', (tester) async {
      await pumpScreen(tester);

      // Enter name with only 1 character
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'A');

      // Tap signup button
      await scrollToAndTap(tester, 'إنشاء حساب');

      // Expect name length validation error
      expect(find.text('الاسم يجب أن يكون حرفين على الأقل'), findsOneWidget);
    });

    testWidgets('should show validation error for empty email', (tester) async {
      await pumpScreen(tester);

      // Enter valid name but no email
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'Ahmed Ali');

      // Tap signup button
      await scrollToAndTap(tester, 'إنشاء حساب');

      // Expect email validation error
      expect(find.text('الرجاء إدخال البريد الإلكتروني'), findsOneWidget);
    });

    testWidgets('should show validation error for invalid email format', (tester) async {
      await pumpScreen(tester);

      // Enter valid name and invalid email
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Ahmed Ali');
      await tester.enterText(textFields.at(1), 'invalidemail');

      // Tap signup button
      await scrollToAndTap(tester, 'إنشاء حساب');

      // Expect email format validation error
      expect(find.text('البريد الإلكتروني غير صحيح'), findsOneWidget);
    });

    testWidgets('should show validation error for empty password', (tester) async {
      await pumpScreen(tester);

      // Enter name and email but no password
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Ahmed Ali');
      await tester.enterText(textFields.at(1), 'ahmed@example.com');

      // Tap signup button
      await scrollToAndTap(tester, 'إنشاء حساب');

      // Expect password validation error
      expect(find.text('الرجاء إدخال كلمة المرور'), findsOneWidget);
    });

    testWidgets('should show validation error for short password', (tester) async {
      await pumpScreen(tester);

      // Enter name, email and short password
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Ahmed Ali');
      await tester.enterText(textFields.at(1), 'ahmed@example.com');
      await tester.enterText(textFields.at(2), '12345'); // Less than 6 chars

      // Tap signup button
      await scrollToAndTap(tester, 'إنشاء حساب');

      // Expect password length validation error
      expect(find.text('كلمة المرور يجب أن تكون 6 أحرف على الأقل'), findsOneWidget);
    });

    testWidgets('should show validation error for empty confirm password', (tester) async {
      await pumpScreen(tester);

      // Enter name, email, password but no confirm password
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Ahmed Ali');
      await tester.enterText(textFields.at(1), 'ahmed@example.com');
      await tester.enterText(textFields.at(2), 'password123');

      // Tap signup button
      await scrollToAndTap(tester, 'إنشاء حساب');

      // Expect confirm password validation error
      expect(find.text('الرجاء تأكيد كلمة المرور'), findsOneWidget);
    });

    testWidgets('should show validation error for password mismatch', (tester) async {
      await pumpScreen(tester);

      // Enter all fields but passwords don't match
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Ahmed Ali');
      await tester.enterText(textFields.at(1), 'ahmed@example.com');
      await tester.enterText(textFields.at(2), 'password123');
      await tester.enterText(textFields.at(3), 'differentPassword');

      // Tap signup button
      await scrollToAndTap(tester, 'إنشاء حساب');

      // Expect password mismatch validation error
      expect(find.text('كلمة المرور غير متطابقة'), findsOneWidget);
    });

    testWidgets('should toggle password visibility', (tester) async {
      await pumpScreen(tester);

      // Password fields should be obscured by default - verify visibility icons are shown
      expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2)); // password + confirm
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

      // Find and tap first visibility toggle button (password field)
      final visibilityButtons = find.byIcon(Icons.visibility_outlined);
      await tester.tap(visibilityButtons.first);
      await pumpAfterAction(tester);

      // One icon should change to visibility_off
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('should toggle confirm password visibility', (tester) async {
      await pumpScreen(tester);

      // Find and tap second visibility toggle button (confirm password field)
      final visibilityButtons = find.byIcon(Icons.visibility_outlined);
      await tester.tap(visibilityButtons.last);
      await pumpAfterAction(tester);

      // One icon should change to visibility_off
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('should navigate to login screen when login link is tapped', (tester) async {
      await pumpScreen(tester);

      // Find and tap login link
      final loginLink = find.text('سجّل الدخول');
      expect(loginLink, findsOneWidget);

      await tester.ensureVisible(loginLink);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(loginLink);
      await pumpAfterAction(tester);
      await tester.pump(const Duration(milliseconds: 100));

      // Verify navigation to login screen
      expect(find.text('Login Screen'), findsOneWidget);
    });

    testWidgets('should accept valid signup data without validation errors', (tester) async {
      await pumpScreen(tester);

      // Enter all valid data
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Ahmed Ali');
      await tester.enterText(textFields.at(1), 'ahmed@example.com');
      await tester.enterText(textFields.at(2), 'password123');
      await tester.enterText(textFields.at(3), 'password123');
      await pumpAfterAction(tester);

      // Tap signup button - should not show validation errors
      await scrollToAndTap(tester, 'إنشاء حساب');

      // Verify no validation errors are shown
      expect(find.text('الرجاء إدخال الاسم'), findsNothing);
      expect(find.text('الاسم يجب أن يكون حرفين على الأقل'), findsNothing);
      expect(find.text('الرجاء إدخال البريد الإلكتروني'), findsNothing);
      expect(find.text('البريد الإلكتروني غير صحيح'), findsNothing);
      expect(find.text('الرجاء إدخال كلمة المرور'), findsNothing);
      expect(find.text('كلمة المرور يجب أن تكون 6 أحرف على الأقل'), findsNothing);
      expect(find.text('الرجاء تأكيد كلمة المرور'), findsNothing);
      expect(find.text('كلمة المرور غير متطابقة'), findsNothing);
    });

    testWidgets('should validate each field independently', (tester) async {
      await pumpScreen(tester);

      // Test name field with valid name
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Ahmed Ali');

      // Tap signup button - should show errors for other fields
      await scrollToAndTap(tester, 'إنشاء حساب');

      // Name should be valid, but other fields should show errors
      expect(find.text('الرجاء إدخال الاسم'), findsNothing);
      expect(find.text('الرجاء إدخال البريد الإلكتروني'), findsOneWidget);
    });

    testWidgets('should handle Arabic name input correctly', (tester) async {
      await pumpScreen(tester);

      // Enter Arabic name
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'أحمد علي');

      // Should accept Arabic characters
      await scrollToAndTap(tester, 'إنشاء حساب');

      // Name validation should pass
      expect(find.text('الرجاء إدخال الاسم'), findsNothing);
      expect(find.text('الاسم يجب أن يكون حرفين على الأقل'), findsNothing);
    });
  });
}
