import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/contact_priority_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/relative_avatar.dart';
import '../providers/home_providers.dart';

/// Shows the #1 priority relative the user should contact today.
///
/// If everyone is up to date, shows a happy "all good" message.
class DailyPriorityCard extends ConsumerWidget {
  const DailyPriorityCard({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final relativesAsync = ref.watch(viewerFilteredRelativesProvider);

    return relativesAsync.when(
      data: (relatives) {
        final priorities =
            ContactPriorityService.getTodayPriority(relatives, limit: 1);

        if (priorities.isEmpty) {
          return _buildAllGoodState(themeColors);
        }

        return _buildPriorityCard(context, priorities.first, themeColors);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildAllGoodState(dynamic themeColors) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Text(
            '💚',
            style: AppTypography.headlineSmall,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'عائلتك بخير!',
              style: AppTypography.titleMedium.copyWith(
                color: themeColors.statusSuccess,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildPriorityCard(
    BuildContext context,
    Relative relative,
    dynamic themeColors,
  ) {
    final daysSince = relative.daysSinceLastContact;
    final daysText = daysSince != null ? _arabicDays(daysSince) : '∞';

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      semanticsLabel: 'أولوية اليوم: تواصل مع ${relative.fullName}',
      child: Row(
        children: [
          RelativeAvatar(
            relative: relative,
            size: RelativeAvatar.sizeMedium,
            showNeedsAttentionBadge: true,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أولوية اليوم',
                  style: AppTypography.labelMedium.copyWith(
                    color: themeColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'كلم ${relative.fullName}، لهم $daysText',
                  style: AppTypography.titleSmall.copyWith(
                    color: themeColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton.icon(
            onPressed: () => _onCallTap(context, relative),
            icon: const Icon(Icons.phone, size: AppSpacing.iconSm),
            label: const Text('كلّمهم'),
            style: FilledButton.styleFrom(
              backgroundColor: themeColors.primary,
              foregroundColor: themeColors.onPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              textStyle: AppTypography.labelMedium,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  /// Arabic day pluralization: 1 → يوم واحد, 2 → يومين, 3-10 → أيام, 11+ → يوم
  String _arabicDays(int days) {
    if (days == 1) return 'يوم واحد';
    if (days == 2) return 'يومين';
    if (days >= 3 && days <= 10) return '$days أيام';
    return '$days يوم';
  }

  Future<void> _onCallTap(BuildContext context, Relative relative) async {
    if (relative.phoneNumber != null && relative.phoneNumber!.isNotEmpty) {
      final uri = Uri(scheme: 'tel', path: relative.phoneNumber);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    }
    // Fallback: navigate to relative detail
    if (context.mounted) {
      context.push('${AppRoutes.relativeDetail}/${relative.id}');
    }
  }
}
