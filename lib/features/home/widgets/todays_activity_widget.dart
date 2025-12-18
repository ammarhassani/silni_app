import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/models/interaction_model.dart';

/// Today's interaction activity list widget
class TodaysActivityWidget extends StatelessWidget {
  const TodaysActivityWidget({
    super.key,
    required this.interactions,
    required this.relatives,
  });

  final List<Interaction> interactions;
  final List<Relative> relatives;

  @override
  Widget build(BuildContext context) {
    if (interactions.isEmpty) return const SizedBox.shrink();

    // Create a map for quick relative lookup
    final relativeMap = {for (var r in relatives) r.id: r};

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
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
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'سجل التواصل',
                style: AppTypography.titleSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: AppSpacing.sm),
          // Compact list
          ...interactions.take(4).map((interaction) {
            final relative = relativeMap[interaction.relativeId];
            return _CompactInteractionItem(
              interaction: interaction,
              relative: relative,
            );
          }),
        ],
      ),
    );
  }
}

class _CompactInteractionItem extends StatelessWidget {
  const _CompactInteractionItem({
    required this.interaction,
    required this.relative,
  });

  final Interaction interaction;
  final Relative? relative;

  @override
  Widget build(BuildContext context) {
    final relativeName = relative?.fullName ?? 'قريب';

    return GestureDetector(
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
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Time
            Text(
              interaction.relativeTime,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
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
