import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'app_logger_service.dart';
import 'performance_monitoring_service.dart';

/// Service for monitoring app health metrics
class AppHealthService {
  static final AppHealthService _instance = AppHealthService._internal();
  factory AppHealthService() => _instance;
  AppHealthService._internal();

  final AppLoggerService _logger = AppLoggerService();
  final PerformanceMonitoringService _perfService =
      PerformanceMonitoringService();

  // Frame timing tracking
  final List<FrameTiming> _recentFrames = [];
  static const int _maxStoredFrames = 120; // ~2 seconds at 60fps

  // Jank detection thresholds
  static const Duration _slowFrameThreshold =
      Duration(milliseconds: 16); // >60fps
  static const Duration _frozenFrameThreshold = Duration(milliseconds: 700);

  // Health metrics
  int _slowFrameCount = 0;
  int _frozenFrameCount = 0;
  int _totalFrameCount = 0;

  bool _isMonitoring = false;

  // Stream controller for health updates
  final _healthStreamController =
      StreamController<AppHealthMetrics>.broadcast();

  /// Stream of health metric updates
  Stream<AppHealthMetrics> get healthStream => _healthStreamController.stream;

  /// Check if monitoring is active
  bool get isMonitoring => _isMonitoring;

  /// Start health monitoring
  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;

    // Add frame callback for timing
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);

    _logger.info(
      'App health monitoring started',
      category: LogCategory.service,
      tag: 'AppHealth',
    );
  }

  /// Stop health monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;
    _isMonitoring = false;

    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);

    _logger.info(
      'App health monitoring stopped',
      category: LogCategory.service,
      tag: 'AppHealth',
    );
  }

  /// Frame timings callback
  void _onFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      _totalFrameCount++;
      _recentFrames.add(timing);

      // Check for slow frames
      final totalDuration = timing.totalSpan;
      if (totalDuration > _frozenFrameThreshold) {
        _frozenFrameCount++;
        _logger.warning(
          'Frozen frame detected',
          category: LogCategory.ui,
          tag: 'AppHealth',
          metadata: {
            'duration_ms': totalDuration.inMilliseconds,
            'build_ms': timing.buildDuration.inMilliseconds,
            'raster_ms': timing.rasterDuration.inMilliseconds,
          },
        );
      } else if (totalDuration > _slowFrameThreshold) {
        _slowFrameCount++;
      }

      // Rotate storage
      if (_recentFrames.length > _maxStoredFrames) {
        _recentFrames.removeAt(0);
      }
    }

    // Emit health update periodically (every 60 frames = ~1 second)
    if (_totalFrameCount % 60 == 0 && !_healthStreamController.isClosed) {
      _healthStreamController.add(getHealthMetrics());
    }
  }

  /// Get current health metrics
  AppHealthMetrics getHealthMetrics() {
    final averageFrameTime = _recentFrames.isEmpty
        ? Duration.zero
        : Duration(
            microseconds: _recentFrames
                    .map((f) => f.totalSpan.inMicroseconds)
                    .reduce((a, b) => a + b) ~/
                _recentFrames.length,
          );

    final averageBuildTime = _recentFrames.isEmpty
        ? Duration.zero
        : Duration(
            microseconds: _recentFrames
                    .map((f) => f.buildDuration.inMicroseconds)
                    .reduce((a, b) => a + b) ~/
                _recentFrames.length,
          );

    final averageRasterTime = _recentFrames.isEmpty
        ? Duration.zero
        : Duration(
            microseconds: _recentFrames
                    .map((f) => f.rasterDuration.inMicroseconds)
                    .reduce((a, b) => a + b) ~/
                _recentFrames.length,
          );

    return AppHealthMetrics(
      totalFrames: _totalFrameCount,
      slowFrames: _slowFrameCount,
      frozenFrames: _frozenFrameCount,
      averageFrameTime: averageFrameTime,
      averageBuildTime: averageBuildTime,
      averageRasterTime: averageRasterTime,
      jankPercentage: _totalFrameCount > 0
          ? (_slowFrameCount + _frozenFrameCount) / _totalFrameCount * 100
          : 0,
      estimatedFps: averageFrameTime.inMicroseconds > 0
          ? (1000000 / averageFrameTime.inMicroseconds).clamp(0, 120)
          : 60,
    );
  }

  /// Report health to performance monitoring
  Future<void> reportHealthSnapshot() async {
    final metrics = getHealthMetrics();

    final traceId = await _perfService.startTrace('health_snapshot',
        attributes: {
          'slow_frames': metrics.slowFrames.toString(),
          'frozen_frames': metrics.frozenFrames.toString(),
          'jank_percentage': metrics.jankPercentage.toStringAsFixed(2),
          'estimated_fps': metrics.estimatedFps.toStringAsFixed(1),
        });

    await _perfService.stopTrace(traceId);

    _logger.info(
      'Health snapshot reported',
      category: LogCategory.service,
      tag: 'AppHealth',
      metadata: metrics.toMap(),
    );
  }

  /// Reset metrics
  void resetMetrics() {
    _slowFrameCount = 0;
    _frozenFrameCount = 0;
    _totalFrameCount = 0;
    _recentFrames.clear();
  }

  void dispose() {
    stopMonitoring();
    _healthStreamController.close();
  }
}

/// App health metrics data class
class AppHealthMetrics {
  final int totalFrames;
  final int slowFrames;
  final int frozenFrames;
  final Duration averageFrameTime;
  final Duration averageBuildTime;
  final Duration averageRasterTime;
  final double jankPercentage;
  final double estimatedFps;

  AppHealthMetrics({
    required this.totalFrames,
    required this.slowFrames,
    required this.frozenFrames,
    required this.averageFrameTime,
    required this.averageBuildTime,
    required this.averageRasterTime,
    required this.jankPercentage,
    required this.estimatedFps,
  });

  Map<String, dynamic> toMap() => {
        'total_frames': totalFrames,
        'slow_frames': slowFrames,
        'frozen_frames': frozenFrames,
        'average_frame_time_ms': averageFrameTime.inMilliseconds,
        'average_build_time_ms': averageBuildTime.inMilliseconds,
        'average_raster_time_ms': averageRasterTime.inMilliseconds,
        'jank_percentage': jankPercentage,
        'estimated_fps': estimatedFps,
      };

  /// Check if the app is performing healthily
  bool get isHealthy => jankPercentage < 5.0 && estimatedFps >= 55;

  /// Get a health status string
  String get healthStatus {
    if (jankPercentage < 1.0 && estimatedFps >= 58) return 'excellent';
    if (jankPercentage < 5.0 && estimatedFps >= 55) return 'good';
    if (jankPercentage < 10.0 && estimatedFps >= 45) return 'fair';
    return 'poor';
  }
}
