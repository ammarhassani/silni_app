import 'dart:async';
import '../../../shared/widgets/directional_icon.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/ai_identity.dart';
import '../../../core/ai/ai_models.dart';
import '../../../core/ai/deepseek_ai_service.dart';
import '../../../core/services/ai_config_service.dart';
import '../../../core/constants/app_breakpoints.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/widgets/ai_generated_badge.dart';
import '../../../shared/widgets/glass_pill_title.dart';
import '../../../shared/widgets/glass_dialog.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../home/providers/home_providers.dart';
import '../providers/ai_chat_provider.dart';
import '../widgets/ai_error_card.dart';
import '../widgets/ai_loading_indicator.dart';
import '../../../shared/utils/ui_helpers.dart';

/// Communication scenario template - now driven by admin config
class ScenarioTemplate {
  final String id;
  final String title;
  final String description;
  final String? promptContext;
  final String emoji;
  final Color color;

  const ScenarioTemplate({
    required this.id,
    required this.title,
    required this.description,
    this.promptContext,
    required this.emoji,
    required this.color,
  });

  /// Get templates from AIConfigService (dynamic from admin panel)
  static List<ScenarioTemplate> get templates {
    return AIConfigService.instance.communicationScenarios.map((scenario) {
      return ScenarioTemplate(
        id: scenario.scenarioKey,
        title: scenario.titleAr,
        description: scenario.descriptionAr,
        promptContext: scenario.promptContext,
        emoji: scenario.emoji,
        color: _parseColor(scenario.colorHex),
      );
    }).toList();
  }

  /// Parse hex color string to Color
  static Color _parseColor(String hexColor) {
    final hex = hexColor.replaceFirst('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return Colors.blue; // fallback
  }
}

/// State for communication scripts
class CommunicationScriptsState {
  final ScenarioTemplate? selectedScenario;
  final Relative? selectedRelative;
  final CommunicationScript? generatedScript;
  final bool isLoading;
  final String? error;
  final List<Relative> relatives;

  const CommunicationScriptsState({
    this.selectedScenario,
    this.selectedRelative,
    this.generatedScript,
    this.isLoading = false,
    this.error,
    this.relatives = const [],
  });

  CommunicationScriptsState copyWith({
    ScenarioTemplate? selectedScenario,
    Relative? selectedRelative,
    CommunicationScript? generatedScript,
    bool? isLoading,
    String? error,
    List<Relative>? relatives,
    bool clearScript = false,
    bool clearError = false,
  }) {
    return CommunicationScriptsState(
      selectedScenario: selectedScenario ?? this.selectedScenario,
      selectedRelative: selectedRelative ?? this.selectedRelative,
      generatedScript: clearScript ? null : (generatedScript ?? this.generatedScript),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      relatives: relatives ?? this.relatives,
    );
  }
}

/// Communication scripts notifier
class CommunicationScriptsNotifier extends StateNotifier<CommunicationScriptsState> {
  final DeepSeekAIService _aiService;

  CommunicationScriptsNotifier(this._aiService, List<Relative> relatives)
      : super(CommunicationScriptsState(relatives: relatives));

  void selectScenario(ScenarioTemplate scenario) {
    state = state.copyWith(
      selectedScenario: scenario,
      clearScript: true,
      clearError: true,
    );
  }

  void selectRelative(Relative? relative) {
    state = state.copyWith(
      selectedRelative: relative,
      clearScript: true,
    );
  }

  Future<void> generateScript() async {
    if (state.selectedScenario == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Use promptContext from admin config if available, otherwise fall back to description
      final additionalContext = state.selectedScenario!.promptContext ?? state.selectedScenario!.description;

      final script = await _aiService.getCommunicationScript(
        scenario: state.selectedScenario!.title,
        relative: state.selectedRelative,
        additionalContext: additionalContext,
        scenarioKey: state.selectedScenario!.id,
      );

      if (!mounted) return;

      state = state.copyWith(
        generatedScript: script,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'حدث خطأ في إنشاء السيناريو',
      );
    }
  }

