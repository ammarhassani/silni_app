import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Bar chart showing time-based communication patterns
class TimePatternsChart extends StatelessWidget {
  const TimePatternsChart({
    super.key,
    required this.timePatterns,
  });

  final Map<String, int> timePatterns;

  @override
  Widget build(BuildContext context) {
    if (timePatterns.isEmpty) {
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
                  maxY: timePatterns.values.isEmpty
                      ? 10
                      : timePatterns.values
                                .reduce((a, b) => a > b ? a : b)
                                .toDouble() +
                            2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final hour = value.toInt();
                          // Only show labels for every 4 hours
                          if (hour % 4 != 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '$hour',
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
                    final count = timePatterns[hour] ?? 0;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: count.toDouble(),
                          color: AppColors.emotionalPurple,
                          width: 6,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
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
