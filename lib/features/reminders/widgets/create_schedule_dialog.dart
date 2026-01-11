import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/reminder_schedule_model.dart';
import '../../../shared/services/reminder_schedules_service.dart';
import '../../../shared/widgets/collapsible_picker.dart';
import 'day_selector_widget.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../shared/widgets/theme_aware_dialog.dart';

/// Dialog for creating a new reminder schedule
class CreateScheduleDialog extends ConsumerStatefulWidget {
  const CreateScheduleDialog({
    super.key,
    required this.template,
    required this.userId,
  });

  final ReminderTemplate template;
  final String userId;

  @override
  ConsumerState<CreateScheduleDialog> createState() => _CreateScheduleDialogState();
}

class _CreateScheduleDialogState extends ConsumerState<CreateScheduleDialog> {
  late TimeOfDay _selectedTime;
  final List<int> _selectedDays = [];
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
    // Validate weekly schedule has at least one day selected
    if (widget.template.frequency == ReminderFrequency.weekly && _selectedDays.isEmpty) {
      UIHelpers.showSnackBar(
        context,
        'يرجى اختيار يوم من أيام الأسبوع',
        isError: true,
      );
      return;
    }

    // Validate monthly schedule has a day selected
    if (widget.template.frequency == ReminderFrequency.monthly && _selectedDayOfMonth == null) {
      UIHelpers.showSnackBar(
        context,
        'يرجى اختيار يوم من الشهر',
        isError: true,
      );
      return;
    }

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
        UIHelpers.showSnackBar(
          context,
          'تم إنشاء التذكير بنجاح',
          backgroundColor: AppColors.islamicGreenPrimary,
        );
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          'حدث خطأ أثناء إنشاء التذكير',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemeAwareAlertDialog(
      title: 'إنشاء ${widget.template.title}',
      titleIcon: const Icon(Icons.add_alarm_rounded, color: Colors.white),
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
                expandedContent: WeekDaySelector(
                  selectedDays: _selectedDays,
                  onDaySelected: (dayNumber) {
                    setState(() {
                      _selectedDays.clear();
                      _selectedDays.add(dayNumber);
                    });
                  },
                ),
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
                    : 'اليوم $_selectedDayOfMonth',
                expandedContent: MonthDaySelector(
                  selectedDay: _selectedDayOfMonth,
                  onDaySelected: (day) {
                    setState(() => _selectedDayOfMonth = day);
                  },
                  useDropdown: true,
                ),
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
        TextButton(
          onPressed: _createSchedule,
          child: const Text('إنشاء'),
        ),
      ],
    );
  }
}
