import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/reminder_schedule_model.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';

/// Card displaying a reminder schedule with drag-and-drop support
class ScheduleCard extends ConsumerWidget {
  const ScheduleCard({
    super.key,
    required this.schedule,
    required this.allRelatives,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onAddRelatives,
    required this.onRemoveRelative,
    required this.onDrop,
  });

  final ReminderSchedule schedule;
  final List<Relative> allRelatives;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddRelatives;
  final void Function(String relativeId) onRemoveRelative;
  final void Function(Relative relative) onDrop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final scheduledRelatives = allRelatives
        .where((r) => schedule.relativeIds.contains(r.id))
        .toList();

    return DragTarget<Relative>(
      onWillAcceptWithDetails: (details) =>
          !schedule.relativeIds.contains(details.data.id),
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: isHovering
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: themeColors.primary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                )
              : null,
          child: GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            gradient: isHovering
                ? LinearGradient(
                    colors: [
                      themeColors.primary.withValues(alpha: 0.3),
                      themeColors.primary.withValues(alpha: 0.1),
                    ],
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Text(
                      schedule.frequency.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schedule.frequency.arabicName,
                            style: AppTypography.headlineSmall.copyWith(
                              color: themeColors.textPrimary, // Better contrast
                            ),
                          ),
                          Text(
                            schedule.description,
                            style: AppTypography.bodySmall.copyWith(
                              color: themeColors.textSecondary, // Better contrast
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: schedule.isActive,
                      onChanged: onToggle,
                      activeTrackColor: themeColors.primary.withValues(alpha: 0.5),
                      activeThumbColor: themeColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(color: Colors.white24),
                const SizedBox(height: AppSpacing.md),

                // Drag hint when hovering
                if (isHovering)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      '✨ أفلت هنا للإضافة',
                      style: AppTypography.bodySmall.copyWith(
                        color: themeColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                // Relatives in this schedule
                if (scheduledRelatives.isEmpty)
                  Text(
                    'لا يوجد أقارب في هذا التذكير',
                    style: AppTypography.bodySmall.copyWith(
                      color: themeColors.textSecondary,
                    ),
                  )
                else
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: scheduledRelatives.map((relative) {
                      return RelativeChip(
                        relative: relative,
                        onRemove: () => onRemoveRelative(relative.id),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: AppSpacing.md),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        onPressed: onAddRelatives,
                        text: 'إضافة أقارب',
                        icon: Icons.person_add_rounded,
                        height: 40,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    GradientButton(
                      onPressed: onEdit,
                      text: '',
                      icon: Icons.edit_rounded,
                      height: 40,
                      width: 50,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    GradientButton(
                      onPressed: onDelete,
                      text: '',
                      icon: Icons.delete_rounded,
                      height: 40,
                      width: 50,
                      gradient: AppColors.streakFire,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn().slideX();
      },
    );
  }
}

/// Chip displaying a relative in a schedule
class RelativeChip extends ConsumerWidget {
  const RelativeChip({
    super.key,
    required this.relative,
    required this.onRemove,
  });

  final Relative relative;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeColors.primary.withValues(alpha: 0.3),
            themeColors.primary.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(relative.displayEmoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: AppSpacing.xs),
          Text(
            relative.fullName,
            style: AppTypography.bodySmall.copyWith(color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.xs),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
