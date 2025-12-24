import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'analytics_service.dart';
import 'app_logger_service.dart';

/// Pre-defined trace names for critical performance paths
class PerformanceTraces {
  PerformanceTraces._();

  // App Lifecycle
  static const appLaunch = 'app_launch';
  static const appColdStart = 'app_cold_start';
  static const appWarmStart = 'app_warm_start';
  static const firstMeaningfulPaint = 'first_meaningful_paint';
  static const timeToInteractive = 'time_to_interactive';

  // Screen Loads
  static const homeScreenLoad = 'home_screen_load';
  static const relativesListLoad = 'relatives_list_load';
  static const relativeDetailLoad = 'relative_detail_load';
  static const remindersScreenLoad = 'reminders_screen_load';
  static const aiChatScreenLoad = 'ai_chat_screen_load';
  static const familyTreeLoad = 'family_tree_load';

  // Data Operations
  static const relativesDataFetch = 'relatives_data_fetch';
  static const interactionsDataFetch = 'interactions_data_fetch';
  static const remindersDataFetch = 'reminders_data_fetch';
  static const userDataSync = 'user_data_sync';

  // AI Operations
  static const aiResponseTime = 'ai_response_time';
  static const aiStreamingStart = 'ai_streaming_start';
  static const aiFullResponse = 'ai_full_response';
  static const aiPreload = 'ai_preload';

  // Cache Operations
  static const cacheRead = 'cache_read';
  static const cacheWrite = 'cache_write';
  static const cacheSync = 'cache_sync';
}

/// Slow load thresholds in milliseconds
class PerformanceThresholds {
  PerformanceThresholds._();

  static const int screenLoad = 500; // 500ms for screen loads
  static const int dataFetch = 1000; // 1s for data fetches
  static const int aiResponse = 3000; // 3s for AI responses
  static const int cacheOperation = 100; // 100ms for cache ops
  static const int coldStart = 2000; // 2s for cold start
}

/// Centralized performance monitoring service
/// Integrates Firebase Performance and Sentry for comprehensive metrics
class PerformanceMonitoringService {
  static final PerformanceMonitoringService _instance =
      PerformanceMonitoringService._internal();
  factory PerformanceMonitoringService() => _instance;
  PerformanceMonitoringService._internal();

  final AppLoggerService _logger = AppLoggerService();
  final AnalyticsService _analytics = AnalyticsService();
  late final FirebasePerformance _firebasePerformance;

  bool _isInitialized = false;
  bool _isEnabled = true;

  // Active traces map for management
  final Map<String, Trace> _activeTraces = {};
  final Map<String, HttpMetric> _activeHttpMetrics = {};
  final Map<String, ISentrySpan> _activeSentrySpans = {};

  // Metrics storage for debugging
  final List<PerformanceMetric> _recentMetrics = [];
  static const int _maxStoredMetrics = 100;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Check if monitoring is enabled
  bool get isEnabled => _isEnabled;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _firebasePerformance = FirebasePerformance.instance;

      // Enable/disable based on build mode and configuration
      _isEnabled = !kDebugMode ||
          const bool.fromEnvironment('ENABLE_PERFORMANCE_MONITORING',
              defaultValue: true);

      await _firebasePerformance.setPerformanceCollectionEnabled(_isEnabled);

