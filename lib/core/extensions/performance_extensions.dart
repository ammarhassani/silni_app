import '../services/performance_monitoring_service.dart';

/// Extension for measuring Future operations
extension PerformanceFutureExtension<T> on Future<T> {
  /// Measure this future's execution time
  Future<T> withPerformanceTrace(
    String operationName, {
    Map<String, String>? attributes,
  }) async {
    final perfService = PerformanceMonitoringService();
    return perfService.measureAsync(
      operationName,
      () => this,
      attributes: attributes,
    );
  }
}

/// Extension for measuring Stream operations
extension PerformanceStreamExtension<T> on Stream<T> {
  /// Measure time to first emission
  Stream<T> withFirstEmitTrace(String operationName) async* {
    final perfService = PerformanceMonitoringService();
    final traceId = await perfService.startTrace(
      '${operationName}_first_emit',
      attributes: {'type': 'stream_first_emit'},
    );

    bool first = true;
    await for (final value in this) {
      if (first) {
        await perfService.stopTrace(traceId);
        first = false;
      }
      yield value;
    }

    // If stream completed without emitting, stop trace anyway
    if (first) {
      await perfService.stopTrace(traceId, metrics: {'empty_stream': 1});
    }
  }

  /// Measure all emissions with count
  Stream<T> withEmissionTrace(String operationName) async* {
    final perfService = PerformanceMonitoringService();
    final traceId = await perfService.startTrace(
      operationName,
      attributes: {'type': 'stream_emissions'},
    );

    int count = 0;
    try {
      await for (final value in this) {
        count++;
        yield value;
      }
    } finally {
      await perfService.stopTrace(traceId, metrics: {'emission_count': count});
    }
  }
}

/// Extension for measuring iterable operations
extension PerformanceIterableExtension<T> on Iterable<T> {
  /// Measure iteration time
  List<T> withIterationTrace(String operationName) {
    final perfService = PerformanceMonitoringService();
    return perfService.measureSync(
      operationName,
      () => toList(),
      attributes: {
        'type': 'iteration',
        'count': length.toString(),
      },
    );
  }
}

/// Helper class for manual performance measurement
class PerformanceTrace {
  final PerformanceMonitoringService _perfService =
      PerformanceMonitoringService();
  String? _traceId;
  final String name;
  final Map<String, String>? attributes;
  final Stopwatch _stopwatch = Stopwatch();

  PerformanceTrace(this.name, {this.attributes});

  /// Start the trace
  Future<void> start() async {
    _traceId = await _perfService.startTrace(name, attributes: attributes);
    _stopwatch.start();
  }

  /// Stop the trace with optional metrics
  Future<void> stop({Map<String, int>? metrics}) async {
    _stopwatch.stop();
    final allMetrics = {
      'duration_ms': _stopwatch.elapsedMilliseconds,
      ...?metrics,
    };
    await _perfService.stopTrace(_traceId, metrics: allMetrics);
  }

  /// Get elapsed time without stopping
  Duration get elapsed => _stopwatch.elapsed;

  /// Execute an operation with this trace
  static Future<T> measure<T>(
    String name,
    Future<T> Function() operation, {
    Map<String, String>? attributes,
  }) async {
    final trace = PerformanceTrace(name, attributes: attributes);
    await trace.start();
    try {
      return await operation();
    } finally {
      await trace.stop();
    }
  }

  /// Execute a sync operation with this trace
  static T measureSync<T>(
    String name,
    T Function() operation, {
    Map<String, String>? attributes,
  }) {
    final perfService = PerformanceMonitoringService();
    return perfService.measureSync(name, operation, attributes: attributes);
  }
}
