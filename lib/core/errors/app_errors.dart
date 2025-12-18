import 'dart:async';
import 'dart:io';

/// Base class for all application errors
abstract class AppError implements Exception {
  final String message;
  final String? arabicMessage;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppError({
    required this.message,
    this.arabicMessage,
    this.originalError,
    this.stackTrace,
  });

  /// Whether this error can be retried
  bool get isRetryable;

  /// User-friendly message (Arabic by default)
  String get userFriendlyMessage => arabicMessage ?? message;

  @override
  String toString() => 'AppError: $message';
}

/// Network connectivity errors (no internet, DNS issues)
class NetworkError extends AppError {
  const NetworkError({
    super.message = 'Network connection error',
    super.arabicMessage = 'خطأ في الاتصال بالإنترنت',
    super.originalError,
    super.stackTrace,
  });

  @override
  bool get isRetryable => true;

  @override
  String toString() => 'NetworkError: $message';
}

/// Device is offline
class OfflineError extends AppError {
  const OfflineError({
    super.message = 'No internet connection',
    super.arabicMessage = 'لا يوجد اتصال بالإنترنت',
    super.originalError,
    super.stackTrace,
  });

  @override
  bool get isRetryable => true;

  @override
  String toString() => 'OfflineError: $message';
}

/// Request timeout errors
class TimeoutError extends AppError {
  final Duration? timeout;

  const TimeoutError({
    super.message = 'Request timed out',
    super.arabicMessage = 'انتهت مهلة الاتصال، يرجى المحاولة مرة أخرى',
    super.originalError,
    super.stackTrace,
    this.timeout,
  });

  @override
  bool get isRetryable => true;

  @override
  String toString() => 'TimeoutError: $message (timeout: $timeout)';
}

/// Authentication errors (invalid credentials, expired session)
class AuthError extends AppError {
  final AuthErrorType type;

  const AuthError({
    required this.type,
    super.message = 'Authentication error',
    super.arabicMessage,
    super.originalError,
    super.stackTrace,
  });

  @override
  bool get isRetryable => type == AuthErrorType.sessionExpired;

  @override
  String get userFriendlyMessage =>
      arabicMessage ?? _getDefaultArabicMessage(type);

  static String _getDefaultArabicMessage(AuthErrorType type) {
    switch (type) {
      case AuthErrorType.invalidCredentials:
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      case AuthErrorType.emailNotConfirmed:
        return 'يرجى تأكيد بريدك الإلكتروني';
      case AuthErrorType.userNotFound:
        return 'لا يوجد حساب بهذا البريد الإلكتروني';
      case AuthErrorType.emailAlreadyExists:
        return 'البريد الإلكتروني مستخدم بالفعل';
      case AuthErrorType.weakPassword:
        return 'كلمة المرور ضعيفة جداً (يجب أن تكون 6 أحرف على الأقل)';
      case AuthErrorType.sessionExpired:
        return 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى';
      case AuthErrorType.rateLimited:
        return 'تم إجراء الكثير من المحاولات. يرجى المحاولة لاحقاً';
      case AuthErrorType.unknown:
        return 'خطأ في المصادقة، يرجى المحاولة مرة أخرى';
    }
  }

  @override
  String toString() => 'AuthError(${type.name}): $message';
}

enum AuthErrorType {
  invalidCredentials,
  emailNotConfirmed,
  userNotFound,
  emailAlreadyExists,
  weakPassword,
  sessionExpired,
  rateLimited,
  unknown,
}

/// Database/Supabase query errors
class DatabaseError extends AppError {
  final String? table;
  final String? operation;

  const DatabaseError({
    super.message = 'Database error',
    super.arabicMessage = 'خطأ في تحميل البيانات',
    super.originalError,
    super.stackTrace,
    this.table,
    this.operation,
  });

  @override
  bool get isRetryable => true;

  @override
  String toString() => 'DatabaseError: $message (table: $table, op: $operation)';
}

/// Input validation errors
class ValidationError extends AppError {
  final String? field;
  final List<String>? validationErrors;

  const ValidationError({
    super.message = 'Validation error',
    super.arabicMessage = 'بيانات غير صحيحة',
    super.originalError,
    super.stackTrace,
    this.field,
    this.validationErrors,
  });

  @override
  bool get isRetryable => false;

  @override
  String toString() => 'ValidationError: $message (field: $field)';
}

/// Server-side errors (5xx responses)
class ServerError extends AppError {
  final int? statusCode;

  const ServerError({
    super.message = 'Server error',
    super.arabicMessage = 'خطأ في الخادم، يرجى المحاولة لاحقاً',
    super.originalError,
    super.stackTrace,
    this.statusCode,
  });

  @override
  bool get isRetryable => true;

  @override
  String toString() => 'ServerError($statusCode): $message';
}

/// Storage errors (secure storage, SharedPreferences)
class StorageError extends AppError {
  const StorageError({
    super.message = 'Storage error',
    super.arabicMessage = 'خطأ في التخزين المحلي',
    super.originalError,
    super.stackTrace,
  });

  @override
  bool get isRetryable => false;

  @override
  String toString() => 'StorageError: $message';
}

/// Permission errors (contacts, notifications, etc.)
class PermissionError extends AppError {
  final String? permission;

  const PermissionError({
    super.message = 'Permission denied',
    super.arabicMessage = 'تم رفض الإذن المطلوب',
    super.originalError,
    super.stackTrace,
    this.permission,
  });

  @override
  bool get isRetryable => false;

  @override
  String toString() => 'PermissionError: $message (permission: $permission)';
}

/// Unknown/unhandled errors
class UnknownError extends AppError {
  const UnknownError({
    super.message = 'An unexpected error occurred',
    super.arabicMessage = 'حدث خطأ غير متوقع',
    super.originalError,
    super.stackTrace,
  });

  @override
  bool get isRetryable => false;

  @override
  String toString() => 'UnknownError: $message';
}

/// Extension to check error types
extension AppErrorChecks on AppError {
  bool get isNetworkRelated =>
      this is NetworkError || this is OfflineError || this is TimeoutError;

  bool get isAuthRelated => this is AuthError;

  bool get requiresReauth =>
      this is AuthError &&
      (this as AuthError).type == AuthErrorType.sessionExpired;
}

/// Extension to convert standard exceptions to AppError
extension ExceptionToAppError on Exception {
  AppError toAppError([StackTrace? stackTrace]) {
    if (this is AppError) return this as AppError;

    if (this is SocketException) {
      return NetworkError(
        message: toString(),
        originalError: this,
        stackTrace: stackTrace,
      );
    }

    if (this is TimeoutException) {
      return TimeoutError(
        message: toString(),
        originalError: this,
        stackTrace: stackTrace,
        timeout: (this as TimeoutException).duration,
      );
    }

    return UnknownError(
      message: toString(),
      originalError: this,
      stackTrace: stackTrace,
    );
  }
}
