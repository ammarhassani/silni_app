import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/providers/cache_provider.dart';
import '../../../core/services/contact_priority_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/interaction_model.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/widgets/relative_avatar.dart';
import '../providers/home_providers.dart';

/// Shows a row of 2-3 avatar faces for one-tap interaction logging.
///
/// Tapping a face immediately logs a "call" interaction for that relative
/// and shows a confirmation SnackBar.
class QuickLogFaces extends ConsumerWidget {
  const QuickLogFaces({
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
        final suggestions =
            ContactPriorityService.getQuickLogSuggestions(relatives, limit: 3);

        if (suggestions.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildFacesRow(context, ref, suggestions, themeColors);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildFacesRow(
    BuildContext context,
    WidgetRef ref,
    List<Relative> suggestions,
    dynamic themeColors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            'سجّل تواصل سريع',
            style: AppTypography.titleSmall.copyWith(
              color: themeColors.textSecondary,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: suggestions.asMap().entries.map((entry) {
            final index = entry.key;
            final relative = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                left: index < suggestions.length - 1 ? AppSpacing.md : 0,
              ),
              child: _QuickLogFace(
                relative: relative,
                userId: userId,
                themeColors: themeColors,
              ),
            ).animate().fadeIn(
                  delay: Duration(milliseconds: index * 80),
                  duration: 300.ms,
                );
          }).toList(),
        ),
      ],
    );
  }
}

class _QuickLogFace extends ConsumerStatefulWidget {
  const _QuickLogFace({
    required this.relative,
    required this.userId,
    required this.themeColors,
  });

  final Relative relative;
  final String userId;
  final dynamic themeColors;

  @override
  ConsumerState<_QuickLogFace> createState() => _QuickLogFaceState();
}

class _QuickLogFaceState extends ConsumerState<_QuickLogFace> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isSubmitting ? null : () => _logInteraction(context),
      child: Semantics(
        label: 'سجّل تواصل مع ${widget.relative.fullName}',
        button: true,
        child: Opacity(
          opacity: _isSubmitting ? 0.5 : 1.0,
          child: Column(
            children: [
              RelativeAvatar(
                relative: widget.relative,
                size: RelativeAvatar.sizeMedium,
                showNeedsAttentionBadge: false,
                showFavoriteBadge: false,
              ),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                width: 70,
                child: Text(
                  widget.relative.fullName,
                  style: AppTypography.labelSmall.copyWith(
                    color: widget.themeColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logInteraction(BuildContext context) async {
    setState(() => _isSubmitting = true);
    try {
      final repository = ref.read(interactionsRepositoryProvider);
      await repository.createInteraction(Interaction(
        id: '',
        userId: widget.userId,
        relativeId: widget.relative.id,
        type: InteractionType.call,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تسجيل تواصل مع ${widget.relative.fullName} ✅'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء تسجيل التواصل'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