  void reset() {
    state = CommunicationScriptsState(relatives: state.relatives);
  }
}

/// Provider for communication scripts
final communicationScriptsProvider =
    StateNotifierProvider.autoDispose<CommunicationScriptsNotifier, CommunicationScriptsState>((ref) {
  final aiService = DeepSeekAIService();
  final relatives = ref.watch(viewerFilteredRelativesProvider).valueOrNull ?? [];
  return CommunicationScriptsNotifier(aiService, relatives);
});

/// Communication Scripts Screen
class CommunicationScriptsScreen extends ConsumerStatefulWidget {
  const CommunicationScriptsScreen({super.key});

  @override
  ConsumerState<CommunicationScriptsScreen> createState() =>
      _CommunicationScriptsScreenState();
}

class _CommunicationScriptsScreenState
    extends ConsumerState<CommunicationScriptsScreen>
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
    final state = ref.watch(communicationScriptsProvider);
    final themeColors = ref.watch(themeColorsProvider);

    return GradientBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Center(
            child: GlassIconButton(
              tooltip: 'رجوع',
              icon: DirectionalIcon(
                Icons.arrow_back_ios_rounded,
                color: themeColors.textOnGradient,
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: GlassPillTitle(
          text: 'سيناريوهات التواصل',
          style: AppTypography.headlineSmall.copyWith(
            color: themeColors.textOnGradient,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (state.generatedScript != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Center(
                child: GlassIconButton(
                  tooltip: 'البدء من جديد',
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: themeColors.textOnGradient,
                    size: 20,
                  ),
                  onPressed: () =>
                      ref.read(communicationScriptsProvider.notifier).reset(),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient orbs
            _buildAmbientOrbs(themeColors),
            // Content
            _buildContent(context, ref, state, themeColors),
          ],
        ),
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

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    CommunicationScriptsState state,
    ThemeColors themeColors,
  ) {
    // Error state
    if (state.error != null && state.generatedScript == null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: AIErrorCard(
          error: state.error!,
          onRetry: () =>
              ref.read(communicationScriptsProvider.notifier).generateScript(),
        ),
      );
    }

    // Loading state
    if (state.isLoading) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: AIEngagingLoader(
          emoji: '📝',
          messages: [
            '${AIIdentity.name} يجهز السيناريو...',
            'يحلل الموقف...',
            'يصيغ العبارات المناسبة...',
            'يختار الكلمات بعناية...',
            'لحظات ويجهز...',
          ],
          accentColor: themeColors.accent,
        ),
      );
    }

    // Show generated script
    if (state.generatedScript != null) {
      return _ScriptResultView(
        script: state.generatedScript!,
        scenario: state.selectedScenario!,
        relative: state.selectedRelative,
        themeColors: themeColors,
      );
    }

    // Scenario selection
    return _ScenarioSelectionView(
      state: state,
      themeColors: themeColors,
      onGenerate: () =>
          ref.read(communicationScriptsProvider.notifier).generateScript(),
    );
  }
}

/// Scenario selection view
class _ScenarioSelectionView extends ConsumerWidget {
  const _ScenarioSelectionView({
    required this.state,
    required this.themeColors,
    required this.onGenerate,
  });

  final CommunicationScriptsState state;
  final ThemeColors themeColors;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Header
        Text(
          'اختر نوع السيناريو',
          style: AppTypography.titleMedium.copyWith(
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
        Text(
          '${AIIdentity.name} يساعدك تصيغ كلامك بشكل مناسب',
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Scenario grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: AppBreakpoints.gridColumns(context),
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.2,
          ),
          itemCount: ScenarioTemplate.templates.length,
          itemBuilder: (context, index) {
            final scenario = ScenarioTemplate.templates[index];
            final isSelected = state.selectedScenario?.id == scenario.id;

            return _ScenarioCard(
              scenario: scenario,
              isSelected: isSelected,
              onTap: () {
                HapticFeedback.lightImpact();
                ref
                    .read(communicationScriptsProvider.notifier)
                    .selectScenario(scenario);
              },
            )
                .animate(delay: Duration(milliseconds: index * 50))
                .fadeIn()
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                );
          },
        ),

        const SizedBox(height: AppSpacing.xl),

