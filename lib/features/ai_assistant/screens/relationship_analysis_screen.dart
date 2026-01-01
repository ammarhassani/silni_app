import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/ai_identity.dart';
import '../../../core/ai/ai_models.dart';
import '../../../core/ai/deepseek_ai_service.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/ai_preload_service.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/relative_model.dart';
import '../widgets/ai_error_card.dart';
import '../widgets/ai_loading_indicator.dart';
import '../widgets/relative_selector.dart';

/// State for relationship analysis
class RelationshipAnalysisState {
  final Relative? selectedRelative;
  final RelationshipAnalysis? analysis;
  final bool isLoading;
  final String? error;

  const RelationshipAnalysisState({
    this.selectedRelative,
    this.analysis,
    this.isLoading = false,
    this.error,
  });

  RelationshipAnalysisState copyWith({
    Relative? selectedRelative,
    RelationshipAnalysis? analysis,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearRelative = false,
    bool clearAnalysis = false,
  }) {
    return RelationshipAnalysisState(
      selectedRelative: clearRelative ? null : (selectedRelative ?? this.selectedRelative),
      analysis: clearAnalysis ? null : (analysis ?? this.analysis),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Relationship analysis provider
class RelationshipAnalysisNotifier extends StateNotifier<RelationshipAnalysisState> {
  final DeepSeekAIService _aiService;

  RelationshipAnalysisNotifier(this._aiService) : super(const RelationshipAnalysisState());

  void selectRelative(Relative? relative) {
    state = state.copyWith(
      selectedRelative: relative,
      clearRelative: relative == null,
      clearAnalysis: true,
      clearError: true,
    );
  }

  Future<void> analyzeRelationship() async {
    if (state.selectedRelative == null) {
      state = state.copyWith(error: 'يرجى اختيار أحد الأقارب أولاً');
      return;
    }

    // Check cache first for instant loading
    final preloadService = AIPreloadService();
    final cachedAnalysis = preloadService.getCachedAnalysis(state.selectedRelative!.id);
    if (cachedAnalysis != null) {
      state = state.copyWith(
        analysis: cachedAnalysis,
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final analysis = await _aiService.analyzeRelationship(
        relative: state.selectedRelative!,
      );

      if (!mounted) return;

      state = state.copyWith(
        analysis: analysis,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'حدث خطأ في تحليل العلاقة: ${e.toString()}',
      );
    }
  }

  void reset() {
    state = const RelationshipAnalysisState();
  }
}

/// Provider for relationship analysis
final relationshipAnalysisProvider =
    StateNotifierProvider.autoDispose<RelationshipAnalysisNotifier, RelationshipAnalysisState>((ref) {
  final aiService = DeepSeekAIService();
  return RelationshipAnalysisNotifier(aiService);
});

/// Screen for AI-powered relationship analysis
class RelationshipAnalysisScreen extends ConsumerWidget {
  const RelationshipAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(relationshipAnalysisProvider);
    final themeColors = ref.watch(themeColorsProvider);

    return Scaffold(
      backgroundColor: themeColors.background1,
      appBar: AppBar(
        backgroundColor: themeColors.background1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'تحليل العلاقات',
          style: AppTypography.headlineSmall.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          if (state.selectedRelative != null && state.analysis != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
              onPressed: () => ref.read(relationshipAnalysisProvider.notifier).analyzeRelationship(),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Relative selector
              RelativeSelector(
                selectedRelativeId: state.selectedRelative?.id,
                onChanged: (relative) {
                  ref.read(relationshipAnalysisProvider.notifier).selectRelative(relative);
                },
                hintText: 'اختر القريب للتحليل',
              ),

              const SizedBox(height: AppSpacing.lg),

              // Analyze button
              _AnalyzeButton(
                isEnabled: state.selectedRelative != null,
                isLoading: state.isLoading,
                themeColors: themeColors,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ref.read(relationshipAnalysisProvider.notifier).analyzeRelationship();
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // Results area
              _buildResultsArea(context, ref, state, themeColors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsArea(
    BuildContext context,
    WidgetRef ref,
    RelationshipAnalysisState state,
    ThemeColors themeColors,
  ) {
    // Error state
    if (state.error != null) {
      return AIErrorCard(
        error: state.error!,
        onRetry: () {
          ref.read(relationshipAnalysisProvider.notifier).analyzeRelationship();
        },
      );
    }

    // Loading state
    if (state.isLoading) {
      return AIEngagingLoader(
        emoji: '🔍',
        messages: [
          '${AIIdentity.name} يحلل العلاقة...',
          'يفحص نمط التواصل...',
          'يستخرج ملاحظات ذكية...',
          'يجهز نصائح مخصصة...',
          'لحظات وتظهر النتائج...',
        ],
        accentColor: themeColors.accent,
      );
    }

    // No results yet
    if (state.analysis == null) {
      return _buildEmptyState(themeColors);
    }

    // Results
    final analysis = state.analysis!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Health score header
        _buildHealthScoreCard(state.selectedRelative!, themeColors),

        const SizedBox(height: AppSpacing.md),

        // Summary
        _buildSummaryCard(analysis.summary, themeColors)
            .animate()
            .fadeIn(delay: 100.ms)
            .slideY(begin: 0.1, end: 0),

        const SizedBox(height: AppSpacing.md),

        // Alerts (if any)
        if (analysis.alerts.isNotEmpty) ...[
          ...analysis.alerts.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _buildAlertCard(entry.value, themeColors)
                  .animate(delay: Duration(milliseconds: 150 + entry.key * 100))
                  .fadeIn()
                  .slideX(begin: 0.1, end: 0),
            );
          }),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Insights section
        if (analysis.insights.isNotEmpty) ...[
          Text(
            'ملاحظات ذكية',
            style: AppTypography.titleSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...analysis.insights.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _buildInsightCard(entry.value, themeColors)
                  .animate(delay: Duration(milliseconds: 200 + entry.key * 100))
                  .fadeIn()
                  .slideY(begin: 0.1, end: 0),
            );
          }),
          const SizedBox(height: AppSpacing.md),
        ],

        // Suggestions section
        if (analysis.suggestions.isNotEmpty) ...[
          Text(
            'اقتراحات عملية',
            style: AppTypography.titleSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...analysis.suggestions.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _buildSuggestionCard(entry.value, themeColors)
                  .animate(delay: Duration(milliseconds: 300 + entry.key * 100))
                  .fadeIn()
                  .slideY(begin: 0.1, end: 0),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildEmptyState(ThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'اختر أحد أقاربك لتحليل العلاقة',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'سيقدم لك ${AIIdentity.name} نصائح مخصصة لتقوية علاقتك',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white38,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard(Relative relative, ThemeColors themeColors) {
    final healthScore = relative.healthScore ?? 50;
    final healthStatus = relative.healthStatus2;

    Color scoreColor;
    String statusText;
    IconData statusIcon;

    switch (healthStatus) {
      case RelationshipHealthStatus.healthy:
        scoreColor = Colors.green;
        statusText = 'علاقة صحية';
        statusIcon = Icons.favorite_rounded;
      case RelationshipHealthStatus.needsAttention:
        scoreColor = Colors.orange;
        statusText = 'تحتاج اهتمام';
        statusIcon = Icons.warning_amber_rounded;
      case RelationshipHealthStatus.atRisk:
        scoreColor = Colors.red;
        statusText = 'معرضة للخطر';
        statusIcon = Icons.error_outline_rounded;
      case RelationshipHealthStatus.unknown:
        scoreColor = Colors.grey;
        statusText = 'غير محددة';
        statusIcon = Icons.help_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scoreColor.withValues(alpha: 0.3),
            scoreColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: scoreColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Score circle
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scoreColor.withValues(alpha: 0.2),
              border: Border.all(color: scoreColor, width: 3),
            ),
            child: Center(
              child: Text(
                '$healthScore%',
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: scoreColor, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      statusText,
                      style: AppTypography.titleSmall.copyWith(
                        color: scoreColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  relative.fullName,
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                ),
                Text(
                  relative.relationshipType.arabicName,
                  style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String summary, ThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: themeColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: themeColors.primaryLight.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📝', style: const TextStyle(fontSize: 24)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              summary,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white,
                height: 1.5,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(AnalysisAlert alert, ThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(alert.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              alert.message,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(AnalysisInsight insight, ThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(insight.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(AnalysisSuggestion suggestion, ThemeColors themeColors) {
    Color priorityColor;
    switch (suggestion.priority) {
      case 'high':
        priorityColor = Colors.orange;
      case 'low':
        priorityColor = Colors.grey;
      default:
        priorityColor = themeColors.accent;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: priorityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: priorityColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(suggestion.icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        suggestion.title,
                        style: AppTypography.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (suggestion.priority == 'high')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'مهم',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.orange,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  suggestion.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Analyze button
class _AnalyzeButton extends StatelessWidget {
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onPressed;
  final ThemeColors themeColors;

  const _AnalyzeButton({
    required this.isEnabled,
    required this.isLoading,
    required this.onPressed,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled && !isLoading ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          gradient: isEnabled
              ? LinearGradient(
                  colors: [
                    themeColors.accent.withValues(alpha: 0.5),
                    themeColors.accent.withValues(alpha: 0.3),
                  ],
                )
              : null,
          color: isEnabled ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isEnabled
                ? themeColors.accent.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ] else ...[
              Icon(
                Icons.psychology_rounded,
                color: isEnabled ? Colors.white : Colors.white38,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(
              isLoading ? 'جاري التحليل...' : 'حلل العلاقة',
              style: AppTypography.titleMedium.copyWith(
                color: isEnabled ? Colors.white : Colors.white38,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
