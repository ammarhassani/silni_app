import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Line chart showing monthly trend
class MonthlyTrendChart extends ConsumerWidget {
  const MonthlyTrendChart({
    super.key,
    required this.monthlyData,
  });

  final List<Map<String, dynamic>> monthlyData;

  static const List<String> _arabicMonths = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  String _getMonthName(String? monthStr) {
    if (monthStr == null) return '';
    // Parse month from format like "2025-01" or just use index
    try {
      final parts = monthStr.split('-');
      if (parts.length >= 2) {
        final monthNum = int.parse(parts[1]);
        if (monthNum >= 1 && monthNum <= 12) {
          return _arabicMonths[monthNum - 1];
        }
      }
    } catch (_) {}
    return monthStr;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    if (monthlyData.isEmpty) {
      return GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: themeColors.textOnGradient.withValues(alpha: 0.54),
                size: 48,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'لا توجد بيانات شهرية',
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
    final maxCount = monthlyData.fold<int>(
      0,
      (max, item) => (item['count'] as int) > max ? (item['count'] as int) : max,
    );
    final yMax = (maxCount * 1.2).ceilToDouble().clamp(10.0, double.maxFinite);

    // Calculate total for summary
    final totalInteractions = monthlyData.fold<int>(
      0,
      (sum, item) => sum + (item['count'] as int),
    );

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
                  'الاتجاه الشهري',
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
                    color: themeColors.secondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    'المجموع: $totalInteractions',
                    style: AppTypography.labelMedium.copyWith(
                      color: themeColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: yMax / 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: themeColors.textOnGradient.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
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
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= monthlyData.length) {
                            return const SizedBox.shrink();
                          }
                          final monthStr = monthlyData[index]['month'] as String?;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _getMonthName(monthStr),
                              style: AppTypography.labelSmall.copyWith(
                                color: themeColors.textOnGradient.withValues(alpha: 0.54),
                                fontSize: 9,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: 0,
                  maxY: yMax,
                  lineBarsData: [
                    LineChartBarData(
                      spots: monthlyData.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          (entry.value['count'] as int).toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: themeColors.secondary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: themeColors.secondary,
                            strokeWidth: 2,
                            strokeColor: themeColors.textOnGradient,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            themeColors.secondary.withValues(alpha: 0.3),
                            themeColors.secondary.withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => themeColors.primaryDark,
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          final monthStr = index < monthlyData.length
                              ? monthlyData[index]['month'] as String?
                              : null;
                          return LineTooltipItem(
                            '${_getMonthName(monthStr)}\n${spot.y.toInt()} تفاعل',
                            AppTypography.labelSmall.copyWith(
                              color: themeColors.textOnGradient,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
