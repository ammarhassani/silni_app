import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ai/deepseek_ai_service.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/gamification_event.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/theme_provider.dart';
import 'glass_card.dart';
import 'share_bottom_sheet.dart';
import 'share_cards/streak_share_card.dart';
import 'shareable_card_generator.dart';

/// Milestone tier for visual customization.
enum MilestoneTier {
  starter,   // 3 days
  common,    // 7, 10, 14, 21 days
  rare,      // 30, 50 days
  epic,      // 100, 200 days
  legendary, // 365, 500 days
}

/// Streak milestone celebration modal.
///
/// Clean glass-card dialog with theme-aware colors and subtle entrance
/// animations. Tier gradient used as accent color on the streak pill.
class StreakMilestoneModal extends ConsumerStatefulWidget {
  final int streak;
  final VoidCallback? onDismiss;
  final bool freezeAwarded;

  const StreakMilestoneModal({
    super.key,
    required this.streak,
    this.onDismiss,
    this.freezeAwarded = false,
  });

  @override
  ConsumerState<StreakMilestoneModal> createState() =>
      _StreakMilestoneModalState();

  static Future<void> show(
    BuildContext context, {
    required int streak,
    bool freezeAwarded = false,
  }) {
    final shouldAwardFreeze =
        freezeAwarded || GamificationEvent.isFreezeAwardMilestone(streak);

    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => StreakMilestoneModal(
        streak: streak,
        freezeAwarded: shouldAwardFreeze,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }
}

/// Arabic day noun form based on number agreement rules (تمييز العدد).
String _arabicDayWord(int count) {
  if (count >= 3 && count <= 10) return 'أيام';
  if (count % 100 == 0) return 'يوم';
  final lastTwo = count % 100;
  if (lastTwo >= 3 && lastTwo <= 10) return 'أيام';
  if (lastTwo >= 11) return 'يومًا';
  return 'يوم';
}

/// Arabic consecutive adjective agreeing with day form.
String _arabicConsecutiveWord(int count) {
  if (count >= 3 && count <= 10) return 'متتالية';
  if (count % 100 == 0) return 'متتالٍ';
  final lastTwo = count % 100;
  if (lastTwo >= 3 && lastTwo <= 10) return 'متتالية';
  if (lastTwo >= 11) return 'متتاليًا';
  return 'متتالٍ';
}

class _StreakMilestoneModalState extends ConsumerState<StreakMilestoneModal> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  MilestoneTier _getMilestoneTier() {
    if (widget.streak >= 365) return MilestoneTier.legendary;
    if (widget.streak >= 100) return MilestoneTier.epic;
    if (widget.streak >= 30) return MilestoneTier.rare;
    if (widget.streak >= 7) return MilestoneTier.common;
    return MilestoneTier.starter;
  }

  LinearGradient _getTierGradient(ThemeColors colors) {
    return switch (_getMilestoneTier()) {
      MilestoneTier.legendary => colors.tierLegendaryGradient,
      MilestoneTier.epic => colors.tierEpicGradient,
      MilestoneTier.rare => colors.tierRareGradient,
      MilestoneTier.common => colors.streakFire,
      MilestoneTier.starter => colors.tierStarterGradient,
    };
  }

  Color _getTierAccentColor(ThemeColors colors) {
    final gradient = _getTierGradient(colors);
    return gradient.colors.isNotEmpty ? gradient.colors.first : colors.primary;
  }

  String _getMilestoneMessage() {
    if (widget.streak >= 500) return 'ما شاء الله! 500 يوم من حفظ الودّ';
    if (widget.streak >= 365) return 'سنة كاملة من الحبّ والتواصل!';
    if (widget.streak >= 200) return '200 يوم! عائلتك محظوظة بك';
    if (widget.streak >= 100) return '100 يوم من الاهتمام — ما شاء الله!';
    if (widget.streak >= 50) return '50 يوم من التواصل الجميل!';
    if (widget.streak >= 30) return 'شهر كامل من صلة الرحم 🤍';
    if (widget.streak >= 21) return '21 يوم — صار التواصل عادة حلوة!';
    if (widget.streak >= 14) return 'أسبوعان من الاهتمام المستمر!';
    if (widget.streak >= 10) return '10 أيام من التواصل الحلو!';
    if (widget.streak >= 7) return 'أسبوع كامل — بداية جميلة!';
    if (widget.streak >= 3) return 'ثلاثة أيام متواصلة — استمر!';
    return 'كل تواصل يصنع فرق 🤍';
  }

