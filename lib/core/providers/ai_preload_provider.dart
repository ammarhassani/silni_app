import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/supabase_config.dart';
import '../services/ai_preload_service.dart';

/// Provider for AI preload service singleton
final aiPreloadServiceProvider = Provider<AIPreloadService>((ref) {
  return AIPreloadService();
});

/// State for AI preload progress
class AIPreloadState {
  final bool isPreloading;
  final bool hasPreloaded;
  final String? error;

  const AIPreloadState({
    this.isPreloading = false,
    this.hasPreloaded = false,
    this.error,
  });

  AIPreloadState copyWith({
    bool? isPreloading,
    bool? hasPreloaded,
    String? error,
  }) {
    return AIPreloadState(
      isPreloading: isPreloading ?? this.isPreloading,
      hasPreloaded: hasPreloaded ?? this.hasPreloaded,
      error: error,
    );
  }
}

/// Notifier for managing AI preload state
class AIPreloadNotifier extends StateNotifier<AIPreloadState> {
  final AIPreloadService _service;

  AIPreloadNotifier(this._service) : super(const AIPreloadState());

  /// Trigger preload if not already done or stale
  Future<void> preloadIfNeeded() async {
    if (state.isPreloading) return;
    if (state.hasPreloaded && !_service.isStale) return;

    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) return;

    state = state.copyWith(isPreloading: true);

    try {
      await _service.preloadAll();
      if (!mounted) return;
      state = state.copyWith(isPreloading: false, hasPreloaded: true);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isPreloading: false,
        error: 'فشل تحميل البيانات الذكية',
      );
    }
  }

  /// Force refresh preload
  Future<void> refresh() async {
    _service.clearCache();
    state = state.copyWith(hasPreloaded: false);
    await preloadIfNeeded();
  }
}

/// Provider for AI preload state and control
final aiPreloadProvider =
    StateNotifierProvider<AIPreloadNotifier, AIPreloadState>((ref) {
  final service = ref.watch(aiPreloadServiceProvider);
  return AIPreloadNotifier(service);
});

/// Auto-trigger preload on provider access
/// Use this in home screen to trigger preload on app start
final aiAutoPreloadProvider = FutureProvider.autoDispose<void>((ref) async {
  final userId = SupabaseConfig.currentUser?.id;
  if (userId == null) return;

  final preloadService = ref.read(aiPreloadServiceProvider);

  // Only preload if stale or never loaded
  if (preloadService.isStale) {
    await preloadService.preloadAll();
  }
});
