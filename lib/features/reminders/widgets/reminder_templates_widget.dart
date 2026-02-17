import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/reminder_schedule_model.dart';

/// Bottom sheet displaying reminder template options vertically.
/// Filters out frequencies that already have a schedule.
class CreateScheduleBottomSheet extends ConsumerWidget {
  const CreateScheduleBottomSheet({
    super.key,
    required this.onTemplateSelected,
    required this.usedFrequencies,
  });

  final void Function(ReminderTemplate template) onTemplateSelected;
  final Set<ReminderFrequency> usedFrequencies;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    final availableTemplates = ReminderTemplate.templates
        .where((t) => !usedFrequencies.contains(t.frequency))
        .toList();

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
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
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
              const SizedBox(height: AppSpacing.lg),
              // Title
              Text(
                'اختر نوع التذكير',
                style: AppTypography.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Template list (only unused frequencies)
              ...availableTemplates.asMap().entries.map((entry) {
                final index = entry.key;
                final template = entry.value;
                return _TemplateOptionTile(
                  template: template,
                  themeColors: themeColors,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTemplateSelected(template);
                  },
                )
                    .animate(delay: (50 * index).ms)
                    .fadeIn()
                    .slideY(begin: 0.1);
              }),
              SizedBox(height: bottomPadding + AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateOptionTile extends StatelessWidget {
  const _TemplateOptionTile({
    required this.template,
    required this.themeColors,
    required this.onTap,
  });

  final ReminderTemplate template;
  final ThemeColors themeColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                // Emoji in rounded square
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: themeColors.primary.withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Center(
                    child: Text(
                      template.frequency.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Title + description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.title,
                        style: AppTypography.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        template.description,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Arrow
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white38,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
