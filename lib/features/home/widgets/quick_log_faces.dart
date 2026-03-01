import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/providers/cache_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/contact_priority_service.dart';
import '../../../core/services/one_question_engine.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/interaction_model.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/widgets/follow_up_question_sheet.dart';
import '../../../shared/widgets/relative_avatar.dart';
import '../providers/home_providers.dart';

/// Shows a row of up to 4 avatar faces for one-tap interaction logging.
///
/// Tapping a face immediately logs a "call" interaction for that relative
/// and shows a confirmation SnackBar with an optional "add details" link.
/// Household relatives are excluded (they don't need contact tracking).
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
        final filteredRelatives = relatives
            .where(
                (r) => r.relativeCategory != RelativeCategory.household)
            .toList();
        final suggestions =
            ContactPriorityService.getQuickLogSuggestions(filteredRelatives, limit: 4);

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
            '⚡ تواصل سريع',
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
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 80),
                child: Text(
                  widget.relative.fullName,
                  style: AppTypography.labelSmall.copyWith(
                    color: widget.themeColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
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
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'إضافة تفاصيل',
              onPressed: () {
                if (context.mounted) {
                  context.push(
                    '${AppRoutes.relativeDetail}/${widget.relative.id}',
                  );
                }
              },
            ),
          ),
        );
      }

      // Check for follow-up question (delayed)
      Future.delayed(const Duration(milliseconds: 1500), () async {
        if (!context.mounted) return;
        final prefs = await SharedPreferences.getInstance();
        final question = await OneQuestionEngine.getQuestion(
          relative: widget.relative,
          prefs: prefs,
        );
        if (question != null && context.mounted) {
          FollowUpQuestionSheet.show(
            context,
            question: question,
            relativeId: widget.relative.id,
            onSubmit: (field, answer) async {
              // Whitelist allowed fields to prevent column-name injection
              const allowedFields = {
                'interests', 'health_status', 'communication_style',
                'best_time_to_contact', 'sensitive_topics',
              };
              if (!allowedFields.contains(field)) return;

              try {
                // Array fields need list values
                const arrayFields = {'interests', 'sensitive_topics'};
                final value = arrayFields.contains(field) ? [answer] : answer;

                await SupabaseConfig.client
                    .from('relatives')
                    .update({field: value})
                    .eq('id', widget.relative.id);
                // Record the answer only on success
                await OneQuestionEngine.recordAnswer(
                  relativeId: widget.relative.id,
                  questionKey: question.key,
                  prefs: prefs,
                );
              } catch (_) {
                // Silently fail — non-critical enrichment
              }
            },
          );
        }
      });
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
