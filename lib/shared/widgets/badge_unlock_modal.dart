import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ai/deepseek_ai_service.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/badge_prestige.dart';
import 'glass_card.dart';
import 'share_bottom_sheet.dart';
import 'share_cards/badge_share_card.dart';
import 'shareable_card_generator.dart';

/// Badge unlock celebration modal.
///
/// Clean glass-card dialog with theme-aware colors and subtle entrance
/// animations. Badge color used as accent only (not full background).
class BadgeUnlockModal extends ConsumerStatefulWidget {
  final String badgeId;
  final String badgeName;
  final String badgeDescription;
  final VoidCallback? onDismiss;

  const BadgeUnlockModal({
    super.key,
    required this.badgeId,
    required this.badgeName,
    required this.badgeDescription,
    this.onDismiss,
  });

  @override
  ConsumerState<BadgeUnlockModal> createState() => _BadgeUnlockModalState();

  static Future<void> show(
    BuildContext context, {
    required String badgeId,
    required String badgeName,
    required String badgeDescription,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => BadgeUnlockModal(
        badgeId: badgeId,
        badgeName: badgeName,
        badgeDescription: badgeDescription,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _BadgeUnlockModalState extends ConsumerState<BadgeUnlockModal> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeColorsProvider);
    final badgeInfo = BadgePrestige.getBadgeInfo(widget.badgeId);
    final badgeColor = badgeInfo.color;
    final badgeEmoji = badgeInfo.emoji;

    return Semantics(
      label: 'تهانينا! حصلت على وسام ${widget.badgeName}',
      liveRegion: true,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          borderRadius: AppSpacing.radiusLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge emoji in accent circle
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badgeColor.withValues(alpha: 0.15),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    badgeEmoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms).scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.0, 1.0),
                    duration: 400.ms,
                    curve: Curves.easeOut,
                  ),

              const SizedBox(height: AppSpacing.md),

              // Title
              Text(
                'أحسنت! 🤍',
                style: AppTypography.dramatic.copyWith(
                  color: colors.textPrimary,
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(
                    begin: 0.05,
                    end: 0,
                    delay: 100.ms,
                    duration: 300.ms,
                  ),

              const SizedBox(height: AppSpacing.lg),

              // Badge name
              Text(
                widget.badgeName,
                textAlign: TextAlign.center,
                style: AppTypography.headlineSmall.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

              const SizedBox(height: AppSpacing.sm),

              // Badge description
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.badgeDescription,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

              const SizedBox(height: AppSpacing.lg),

              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      final isMax = ref.read(isMaxProvider);
                      ShareBottomSheet.show(
                        context,
                        cardBuilder: (format, {String? aiCopy}) =>
                            BadgeShareCard(
                          format: format,
                          badgeEmoji: badgeEmoji,
                          badgeName: widget.badgeName,
                          badgeColor: badgeColor,
                          gradient: colors.primaryGradient,
                          copyText: aiCopy,
                        ),
                        shareText: ShareableCardData.badge(
                          badgeName: widget.badgeName,
                          badgeEmoji: badgeEmoji,
                        ).shareText,
                        aiCopyFuture: isMax
                            ? DeepSeekAIService().generateShareCopy(
                                cardType: 'badge',
                                context: {
                                  'badgeName': widget.badgeName,
                                  'badgeEmoji': badgeEmoji,
                                },
                              )
                            : null,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size.zero,
                      foregroundColor: colors.dialogButtonPrimary,
                      side: BorderSide(
                        color: colors.dialogButtonPrimary,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.share, size: 18),
                    label: Text(
                      'شارك',
                      style: AppTypography.buttonLarge.copyWith(
                        color: colors.dialogButtonPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => widget.onDismiss?.call(),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.zero,
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'رائع!',
                      style: AppTypography.buttonLarge.copyWith(
                        color: colors.onPrimary,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 300.ms)
            .scale(
              begin: const Offset(0.95, 0.95),
              end: const Offset(1.0, 1.0),
              duration: 400.ms,
              curve: Curves.easeOut,
            ),
      ),
    );
  }
}
