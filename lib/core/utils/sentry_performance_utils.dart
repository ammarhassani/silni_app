import 'dart:async';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Extension methods for enhanced Sentry performance tracking
extension SentrySpanExtensions on ISentrySpan {
  /// Add database operation context
  void addDatabaseContext({
    required String table,
    required String operation,
    int? rowCount,
  }) {
    setData('db.table', table);
    setData('db.operation', operation);
    if (rowCount != null) setData('db.row_count', rowCount);
  }

  /// Add API call context
  void addApiContext({
    required String endpoint,
    required String method,
    int? statusCode,
  }) {
    setData('http.url', endpoint);
    setData('http.method', method);
    if (statusCode != null) setData('http.status_code', statusCode);
  }

  /// Add user flow context
  void addUserFlowContext({
    required String flowName,
    required String step,
    int? stepNumber,
  }) {
    setData('flow.name', flowName);
    setData('flow.step', step);
    if (stepNumber != null) setData('flow.step_number', stepNumber);
  }

  /// Add screen context
  void addScreenContext({
    required String screenName,
    String? previousScreen,
    Map<String, dynamic>? parameters,
  }) {
    setData('screen.name', screenName);
    if (previousScreen != null) setData('screen.previous', previousScreen);
    if (parameters != null) setData('screen.parameters', parameters);
  }
}

/// Helper class for Sentry transaction management
class SentryTransactionHelper {
  static ISentrySpan? _currentTransaction;

  /// Start a user flow transaction
  static ISentrySpan startUserFlow(String flowName) {
    _currentTransaction = Sentry.startTransaction(
      flowName,
      'user_flow',
      bindToScope: true,
    );
    return _currentTransaction!;
  }

  /// Get current transaction
  static ISentrySpan? get currentTransaction => _currentTransaction;

  /// Check if there's an active transaction
  static bool get hasActiveTransaction => _currentTransaction != null;

  /// Add a child span to current transaction
  static ISentrySpan? addSpan(String operation, String description) {
    return _currentTransaction?.startChild(operation, description: description);
  }

  /// Finish current transaction
  static Future<void> finishUserFlow({SpanStatus? status}) async {
    if (status != null) {
      _currentTransaction?.status = status;
    }
    await _currentTransaction?.finish();
    _currentTransaction = null;
  }

  /// Execute operation within a span (returns null-safe)
  static Future<T> withSpan<T>(
    String operation,
    String description,
    Future<T> Function(ISentrySpan? span) action,
  ) async {
    final span = addSpan(operation, description);

    try {
      final result = await action(span);
      span?.status = const SpanStatus.ok();
      return result;
    } catch (e) {
      span?.status = const SpanStatus.internalError();
      span?.throwable = e;
      rethrow;
    } finally {
      await span?.finish();
    }
  }

  /// Execute a synchronous operation within a span
  static T withSpanSync<T>(
    String operation,
    String description,
    T Function(ISentrySpan? span) action,
  ) {
    final span = addSpan(operation, description);

    try {
      final result = action(span);
      span?.status = const SpanStatus.ok();
      return result;
    } catch (e) {
      span?.status = const SpanStatus.internalError();
      span?.throwable = e;
      rethrow;
    } finally {
      span?.finish();
    }
  }

  /// Track a database operation
  static Future<T> trackDatabaseOperation<T>(
    String table,
    String operation,
    Future<T> Function() action,
  ) async {
    return withSpan(
      'db.$operation',
      '$operation on $table',
      (span) async {
        span?.addDatabaseContext(table: table, operation: operation);
        return action();
      },
    );
  }

  /// Track an API call
  static Future<T> trackApiCall<T>(
    String endpoint,
    String method,
    Future<T> Function() action,
  ) async {
    return withSpan(
      'http.$method',
      '$method $endpoint',
      (span) async {
        span?.addApiContext(endpoint: endpoint, method: method);
        return action();
      },
    );
  }
}
