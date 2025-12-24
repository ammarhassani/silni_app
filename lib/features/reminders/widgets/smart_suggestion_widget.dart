import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/ai/ai_models.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/models/reminder_schedule_model.dart';
import '../../../shared/services/reminder_schedules_service.dart';
import '../providers/smart_suggestion_provider.dart';

/// Compact smart suggestion section for reminders screen
class SmartSuggestionSection extends ConsumerWidget {
  const SmartSuggestionSection({
    super.key,
    required this.relatives,
    required this.schedules,
    required this.userId,
  });

  final List<Relative> relatives;
  final List<ReminderSchedule> schedules;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(smartSuggestionProvider);
    final themeColors = ref.watch(themeColorsProvider);

    // Don't show if loading or no suggestions
    if (state.isLoading && state.suggestions.isEmpty) {
      return _buildLoadingState(themeColors);
    }

    if (state.activeSuggestions.isEmpty && !state.isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeColors.primary.withValues(alpha: 0.12),
            themeColors.primaryLight.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: themeColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          GestureDetector(
            onTap: () => ref.read(smartSuggestionProvider.notifier).toggleExpanded(),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: themeColors.accent,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'اضغط للإضافة',
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ),
                if (state.isLoading)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: themeColors.accent,
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () =>
                        ref.read(smartSuggestionProvider.notifier).toggleExpanded(),
                    child: Icon(
                      state.isExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: Colors.white38,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),

          // Suggestion chips
          if (state.isExpanded) ...[
            const SizedBox(height: AppSpacing.sm),
            Builder(
              builder: (context) {
                // Filter suggestions to only show relatives not in all schedules
                final filteredSuggestions = state.activeSuggestions.where((suggestion) {
                  final relative = _findRelative(suggestion.relativeName);
                  if (relative == null) return false;
                  // Don't show if already in all schedules
                  return !_isRelativeInAllSchedules(relative.id);
                }).take(6).toList();

                if (filteredSuggestions.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: filteredSuggestions.map((suggestion) {
                    final relative = _findRelative(suggestion.relativeName)!;

                    return _SuggestionChip(
                      suggestion: suggestion,
                      relative: relative,
                      schedules: schedules,
                      themeColors: themeColors,
                      onDismiss: () {
                        HapticFeedback.lightImpact();
                        ref
                            .read(smartSuggestionProvider.notifier)
                            .dismissSuggestion(suggestion.relativeName);
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Relative? _findRelative(String name) {
    try {
      return relatives.firstWhere((r) => r.fullName == name);
    } catch (_) {
      return null;
    }
  }

  /// Check if a relative is already in all schedules
  bool _isRelativeInAllSchedules(String relativeId) {
    if (schedules.isEmpty) return false;
    return schedules.every((s) => s.relativeIds.contains(relativeId));
  }

  Widget _buildLoadingState(ThemeColors themeColors) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: themeColors.accent,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'تحليل...',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}

/// Suggestion chip - tap to show add dialog
class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.suggestion,
    required this.relative,
    required this.schedules,
    required this.themeColors,
    required this.onDismiss,
  });

  final SmartReminderSuggestion suggestion;
  final Relative relative;
  final List<ReminderSchedule> schedules;
  final ThemeColors themeColors;
  final VoidCallback onDismiss;

  /// Get suggested reminder frequency based on urgency
  ReminderFrequency get _suggestedFrequency {
    switch (suggestion.urgency) {
      case 'high':
        return ReminderFrequency.daily;
      case 'medium':
        return ReminderFrequency.weekly;
      case 'low':
        return ReminderFrequency.monthly;
      default:
        return ReminderFrequency.weekly;
    }
  }

  Color get _frequencyColor {
    switch (_suggestedFrequency) {
      case ReminderFrequency.daily:
        return Colors.red.shade400;
      case ReminderFrequency.weekly:
        return Colors.amber.shade400;
      case ReminderFrequency.monthly:
        return Colors.green.shade400;
      case ReminderFrequency.friday:
        return Colors.indigo.shade400;
      case ReminderFrequency.custom:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showAddBottomSheet(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _frequencyColor.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji
            Text(
              relative.displayEmoji,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 6),
            // Name
            Text(
              relative.fullName,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            // Suggested frequency indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _frequencyColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _suggestedFrequency.emoji,
                style: const TextStyle(fontSize: 10),
              ),
            ),
            const SizedBox(width: 4),
            // Dismiss
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AddToReminderBottomSheet(
        relative: relative,
        schedules: schedules,
        suggestedFrequency: _suggestedFrequency,
        frequencyColor: _frequencyColor,
      ),
    );
  }
}

/// Bottom sheet to add relative to a reminder
class _AddToReminderBottomSheet extends ConsumerStatefulWidget {
  const _AddToReminderBottomSheet({
    required this.relative,
    required this.schedules,
    required this.suggestedFrequency,
    required this.frequencyColor,
  });

  final Relative relative;
  final List<ReminderSchedule> schedules;
  final ReminderFrequency suggestedFrequency;
  final Color frequencyColor;

  @override
  ConsumerState<_AddToReminderBottomSheet> createState() =>
      _AddToReminderBottomSheetState();
}

class _AddToReminderBottomSheetState
    extends ConsumerState<_AddToReminderBottomSheet> {
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _selectedScheduleId;

  // Filter schedules that don't already have this relative
  List<ReminderSchedule> get _availableSchedules {
    return widget.schedules
        .where((s) => !s.relativeIds.contains(widget.relative.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                themeColors.background1.withValues(alpha: 0.95),
                themeColors.background2.withValues(alpha: 0.98),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header with relative info
              _buildHeader(themeColors),

              // Divider
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

              // Content
              if (_isSuccess)
                _buildSuccessState(themeColors)
              else if (_isLoading)
                _buildLoadingState(themeColors)
              else
                _buildScheduleOptions(themeColors),

              SizedBox(height: bottomPadding + AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          // Avatar with glow effect
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  widget.frequencyColor.withValues(alpha: 0.5),
                  widget.frequencyColor.withValues(alpha: 0.2),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.frequencyColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: themeColors.background2,
              ),
              child: Center(
                child: Text(
                  widget.relative.displayEmoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
          ).animate().scale(
                duration: 400.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(width: AppSpacing.md),

          // Name and relationship
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.relative.fullName,
                  style: AppTypography.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: widget.frequencyColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.frequencyColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.suggestedFrequency.emoji,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.suggestedFrequency.arabicName,
                            style: AppTypography.labelSmall.copyWith(
                              color: widget.frequencyColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'مقترح',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ],
            ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1),
          ),

          // Close button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white54,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleOptions(ThemeColors themeColors) {
    if (_availableSchedules.isEmpty) {
      return _buildEmptyState(themeColors);
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اختر التذكير',
            style: AppTypography.labelLarge.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ..._availableSchedules.asMap().entries.map((entry) {
            final index = entry.key;
            final schedule = entry.value;
            final isRecommended = schedule.frequency == widget.suggestedFrequency;
            final isSelected = _selectedScheduleId == schedule.id;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ScheduleOptionCard(
                schedule: schedule,
                isRecommended: isRecommended,
                isSelected: isSelected,
                themeColors: themeColors,
                onTap: () => _addToSchedule(schedule),
              ),
            ).animate(delay: (100 + index * 50).ms).fadeIn().slideY(begin: 0.1);
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeColors themeColors) {
    return Container(
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
              widget.schedules.isEmpty
                  ? Icons.alarm_add_rounded
                  : Icons.check_circle_rounded,
              size: 40,
              color: themeColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            widget.schedules.isEmpty ? 'لا توجد تذكيرات' : 'مضاف لكل التذكيرات ✓',
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.schedules.isEmpty
                ? 'أنشئ تذكير أولاً لإضافة الأقارب'
                : 'هذا القريب مضاف لجميع التذكيرات المتاحة',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white38,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildLoadingState(ThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: themeColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'جاري الإضافة...',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(ThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
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
            'تمت الإضافة بنجاح!',
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ).animate(delay: 200.ms).fadeIn(),
        ],
      ),
    );
  }

  Future<void> _addToSchedule(ReminderSchedule schedule) async {
    setState(() {
      _isLoading = true;
      _selectedScheduleId = schedule.id;
    });

    HapticFeedback.mediumImpact();

    try {
      final service = ref.read(reminderSchedulesServiceProvider);
      final updatedRelativeIds = [...schedule.relativeIds, widget.relative.id];

      await service.updateSchedule(
        schedule.id,
        schedule.copyWith(relativeIds: updatedRelativeIds).toJson(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });

        HapticFeedback.heavyImpact();

        // Auto close after success
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedScheduleId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// Individual schedule option card
class _ScheduleOptionCard extends StatelessWidget {
  const _ScheduleOptionCard({
    required this.schedule,
    required this.isRecommended,
    required this.isSelected,
    required this.themeColors,
    required this.onTap,
  });

  final ReminderSchedule schedule;
  final bool isRecommended;
  final bool isSelected;
  final ThemeColors themeColors;
  final VoidCallback onTap;

  Color get _frequencyColor {
    switch (schedule.frequency) {
      case ReminderFrequency.daily:
        return Colors.red.shade400;
      case ReminderFrequency.weekly:
        return Colors.amber.shade400;
      case ReminderFrequency.monthly:
        return Colors.green.shade400;
      case ReminderFrequency.friday:
        return Colors.indigo.shade400;
      case ReminderFrequency.custom:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: isRecommended
                ? LinearGradient(
                    colors: [
                      _frequencyColor.withValues(alpha: 0.2),
                      _frequencyColor.withValues(alpha: 0.08),
                    ],
                  )
                : null,
            color: isRecommended ? null : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRecommended
                  ? _frequencyColor.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.1),
              width: isRecommended ? 2 : 1,
            ),
            boxShadow: isRecommended
                ? [
                    BoxShadow(
                      color: _frequencyColor.withValues(alpha: 0.2),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Frequency emoji with background
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _frequencyColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    schedule.frequency.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Schedule info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          schedule.frequency.arabicName,
                          style: AppTypography.titleSmall.copyWith(
                            color: Colors.white,
                            fontWeight:
                                isRecommended ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _frequencyColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  size: 10,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'مقترح',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${schedule.relativeIds.length} أقارب',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.add_circle_outline_rounded,
                color: isRecommended ? _frequencyColor : Colors.white38,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
