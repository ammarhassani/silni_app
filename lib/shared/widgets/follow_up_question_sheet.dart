import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/one_question_engine.dart';
import '../../core/theme/theme_provider.dart';

/// Minimal bottom sheet for one follow-up question after quick log
class FollowUpQuestionSheet extends ConsumerStatefulWidget {
  final FollowUpQuestion question;
  final String relativeId;
  final Future<void> Function(String field, String answer) onSubmit;

  const FollowUpQuestionSheet({
    super.key,
    required this.question,
    required this.relativeId,
    required this.onSubmit,
  });

  /// Show as a modal bottom sheet
  static Future<void> show(
    BuildContext context, {
    required FollowUpQuestion question,
    required String relativeId,
    required Future<void> Function(String field, String answer) onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FollowUpQuestionSheet(
        question: question,
        relativeId: relativeId,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  ConsumerState<FollowUpQuestionSheet> createState() =>
      _FollowUpQuestionSheetState();
}

class _FollowUpQuestionSheetState
    extends ConsumerState<FollowUpQuestionSheet> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: themeColors.background1,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: themeColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Header
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: themeColors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'واصل يسألك:',
                  style: AppTypography.labelMedium.copyWith(
                    color: themeColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Question
            Text(
              widget.question.text,
              style: AppTypography.bodyLarge.copyWith(
                color: themeColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Text field
            TextField(
              controller: _controller,
              autofocus: true,
              textDirection: TextDirection.rtl,
              style: TextStyle(color: themeColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'اكتب إجابتك...',
                hintStyle: TextStyle(color: themeColors.textSecondary),
                filled: true,
                fillColor:
                    themeColors.surface.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: BorderSide(
                    color: themeColors.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: BorderSide(
                    color: themeColors.textSecondary.withValues(alpha: 0.3),
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

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'تخطي',
                      style: TextStyle(color: themeColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            final answer = _controller.text.trim();
                            if (answer.isEmpty) return;
                            setState(() => _isSubmitting = true);
                            HapticFeedback.lightImpact();
                            await widget.onSubmit(
                                widget.question.field, answer);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColors.primary,
                      foregroundColor: Colors.white,
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
      ),
    );
  }
}
