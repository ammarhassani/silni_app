import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/subscription_provider.dart';
import '../models/contextual_tip.dart';
import 'onboarding_storage_provider.dart';

/// State for contextual tips
class ContextualTipsState {
  /// Map of tip IDs that have been dismissed
  final Map<String, bool> dismissedTips;

  /// Currently showing tip ID (null if none)
  final String? currentTipId;

  /// Whether tips are enabled globally
  final bool tipsEnabled;

  /// Whether state is loading
  final bool isLoading;

  const ContextualTipsState({
    this.dismissedTips = const {},
    this.currentTipId,
    this.tipsEnabled = true,
    this.isLoading = false,
  });

  ContextualTipsState copyWith({
    Map<String, bool>? dismissedTips,
    String? currentTipId,
    bool? tipsEnabled,
    bool? isLoading,
    bool clearCurrentTip = false,
  }) {
    return ContextualTipsState(
      dismissedTips: dismissedTips ?? this.dismissedTips,
      currentTipId: clearCurrentTip ? null : (currentTipId ?? this.currentTipId),
      tipsEnabled: tipsEnabled ?? this.tipsEnabled,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier for managing contextual tips state
class ContextualTipsNotifier extends StateNotifier<ContextualTipsState> {
  final Ref ref;
  final OnboardingStorageService _storage;
  bool _isInitialized = false;

  ContextualTipsNotifier(this.ref, this._storage)
      : super(const ContextualTipsState(isLoading: true)) {
    _loadDismissedTips();
  }

  /// Load dismissed tips from storage
  Future<void> _loadDismissedTips() async {
    if (_isInitialized) return;

    try {
      final dismissedTips = await _storage.loadDismissedTips();
      state = state.copyWith(
        dismissedTips: dismissedTips,
        isLoading: false,
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('[ContextualTips] Failed to load dismissed tips: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Get tips for a specific screen that haven't been dismissed
  List<ContextualTip> getTipsForScreen(String screenRoute) {
    // Check if MAX user
    final isMax = ref.read(isMaxProvider);
    if (!isMax || !state.tipsEnabled) return [];

    // Get tips for this screen, excluding dismissed ones
    return ContextualTips.getTipsForScreen(screenRoute)
        .where((tip) => !state.dismissedTips.containsKey(tip.id))
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }

  /// Get the next tip to show for a screen
  ContextualTip? getNextTipForScreen(String screenRoute) {
    final tips = getTipsForScreen(screenRoute);
    return tips.isEmpty ? null : tips.first;
  }

  /// Show a specific tip
  void showTip(String tipId) {
    state = state.copyWith(currentTipId: tipId);
    debugPrint('[ContextualTips] Showing tip: $tipId');
  }

  /// Dismiss a tip
  Future<void> dismissTip(String tipId) async {
    final updatedDismissed = Map<String, bool>.from(state.dismissedTips);
    updatedDismissed[tipId] = true;

    state = state.copyWith(
      dismissedTips: updatedDismissed,
      clearCurrentTip: true,
    );

    // Save to storage
    await _storage.saveDismissedTips(updatedDismissed);
    debugPrint('[ContextualTips] Dismissed tip: $tipId');
  }

  /// Dismiss all tips for a screen
  Future<void> dismissTipsForScreen(String screenRoute) async {
    final tipsToDisable = ContextualTips.getTipsForScreen(screenRoute);
    final updatedDismissed = Map<String, bool>.from(state.dismissedTips);

    for (final tip in tipsToDisable) {
      updatedDismissed[tip.id] = true;
    }

    state = state.copyWith(
      dismissedTips: updatedDismissed,
      clearCurrentTip: true,
    );

    await _storage.saveDismissedTips(updatedDismissed);
    debugPrint('[ContextualTips] Dismissed all tips for: $screenRoute');
  }

  /// Enable/disable tips globally
  void setTipsEnabled(bool enabled) {
    state = state.copyWith(tipsEnabled: enabled);
    if (!enabled) {
      state = state.copyWith(clearCurrentTip: true);
    }
    debugPrint('[ContextualTips] Tips enabled: $enabled');
  }

  /// Clear current tip without dismissing
  void clearCurrentTip() {
    state = state.copyWith(clearCurrentTip: true);
  }

  /// Reset all dismissed tips (for testing)
  Future<void> resetAllTips() async {
    state = state.copyWith(
      dismissedTips: {},
      clearCurrentTip: true,
    );
    await _storage.saveDismissedTips({});
    debugPrint('[ContextualTips] All tips reset');
  }

  /// Check if a specific tip has been dismissed
  bool isTipDismissed(String tipId) {
    return state.dismissedTips.containsKey(tipId);
  }
}

// =====================================================
// PROVIDERS
// =====================================================

/// Main contextual tips state provider
final contextualTipsProvider =
    StateNotifierProvider<ContextualTipsNotifier, ContextualTipsState>((ref) {
  final storage = ref.watch(onboardingStorageProvider);
  return ContextualTipsNotifier(ref, storage);
});

/// Provider to check if a specific tip should be shown
/// Usage: ref.watch(shouldShowTipProvider('tip_id'))
final shouldShowTipProvider = Provider.family<bool, String>((ref, tipId) {
  final state = ref.watch(contextualTipsProvider);
  final isMax = ref.watch(isMaxProvider);

  return isMax &&
      state.tipsEnabled &&
      !state.dismissedTips.containsKey(tipId) &&
      !state.isLoading;
});

/// Provider for getting the current tip being shown
final currentTipProvider = Provider<ContextualTip?>((ref) {
  final state = ref.watch(contextualTipsProvider);
  if (state.currentTipId == null) return null;
  return ContextualTips.getById(state.currentTipId!);
});

/// Provider for checking if tips are enabled
final tipsEnabledProvider = Provider<bool>((ref) {
  final state = ref.watch(contextualTipsProvider);
  return state.tipsEnabled;
});

/// Provider for checking if tips are loading
final tipsLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(contextualTipsProvider);
  return state.isLoading;
});
