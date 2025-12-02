import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/gamification_service.dart';
import 'analytics_provider.dart';
import 'gamification_events_provider.dart';

/// Provider for the Gamification service
final gamificationServiceProvider = Provider<GamificationService>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  final eventsController = ref.watch(gamificationEventsControllerProvider);
  return GamificationService(
    analytics: analytics,
    eventsController: eventsController,
  );
});
