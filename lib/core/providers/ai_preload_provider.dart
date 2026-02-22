import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/supabase_config.dart';
import '../services/ai_preload_service.dart';
import 'subscription_provider.dart';

/// Provider for AI preload service singleton
final aiPreloadServiceProvider = Provider<AIPreloadService>((ref) {
  return AIPreloadService();
});

/// Auto-trigger preload on provider access
/// Use this in home screen to trigger preload on app start
final aiAutoPreloadProvider = FutureProvider.autoDispose<void>((ref) async {
  final userId = SupabaseConfig.currentUser?.id;
  if (userId == null) return;

  // Skip AI preload for free users — they have 0 AI rate limit
  final isMax = ref.read(isMaxProvider);
  if (!isMax) return;

  final preloadService = ref.read(aiPreloadServiceProvider);

  // Only preload if stale or never loaded
  if (preloadService.isStale) {
    await preloadService.preloadAll();
  }
});
