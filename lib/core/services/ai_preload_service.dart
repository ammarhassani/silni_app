import '../ai/ai_models.dart';
import '../ai/deepseek_ai_service.dart';
import '../../shared/models/relative_model.dart';
import '../../shared/services/relatives_service.dart';
import '../config/supabase_config.dart';

/// Service to preload AI data in background when app starts
/// This improves UX by having data ready when user navigates to AI features
class AIPreloadService {
  final DeepSeekAIService _aiService;
  final RelativesService _relativesService;

  // Cached results
  List<SmartReminderSuggestion>? _cachedSuggestions;
  final Map<String, RelationshipAnalysis> _cachedAnalyses = {};
  DateTime? _lastPreloadTime;
  bool _isPreloading = false;

  // Singleton instance
  static AIPreloadService? _instance;

  AIPreloadService._({
    required DeepSeekAIService aiService,
    required RelativesService relativesService,
  })  : _aiService = aiService,
        _relativesService = relativesService;

  /// Get singleton instance
  factory AIPreloadService({
    DeepSeekAIService? aiService,
    RelativesService? relativesService,
  }) {
    _instance ??= AIPreloadService._(
      aiService: aiService ?? DeepSeekAIService(),
      relativesService: relativesService ?? RelativesService(),
    );
    return _instance!;
  }

  /// Check if cache is stale (older than 30 minutes)
  bool get isStale =>
      _lastPreloadTime == null ||
      DateTime.now().difference(_lastPreloadTime!).inMinutes > 30;

  /// Check if currently preloading
  bool get isPreloading => _isPreloading;

  /// Check if suggestions are cached
  bool get hasCachedSuggestions => _cachedSuggestions != null;

  /// Get cached suggestions
  List<SmartReminderSuggestion>? get cachedSuggestions => _cachedSuggestions;

  /// Get cached analysis for a specific relative
  RelationshipAnalysis? getCachedAnalysis(String relativeId) =>
      _cachedAnalyses[relativeId];

  /// Check if analysis is cached for a relative
  bool hasAnalysisFor(String relativeId) =>
      _cachedAnalyses.containsKey(relativeId);

  /// Preload all AI data in background
  Future<void> preloadAll() async {
    if (_isPreloading) return;

    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) return;

    _isPreloading = true;

    try {
      final relatives = await _relativesService
          .getRelativesStream(userId)
          .first
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => <Relative>[],
          );

      if (relatives.isEmpty) {
        _isPreloading = false;
        return;
      }

      // Parallel preload - suggestions and priority analyses
      await Future.wait([
        _preloadSmartSuggestions(relatives),
        _preloadPriorityAnalyses(relatives),
      ]);

      _lastPreloadTime = DateTime.now();
    } catch (e) {
      // Silent fail - preloading is optional enhancement
    } finally {
      _isPreloading = false;
    }
  }

  /// Preload smart reminder suggestions
  Future<void> _preloadSmartSuggestions(List<Relative> relatives) async {
    try {
      _cachedSuggestions = await _aiService.getSmartReminderSuggestions(
        relatives: relatives,
      );
    } catch (e) {
      // Silent fail
    }
  }

  /// Preload relationship analyses for priority relatives (at-risk or needs attention)
  Future<void> _preloadPriorityAnalyses(List<Relative> relatives) async {
    // Only preload for top 5 priority relatives
    final priorityRelatives = relatives
        .where((r) =>
            r.healthStatus2 == RelationshipHealthStatus.atRisk ||
            r.healthStatus2 == RelationshipHealthStatus.needsAttention)
        .take(5)
        .toList();

    for (final relative in priorityRelatives) {
      try {
        final analysis = await _aiService.analyzeRelationship(
          relative: relative,
        );
        _cachedAnalyses[relative.id] = analysis;
      } catch (e) {
        // Silent fail - continue with next relative
      }
    }
  }

  /// Preload analysis for a specific relative
  Future<RelationshipAnalysis?> preloadAnalysis(Relative relative) async {
    if (_cachedAnalyses.containsKey(relative.id)) {
      return _cachedAnalyses[relative.id];
    }

    try {
      final analysis = await _aiService.analyzeRelationship(relative: relative);
      _cachedAnalyses[relative.id] = analysis;
      return analysis;
    } catch (e) {
      return null;
    }
  }

  /// Manually set suggestions (for when loaded elsewhere)
  void setCachedSuggestions(List<SmartReminderSuggestion> suggestions) {
    _cachedSuggestions = suggestions;
    _lastPreloadTime = DateTime.now();
  }

  /// Clear all cached data
  void clearCache() {
    _cachedSuggestions = null;
    _cachedAnalyses.clear();
    _lastPreloadTime = null;
  }

  /// Clear analysis cache for a specific relative (use after interaction)
  void clearAnalysisFor(String relativeId) {
    _cachedAnalyses.remove(relativeId);
  }
}
