import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import 'glass_card.dart';

/// Health status options for relatives
enum HealthStatusOption {
  excellent('excellent', 'ممتاز', '💪', Color(0xFF4CAF50)),
  good('good', 'جيد', '😊', Color(0xFF8BC34A)),
  normal('normal', 'عادي', '🙂', Color(0xFF2196F3)),
  needsCare('needs_care', 'يحتاج رعاية', '🩺', Color(0xFFFF9800)),
  sick('sick', 'مريض', '🤒', Color(0xFFF44336)),
  elderly('elderly', 'مسن', '👴', Color(0xFF9C27B0)),
  disabled('disabled', 'ذوي احتياجات خاصة', '♿', Color(0xFF607D8B));

  final String value;
  final String arabicName;
  final String emoji;
  final Color color;

  const HealthStatusOption(this.value, this.arabicName, this.emoji, this.color);

  static HealthStatusOption? fromString(String? value) {
    if (value == null) return null;
    return HealthStatusOption.values.firstWhere(
      (status) => status.value == value,
      orElse: () => HealthStatusOption.normal,
    );
  }
}

/// A health status picker widget for recording relative's health condition
class HealthStatusPicker extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
                  color: Colors.white.withValues(alpha: 0.7),
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
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'اختياري - لتذكيرك بالاطمئنان على صحتهم',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
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
              return _buildStatusChip(status, isSelected);
            }).toList(),
          ),
          if (selectedStatus != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildSelectedInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(HealthStatusOption status, bool isSelected) {
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
                    status.color.withValues(alpha: 0.8),
                    status.color,
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isSelected ? status.color : Colors.white.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: status.color.withValues(alpha: 0.4),
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
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedInfo() {
    final status = HealthStatusOption.fromString(selectedStatus);
    if (status == null) return const SizedBox.shrink();

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
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: status.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: status.color,
            size: 16,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              hint,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
