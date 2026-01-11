import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/reminder_schedule_model.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/services/reminder_schedules_service.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../shared/widgets/theme_aware_dialog.dart';

/// Dialog for adding relatives to a reminder schedule
class AddRelativesDialog extends ConsumerStatefulWidget {
  const AddRelativesDialog({
    super.key,
    required this.schedule,
    required this.relatives,
  });

  final ReminderSchedule schedule;
  final List<Relative> relatives;

  @override
  ConsumerState<AddRelativesDialog> createState() => _AddRelativesDialogState();
}

class _AddRelativesDialogState extends ConsumerState<AddRelativesDialog> {
  final Set<String> _selectedRelativeIds = {};

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
        UIHelpers.showSnackBar(
          context,
          'تم إضافة ${_selectedRelativeIds.length} أقارب للتذكير',
          backgroundColor: AppColors.islamicGreenPrimary,
        );
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          'خطأ: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);

    return ThemeAwareAlertDialog(
      title: 'إضافة أقارب للتذكير',
      titleIcon: const Icon(Icons.person_add_rounded, color: Colors.white),
      padding: const EdgeInsets.only(top: AppSpacing.md),
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
        ThemeAwareDialogButton(
          text: 'إلغاء',
          isPrimary: false,
          onPressed: () => Navigator.pop(context),
        ),
        ThemeAwareDialogButton(
          text: 'إضافة',
          isPrimary: true,
          onPressed: _selectedRelativeIds.isEmpty ? () {} : _addRelatives,
        ),
      ],
    );
  }
}
