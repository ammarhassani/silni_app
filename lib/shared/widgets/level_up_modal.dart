import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/ai/deepseek_ai_service.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/theme/theme_provider.dart';
import 'glass_card.dart';
import 'share_bottom_sheet.dart';
import 'share_cards/level_up_share_card.dart';
import 'shareable_card_generator.dart';

/// Level up celebration modal.
///
/// Clean glass-card dialog with theme-aware colors and subtle entrance
/// animations. No confetti, no glow — just clear information.
class LevelUpModal extends ConsumerStatefulWidget {
  final int oldLevel;
  final int newLevel;
  final int currentXP;
  final int xpToNextLevel;
  final VoidCallback? onDismiss;

  const LevelUpModal({
    super.key,
    required this.oldLevel,
    required this.newLevel,
    required this.currentXP,
    required this.xpToNextLevel,
    this.onDismiss,
  });

  @override
  ConsumerState<LevelUpModal> createState() => _LevelUpModalState();

  static Future<void> show(
    BuildContext context, {
    required int oldLevel,
    required int newLevel,
    required int currentXP,
    required int xpToNextLevel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => LevelUpModal(
        oldLevel: oldLevel,
        newLevel: newLevel,
        currentXP: currentXP,
        xpToNextLevel: xpToNextLevel,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _LevelUpModalState extends ConsumerState<LevelUpModal> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeColorsProvider);

    return Semantics(
      label: 'تهانينا! لقد وصلت للمستوى ${widget.newLevel}',
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
              // Star icon
              Icon(
                Icons.stars_rounded,
                size: 56,
                color: colors.secondary,
              ).animate().fadeIn(duration: 300.ms).scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.0, 1.0),
                    duration: 400.ms,
                    curve: Curves.easeOut,
                  ),

              const SizedBox(height: AppSpacing.md),

              // Title
              Text(
                'مستوى جديد!',
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

              // Level number
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary.withValues(alpha: 0.15),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Text(
                  '${widget.newLevel}',
                  style: AppTypography.numberLarge.copyWith(
                    color: colors.textPrimary,
                    fontSize: 56,
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms).scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.0, 1.0),
                    delay: 200.ms,
                    duration: 400.ms,
                    curve: Curves.easeOut,
                  ),

              const SizedBox(height: AppSpacing.lg),

              // Congratulatory message
              Text(
                'أحسنت! لقد وصلت للمستوى ${widget.newLevel}',
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

              const SizedBox(height: AppSpacing.md),

              // XP progress info
              if (widget.xpToNextLevel > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${widget.xpToNextLevel} ${widget.xpToNextLevel >= 3 && widget.xpToNextLevel <= 10 ? 'نقاط' : 'نقطة'} للمستوى التالي',
                        style: AppTypography.bodyMedium.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: widget.currentXP /
                            (widget.currentXP + widget.xpToNextLevel),
                        backgroundColor: colors.primary.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colors.primary,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
              ],

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
                            LevelUpShareCard(
                          format: format,
                          level: widget.newLevel,
                          gradient: colors.goldenGradient,
                          copyText: aiCopy,
                        ),
                        shareText: ShareableCardData.levelUp(
                          newLevel: widget.newLevel,
                        ).shareText,
                        aiCopyFuture: isMax
                            ? DeepSeekAIService().generateShareCopy(
                                cardType: 'level_up',
                                context: {'level': widget.newLevel},
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
              ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
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
