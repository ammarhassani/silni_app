import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/reminder_schedule_model.dart';
import '../../../shared/services/reminder_schedules_service.dart';
import '../../../shared/widgets/collapsible_picker.dart';
import '../../../shared/widgets/glass_bottom_sheet.dart';
import '../../../shared/widgets/gradient_button.dart';
import 'day_selector_widget.dart';
import 'glass_time_picker.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../core/theme/theme_provider.dart';

/// Glass bottom sheet for creating a new reminder schedule.
class CreateScheduleConfigSheet extends ConsumerStatefulWidget {
  const CreateScheduleConfigSheet({
    super.key,
    required this.template,
    required this.userId,
  });

  final ReminderTemplate template;
  final String userId;

  @override
  ConsumerState<CreateScheduleConfigSheet> createState() =>
      _CreateScheduleConfigSheetState();
}

class _CreateScheduleConfigSheetState
    extends ConsumerState<CreateScheduleConfigSheet> {
  late TimeOfDay _selectedTime;
  final List<int> _selectedDays = [];
  int? _selectedDayOfMonth;
  bool _isLoading = false;

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
      '',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    if (dayNumber >= 1 && dayNumber <= 7) return days[dayNumber];
    return '';
  }

  void _createSchedule() async {
    if (widget.template.frequency == ReminderFrequency.weekly &&
        _selectedDays.isEmpty) {
      UIHelpers.showSnackBar(
        context,
        'يرجى اختيار يوم من أيام الأسبوع',
        isError: true,
      );
      return;
    }

    if (widget.template.frequency == ReminderFrequency.monthly &&
        _selectedDayOfMonth == null) {
      UIHelpers.showSnackBar(
        context,
        'يرجى اختيار يوم من الشهر',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
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
        UIHelpers.showSnackBar(context, 'تم إنشاء التذكير بنجاح');
      }
    } catch (e) {
      setState(() => _isLoading = false);
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
    ref.watch(themeColorsProvider);

    return GlassBottomSheet(
      icon: Icons.add_alarm_rounded,
      title: 'إنشاء ${widget.template.title}',
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                widget.template.description,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ).animate(delay: 200.ms).fadeIn(),

            const SizedBox(height: AppSpacing.lg),

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
            ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.05),

            // Weekly days selector
            if (widget.template.frequency ==
                ReminderFrequency.weekly) ...[
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: CollapsiblePicker(
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
              ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.05),
            ],

            // Monthly day selector
            if (widget.template.frequency ==
                ReminderFrequency.monthly) ...[
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: CollapsiblePicker(
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
                  ),
                ),
              ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.05),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Create button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: GradientButton(
                text: 'إنشاء',
                icon: Icons.add_alarm_rounded,
                onPressed: _createSchedule,
                isLoading: _isLoading,
              ),
            ).animate(delay: 500.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}
