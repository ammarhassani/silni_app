import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/ai_briefing_provider.dart';

/// Proactive AI briefing card — "واصل يقولك"
class AIBriefingCard extends ConsumerWidget {
  const AIBriefingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefingAsync = ref.watch(aiBriefingProvider);
    final themeColors = ref.watch(themeColorsProvider);

    return briefingAsync.when(
      data: (briefing) {
        if (briefing == null) return const SizedBox.shrink();
        return GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: themeColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'واصل يقولك:',
                    style: AppTypography.labelMedium.copyWith(
                      color: themeColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Message
              Row(
                children: [
                  Text(briefing.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      briefing.message,
                      style: AppTypography.bodyLarge.copyWith(
                        color: themeColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (briefing.actions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: briefing.actions.map((action) {
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: AppSpacing.sm,
                      ),
                      child: _ActionButton(
                        action: action,
                        relativeId: briefing.relativeId,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        )
            .animate()
            .fadeIn(duration: AppAnimations.modal)
            .slideY(
              begin: AppAnimations.slideUpOffset,
              end: 0,
              duration: AppAnimations.modal,
            );
      },
      loading: () => GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: themeColors.textSecondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              width: 80,
              height: 14,
              decoration: BoxDecoration(
                color: themeColors.textSecondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final BriefingAction action;
  final String? relativeId;

  const _ActionButton({required this.action, this.relativeId});

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (action) {
      BriefingAction.call => (Icons.call_rounded, 'اتصل'),
      BriefingAction.message => (Icons.message_rounded, 'راسل'),
      BriefingAction.visit => (Icons.directions_walk_rounded, 'زور'),
    };

    return OutlinedButton.icon(
      onPressed: () {
        HapticFeedback.lightImpact();
        if (relativeId != null) {
          context.push('${AppRoutes.relativeDetail}/$relativeId');
        }
      },
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        textStyle: AppTypography.labelSmall,
      ),
    );
  }
}
