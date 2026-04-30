import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/widgets/directional_icon.dart';

import '../../../core/ai/ai_identity.dart';
import '../../../core/ai/ai_models.dart';
import '../../../core/ai/ai_prompts.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/utils/relationship_label_helper.dart';
import '../../../shared/widgets/ai_generated_badge.dart';
import '../../../shared/widgets/glass_pill_title.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../home/providers/home_providers.dart';
import '../providers/ai_chat_provider.dart';
import '../providers/weekly_report_stats_provider.dart';
import '../widgets/markdown_styles.dart';

/// Weekly AI Report Screen
class WeeklyReportScreen extends ConsumerStatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  ConsumerState<WeeklyReportScreen> createState() =>
      _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends ConsumerState<WeeklyReportScreen>
    with TickerProviderStateMixin {
  bool _isGeneratingReport = false;
  String? _aiInsight;
  String? _weeklyTip;

  late AnimationController _glowController;
  late Animation<double> _glowIntensity;

  static const _cacheKeyInsight = 'weekly_report_insight';
  static const _cacheKeyTip = 'weekly_report_tip';
  static const _cacheKeyTimestamp = 'weekly_report_ts';

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
    _loadOrGenerateReport();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  /// Load cached report if fresh (< 7 days), otherwise generate new one.
  Future<void> _loadOrGenerateReport() async {
    setState(() => _isGeneratingReport = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedTs = prefs.getInt(_cacheKeyTimestamp);

      if (cachedTs != null) {
        final age = DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(cachedTs));
        if (age.inDays < 7) {
          final insight = prefs.getString(_cacheKeyInsight);
          final tip = prefs.getString(_cacheKeyTip);
          if (insight != null && tip != null && mounted) {
            setState(() {
              _aiInsight = insight;
              _weeklyTip = tip;
              _isGeneratingReport = false;
            });
            return;
          }
        }
      }
    } catch (_) {
      // Fall through to generate
    }

    await _generateAIInsights();
  }

  Future<void> _generateAIInsights() async {
    if (!_isGeneratingReport && mounted) {
      setState(() => _isGeneratingReport = true);
    }

    try {
      final aiService = ref.read(aiServiceProvider);
      final relatives = ref.read(viewerFilteredRelativesProvider).valueOrNull ?? [];

      if (relatives.isEmpty) {
        setState(() {
          _aiInsight =
              'أضف أقاربك لتحصل على تقرير مفصل عن علاقاتك العائلية.';
          _weeklyTip =
              'ابدأ بإضافة والديك وإخوتك، ثم توسع لباقي العائلة.';
          _isGeneratingReport = false;
        });
        return;
      }

      // Build context with second-person labels (عمك instead of عمي)
      final labels = ref.read(perspectiveLabelsProvider);
      final relativesContext = relatives.take(10).map((r) {
        final firstPerson = labels[r.id] ?? r.relationshipType.arabicName;
        final label = toSecondPerson(firstPerson);
        final lastContact = r.lastContactDate;
        final daysSince = lastContact != null
            ? DateTime.now().difference(lastContact).inDays
            : 999;
        return '${r.fullName} ($label): آخر تواصل قبل $daysSince يوم';
      }).join('\n');

      // Use dynamic personality from admin config
      final personality = AIPrompts.dynamicPersonality;

      final prompt = '''
أنت مساعد ذكي لصلة الرحم. بناءً على معلومات الأقارب التالية، اكتب تقرير أسبوعي قصير (3-4 جمل) عن حالة صلة الرحم.

$personality

$relativesContext

ركز على:
- خاطب المستخدم بصيغة المخاطب (أنت/ك) وليس المتكلم (أنا/ي)
- من يحتاج تواصل عاجل
- إنجازات الأسبوع إن وجدت
- تشجيع بسيط
''';

      final tipPrompt = '''
اكتب نصيحة واحدة قصيرة (جملة أو جملتين) عن صلة الرحم.

$personality

النصيحة تكون عملية وسهلة التطبيق. خاطب المستخدم بصيغة المخاطب (أنت).
''';

      final uuid = const Uuid();
      // Use dynamic personality for system prompts
      final systemPrompt =
          'أنت مساعد ذكي لصلة الرحم.\n\n$personality';

      final insight = await aiService.getChatCompletion(
        messages: [
          ChatMessage(
            id: uuid.v4(),
            conversationId: 'weekly-report',
            userId: 'system',
            role: MessageRole.user,
            content: prompt,
            createdAt: DateTime.now(),
          ),
        ],
        systemPrompt: systemPrompt,
        maxTokens: 500,
      );
      final tip = await aiService.getChatCompletion(
        messages: [
          ChatMessage(
            id: uuid.v4(),
            conversationId: 'weekly-report',
            userId: 'system',
            role: MessageRole.user,
            content: tipPrompt,
            createdAt: DateTime.now(),
          ),
        ],
        systemPrompt: systemPrompt,
        maxTokens: 200,
      );

      if (mounted) {
        setState(() {
          _aiInsight = insight;
          _weeklyTip = tip;
          _isGeneratingReport = false;
        });

        // Cache results for the week
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cacheKeyInsight, insight);
          await prefs.setString(_cacheKeyTip, tip);
          await prefs.setInt(
            _cacheKeyTimestamp,
            DateTime.now().millisecondsSinceEpoch,
          );
        } catch (_) {
          // Cache write failure is not critical
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiInsight = 'تعذر إنشاء التقرير. حاول مرة أخرى.';
          _weeklyTip = 'صلة الرحم تزيد في الرزق والعمر.';
          _isGeneratingReport = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);
    final statsAsync = ref.watch(detailedStatsProvider);
    final relativesAsync = ref.watch(viewerFilteredRelativesProvider);

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(animated: true, child: SizedBox.expand()),
          // Ambient orbs
          _buildAmbientOrbs(themeColors),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, themeColors),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                        // AI Weekly Summary
                        _buildAISummaryCard(themeColors),
                        const SizedBox(height: AppSpacing.lg),

                        // Weekly Stats
                        statsAsync.when(
                          data: (stats) =>
                              _buildWeeklyStats(themeColors, stats),
                          loading: () => _buildLoadingCard(themeColors),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Top Connections This Week
                        relativesAsync.when(
                          data: (relatives) =>
                              _buildTopConnections(themeColors, relatives),
                          loading: () => _buildLoadingCard(themeColors),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Weekly Tip
                        _buildWeeklyTip(themeColors),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
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

  Widget _buildHeader(BuildContext context, ThemeColors themeColors) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const DirectionalIcon(Icons.arrow_back_ios_rounded,
                color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: GlassPillTitle(
              text: 'التقرير الأسبوعي',
              style: AppTypography.headlineSmall.copyWith(
                color: themeColors.textOnGradient,
                fontWeight: FontWeight.bold,
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      themeColors.primary,
                      themeColors.primaryLight,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          themeColors.primary.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              subtitle: Text(
                'ملخص صلة الرحم',
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
            ),
          ),
          if (_isGeneratingReport)
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: themeColors.primary,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildAISummaryCard(ThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeColors.primary.withValues(alpha: 0.3),
            Colors.black.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: themeColors.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: themeColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon badge with glow halo
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      themeColors.primary.withValues(alpha: 0.5),
                      themeColors.primary.withValues(alpha: 0.2),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          themeColors.primary.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                    BoxShadow(
                      color:
                          themeColors.primary.withValues(alpha: 0.25),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'ملخص ${AIIdentity.name}',
                style: AppTypography.titleMedium.copyWith(
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
              const SizedBox(width: AppSpacing.sm),
              const AIGeneratedBadge(color: Colors.white),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_isGeneratingReport)
            _buildTypingIndicator(themeColors)
          else
            Directionality(
              textDirection: TextDirection.rtl,
              child: MarkdownBody(
                data: _aiInsight ?? 'جاري تحليل بياناتك...',
                styleSheet: buildCardMarkdownStyle(context),
                selectable: true,
                softLineBreak: true,
              ),
            ),
        ],
      ),
    ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1);
  }

  Widget _buildTypingIndicator(ThemeColors themeColors) {
    return Row(
      children: [
        ...List.generate(
          3,
          (index) => Container(
            margin: const EdgeInsets.only(right: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: themeColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: themeColors.primary.withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          )
              .animate(
                onPlay: (c) => c.repeat(),
                delay: Duration(milliseconds: index * 200),
              )
              .fadeIn(duration: 300.ms)
              .then()
              .fadeOut(duration: 300.ms),
        ),
        const SizedBox(width: 8),
        Text(
          'جاري التحليل...',
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white54,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyStats(ThemeColors themeColors, DetailedStats stats) {
    // Aggregate raw interaction records by day
    final Map<String, int> dailyCounts = {};
    for (final interaction in stats.recentActivity) {
      final dateValue = interaction['date'];
      if (dateValue != null) {
        final dateStr = dateValue.toString().split('T')[0];
        dailyCounts[dateStr] = (dailyCounts[dateStr] ?? 0) + 1;
      }
    }

    final weeklyInteractions =
        dailyCounts.values.fold(0, (sum, c) => sum + c);
    final avgPerDay = dailyCounts.isNotEmpty
        ? (weeklyInteractions / dailyCounts.length).toStringAsFixed(1)
        : '0';

    final currentStreak = stats.userStats['current_streak'] ?? 0;

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
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إحصائيات الأسبوع',
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
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '📞',
                  weeklyInteractions.toString(),
                  'تواصل',
                  Colors.green,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildStatItem(
                  '📊',
                  avgPerDay,
                  'معدل يومي',
                  Colors.blue,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildStatItem(
                  '🔥',
                  currentStreak.toString(),
                  'أيام متتالية',
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1);
  }

  Widget _buildStatItem(
      String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.2),
            Colors.black.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          top: BorderSide(color: color.withValues(alpha: 0.5), width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: TextStyle(
              fontSize: 24,
              shadows: [
                Shadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.headlineSmall.copyWith(
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
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
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
    );
  }

  Widget _buildTopConnections(
      ThemeColors themeColors, List<Relative> relatives) {
    // Sort by most recent contact
    final sortedRelatives = [...relatives];
    sortedRelatives.sort((a, b) {
      final aDate = a.lastContactDate ?? DateTime(2000);
      final bDate = b.lastContactDate ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    final topThree = sortedRelatives.take(3).toList();

    if (topThree.isEmpty) return const SizedBox.shrink();

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
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'أكثر من تواصلت معهم',
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
          const SizedBox(height: AppSpacing.md),
          ...topThree.asMap().entries.map((entry) {
            final index = entry.key;
            final relative = entry.value;
            final medal = index == 0
                ? '🥇'
                : index == 1
                    ? '🥈'
                    : '🥉';

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Text(
                    medal,
                    style: TextStyle(
                      fontSize: 20,
                      shadows: [
                        Shadow(
                          color:
                              Colors.amber.withValues(alpha: 0.6),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    relative.displayEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          relative.fullName,
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Colors.black
                                    .withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          ref.read(perspectiveLabelsProvider)[relative.id] ??
                              relative.relationshipType.arabicName,
                          style: AppTypography.labelSmall.copyWith(
                            color:
                                Colors.white.withValues(alpha: 0.7),
                            shadows: [
                              Shadow(
                                color: Colors.black
                                    .withValues(alpha: 0.4),
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
            );
          }),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1);
  }

  Widget _buildWeeklyTip(ThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.shade800.withValues(alpha: 0.3),
            Colors.black.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Lightbulb with amber glow halo
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.withValues(alpha: 0.4),
                      Colors.amber.withValues(alpha: 0.15),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.25),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('💡', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'نصيحة الأسبوع',
                style: AppTypography.titleMedium.copyWith(
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
              const SizedBox(width: AppSpacing.sm),
              const AIGeneratedBadge(color: Colors.white),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_isGeneratingReport)
            Text(
              'جاري التحميل...',
              style: AppTypography.bodyMedium
                  .copyWith(color: Colors.white70),
            )
          else
            Directionality(
              textDirection: TextDirection.rtl,
              child: MarkdownBody(
                data: _weeklyTip ??
                    'صلة الرحم تزيد في الرزق وتبارك في العمر.',
                styleSheet: buildCardMarkdownStyle(context),
                selectable: true,
                softLineBreak: true,
              ),
            ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1);
  }

  Widget _buildLoadingCard(ThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(color: themeColors.primary),
      ),
    );
  }
}
