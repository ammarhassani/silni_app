import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/reminder_schedule_model.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/services/reminder_schedules_service.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../shared/widgets/glass_bottom_sheet.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_providers.dart';

/// Glass bottom sheet for adding relatives to a reminder schedule.
class AddRelativesBottomSheet extends ConsumerStatefulWidget {
  const AddRelativesBottomSheet({
    super.key,
    required this.schedule,
    required this.relatives,
    this.relationshipLabels,
  });

  final ReminderSchedule schedule;
  final List<Relative> relatives;
  final Map<String, String>? relationshipLabels;

  @override
  ConsumerState<AddRelativesBottomSheet> createState() =>
      _AddRelativesBottomSheetState();
}

class _AddRelativesBottomSheetState
    extends ConsumerState<AddRelativesBottomSheet> {
  final Set<String> _selectedRelativeIds = {};
  bool _isLoading = false;
  bool _isSuccess = false;

  void _addRelatives() async {
    setState(() => _isLoading = true);

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

      // Invalidate stream so UI updates immediately
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref.invalidate(reminderSchedulesStreamProvider(user.id));
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });

        HapticFeedback.heavyImpact();

        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) {
          Navigator.pop(context, _selectedRelativeIds.toList());
        }
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
    final themeColors = ref.watch(themeColorsProvider);

    return GlassBottomSheet(
      icon: _isSuccess ? Icons.check_circle_rounded : Icons.person_add_rounded,
      title: _isSuccess ? 'تمت الإضافة!' : 'إضافة أقارب للتذكير',
      child: _isSuccess
          ? _buildSuccessState(themeColors)
          : widget.relatives.isEmpty
              ? _buildEmptyState(themeColors)
              : _buildContent(themeColors),
    );
  }

  Widget _buildSuccessState(dynamic themeColors) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 200),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.shade400,
                      Colors.green.shade600,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ).animate().scale(
                    duration: 400.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'تم إضافة ${_selectedRelativeIds.length} أقارب للتذكير',
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ).animate(delay: 200.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(dynamic themeColors) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: themeColors.primary.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.check_circle_rounded,
              size: 40,
              color: themeColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'جميع الأقارب مضافون بالفعل',
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildContent(dynamic themeColors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Gradient divider
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                themeColors.primary.withValues(alpha: 0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),

        // Relative list
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            itemCount: widget.relatives.length,
            itemBuilder: (context, index) {
              final relative = widget.relatives[index];
              final isSelected =
                  _selectedRelativeIds.contains(relative.id);

              return _RelativeRow(
                relative: relative,
                isSelected: isSelected,
                themeColors: themeColors,
                label: widget.relationshipLabels?[relative.id],
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (isSelected) {
                      _selectedRelativeIds.remove(relative.id);
                    } else {
                      _selectedRelativeIds.add(relative.id);
                    }
                  });
                },
              )
                  .animate(delay: (50 * index).ms)
                  .fadeIn()
                  .slideY(begin: 0.1);
            },
          ),
        ),

        // Sticky bottom action
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: GradientButton(
            text: _selectedRelativeIds.isEmpty
                ? 'اختر أقارب'
                : 'إضافة (${_selectedRelativeIds.length})',
            icon: Icons.person_add_rounded,
            onPressed: _addRelatives,
            enabled: _selectedRelativeIds.isNotEmpty,
            isLoading: _isLoading,
          ),
        ),
      ],
    );
  }
}

/// A single selectable relative row with custom animated checkmark.
class _RelativeRow extends StatelessWidget {
  const _RelativeRow({
    required this.relative,
    required this.isSelected,
    required this.themeColors,
    required this.onTap,
    this.label,
  });

  final Relative relative;
  final bool isSelected;
  final dynamic themeColors;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: relative.fullName,
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          curve: AppAnimations.toggleCurve,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          decoration: BoxDecoration(
            color: isSelected
                ? themeColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isSelected
                  ? themeColors.primary.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Emoji avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: themeColors.primary.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(
                    relative.displayEmoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Name + relationship
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      relative.fullName,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label ?? relative.relationshipType.arabicName,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // Custom animated checkmark
              AnimatedContainer(
                duration: AppAnimations.fast,
                curve: AppAnimations.toggleCurve,
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isSelected ? themeColors.primaryGradient : null,
                  color: isSelected
                      ? null
                      : Colors.white.withValues(alpha: 0.1),
                  border: Border.all(
                    color: isSelected
                        ? themeColors.primary
                        : Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
