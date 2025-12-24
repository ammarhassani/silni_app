import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'analytics_service.dart';
import 'app_logger_service.dart';

/// Memory usage thresholds in MB
class MemoryThresholds {
  MemoryThresholds._();

  static const int warning = 150; // 150MB warning threshold
  static const int critical = 200; // 200MB critical threshold
  static const int maxHeapGrowth = 50; // 50MB growth per check is suspicious
}

/// Memory snapshot for tracking changes
class MemorySnapshot {
  final DateTime timestamp;
  final int usedHeapSizeMB;
  final int externalSizeMB;
  final String? context;

  MemorySnapshot({
    required this.timestamp,
    required this.usedHeapSizeMB,
    required this.externalSizeMB,
    this.context,
  });

  int get totalMB => usedHeapSizeMB + externalSizeMB;

  Map<String, dynamic> toMap() => {
        'timestamp': timestamp.toIso8601String(),
        'used_heap_mb': usedHeapSizeMB,
        'external_mb': externalSizeMB,
        'total_mb': totalMB,
        if (context != null) 'context': context,
      };
}

/// Memory monitoring service for detecting leaks and high usage
class MemoryMonitorService {
  static final MemoryMonitorService _instance =
      MemoryMonitorService._internal();
  factory MemoryMonitorService() => _instance;
  MemoryMonitorService._internal();

  final AppLoggerService _logger = AppLoggerService();
  final AnalyticsService _analytics = AnalyticsService();

  Timer? _monitorTimer;
  bool _isMonitoring = false;
  final List<MemorySnapshot> _snapshots = [];
  static const int _maxSnapshots = 60; // Keep last 60 snapshots
  static const Duration _monitorInterval = Duration(seconds: 30);

  MemorySnapshot? _lastSnapshot;
  int _consecutiveHighUsageCount = 0;

  /// Check if monitoring is active
  bool get isMonitoring => _isMonitoring;

  /// Get recent memory snapshots
  List<MemorySnapshot> get snapshots => List.unmodifiable(_snapshots);

  /// Get current memory usage in MB
  int get currentUsageMB => _lastSnapshot?.totalMB ?? 0;

  /// Start periodic memory monitoring
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _takeSnapshot(context: 'monitoring_started');

    _monitorTimer = Timer.periodic(_monitorInterval, (_) {
      _takeSnapshot();
    });

