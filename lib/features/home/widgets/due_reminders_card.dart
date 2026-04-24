import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/models/reminder_schedule_model.dart';
import '../../../shared/utils/relationship_label_helper.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/home_providers.dart';

/// Card showing today's due reminders as a task list
class DueRemindersCard extends ConsumerWidget {
  const DueRemindersCard({
    super.key,
    required this.userId,
    required this.relatives,
    required this.schedules,
    required this.contactedSet,
    this.relationshipLabels,
  });

  final String userId;
  final List<Relative> relatives;
  final List<ReminderSchedule> schedules;
  final Set<String> contactedSet;

  /// Optional map of relative ID to perspective-shifted label.
  /// Falls back to [relative.relationshipType.arabicName] for any missing entry.
  final Map<String, String>? relationshipLabels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    // Get today's due relatives
    final dueRelatives = ref.watch(todayDueRelativesProvider((
      schedules: schedules,
      relatives: relatives,
    )));

    // If no reminders exist at all, show "add reminders" prompt
    if (schedules.isEmpty) {
      return _buildNoRemindersState(context, themeColors);
    }

    // If no due reminders today
    if (dueRelatives.isEmpty) {
      // Check if there are relatives not assigned to any schedule
      final scheduledIds = schedules.expand((s) => s.relativeIds).toSet();
      final unscheduledCount =
          relatives.where((r) => !scheduledIds.contains(r.id)).length;

      if (unscheduledCount > 0) {
        return _buildUnscheduledNudge(context, themeColors, unscheduledCount);
      }
      return _buildAllDoneState(themeColors);
    }

    // Count contacted vs total
    final contactedCount = dueRelatives.where(
      (r) => contactedSet.contains(r.relative.id)
    ).length;
    final totalCount = dueRelatives.length;
    final allContacted = contactedCount == totalCount;

    // All relatives contacted - show celebration
    if (allContacted) {
      return _buildCelebrationState(themeColors);
    }