        // Relative selector (optional)
        if (state.selectedScenario != null && state.relatives.isNotEmpty) ...[
          Text(
            'اختر القريب (اختياري)',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: DropdownButton<String?>(
              value: state.selectedRelative?.id,
              hint: Text(
                'بدون تحديد قريب',
                style: AppTypography.bodyMedium
                    .copyWith(color: Colors.white60),
              ),
              dropdownColor: themeColors.background2,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white54),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    'بدون تحديد قريب',
                    style: AppTypography.bodyMedium
                        .copyWith(color: Colors.white60),
                  ),
                ),
                ...state.relatives.map((relative) {
                  final labels = ref.read(perspectiveLabelsProvider);
                  final label = labels[relative.id] ??
                      relative.relationshipType.arabicName;
                  return DropdownMenuItem<String?>(
                    value: relative.id,
                    child: Text(
                      '${relative.fullName} ($label)',
                      style: AppTypography.bodyMedium
                          .copyWith(color: Colors.white),
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                final relative = value != null
                    ? state.relatives.firstWhere((r) => r.id == value)
                    : null;
                ref
                    .read(communicationScriptsProvider.notifier)
                    .selectRelative(relative);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Generate button
        if (state.selectedScenario != null)
          GestureDetector(
            onTap: onGenerate,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    state.selectedScenario!.color.withValues(alpha: 0.6),
                    state.selectedScenario!.color.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color:
                      state.selectedScenario!.color.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: state.selectedScenario!.color
                        .withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: state.selectedScenario!.color
                        .withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.25),
                          Colors.white.withValues(alpha: 0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: state.selectedScenario!.color
                              .withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'اكتب السيناريو',
                    style: AppTypography.labelLarge.copyWith(
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
                ],
              ),
            ),
          ).animate().fadeIn().slideY(begin: 0.2, end: 0),
      ],
    );
  }
}

