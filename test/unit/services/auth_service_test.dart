import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:silni_app/shared/services/auth_service.dart';

/// Unit tests for AuthService
///
/// NOTE: These tests currently verify the error message translation logic
/// and demonstrate the test structure for auth operations.
///
/// LIMITATION: AuthService uses SupabaseConfig.client (singleton), which
/// makes it difficult to mock without dependency injection. For full test
/// coverage, consider:
/// 1. Refactoring AuthService to accept SupabaseClient via constructor
/// 2. Using integration tests with a test Supabase instance
/// 3. Using a service locator pattern (e.g., GetIt) for dependency injection

// Mock classes for demonstration
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockAuthResponse extends Mock implements AuthResponse {}

class MockUser extends Mock implements User {}

void main() {
  group('AuthService', () {
    group('getErrorMessage', () {
      test('should return Arabic message for invalid credentials', () {
        // Act
        final message =
            AuthService.getErrorMessage('Invalid login credentials');

        // Assert
        expect(message, 'البريد الإلكتروني أو كلمة المرور غير صحيحة');
      });

      test(
          'should return Arabic message for invalid email or password variant',
          () {
        // Act
        final message =
            AuthService.getErrorMessage('Invalid email or password');

        // Assert
        expect(message, 'البريد الإلكتروني أو كلمة المرور غير صحيحة');
      });

      test('should return Arabic message for email not confirmed', () {
        // Act
        final message = AuthService.getErrorMessage('Email not confirmed');

        // Assert
        expect(message, 'يرجى تأكيد بريدك الإلكتروني');
      });

      test('should return Arabic message for user already registered', () {
        // Act
        final message1 = AuthService.getErrorMessage('User already registered');
        final message2 = AuthService.getErrorMessage('Email already exists');

        // Assert
        expect(message1, 'البريد الإلكتروني مستخدم بالفعل');
        expect(message2, 'البريد الإلكتروني مستخدم بالفعل');
      });

      test('should return Arabic message for invalid email', () {
        // Act
        final message = AuthService.getErrorMessage('Invalid email');

        // Assert
        expect(message, 'البريد الإلكتروني غير صحيح');
      });

      test('should return Arabic message for weak password', () {
        // Act
        final message1 = AuthService.getErrorMessage('Password is too short');
        final message2 = AuthService.getErrorMessage('Password is weak');

        // Assert
        expect(message1, 'كلمة المرور ضعيفة جداً (يجب أن تكون 6 أحرف على الأقل)');
        expect(message2, 'كلمة المرور ضعيفة جداً (يجب أن تكون 6 أحرف على الأقل)');
      });

      test('should return Arabic message for user not found', () {
        // Act
        final message = AuthService.getErrorMessage('User not found');

        // Assert
        expect(message, 'لا يوجد حساب بهذا البريد الإلكتروني');
      });

      test('should return Arabic message for rate limit exceeded', () {
        // Act
        final message1 =
            AuthService.getErrorMessage('Email rate limit exceeded');
        final message2 = AuthService.getErrorMessage('Too many requests');

        // Assert
        expect(message1, 'تم إجراء الكثير من المحاولات. يرجى المحاولة لاحقاً');
        expect(message2, 'تم إجراء الكثير من المحاولات. يرجى المحاولة لاحقاً');
      });

      test('should return Arabic message for network errors', () {
        // Act
        final message1 = AuthService.getErrorMessage('Network error');
        final message2 = AuthService.getErrorMessage('Connection failed');

        // Assert
        expect(message1, 'خطأ في الاتصال بالإنترنت');
        expect(message2, 'خطأ في الاتصال بالإنترنت');
      });

      test('should return generic Arabic message for unknown errors', () {
        // Act
        final message = AuthService.getErrorMessage('Unknown error occurred');

        // Assert
        expect(message, 'حدث خطأ ما. يرجى المحاولة مرة أخرى');
      });

      test('should handle case-insensitive error messages', () {
        // Act
        final message1 = AuthService.getErrorMessage('INVALID EMAIL');
        final message2 = AuthService.getErrorMessage('invalid email');
        final message3 = AuthService.getErrorMessage('InVaLiD EmAiL');

        // Assert
        expect(message1, 'البريد الإلكتروني غير صحيح');
        expect(message2, 'البريد الإلكتروني غير صحيح');
        expect(message3, 'البريد الإلكتروني غير صحيح');
      });

      test('should handle multiple keywords in error message', () {
        // Act
        final message = AuthService.getErrorMessage(
            'Password validation failed: password is too short');

        // Assert - Should match "password" + "short" pattern
        expect(message, 'كلمة المرور ضعيفة جداً (يجب أن تكون 6 أحرف على الأقل)');
      });

      test('should prioritize specific patterns over generic ones', () {
        // Act - "invalid" alone should not match "invalid credentials"
        final message1 = AuthService.getErrorMessage('Invalid credentials');
        final message2 = AuthService.getErrorMessage('Invalid input');

        // Assert
        expect(message1, 'حدث خطأ ما. يرجى المحاولة مرة أخرى');
        expect(message2, 'حدث خطأ ما. يرجى المحاولة مرة أخرى');
      });
    });

    group('Mock-based tests (demonstration)', () {
      // These tests demonstrate how to structure tests for auth operations
      // when dependency injection is added to AuthService

      late MockSupabaseClient mockSupabaseClient;
      late MockGoTrueClient mockAuthClient;

      setUp(() {
        mockSupabaseClient = MockSupabaseClient();
        mockAuthClient = MockGoTrueClient();

        when(() => mockSupabaseClient.auth).thenReturn(mockAuthClient);
      });

      group('signUpWithEmail (structure demo)', () {
        test('demonstrates testing successful sign up', () async {
          // Arrange
          const email = 'test@example.com';
          const password = 'password123';
          const fullName = 'Test User';

          final mockUser = MockUser();
          final mockAuthResponse = MockAuthResponse();

          when(() => mockUser.id).thenReturn('test-user-id');
          when(() => mockUser.email).thenReturn(email);
          when(() => mockAuthResponse.user).thenReturn(mockUser);

          when(() => mockAuthClient.signUp(
                email: email,
                password: password,
                data: {'full_name': fullName},
              )).thenAnswer((_) async => mockAuthResponse);

          // Act
          final response = await mockAuthClient.signUp(
            email: email,
            password: password,
            data: {'full_name': fullName},
          );

          // Assert
          expect(response.user, isNotNull);
          expect(response.user!.id, 'test-user-id');
          expect(response.user!.email, email);
          verify(() => mockAuthClient.signUp(
                email: email,
                password: password,
                data: {'full_name': fullName},
              )).called(1);
        });

        test('demonstrates testing email already exists error', () async {
          // Arrange
          const email = 'existing@example.com';
          const password = 'password123';
          const fullName = 'Test User';

          when(() => mockAuthClient.signUp(
                email: email,
                password: password,
                data: {'full_name': fullName},
              )).thenThrow(
            AuthException('User already registered'),
          );

          // Act & Assert
          expect(
            () => mockAuthClient.signUp(
              email: email,
              password: password,
              data: {'full_name': fullName},
            ),
            throwsA(isA<AuthException>()),
          );
        });

        test('demonstrates testing null user response', () async {
          // Arrange
          const email = 'test@example.com';
          const password = 'password123';
          const fullName = 'Test User';

          final mockAuthResponse = MockAuthResponse();
          when(() => mockAuthResponse.user).thenReturn(null);

          when(() => mockAuthClient.signUp(
                email: email,
                password: password,
                data: {'full_name': fullName},
              )).thenAnswer((_) async => mockAuthResponse);

          // Act
          final response = await mockAuthClient.signUp(
            email: email,
            password: password,
            data: {'full_name': fullName},
          );

          // Assert
          expect(response.user, isNull);

          // In actual implementation, AuthService should throw
          // Exception('Sign up failed - no user returned')
        });
      });

      group('signInWithEmail (structure demo)', () {
        test('demonstrates testing successful sign in', () async {
          // Arrange
          const email = 'test@example.com';
          const password = 'password123';

          final mockUser = MockUser();
          final mockAuthResponse = MockAuthResponse();

          when(() => mockUser.id).thenReturn('test-user-id');
          when(() => mockUser.email).thenReturn(email);
          when(() => mockAuthResponse.user).thenReturn(mockUser);

          when(() => mockAuthClient.signInWithPassword(
                email: email,
                password: password,
              )).thenAnswer((_) async => mockAuthResponse);

          // Act
          final response = await mockAuthClient.signInWithPassword(
            email: email,
            password: password,
          );

          // Assert
          expect(response.user, isNotNull);
          expect(response.user!.id, 'test-user-id');
          verify(() => mockAuthClient.signInWithPassword(
                email: email,
                password: password,
              )).called(1);
        });

        test('demonstrates testing invalid credentials error', () async {
          // Arrange
          const email = 'test@example.com';
          const password = 'wrongpassword';

          when(() => mockAuthClient.signInWithPassword(
                email: email,
                password: password,
              )).thenThrow(
            AuthException('Invalid login credentials'),
          );

          // Act & Assert
          expect(
            () => mockAuthClient.signInWithPassword(
              email: email,
              password: password,
            ),
            throwsA(isA<AuthException>()),
          );
        });
      });

      group('signOut (structure demo)', () {
        test('demonstrates testing successful sign out', () async {
          // Arrange
          when(() => mockAuthClient.signOut()).thenAnswer((_) async {});

          // Act
          await mockAuthClient.signOut();

          // Assert
          verify(() => mockAuthClient.signOut()).called(1);
        });

        test('demonstrates testing sign out error', () async {
          // Arrange
          when(() => mockAuthClient.signOut()).thenThrow(
            Exception('Sign out failed'),
          );

          // Act & Assert
          expect(
            () => mockAuthClient.signOut(),
            throwsException,
          );
        });
      });

      group('resetPassword (structure demo)', () {
        test('demonstrates testing successful password reset', () async {
          // Arrange
          const email = 'test@example.com';

          when(() => mockAuthClient.resetPasswordForEmail(email))
              .thenAnswer((_) async {});

          // Act
          await mockAuthClient.resetPasswordForEmail(email);

          // Assert
          verify(() => mockAuthClient.resetPasswordForEmail(email)).called(1);
        });

        test('demonstrates testing invalid email error', () async {
          // Arrange
          const email = 'invalid-email';

          when(() => mockAuthClient.resetPasswordForEmail(email)).thenThrow(
            AuthException('Invalid email'),
          );

          // Act & Assert
          expect(
            () => mockAuthClient.resetPasswordForEmail(email),
            throwsA(isA<AuthException>()),
          );
        });
      });
    });
  });
}
