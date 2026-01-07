import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/app_themes.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/models/interaction_model.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Pie chart showing interaction breakdown by type
class InteractionTypeChart extends ConsumerWidget {
  const InteractionTypeChart({
    super.key,
    required this.interactionCounts,
  });

  final Map<InteractionType, int> interactionCounts;

  /// Get distinct colors for each interaction type using theme colors
  Color _getColorForInteractionType(InteractionType type, ThemeColors themeColors) {
    switch (type) {
      case InteractionType.call:
        return themeColors.accent;
      case InteractionType.visit:
        return themeColors.primaryLight;
      case InteractionType.message:
        return themeColors.primary;
      case InteractionType.gift:
        return themeColors.secondary;
      case InteractionType.event:
        return themeColors.primaryDark;
      case InteractionType.other:
        return themeColors.textOnGradient.withValues(alpha: 0.5);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

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
                color: themeColors.textOnGradient,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: interactionCounts.entries.map((entry) {
                    final percentage = entry.value / total * 100;
                    final percentageStr = percentage.toStringAsFixed(1);
                    // Only show title for sections > 15% to avoid overlap
                    final showTitle = percentage > 15;
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: showTitle ? '${entry.key.arabicName}\n$percentageStr%' : '',
                      color: _getColorForInteractionType(entry.key, themeColors),
                      radius: 70,
                      titleStyle: AppTypography.bodySmall.copyWith(
                        color: themeColors.textOnGradient,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      titlePositionPercentageOffset: 0.55,
                    );
                  }).toList(),
                  sectionsSpace: 3,
                  centerSpaceRadius: 30,
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
                        color: _getColorForInteractionType(entry.key, themeColors),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${entry.key.emoji} ${entry.key.arabicName}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: themeColors.textOnGradient,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${entry.value}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: themeColors.textOnGradient,
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
