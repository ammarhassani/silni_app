import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';

/// Shared day selector widget for weekly reminders.
///
/// Enhanced with WCAG 2.1 AA touch targets (44px min), haptic feedback,
/// animated selection glow, and semantic labels.
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

            return Semantics(
              label: _days[index],
              selected: isSelected,
              button: true,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onDaySelected(dayNumber);
                },
                child: AnimatedContainer(
                  duration: AppAnimations.fast,
                  curve: AppAnimations.toggleCurve,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? themeColors.primaryGradient
                        : LinearGradient(
                            colors: [
                              themeColors.glassBackground,
                              themeColors.glassBackground,
                            ],
                          ),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: isSelected
                          ? themeColors.primary
                          : themeColors.glassBorder,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: themeColors.primary
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    _days[index],
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
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

/// Month day selector widget for monthly reminders.
///
/// Grid of numbered day buttons (1-31) with glass styling,
/// WCAG 2.1 AA touch targets (44px), haptic feedback, and glow on selection.
class MonthDaySelector extends ConsumerWidget {
  const MonthDaySelector({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final int? selectedDay;
  final ValueChanged<int> onDaySelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: List.generate(31, (index) {
        final day = index + 1;
        final isSelected = selectedDay == day;

        return Semantics(
          label: 'اليوم $day',
          selected: isSelected,
          button: true,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onDaySelected(day);
            },
            child: AnimatedContainer(
              duration: AppAnimations.fast,
              curve: AppAnimations.toggleCurve,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? themeColors.primaryGradient
                    : LinearGradient(
                        colors: [
                          themeColors.glassBackground,
                          themeColors.glassBackground,
                        ],
                      ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: isSelected
                      ? themeColors.primary
                      : themeColors.glassBorder,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color:
                              themeColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
