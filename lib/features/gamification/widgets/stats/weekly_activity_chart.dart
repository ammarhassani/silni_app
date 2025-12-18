import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Bar chart showing weekly activity
class WeeklyActivityChart extends StatelessWidget {
  const WeeklyActivityChart({
    super.key,
    required this.recentActivity,
  });

  final List<Map<String, dynamic>> recentActivity;

  @override
  Widget build(BuildContext context) {
    if (recentActivity.isEmpty) {
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
    for (final activity in recentActivity) {
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
}
