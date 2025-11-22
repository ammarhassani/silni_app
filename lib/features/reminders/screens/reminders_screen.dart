import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/models/reminder_schedule_model.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/services/relatives_service.dart';
import '../../../shared/services/reminder_schedules_service.dart';
import '../../auth/providers/auth_provider.dart';

// Providers
final reminderSchedulesServiceProvider = Provider((ref) => ReminderSchedulesService());

final reminderSchedulesStreamProvider = StreamProvider.family<List<ReminderSchedule>, String>((ref, userId) {
  final service = ref.watch(reminderSchedulesServiceProvider);
  return service.getSchedulesStream(userId);
});

final relativesServiceProvider = Provider((ref) => RelativesService());

final relativesStreamProvider = StreamProvider.family<List<Relative>, String>((ref, userId) {
  final service = ref.watch(relativesServiceProvider);
  return service.getRelativesStream(userId);
});

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  ReminderFrequency? _selectedFrequency;
  final Map<ReminderFrequency, List<String>> _selectedRelatives = {
    ReminderFrequency.daily: [],
    ReminderFrequency.weekly: [],
    ReminderFrequency.monthly: [],
    ReminderFrequency.friday: [],
  };

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.uid ?? '';

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
                      data: (schedules) => _buildContent(context, relatives, schedules),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => _buildError(),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
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
                  style: AppTypography.h2.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'نظّم تذكيراتك للتواصل مع أحبتك',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Relative> relatives, List<ReminderSchedule> schedules) {
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
            style: AppTypography.h3.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildReminderTemplates(),
          const SizedBox(height: AppSpacing.xl),

          // Schedule Cards
          Text(
            '📅 جداول التذكير',
            style: AppTypography.h3.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildScheduleCards(schedules, relatives),
          const SizedBox(height: AppSpacing.xl),

          // Unassigned Relatives
          if (_getUnassignedRelatives(relatives, schedules).isNotEmpty) ...[
            Text(
              '👥 الأقارب غير المضافين',
              style: AppTypography.h3.copyWith(color: Colors.white),
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
          padding: AppSpacing.md,
          gradient: isSelected
              ? AppColors.goldenGradient
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    template.frequency.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                ],
              ),
              const Spacer(),
              Text(
                template.title,
                style: AppTypography.h4.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                template.description,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ).animate().fadeIn().scale(),
    );
  }

  Widget _buildScheduleCards(List<ReminderSchedule> schedules, List<Relative> relatives) {
    if (schedules.isEmpty) {
      return GlassCard(
        padding: AppSpacing.lg,
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
                color: Colors.white.withOpacity(0.7),
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

  Widget _buildScheduleCard(ReminderSchedule schedule, List<Relative> allRelatives) {
    final scheduledRelatives = allRelatives
        .where((r) => schedule.relativeIds.contains(r.id))
        .toList();

    return GlassCard(
      padding: AppSpacing.md,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                      style: AppTypography.h4.copyWith(color: Colors.white),
                    ),
                    Text(
                      schedule.description,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: schedule.isActive,
                onChanged: (value) => _toggleSchedule(schedule, value),
                activeColor: AppColors.islamicGreenPrimary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: Colors.white24),
          const SizedBox(height: AppSpacing.md),

          // Relatives in this schedule
          if (scheduledRelatives.isEmpty)
            Text(
              'لا يوجد أقارب في هذا التذكير',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.5),
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
                  onPressed: () => _showAddRelativesToSchedule(schedule, allRelatives),
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
    ).animate().fadeIn().slideX();
  }

  Widget _buildRelativeChip(Relative relative, ReminderSchedule schedule) {
    return Chip(
      avatar: Text(relative.displayEmoji, style: const TextStyle(fontSize: 18)),
      label: Text(
        relative.fullName,
        style: AppTypography.bodySmall.copyWith(color: Colors.white),
      ),
      backgroundColor: AppColors.islamicGreenPrimary.withOpacity(0.3),
      deleteIcon: const Icon(Icons.close_rounded, size: 18, color: Colors.white70),
      onDeleted: () => _removeRelativeFromSchedule(schedule, relative.id),
    );
  }

  Widget _buildUnassignedRelatives(List<Relative> allRelatives, List<ReminderSchedule> schedules) {
    final unassigned = _getUnassignedRelatives(allRelatives, schedules);

    return GlassCard(
      padding: AppSpacing.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اسحب الأقارب لإضافتهم إلى تذكير',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.7),
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.islamicGreenPrimary.withOpacity(0.3),
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

  List<Relative> _getUnassignedRelatives(List<Relative> allRelatives, List<ReminderSchedule> schedules) {
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
          padding: AppSpacing.xl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👥', style: TextStyle(fontSize: 64)),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'لا يوجد أقارب بعد',
                style: AppTypography.h3.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'أضف أقاربك أولاً لتتمكن من إنشاء تذكيرات',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.7),
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
        margin: AppSpacing.xl,
        padding: AppSpacing.xl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              'حدث خطأ في تحميل البيانات',
              style: AppTypography.bodyLarge.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateScheduleDialog(ReminderTemplate template) {
    final user = ref.read(currentUserProvider);
    final userId = user?.uid ?? '';

    showDialog(
      context: context,
      builder: (context) => _CreateScheduleDialog(
        template: template,
        userId: userId,
      ),
    );
  }

  void _showAddRelativesToSchedule(ReminderSchedule schedule, List<Relative> allRelatives) {
    final unassigned = allRelatives
        .where((r) => !schedule.relativeIds.contains(r.id))
        .toList();

    showDialog(
      context: context,
      builder: (context) => _AddRelativesDialog(
        schedule: schedule,
        relatives: unassigned,
      ),
    );
  }

  void _toggleSchedule(ReminderSchedule schedule, bool value) async {
    final service = ref.read(reminderSchedulesServiceProvider);
    try {
      await service.updateSchedule(
        schedule.id,
        schedule.copyWith(isActive: value).toFirestore(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  void _editSchedule(ReminderSchedule schedule) {
    // TODO: Implement edit schedule
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قريباً: تعديل التذكير')),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف التذكير')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: $e')),
          );
        }
      }
    }
  }

  void _removeRelativeFromSchedule(ReminderSchedule schedule, String relativeId) async {
    final service = ref.read(reminderSchedulesServiceProvider);
    try {
      final updatedRelativeIds = List<String>.from(schedule.relativeIds)
        ..remove(relativeId);

      await service.updateSchedule(
        schedule.id,
        schedule.copyWith(relativeIds: updatedRelativeIds).toFirestore(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }
}

// Dialog for creating a new schedule
class _CreateScheduleDialog extends ConsumerStatefulWidget {
  final ReminderTemplate template;
  final String userId;

  const _CreateScheduleDialog({
    required this.template,
    required this.userId,
  });

  @override
  ConsumerState<_CreateScheduleDialog> createState() => _CreateScheduleDialogState();
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.darkBackground,
      title: Text(
        'إنشاء ${widget.template.title}',
        style: AppTypography.h3.copyWith(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.template.description,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Time Picker
            GlassCard(
              padding: AppSpacing.md,
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded, color: Colors.white),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'الوقت: ${_selectedTime.format(context)}',
                    style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Weekly days selector
            if (widget.template.frequency == ReminderFrequency.weekly) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'اختر الأيام:',
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDaySelector(),
            ],

            // Monthly day selector
            if (widget.template.frequency == ReminderFrequency.monthly) ...[
              const SizedBox(height: AppSpacing.md),
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
        TextButton(
          onPressed: _createSchedule,
          child: const Text('إنشاء'),
        ),
      ],
    );
  }

  Widget _buildDaySelector() {
    final days = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: List.generate(7, (index) {
        final dayNumber = index == 6 ? 7 : index + 1;
        final isSelected = _selectedDays.contains(dayNumber);

        return FilterChip(
          label: Text(days[index]),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedDays.add(dayNumber);
              } else {
                _selectedDays.remove(dayNumber);
              }
            });
          },
          selectedColor: AppColors.islamicGreenPrimary,
          checkmarkColor: Colors.white,
        );
      }),
    );
  }

  Widget _buildMonthDaySelector() {
    return GlassCard(
      padding: AppSpacing.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اختر يوم من الشهر (1-31):',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButton<int>(
            value: _selectedDayOfMonth,
            hint: const Text('اختر اليوم'),
            isExpanded: true,
            dropdownColor: AppColors.darkBackground,
            items: List.generate(31, (index) {
              final day = index + 1;
              return DropdownMenuItem(
                value: day,
                child: Text('اليوم $day', style: const TextStyle(color: Colors.white)),
              );
            }),
            onChanged: (value) {
              setState(() => _selectedDayOfMonth = value);
            },
          ),
        ],
      ),
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
        time: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        customDays: widget.template.frequency == ReminderFrequency.weekly ? _selectedDays : null,
        dayOfMonth: widget.template.frequency == ReminderFrequency.monthly ? _selectedDayOfMonth : null,
        createdAt: DateTime.now(),
      );

      await service.createSchedule(schedule.toFirestore());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء التذكير بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }
}

// Dialog for adding relatives to a schedule
class _AddRelativesDialog extends ConsumerStatefulWidget {
  final ReminderSchedule schedule;
  final List<Relative> relatives;

  const _AddRelativesDialog({
    required this.schedule,
    required this.relatives,
  });

  @override
  ConsumerState<_AddRelativesDialog> createState() => _AddRelativesDialogState();
}

class _AddRelativesDialogState extends ConsumerState<_AddRelativesDialog> {
  final Set<String> _selectedRelativeIds = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.darkBackground,
      title: Text(
        'إضافة أقارب للتذكير',
        style: AppTypography.h3.copyWith(color: Colors.white),
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
                        Text(relative.displayEmoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          relative.fullName,
                          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      relative.relationshipType.arabicName,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    activeColor: AppColors.islamicGreenPrimary,
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
        widget.schedule.copyWith(relativeIds: updatedRelativeIds).toFirestore(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إضافة ${_selectedRelativeIds.length} أقارب للتذكير'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }
}