  String _getEncouragementMessage() {
    if (widget.streak >= 365) return 'أنت قدوة في صلة الرحم — جزاك الله خير';
    if (widget.streak >= 100) return 'عائلتك تحسّ باهتمامك — استمر 🤍';
    if (widget.streak >= 30) return 'ما شاء الله! التواصل المستمر يقوّي الرابطة';
    if (widget.streak >= 7) return 'بداية جميلة — كل تواصل يفرق';
    return 'كل خطوة تقرّبك من أهلك 🤍';
  }

  int _getNextMilestone() {
    const milestones = [3, 7, 10, 14, 21, 30, 50, 100, 200, 365, 500];
    for (final m in milestones) {
      if (m > widget.streak) return m;
    }
    return widget.streak + 100;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeColorsProvider);
    final tierAccent = _getTierAccentColor(colors);
    final nextMilestone = _getNextMilestone();

    return Semantics(
      label: 'تهانينا! ${widget.streak} ${_arabicDayWord(widget.streak)} ${_arabicConsecutiveWord(widget.streak)} من التواصل',
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
              // Fire emoji
              const Text(
                '🔥',
                style: TextStyle(fontSize: 56),
              ).animate().fadeIn(duration: 300.ms).scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.0, 1.0),
                    duration: 400.ms,
                    curve: Curves.easeOut,
                  ),

              const SizedBox(height: AppSpacing.md),

              // Title
              Text(
                'ما شاء الله! 🌟',
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

              // Streak number pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: tierAccent.withValues(alpha: 0.15),
                  border: Border.all(
                    color: tierAccent.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.streak}',
                      style: AppTypography.numberLarge.copyWith(
                        color: colors.textPrimary,
                        fontSize: 48,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _arabicDayWord(widget.streak),
                          style: AppTypography.titleLarge.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'تواصل',
                          style: AppTypography.bodyMedium.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms).scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.0, 1.0),
                    delay: 200.ms,
                    duration: 400.ms,
                    curve: Curves.easeOut,
                  ),

              const SizedBox(height: AppSpacing.lg),

              // Milestone message
              Text(
                _getMilestoneMessage(),
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

              const SizedBox(height: AppSpacing.sm),

              // Encouragement
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
                  _getEncouragementMessage(),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 300.ms),

              // Freeze earned banner
              if (widget.freezeAwarded) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colors.statusInfo.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.statusInfo.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('❄️', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'حصلت على حماية شعلة!',
                              style: AppTypography.labelMedium.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'تحمي شعلتك عند نسيان التفاعل',
                              style: AppTypography.labelSmall.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
              ],

              // Next milestone
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'الهدف التالي:',
                      style: AppTypography.labelSmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$nextMilestone ${_arabicDayWord(nextMilestone)}',
                      style: AppTypography.labelMedium.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${nextMilestone - widget.streak} ${_arabicDayWord(nextMilestone - widget.streak)} متبقي)',
                      style: AppTypography.labelSmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(
                    delay: widget.freezeAwarded ? 600.ms : 500.ms,
                    duration: 300.ms,
                  ),

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
                            StreakShareCard(
                          format: format,
                          streak: widget.streak,
                          gradient: _getTierGradient(colors),
                          copyText: aiCopy,
                        ),
                        shareText: ShareableCardData.streak(
                          streak: widget.streak,
                        ).shareText,
                        aiCopyFuture: isMax
                            ? DeepSeekAIService().generateShareCopy(
                                cardType: 'streak',
                                context: {'streak': widget.streak},
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
              ).animate().fadeIn(
                    delay: widget.freezeAwarded ? 700.ms : 600.ms,
                    duration: 300.ms,
                  ),
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
