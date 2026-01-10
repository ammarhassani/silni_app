import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/models/interaction_model.dart';
import '../../../../core/providers/cache_provider.dart';
import '../../../../shared/widgets/mood_selector.dart';

/// List of recent interactions for a relative
class RelativeInteractionsList extends ConsumerWidget {
  const RelativeInteractionsList({
    super.key,
    required this.relativeId,
  });

  final String relativeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    final repository = ref.watch(interactionsRepositoryProvider);

    return StreamBuilder<List<Interaction>>(
      stream: repository.watchRelativeInteractions(relativeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: CircularProgressIndicator(color: themeColors.primary),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: GlassCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'لا توجد تفاعلات بعد',
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'ابدأ بتسجيل تواصلك مع هذا القريب',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white60,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final interactions = snapshot.data!.take(5).toList();

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: interactions.map((interaction) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _InteractionCard(
                  interaction: interaction,
                  themeColors: themeColors,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _InteractionCard extends StatelessWidget {
  const _InteractionCard({
    required this.interaction,
    required this.themeColors,
  });

  final Interaction interaction;
  final dynamic themeColors;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: themeColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Center(
              child: Text(
                interaction.type.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  interaction.type.arabicName,
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  interaction.relativeTime,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (interaction.notes != null &&
                    interaction.notes!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    interaction.notes!,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white60,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Location display
                if (interaction.location != null &&
                    interaction.location!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          interaction.location!,
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                // Photo indicator
                if (interaction.photoUrls.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(
                        Icons.photo_library,
                        size: 12,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${interaction.photoUrls.length} صور',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Mood emoji display
          if (interaction.mood != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Builder(
              builder: (context) {
                final moodOption = MoodOption.fromString(interaction.mood);
                final moodColor =
                    moodOption?.getColor(themeColors) ?? themeColors.moodNeutral;
                return Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: moodColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    moodOption?.emoji ?? '',
                    style: const TextStyle(fontSize: 18),
                  ),
                );
              },
            ),
          ],
          if (interaction.duration != null)
            Column(
              children: [
                const Icon(
                  Icons.timer,
                  color: AppColors.premiumGold,
                  size: 16,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  interaction.formattedDuration,
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
