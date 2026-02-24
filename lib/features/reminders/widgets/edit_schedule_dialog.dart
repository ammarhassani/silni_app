import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/reminder_schedule_model.dart';
import '../../../core/providers/cache_provider.dart';
import '../../home/providers/home_providers.dart';
import '../../../shared/widgets/glass_bottom_sheet.dart';
import '../../../shared/widgets/gradient_button.dart';
import 'day_selector_widget.dart';
import 'glass_time_picker.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../core/theme/theme_provider.dart';

/// Glass bottom sheet for editing an existing reminder schedule.
class EditScheduleBottomSheet extends ConsumerStatefulWidget {
  const EditScheduleBottomSheet({
    super.key,
    required this.schedule,
  });

  final ReminderSchedule schedule;

  @override
  ConsumerState<EditScheduleBottomSheet> createState() =>
      _EditScheduleBottomSheetState();
}

class _EditScheduleBottomSheetState
    extends ConsumerState<EditScheduleBottomSheet> {
  late TimeOfDay _selectedTime;
  late List<int> _selectedDays;
  late int? _selectedDayOfMonth;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final parts = widget.schedule.time.split(':');
    _selectedTime = TimeOfDay(
      hour: parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 9) : 9,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
    _selectedDays = List.from(widget.schedule.customDays ?? []);
    _selectedDayOfMonth = widget.schedule.dayOfMonth;
  }

  void _saveChanges() async {
    if (widget.schedule.frequency == ReminderFrequency.weekly &&
        _selectedDays.isEmpty) {
      UIHelpers.showSnackBar(
        context,
        'يرجى اختيار يوم للتذكير الأسبوعي',
        isError: true,
      );
      return;
    }
    if (widget.schedule.frequency == ReminderFrequency.monthly &&
        _selectedDayOfMonth == null) {
      UIHelpers.showSnackBar(
        context,
        'يرجى اختيار يوم من الشهر',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    final repository = ref.read(reminderSchedulesRepositoryProvider);

    try {
      final timeString =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
      final updatedSchedule = widget.schedule.copyWith(
        time: timeString,
        customDays: _selectedDays,
        dayOfMonth: _selectedDayOfMonth,
      );
      await repository.updateSchedule(
        widget.schedule.id,
        updatedSchedule.toJson(),
      );

      // Invalidate the stream provider so the list refreshes immediately
      ref.invalidate(reminderSchedulesStreamProvider(widget.schedule.userId));

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);
        UIHelpers.showSnackBar(context, 'تم تحديث التذكير بنجاح');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        UIHelpers.showSnackBar(context, 'خطأ: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeColorsProvider);

    return GlassBottomSheet(
      icon: Icons.edit_calendar_rounded,
      title: 'تعديل التذكير',
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time picker section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'وقت التذكير',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GlassTimePicker(
                    initialTime: _selectedTime,
                    onTimeChanged: (time) {
                      setState(() => _selectedTime = time);
                    },
                  ),
                ],
              ),
            ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.05),

            // Weekly day selector
            if (widget.schedule.frequency ==
                ReminderFrequency.weekly) ...[
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'يوم الأسبوع',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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
                ),
              ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.05),
            ],

            // Monthly day selector
            if (widget.schedule.frequency ==
                ReminderFrequency.monthly) ...[
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'يوم من الشهر',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    MonthDaySelector(
                      selectedDay: _selectedDayOfMonth,
                      onDaySelected: (day) {
                        setState(() => _selectedDayOfMonth = day);
                      },
                    ),
                  ],
                ),
              ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.05),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Save button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: GradientButton(
                text: 'حفظ',
                icon: Icons.save_rounded,
                onPressed: _saveChanges,
                isLoading: _isLoading,
              ),
            ).animate(delay: 400.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}
