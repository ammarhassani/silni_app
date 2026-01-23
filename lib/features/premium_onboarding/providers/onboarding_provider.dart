import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/subscription_provider.dart';
import '../models/onboarding_state.dart';
import '../models/onboarding_step.dart';
import 'onboarding_storage_provider.dart';

/// Main onboarding state notifier
/// Manages the premium onboarding flow and progress
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final Ref ref;
  final OnboardingStorageService _storage;
  DateTime? _stepStartTime;
  bool _isInitialized = false;

  OnboardingNotifier(this.ref, this._storage)
      : super(OnboardingState.initial()) {
    _loadState();
  }

  /// Load state from storage on initialization
  Future<void> _loadState() async {
    if (_isInitialized) return;

    state = state.copyWith(isLoading: true);

    try {
      final savedState = await _storage.loadState();
      if (savedState != null) {
        state = savedState.copyWith(isLoading: false);
      } else {
        // Initialize with step progress for all steps
        final stepProgress = OnboardingSteps.allSteps
            .map((step) => StepProgress(stepId: step.id))
            .toList();

        state = OnboardingState(
          stepProgress: stepProgress,
          isLoading: false,
        );
      }
      _isInitialized = true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Start the onboarding flow
  Future<void> startOnboarding() async {
    if (state.hasStarted) return;

    final now = DateTime.now();
    _stepStartTime = now;

    // Initialize step progress if empty
    List<StepProgress> stepProgress = state.stepProgress;
    if (stepProgress.isEmpty) {
      stepProgress = OnboardingSteps.allSteps
          .map((step) => StepProgress(stepId: step.id))
          .toList();
    }

    state = state.copyWith(
      hasStarted: true,
      startedAt: now,
      currentStepIndex: 0,
      stepProgress: stepProgress,
    );

    await _saveState();
  }

  /// View a specific step (updates progress)
  Future<void> viewStep(int index) async {
    if (index < 0 || index >= OnboardingSteps.totalSteps) return;

    // Record time spent on previous step
    _recordStepTime();

    final step = OnboardingSteps.allSteps[index];
    final updatedProgress = _updateStepProgress(step.id, StepStatus.viewed);

    state = state.copyWith(
      currentStepIndex: index,
      stepProgress: updatedProgress,
    );

    _stepStartTime = DateTime.now();
    await _saveState();
  }

  /// Mark a step as completed (user tapped "Try Now")
  Future<void> completeStep(int index) async {
    if (index < 0 || index >= OnboardingSteps.totalSteps) return;

    _recordStepTime();

    final step = OnboardingSteps.allSteps[index];
    final updatedProgress = _updateStepProgress(step.id, StepStatus.completed);

    state = state.copyWith(
      stepProgress: updatedProgress,
    );

    await _saveState();
  }

  /// Skip a specific step
  Future<void> skipStep(int index) async {
    if (index < 0 || index >= OnboardingSteps.totalSteps) return;

    _recordStepTime();

    final step = OnboardingSteps.allSteps[index];
    final updatedProgress = _updateStepProgress(step.id, StepStatus.skipped);

    state = state.copyWith(
      stepProgress: updatedProgress,
    );

    await _saveState();
  }

  /// Skip the entire showcase
  Future<void> skipShowcase() async {
    _recordStepTime();

    state = state.copyWith(
      skippedShowcase: true,
      isCompleted: true,
      completedAt: DateTime.now(),
    );

    await _saveState();
  }

  /// Complete the entire onboarding
  Future<void> completeOnboarding() async {
    _recordStepTime();

    state = state.copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );

    await _saveState();
  }

  /// Mark a screen as viewed (for contextual tips)
  Future<void> markScreenViewed(String screenRoute) async {
    final updatedScreens = Map<String, bool>.from(state.viewedScreens);
    updatedScreens[screenRoute] = true;

    state = state.copyWith(viewedScreens: updatedScreens);
    await _saveState();
  }

  /// Reset onboarding (for testing)
  Future<void> resetOnboarding() async {
    await _storage.clearState();

    final stepProgress = OnboardingSteps.allSteps
        .map((step) => StepProgress(stepId: step.id))
        .toList();

    state = OnboardingState(
      stepProgress: stepProgress,
      isLoading: false,
    );
  }

  // =====================================================
  // PRIVATE HELPERS
  // =====================================================

  void _recordStepTime() {
    if (_stepStartTime == null) return;

    final elapsed = DateTime.now().difference(_stepStartTime!).inSeconds;
    state = state.copyWith(
      totalTimeSpentSeconds: state.totalTimeSpentSeconds + elapsed,
    );

    // Update step progress time
    if (state.currentStepIndex >= 0 &&
        state.currentStepIndex < state.stepProgress.length) {
      final currentProgress = state.stepProgress[state.currentStepIndex];
      final updatedProgress = List<StepProgress>.from(state.stepProgress);
      updatedProgress[state.currentStepIndex] = currentProgress.copyWith(
        timeSpentSeconds: currentProgress.timeSpentSeconds + elapsed,
      );
      state = state.copyWith(stepProgress: updatedProgress);
    }

    _stepStartTime = null;
  }

  List<StepProgress> _updateStepProgress(String stepId, StepStatus newStatus) {
    final updatedProgress = List<StepProgress>.from(state.stepProgress);
    final index = updatedProgress.indexWhere((p) => p.stepId == stepId);

    if (index >= 0) {
      final current = updatedProgress[index];
      updatedProgress[index] = current.copyWith(
        status: newStatus,
        viewedAt: newStatus == StepStatus.viewed && current.viewedAt == null
            ? DateTime.now()
            : current.viewedAt,
        completedAt: newStatus == StepStatus.completed ? DateTime.now() : null,
        skipped: newStatus == StepStatus.skipped,
      );
    }

    return updatedProgress;
  }

  Future<void> _saveState() async {
    try {
      await _storage.saveState(state);
    } catch (_) {
      // Failed to save state silently
    }
  }
}

// =====================================================
// PROVIDERS
// =====================================================

/// Main onboarding state provider
final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final storage = ref.watch(onboardingStorageProvider);
  return OnboardingNotifier(ref, storage);
});

/// Whether premium onboarding should be shown
/// True if user is MAX and hasn't completed onboarding
final shouldShowOnboardingProvider = Provider<bool>((ref) {
  final isMax = ref.watch(isMaxProvider);
  final onboardingState = ref.watch(onboardingProvider);

  // Don't show if not MAX
  if (!isMax) return false;

  // Don't show if already completed
  if (onboardingState.isCompleted) return false;

  // Don't show if still loading
  if (onboardingState.isLoading) return false;

  return true;
});

/// Completion percentage (0.0 to 1.0)
final onboardingProgressProvider = Provider<double>((ref) {
  final state = ref.watch(onboardingProvider);
  return state.completionPercentage;
});

/// Current step index
final currentStepIndexProvider = Provider<int>((ref) {
  final state = ref.watch(onboardingProvider);
  return state.currentStepIndex;
});

/// Whether onboarding is complete
final isOnboardingCompleteProvider = Provider<bool>((ref) {
  final state = ref.watch(onboardingProvider);
  return state.isCompleted;
});

/// Total steps count
final totalStepsProvider = Provider<int>((ref) {
  return OnboardingSteps.totalSteps;
});
