import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/analytics.dart';

/// Provider for the Analytics service
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});
