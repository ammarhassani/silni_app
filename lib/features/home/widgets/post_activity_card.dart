import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/providers/cache_provider.dart';
import '../../../core/services/contact_priority_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/interaction_model.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/relative_avatar.dart';
import '../providers/home_providers.dart';

/// Shows a "كلمت [name]?" card when the user returns to the app.
///
/// Detects app resume via a provider and suggests the most likely
/// relative the user just contacted. One tap to confirm = logs interaction.
/// One tap to dismiss = hides until next app resume.
class PostActivityCard extends ConsumerStatefulWidget {
  const PostActivityCard({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<PostActivityCard> createState() => _PostActivityCardState();
}

class _PostActivityCardState extends ConsumerState<PostActivityCard>
    with WidgetsBindingObserver {
  bool _showSuggestion = false;
  bool _isSubmitting = false;
  Relative? _suggestedRelative;
  String? _dismissedSession;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    } else if (state == AppLifecycleState.paused) {
      // Reset dismissed state when app goes to background
      _dismissedSession = null;
    }
  }

  void _onAppResumed() {
    // Don't show if already dismissed this session
    if (_dismissedSession != null) return;

    final relativesAsync = ref.read(viewerFilteredRelativesProvider);
    relativesAsync.whenData((relatives) {
      if (relatives.isEmpty) return;

      final suggestions =
          ContactPriorityService.getQuickLogSuggestions(relatives, limit: 1);
      if (suggestions.isEmpty) return;

      final suggested = suggestions.first;
      // Only suggest if they haven't been contacted today and gap > 1 day
      if (suggested.daysSinceLastContact != null &&
          suggested.daysSinceLastContact! > 0) {
        if (mounted) {
          setState(() {
            _suggestedRelative = suggested;
            _showSuggestion = true;
          });
        }
      }
    });
  }

  void _dismiss() {
    _dismissedSession = 'dismissed';
    if (mounted) {
      setState(() => _showSuggestion = false);
    }
  }

  Future<void> _confirmInteraction() async {
    if (_suggestedRelative == null || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(interactionsRepositoryProvider);
      await repository.createInteraction(Interaction(
        id: '',
        userId: widget.userId,
        relativeId: _suggestedRelative!.id,
        type: InteractionType.call,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'تم تسجيل تواصل مع ${_suggestedRelative!.fullName} ✅'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _showSuggestion = false);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء تسجيل التواصل'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showSuggestion || _suggestedRelative == null) {
      return const SizedBox.shrink();
    }

    final themeColors = ref.watch(themeColorsProvider);
    final relative = _suggestedRelative!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            RelativeAvatar(
              relative: relative,
              size: RelativeAvatar.sizeSmall,
              showNeedsAttentionBadge: false,
              showFavoriteBadge: false,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'كلمت ${relative.fullName}؟',
                    style: AppTypography.titleSmall.copyWith(
                      color: themeColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (relative.daysSinceLastContact != null)
                    Text(
                      'آخر تواصل قبل ${relative.daysSinceLastContact} يوم',
                      style: AppTypography.bodySmall.copyWith(
                        color: themeColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            // Confirm button
            GestureDetector(
              onTap: _isSubmitting ? null : _confirmInteraction,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: themeColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'إيه ✅',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Dismiss button
            GestureDetector(
              onTap: _dismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: themeColors.textSecondary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'لا',
                  style: AppTypography.labelSmall.copyWith(
                    color: themeColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: AppAnimations.normal).slideY(begin: -0.1, end: 0),
    );
  }
}