    // Show due reminders as tasks
    return _buildTaskList(
      context,
      dueRelatives,
      contactedCount,
      totalCount,
      themeColors,
    );
  }

  Widget _buildNoRemindersState(BuildContext context, dynamic themeColors) {
    return Semantics(
      label: 'لا توجد تذكيرات - أضف تذكيرات للتواصل مع أقاربك',
      child: GlassCard(
        gradient: LinearGradient(
          colors: [
            themeColors.disabled.withValues(alpha: 0.3),
            themeColors.disabled.withValues(alpha: 0.1),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 48,
              color: themeColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'لا توجد تذكيرات',
              style: AppTypography.titleMedium.copyWith(
                color: themeColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'أضف تذكيرات لتبقى على تواصل مع أقاربك',
              style: AppTypography.bodySmall.copyWith(
                color: themeColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Semantics(
                label: 'إضافة تذكير',
                button: true,
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.reminders),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: themeColors.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Text(
                      'إضافة تذكير',
                      style: AppTypography.labelMedium.copyWith(
                        color: themeColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: AppAnimations.normal);
  }

  Widget _buildUnscheduledNudge(
    BuildContext context,
    dynamic themeColors,
    int unscheduledCount,
  ) {
    return Semantics(
      label: 'لديك $unscheduledCount أقارب بدون تذكيرات - اضغط لجدولتهم',
      button: true,
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.reminders),
        child: GlassCard(
          gradient: LinearGradient(
            colors: [
              themeColors.primary.withValues(alpha: 0.25),
              AppColors.premiumGold.withValues(alpha: 0.15),
            ],
          ),
          child: Row(
            children: [
              const Text('📋', style: TextStyle(fontSize: 40)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'لديك $unscheduledCount أقارب بدون تذكيرات',
                      style: AppTypography.titleSmall.copyWith(
                        color: themeColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'جدوّل تواصلك معهم لتبقى قريبًا منهم',
                      style: AppTypography.bodySmall.copyWith(
                        color: themeColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: themeColors.textHint,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: AppAnimations.normal);
  }

  Widget _buildAllDoneState(dynamic themeColors) {
    return Semantics(
      label: 'أنت على تواصل جيد - لا توجد تذكيرات لليوم',
      child: GlassCard(
        gradient: LinearGradient(
          colors: [
            themeColors.primaryLight.withValues(alpha: 0.3),
            AppColors.premiumGold.withValues(alpha: 0.2),
          ],
        ),
        child: Row(
          children: [
            const Text('✅', style: TextStyle(fontSize: 40)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أنت على تواصل جيد!',
                    style: AppTypography.titleMedium.copyWith(
                      color: themeColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'لا توجد تذكيرات لليوم',
                    style: AppTypography.bodySmall.copyWith(
                      color: themeColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: AppAnimations.normal);
  }

  Widget _buildCelebrationState(dynamic themeColors) {
    return Semantics(
      label: 'أحسنت! تواصلت مع جميع الأقارب في تذكيراتك اليوم',
      liveRegion: true,
      child: GlassCard(
        gradient: LinearGradient(
          colors: [
            AppColors.premiumGold.withValues(alpha: 0.4),
            themeColors.primaryLight.withValues(alpha: 0.3),
          ],
        ),
        child: Row(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 40)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أحسنت! أكملت مهامك',
                    style: AppTypography.titleMedium.copyWith(
                      color: themeColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تواصلت مع جميع الأقارب في تذكيراتك اليوم',
                    style: AppTypography.bodySmall.copyWith(
                      color: themeColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: AppAnimations.normal).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildTaskList(
    BuildContext context,
    List<DueRelativeWithFrequencies> dueRelatives,
    int contactedCount,
    int totalCount,
    dynamic themeColors,
  ) {
    return Semantics(
      label: 'تذكيرات اليوم - $contactedCount من $totalCount مكتمل',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تذكيرات اليوم',
                style: AppTypography.headlineSmall.copyWith(
                  color: themeColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: themeColors.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '$contactedCount / $totalCount',
                  style: AppTypography.labelMedium.copyWith(
                    color: themeColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalCount > 0 ? contactedCount / totalCount : 0,
              backgroundColor: themeColors.glassHighlight,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.premiumGold,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Due relatives list
          ...dueRelatives.take(5).map((dueRelative) {
            final isContacted = contactedSet.contains(dueRelative.relative.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _DueRelativeCard(
                dueRelative: dueRelative,
                isContacted: isContacted,
                themeColors: themeColors,
                relationshipLabel: relationshipLabels?[dueRelative.relative.id],
              ),
            );
          }),

          // Show more button if more than 5
          if (dueRelatives.length > 5)
            Semantics(
              label: 'عرض ${dueRelatives.length - 5} تذكيرات إضافية',
              button: true,
              child: GestureDetector(
                onTap: () => context.push(AppRoutes.remindersDue),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    'عرض ${dueRelatives.length - 5} المزيد...',
                    style: AppTypography.labelMedium.copyWith(
                      color: themeColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: AppAnimations.normal).slideY(begin: 0.1, end: 0);
  }
}

class _DueRelativeCard extends StatelessWidget {
  const _DueRelativeCard({
    required this.dueRelative,
    required this.isContacted,
    required this.themeColors,
    this.relationshipLabel,
  });

  final DueRelativeWithFrequencies dueRelative;
  final bool isContacted;
  final dynamic themeColors;
  final String? relationshipLabel;

  static const _fridayGreen = Color(0xFF1B5E20);
  static const _fridayGreenLight = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    final relative = dueRelative.relative;
    final hasFriday = dueRelative.hasFridayReminder;

    return Semantics(
      label: '${relative.fullName} - ${isContacted ? "تم التواصل" : "بانتظار التواصل"}',
      button: true,
      child: GestureDetector(
        onTap: () => context.push('${AppRoutes.relativeDetail}/${relative.id}'),
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          gradient: isContacted
              ? LinearGradient(
                  colors: [
                    Colors.green.withValues(alpha: 0.3),
                    Colors.green.withValues(alpha: 0.1),
                  ],
                )
              : hasFriday
                  ? LinearGradient(
                      colors: [
                        _fridayGreen.withValues(alpha: 0.3),
                        _fridayGreenLight.withValues(alpha: 0.15),
                      ],
                    )
                  : null,
          child: Row(
            children: [
              // Checkbox/status indicator
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isContacted
                      ? Colors.green
                      : themeColors.glassHighlight,
                  border: isContacted
                      ? null
                      : Border.all(color: themeColors.textSecondary, width: 2),
                ),
                child: isContacted
                    ? Icon(Icons.check, color: themeColors.textOnGradient, size: 18)
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),

              // Relative info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      relative.fullName,
                      style: AppTypography.titleSmall.copyWith(
                        color: themeColors.textPrimary,
                        decoration: isContacted ? TextDecoration.lineThrough : null,
                        decorationColor: themeColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            relationshipLabel ?? getSideAwareLabel(relative.relationshipType, relative.familySide, relative.gender),
                            style: AppTypography.bodySmall.copyWith(
                              color: themeColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ...dueRelative.sortedFrequencies.take(2).map((freq) => Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: _FrequencyBadge(frequency: freq, themeColors: themeColors),
                        )),
                      ],
                    ),
                  ],
                ),
              ),

              // Show contacted badge or arrow
              if (isContacted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    'تم',
                    style: AppTypography.labelSmall.copyWith(
                      color: themeColors.textOnGradient,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: themeColors.textHint,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrequencyBadge extends StatelessWidget {
  const _FrequencyBadge({
    required this.frequency,
    required this.themeColors,
  });

  final ReminderFrequency frequency;
  final dynamic themeColors;

  static const _fridayGreen = Color(0xFF1B5E20);
  static const _fridayGreenLight = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    final isFriday = frequency == ReminderFrequency.friday;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isFriday
            ? _fridayGreen.withValues(alpha: 0.6)
            : themeColors.glassHighlight,
        borderRadius: BorderRadius.circular(4),
        border: isFriday
            ? Border.all(color: _fridayGreenLight.withValues(alpha: 0.5), width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFriday) ...[
            const Text('🕌', style: TextStyle(fontSize: 10)),
            const SizedBox(width: 2),
          ],
          Text(
            frequency.arabicName,
            style: AppTypography.labelSmall.copyWith(
              color: themeColors.textPrimary,
              fontSize: 9,
              fontWeight: isFriday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
