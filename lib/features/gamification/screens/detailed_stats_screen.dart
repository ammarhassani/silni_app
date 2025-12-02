import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/models/interaction_model.dart';
import '../../auth/providers/auth_provider.dart';

/// Detailed statistics screen showing comprehensive gamification data
class DetailedStatsScreen extends ConsumerStatefulWidget {
  const DetailedStatsScreen({super.key});

  @override
  ConsumerState<DetailedStatsScreen> createState() => _DetailedStatsScreenState();
}

class _DetailedStatsScreenState extends ConsumerState<DetailedStatsScreen> {
  Map<String, dynamic>? _userStats;
  Map<InteractionType, int>? _interactionCounts;
  List<Map<String, dynamic>>? _recentActivity;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      // Load user stats
      final userResponse = await SupabaseConfig.client
          .from('users')
          .select('points, level, current_streak, longest_streak, badges, total_interactions')
          .eq('id', user.id)
          .single();

      // Load interaction counts by type
      final interactionsResponse = await SupabaseConfig.client
          .from('interactions')
          .select('type')
          .eq('user_id', user.id);

      final Map<InteractionType, int> counts = {};
      for (final row in (interactionsResponse as List)) {
        final type = InteractionType.fromString(row['type'] as String);
        counts[type] = (counts[type] ?? 0) + 1;
      }

      // Load recent activity (last 7 days)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final recentResponse = await SupabaseConfig.client
          .from('interactions')
          .select('date, type')
          .eq('user_id', user.id)
          .gte('date', sevenDaysAgo.toIso8601String())
          .order('date', ascending: true);

