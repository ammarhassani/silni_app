import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/core/utils/retry_helper.dart';

void main() {
  group('RetryHelper - withExponentialBackoff', () {
    test('succeeds on first attempt when operation succeeds', () async {
      int attempts = 0;

      final result = await RetryHelper.withExponentialBackoff<String>(
        operation: () async {
          attempts++;
          return 'success';
        },
        maxAttempts: 3,
        initialDelay: const Duration(milliseconds: 10),
      );

      expect(result, 'success');
      expect(attempts, 1);
    });

    test('retries on failure and succeeds on second attempt', () async {
      int attempts = 0;

      final result = await RetryHelper.withExponentialBackoff<String>(
        operation: () async {
          attempts++;
          if (attempts < 2) {
            throw const SocketException('Connection failed');
          }
          return 'success';
        },
        maxAttempts: 3,
        initialDelay: const Duration(milliseconds: 10),
      );

      expect(result, 'success');
      expect(attempts, 2);
    });

    test('retries until max attempts and throws last error', () async {
      int attempts = 0;

      await expectLater(
        RetryHelper.withExponentialBackoff<String>(
          operation: () async {
            attempts++;
            throw const SocketException('Connection failed');
          },
          maxAttempts: 3,
          initialDelay: const Duration(milliseconds: 10),
        ),
        throwsA(isA<SocketException>()),
      );

      expect(attempts, 3);
    });

    test('uses shouldRetry callback to determine retryability', () async {
      int attempts = 0;

      // Should NOT retry because shouldRetry returns false
      await expectLater(
        RetryHelper.withExponentialBackoff<String>(
          operation: () async {
            attempts++;
            throw Exception('Non-retryable error');
          },
          maxAttempts: 3,
          initialDelay: const Duration(milliseconds: 10),
          shouldRetry: (e) => e is SocketException, // Only retry SocketException
        ),
        throwsA(isA<Exception>()),
      );

      // Should only attempt once because the error is not retryable
      expect(attempts, 1);
    });

    test('retries SocketException when shouldRetry allows it', () async {
      int attempts = 0;

      await expectLater(
        RetryHelper.withExponentialBackoff<String>(
          operation: () async {
            attempts++;
            throw const SocketException('Connection failed');
          },
          maxAttempts: 3,
          initialDelay: const Duration(milliseconds: 10),
          shouldRetry: (e) => e is SocketException,
        ),
        throwsA(isA<SocketException>()),
      );

      // Should attempt all 3 times because SocketException is retryable
      expect(attempts, 3);
    });

    test('calls onRetry callback before each retry', () async {
      int attempts = 0;
      List<int> retryAttempts = [];
      List<Duration> retryDelays = [];

      await expectLater(
        RetryHelper.withExponentialBackoff<String>(
          operation: () async {
            attempts++;
            throw const SocketException('Connection failed');
          },
          maxAttempts: 3,
          initialDelay: const Duration(milliseconds: 100),
          onRetry: (attempt, delay, error) {
            retryAttempts.add(attempt);
            retryDelays.add(delay);
          },
        ),
        throwsA(isA<SocketException>()),
      );

      expect(attempts, 3);
      expect(retryAttempts, [1, 2]); // Called after failure 1 and 2 (before next attempt)
      expect(retryDelays.length, 2);
      // Check delays increase (exponential backoff)
      expect(retryDelays[1].inMilliseconds, greaterThan(retryDelays[0].inMilliseconds));
    });

    test('exponential backoff increases delay', () async {
      List<Duration> delays = [];

      await expectLater(
        RetryHelper.withExponentialBackoff<String>(
          operation: () async {
            throw const SocketException('Connection failed');
          },
          maxAttempts: 4,
          initialDelay: const Duration(milliseconds: 100),
          backoffMultiplier: 2.0,
          onRetry: (attempt, delay, error) {
            delays.add(delay);
          },
        ),
        throwsA(isA<SocketException>()),
      );

      expect(delays.length, 3); // 3 retries = 3 delays
      // Each delay should be roughly double the previous (with some jitter)
      expect(delays[1].inMilliseconds, greaterThanOrEqualTo(delays[0].inMilliseconds));
      expect(delays[2].inMilliseconds, greaterThanOrEqualTo(delays[1].inMilliseconds));
    });

    test('handles TimeoutException as retryable by default', () async {
      int attempts = 0;

      await expectLater(
        RetryHelper.withExponentialBackoff<String>(
          operation: () async {
            attempts++;
            throw TimeoutException('Request timed out');
          },
          maxAttempts: 2,
          initialDelay: const Duration(milliseconds: 10),
        ),
        throwsA(isA<TimeoutException>()),
      );

      expect(attempts, 2);
    });

    test('stops retrying when operation succeeds after failures', () async {
      int attempts = 0;

      final result = await RetryHelper.withExponentialBackoff<String>(
        operation: () async {
          attempts++;
          if (attempts < 3) {
            throw const SocketException('Connection failed');
          }
          return 'finally succeeded';
        },
        maxAttempts: 5,
        initialDelay: const Duration(milliseconds: 10),
      );

      expect(result, 'finally succeeded');
      expect(attempts, 3);
    });

    test('does not retry non-Exception errors', () async {
      int attempts = 0;

      await expectLater(
        RetryHelper.withExponentialBackoff<String>(
          operation: () async {
            attempts++;
            throw 'String error'; // Not an Exception
          },
          maxAttempts: 3,
          initialDelay: const Duration(milliseconds: 10),
        ),
        throwsA(isA<String>()),
      );

      // Should only attempt once because String is not an Exception
      expect(attempts, 1);
    });
  });

  group('RetryHelper - Edge Cases', () {
    test('handles maxAttempts of 1 (no retries)', () async {
      int attempts = 0;

      await expectLater(
        RetryHelper.withExponentialBackoff<String>(
          operation: () async {
            attempts++;
            throw const SocketException('Connection failed');
          },
          maxAttempts: 1,
          initialDelay: const Duration(milliseconds: 10),
        ),
        throwsA(isA<SocketException>()),
      );

      expect(attempts, 1);
    });

    test('works with zero initial delay', () async {
      int attempts = 0;

      final result = await RetryHelper.withExponentialBackoff<String>(
        operation: () async {
          attempts++;
          if (attempts < 2) {
            throw const SocketException('Connection failed');
          }
          return 'success';
        },
        maxAttempts: 3,
        initialDelay: Duration.zero,
      );

      expect(result, 'success');
      expect(attempts, 2);
    });

    test('returns correct type', () async {
      final intResult = await RetryHelper.withExponentialBackoff<int>(
        operation: () async => 42,
        maxAttempts: 1,
      );
      expect(intResult, 42);

      final listResult = await RetryHelper.withExponentialBackoff<List<String>>(
        operation: () async => ['a', 'b', 'c'],
        maxAttempts: 1,
      );
      expect(listResult, ['a', 'b', 'c']);

      final mapResult = await RetryHelper.withExponentialBackoff<Map<String, int>>(
        operation: () async => {'key': 123},
        maxAttempts: 1,
      );
      expect(mapResult, {'key': 123});
    });
  });
}
