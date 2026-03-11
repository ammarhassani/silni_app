import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../shared/utils/relationship_label_helper.dart';
import '../../../shared/widgets/glass_bottom_sheet.dart';
import '../../../shared/widgets/relative_avatar.dart';
import '../../ai_assistant/providers/ai_chat_provider.dart';
import '../providers/home_providers.dart';

/// Shows a row of up to 4 avatar faces for one-tap interaction logging.
///
/// Tapping a face immediately logs a "call" interaction for that relative
/// and shows a confirmation SnackBar with an optional "add details" link.
/// Household relatives are excluded (they don't need contact tracking).
class QuickLogFaces extends ConsumerStatefulWidget {
  const QuickLogFaces({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  ConsumerState<QuickLogFaces> createState() => _QuickLogFacesState();
}

class _QuickLogFacesState extends ConsumerState<QuickLogFaces> {
  /// Track which relative IDs have been logged this session so they disappear
  final _loggedIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);
    final relativesAsync = ref.watch(viewerFilteredRelativesProvider);
    final labels = ref.watch(perspectiveLabelsProvider);

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

        return _buildFacesRow(context, suggestions, themeColors, labels);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildFacesRow(
    BuildContext context,
    List<Relative> suggestions,
    dynamic themeColors,
    Map<String, String> labels,
  ) {
    final visible = suggestions
        .where((r) => !_loggedIds.contains(r.id))
        .toList();

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: AlignmentDirectional.topStart,
      child: visible.isEmpty
          ? const SizedBox.shrink()
          : Column(
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
                  children: visible.asMap().entries.map((entry) {
                    final index = entry.key;
                    final relative = entry.value;
                    return Padding(
                      key: ValueKey(relative.id),
                      padding: EdgeInsets.only(
                        left: index < visible.length - 1 ? AppSpacing.md : 0,
                      ),
                      child: _QuickLogFace(
                        relative: relative,
                        userId: widget.userId,
                        themeColors: themeColors,
                        labels: labels,
                        onLogged: () {
                          setState(() => _loggedIds.add(relative.id));
                        },
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }
}

class _QuickLogFace extends ConsumerStatefulWidget {
  const _QuickLogFace({
    required this.relative,
    required this.userId,
    required this.themeColors,
    required this.labels,
    required this.onLogged,
  });

  final Relative relative;
  final String userId;
  final dynamic themeColors;
  final Map<String, String> labels;
  final VoidCallback onLogged;

  @override
  ConsumerState<_QuickLogFace> createState() => _QuickLogFaceState();
}

class _QuickLogFaceState extends ConsumerState<_QuickLogFace> {
  bool _isExiting = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isExiting ? null : () => _logInteraction(context),
      child: AnimatedScale(
        scale: _isExiting ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInBack,
        child: AnimatedOpacity(
          opacity: _isExiting ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 250),
          child: Semantics(
            label: 'سجّل تواصل مع ${widget.relative.fullName}',
            button: true,
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
      ),
    );
  }

  /// Build a second-person display name for واصل's questions
  String _getSecondPersonName() {
    final firstPersonLabel = widget.labels[widget.relative.id];
    if (firstPersonLabel != null && firstPersonLabel.isNotEmpty) {
      final secondPerson = toSecondPerson(firstPersonLabel);
      // Extract the bare name (fullName minus any first-person prefix)
      // e.g. "عمي منصور" → "منصور", then prepend "عمك"
      final fullName = widget.relative.fullName;
      // Try to find a space after the relationship prefix
      final spaceIdx = fullName.indexOf(' ');
      if (spaceIdx > 0) {
        final bareName = fullName.substring(spaceIdx + 1);
        return '$secondPerson $bareName';
      }
      return '$secondPerson $fullName';
    }
    return widget.relative.fullName;
  }

  Future<void> _logInteraction(BuildContext context) async {
    // Start exit animation immediately
    setState(() => _isExiting = true);
    HapticFeedback.lightImpact();

    // Fire network calls in background — don't block UI
    () async {
      try {
        final interactionsRepo = ref.read(interactionsRepositoryProvider);
        final relativesRepo = ref.read(relativesRepositoryProvider);
        await Future.wait([
          interactionsRepo.createInteraction(Interaction(
            id: '',
            userId: widget.userId,
            relativeId: widget.relative.id,
            type: InteractionType.call,
            date: DateTime.now(),
            createdAt: DateTime.now(),
          )),
          relativesRepo.recordInteraction(widget.relative.id),
        ]);
      } catch (_) {
        // Both repos handle offline queuing internally
      }
    }();

    // Show glass confirmation sheet (handles follow-up question too)
    if (context.mounted) {
      _QuickLogSheet.show(
        context,
        relative: widget.relative,
        displayName: _getSecondPersonName(),
      );
    }

    // After exit animation completes, remove from parent's list
    await Future.delayed(const Duration(milliseconds: 350));
    if (mounted) widget.onLogged();
  }
}

// ---------------------------------------------------------------------------
// Glass confirmation sheet — replaces Material snackbar
// Shows success → optionally transitions to follow-up question
// ---------------------------------------------------------------------------

class _QuickLogSheet extends ConsumerStatefulWidget {
  final Relative relative;
  final String displayName;

  const _QuickLogSheet({
    required this.relative,
    required this.displayName,
  });

  static Future<void> show(
    BuildContext context, {
    required Relative relative,
    required String displayName,
  }) {
    return GlassBottomSheet.show(
      context: context,
      builder: (_) => _QuickLogSheet(
        relative: relative,
        displayName: displayName,
      ),
    );
  }

  @override
  ConsumerState<_QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends ConsumerState<_QuickLogSheet> {
  FollowUpQuestion? _question;
  SharedPreferences? _prefs;
  bool _showQuestion = false;
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadFollowUp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadFollowUp() async {
    _prefs = await SharedPreferences.getInstance();
    final question = await OneQuestionEngine.getQuestion(
      relative: widget.relative,
      prefs: _prefs!,
      displayName: widget.displayName,
    );

    // Let confirmation show for a moment
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    if (question != null) {
      setState(() {
        _question = question;
        _showQuestion = true;
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);

    return GlassBottomSheet(
      icon: _showQuestion
          ? Icons.auto_awesome_rounded
          : Icons.check_circle_rounded,
      iconAccentColor: _showQuestion ? themeColors.primary : Colors.green,
      title: _showQuestion ? 'واصل يسألك' : 'تم التسجيل!',
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _showQuestion
              ? _buildQuestionContent(themeColors)
              : _buildConfirmContent(themeColors),
        ),
      ),
    );
  }

  Widget _buildConfirmContent(dynamic themeColors) {
    return Padding(
      key: const ValueKey('confirm'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 40,
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'تم تسجيل تواصل مع ${widget.relative.fullName}',
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 200.ms).fadeIn(),
          const SizedBox(height: AppSpacing.lg),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(
                '${AppRoutes.relativeDetail}/${widget.relative.id}',
              );
            },
            child: Text(
              'إضافة تفاصيل',
              style: AppTypography.labelMedium.copyWith(
                color: themeColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent(dynamic themeColors) {
    return SingleChildScrollView(
      key: const ValueKey('question'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _question!.text,
            style: AppTypography.bodyLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            textDirection: TextDirection.rtl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'اكتب إجابتك...',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(color: themeColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'تخطي',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('حفظ'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitAnswer() async {
    final answer = _controller.text.trim();
    if (answer.isEmpty) return;
    setState(() => _isSubmitting = true);
    HapticFeedback.lightImpact();

    const allowedFields = {
      'interests',
      'health_status',
      'communication_style',
      'best_time_to_contact',
      'sensitive_topics',
    };
    if (!allowedFields.contains(_question!.field)) return;

    try {
      const arrayFields = {'interests', 'sensitive_topics'};
      final value =
          arrayFields.contains(_question!.field) ? [answer] : answer;

      await SupabaseConfig.client
          .from('relatives')
          .update({_question!.field: value})
          .eq('id', widget.relative.id);
      await OneQuestionEngine.recordAnswer(
        relativeId: widget.relative.id,
        questionKey: _question!.key,
        prefs: _prefs!,
      );
    } catch (_) {
      // Silently fail — non-critical enrichment
    }

    if (mounted) Navigator.pop(context);
  }
}
