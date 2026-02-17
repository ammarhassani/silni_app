import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
import '../../../shared/widgets/glass_pill_title.dart';
import '../providers/ai_chat_provider.dart';
import '../widgets/ai_error_card.dart';
import '../widgets/ai_loading_indicator.dart';
import '../widgets/markdown_styles.dart';
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
      selectedRelative:
          clearRelative ? null : (selectedRelative ?? this.selectedRelative),
      analysis: clearAnalysis ? null : (analysis ?? this.analysis),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Relationship analysis provider
class RelationshipAnalysisNotifier
    extends StateNotifier<RelationshipAnalysisState> {
  final DeepSeekAIService _aiService;

  RelationshipAnalysisNotifier(this._aiService)
      : super(const RelationshipAnalysisState());

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
    final cachedAnalysis =
        preloadService.getCachedAnalysis(state.selectedRelative!.id);
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
final relationshipAnalysisProvider = StateNotifierProvider.autoDispose<
    RelationshipAnalysisNotifier, RelationshipAnalysisState>((ref) {
  final aiService = DeepSeekAIService();
  return RelationshipAnalysisNotifier(aiService);
});

/// Screen for AI-powered relationship analysis
class RelationshipAnalysisScreen extends ConsumerStatefulWidget {
  const RelationshipAnalysisScreen({super.key});

  @override
  ConsumerState<RelationshipAnalysisScreen> createState() =>
      _RelationshipAnalysisScreenState();
}

class _RelationshipAnalysisScreenState
    extends ConsumerState<RelationshipAnalysisScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowIntensity;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowIntensity = Tween<double>(begin: 0.3, end: 0.55).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        title: GlassPillTitle(
          text: 'تحليل العلاقات',
          style: AppTypography.headlineSmall.copyWith(
            color: themeColors.textOnGradient,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (state.selectedRelative != null && state.analysis != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  color: Colors.white70),
              onPressed: () => ref
                  .read(relationshipAnalysisProvider.notifier)
                  .analyzeRelationship(),
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient orbs
            _buildAmbientOrbs(themeColors),
            // Content
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Relative selector
                  RelativeSelector(
                    selectedRelativeId: state.selectedRelative?.id,
                    onChanged: (relative) {
                      ref
                          .read(relationshipAnalysisProvider.notifier)
                          .selectRelative(relative);
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
                      ref
                          .read(relationshipAnalysisProvider.notifier)
                          .analyzeRelationship();
                    },
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Results area
                  _buildResultsArea(context, ref, state, themeColors),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmbientOrbs(ThemeColors themeColors) {
    return AnimatedBuilder(
      animation: _glowIntensity,
      builder: (context, _) => Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    themeColors.primary
                        .withValues(alpha: _glowIntensity.value * 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    themeColors.accent
                        .withValues(alpha: _glowIntensity.value * 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
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
          ref
              .read(relationshipAnalysisProvider.notifier)
              .analyzeRelationship();
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
                  .animate(delay: Duration(
                      milliseconds: 150 + entry.key * 100))
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
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...analysis.insights.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _buildInsightCard(entry.value, themeColors)
                  .animate(delay: Duration(
                      milliseconds: 200 + entry.key * 100))
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
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...analysis.suggestions.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _buildSuggestionCard(entry.value, themeColors)
                  .animate(delay: Duration(
                      milliseconds: 300 + entry.key * 100))
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
          // Icon with breathing glow halo
          AnimatedBuilder(
            animation: _glowIntensity,
            builder: (context, child) => Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    themeColors.accent.withValues(alpha: 0.15),
                    themeColors.accent.withValues(alpha: 0.05),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeColors.accent
                        .withValues(alpha: _glowIntensity.value * 0.3),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Icon(
                Icons.psychology_outlined,
                size: 44,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'اختر أحد أقاربك لتحليل العلاقة',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'سيقدم لك ${AIIdentity.name} نصائح مخصصة لتقوية علاقتك',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 6,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard(
      Relative relative, ThemeColors themeColors) {
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scoreColor.withValues(alpha: 0.3),
            Colors.black.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: scoreColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: scoreColor.withValues(alpha: 0.15),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Glowing score ring
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: _GlowingScoreRingPainter(
                score: healthScore,
                color: scoreColor,
                glowIntensity: _glowIntensity.value,
              ),
              child: Center(
                child: Text(
                  '$healthScore%',
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.7),
                        blurRadius: 8,
                      ),
                      Shadow(
                        color: scoreColor.withValues(alpha: 0.5),
                        blurRadius: 16,
                      ),
                    ],
                  ),
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
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  relative.fullName,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                Text(
                  ref.read(perspectiveLabelsProvider)[relative.id] ??
                      relative.relationshipType.arabicName,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildSummaryCard(String summary, ThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeColors.primary.withValues(alpha: 0.2),
            Colors.black.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: themeColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: themeColors.primary.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji with glow
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  themeColors.primary.withValues(alpha: 0.3),
                  themeColors.primary.withValues(alpha: 0.1),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: themeColors.primary.withValues(alpha: 0.4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Center(
              child: Text('📝', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: MarkdownBody(
                data: summary,
                styleSheet: buildCardMarkdownStyle(context),
                selectable: true,
                softLineBreak: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(
      AnalysisAlert alert, ThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red.withValues(alpha: 0.2),
            Colors.black.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji with red glow
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.red.withValues(alpha: 0.3),
                  Colors.red.withValues(alpha: 0.1),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child:
                  Text(alert.icon, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              alert.message,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
      AnalysisInsight insight, ThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.06),
            Colors.black.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: themeColors.accent.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji with glow badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  themeColors.accent.withValues(alpha: 0.25),
                  themeColors.accent.withValues(alpha: 0.08),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: themeColors.accent.withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Text(insight.icon,
                  style: const TextStyle(fontSize: 20)),
            ),
          ),
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
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
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

  Widget _buildSuggestionCard(
      AnalysisSuggestion suggestion, ThemeColors themeColors) {
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            priorityColor.withValues(alpha: 0.15),
            Colors.black.withValues(alpha: 0.45),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: priorityColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: priorityColor.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge with glow halo
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [
                  priorityColor.withValues(alpha: 0.35),
                  priorityColor.withValues(alpha: 0.1),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: priorityColor.withValues(alpha: 0.35),
                  blurRadius: 8,
                ),
                BoxShadow(
                  color: priorityColor.withValues(alpha: 0.15),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Text(suggestion.icon,
                style: const TextStyle(fontSize: 20)),
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
                          shadows: [
                            Shadow(
                              color:
                                  Colors.black.withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (suggestion.priority == 'high')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.withValues(alpha: 0.4),
                              Colors.orange.withValues(alpha: 0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange
                                  .withValues(alpha: 0.3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Text(
                          'مهم',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  suggestion.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
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

/// Analyze button with neon glow
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
                    themeColors.accent.withValues(alpha: 0.25),
                  ],
                )
              : null,
          color: isEnabled
              ? null
              : Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isEnabled
                ? themeColors.accent.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
            width: 1.5,
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color:
                        themeColors.accent.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color:
                        themeColors.accent.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
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
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isEnabled
                      ? LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.25),
                            Colors.white.withValues(alpha: 0.1),
                          ],
                        )
                      : null,
                  boxShadow: isEnabled
                      ? [
                          BoxShadow(
                            color: themeColors.accent
                                .withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  Icons.psychology_rounded,
                  color: isEnabled ? Colors.white : Colors.white38,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(
              isLoading ? 'جاري التحليل...' : 'حلل العلاقة',
              style: AppTypography.titleMedium.copyWith(
                color: isEnabled ? Colors.white : Colors.white38,
                fontWeight: FontWeight.bold,
                shadows: isEnabled
                    ? [
                        Shadow(
                          color:
                              Colors.black.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter for the glowing score ring
class _GlowingScoreRingPainter extends CustomPainter {
  final int score;
  final Color color;
  final double glowIntensity;

  _GlowingScoreRingPainter({
    required this.score,
    required this.color,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final sweepAngle = (score / 100) * 2 * pi;
    const startAngle = -pi / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Glow layer (wider, blurred)
    final glowPaint = Paint()
      ..color = color.withValues(alpha: glowIntensity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      glowPaint,
    );

    // Main arc
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_GlowingScoreRingPainter oldDelegate) =>
      oldDelegate.score != score ||
      oldDelegate.color != color ||
      oldDelegate.glowIntensity != glowIntensity;
}
