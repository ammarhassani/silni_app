import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/ai_identity.dart';
import '../../../core/ai/ai_models.dart';
import '../../../core/ai/deepseek_ai_service.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/services/ai_config_service.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/services/relatives_service.dart';
import '../../../shared/widgets/glass_card.dart';
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
  final RelativesService _relativesService;

  CommunicationScriptsNotifier(this._aiService, this._relativesService)
      : super(const CommunicationScriptsState()) {
    _loadRelatives();
  }

  Future<void> _loadRelatives() async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId == null) return;

      final relatives = await _relativesService
          .getRelativesStream(userId)
          .first
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => <Relative>[],
          );
      if (!mounted) return;
      state = state.copyWith(relatives: relatives);
    } catch (_) {
      // Ignore errors loading relatives
    }
  }

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
  final relativesService = RelativesService();
  return CommunicationScriptsNotifier(aiService, relativesService);
});

/// Communication Scripts Screen
class CommunicationScriptsScreen extends ConsumerWidget {
  const CommunicationScriptsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communicationScriptsProvider);
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
          'سيناريوهات التواصل',
          style: AppTypography.headlineSmall.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          if (state.generatedScript != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
              onPressed: () => ref.read(communicationScriptsProvider.notifier).reset(),
              tooltip: 'البدء من جديد',
            ),
        ],
      ),
      body: SafeArea(
        child: _buildContent(context, ref, state, themeColors),
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
          onRetry: () => ref.read(communicationScriptsProvider.notifier).generateScript(),
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
      onGenerate: () => ref.read(communicationScriptsProvider.notifier).generateScript(),
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
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${AIIdentity.name} يساعدك تصيغ كلامك بشكل مناسب',
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white60,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Scenario grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
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
                ref.read(communicationScriptsProvider.notifier).selectScenario(scenario);
              },
            ).animate(delay: Duration(milliseconds: index * 50)).fadeIn().scale(
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
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: DropdownButton<String?>(
              value: state.selectedRelative?.id,
              hint: Text(
                'بدون تحديد قريب',
                style: AppTypography.bodyMedium.copyWith(color: Colors.white60),
              ),
              dropdownColor: themeColors.background2,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    'بدون تحديد قريب',
                    style: AppTypography.bodyMedium.copyWith(color: Colors.white60),
                  ),
                ),
                ...state.relatives.map((relative) => DropdownMenuItem<String?>(
                      value: relative.id,
                      child: Text(
                        '${relative.fullName} (${relative.relationshipType.arabicName})',
                        style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                      ),
                    )),
              ],
              onChanged: (value) {
                final relative = value != null
                    ? state.relatives.firstWhere((r) => r.id == value)
                    : null;
                ref.read(communicationScriptsProvider.notifier).selectRelative(relative);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Generate button
        if (state.selectedScenario != null)
          ElevatedButton.icon(
            onPressed: onGenerate,
            style: ElevatedButton.styleFrom(
              backgroundColor: state.selectedScenario!.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(
              'اكتب السيناريو',
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
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
          color: isSelected
              ? scenario.color.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? scenario.color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(scenario.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              scenario.title,
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text(
                scenario.description,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white54,
                  fontSize: 11,
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
              colors: [
                scenario.color.withValues(alpha: 0.2),
                scenario.color.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            children: [
              Text(scenario.emoji, style: const TextStyle(fontSize: 32)),
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
                      ),
                    ),
                    if (relative != null)
                      Text(
                        'مع ${relative!.fullName}',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
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

        // Copy all button
        ElevatedButton.icon(
          onPressed: () => _copyAllToClipboard(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          icon: const Icon(Icons.copy_all_rounded),
          label: const Text('نسخ الكل'),
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
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Copy button
              IconButton(
                icon: Icon(Icons.copy_rounded, color: Colors.white38, size: 18),
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
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: SelectableText(
                content!,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  height: 1.5,
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
