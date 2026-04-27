import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/supabase_config.dart';
import '../services/ai_preload_service.dart';
import 'subscription_provider.dart';

/// Provider for AI preload service singleton
final aiPreloadServiceProvider = Provider<AIPreloadService>((ref) {
  return AIPreloadService();
});

/// Auto-trigger preload on provider access.
/// Used by home screen to trigger preload on app start.
///
/// Watched (not read) for `isMaxProvider` so the gate re-evaluates if
/// the subscription tier flips while the user is on the home screen
/// (e.g. a RevenueCat webhook landing or an in-app purchase resolving
/// without leaving the screen). Without `watch`, the gate would only
/// re-evaluate when the home screen unmounts and remounts.
final aiAutoPreloadProvider = FutureProvider.autoDispose<void>((ref) async {
  final userId = SupabaseConfig.currentUser?.id;
  if (userId == null) return;

  // Skip AI preload for free users — they have 0 AI rate limit and the
  // preload calls would be wasted DeepSeek invocations.
  final isMax = ref.watch(isMaxProvider);
  if (!isMax) return;

  final preloadService = ref.read(aiPreloadServiceProvider);

  // Only preload if stale or never loaded.
  if (preloadService.isStale) {
    await preloadService.preloadAll();
  }
});
