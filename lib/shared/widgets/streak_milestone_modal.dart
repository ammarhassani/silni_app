import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_animations.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/gamification_event.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/theme_provider.dart';
import 'share_bottom_sheet.dart';
import 'share_cards/streak_share_card.dart';
import 'shareable_card_generator.dart';

/// Milestone tier for visual customization
enum MilestoneTier {
  starter,   // 3 days
  common,    // 7, 10, 14, 21 days
  rare,      // 30, 50 days
  epic,      // 100, 200 days
  legendary, // 365, 500 days
}

/// Dramatic streak milestone celebration modal
/// Shows when user reaches a streak milestone (3, 7, 10, 14, 21, 30, 50, 100, 200, 365, 500 days)
class StreakMilestoneModal extends ConsumerStatefulWidget {
  final int streak;
  final VoidCallback? onDismiss;
  final bool freezeAwarded; // Whether a freeze was awarded at this milestone

  const StreakMilestoneModal({
    super.key,
    required this.streak,
    this.onDismiss,
    this.freezeAwarded = false,
  });

  @override
  ConsumerState<StreakMilestoneModal> createState() =>
      _StreakMilestoneModalState();

  /// Show the streak milestone modal
  static Future<void> show(
    BuildContext context, {
    required int streak,
    bool freezeAwarded = false,
  }) {
    // Check if freeze should be awarded
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

class _StreakMilestoneModalState extends ConsumerState<StreakMilestoneModal>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _flameController;
  late Animation<double> _flameAnimation;

  @override
  void initState() {
    super.initState();

    // Confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );

    // Flame animation
    _flameController = AnimationController(
      vsync: this,
      duration: AppAnimations.celebration,
    )..repeat(reverse: true);

    _flameAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _flameController, curve: Curves.easeInOut),
    );

    // Trigger haptic feedback
    HapticFeedback.heavyImpact();

