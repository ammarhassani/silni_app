import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/models/interaction_model.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Pie chart showing interaction breakdown by type
class InteractionTypeChart extends StatelessWidget {
  const InteractionTypeChart({
    super.key,
    required this.interactionCounts,
  });

  final Map<InteractionType, int> interactionCounts;

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

  @override
  Widget build(BuildContext context) {
    if (interactionCounts.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = interactionCounts.values.fold<int>(
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
                  sections: interactionCounts.entries.map((entry) {
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
            ...interactionCounts.entries.map((entry) {
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
}
