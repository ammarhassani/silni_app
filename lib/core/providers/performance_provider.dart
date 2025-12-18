import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/performance_monitoring_service.dart';

/// Provider for performance monitoring service
final performanceMonitoringProvider = Provider<PerformanceMonitoringService>((ref) {
  final service = PerformanceMonitoringService();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider for recent performance metrics
final recentMetricsProvider = Provider<List<PerformanceMetric>>((ref) {
  final service = ref.watch(performanceMonitoringProvider);
  return service.getRecentMetrics();
});

/// Provider to get average duration for specific operation
final averageDurationProvider = Provider.family<double?, String>((ref, operationName) {
  final service = ref.watch(performanceMonitoringProvider);
  return service.getAverageDuration(operationName);
});

/// Provider to get performance summary for specific operation
final performanceSummaryProvider = Provider.family<PerformanceSummary?, String>((ref, operationName) {
  final service = ref.watch(performanceMonitoringProvider);
  return service.getPerformanceSummary(operationName);
});

/// Provider for performance monitoring enabled state
final performanceMonitoringEnabledProvider = StateProvider<bool>((ref) {
  final service = ref.watch(performanceMonitoringProvider);
  return service.isEnabled;
});
