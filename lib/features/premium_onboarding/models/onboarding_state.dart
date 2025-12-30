import 'dart:convert';

/// Status of an individual onboarding step
enum StepStatus {
  pending,
  viewed,
  interacted,
  completed,
  skipped;

  String get id => name;

  static StepStatus fromId(String id) {
    return StepStatus.values.firstWhere(
      (s) => s.id == id,
      orElse: () => StepStatus.pending,
    );
  }
}

/// Progress for a single onboarding step
class StepProgress {
  final String stepId;
  final StepStatus status;
  final DateTime? viewedAt;
  final DateTime? completedAt;
  final int timeSpentSeconds;
  final bool skipped;

  const StepProgress({
    required this.stepId,
    this.status = StepStatus.pending,
    this.viewedAt,
    this.completedAt,
    this.timeSpentSeconds = 0,
    this.skipped = false,
  });

  StepProgress copyWith({
    String? stepId,
    StepStatus? status,
    DateTime? viewedAt,
    DateTime? completedAt,
    int? timeSpentSeconds,
    bool? skipped,
    bool clearViewedAt = false,
    bool clearCompletedAt = false,
  }) {
    return StepProgress(
      stepId: stepId ?? this.stepId,
      status: status ?? this.status,
      viewedAt: clearViewedAt ? null : (viewedAt ?? this.viewedAt),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      skipped: skipped ?? this.skipped,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stepId': stepId,
      'status': status.id,
      'viewedAt': viewedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'timeSpentSeconds': timeSpentSeconds,
      'skipped': skipped,
    };
  }

