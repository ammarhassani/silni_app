import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:silni_app/features/auth/screens/login_screen.dart';
import 'package:silni_app/core/router/app_routes.dart';

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
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets('should render all login screen elements', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Use pump() instead of pumpAndSettle() due to animations

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

      // Verify signup link
      expect(find.text('ليس لديك حساب؟'), findsOneWidget);
      expect(find.text('سجّل الآن'), findsOneWidget);
    });

    testWidgets('should show validation error for empty email', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Find and tap login button without entering credentials
      final loginButton = find.text('تسجيل الدخول');
      await tester.tap(loginButton);
      await tester.pump();

      // Expect email validation error
      expect(find.text('الرجاء إدخال البريد الإلكتروني'), findsOneWidget);
    });

    testWidgets('should show validation error for invalid email format', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Find email field and enter invalid email
      final emailFields = find.byType(TextFormField);
      await tester.enterText(emailFields.first, 'invalidemail');

      // Tap login button
      final loginButton = find.text('تسجيل الدخول');
      await tester.tap(loginButton);
      await tester.pump();

      // Expect email format validation error
      expect(find.text('البريد الإلكتروني غير صحيح'), findsOneWidget);
    });

    testWidgets('should show validation error for empty password', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Enter valid email but no password
      final emailFields = find.byType(TextFormField);
      await tester.enterText(emailFields.first, 'test@example.com');

      // Tap login button
      final loginButton = find.text('تسجيل الدخول');
      await tester.tap(loginButton);
      await tester.pump();

      // Expect password validation error
      expect(find.text('الرجاء إدخال كلمة المرور'), findsOneWidget);
    });

    testWidgets('should show validation error for short password', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Enter valid email and short password
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'test@example.com');
      await tester.enterText(textFields.last, '12345'); // Less than 6 chars

      // Tap login button
      final loginButton = find.text('تسجيل الدخول');
      await tester.tap(loginButton);
      await tester.pump();

      // Expect password length validation error
      expect(find.text('كلمة المرور يجب أن تكون 6 أحرف على الأقل'), findsOneWidget);
    });

    testWidgets('should toggle password visibility', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Password should be obscured by default - verify visibility icon is shown
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

      // Find and tap visibility toggle button
      final visibilityButton = find.byIcon(Icons.visibility_outlined);
      await tester.tap(visibilityButton);
      await tester.pump();

      // Icon should change to visibility_off (password is now visible)
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);

      // Tap again to hide password
      final visibilityOffButton = find.byIcon(Icons.visibility_off_outlined);
      await tester.tap(visibilityOffButton);
      await tester.pump();

      // Icon should change back to visibility
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
    });

    testWidgets('should navigate to signup screen when signup link is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Find and tap signup link
      final signupLink = find.text('سجّل الآن');
      expect(signupLink, findsOneWidget);

      await tester.tap(signupLink);
      await tester.pump();

      // Verify navigation to signup screen
      expect(find.text('Signup Screen'), findsOneWidget);
    });

    testWidgets('should show forgot password dialog when forgot password is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Find and tap forgot password button
      final forgotPasswordButton = find.text('نسيت كلمة المرور؟');
      await tester.tap(forgotPasswordButton);
      await tester.pump();

      // Verify dialog is shown
      expect(find.text('إعادة تعيين كلمة المرور'), findsOneWidget);
      expect(find.text('سنرسل لك رابط لإعادة تعيين كلمة المرور'), findsOneWidget);

      // Verify dialog buttons
      expect(find.text('إلغاء'), findsOneWidget);
      expect(find.text('إرسال'), findsOneWidget);
    });

    testWidgets('should close forgot password dialog when cancel is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Open forgot password dialog
      final forgotPasswordButton = find.text('نسيت كلمة المرور؟');
      await tester.tap(forgotPasswordButton);
      await tester.pump();

      // Tap cancel button
      final cancelButton = find.text('إلغاء');
      await tester.tap(cancelButton);
      await tester.pump();

      // Verify dialog is closed
      expect(find.text('إعادة تعيين كلمة المرور'), findsNothing);
    });

    testWidgets('should show validation error in forgot password dialog for empty email', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Open forgot password dialog
      final forgotPasswordButton = find.text('نسيت كلمة المرور؟');
      await tester.tap(forgotPasswordButton);
      await tester.pump();

      // Tap send button without entering email
      final sendButton = find.text('إرسال');
      await tester.tap(sendButton);
      await tester.pump();

      // Verify validation error
      expect(find.text('يرجى إدخال البريد الإلكتروني'), findsOneWidget);
    });

    testWidgets('should show validation error in forgot password dialog for invalid email', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Open forgot password dialog
      final forgotPasswordButton = find.text('نسيت كلمة المرور؟');
      await tester.tap(forgotPasswordButton);
      await tester.pump();

      // Enter invalid email
      final dialogEmailField = find.byType(TextFormField).last;
      await tester.enterText(dialogEmailField, 'invalidemail');

      // Tap send button
      final sendButton = find.text('إرسال');
      await tester.tap(sendButton);
      await tester.pump();

      // Verify validation error
      expect(find.text('يرجى إدخال بريد إلكتروني صحيح'), findsOneWidget);
    });

    testWidgets('should accept valid email and password input', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Enter valid credentials
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'test@example.com');
      await tester.enterText(textFields.last, 'password123');
      await tester.pump();

      // Tap login button - should not show validation errors
      final loginButton = find.text('تسجيل الدخول');
      await tester.tap(loginButton);
      await tester.pump();

      // Verify no validation errors are shown
      expect(find.text('الرجاء إدخال البريد الإلكتروني'), findsNothing);
      expect(find.text('البريد الإلكتروني غير صحيح'), findsNothing);
      expect(find.text('الرجاء إدخال كلمة المرور'), findsNothing);
      expect(find.text('كلمة المرور يجب أن تكون 6 أحرف على الأقل'), findsNothing);
    });
  });
}
