import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/collapsible_picker.dart';
import '../../../shared/models/reminder_schedule_model.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/services/reminder_schedules_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/screens/home_screen.dart';
import '../../../core/providers/realtime_provider.dart';

// Providers - Note: reminderSchedulesServiceProvider is imported from shared/services/reminder_schedules_service.dart
// Note: relativesStreamProvider is imported from features/home/screens/home_screen.dart

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  ReminderFrequency? _selectedFrequency;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';

    // Initialize real-time subscriptions for this user
    ref.watch(autoRealtimeSubscriptionsProvider);

    final schedulesAsync = ref.watch(reminderSchedulesStreamProvider(userId));
    final relativesAsync = ref.watch(relativesStreamProvider(userId));

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(animated: true, child: SizedBox.expand()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: relativesAsync.when(
                    data: (relatives) => schedulesAsync.when(
                      data: (schedules) =>
                          _buildContent(context, relatives, schedules),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) => _buildError(),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => _buildError(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تذكير صلة الرحم',
                  style: AppTypography.headlineLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'نظّم تذكيراتك للتواصل مع أحبتك',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Relative> relatives,
    List<ReminderSchedule> schedules,
  ) {
    if (relatives.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reminder Templates Section
          Text(
            '✨ اختر نوع التذكير',
            style: AppTypography.headlineMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildReminderTemplates(),
          const SizedBox(height: AppSpacing.xl),

          // Schedule Cards
          Text(
            '📅 جداول التذكير',
            style: AppTypography.headlineMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildScheduleCards(schedules, relatives),
          const SizedBox(height: AppSpacing.xl),

          // Unassigned Relatives
          if (_getUnassignedRelatives(relatives, schedules).isNotEmpty) ...[
            Text(
              '👥 الأقارب غير المضافين',
              style: AppTypography.headlineMedium.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildUnassignedRelatives(relatives, schedules),
            const SizedBox(height: AppSpacing.xl),
          ],
        ],
      ),
    );
  }

  Widget _buildReminderTemplates() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ReminderTemplate.templates.length,
        itemBuilder: (context, index) {
          final template = ReminderTemplate.templates[index];
          return _buildTemplateCard(template);
        },
      ),
    );
  }

  Widget _buildTemplateCard(ReminderTemplate template) {
    final isSelected = _selectedFrequency == template.frequency;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFrequency = isSelected ? null : template.frequency;
        });

        if (!isSelected) {
          _showCreateScheduleDialog(template);
        }
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          gradient: isSelected
              ? AppColors.goldenGradient
              : LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    template.frequency.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                template.title,
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  template.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn().scale(),
    );
  }

  Widget _buildScheduleCards(
    List<ReminderSchedule> schedules,
    List<Relative> relatives,
  ) {
    if (schedules.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const Text('📝', style: TextStyle(fontSize: 48)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'لا توجد جداول تذكير بعد',
              style: AppTypography.bodyLarge.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'اختر نوع تذكير من الأعلى للبدء',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: schedules.map((schedule) {
        return _buildScheduleCard(schedule, relatives);
      }).toList(),
    );
  }

  Widget _buildScheduleCard(
    ReminderSchedule schedule,
    List<Relative> allRelatives,
  ) {
    // Use theme-aware colors
    final themeColors = ref.watch(themeColorsProvider);

    final scheduledRelatives = allRelatives
        .where((r) => schedule.relativeIds.contains(r.id))
        .toList();

    return DragTarget<Relative>(
      onWillAcceptWithDetails: (details) =>
          !schedule.relativeIds.contains(details.data.id),
      onAcceptWithDetails: (details) => _handleDragTarget(details, schedule),
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
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            schedule.description,
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: schedule.isActive,
                      onChanged: (value) => _toggleSchedule(schedule, value),
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
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  )
                else
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: scheduledRelatives.map((relative) {
                      return _buildRelativeChip(relative, schedule);
                    }).toList(),
                  ),

                const SizedBox(height: AppSpacing.md),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        onPressed: () =>
                            _showAddRelativesToSchedule(schedule, allRelatives),
                        text: 'إضافة أقارب',
                        icon: Icons.person_add_rounded,
                        height: 40,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    GradientButton(
                      onPressed: () => _editSchedule(schedule),
                      text: '',
                      icon: Icons.edit_rounded,
                      height: 40,
                      width: 50,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    GradientButton(
                      onPressed: () => _deleteSchedule(schedule),
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

  Widget _buildRelativeChip(Relative relative, ReminderSchedule schedule) {
    // Use theme-aware colors for chips
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
            onTap: () => _removeRelativeFromSchedule(schedule, relative.id),
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

  Widget _buildUnassignedRelatives(
    List<Relative> allRelatives,
    List<ReminderSchedule> schedules,
  ) {
    final unassigned = _getUnassignedRelatives(allRelatives, schedules);

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اسحب الأقارب لإضافتهم إلى تذكير',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: unassigned.map((relative) {
              return Draggable<Relative>(
                data: relative,
                feedback: Material(
                  color: Colors.transparent,
                  child: Opacity(
                    opacity: 0.8,
                    child: _buildRelativeAvatarCard(relative),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: _buildRelativeAvatarCard(relative),
                ),
                child: _buildRelativeAvatarCard(relative),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRelativeAvatarCard(Relative relative) {
    // Use theme-aware colors
    final themeColors = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: themeColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: themeColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(relative.displayEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: AppSpacing.sm),
          Text(
            relative.fullName,
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  List<Relative> _getUnassignedRelatives(
    List<Relative> allRelatives,
    List<ReminderSchedule> schedules,
  ) {
    final assignedIds = schedules
        .expand((schedule) => schedule.relativeIds)
        .toSet();

    return allRelatives
        .where((relative) => !assignedIds.contains(relative.id))
        .toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👥', style: TextStyle(fontSize: 64)),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'لا يوجد أقارب بعد',
                style: AppTypography.headlineMedium.copyWith(
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'أضف أقاربك أولاً لتتمكن من إنشاء تذكيرات',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              GradientButton(
                onPressed: () => context.pop(),
                text: 'إضافة أقارب',
                icon: Icons.person_add_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: GlassCard(
        margin: const EdgeInsets.all(AppSpacing.xl),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'حدث خطأ في تحميل البيانات',
              style: AppTypography.bodyLarge.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'يرجى التحقق من الاتصال بالإنترنت والمحاولة مرة أخرى',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            GradientButton(
              onPressed: () {
                // Force refresh by invalidating the provider
                final user = ref.read(currentUserProvider);
                if (user != null) {
                  ref.invalidate(reminderSchedulesStreamProvider(user.id));
                }
              },
              text: 'إعادة المحاولة',
              icon: Icons.refresh_rounded,
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateScheduleDialog(ReminderTemplate template) {
    final user = ref.read(currentUserProvider);
    final userId = user?.id ?? '';

    showDialog(
      context: context,
      builder: (context) =>
          _CreateScheduleDialog(template: template, userId: userId),
    );
  }

  void _showAddRelativesToSchedule(
    ReminderSchedule schedule,
    List<Relative> allRelatives,
  ) {
    final unassigned = allRelatives
        .where((r) => !schedule.relativeIds.contains(r.id))
        .toList();

    showDialog(
      context: context,
      builder: (context) =>
          _AddRelativesDialog(schedule: schedule, relatives: unassigned),
    );
  }

  void _toggleSchedule(ReminderSchedule schedule, bool value) async {
    final service = ref.read(reminderSchedulesServiceProvider);
    try {
      await service.updateSchedule(
        schedule.id,
        schedule.copyWith(isActive: value).toJson(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  void _editSchedule(ReminderSchedule schedule) {
    showDialog(
      context: context,
      builder: (context) => _EditScheduleDialog(schedule: schedule),
    );
  }

  void _deleteSchedule(ReminderSchedule schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف التذكير'),
        content: const Text('هل أنت متأكد من حذف هذا التذكير؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final service = ref.read(reminderSchedulesServiceProvider);
      try {
        await service.deleteSchedule(schedule.id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تم حذف التذكير')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
        }
      }
    }
  }

  void _removeRelativeFromSchedule(
    ReminderSchedule schedule,
    String relativeId,
  ) async {
    final service = ref.read(reminderSchedulesServiceProvider);
    try {
      final updatedRelativeIds = List<String>.from(schedule.relativeIds)
        ..remove(relativeId);

      await service.updateSchedule(
        schedule.id,
        schedule.copyWith(relativeIds: updatedRelativeIds).toJson(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  /// Handle drag target for adding relatives to schedule
  void _handleDragTarget(DragTargetDetails details, ReminderSchedule schedule) {
    final relative = details.data as Relative;

    // Add relative to schedule
    final updatedRelativeIds = [...schedule.relativeIds, relative.id];

    // Update the schedule
    _updateScheduleRelativeIds(schedule.id, updatedRelativeIds);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت إضافة ${relative.fullName} إلى التذكير'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Update schedule with new relative IDs
  void _updateScheduleRelativeIds(
    String scheduleId,
    List<String> newRelativeIds,
  ) async {
    final service = ref.read(reminderSchedulesServiceProvider);
    try {
      await service.updateSchedule(scheduleId, {
        'relative_ids': newRelativeIds,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }
}

// Dialog for creating a new schedule
class _CreateScheduleDialog extends ConsumerStatefulWidget {
  final ReminderTemplate template;
  final String userId;

  const _CreateScheduleDialog({required this.template, required this.userId});

  @override
  ConsumerState<_CreateScheduleDialog> createState() =>
      _CreateScheduleDialogState();
}

class _CreateScheduleDialogState extends ConsumerState<_CreateScheduleDialog> {
  late TimeOfDay _selectedTime;
  List<int> _selectedDays = [];
  int? _selectedDayOfMonth;

  @override
  void initState() {
    super.initState();
    final parts = widget.template.defaultTime.split(':');
    _selectedTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _getDayName(int dayNumber) {
    const days = [
      '', // 0 - not used
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    if (dayNumber >= 1 && dayNumber <= 7) {
      return days[dayNumber];
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);
    return AlertDialog(
      backgroundColor: themeColors.background1.withValues(alpha: 0.95),
      title: Text(
        'إنشاء ${widget.template.title}',
        style: AppTypography.headlineMedium.copyWith(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.template.description,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Time Picker - Collapsible
            CollapsiblePicker(
              title: 'وقت التذكير',
              icon: Icons.access_time_rounded,
              summaryText: _selectedTime.format(context),
              initiallyExpanded: true,
              expandedContent: Column(
                children: [
                  Text(
                    'اختر الوقت المناسب لإرسال التذكير',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text(
                      'تغيير الوقت: ${_selectedTime.format(context)}',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Weekly days selector - Collapsible
            if (widget.template.frequency == ReminderFrequency.weekly) ...[
              const SizedBox(height: AppSpacing.md),
              CollapsiblePicker(
                title: 'يوم الأسبوع',
                icon: Icons.calendar_view_week_rounded,
                summaryText: _selectedDays.isEmpty
                    ? 'لم يتم اختيار يوم بعد'
                    : _getDayName(_selectedDays.first),
                expandedContent: _buildDaySelector(),
              ),
            ],

            // Monthly day selector - Collapsible
            if (widget.template.frequency == ReminderFrequency.monthly) ...[
              const SizedBox(height: AppSpacing.md),
              CollapsiblePicker(
                title: 'يوم من الشهر',
                icon: Icons.calendar_month_rounded,
                summaryText: _selectedDayOfMonth == null
                    ? 'اختر يوم من الشهر'
                    : 'اليوم ${_selectedDayOfMonth}',
                expandedContent: _buildMonthDaySelector(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        TextButton(onPressed: _createSchedule, child: const Text('إنشاء')),
      ],
    );
  }

  Widget _buildDaySelector() {
    // Use theme-aware colors
    final themeColors = ref.watch(themeColorsProvider);
    final days = [
      'الأحد',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر يوم واحد للتذكير الأسبوعي',
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: List.generate(7, (index) {
            final dayNumber = index == 6 ? 7 : index + 1;
            // Single selection: check if this is the only selected day
            final isSelected = _selectedDays.length == 1 && _selectedDays.contains(dayNumber);

            return GestureDetector(
              onTap: () {
                setState(() {
                  // Single selection: clear and set only this day
                  _selectedDays.clear();
                  _selectedDays.add(dayNumber);
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? themeColors.primaryGradient
                      : LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.1),
                            Colors.white.withValues(alpha: 0.05),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isSelected
                        ? themeColors.primary
                        : Colors.white.withValues(alpha: 0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  days[index],
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMonthDaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر يوم من الشهر (1-31):',
          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: DropdownButton<int>(
            value: _selectedDayOfMonth,
            hint: Text(
              'اختر اليوم',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: const Color(0xFF1A1A1A),
            items: List.generate(31, (index) {
              final day = index + 1;
              return DropdownMenuItem(
                value: day,
                child: Text(
                  'اليوم $day',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }),
            onChanged: (value) {
              setState(() => _selectedDayOfMonth = value);
            },
          ),
        ),
      ],
    );
  }

  void _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  void _createSchedule() async {
    final service = ref.read(reminderSchedulesServiceProvider);

    try {
      final schedule = ReminderSchedule(
        id: '',
        userId: widget.userId,
        frequency: widget.template.frequency,
        relativeIds: [],
        time:
            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        customDays: widget.template.frequency == ReminderFrequency.weekly
            ? _selectedDays
            : null,
        dayOfMonth: widget.template.frequency == ReminderFrequency.monthly
            ? _selectedDayOfMonth
            : null,
        createdAt: DateTime.now(),
      );

      await service.createSchedule(schedule.toJson());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم إنشاء التذكير بنجاح')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }
}

// Dialog for adding relatives to a schedule
class _AddRelativesDialog extends ConsumerStatefulWidget {
  final ReminderSchedule schedule;
  final List<Relative> relatives;

  const _AddRelativesDialog({required this.schedule, required this.relatives});

  @override
  ConsumerState<_AddRelativesDialog> createState() =>
      _AddRelativesDialogState();
}

class _AddRelativesDialogState extends ConsumerState<_AddRelativesDialog> {
  final Set<String> _selectedRelativeIds = {};

  @override
  Widget build(BuildContext context) {
    // Use theme-aware colors
    final themeColors = ref.watch(themeColorsProvider);

    return AlertDialog(
      backgroundColor: themeColors.background1.withValues(alpha: 0.95),
      title: Text(
        'إضافة أقارب للتذكير',
        style: AppTypography.headlineMedium.copyWith(color: Colors.white),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.relatives.isEmpty
            ? Text(
                'جميع الأقارب مضافون بالفعل',
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: widget.relatives.length,
                itemBuilder: (context, index) {
                  final relative = widget.relatives[index];
                  final isSelected = _selectedRelativeIds.contains(relative.id);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedRelativeIds.add(relative.id);
                        } else {
                          _selectedRelativeIds.remove(relative.id);
                        }
                      });
                    },
                    title: Row(
                      children: [
                        Text(
                          relative.displayEmoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          relative.fullName,
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      relative.relationshipType.arabicName,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    activeColor: themeColors.primary,
                    checkColor: Colors.white,
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: _selectedRelativeIds.isEmpty ? null : _addRelatives,
          child: const Text('إضافة'),
        ),
      ],
    );
  }

  void _addRelatives() async {
    final service = ref.read(reminderSchedulesServiceProvider);

    try {
      final updatedRelativeIds = [
        ...widget.schedule.relativeIds,
        ..._selectedRelativeIds,
      ];

      await service.updateSchedule(
        widget.schedule.id,
        widget.schedule.copyWith(relativeIds: updatedRelativeIds).toJson(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إضافة ${_selectedRelativeIds.length} أقارب للتذكير',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }
}

// Edit Schedule Dialog
class _EditScheduleDialog extends ConsumerStatefulWidget {
  final ReminderSchedule schedule;

  const _EditScheduleDialog({required this.schedule});

  @override
  ConsumerState<_EditScheduleDialog> createState() =>
      _EditScheduleDialogState();
}

class _EditScheduleDialogState extends ConsumerState<_EditScheduleDialog> {
  late TimeOfDay _selectedTime;
  late List<int> _selectedDays;
  late int? _selectedDayOfMonth;

  @override
  void initState() {
    super.initState();
    final parts = widget.schedule.time.split(':');
    _selectedTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    _selectedDays = List.from(widget.schedule.customDays ?? []);
    _selectedDayOfMonth = widget.schedule.dayOfMonth;
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(data: ThemeData.dark(), child: child!),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Widget _buildDaySelector() {
    final themeColors = ref.watch(themeColorsProvider);
    final days = [
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر يوم واحد للتذكير الأسبوعي',
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(7, (index) {
            // Single selection: check if this day is the only selected day
            final isSelected = _selectedDays.length == 1 && _selectedDays.contains(index);
            return GestureDetector(
              onTap: () {
                setState(() {
                  // Single selection: clear and set only this day
                  _selectedDays.clear();
                  _selectedDays.add(index);
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? themeColors.primaryGradient
                      : LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.1),
                            Colors.white.withValues(alpha: 0.05),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isSelected
                        ? themeColors.primary
                        : Colors.white.withValues(alpha: 0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  days[index],
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMonthDaySelector() {
    final themeColors = ref.watch(themeColorsProvider);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(31, (index) {
        final day = index + 1;
        final isSelected = _selectedDayOfMonth == day;
        return GestureDetector(
          onTap: () => setState(() => _selectedDayOfMonth = day),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? themeColors.primaryGradient
                  : LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: isSelected
                    ? themeColors.primary
                    : Colors.white.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                '$day',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);
    return AlertDialog(
      backgroundColor: themeColors.background1.withValues(alpha: 0.95),
      title: Text(
        'تعديل التذكير',
        style: AppTypography.headlineMedium.copyWith(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'وقت التذكير',
              style: AppTypography.titleMedium.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.schedule_rounded),
              label: Text('الوقت: ${_selectedTime.format(context)}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
            if (widget.schedule.frequency == ReminderFrequency.weekly) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'يوم الأسبوع',
                style: AppTypography.titleMedium.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDaySelector(),
            ],
            if (widget.schedule.frequency == ReminderFrequency.monthly) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'يوم من الشهر',
                style: AppTypography.titleMedium.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildMonthDaySelector(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        TextButton(onPressed: _saveChanges, child: const Text('حفظ')),
      ],
    );
  }

  void _saveChanges() async {
    if (widget.schedule.frequency == ReminderFrequency.weekly &&
        _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار يوم للتذكير الأسبوعي')),
      );
      return;
    }
    if (widget.schedule.frequency == ReminderFrequency.monthly &&
        _selectedDayOfMonth == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى اختيار يوم من الشهر')));
      return;
    }

    final service = ref.read(reminderSchedulesServiceProvider);
    try {
      final timeString =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
      final updatedSchedule = widget.schedule.copyWith(
        time: timeString,
        customDays: _selectedDays,
        dayOfMonth: _selectedDayOfMonth,
      );
      await service.updateSchedule(
        widget.schedule.id,
        updatedSchedule.toJson(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم تحديث التذكير بنجاح')));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }
}