  factory StepProgress.fromJson(Map<String, dynamic> json) {
    return StepProgress(
      stepId: json['stepId'] as String,
      status: StepStatus.fromId(json['status'] as String? ?? 'pending'),
      viewedAt: json['viewedAt'] != null
          ? DateTime.parse(json['viewedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      timeSpentSeconds: json['timeSpentSeconds'] as int? ?? 0,
      skipped: json['skipped'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StepProgress &&
        other.stepId == stepId &&
        other.status == status &&
        other.viewedAt == viewedAt &&
        other.completedAt == completedAt &&
        other.timeSpentSeconds == timeSpentSeconds &&
        other.skipped == skipped;
  }

  @override
  int get hashCode => Object.hash(
        stepId,
        status,
        viewedAt,
        completedAt,
        timeSpentSeconds,
        skipped,
      );
}

/// Main onboarding state model
/// Tracks progress through the premium onboarding experience
class OnboardingState {
  /// Whether onboarding has been started
  final bool hasStarted;

  /// Whether onboarding has been completed
  final bool isCompleted;

  /// Current step index in the carousel
  final int currentStepIndex;

  /// Progress for each step
  final List<StepProgress> stepProgress;

  /// Screens that have been viewed (for contextual tips)
  final Map<String, bool> viewedScreens;

  /// When onboarding was started
  final DateTime? startedAt;

  /// When onboarding was completed
  final DateTime? completedAt;

  /// Total time spent in onboarding (seconds)
  final int totalTimeSpentSeconds;

  /// Whether user skipped the showcase
  final bool skippedShowcase;

  /// Whether state is loading
  final bool isLoading;

  /// Error message if any
  final String? error;

  const OnboardingState({
    this.hasStarted = false,
    this.isCompleted = false,
    this.currentStepIndex = 0,
    this.stepProgress = const [],
    this.viewedScreens = const {},
    this.startedAt,
    this.completedAt,
    this.totalTimeSpentSeconds = 0,
    this.skippedShowcase = false,
    this.isLoading = false,
    this.error,
  });

  /// Initial state factory
  factory OnboardingState.initial() {
    return const OnboardingState();
  }

  /// Loading state factory
  factory OnboardingState.loading() {
    return const OnboardingState(isLoading: true);
  }

  OnboardingState copyWith({
    bool? hasStarted,
    bool? isCompleted,
    int? currentStepIndex,
    List<StepProgress>? stepProgress,
    Map<String, bool>? viewedScreens,
    DateTime? startedAt,
    DateTime? completedAt,
    int? totalTimeSpentSeconds,
    bool? skippedShowcase,
    bool? isLoading,
    String? error,
    bool clearStartedAt = false,
    bool clearCompletedAt = false,
    bool clearError = false,
  }) {
    return OnboardingState(
      hasStarted: hasStarted ?? this.hasStarted,
      isCompleted: isCompleted ?? this.isCompleted,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      stepProgress: stepProgress ?? this.stepProgress,
      viewedScreens: viewedScreens ?? this.viewedScreens,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      totalTimeSpentSeconds:
          totalTimeSpentSeconds ?? this.totalTimeSpentSeconds,
      skippedShowcase: skippedShowcase ?? this.skippedShowcase,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  // =====================================================
  // CONVENIENCE GETTERS
  // =====================================================

  /// Completion percentage (0.0 to 1.0)
  double get completionPercentage {
    if (stepProgress.isEmpty) return 0.0;
    final completed = stepProgress
        .where((s) =>
            s.status == StepStatus.completed || s.status == StepStatus.skipped)
        .length;
    return completed / stepProgress.length;
  }

  /// Number of steps completed
  int get completedStepsCount {
    return stepProgress
        .where((s) => s.status == StepStatus.completed)
        .length;
  }

  /// Number of steps skipped
  int get skippedStepsCount {
    return stepProgress
        .where((s) => s.status == StepStatus.skipped)
        .length;
  }

  /// Whether all steps have been viewed
  bool get allStepsViewed {
    if (stepProgress.isEmpty) return false;
    return stepProgress.every((s) => s.status != StepStatus.pending);
  }

  /// Get progress for a specific step
  StepProgress? getStepProgress(String stepId) {
    try {
      return stepProgress.firstWhere((s) => s.stepId == stepId);
    } catch (_) {
      return null;
    }
  }

  /// Check if a screen has been viewed (for contextual tips)
  bool hasViewedScreen(String screenRoute) {
    return viewedScreens[screenRoute] ?? false;
  }

  // =====================================================
  // SERIALIZATION
  // =====================================================

  Map<String, dynamic> toJson() {
    return {
      'hasStarted': hasStarted,
      'isCompleted': isCompleted,
      'currentStepIndex': currentStepIndex,
      'stepProgress': stepProgress.map((s) => s.toJson()).toList(),
      'viewedScreens': viewedScreens,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'totalTimeSpentSeconds': totalTimeSpentSeconds,
      'skippedShowcase': skippedShowcase,
    };
  }

  factory OnboardingState.fromJson(Map<String, dynamic> json) {
    return OnboardingState(
      hasStarted: json['hasStarted'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      currentStepIndex: json['currentStepIndex'] as int? ?? 0,
      stepProgress: (json['stepProgress'] as List<dynamic>?)
              ?.map((e) => StepProgress.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      viewedScreens: (json['viewedScreens'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as bool)) ??
          {},
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      totalTimeSpentSeconds: json['totalTimeSpentSeconds'] as int? ?? 0,
      skippedShowcase: json['skippedShowcase'] as bool? ?? false,
    );
  }

  /// Convert to JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Parse from JSON string
  factory OnboardingState.fromJsonString(String jsonString) {
    return OnboardingState.fromJson(jsonDecode(jsonString));
  }

  @override
  String toString() {
    return 'OnboardingState(hasStarted: $hasStarted, isCompleted: $isCompleted, '
        'currentStep: $currentStepIndex, progress: ${(completionPercentage * 100).toStringAsFixed(0)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnboardingState &&
        other.hasStarted == hasStarted &&
        other.isCompleted == isCompleted &&
        other.currentStepIndex == currentStepIndex &&
        other.totalTimeSpentSeconds == totalTimeSpentSeconds &&
        other.skippedShowcase == skippedShowcase;
  }

  @override
  int get hashCode => Object.hash(
        hasStarted,
        isCompleted,
        currentStepIndex,
        totalTimeSpentSeconds,
        skippedShowcase,
      );
}
