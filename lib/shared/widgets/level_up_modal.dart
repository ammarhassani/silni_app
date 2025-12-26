import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../../core/constants/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

/// Dramatic level up celebration modal
/// Shows when user reaches a new level
class LevelUpModal extends StatefulWidget {
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
  State<LevelUpModal> createState() => _LevelUpModalState();

  /// Show the level up modal
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
      barrierColor: AppColors.islamicGreenDark.withValues(alpha: 0.9),
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

class _LevelUpModalState extends State<LevelUpModal>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Glow animation for the level number
    _glowController = AnimationController(
      vsync: this,
      duration: AppAnimations.celebration,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
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
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'تهانينا! لقد وصلت للمستوى ${widget.newLevel}',
      liveRegion: true,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2, // Down
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
              colors: const [
                AppColors.premiumGold,
                AppColors.premiumGoldLight,
                AppColors.islamicGreenLight,
                AppColors.islamicGreenPrimary,
              ],
            ),
          ),

          // Modal content
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: AppColors.goldenGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.premiumGold.withValues(alpha: 0.5),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sparkle icon
                const Icon(
                  Icons.stars_rounded,
                  size: 80,
                  color: Colors.white,
                )
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0),
                      duration: 1000.ms,
                    )
                    .rotate(
                      begin: -0.1,
                      end: 0.1,
                      duration: 1000.ms,
                    ),

                const SizedBox(height: 16),

                // "مستوى جديد!" text
                Text(
                  'مستوى جديد!',
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

                // Level number with animated glow
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: _glowAnimation.value * 0.8),
                            blurRadius: 40 * _glowAnimation.value,
                            spreadRadius: 10 * _glowAnimation.value,
                          ),
                        ],
                      ),
                      child: Text(
                        '${widget.newLevel}',
                        style: AppTypography.numberLarge.copyWith(
                          color: Colors.white,
                          fontSize: 72,
                          shadows: [
                            Shadow(
                              blurRadius: 20,
                              color: Colors.black.withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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

                // Congratulatory message
                Text(
                  'أحسنت! لقد وصلت للمستوى ${widget.newLevel}',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                const SizedBox(height: 16),

                // XP progress info
                if (widget.xpToNextLevel > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${widget.xpToNextLevel} نقطة للمستوى التالي',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: widget.currentXP /
                              (widget.currentXP + widget.xpToNextLevel),
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
                ],

                const SizedBox(height: 32),

                // Close button
                ElevatedButton(
                  onPressed: () {
                    widget.onDismiss?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.premiumGoldDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
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
                      color: AppColors.premiumGoldDark,
                    ),
                  ),
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
