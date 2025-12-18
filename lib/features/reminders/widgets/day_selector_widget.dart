import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';

/// Shared day selector widget for weekly reminders
class WeekDaySelector extends ConsumerWidget {
  const WeekDaySelector({
    super.key,
    required this.selectedDays,
    required this.onDaySelected,
    this.singleSelection = true,
  });

  final List<int> selectedDays;
  final ValueChanged<int> onDaySelected;
  final bool singleSelection;

  static const _days = [
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          singleSelection
              ? 'اختر يوم واحد للتذكير الأسبوعي'
              : 'اختر أيام التذكير',
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
            final isSelected = singleSelection
                ? selectedDays.length == 1 && selectedDays.contains(dayNumber)
                : selectedDays.contains(dayNumber);

            return GestureDetector(
              onTap: () => onDaySelected(dayNumber),
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
                  _days[index],
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
}

/// Month day selector widget for monthly reminders
class MonthDaySelector extends ConsumerWidget {
  const MonthDaySelector({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
    this.useDropdown = false,
  });

  final int? selectedDay;
  final ValueChanged<int> onDaySelected;
  final bool useDropdown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (useDropdown) {
      return _buildDropdown(context);
    }
    return _buildGrid(ref);
  }

  Widget _buildDropdown(BuildContext context) {
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
            value: selectedDay,
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
              if (value != null) onDaySelected(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(31, (index) {
        final day = index + 1;
        final isSelected = selectedDay == day;

        return GestureDetector(
          onTap: () => onDaySelected(day),
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
}
