import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';

/// Custom inline glassmorphic time picker with dual scroll wheels.
///
/// Replaces the Material `showTimePicker()` with an embedded, premium
/// scroll-wheel picker. Uses `ListWheelScrollView` for smooth snapping.
class GlassTimePicker extends ConsumerStatefulWidget {
  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final double height;

  const GlassTimePicker({
    super.key,
    required this.initialTime,
    required this.onTimeChanged,
    this.height = 180,
  });

  @override
  ConsumerState<GlassTimePicker> createState() => _GlassTimePickerState();
}

class _GlassTimePickerState extends ConsumerState<GlassTimePicker> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late int _selectedHour;
  late int _selectedMinute;

  static const _itemExtent = 44.0;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hour;
    _selectedMinute = widget.initialTime.minute;
    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController =
        FixedExtentScrollController(initialItem: _selectedMinute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _onHourChanged(int index) {
    HapticFeedback.selectionClick();
    setState(() => _selectedHour = index);
    widget.onTimeChanged(TimeOfDay(hour: _selectedHour, minute: _selectedMinute));
  }

  void _onMinuteChanged(int index) {
    HapticFeedback.selectionClick();
    setState(() => _selectedMinute = index);
    widget.onTimeChanged(TimeOfDay(hour: _selectedHour, minute: _selectedMinute));
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);

    return Semantics(
      label: 'اختيار الوقت',
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: themeColors.glassBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: themeColors.glassBorder,
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            // Center selection highlight band
            Center(
              child: Container(
                height: _itemExtent,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: themeColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: themeColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
            ),

            // Wheels row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Minutes wheel (RTL: minutes first on the right)
                Expanded(
                  child: _buildWheel(
                    controller: _minuteController,
                    itemCount: 60,
                    onChanged: _onMinuteChanged,
                    selectedIndex: _selectedMinute,
                    labelBuilder: (i) => i.toString().padLeft(2, '0'),
                    semanticsPrefix: 'دقيقة',
                    themeColors: themeColors,
                  ),
                ),

                // Colon separator
                Text(
                  ':',
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Hours wheel
                Expanded(
                  child: _buildWheel(
                    controller: _hourController,
                    itemCount: 24,
                    onChanged: _onHourChanged,
                    selectedIndex: _selectedHour,
                    labelBuilder: (i) => i.toString().padLeft(2, '0'),
                    semanticsPrefix: 'ساعة',
                    themeColors: themeColors,
                  ),
                ),
              ],
            ),

            // Top and bottom fade gradients for depth
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: widget.height * 0.3,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        themeColors.glassBackground,
                        themeColors.glassBackground.withValues(alpha: 0),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: widget.height * 0.3,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        themeColors.glassBackground,
                        themeColors.glassBackground.withValues(alpha: 0),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required ValueChanged<int> onChanged,
    required int selectedIndex,
    required String Function(int) labelBuilder,
    required String semanticsPrefix,
    required dynamic themeColors,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: _itemExtent,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      diameterRatio: 1.5,
      perspective: 0.003,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) {
          final isSelected = index == selectedIndex;
          return Semantics(
            label: '$semanticsPrefix ${labelBuilder(index)}',
            selected: isSelected,
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: isSelected
                    ? AppTypography.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      )
                    : AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                child: Text(labelBuilder(index)),
              ),
            ),
          );
        },
      ),
    );
  }
}
