import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/core/errors/app_errors.dart';
import 'package:silni_app/core/services/error_handler_service.dart';

void main() {
  late ErrorHandlerService errorHandler;

  setUp(() {
    errorHandler = ErrorHandlerService();
  });

  group('ErrorHandlerService - Error Categorization', () {
    test('categorizes SocketException as NetworkError', () {
      final error = const SocketException('Connection refused');
      final result = errorHandler.categorize(error);

      expect(result, isA<NetworkError>());
      expect(result.isRetryable, true);
    });

    test('categorizes TimeoutException as TimeoutError', () {
      final error = TimeoutException('Request timed out', const Duration(seconds: 30));
      final result = errorHandler.categorize(error);

      expect(result, isA<TimeoutError>());
      expect(result.isRetryable, true);
    });

    test('categorizes ClientException with SocketException as NetworkError', () {
      // Simulates the common Supabase error format
      final error = Exception('ClientException with SocketException: Failed host lookup');
      final result = errorHandler.categorize(error);

      expect(result, isA<NetworkError>());
      expect(result.isRetryable, true);
    });

    test('categorizes failed host lookup as NetworkError', () {
      final error = Exception('Failed host lookup: api.example.com');
      final result = errorHandler.categorize(error);

      expect(result, isA<NetworkError>());
      expect(result.isRetryable, true);
    });

    test('categorizes network unreachable as NetworkError', () {
      final error = Exception('Network is unreachable');
      final result = errorHandler.categorize(error);

      expect(result, isA<NetworkError>());
      expect(result.isRetryable, true);
    });

    test('categorizes connection refused as NetworkError', () {
      final error = Exception('Connection refused');
      final result = errorHandler.categorize(error);

      expect(result, isA<NetworkError>());
      expect(result.isRetryable, true);
    });

    test('categorizes timeout in message as TimeoutError', () {
      final error = Exception('Request timed out after 30 seconds');
      final result = errorHandler.categorize(error);

      expect(result, isA<TimeoutError>());
      expect(result.isRetryable, true);
    });

    test('categorizes unknown exception as UnknownError', () {
      final error = Exception('Some random error');
      final result = errorHandler.categorize(error);

      expect(result, isA<UnknownError>());
      expect(result.isRetryable, false);
    });

    test('returns AppError as-is if already categorized', () {
      const error = NetworkError(message: 'Already categorized');
      final result = errorHandler.categorize(error);

      expect(result, same(error));
    });
  });

  group('ErrorHandlerService - Arabic Messages', () {
    test('returns Arabic message for NetworkError', () {
      final error = const SocketException('Connection refused');
      final message = errorHandler.getArabicMessage(error);

      expect(message, 'خطأ في الاتصال بالإنترنت');
    });

    test('returns Arabic message for TimeoutError', () {
      final error = TimeoutException('Request timed out');
      final message = errorHandler.getArabicMessage(error);

      expect(message, 'انتهت مهلة الاتصال، يرجى المحاولة مرة أخرى');
    });

    test('returns Arabic message for OfflineError', () {
      const error = OfflineError();
      final message = errorHandler.getArabicMessage(error);

      expect(message, 'لا يوجد اتصال بالإنترنت');
    });

    test('returns Arabic message for DatabaseError', () {
      const error = DatabaseError();
      final message = errorHandler.getArabicMessage(error);

      expect(message, 'خطأ في تحميل البيانات');
    });

    test('returns Arabic message for ServerError', () {
      const error = ServerError();
      final message = errorHandler.getArabicMessage(error);

      expect(message, 'خطأ في الخادم، يرجى المحاولة لاحقاً');
    });

    test('returns Arabic message for ValidationError', () {
      const error = ValidationError();
      final message = errorHandler.getArabicMessage(error);

      expect(message, 'بيانات غير صحيحة');
    });

    test('returns Arabic message for UnknownError', () {
      final error = Exception('Something went wrong');
      final message = errorHandler.getArabicMessage(error);

      expect(message, 'حدث خطأ غير متوقع');
    });

    test('returns Arabic message for ClientException wrapper', () {
      final error = Exception('ClientException with SocketException: Failed host lookup');
      final message = errorHandler.getArabicMessage(error);

      expect(message, 'خطأ في الاتصال بالإنترنت');
    });
  });

  group('ErrorHandlerService - Retryable Check', () {
    test('NetworkError is retryable', () {
      final error = const SocketException('Connection refused');
      expect(errorHandler.isRetryable(error), true);
    });

    test('TimeoutError is retryable', () {
      final error = TimeoutException('Request timed out');
      expect(errorHandler.isRetryable(error), true);
    });

    test('OfflineError is retryable', () {
      const error = OfflineError();
      expect(errorHandler.isRetryable(error), true);
    });

    test('DatabaseError is retryable', () {
      const error = DatabaseError();
      expect(errorHandler.isRetryable(error), true);
    });

    test('ServerError is retryable', () {
      const error = ServerError();
      expect(errorHandler.isRetryable(error), true);
    });

    test('ValidationError is NOT retryable', () {
      const error = ValidationError();
      expect(errorHandler.isRetryable(error), false);
    });

    test('UnknownError is NOT retryable', () {
      final error = Exception('Something went wrong');
      expect(errorHandler.isRetryable(error), false);
    });
  });

  group('AuthError - Arabic Messages', () {
    test('invalid credentials returns correct Arabic message', () {
      const error = AuthError(
        type: AuthErrorType.invalidCredentials,
        message: 'Invalid login credentials',
      );
      expect(error.userFriendlyMessage, 'البريد الإلكتروني أو كلمة المرور غير صحيحة');
    });

    test('email not confirmed returns correct Arabic message', () {
      const error = AuthError(
        type: AuthErrorType.emailNotConfirmed,
        message: 'Email not confirmed',
      );
      expect(error.userFriendlyMessage, 'يرجى تأكيد بريدك الإلكتروني');
    });

    test('user not found returns correct Arabic message', () {
      const error = AuthError(
        type: AuthErrorType.userNotFound,
        message: 'User not found',
      );
      expect(error.userFriendlyMessage, 'لا يوجد حساب بهذا البريد الإلكتروني');
    });

    test('email already exists returns correct Arabic message', () {
      const error = AuthError(
        type: AuthErrorType.emailAlreadyExists,
        message: 'Email already exists',
      );
      expect(error.userFriendlyMessage, 'البريد الإلكتروني مستخدم بالفعل');
    });

    test('weak password returns correct Arabic message', () {
      const error = AuthError(
        type: AuthErrorType.weakPassword,
        message: 'Password is too weak',
      );
      expect(error.userFriendlyMessage, 'كلمة المرور ضعيفة جداً (يجب أن تكون 6 أحرف على الأقل)');
    });

    test('session expired returns correct Arabic message', () {
      const error = AuthError(
        type: AuthErrorType.sessionExpired,
        message: 'Session expired',
      );
      expect(error.userFriendlyMessage, 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى');
    });

    test('rate limited returns correct Arabic message', () {
      const error = AuthError(
        type: AuthErrorType.rateLimited,
        message: 'Too many requests',
      );
      expect(error.userFriendlyMessage, 'تم إجراء الكثير من المحاولات. يرجى المحاولة لاحقاً');
    });

    test('session expired is retryable', () {
      const error = AuthError(
        type: AuthErrorType.sessionExpired,
        message: 'Session expired',
      );
      expect(error.isRetryable, true);
    });

    test('invalid credentials is NOT retryable', () {
      const error = AuthError(
        type: AuthErrorType.invalidCredentials,
        message: 'Invalid credentials',
      );
      expect(error.isRetryable, false);
    });
  });

  group('AppError Extensions', () {
    test('NetworkError is network related', () {
      const error = NetworkError();
      expect(error.isNetworkRelated, true);
    });

    test('OfflineError is network related', () {
      const error = OfflineError();
      expect(error.isNetworkRelated, true);
    });

    test('TimeoutError is network related', () {
      const error = TimeoutError();
      expect(error.isNetworkRelated, true);
    });

    test('AuthError is auth related', () {
      const error = AuthError(type: AuthErrorType.invalidCredentials);
      expect(error.isAuthRelated, true);
    });

    test('session expired requires reauth', () {
      const error = AuthError(type: AuthErrorType.sessionExpired);
      expect(error.requiresReauth, true);
    });

    test('invalid credentials does NOT require reauth', () {
      const error = AuthError(type: AuthErrorType.invalidCredentials);
      expect(error.requiresReauth, false);
    });
  });
}
