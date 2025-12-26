import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/models/interaction_model.dart';

/// Today's interaction activity list widget
class TodaysActivityWidget extends ConsumerWidget {
  const TodaysActivityWidget({
    super.key,
    required this.interactions,
    required this.relatives,
  });

  final List<Interaction> interactions;
  final List<Relative> relatives;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (interactions.isEmpty) return const SizedBox.shrink();

    final themeColors = ref.watch(themeColorsProvider);

    // Create a map for quick relative lookup
    final relativeMap = {for (var r in relatives) r.id: r};

    return Semantics(
      label: 'سجل التواصل - ${interactions.length} تفاعل',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: themeColors.glassBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: themeColors.glassBorder,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with icon
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: themeColors.glassHighlight,
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    color: themeColors.textSecondary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'سجل التواصل',
                  style: AppTypography.titleSmall.copyWith(
                    color: themeColors.textPrimary.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Divider(color: themeColors.divider, height: 1),
            const SizedBox(height: AppSpacing.sm),
            // Compact list
            ...interactions.take(4).map((interaction) {
              final relative = relativeMap[interaction.relativeId];
              return _CompactInteractionItem(
                interaction: interaction,
                relative: relative,
                themeColors: themeColors,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CompactInteractionItem extends StatelessWidget {
  const _CompactInteractionItem({
    required this.interaction,
    required this.relative,
    required this.themeColors,
  });

  final Interaction interaction;
  final Relative? relative;
  final dynamic themeColors;

  @override
  Widget build(BuildContext context) {
    final relativeName = relative?.fullName ?? 'قريب';

    return Semantics(
      label: '${interaction.type.arabicName} مع $relativeName',
      button: relative != null,
      child: GestureDetector(
        onTap: relative != null
            ? () => context.push('${AppRoutes.relativeDetail}/${relative!.id}')
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              // Interaction emoji in colored circle
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getInteractionColor(interaction.type).withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(
                    interaction.type.emoji,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Name
              Expanded(
                child: Text(
                  relativeName,
                  style: AppTypography.bodySmall.copyWith(
                    color: themeColors.textPrimary.withValues(alpha: 0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Time
              Text(
                interaction.relativeTime,
                style: AppTypography.labelSmall.copyWith(
                  color: themeColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getInteractionColor(InteractionType type) {
    switch (type) {
      case InteractionType.call:
        return Colors.green;
      case InteractionType.message:
        return Colors.blue;
      case InteractionType.visit:
        return Colors.orange;
      case InteractionType.gift:
        return Colors.pink;
      case InteractionType.event:
        return Colors.teal;
      case InteractionType.other:
        return Colors.purple;
    }
  }
}