/// Scenario card widget
class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.scenario,
    required this.isSelected,
    required this.onTap,
  });

  final ScenarioTemplate scenario;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scenario.color.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected
                ? scenario.color.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: scenario.color.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: scenario.color.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              scenario.emoji,
              style: TextStyle(
                fontSize: 32,
                shadows: [
                  Shadow(
                    color: scenario.color.withValues(alpha: 0.6),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              scenario.title,
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 8,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text(
                scenario.description,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Script result view
class _ScriptResultView extends StatelessWidget {
  const _ScriptResultView({
    required this.script,
    required this.scenario,
    required this.relative,
    required this.themeColors,
  });

  final CommunicationScript script;
  final ScenarioTemplate scenario;
  final Relative? relative;
  final ThemeColors themeColors;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scenario.color.withValues(alpha: 0.35),
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: scenario.color.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: scenario.color.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Emoji with glow halo
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      scenario.color.withValues(alpha: 0.4),
                      scenario.color.withValues(alpha: 0.15),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scenario.color.withValues(alpha: 0.5),
                      blurRadius: 12,
                    ),
                    BoxShadow(
                      color: scenario.color.withValues(alpha: 0.25),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(scenario.emoji,
                      style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scenario.title,
                      style: AppTypography.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    if (relative != null)
                      Text(
                        'مع ${relative!.fullName}',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                    const AIGeneratedBadge(color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(),

        const SizedBox(height: AppSpacing.lg),

        // Opening
        _ScriptSection(
          title: 'جملة الافتتاح',
          icon: Icons.record_voice_over_rounded,
          color: Colors.green,
          content: script.opening,
          themeColors: themeColors,
        ).animate(delay: 100.ms).fadeIn().slideX(begin: 0.1, end: 0),

        const SizedBox(height: AppSpacing.md),

        // Key points
        _ScriptSection(
          title: 'النقاط الرئيسية',
          icon: Icons.list_alt_rounded,
          color: Colors.blue,
          items: script.keyPoints,
          themeColors: themeColors,
        ).animate(delay: 200.ms).fadeIn().slideX(begin: 0.1, end: 0),

        const SizedBox(height: AppSpacing.md),

        // Phrases to use
        _ScriptSection(
          title: 'عبارات مفيدة',
          icon: Icons.check_circle_rounded,
          color: Colors.teal,
          items: script.phrasesToUse,
          themeColors: themeColors,
          isPositive: true,
        ).animate(delay: 300.ms).fadeIn().slideX(begin: 0.1, end: 0),

        const SizedBox(height: AppSpacing.md),

        // Phrases to avoid
        _ScriptSection(
          title: 'عبارات يجب تجنبها',
          icon: Icons.cancel_rounded,
          color: Colors.red,
          items: script.phrasesToAvoid,
          themeColors: themeColors,
          isNegative: true,
        ).animate(delay: 400.ms).fadeIn().slideX(begin: 0.1, end: 0),

        const SizedBox(height: AppSpacing.md),

        // Closing
        _ScriptSection(
          title: 'جملة الختام',
          icon: Icons.sentiment_satisfied_rounded,
          color: Colors.purple,
          content: script.closing,
          themeColors: themeColors,
        ).animate(delay: 500.ms).fadeIn().slideX(begin: 0.1, end: 0),

        const SizedBox(height: AppSpacing.xl),

        // Copy all button — neon gradient
        GestureDetector(
          onTap: () => _copyAllToClipboard(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  themeColors.primary.withValues(alpha: 0.5),
                  themeColors.primary.withValues(alpha: 0.25),
                ],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: themeColors.primary.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: themeColors.primary.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: themeColors.primary.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.copy_all_rounded, color: Colors.white, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'نسخ الكل',
                  style: AppTypography.labelLarge.copyWith(
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
              ],
            ),
          ),
        ).animate(delay: 600.ms).fadeIn(),
      ],
    );
  }

  void _copyAllToClipboard(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln('📝 ${scenario.title}');
    if (relative != null) {
      buffer.writeln('👤 مع ${relative!.fullName}');
    }
    buffer.writeln();
    buffer.writeln('🎤 جملة الافتتاح:');
    buffer.writeln(script.opening);
    buffer.writeln();
    buffer.writeln('📋 النقاط الرئيسية:');
    for (final point in script.keyPoints) {
      buffer.writeln('• $point');
    }
    buffer.writeln();
    buffer.writeln('✅ عبارات مفيدة:');
    for (final phrase in script.phrasesToUse) {
      buffer.writeln('• $phrase');
    }
    buffer.writeln();
    buffer.writeln('❌ عبارات يجب تجنبها:');
    for (final phrase in script.phrasesToAvoid) {
      buffer.writeln('• $phrase');
    }
    buffer.writeln();
    buffer.writeln('🎯 جملة الختام:');
    buffer.writeln(script.closing);

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    UIHelpers.showSnackBar(
      context,
      'تم نسخ السيناريو كاملاً',
      backgroundColor: themeColors.primary,
    );
  }
}

/// Script section widget
class _ScriptSection extends StatelessWidget {
  const _ScriptSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.themeColors,
    this.content,
    this.items,
    this.isPositive = false,
    this.isNegative = false,
  });

  final String title;
  final IconData icon;
  final Color color;
  final ThemeColors themeColors;
  final String? content;
  final List<String>? items;
  final bool isPositive;
  final bool isNegative;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            Colors.black.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              // Icon badge with glow halo
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.4),
                      color.withValues(alpha: 0.15),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              // Copy button
              IconButton(
                icon: const Icon(Icons.copy_rounded,
                    color: Colors.white54, size: 18),
                onPressed: () {
                  final text = content ?? items?.join('\n') ?? '';
                  Clipboard.setData(ClipboardData(text: text));
                  UIHelpers.showSnackBar(
                    context,
                    'تم النسخ',
                    backgroundColor: themeColors.primary,
                    duration: const Duration(seconds: 1),
                  );
                },
                tooltip: 'نسخ',
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Content
          if (content != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: SelectableText(
                content!,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  height: 1.5,
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

          // Items list
          if (items != null)
            ...items!.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isPositive
                            ? Icons.check_rounded
                            : isNegative
                                ? Icons.close_rounded
                                : Icons.circle,
                        color: isPositive
                            ? Colors.green
                            : isNegative
                                ? Colors.red
                                : Colors.white54,
                        size: isPositive || isNegative ? 18 : 8,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: SelectableText(
                          item,
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
                )),
        ],
      ),
    );
  }
}
