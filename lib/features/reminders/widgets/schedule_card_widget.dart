import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/reminder_schedule_model.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/utils/relationship_label_helper.dart';
import '../../../shared/widgets/glass_card.dart';

/// Compact schedule card with swipe actions for edit/delete
class CompactScheduleCard extends ConsumerStatefulWidget {
  const CompactScheduleCard({
    super.key,
    required this.schedule,
    required this.allRelatives,
    this.relationshipLabels,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onAddRelatives,
    required this.onRemoveRelative,
  });

  final ReminderSchedule schedule;
  final List<Relative> allRelatives;
  final Map<String, String>? relationshipLabels;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddRelatives;
  final void Function(String relativeId) onRemoveRelative;

  @override
  ConsumerState<CompactScheduleCard> createState() =>
      _CompactScheduleCardState();
}

class _CompactScheduleCardState extends ConsumerState<CompactScheduleCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);
    final scheduledRelatives = widget.allRelatives
        .where((r) => widget.schedule.relativeIds.contains(r.id))
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Slidable(
        key: ValueKey(widget.schedule.id),
        startActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.4,
          children: [
            CustomSlidableAction(
              onPressed: (_) {
                HapticFeedback.lightImpact();
                widget.onEdit();
              },
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.only(
                right: AppSpacing.xs,
                top: AppSpacing.xs,
                bottom: AppSpacing.xs,
              ),
              child: SizedBox.expand(
                child: Container(
                  decoration: BoxDecoration(
                    color: themeColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: themeColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                      const SizedBox(height: 4),
                      Text(
                        'تعديل',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            CustomSlidableAction(
              onPressed: (_) {
                HapticFeedback.lightImpact();
                widget.onDelete();
              },
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.only(
                right: AppSpacing.xs,
                top: AppSpacing.xs,
                bottom: AppSpacing.xs,
              ),
              child: SizedBox.expand(
                child: Container(
                  decoration: BoxDecoration(
                    color: themeColors.statusError.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: themeColors.statusError.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_rounded, color: Colors.white, size: 20),
                      const SizedBox(height: 4),
                      Text(
                        'حذف',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: emoji + name + count + time pill + switch
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Text(
                      widget.schedule.frequency.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.schedule.frequency.arabicName,
                            style: AppTypography.titleMedium.copyWith(
                              color: themeColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (scheduledRelatives.isNotEmpty)
                            Text(
                              '${scheduledRelatives.length} أقارب',
                              style: AppTypography.labelSmall.copyWith(
                                color: themeColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Time pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: themeColors.primary.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusRound),
                        border: Border.all(
                          color: themeColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        widget.schedule.time,
                        style: AppTypography.labelSmall.copyWith(
                          color: themeColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    // Compact switch
                    SizedBox(
                      height: 28,
                      child: FittedBox(
                        child: Switch(
                          value: widget.schedule.isActive,
                          onChanged: widget.onToggle,
                          activeTrackColor:
                              themeColors.primary.withValues(alpha: 0.5),
                          activeThumbColor: themeColors.primary,
                          inactiveTrackColor:
                              Colors.white.withValues(alpha: 0.15),
                          inactiveThumbColor:
                              Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    // Expand chevron
                    Icon(
                      _isExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: themeColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),

              // Expandable relatives list
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: _isExpanded
                    ? Padding(
                        padding:
                            const EdgeInsets.only(top: AppSpacing.sm),
                        child: scheduledRelatives.isEmpty
                            ? GestureDetector(
                                onTap: widget.onAddRelatives,
                                behavior: HitTestBehavior.opaque,
                                child:
                                    _buildEmptyRelativesHint(themeColors),
                              )
                            : _buildRelativesList(
                                scheduledRelatives, themeColors),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRelativesList(
    List<Relative> relatives,
    dynamic themeColors,
  ) {
    return Column(
      children: [
        ...relatives.map((relative) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  // Emoji avatar
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          themeColors.primary.withValues(alpha: 0.3),
                          themeColors.primary.withValues(alpha: 0.15),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        relative.displayEmoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Name + relationship
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          relative.fullName,
                          style: AppTypography.labelMedium.copyWith(
                            color: themeColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.relationshipLabels?[relative.id] ??
                              getSideAwareLabel(relative.relationshipType, relative.familySide, relative.gender),
                          style: AppTypography.labelSmall.copyWith(
                            color: themeColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Remove button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onRemoveRelative(relative.id);
                    },
                    child: Icon(
                      Icons.remove_circle_outline_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            )),
        // Action row: add relatives + delete
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Row(
            children: [
              // Add relatives — white on semi-opaque bg
              Expanded(
                child: GestureDetector(
                  onTap: widget.onAddRelatives,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusRound),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_add_rounded,
                            size: 16, color: Colors.white),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'إضافة أقارب',
                          style: AppTypography.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Delete schedule
              GestureDetector(
                onTap: widget.onDelete,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusRound),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 16, color: Colors.red.shade300),
                      const SizedBox(width: 4),
                      Text(
                        'حذف',
                        style: AppTypography.labelMedium.copyWith(
                          color: Colors.red.shade300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyRelativesHint(dynamic themeColors) {
    return Row(
      children: [
        Icon(Icons.person_add_alt_1_rounded,
            size: 16, color: themeColors.textHint),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'اضغط لإضافة أقارب',
          style: AppTypography.bodySmall.copyWith(
            color: themeColors.textHint,
          ),
        ),
      ],
    );
  }
}