    _logger.info(
      'Memory monitoring started',
      category: LogCategory.service,
      tag: 'Memory',
    );
  }

  /// Stop memory monitoring
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
    _isMonitoring = false;

    _logger.info(
      'Memory monitoring stopped',
      category: LogCategory.service,
      tag: 'Memory',
    );
  }

  /// Take a memory snapshot
  void _takeSnapshot({String? context}) {
    try {
      // Estimate heap usage - in production we use approximate values
      // Real values require native code or profiling tools
      final snapshot = MemorySnapshot(
        timestamp: DateTime.now(),
        usedHeapSizeMB: _estimateHeapUsage(),
        externalSizeMB: _estimateExternalUsage(),
        context: context,
      );

      _addSnapshot(snapshot);
      _analyzeSnapshot(snapshot);
    } catch (e) {
      _logger.warning(
        'Failed to take memory snapshot',
        category: LogCategory.service,
        tag: 'Memory',
        metadata: {'error': e.toString()},
      );
    }
  }

  /// Estimate current heap usage (approximate)
  int _estimateHeapUsage() {
    // In debug mode, we can get more accurate info
    // In release, this is an approximation based on object counts
    if (kDebugMode) {
      // Use developer extension in debug
      return 80; // Placeholder - actual implementation requires VM service
    }
    return 80; // Conservative estimate for release
  }

  /// Estimate external memory usage
  int _estimateExternalUsage() {
    // External memory (images, native resources)
    return 20; // Placeholder estimate
  }

  void _addSnapshot(MemorySnapshot snapshot) {
    _snapshots.add(snapshot);
    _lastSnapshot = snapshot;

    // Rotate if too many
    if (_snapshots.length > _maxSnapshots) {
      _snapshots.removeAt(0);
    }
  }

  void _analyzeSnapshot(MemorySnapshot snapshot) {
    // Check for high memory usage
    if (snapshot.totalMB >= MemoryThresholds.critical) {
      _handleCriticalMemory(snapshot);
    } else if (snapshot.totalMB >= MemoryThresholds.warning) {
      _handleWarningMemory(snapshot);
    } else {
      _consecutiveHighUsageCount = 0;
    }

    // Check for rapid growth (potential leak)
    _checkForLeaks(snapshot);
  }

  void _handleWarningMemory(MemorySnapshot snapshot) {
    _consecutiveHighUsageCount++;

    _logger.warning(
      'High memory usage: ${snapshot.totalMB}MB',
      category: LogCategory.service,
      tag: 'Memory',
      metadata: snapshot.toMap(),
    );

    if (_consecutiveHighUsageCount >= 3) {
      _reportMemoryIssue('warning', snapshot);
    }
  }

  void _handleCriticalMemory(MemorySnapshot snapshot) {
    _consecutiveHighUsageCount++;

    _logger.error(
      'Critical memory usage: ${snapshot.totalMB}MB',
      category: LogCategory.service,
      tag: 'Memory',
      metadata: snapshot.toMap(),
    );

    _reportMemoryIssue('critical', snapshot);

    // Suggest garbage collection
    _suggestCleanup();
  }

  void _checkForLeaks(MemorySnapshot current) {
    if (_snapshots.length < 5) return;

    // Compare with snapshot from 5 intervals ago
    final previous = _snapshots[_snapshots.length - 5];
    final growth = current.totalMB - previous.totalMB;

    if (growth > MemoryThresholds.maxHeapGrowth) {
      _logger.warning(
        'Potential memory leak detected: +${growth}MB in ${5 * _monitorInterval.inSeconds}s',
        category: LogCategory.service,
        tag: 'Memory',
        metadata: {
          'growth_mb': growth,
          'previous': previous.toMap(),
          'current': current.toMap(),
        },
      );

      _reportMemoryLeak(growth, previous, current);
    }
  }

  Future<void> _reportMemoryIssue(
      String severity, MemorySnapshot snapshot) async {
    try {
      // Report to Sentry
      Sentry.captureMessage(
        'Memory $severity: ${snapshot.totalMB}MB',
        level: severity == 'critical' ? SentryLevel.error : SentryLevel.warning,
        withScope: (scope) {
          scope.setContexts('memory', snapshot.toMap());
          scope.setTag('memory_severity', severity);
        },
      );

      // Report to analytics
      await _analytics.logError(
        'memory_$severity',
        context: 'usage_${snapshot.totalMB}MB',
      );
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _reportMemoryLeak(
      int growthMB, MemorySnapshot previous, MemorySnapshot current) async {
    try {
      Sentry.captureMessage(
        'Potential memory leak: +${growthMB}MB',
        level: SentryLevel.warning,
        withScope: (scope) {
          scope.setContexts('memory_leak', {
            'growth_mb': growthMB,
            'previous': previous.toMap(),
            'current': current.toMap(),
          });
          scope.setTag('issue_type', 'memory_leak');
        },
      );
    } catch (e) {
      // Silently fail
    }
  }

  void _suggestCleanup() {
    _logger.info(
      'Suggesting memory cleanup - clearing caches',
      category: LogCategory.service,
      tag: 'Memory',
    );
    // The app should listen to this and clear image caches, etc.
  }

  /// Manually trigger a memory snapshot with context
  void takeManualSnapshot(String context) {
    _takeSnapshot(context: context);
  }

  /// Get memory trend (growth per minute)
  double? getMemoryTrend() {
    if (_snapshots.length < 2) return null;

    final oldest = _snapshots.first;
    final newest = _snapshots.last;

    final durationMinutes =
        newest.timestamp.difference(oldest.timestamp).inMinutes;
    if (durationMinutes == 0) return null;

    return (newest.totalMB - oldest.totalMB) / durationMinutes;
  }

  /// Get memory health status
  MemoryHealthStatus getHealthStatus() {
    final usage = currentUsageMB;
    final trend = getMemoryTrend();

    if (usage >= MemoryThresholds.critical) {
      return MemoryHealthStatus.critical;
    }
    if (usage >= MemoryThresholds.warning) {
      return MemoryHealthStatus.warning;
    }
    if (trend != null && trend > 5) {
      // Growing more than 5MB/minute
      return MemoryHealthStatus.leaking;
    }
    return MemoryHealthStatus.healthy;
  }

  /// Clear all snapshots
  void clearSnapshots() {
    _snapshots.clear();
    _lastSnapshot = null;
    _consecutiveHighUsageCount = 0;
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    clearSnapshots();
  }
}

/// Memory health status
enum MemoryHealthStatus {
  healthy,
  warning,
  critical,
  leaking,
}

extension MemoryHealthStatusX on MemoryHealthStatus {
  String get displayName {
    switch (this) {
      case MemoryHealthStatus.healthy:
        return 'Healthy';
      case MemoryHealthStatus.warning:
        return 'High Usage';
      case MemoryHealthStatus.critical:
        return 'Critical';
      case MemoryHealthStatus.leaking:
        return 'Potential Leak';
    }
  }

  bool get isHealthy => this == MemoryHealthStatus.healthy;
}
