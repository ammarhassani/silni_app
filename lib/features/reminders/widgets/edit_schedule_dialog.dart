import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/reminder_schedule_model.dart';
import '../../../shared/services/reminder_schedules_service.dart';
import 'day_selector_widget.dart';

/// Dialog for editing an existing reminder schedule
class EditScheduleDialog extends ConsumerStatefulWidget {
  const EditScheduleDialog({
    super.key,
    required this.schedule,
  });

  final ReminderSchedule schedule;

  @override
  ConsumerState<EditScheduleDialog> createState() => _EditScheduleDialogState();
}

class _EditScheduleDialogState extends ConsumerState<EditScheduleDialog> {
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
    if (time != null) {
      setState(() => _selectedTime = time);
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار يوم من الشهر')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث التذكير بنجاح')),
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
              WeekDaySelector(
                selectedDays: _selectedDays,
                onDaySelected: (dayNumber) {
                  setState(() {
                    _selectedDays.clear();
                    _selectedDays.add(dayNumber);
                  });
                },
              ),
            ],

            if (widget.schedule.frequency == ReminderFrequency.monthly) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'يوم من الشهر',
                style: AppTypography.titleMedium.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sm),
              MonthDaySelector(
                selectedDay: _selectedDayOfMonth,
                onDaySelected: (day) {
                  setState(() => _selectedDayOfMonth = day);
                },
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
          onPressed: _saveChanges,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
