import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai_context_engine.dart';
import '../services/ai_touch_point_service.dart';
import '../../shared/models/relative_model.dart';

/// Provider for AI Context Engine singleton
final aiContextEngineProvider = Provider<AIContextEngine>((ref) {
  return AIContextEngine.instance;
});

/// Provider for AI Touch Point Service singleton
final aiTouchPointServiceProvider = Provider<AITouchPointService>((ref) {
  return AITouchPointService.instance;
});

/// Provider to build AI context for a specific feature
final aiContextProvider = FutureProvider.family<AIContext, String?>((ref, featureContext) async {
  final engine = ref.watch(aiContextEngineProvider);
  return engine.buildContext(featureContext: featureContext);
});

/// Provider to generate AI content for a touch point
final aiTouchPointProvider = FutureProvider.family<AITouchPointResult, AITouchPointRequest>((ref, request) async {
  final service = ref.watch(aiTouchPointServiceProvider);
  final engine = ref.watch(aiContextEngineProvider);

  // Initialize if needed
  await service.initialize();

  // Build context with focus relative if provided
  AIContext? context;
  if (request.focusRelative != null) {
    context = await engine.buildContext(
      featureContext: request.screenKey,
      focusRelative: request.focusRelative,
    );
  }

  return service.generate(
    screenKey: request.screenKey,
    touchPointKey: request.touchPointKey,
    context: context,
    useCache: request.useCache,
  );
});

/// Request parameters for AI touch point generation
class AITouchPointRequest {
  final String screenKey;
  final String touchPointKey;
  final bool useCache;
  final Relative? focusRelative;

  const AITouchPointRequest({
    required this.screenKey,
    required this.touchPointKey,
    this.useCache = true,
    this.focusRelative,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AITouchPointRequest &&
          runtimeType == other.runtimeType &&
          screenKey == other.screenKey &&
          touchPointKey == other.touchPointKey &&
          useCache == other.useCache &&
          focusRelative?.id == other.focusRelative?.id;

  @override
  int get hashCode =>
      screenKey.hashCode ^ touchPointKey.hashCode ^ useCache.hashCode ^ (focusRelative?.id.hashCode ?? 0);
}
