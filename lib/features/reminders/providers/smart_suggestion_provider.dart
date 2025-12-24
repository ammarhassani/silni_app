import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/ai/ai_models.dart';
import '../../../core/ai/deepseek_ai_service.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/services/ai_preload_service.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/services/relatives_service.dart';

/// State for smart reminder suggestions
class SmartSuggestionState {
  final List<SmartReminderSuggestion> suggestions;
  final bool isLoading;
  final String? error;
  final Set<String> dismissedSuggestions;
  final bool isExpanded;

  const SmartSuggestionState({
    this.suggestions = const [],
    this.isLoading = false,
    this.error,
    this.dismissedSuggestions = const {},
    this.isExpanded = true,
  });

  SmartSuggestionState copyWith({
    List<SmartReminderSuggestion>? suggestions,
    bool? isLoading,
    String? error,
    Set<String>? dismissedSuggestions,
    bool? isExpanded,
    bool clearError = false,
  }) {
    return SmartSuggestionState(
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      dismissedSuggestions: dismissedSuggestions ?? this.dismissedSuggestions,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  List<SmartReminderSuggestion> get activeSuggestions {
    return suggestions
        .where((s) => !dismissedSuggestions.contains(s.relativeName))
        .toList();
  }
}

/// Smart suggestion notifier
class SmartSuggestionNotifier extends StateNotifier<SmartSuggestionState> {
  final DeepSeekAIService _aiService;
  final RelativesService _relativesService;
  static const _dismissedKey = 'smart_suggestions_dismissed';

  SmartSuggestionNotifier(this._aiService, this._relativesService)
      : super(const SmartSuggestionState()) {
    _loadDismissedSuggestions();
  }

  Future<void> _loadDismissedSuggestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getStringList(_dismissedKey) ?? [];
      state = state.copyWith(dismissedSuggestions: dismissed.toSet());
    } catch (_) {
      // Ignore errors loading dismissed suggestions
    }
  }

  Future<void> _saveDismissedSuggestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _dismissedKey,
        state.dismissedSuggestions.toList(),
      );
    } catch (_) {
      // Ignore errors saving
    }
  }

  Future<void> loadSuggestions() async {
    if (state.isLoading) return;

    // Check cache first for instant loading
    final preloadService = AIPreloadService();
    if (preloadService.hasCachedSuggestions) {
      state = state.copyWith(
        suggestions: preloadService.cachedSuggestions!,
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'يرجى تسجيل الدخول',
        );
        return;
      }

      final relatives = await _relativesService
          .getRelativesStream(userId)
          .first
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => <Relative>[],
          );

      if (relatives.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          suggestions: [],
        );
        return;
      }

      final suggestions = await _aiService.getSmartReminderSuggestions(
        relatives: relatives,
      );

      if (!mounted) return;

      // Cache the suggestions for future use
      preloadService.setCachedSuggestions(suggestions);

      state = state.copyWith(
        suggestions: suggestions,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'حدث خطأ في تحميل الاقتراحات',
      );
    }
  }

  void dismissSuggestion(String relativeName) {
    final newDismissed = Set<String>.from(state.dismissedSuggestions)
      ..add(relativeName);
    state = state.copyWith(dismissedSuggestions: newDismissed);
    _saveDismissedSuggestions();
  }

  void toggleExpanded() {
    state = state.copyWith(isExpanded: !state.isExpanded);
  }

  void clearDismissed() {
    state = state.copyWith(dismissedSuggestions: {});
    _saveDismissedSuggestions();
  }

  /// Get relative by name from suggestions
  Relative? getRelativeByName(String name, List<Relative> relatives) {
    try {
      return relatives.firstWhere(
        (r) => r.fullName == name,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Provider for smart suggestions
final smartSuggestionProvider =
    StateNotifierProvider.autoDispose<SmartSuggestionNotifier, SmartSuggestionState>((ref) {
  final aiService = DeepSeekAIService();
  final relativesService = RelativesService();
  final notifier = SmartSuggestionNotifier(aiService, relativesService);
  // Auto-load when provider is created
  notifier.loadSuggestions();
  return notifier;
});
