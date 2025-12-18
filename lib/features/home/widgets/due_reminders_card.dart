import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/models/reminder_schedule_model.dart';
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
  });

  final String userId;
  final List<Relative> relatives;
  final List<ReminderSchedule> schedules;
  final Set<String> contactedSet;

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
    return GlassCard(
      gradient: LinearGradient(
        colors: [
          Colors.grey.withValues(alpha: 0.3),
          Colors.grey.withValues(alpha: 0.1),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none,
            size: 48,
            color: Colors.white.withValues(alpha: 0.6),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'لا توجد تذكيرات',
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'أضف تذكيرات لتبقى على تواصل مع أقاربك',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
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
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildAllDoneState(dynamic themeColors) {
    return GlassCard(
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
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'لا توجد تذكيرات لليوم',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildCelebrationState(dynamic themeColors) {
    return GlassCard(
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
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تواصلت مع جميع الأقارب في تذكيراتك اليوم',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildTaskList(
    BuildContext context,
    List<DueRelativeWithFrequencies> dueRelatives,
    int contactedCount,
    int totalCount,
    dynamic themeColors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with progress
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'تذكيرات اليوم',
              style: AppTypography.headlineSmall.copyWith(
                color: Colors.white,
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
                  color: Colors.white,
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
            backgroundColor: Colors.white.withValues(alpha: 0.2),
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
            ),
          );
        }),

        // Show more button if more than 5
        if (dueRelatives.length > 5)
          GestureDetector(
            onTap: () => context.push(AppRoutes.remindersDue),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'عرض ${dueRelatives.length - 5} المزيد...',
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}

class _DueRelativeCard extends StatelessWidget {
  const _DueRelativeCard({
    required this.dueRelative,
    required this.isContacted,
  });

  final DueRelativeWithFrequencies dueRelative;
  final bool isContacted;

  static const _fridayGreen = Color(0xFF1B5E20);
  static const _fridayGreenLight = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    final relative = dueRelative.relative;
    final hasFriday = dueRelative.hasFridayReminder;

    return GestureDetector(
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
                    : Colors.white.withValues(alpha: 0.2),
                border: isContacted
                    ? null
                    : Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
              ),
              child: isContacted
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
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
                      color: Colors.white,
                      decoration: isContacted ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.white.withValues(alpha: 0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        relative.relationshipType.arabicName,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...dueRelative.sortedFrequencies.map((freq) => Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: _FrequencyBadge(frequency: freq),
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
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.5),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}

class _FrequencyBadge extends StatelessWidget {
  const _FrequencyBadge({required this.frequency});

  final ReminderFrequency frequency;

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
            : Colors.white.withValues(alpha: 0.15),
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
              color: Colors.white,
              fontSize: 9,
              fontWeight: isFriday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
