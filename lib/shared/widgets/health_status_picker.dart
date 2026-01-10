import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/theme_provider.dart';
import 'glass_card.dart';

/// Health status options for relatives (represents communication frequency)
enum HealthStatusOption {
  excellent('excellent', 'ممتاز', '💪'),
  good('good', 'جيد', '😊'),
  normal('normal', 'عادي', '🙂'),
  needsCare('needs_care', 'يحتاج رعاية', '🩺'),
  sick('sick', 'مريض', '🤒'),
  elderly('elderly', 'مسن', '👴'),
  disabled('disabled', 'ذوي احتياجات خاصة', '♿');

  final String value;
  final String arabicName;
  final String emoji;

  const HealthStatusOption(this.value, this.arabicName, this.emoji);

  /// Get theme-aware color for this status
  Color getColor(ThemeColors colors) => switch (this) {
        excellent => colors.contactExcellent,
        good => colors.contactGood,
        normal => colors.contactNormal,
        needsCare => colors.contactNeedsCare,
        sick => colors.contactCritical,
        elderly => colors.contactElderly,
        disabled => colors.contactDisabled,
      };

  static HealthStatusOption? fromString(String? value) {
    if (value == null) return null;
    return HealthStatusOption.values.firstWhere(
      (status) => status.value == value,
      orElse: () => HealthStatusOption.normal,
    );
  }
}

/// A health status picker widget for recording relative's health condition
class HealthStatusPicker extends ConsumerWidget {
  final String? selectedStatus;
  final ValueChanged<String?> onStatusChanged;
  final bool showLabel;

  const HealthStatusPicker({
    super.key,
    this.selectedStatus,
    required this.onStatusChanged,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLabel) ...[
            Row(
              children: [
                Icon(
                  Icons.health_and_safety_rounded,
                  color: colors.textOnGradient.withValues(alpha: 0.7),
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الحالة الصحية',
                        style: AppTypography.titleMedium.copyWith(
                          color: colors.textOnGradient,
                        ),
                      ),
                      Text(
                        'اختياري - لتذكيرك بالاطمئنان على صحتهم',
                        style: AppTypography.labelSmall.copyWith(
                          color: colors.textOnGradient.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: HealthStatusOption.values.map((status) {
              final isSelected = selectedStatus == status.value;
              return _buildStatusChip(status, isSelected, colors);
            }).toList(),
          ),
          if (selectedStatus != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildSelectedInfo(colors),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    HealthStatusOption status,
    bool isSelected,
    ThemeColors colors,
  ) {
    final statusColor = status.getColor(colors);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // Toggle: if already selected, deselect
        onStatusChanged(isSelected ? null : status.value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    statusColor.withValues(alpha: 0.8),
                    statusColor,
                  ],
                )
              : null,
          color: isSelected
              ? null
              : colors.glassBackground.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isSelected
                ? statusColor
                : colors.glassBorder.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              status.emoji,
              style: TextStyle(fontSize: isSelected ? 20 : 16),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              status.arabicName,
              style: AppTypography.labelMedium.copyWith(
                color: colors.textOnGradient,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedInfo(ThemeColors colors) {
    final status = HealthStatusOption.fromString(selectedStatus);
    if (status == null) return const SizedBox.shrink();

    final statusColor = status.getColor(colors);

    String hint = '';
    switch (status) {
      case HealthStatusOption.needsCare:
        hint = 'سيتم تذكيرك بالسؤال عن صحتهم بشكل متكرر';
        break;
      case HealthStatusOption.sick:
        hint = 'سيتم تذكيرك بالاطمئنان عليهم يومياً';
        break;
      case HealthStatusOption.elderly:
        hint = 'سيتم إعطاء أولوية أعلى للتواصل معهم';
        break;
      case HealthStatusOption.disabled:
        hint = 'سيتم تذكيرك بتقديم الدعم والمساعدة';
        break;
      default:
        hint = '';
    }

    if (hint.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: statusColor,
            size: 16,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              hint,
              style: AppTypography.labelSmall.copyWith(
                color: colors.textOnGradient.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
