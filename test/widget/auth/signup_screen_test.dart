import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:silni_app/features/auth/screens/signup_screen.dart';
import 'package:silni_app/core/router/app_routes.dart';

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
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets('should render all signup screen elements', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

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
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Tap signup button without entering any data
      final signupButton = find.text('إنشاء حساب');
      await tester.tap(signupButton);
      await tester.pump();

      // Expect name validation error
      expect(find.text('الرجاء إدخال الاسم'), findsOneWidget);
    });

    testWidgets('should show validation error for short name', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Enter name with only 1 character
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'A');

      // Tap signup button
      final signupButton = find.text('إنشاء حساب');
      await tester.tap(signupButton);
      await tester.pump();

      // Expect name length validation error
      expect(find.text('الاسم يجب أن يكون حرفين على الأقل'), findsOneWidget);
    });

    testWidgets('should show validation error for empty email', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Enter valid name but no email
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'Ahmed Ali');

      // Tap signup button
      final signupButton = find.text('إنشاء حساب');
      await tester.tap(signupButton);
      await tester.pump();

      // Expect email validation error
      expect(find.text('الرجاء إدخال البريد الإلكتروني'), findsOneWidget);
    });

    testWidgets('should show validation error for invalid email format', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Enter valid name and invalid email
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Ahmed Ali');
      await tester.enterText(textFields.at(1), 'invalidemail');

      // Tap signup button
      final signupButton = find.text('إنشاء حساب');
      await tester.tap(signupButton);
      await tester.pump();

      // Expect email format validation error
      expect(find.text('البريد الإلكتروني غير صحيح'), findsOneWidget);
    });

    testWidgets('should show validation error for empty password', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Enter name and email but no password
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Ahmed Ali');
      await tester.enterText(textFields.at(1), 'ahmed@example.com');

      // Tap signup button
      final signupButton = find.text('إنشاء حساب');
      await tester.tap(signupButton);
      await tester.pump();

      // Expect password validation error
      expect(find.text('الرجاء إدخال كلمة المرور'), findsOneWidget);
    });

    testWidgets('should show validation error for short password', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Enter name, email and short password
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Ahmed Ali');
      await tester.enterText(textFields.at(1), 'ahmed@example.com');
      await tester.enterText(textFields.at(2), '12345'); // Less than 6 chars

      // Tap signup button
      final signupButton = find.text('إنشاء حساب');
      await tester.tap(signupButton);
      await tester.pump();

      // Expect password length validation error
      expect(find.text('كلمة المرور يجب أن تكون 6 أحرف على الأقل'), findsOneWidget);
    });

    testWidgets('should show validation error for empty confirm password', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Enter name, email, password but no confirm password
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Ahmed Ali');
      await tester.enterText(textFields.at(1), 'ahmed@example.com');
      await tester.enterText(textFields.at(2), 'password123');

      // Tap signup button
      final signupButton = find.text('إنشاء حساب');
      await tester.tap(signupButton);
      await tester.pump();

      // Expect confirm password validation error
      expect(find.text('الرجاء تأكيد كلمة المرور'), findsOneWidget);
    });

    testWidgets('should show validation error for password mismatch', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Enter all fields but passwords don't match
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Ahmed Ali');
      await tester.enterText(textFields.at(1), 'ahmed@example.com');
      await tester.enterText(textFields.at(2), 'password123');
      await tester.enterText(textFields.at(3), 'differentPassword');

      // Tap signup button
      final signupButton = find.text('إنشاء حساب');
      await tester.tap(signupButton);
      await tester.pump();

      // Expect password mismatch validation error
      expect(find.text('كلمة المرور غير متطابقة'), findsOneWidget);
    });

    testWidgets('should toggle password visibility', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Password fields should be obscured by default - verify visibility icons are shown
      expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2)); // password + confirm
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

      // Find and tap first visibility toggle button (password field)
      final visibilityButtons = find.byIcon(Icons.visibility_outlined);
      await tester.tap(visibilityButtons.first);
      await tester.pump();

      // One icon should change to visibility_off
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('should toggle confirm password visibility', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Find and tap second visibility toggle button (confirm password field)
      final visibilityButtons = find.byIcon(Icons.visibility_outlined);
      await tester.tap(visibilityButtons.last);
      await tester.pump();

      // One icon should change to visibility_off
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('should navigate to login screen when login link is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Find and tap login link
      final loginLink = find.text('سجّل الدخول');
      expect(loginLink, findsOneWidget);

      await tester.tap(loginLink);
      await tester.pump();

      // Verify navigation to login screen
      expect(find.text('Login Screen'), findsOneWidget);
    });

    testWidgets('should accept valid signup data without validation errors', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Enter all valid data
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Ahmed Ali');
      await tester.enterText(textFields.at(1), 'ahmed@example.com');
      await tester.enterText(textFields.at(2), 'password123');
      await tester.enterText(textFields.at(3), 'password123');
      await tester.pump();

      // Tap signup button - should not show validation errors
      final signupButton = find.text('إنشاء حساب');
      await tester.tap(signupButton);
      await tester.pump();

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
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Test name field with valid name
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Ahmed Ali');

      // Tap signup button - should show errors for other fields
      final signupButton = find.text('إنشاء حساب');
      await tester.tap(signupButton);
      await tester.pump();

      // Name should be valid, but other fields should show errors
      expect(find.text('الرجاء إدخال الاسم'), findsNothing);
      expect(find.text('الرجاء إدخال البريد الإلكتروني'), findsOneWidget);
    });

    testWidgets('should handle Arabic name input correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Enter Arabic name
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'أحمد علي');

      // Should accept Arabic characters
      final signupButton = find.text('إنشاء حساب');
      await tester.tap(signupButton);
      await tester.pump();

      // Name validation should pass
      expect(find.text('الرجاء إدخال الاسم'), findsNothing);
      expect(find.text('الاسم يجب أن يكون حرفين على الأقل'), findsNothing);
    });
  });
}