      if (mounted) {
        setState(() {
          _userStats = userResponse;
          _interactionCounts = counts;
          _recentActivity = List<Map<String, dynamic>>.from(recentResponse as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(animated: true, child: SizedBox.expand()),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios_rounded),
                        color: Colors.white,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'الإحصائيات التفصيلية',
                        style: AppTypography.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          children: [
                            // Overall stats
                            _buildOverallStats(),
                            const SizedBox(height: AppSpacing.lg),

                            // Interaction type breakdown
                            _buildInteractionTypeChart(),
                            const SizedBox(height: AppSpacing.lg),

                            // Weekly activity
                            _buildWeeklyActivity(),
                            const SizedBox(height: AppSpacing.lg),

                            // Milestones progress
                            _buildMilestonesProgress(),
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

  Widget _buildOverallStats() {
    final stats = _userStats ?? {};
    final points = stats['points'] ?? 0;
    final level = stats['level'] ?? 1;
    final currentStreak = stats['current_streak'] ?? 0;
    final longestStreak = stats['longest_streak'] ?? 0;
    final totalInteractions = stats['total_interactions'] ?? 0;
    final badgesCount = (stats['badges'] as List?)?.length ?? 0;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'نظرة عامة',
              style: AppTypography.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.4,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              children: [
                _buildStatTile(
                  icon: Icons.star_rounded,
                  value: points.toString(),
                  label: 'النقاط',
                  color: AppColors.premiumGold,
                ),
                _buildStatTile(
                  icon: Icons.workspace_premium_rounded,
                  value: level.toString(),
                  label: 'المستوى',
                  color: AppColors.islamicGreenPrimary,
                ),
                _buildStatTile(
                  icon: Icons.local_fire_department_rounded,
                  value: currentStreak.toString(),
                  label: 'السلسلة الحالية',
                  color: AppColors.energeticRed,
                ),
                _buildStatTile(
                  icon: Icons.emoji_events_rounded,
                  value: badgesCount.toString(),
                  label: 'الأوسمة',
                  color: AppColors.joyfulOrange,
                ),
                _buildStatTile(
                  icon: Icons.trending_up_rounded,
                  value: longestStreak.toString(),
                  label: 'أطول سلسلة',
                  color: AppColors.calmBlue,
                ),
                _buildStatTile(
                  icon: Icons.touch_app_rounded,
                  value: totalInteractions.toString(),
                  label: 'مجموع التفاعلات',
                  color: AppColors.emotionalPurple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.headlineSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white70,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionTypeChart() {
    if (_interactionCounts == null || _interactionCounts!.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = _interactionCounts!.values.fold<int>(0, (sum, count) => sum + count);

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'التفاعلات حسب النوع',
              style: AppTypography.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _interactionCounts!.entries.map((entry) {
                    final percentage = (entry.value / total * 100).toStringAsFixed(1);
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: '${entry.key.arabicName}\n$percentage%',
                      color: _getColorForInteractionType(entry.key),
                      radius: 80,
                      titleStyle: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 0,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ..._interactionCounts!.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getColorForInteractionType(entry.key),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${entry.key.emoji} ${entry.key.arabicName}',
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                    ),
                    const Spacer(),
                    Text(
                      '${entry.value}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyActivity() {
    if (_recentActivity == null || _recentActivity!.isEmpty) {
      return GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Icon(Icons.calendar_today_rounded, color: Colors.white54, size: 48),
              const SizedBox(height: AppSpacing.md),
              Text(
                'لا توجد تفاعلات في الأيام السبعة الماضية',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    // Group by day
    final Map<String, int> dailyCounts = {};
    for (final activity in _recentActivity!) {
      final date = DateTime.parse(activity['date'] as String);
      final dayKey = '${date.year}-${date.month}-${date.day}';
      dailyCounts[dayKey] = (dailyCounts[dayKey] ?? 0) + 1;
    }

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'النشاط الأسبوعي',
              style: AppTypography.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: dailyCounts.values.isEmpty ? 10 : dailyCounts.values.reduce((a, b) => a > b ? a : b).toDouble() + 2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final days = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
                          final now = DateTime.now();
                          final dayIndex = (now.weekday + value.toInt()) % 7;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              days[dayIndex],
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (index) {
                    final now = DateTime.now();
                    final date = now.subtract(Duration(days: 6 - index));
                    final dayKey = '${date.year}-${date.month}-${date.day}';
                    final count = dailyCounts[dayKey] ?? 0;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: count.toDouble(),
                          color: AppColors.islamicGreenPrimary,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestonesProgress() {
    final stats = _userStats ?? {};
    final points = stats['points'] ?? 0;
    final totalInteractions = stats['total_interactions'] ?? 0;
    final currentStreak = stats['current_streak'] ?? 0;

    final milestones = [
      _MilestoneData(
        title: 'المستوى التالي',
        current: points,
        target: _getNextLevelPoints(stats['level'] ?? 1),
        icon: Icons.workspace_premium_rounded,
        color: AppColors.premiumGold,
      ),
      _MilestoneData(
        title: 'سلسلة 7 أيام',
        current: currentStreak,
        target: 7,
        icon: Icons.local_fire_department_rounded,
        color: AppColors.energeticRed,
      ),
      _MilestoneData(
        title: '100 تفاعل',
        current: totalInteractions,
        target: 100,
        icon: Icons.touch_app_rounded,
        color: AppColors.islamicGreenPrimary,
      ),
    ];

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تقدم الإنجازات',
              style: AppTypography.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...milestones.map((milestone) => _buildMilestoneProgress(milestone)),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneProgress(_MilestoneData milestone) {
    final progress = milestone.current / milestone.target;
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(milestone.icon, color: milestone.color, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                milestone.title,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${milestone.current}/${milestone.target}',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: clampedProgress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(milestone.color),
              minHeight: 8,
            ),
          ),
          if (progress >= 1.0) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.check_circle, color: milestone.color, size: 16),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'مكتمل!',
                  style: AppTypography.bodySmall.copyWith(
                    color: milestone.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getColorForInteractionType(InteractionType type) {
    switch (type) {
      case InteractionType.call:
        return AppColors.calmBlue;
      case InteractionType.visit:
        return AppColors.islamicGreenPrimary;
      case InteractionType.message:
        return AppColors.emotionalPurple;
      case InteractionType.gift:
        return AppColors.joyfulOrange;
      case InteractionType.event:
        return AppColors.energeticRed;
      case InteractionType.other:
        return Colors.grey;
    }
  }

  int _getNextLevelPoints(int currentLevel) {
    const xpPerLevel = [0, 100, 250, 500, 1000, 2000, 3500, 5500, 8000, 11000, 15000];
    if (currentLevel < xpPerLevel.length) {
      return xpPerLevel[currentLevel];
    }
    return xpPerLevel.last + (currentLevel - xpPerLevel.length + 1) * 5000;
  }
}

class _MilestoneData {
  final String title;
  final int current;
  final int target;
  final IconData icon;
  final Color color;

  _MilestoneData({
    required this.title,
    required this.current,
    required this.target,
    required this.icon,
    required this.color,
  });
}