      _isInitialized = true;
      _logger.info(
        'Performance monitoring initialized',
        category: LogCategory.service,
        tag: 'Performance',
        metadata: {'enabled': _isEnabled},
      );
    } catch (e, stack) {
      _logger.error(
        'Failed to initialize performance monitoring',
        category: LogCategory.service,
        tag: 'Performance',
        metadata: {'error': e.toString()},
        stackTrace: stack,
      );
    }
  }

  /// Enable or disable performance collection
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    if (_isInitialized) {
      await _firebasePerformance.setPerformanceCollectionEnabled(enabled);
    }
  }

  // =====================================================
  // CUSTOM TRACES - For measuring specific operations
  // =====================================================

  /// Start a custom trace
  Future<String?> startTrace(String name,
      {Map<String, String>? attributes}) async {
    if (!_isEnabled || !_isInitialized) return null;

    try {
      final traceId = '${name}_${DateTime.now().millisecondsSinceEpoch}';
      final trace = _firebasePerformance.newTrace(name);

      // Add attributes
      attributes?.forEach((key, value) {
        trace.putAttribute(key, value);
      });

      await trace.start();
      _activeTraces[traceId] = trace;

      // Also start Sentry span for correlation
      final transaction = Sentry.startTransaction(name, 'custom_trace');
      _activeSentrySpans[traceId] = transaction;

      _logger.debug(
        'Started trace: $name',
        category: LogCategory.service,
        tag: 'Performance',
      );

      return traceId;
    } catch (e) {
      _logger.warning(
        'Failed to start trace: $name',
        category: LogCategory.service,
        tag: 'Performance',
        metadata: {'error': e.toString()},
      );
      return null;
    }
  }

  /// Stop a custom trace
  Future<void> stopTrace(String? traceId, {Map<String, int>? metrics}) async {
    if (traceId == null || !_activeTraces.containsKey(traceId)) return;

    try {
      final trace = _activeTraces.remove(traceId);

      // Add metrics before stopping
      metrics?.forEach((key, value) {
        trace?.setMetric(key, value);
      });

      await trace?.stop();

      // Stop Sentry span
      final span = _activeSentrySpans.remove(traceId);
      await span?.finish();

      _logger.debug(
        'Stopped trace: $traceId',
        category: LogCategory.service,
        tag: 'Performance',
      );
    } catch (e) {
      _logger.warning(
        'Failed to stop trace: $traceId',
        category: LogCategory.service,
        tag: 'Performance',
        metadata: {'error': e.toString()},
      );
    }
  }

  /// Measure a synchronous operation
  T measureSync<T>(
    String name,
    T Function() operation, {
    Map<String, String>? attributes,
  }) {
    final stopwatch = Stopwatch()..start();

    try {
      final result = operation();
      stopwatch.stop();
      _recordMetric(name, stopwatch.elapsedMilliseconds);

      // Fire-and-forget trace recording
      _recordTraceAsync(name, stopwatch.elapsedMilliseconds, attributes, false);

      return result;
    } catch (e) {
      stopwatch.stop();
      _recordMetric(name, stopwatch.elapsedMilliseconds, hasError: true);
      _recordTraceAsync(name, stopwatch.elapsedMilliseconds, attributes, true);
      rethrow;
    }
  }

  /// Helper to record trace asynchronously
  Future<void> _recordTraceAsync(String name, int durationMs,
      Map<String, String>? attributes, bool hasError) async {
    final traceId = await startTrace(name, attributes: attributes);
    await stopTrace(traceId, metrics: {
      'duration_ms': durationMs,
      if (hasError) 'error': 1,
    });
  }

  /// Measure an asynchronous operation
  Future<T> measureAsync<T>(
    String name,
    Future<T> Function() operation, {
    Map<String, String>? attributes,
  }) async {
    final traceId = await startTrace(name, attributes: attributes);
    final stopwatch = Stopwatch()..start();

    try {
      final result = await operation();
      stopwatch.stop();
      await stopTrace(traceId,
          metrics: {'duration_ms': stopwatch.elapsedMilliseconds});
      _recordMetric(name, stopwatch.elapsedMilliseconds);
      return result;
    } catch (e) {
      stopwatch.stop();
      await stopTrace(traceId, metrics: {
        'duration_ms': stopwatch.elapsedMilliseconds,
        'error': 1,
      });
      _recordMetric(name, stopwatch.elapsedMilliseconds, hasError: true);
      rethrow;
    }
  }

  // =====================================================
  // HTTP METRICS - For API call monitoring
  // =====================================================

  /// Start tracking an HTTP request
  Future<String?> startHttpMetric(
    String url,
    HttpMethod method, {
    int? requestPayloadSize,
  }) async {
    if (!_isEnabled || !_isInitialized) return null;

    try {
      final metricId = '${url}_${DateTime.now().millisecondsSinceEpoch}';
      final metric = _firebasePerformance.newHttpMetric(url, method);

      if (requestPayloadSize != null) {
        metric.requestPayloadSize = requestPayloadSize;
      }

      await metric.start();
      _activeHttpMetrics[metricId] = metric;

      return metricId;
    } catch (e) {
      _logger.warning(
        'Failed to start HTTP metric',
        category: LogCategory.network,
        tag: 'Performance',
        metadata: {'url': url, 'error': e.toString()},
      );
      return null;
    }
  }

  /// Stop tracking an HTTP request
  Future<void> stopHttpMetric(
    String? metricId, {
    int? responseCode,
    int? responsePayloadSize,
    String? responseContentType,
  }) async {
    if (metricId == null || !_activeHttpMetrics.containsKey(metricId)) return;

    try {
      final metric = _activeHttpMetrics.remove(metricId);

      if (responseCode != null) metric?.httpResponseCode = responseCode;
      if (responsePayloadSize != null) {
        metric?.responsePayloadSize = responsePayloadSize;
      }
      if (responseContentType != null) {
        metric?.responseContentType = responseContentType;
      }

      await metric?.stop();
    } catch (e) {
      _logger.warning(
        'Failed to stop HTTP metric',
        category: LogCategory.network,
        tag: 'Performance',
        metadata: {'metricId': metricId, 'error': e.toString()},
      );
    }
  }

  // =====================================================
  // SCREEN RENDERING TRACES
  // =====================================================

  /// Start a screen rendering trace
  Future<String?> startScreenTrace(String screenName) async {
    return startTrace('screen_$screenName', attributes: {
      'screen_name': screenName,
      'trace_type': 'screen_render',
    });
  }

  /// Stop a screen rendering trace with frame metrics
  Future<void> stopScreenTrace(
    String? traceId, {
    int? frameCount,
    int? slowFrames,
    int? frozenFrames,
  }) async {
    final metrics = <String, int>{};
    if (frameCount != null) metrics['frame_count'] = frameCount;
    if (slowFrames != null) metrics['slow_frames'] = slowFrames;
    if (frozenFrames != null) metrics['frozen_frames'] = frozenFrames;

    await stopTrace(traceId, metrics: metrics);
  }

  // =====================================================
  // DATABASE OPERATION TRACES
  // =====================================================

  /// Measure a database operation
  Future<T> measureDatabaseOperation<T>(
    String operation,
    String table,
    Future<T> Function() dbOperation,
  ) async {
    return measureAsync(
      'db_${operation}_$table',
      dbOperation,
      attributes: {
        'operation': operation,
        'table': table,
        'trace_type': 'database',
      },
    );
  }

  // =====================================================
  // SENTRY INTEGRATION
  // =====================================================

  /// Create a Sentry span for detailed tracing
  ISentrySpan? startSentrySpan(
    String operation,
    String description, {
    ISentrySpan? parent,
  }) {
    try {
      if (parent != null) {
        return parent.startChild(operation, description: description);
      }
      return Sentry.startTransaction(operation, description);
    } catch (e) {
      _logger.warning(
        'Failed to start Sentry span',
        category: LogCategory.service,
        tag: 'Performance',
        metadata: {'operation': operation, 'error': e.toString()},
      );
      return null;
    }
  }

  /// Add performance context to Sentry scope
  void addSentryPerformanceContext(Scope scope, String operationName) {
    scope.setContexts('performance', {
      'operation': operationName,
      'recent_metrics': _recentMetrics.take(10).map((m) => m.toMap()).toList(),
    });
  }

  // =====================================================
  // METRICS STORAGE & RETRIEVAL
  // =====================================================

  void _recordMetric(String name, int durationMs, {bool hasError = false}) {
    _recentMetrics.add(PerformanceMetric(
      name: name,
      durationMs: durationMs,
      timestamp: DateTime.now(),
      hasError: hasError,
    ));

    // Rotate if too many
    if (_recentMetrics.length > _maxStoredMetrics) {
      _recentMetrics.removeAt(0);
    }
  }

  /// Get recent performance metrics
  List<PerformanceMetric> getRecentMetrics({String? filter}) {
    if (filter == null) return List.from(_recentMetrics);
    return _recentMetrics.where((m) => m.name.contains(filter)).toList();
  }

  /// Get average duration for an operation
  double? getAverageDuration(String operationName) {
    final matching = _recentMetrics.where((m) => m.name == operationName);
    if (matching.isEmpty) return null;
    return matching.map((m) => m.durationMs).reduce((a, b) => a + b) /
        matching.length;
  }

  /// Get performance summary for an operation
  PerformanceSummary? getPerformanceSummary(String operationName) {
    final matching =
        _recentMetrics.where((m) => m.name == operationName).toList();
    if (matching.isEmpty) return null;

    final durations = matching.map((m) => m.durationMs).toList()..sort();
    final errorCount = matching.where((m) => m.hasError).length;

    return PerformanceSummary(
      operationName: operationName,
      sampleCount: matching.length,
      averageMs: durations.reduce((a, b) => a + b) / durations.length,
      minMs: durations.first,
      maxMs: durations.last,
      medianMs: durations[durations.length ~/ 2],
      errorRate: errorCount / matching.length,
    );
  }

  /// Clear all stored metrics
  void clearMetrics() {
    _recentMetrics.clear();
  }

  /// Cleanup active traces
  Future<void> dispose() async {
    for (final trace in _activeTraces.values) {
      await trace.stop();
    }
    _activeTraces.clear();

    for (final metric in _activeHttpMetrics.values) {
      await metric.stop();
    }
    _activeHttpMetrics.clear();

    for (final span in _activeSentrySpans.values) {
      await span.finish();
    }
    _activeSentrySpans.clear();
  }

  // =====================================================
  // CRITICAL PATH MONITORING WITH ANALYTICS
  // =====================================================

  /// Measure a screen load and report slow loads to analytics
  Future<T> measureScreenLoad<T>(
    String screenName,
    Future<T> Function() operation, {
    int? itemCount,
  }) async {
    final stopwatch = Stopwatch()..start();
    final traceId = await startScreenTrace(screenName);

    try {
      final result = await operation();
      stopwatch.stop();

      final duration = stopwatch.elapsedMilliseconds;
      await stopScreenTrace(traceId);
      _recordMetric('screen_$screenName', duration);

      // Report slow loads to analytics
      if (duration > PerformanceThresholds.screenLoad) {
        await _analytics.logSlowLoad(
          screenName: screenName,
          loadTimeMs: duration,
          itemCount: itemCount,
        );
        _logger.warning(
          'Slow screen load: $screenName took ${duration}ms',
          category: LogCategory.service,
          tag: 'Performance',
        );
      }

      return result;
    } catch (e) {
      stopwatch.stop();
      await stopScreenTrace(traceId);
      _recordMetric('screen_$screenName', stopwatch.elapsedMilliseconds,
          hasError: true);
      rethrow;
    }
  }

  /// Measure AI response time with analytics reporting
  Future<T> measureAIResponse<T>(
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    final traceId = await startTrace(PerformanceTraces.aiResponseTime);

    try {
      final result = await operation();
      stopwatch.stop();

      final duration = stopwatch.elapsedMilliseconds;
      await stopTrace(traceId, metrics: {'duration_ms': duration});
      _recordMetric(PerformanceTraces.aiResponseTime, duration);

      // Report to analytics
      await _analytics.logAIResponseReceived(responseTimeMs: duration);

      if (duration > PerformanceThresholds.aiResponse) {
        _logger.warning(
          'Slow AI response: ${duration}ms',
          category: LogCategory.service,
          tag: 'Performance',
        );
      }

      return result;
    } catch (e) {
      stopwatch.stop();
      await stopTrace(traceId, metrics: {
        'duration_ms': stopwatch.elapsedMilliseconds,
        'error': 1,
      });
      rethrow;
    }
  }

  /// Measure data fetch with threshold checking
  Future<T> measureDataFetch<T>(
    String operationName,
    Future<T> Function() operation, {
    int? itemCount,
  }) async {
    final stopwatch = Stopwatch()..start();
    final traceId = await startTrace(operationName, attributes: {
      'trace_type': 'data_fetch',
      if (itemCount != null) 'item_count': itemCount.toString(),
    });

    try {
      final result = await operation();
      stopwatch.stop();

      final duration = stopwatch.elapsedMilliseconds;
      await stopTrace(traceId, metrics: {
        'duration_ms': duration,
        if (itemCount != null) 'item_count': itemCount,
      });
      _recordMetric(operationName, duration);

      if (duration > PerformanceThresholds.dataFetch) {
        await _analytics.logSlowLoad(
          screenName: operationName,
          loadTimeMs: duration,
          itemCount: itemCount,
        );
      }

      return result;
    } catch (e) {
      stopwatch.stop();
      await stopTrace(traceId, metrics: {
        'duration_ms': stopwatch.elapsedMilliseconds,
        'error': 1,
      });
      rethrow;
    }
  }

  /// Track app cold start performance
  Future<void> trackColdStart(DateTime appStartTime) async {
    final duration = DateTime.now().difference(appStartTime).inMilliseconds;

    final traceId = await startTrace(PerformanceTraces.appColdStart);
    await stopTrace(traceId, metrics: {'duration_ms': duration});
    _recordMetric(PerformanceTraces.appColdStart, duration);

    if (duration > PerformanceThresholds.coldStart) {
      await _analytics.logSlowLoad(
        screenName: 'cold_start',
        loadTimeMs: duration,
      );
      _logger.warning(
        'Slow cold start: ${duration}ms (threshold: ${PerformanceThresholds.coldStart}ms)',
        category: LogCategory.service,
        tag: 'Performance',
      );
    }
  }

  /// Get health status of critical operations
  Map<String, bool> getCriticalPathHealth() {
    return {
      'home_screen': _isOperationHealthy(PerformanceTraces.homeScreenLoad),
      'relatives_list': _isOperationHealthy(PerformanceTraces.relativesListLoad),
      'ai_response': _isOperationHealthy(PerformanceTraces.aiResponseTime),
      'data_fetch': _isOperationHealthy(PerformanceTraces.relativesDataFetch),
    };
  }

  bool _isOperationHealthy(String operationName) {
    final summary = getPerformanceSummary(operationName);
    return summary?.isHealthy ?? true;
  }
}

/// Performance metric data class
class PerformanceMetric {
  final String name;
  final int durationMs;
  final DateTime timestamp;
  final bool hasError;

  PerformanceMetric({
    required this.name,
    required this.durationMs,
    required this.timestamp,
    this.hasError = false,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'duration_ms': durationMs,
        'timestamp': timestamp.toIso8601String(),
        'has_error': hasError,
      };
}

/// Performance summary for an operation
class PerformanceSummary {
  final String operationName;
  final int sampleCount;
  final double averageMs;
  final int minMs;
  final int maxMs;
  final int medianMs;
  final double errorRate;

  PerformanceSummary({
    required this.operationName,
    required this.sampleCount,
    required this.averageMs,
    required this.minMs,
    required this.maxMs,
    required this.medianMs,
    required this.errorRate,
  });

  Map<String, dynamic> toMap() => {
        'operation': operationName,
        'sample_count': sampleCount,
        'average_ms': averageMs,
        'min_ms': minMs,
        'max_ms': maxMs,
        'median_ms': medianMs,
        'error_rate': errorRate,
      };

  bool get isHealthy => averageMs < 1000 && errorRate < 0.1;
}
