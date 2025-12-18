import 'dart:async';
import 'dart:math' as math;

import '../errors/app_errors.dart';
import '../services/app_logger_service.dart';

/// Helper class for retrying operations with exponential backoff
class RetryHelper {
  static final AppLoggerService _logger = AppLoggerService();

  /// Execute an operation with exponential backoff retry
  ///
  /// [operation] - The async operation to retry
  /// [maxAttempts] - Maximum number of attempts (default: 3)
  /// [initialDelay] - Initial delay before first retry (default: 500ms)
  /// [backoffMultiplier] - Multiplier for each subsequent delay (default: 2.0)
  /// [maxDelay] - Maximum delay between retries (default: 30s)
  /// [shouldRetry] - Custom function to determine if error is retryable
  /// [onRetry] - Callback invoked before each retry attempt
  static Future<T> withExponentialBackoff<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
    double backoffMultiplier = 2.0,
    Duration maxDelay = const Duration(seconds: 30),
    bool Function(Exception)? shouldRetry,
    void Function(int attempt, Duration delay, Exception error)? onRetry,
  }) async {
    int attempts = 0;
    Duration delay = initialDelay;

    while (true) {
      try {
        attempts++;
        return await operation();
      } catch (e) {
        final exception = e is Exception ? e : Exception(e.toString());

        // Check if we should retry
        final canRetry = _canRetry(exception, shouldRetry);
        final hasMoreAttempts = attempts < maxAttempts;

        if (!canRetry || !hasMoreAttempts) {
          _logger.warning(
            'Retry exhausted after $attempts attempts',
            category: LogCategory.network,
            metadata: {
              'error': e.toString(),
              'attempts': attempts,
              'canRetry': canRetry,
            },
          );
          rethrow;
        }

        // Calculate delay with jitter to avoid thundering herd
        final jitterRange = delay.inMilliseconds ~/ 4;
        final jitter = jitterRange > 0
            ? Duration(milliseconds: math.Random().nextInt(jitterRange))
            : Duration.zero;
        final actualDelay = delay + jitter;
        final clampedDelay = actualDelay > maxDelay ? maxDelay : actualDelay;

        _logger.debug(
          'Retry attempt $attempts/$maxAttempts after ${clampedDelay.inMilliseconds}ms',
          category: LogCategory.network,
          metadata: {'error': e.toString()},
        );

        // Invoke retry callback if provided
        onRetry?.call(attempts, clampedDelay, exception);

        // Wait before retrying
        await Future.delayed(clampedDelay);

        // Increase delay for next iteration
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).round(),
        );
      }
    }
  }

  /// Determine if an exception should be retried
  static bool _canRetry(Exception e, bool Function(Exception)? customCheck) {
    // Use custom check if provided
    if (customCheck != null) {
      return customCheck(e);
    }

    // Default: retry network-related errors
    if (e is AppError) {
      return e.isRetryable;
    }

    final message = e.toString().toLowerCase();
    return message.contains('timeout') ||
        message.contains('connection') ||
        message.contains('network') ||
        message.contains('socket') ||
        message.contains('unreachable');
  }

  /// Execute with simple retry (fixed delay between attempts)
  static Future<T> withFixedDelay<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 1),
    bool Function(Exception)? shouldRetry,
  }) async {
    return withExponentialBackoff(
      operation: operation,
      maxAttempts: maxAttempts,
      initialDelay: delay,
      backoffMultiplier: 1.0, // No increase
      shouldRetry: shouldRetry,
    );
  }

  /// Execute with timeout and retry
  static Future<T> withTimeoutAndRetry<T>({
    required Future<T> Function() operation,
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
    bool Function(Exception)? shouldRetry,
  }) async {
    return withExponentialBackoff(
      operation: () => operation().timeout(timeout),
      maxAttempts: maxAttempts,
      initialDelay: initialDelay,
      shouldRetry: (e) {
        // Always retry timeouts
        if (e is TimeoutException) return true;
        return shouldRetry?.call(e) ?? _canRetry(e, null);
      },
    );
  }
}

/// Extension to add retry capability to any Future
extension RetryableFuture<T> on Future<T> {
  /// Retry this future with exponential backoff
  Future<T> withRetry({
    int maxAttempts = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
    bool Function(Exception)? shouldRetry,
  }) {
    return RetryHelper.withExponentialBackoff(
      operation: () => this,
      maxAttempts: maxAttempts,
      initialDelay: initialDelay,
      shouldRetry: shouldRetry,
    );
  }

  /// Add timeout and retry
  Future<T> withTimeoutAndRetry({
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 3,
  }) {
    return RetryHelper.withTimeoutAndRetry(
      operation: () => this,
      timeout: timeout,
      maxAttempts: maxAttempts,
    );
  }
}
