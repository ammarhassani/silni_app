import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/utils/relationship_label_helper.dart';
import '../../../shared/models/reminder_schedule_model.dart';
import '../../../shared/services/reminder_schedules_service.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_providers.dart';

/// Shows all relatives not currently assigned to any reminder schedule.
/// Deterministic — no AI, no provider, just filters relatives vs schedules.
class UnscheduledRelativesSection extends StatefulWidget {
  const UnscheduledRelativesSection({
    super.key,
    required this.relatives,
    required this.schedules,
  });

  final List<Relative> relatives;
  final List<ReminderSchedule> schedules;

  @override
  State<UnscheduledRelativesSection> createState() =>
      _UnscheduledRelativesSectionState();
}

class _UnscheduledRelativesSectionState
    extends State<UnscheduledRelativesSection> {
  bool _isExpanded = true;

  List<Relative> get _unscheduledRelatives {
    // Only count IDs that correspond to actually-existing relatives.
    // Stale IDs (from deleted relatives) are ignored.
    final validIds = widget.relatives.map((r) => r.id).toSet();
    final allScheduledIds = widget.schedules
        .expand((s) => s.relativeIds)
        .where((id) => validIds.contains(id))
        .toSet();
    // Note: viewer's own node is already excluded by the parent screen,
    // so we don't need !r.isSelf here (which would wrongly exclude
    // other users' claimed nodes in group mode).
    //
    // Household members are NEVER candidates for reminders — the
    // onboarding wizard explicitly tells the user "we won't disturb
    // you about people you see daily." Surfacing them here as "needs
    // a reminder" contradicts that promise.
    return widget.relatives
        .where((r) =>
            r.relativeCategory != RelativeCategory.household &&
            !allScheduledIds.contains(r.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final unscheduled = _unscheduledRelatives;

    // Hide only when no schedules exist yet
    if (widget.schedules.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        onTap: unscheduled.isNotEmpty
            ? () => setState(() => _isExpanded = !_isExpanded)
            : null,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row
            Row(
              children: [
                const Text('👥', style: TextStyle(fontSize: 20)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    unscheduled.isEmpty
                        ? 'كل الأقارب مجدولين ✓'
                        : 'أقارب بدون تذكير (${unscheduled.length})',
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (unscheduled.isNotEmpty)
                  Icon(
                    _isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: Colors.white54,
                    size: 20,
                  ),
              ],
            ),
            // Expandable chip area
            if (unscheduled.isNotEmpty)
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: _isExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: unscheduled.map((relative) {
                            return _UnscheduledChip(
                              relative: relative,
                              schedules: widget.schedules,
                              allRelatives: widget.relatives,
                            );
                          }).toList(),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}

/// Chip for an unscheduled relative — tap to pick which schedule to add to.
class _UnscheduledChip extends StatelessWidget {
  const _UnscheduledChip({
    required this.relative,
    required this.schedules,
    required this.allRelatives,
  });

  final Relative relative;
  final List<ReminderSchedule> schedules;
  final List<Relative> allRelatives;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => _AddToScheduleSheet(
            relative: relative,
            schedules: schedules,
            allRelatives: allRelatives,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              relative.displayEmoji,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 6),
            Text(
              relative.fullName,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet to add a relative to one of the existing schedules.
class _AddToScheduleSheet extends ConsumerStatefulWidget {
  const _AddToScheduleSheet({
    required this.relative,
    required this.schedules,
    required this.allRelatives,
  });

  final Relative relative;
  final List<ReminderSchedule> schedules;
  final List<Relative> allRelatives;

  @override
  ConsumerState<_AddToScheduleSheet> createState() =>
      _AddToScheduleSheetState();
}

class _AddToScheduleSheetState extends ConsumerState<_AddToScheduleSheet> {
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _selectedScheduleId;

  List<ReminderSchedule> get _availableSchedules {
    return widget.schedules
        .where((s) => !s.relativeIds.contains(widget.relative.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                themeColors.background1.withValues(alpha: 0.95),
                themeColors.background2.withValues(alpha: 0.98),
              ],
            ),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildHeader(themeColors),
              // Divider
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      themeColors.primary.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              if (_isSuccess)
                _buildSuccessState(themeColors)
              else if (_isLoading)
                _buildLoadingState(themeColors)
              else
                _buildScheduleOptions(themeColors),
              SizedBox(height: bottomPadding + AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  themeColors.primary.withValues(alpha: 0.5),
                  themeColors.primary.withValues(alpha: 0.2),
                ],
              ),
            ),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: themeColors.background2,
              ),
              child: Center(
                child: Text(
                  widget.relative.displayEmoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
          ).animate().scale(
                duration: 400.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.relative.fullName,
                  style: AppTypography.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  getSideAwareLabel(widget.relative.relationshipType, widget.relative.familySide, widget.relative.gender),
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white54,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white54,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleOptions(ThemeColors themeColors) {
    if (_availableSchedules.isEmpty) {
      return _buildEmptyState(themeColors);
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اختر التذكير',
            style: AppTypography.labelLarge.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ..._availableSchedules.asMap().entries.map((entry) {
            final index = entry.key;
            final schedule = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ScheduleOptionCard(
                schedule: schedule,
                isSelected: _selectedScheduleId == schedule.id,
                themeColors: themeColors,
                validRelativeCount: widget.allRelatives
                    .where((r) => schedule.relativeIds.contains(r.id))
                    .length,
                onTap: () => _addToSchedule(schedule),
              ),
            )
                .animate(delay: (100 + index * 50).ms)
                .fadeIn()
                .slideY(begin: 0.1);
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: themeColors.primary.withValues(alpha: 0.1),
            ),
            child: Icon(
              widget.schedules.isEmpty
                  ? Icons.alarm_add_rounded
                  : Icons.check_circle_rounded,
              size: 40,
              color: themeColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            widget.schedules.isEmpty
                ? 'لا توجد تذكيرات'
                : 'مضاف لكل التذكيرات',
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.schedules.isEmpty
                ? 'أنشئ تذكير أولاً لإضافة الأقارب'
                : 'هذا القريب مضاف لجميع التذكيرات المتاحة',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white38,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildLoadingState(ThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: themeColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'جاري الإضافة...',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(ThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade400,
                  Colors.green.shade600,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 40,
            ),
          ).animate().scale(
                duration: 400.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'تمت الإضافة بنجاح!',
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ).animate(delay: 200.ms).fadeIn(),
        ],
      ),
    );
  }

  Future<void> _addToSchedule(ReminderSchedule schedule) async {
    setState(() {
      _isLoading = true;
      _selectedScheduleId = schedule.id;
    });

    HapticFeedback.mediumImpact();

    try {
      final service = ref.read(reminderSchedulesServiceProvider);
      final updatedRelativeIds = [
        ...schedule.relativeIds,
        widget.relative.id,
      ];

      await service.updateSchedule(
        schedule.id,
        schedule.copyWith(relativeIds: updatedRelativeIds).toJson(),
      );

      // Invalidate stream so schedule list updates immediately
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref.invalidate(reminderSchedulesStreamProvider(user.id));
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });

        HapticFeedback.heavyImpact();

        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedScheduleId = null;
        });
        UIHelpers.showSnackBar(
          context,
          'خطأ: $e',
          isError: true,
        );
      }
    }
  }
}

/// Individual schedule option card
class _ScheduleOptionCard extends StatelessWidget {
  const _ScheduleOptionCard({
    required this.schedule,
    required this.isSelected,
    required this.themeColors,
    required this.validRelativeCount,
    required this.onTap,
  });

  final ReminderSchedule schedule;
  final bool isSelected;
  final ThemeColors themeColors;
  final int validRelativeCount;
  final VoidCallback onTap;

  Color get _frequencyColor {
    switch (schedule.frequency) {
      case ReminderFrequency.daily:
        return Colors.red.shade400;
      case ReminderFrequency.weekly:
        return Colors.amber.shade400;
      case ReminderFrequency.monthly:
        return Colors.green.shade400;
      case ReminderFrequency.friday:
        return Colors.indigo.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _frequencyColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    schedule.frequency.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.frequency.arabicName,
                      style: AppTypography.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$validRelativeCount أقارب',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.add_circle_outline_rounded,
                color: Colors.white38,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
