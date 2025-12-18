import 'dart:async';
import 'dart:io';

import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/app_errors.dart';
import 'app_logger_service.dart';
import 'performance_monitoring_service.dart';

/// Centralized error handling service
class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();
  factory ErrorHandlerService() => _instance;
  ErrorHandlerService._internal();

  final AppLoggerService _logger = AppLoggerService();

  /// Categorize and wrap any error into an AppError
  AppError categorize(dynamic error, [StackTrace? stackTrace]) {
    // Already an AppError
    if (error is AppError) return error;

    // Socket/Network errors
    if (error is SocketException) {
      return NetworkError(
        message: error.message,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Timeout errors
    if (error is TimeoutException) {
      return TimeoutError(
        message: error.message ?? 'Request timed out',
        originalError: error,
        stackTrace: stackTrace,
        timeout: error.duration,
      );
    }

    // Supabase Auth errors
    if (error is AuthException) {
      return _categorizeAuthError(error, stackTrace);
    }

    // Supabase PostgrestException (database errors)
    if (error is PostgrestException) {
      return _categorizePostgrestError(error, stackTrace);
    }

    // Generic Exception - check message for known patterns
    final message = error.toString().toLowerCase();

    // Check for network-related errors (including ClientException wrapping SocketException)
    if (message.contains('socketexception') ||
        message.contains('clientexception') ||
        message.contains('network') ||
        message.contains('connection') ||
        message.contains('unreachable') ||
        message.contains('no route to host') ||
        message.contains('failed host lookup') ||
        message.contains('no address associated') ||
        message.contains('host not found')) {
      return NetworkError(
        message: error.toString(),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Check for timeout-related messages
    if (message.contains('timeout') || message.contains('timed out')) {
      return TimeoutError(
        message: error.toString(),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Unknown error
    return UnknownError(
      message: error?.toString() ?? 'Unknown error',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Categorize Supabase AuthException
  AuthError _categorizeAuthError(AuthException error, StackTrace? stackTrace) {
    final message = error.message.toLowerCase();

    AuthErrorType type;
    String? arabicMessage;

    if (message.contains('invalid login credentials') ||
        message.contains('invalid email or password')) {
      type = AuthErrorType.invalidCredentials;
    } else if (message.contains('email not confirmed')) {
      type = AuthErrorType.emailNotConfirmed;
    } else if (message.contains('user already registered') ||
        message.contains('email already exists')) {
      type = AuthErrorType.emailAlreadyExists;
    } else if (message.contains('user not found')) {
      type = AuthErrorType.userNotFound;
    } else if (message.contains('password') &&
        (message.contains('short') || message.contains('weak'))) {
      type = AuthErrorType.weakPassword;
    } else if (message.contains('refresh_token_not_found') ||
        message.contains('invalid_grant') ||
        message.contains('token is expired') ||
        message.contains('session expired')) {
      type = AuthErrorType.sessionExpired;
    } else if (message.contains('rate limit') ||
        message.contains('too many requests')) {
      type = AuthErrorType.rateLimited;
    } else {
      type = AuthErrorType.unknown;
    }

    return AuthError(
      type: type,
      message: error.message,
      arabicMessage: arabicMessage,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Categorize Supabase PostgrestException
  DatabaseError _categorizePostgrestError(
    PostgrestException error,
    StackTrace? stackTrace,
  ) {
    String? arabicMessage;

    // Check for specific error codes
    if (error.code == '23505') {
      // Unique constraint violation
      arabicMessage = 'هذا العنصر موجود بالفعل';
    } else if (error.code == '23503') {
      // Foreign key violation
      arabicMessage = 'لا يمكن حذف هذا العنصر لوجود بيانات مرتبطة به';
    } else if (error.code == '42501') {
      // Insufficient privilege
      arabicMessage = 'ليس لديك صلاحية للقيام بهذه العملية';
    } else if (error.code?.startsWith('P') == true) {
      // PostgreSQL errors
      arabicMessage = 'خطأ في قاعدة البيانات';
    }

    return DatabaseError(
      message: error.message,
      arabicMessage: arabicMessage,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Get user-friendly Arabic message for any error
  String getArabicMessage(dynamic error) {
    final appError = categorize(error);
    return appError.userFriendlyMessage;
  }

  /// Check if an error is retryable
  bool isRetryable(dynamic error) {
    final appError = categorize(error);
    return appError.isRetryable;
  }

  /// Report error to Sentry with context and performance data
  Future<void> reportError(
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? tag,
    bool fatal = false,
  }) async {
    final appError = categorize(error, stackTrace);
    final perfService = PerformanceMonitoringService();

    // Log locally
    _logger.error(
      appError.message,
      category: _getLogCategory(appError),
      tag: tag,
      metadata: {
        'errorType': appError.runtimeType.toString(),
        'isRetryable': appError.isRetryable,
        if (context != null) ...context,
      },
      stackTrace: stackTrace,
    );

    // Report to Sentry with performance context
    await Sentry.captureException(
      appError.originalError ?? appError,
      stackTrace: stackTrace ?? appError.stackTrace,
      withScope: (scope) {
        scope.setTag('error_type', appError.runtimeType.toString());
        scope.setTag('is_retryable', appError.isRetryable.toString());
        if (tag != null) scope.setTag('tag', tag);
        if (context != null) {
          scope.setContexts('error_context', context);
        }

        // Add performance context for better debugging
        perfService.addSentryPerformanceContext(scope, tag ?? 'unknown_operation');

        if (fatal) {
          scope.level = SentryLevel.fatal;
        }
      },
    );
  }

  /// Add error breadcrumb for context tracking
  void addErrorBreadcrumb(
    String message, {
    Map<String, dynamic>? data,
    SentryLevel level = SentryLevel.error,
  }) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: 'error',
        level: level,
        data: data,
      ),
    );
  }

  /// Get the appropriate log category for an error
  LogCategory _getLogCategory(AppError error) {
    if (error is AuthError) return LogCategory.auth;
    if (error is NetworkError ||
        error is OfflineError ||
        error is TimeoutError) {
      return LogCategory.network;
    }
    if (error is DatabaseError) return LogCategory.database;
    return LogCategory.service;
  }

  /// Handle error with logging and optional reporting
  Future<AppError> handle(
    dynamic error, {
    StackTrace? stackTrace,
    String? tag,
    bool report = true,
    Map<String, dynamic>? context,
  }) async {
    final appError = categorize(error, stackTrace);

    if (report) {
      await reportError(
        appError,
        stackTrace: stackTrace,
        context: context,
        tag: tag,
      );
    } else {
      // Just log locally
      _logger.error(
        appError.message,
        category: _getLogCategory(appError),
        tag: tag,
        metadata: context,
        stackTrace: stackTrace,
      );
    }

    return appError;
  }
}

/// Global error handler instance
final errorHandler = ErrorHandlerService();