    // Start confetti after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _flameController.dispose();
    super.dispose();
  }

  /// Get milestone tier for customization
  MilestoneTier _getMilestoneTier() {
    if (widget.streak >= 365) return MilestoneTier.legendary;
    if (widget.streak >= 100) return MilestoneTier.epic;
    if (widget.streak >= 30) return MilestoneTier.rare;
    if (widget.streak >= 7) return MilestoneTier.common;
    return MilestoneTier.starter;
  }

  /// Get gradient for tier from theme
  LinearGradient _getTierGradient(ThemeColors colors) {
    switch (_getMilestoneTier()) {
      case MilestoneTier.legendary:
        return colors.tierLegendaryGradient;
      case MilestoneTier.epic:
        return colors.tierEpicGradient;
      case MilestoneTier.rare:
        return colors.tierRareGradient;
      case MilestoneTier.common:
        return colors.streakFire;
      case MilestoneTier.starter:
        return colors.tierStarterGradient;
    }
  }

  /// Get confetti colors from tier gradient
  List<Color> _getConfettiColors(ThemeColors colors) {
    final gradient = _getTierGradient(colors);
    return [...gradient.colors, colors.onPrimary];
  }

  /// Get particle count for tier
  int _getParticleCount() {
    switch (_getMilestoneTier()) {
      case MilestoneTier.legendary:
        return 50;
      case MilestoneTier.epic:
        return 40;
      case MilestoneTier.rare:
        return 30;
      case MilestoneTier.common:
        return 25;
      case MilestoneTier.starter:
        return 15;
    }
  }

  /// Get milestone message based on streak
  String _getMilestoneMessage() {
    if (widget.streak >= 500) {
      return 'إنجاز أسطوري! 500 يوم!';
    } else if (widget.streak >= 365) {
      return 'سنة كاملة من التواصل المستمر!';
    } else if (widget.streak >= 200) {
      return '200 يوم! مثابرة استثنائية!';
    } else if (widget.streak >= 100) {
      return '100 يوم متتالي! إنجاز رائع!';
    } else if (widget.streak >= 50) {
      return '50 يوم من الالتزام!';
    } else if (widget.streak >= 30) {
      return 'شهر كامل من التواصل!';
    } else if (widget.streak >= 21) {
      return '21 يوم! عادة راسخة!';
    } else if (widget.streak >= 14) {
      return 'أسبوعان متتاليان!';
    } else if (widget.streak >= 10) {
      return '10 أيام متتالية!';
    } else if (widget.streak >= 7) {
      return 'أسبوع متتالي رائع!';
    } else if (widget.streak >= 3) {
      return 'ثلاثة أيام متتالية!';
    } else {
      return 'استمر في التواصل!';
    }
  }

  /// Get encouragement message
  String _getEncouragementMessage() {
    if (widget.streak >= 365) {
      return 'أنت قدوة حقيقية في صلة الرحم';
    } else if (widget.streak >= 100) {
      return 'التزامك ملهم للجميع!';
    } else if (widget.streak >= 30) {
      return 'ما شاء الله! استمر على هذا النهج';
    } else if (widget.streak >= 7) {
      return 'بداية ممتازة! واصل التميز';
    } else {
      return 'كل يوم يقربك من هدفك';
    }
  }

  /// Get next milestone
  int _getNextMilestone() {
    const milestones = [3, 7, 10, 14, 21, 30, 50, 100, 200, 365, 500];
    for (final m in milestones) {
      if (m > widget.streak) return m;
    }
    return widget.streak + 100; // Beyond 500, show +100 increments
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeColorsProvider);
    final tierGradient = _getTierGradient(colors);
    final confettiColors = _getConfettiColors(colors);
    final particleCount = _getParticleCount();
    final nextMilestone = _getNextMilestone();
    final primaryGradientColor = tierGradient.colors.isNotEmpty
        ? tierGradient.colors.first
        : colors.primary;

    return Semantics(
      label: 'تهانينا! ${widget.streak} يوم متتالي من التواصل',
      liveRegion: true,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Confetti with tier-specific colors
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: 3.14 / 2, // Down
                emissionFrequency: 0.03,
                numberOfParticles: particleCount,
                gravity: 0.2,
                colors: confettiColors,
              ),
            ),

            // Modal content with tier-specific gradient
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: tierGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: primaryGradientColor.withValues(alpha: 0.6),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fire emoji with animation
                AnimatedBuilder(
                  animation: _flameAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _flameAnimation.value,
                      child: const Text(
                        '🔥',
                        style: TextStyle(fontSize: 80),
                      ),
                    );
                  },
                )
                    .animate(
                      onPlay: (controller) => controller.repeat(),
                    )
                    .shimmer(
                      duration: 2000.ms,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),

                const SizedBox(height: 16),

                // "سلسلة مميزة!" text
                Text(
                  'سلسلة مميزة!',
                  style: AppTypography.dramatic.copyWith(
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 20,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(
                      begin: -0.2,
                      end: 0,
                      duration: 500.ms,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 24),

                // Streak number
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.streak}',
                        style: AppTypography.numberLarge.copyWith(
                          color: Colors.white,
                          fontSize: 64,
                          shadows: [
                            Shadow(
                              blurRadius: 20,
                              color: Colors.black.withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'يوم',
                            style: AppTypography.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'متتالي',
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      delay: 200.ms,
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    ),

                const SizedBox(height: 24),

                // Milestone message
                Text(
                  _getMilestoneMessage(),
                  textAlign: TextAlign.center,
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                const SizedBox(height: 12),

                // Encouragement message
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getEncouragementMessage(),
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

                // Freeze earned banner (if applicable)
                if (widget.freezeAwarded) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('❄️', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'حصلت على حماية شعلة!',
                                style: AppTypography.labelMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'تحمي شعلتك عند نسيان التفاعل',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 700.ms, duration: 400.ms)
                      .slideY(begin: 0.1, end: 0, delay: 700.ms, duration: 400.ms)
                      .shimmer(
                        delay: 1200.ms,
                        duration: 1500.ms,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                ],

                // Progress to next milestone
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'الهدف التالي:',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$nextMilestone يوم',
                        style: AppTypography.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${nextMilestone - widget.streak} متبقي)',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 750.ms, duration: 400.ms),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Share button
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ShareBottomSheet.show(
                          context,
                          cardBuilder: (format) => StreakShareCard(
                            format: format,
                            streak: widget.streak,
                          ),
                          shareText: ShareableCardData.streak(
                            streak: widget.streak,
                          ).shareText,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: const Icon(Icons.share, size: 18),
                      label: Text(
                        'شارك',
                        style: AppTypography.buttonLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Dismiss button
                    ElevatedButton(
                      onPressed: () {
                        widget.onDismiss?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.onPrimary,
                        foregroundColor: primaryGradientColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                      ),
                      child: Text(
                        'رائع!',
                        style: AppTypography.buttonLarge.copyWith(
                          color: primaryGradientColor,
                        ),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 400.ms)
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      delay: 800.ms,
                      duration: 400.ms,
                    ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                duration: 500.ms,
                curve: Curves.easeOut,
              ),
        ],
      ),
      ),
    );
  }
}
