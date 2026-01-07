import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/ai/ai_identity.dart';
import '../../../core/ai/ai_models.dart';
import '../../../core/ai/ai_prompts.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../gamification/providers/stats_provider.dart';
import '../providers/ai_chat_provider.dart';

/// Weekly AI Report Screen
class WeeklyReportScreen extends ConsumerStatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  ConsumerState<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends ConsumerState<WeeklyReportScreen> {
  bool _isGeneratingReport = false;
  String? _aiInsight;
  String? _weeklyTip;

  @override
  void initState() {
    super.initState();
    _generateAIInsights();
  }

  Future<void> _generateAIInsights() async {
    setState(() => _isGeneratingReport = true);

    try {
      final aiService = ref.read(aiServiceProvider);
      final relatives = ref.read(aiRelativesProvider).valueOrNull ?? [];

      if (relatives.isEmpty) {
        setState(() {
          _aiInsight = 'أضف أقاربك لتحصل على تقرير مفصل عن علاقاتك العائلية.';
          _weeklyTip = 'ابدأ بإضافة والديك وإخوتك، ثم توسع لباقي العائلة.';
          _isGeneratingReport = false;
        });
        return;
      }

      // Generate weekly insight
      final relativesContext = relatives.take(10).map((r) {
        final lastContact = r.lastContactDate;
        final daysSince = lastContact != null
            ? DateTime.now().difference(lastContact).inDays
            : 999;
        return '${r.fullName} (${r.relationshipType.arabicName}): آخر تواصل قبل $daysSince يوم';
      }).join('\n');

      // Use dynamic personality from admin config
      final personality = AIPrompts.dynamicPersonality;

      final prompt = '''
أنت مساعد ذكي لصلة الرحم. بناءً على معلومات الأقارب التالية، اكتب تقرير أسبوعي قصير (3-4 جمل) عن حالة صلة الرحم.

$personality

$relativesContext

ركز على:
- من يحتاج تواصل عاجل
- إنجازات الأسبوع إن وجدت
- تشجيع بسيط
''';

      final tipPrompt = '''
اكتب نصيحة واحدة قصيرة (جملة أو جملتين) عن صلة الرحم.

$personality

النصيحة تكون عملية وسهلة التطبيق.
''';

      final uuid = const Uuid();
      // Use dynamic personality for system prompts
      final systemPrompt = 'أنت مساعد ذكي لصلة الرحم.\n\n$personality';

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
    final relativesAsync = ref.watch(aiRelativesProvider);

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(animated: true, child: SizedBox.expand()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, themeColors),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _generateAIInsights,
                    color: themeColors.primary,
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        // AI Weekly Summary
                        _buildAISummaryCard(themeColors),
                        const SizedBox(height: AppSpacing.lg),

                        // Weekly Stats
                        statsAsync.when(
                          data: (stats) => _buildWeeklyStats(themeColors, stats),
                          loading: () => _buildLoadingCard(themeColors),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Top Connections This Week
                        relativesAsync.when(
                          data: (relatives) =>
                              _buildTopConnections(themeColors, relatives),
                          loading: () => _buildLoadingCard(themeColors),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Weekly Tip
                        _buildWeeklyTip(themeColors),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
              ],
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
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.teal.shade400, Colors.teal.shade600],
              ),
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'التقرير الأسبوعي',
                  style: AppTypography.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ملخص صلة الرحم',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isGeneratingReport ? null : _generateAIInsights,
            icon: _isGeneratingReport
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: themeColors.primary,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: Colors.white70),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildAISummaryCard(ThemeColors themeColors) {
    return GlassCard(
      gradient: LinearGradient(
        colors: [
          themeColors.primary.withValues(alpha: 0.2),
          themeColors.primaryLight.withValues(alpha: 0.1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColors.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
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
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_isGeneratingReport)
            _buildTypingIndicator(themeColors)
          else
            Text(
              _aiInsight ?? 'جاري تحليل بياناتك...',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.6,
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
          style: AppTypography.bodySmall.copyWith(color: Colors.white54),
        ),
      ],
    );
  }

  Widget _buildWeeklyStats(ThemeColors themeColors, DetailedStats stats) {
    // Aggregate raw interaction records by day
    // Data comes as [{date: '2025-12-24T10:30:00Z', type: 'call'}, ...]
    final Map<String, int> dailyCounts = {};
    for (final interaction in stats.recentActivity) {
      final dateValue = interaction['date'];
      if (dateValue != null) {
        final dateStr = dateValue.toString().split('T')[0];
        dailyCounts[dateStr] = (dailyCounts[dateStr] ?? 0) + 1;
      }
    }

    final weeklyInteractions = dailyCounts.values.fold(0, (sum, c) => sum + c);
    final avgPerDay = dailyCounts.isNotEmpty
        ? (weeklyInteractions / dailyCounts.length).toStringAsFixed(1)
        : '0';

    final currentStreak = stats.userStats['current_streak'] ?? 0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إحصائيات الأسبوع',
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
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
              Expanded(
                child: _buildStatItem(
                  '📊',
                  avgPerDay,
                  'معدل يومي',
                  Colors.blue,
                ),
              ),
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

  Widget _buildStatItem(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.headlineSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildTopConnections(ThemeColors themeColors, List<Relative> relatives) {
    // Sort by most recent contact
    final sortedRelatives = [...relatives];
    sortedRelatives.sort((a, b) {
      final aDate = a.lastContactDate ?? DateTime(2000);
      final bDate = b.lastContactDate ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    final topThree = sortedRelatives.take(3).toList();

    if (topThree.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'أكثر من تواصلت معهم',
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
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
                  Text(medal, style: const TextStyle(fontSize: 20)),
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
                          ),
                        ),
                        Text(
                          relative.relationshipType.arabicName,
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white54,
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
    return GlassCard(
      gradient: LinearGradient(
        colors: [
          Colors.amber.shade800.withValues(alpha: 0.3),
          Colors.orange.shade900.withValues(alpha: 0.2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 24)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'نصيحة الأسبوع',
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_isGeneratingReport)
            Text(
              'جاري التحميل...',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
            )
          else
            Text(
              _weeklyTip ?? 'صلة الرحم تزيد في الرزق وتبارك في العمر.',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1);
  }

  Widget _buildLoadingCard(ThemeColors themeColors) {
    return GlassCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(color: themeColors.primary),
        ),
      ),
    );
  }
}
