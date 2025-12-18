import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/reminder_schedule_model.dart';
import '../../../shared/widgets/glass_card.dart';

/// Horizontal list of reminder templates
class ReminderTemplatesWidget extends StatelessWidget {
  const ReminderTemplatesWidget({
    super.key,
    required this.selectedFrequency,
    required this.onTemplateSelected,
  });

  final ReminderFrequency? selectedFrequency;
  final void Function(ReminderTemplate template) onTemplateSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ReminderTemplate.templates.length,
        itemBuilder: (context, index) {
          final template = ReminderTemplate.templates[index];
          return _TemplateCard(
            template: template,
            isSelected: selectedFrequency == template.frequency,
            onTap: () => onTemplateSelected(template),
          );
        },
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  final ReminderTemplate template;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          gradient: isSelected
              ? AppColors.goldenGradient
              : LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    template.frequency.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                template.title,
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  template.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn().scale(),
    );
  }
}
