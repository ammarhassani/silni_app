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
  ConsumerState<DetailedStatsScreen> createState() =>
      _DetailedStatsScreenState();
}

class _DetailedStatsScreenState extends ConsumerState<DetailedStatsScreen> {
  Map<String, dynamic>? _userStats;
  Map<InteractionType, int>? _interactionCounts;
  List<Map<String, dynamic>>? _recentActivity;
  List<Map<String, dynamic>>? _monthlyData;
  List<Map<String, dynamic>>? _topRelatives;
  Map<String, int>? _timePatterns;
  List<Map<String, dynamic>>? _achievements;
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
          .select(
            'points, level, current_streak, longest_streak, badges, total_interactions',
          )
          .eq('id', user.id)
          .single();

      // Load interaction counts by type
      final interactionsResponse = await SupabaseConfig.client
          .from('interactions')
          .select('type, relative_id, date')
          .eq('user_id', user.id);

      final Map<InteractionType, int> counts = {};
      final Map<String, int> relativeCounts = {};
      final Map<String, int> hourlyPatterns = {};

      for (final row in (interactionsResponse as List)) {
        final type = InteractionType.fromString(row['type'] as String);
        counts[type] = (counts[type] ?? 0) + 1;

        final relativeId = row['relative_id'] as String?;
        if (relativeId != null) {
          relativeCounts[relativeId] = (relativeCounts[relativeId] ?? 0) + 1;
        }

        final date = DateTime.parse(row['date'] as String);
        final hour = date.hour.toString();
        hourlyPatterns[hour] = (hourlyPatterns[hour] ?? 0) + 1;
      }

      // Load recent activity (last 7 days)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final recentResponse = await SupabaseConfig.client
          .from('interactions')
          .select('date, type')
          .eq('user_id', user.id)
          .gte('date', sevenDaysAgo.toIso8601String())
          .order('date', ascending: true);

      // Load monthly data (last 6 months)
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
      final monthlyResponse = await SupabaseConfig.client
          .from('interactions')
          .select('date')
          .eq('user_id', user.id)
          .gte('date', sixMonthsAgo.toIso8601String())
          .order('date', ascending: true);

      // Process monthly data
      final Map<String, int> monthlyCounts = {};
      for (final row in (monthlyResponse as List)) {
        final date = DateTime.parse(row['date'] as String);
        final monthKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}';
        monthlyCounts[monthKey] = (monthlyCounts[monthKey] ?? 0) + 1;
      }

      // Get top relatives with names
      final topRelativesData = <Map<String, dynamic>>[];
      if (relativeCounts.isNotEmpty) {
        final sortedRelatives = relativeCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final topRelativeIds = sortedRelatives
            .take(5)
            .map((e) => e.key)
            .toList();

        if (topRelativeIds.isNotEmpty) {
          final relativesResponse = await SupabaseConfig.client
              .from('relatives')
              .select('id, full_name')
              .eq('user_id', user.id)
              .filter('id', 'in', topRelativeIds);

          for (final relative in (relativesResponse as List)) {
            final relativeId = relative['id'] as String;
            topRelativesData.add({
              'id': relativeId,
              'name': relative['full_name'] as String,
              'count': relativeCounts[relativeId] ?? 0,
            });
          }

          topRelativesData.sort(
            (a, b) => (b['count'] as int).compareTo(a['count'] as int),
          );
        }
      }

      if (mounted) {
        setState(() {
          _userStats = userResponse;
          _interactionCounts = counts;
          _recentActivity = List<Map<String, dynamic>>.from(
            recentResponse as List,
          );
          _monthlyData = monthlyCounts.entries
              .map((e) => {'month': e.key, 'count': e.value})
              .toList();
          _topRelatives = topRelativesData;
          _timePatterns = hourlyPatterns;
          _achievements =
              (userResponse['badges'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ??
              [];
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

                            // Monthly trend analysis
                            _buildMonthlyTrend(),
                            const SizedBox(height: AppSpacing.lg),

                            // Top relatives breakdown
                            _buildTopRelatives(),
                            const SizedBox(height: AppSpacing.lg),

                            // Time-based patterns
                            _buildTimePatterns(),
                            const SizedBox(height: AppSpacing.lg),

                            // Achievement badges showcase
                            _buildAchievementsShowcase(),
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
        border: Border.all(color: color.withOpacity(0.3), width: 1),
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
            style: AppTypography.bodySmall.copyWith(color: Colors.white70),
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

    final total = _interactionCounts!.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );

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
                    final percentage = (entry.value / total * 100)
                        .toStringAsFixed(1);
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
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white,
                      ),
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
              const Icon(
                Icons.calendar_today_rounded,
                color: Colors.white54,
                size: 48,
              ),
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
                  maxY: dailyCounts.values.isEmpty
                      ? 10
                      : dailyCounts.values
                                .reduce((a, b) => a > b ? a : b)
                                .toDouble() +
                            2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final days = [
                            'السبت',
                            'الأحد',
                            'الاثنين',
                            'الثلاثاء',
                            'الأربعاء',
                            'الخميس',
                            'الجمعة',
                          ];
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
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
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
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
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
            ...milestones.map(
              (milestone) => _buildMilestoneProgress(milestone),
            ),
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
                style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
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

  Widget _buildMonthlyTrend() {
    if (_monthlyData == null || _monthlyData!.isEmpty) {
      return GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                color: Colors.white54,
                size: 48,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'لا توجد بيانات شهرية',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الاتجاه الشهري',
              style: AppTypography.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _monthlyData!.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value['count'].toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: AppColors.premiumGold,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.premiumGold.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRelatives() {
    if (_topRelatives == null || _topRelatives!.isEmpty) {
      return GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Icon(Icons.people_rounded, color: Colors.white54, size: 48),
              const SizedBox(height: AppSpacing.md),
              Text(
                'لا توجد بيانات عن الأقارب',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الأقارب الأكثر تواصلاً',
              style: AppTypography.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ..._topRelatives!.take(5).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final relative = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.islamicGreenPrimary,
                            AppColors.calmBlue,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            relative['name'] as String,
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${relative['count']} تفاعل',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white70,
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
      ),
    );
  }

  Widget _buildTimePatterns() {
    if (_timePatterns == null || _timePatterns!.isEmpty) {
      return GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Icon(
                Icons.schedule_rounded,
                color: Colors.white54,
                size: 48,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'لا توجد أنماط زمنية',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الأنماط الزمنية للتواصل',
              style: AppTypography.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _timePatterns!.values.isEmpty
                      ? 10
                      : _timePatterns!.values
                                .reduce((a, b) => a > b ? a : b)
                                .toDouble() +
                            2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final hour = value.toInt();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${hour.toString().padLeft(2, '0')}:00',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(24, (index) {
                    final hour = index.toString();
                    final count = _timePatterns![hour] ?? 0;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: count.toDouble(),
                          color: AppColors.emotionalPurple,
                          width: 8,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
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

  Widget _buildAchievementsShowcase() {
    if (_achievements == null || _achievements!.isEmpty) {
      return GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: Colors.white54,
                size: 48,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'لا توجد إنجازات بعد',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إنجازاتي',
              style: AppTypography.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              children: _achievements!.take(6).map((achievement) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.joyfulOrange, AppColors.energeticRed],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.joyfulOrange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        achievement['name'] as String? ?? 'إنجاز',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
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
    const xpPerLevel = [
      0,
      100,
      250,
      500,
      1000,
      2000,
      3500,
      5500,
      8000,
      11000,
      15000,
    ];
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
