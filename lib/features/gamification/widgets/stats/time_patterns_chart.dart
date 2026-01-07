import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Bar chart showing time-based communication patterns
class TimePatternsChart extends ConsumerWidget {
  const TimePatternsChart({
    super.key,
    required this.timePatterns,
  });

  final Map<String, int> timePatterns;

  /// Get time period label for an hour
  String _getTimePeriod(int hour) {
    if (hour >= 5 && hour < 12) return 'صباحاً';
    if (hour >= 12 && hour < 17) return 'ظهراً';
    if (hour >= 17 && hour < 21) return 'مساءً';
    return 'ليلاً';
  }

  /// Get formatted hour with AM/PM indicator
  String _formatHour(int hour) {
    if (hour == 0) return '12\nليلاً';
    if (hour == 12) return '12\nظهراً';
    if (hour < 12) return '$hour\nص';
    return '${hour - 12}\nم';
  }

  /// Find peak hours for insights
  String _getPeakInsight() {
    if (timePatterns.isEmpty) return '';

    // Group by period
    int morning = 0, afternoon = 0, evening = 0, night = 0;

    timePatterns.forEach((hourStr, count) {
      final hour = int.tryParse(hourStr) ?? 0;
      if (hour >= 5 && hour < 12) {
        morning += count;
      } else if (hour >= 12 && hour < 17) {
        afternoon += count;
      } else if (hour >= 17 && hour < 21) {
        evening += count;
      } else {
        night += count;
      }
    });

    final periods = {
      'الصباح': morning,
      'الظهر': afternoon,
      'المساء': evening,
      'الليل': night,
    };

    final peakPeriod = periods.entries
        .reduce((a, b) => a.value > b.value ? a : b);

    if (peakPeriod.value == 0) return '';
    return 'أكثر نشاطاً في ${peakPeriod.key}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    if (timePatterns.isEmpty) {
      return GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Icon(
                Icons.schedule_rounded,
                color: themeColors.textOnGradient.withValues(alpha: 0.54),
                size: 48,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'لا توجد أنماط زمنية',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: themeColors.textOnGradient.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate max value for Y axis
    final maxCount = timePatterns.values.isEmpty
        ? 10
        : timePatterns.values.reduce((a, b) => a > b ? a : b);
    final yMax = (maxCount * 1.2).ceilToDouble().clamp(5.0, double.maxFinite);

    // Calculate total interactions
    final totalInteractions = timePatterns.values.fold<int>(0, (a, b) => a + b);

    // Get insight
    final peakInsight = _getPeakInsight();

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الأنماط الزمنية للتواصل',
                  style: AppTypography.titleLarge.copyWith(
                    color: themeColors.textOnGradient,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: themeColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    '$totalInteractions تفاعل',
                    style: AppTypography.labelMedium.copyWith(
                      color: themeColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (peakInsight.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                peakInsight,
                style: AppTypography.bodySmall.copyWith(
                  color: themeColors.textOnGradient.withValues(alpha: 0.7),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: yMax,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => themeColors.primaryDark,
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final hour = group.x;
                        final count = rod.toY.toInt();
                        return BarTooltipItem(
                          'الساعة $hour:00\n$count تفاعل\n${_getTimePeriod(hour)}',
                          AppTypography.labelSmall.copyWith(
                            color: themeColors.textOnGradient,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) {
                          final hour = value.toInt();
                          // Show labels for key hours
                          if (hour != 0 && hour != 6 && hour != 12 && hour != 18) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _formatHour(hour),
                              textAlign: TextAlign.center,
                              style: AppTypography.labelSmall.copyWith(
                                color: themeColors.textOnGradient.withValues(alpha: 0.54),
                                fontSize: 9,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: yMax / 4,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              value.toInt().toString(),
                              style: AppTypography.labelSmall.copyWith(
                                color: themeColors.textOnGradient.withValues(alpha: 0.54),
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: yMax / 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: themeColors.textOnGradient.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(24, (index) {
                    final hour = index.toString();
                    final count = timePatterns[hour] ?? 0;

                    // Color intensity based on value
                    final intensity = maxCount > 0 ? count / maxCount : 0.0;
                    final color = Color.lerp(
                      themeColors.accent.withValues(alpha: 0.4),
                      themeColors.accent,
                      intensity,
                    )!;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: count.toDouble(),
                          color: color,
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
}
