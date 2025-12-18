import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../../core/constants/app_typography.dart';

/// Dramatic streak milestone celebration modal
/// Shows when user reaches a streak milestone (7, 30, 100, 365 days)
class StreakMilestoneModal extends StatefulWidget {
  final int streak;
  final VoidCallback? onDismiss;

  const StreakMilestoneModal({
    super.key,
    required this.streak,
    this.onDismiss,
  });

  @override
  State<StreakMilestoneModal> createState() => _StreakMilestoneModalState();

  /// Show the streak milestone modal
  static Future<void> show(
    BuildContext context, {
    required int streak,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => StreakMilestoneModal(
        streak: streak,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _StreakMilestoneModalState extends State<StreakMilestoneModal>
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
      duration: const Duration(milliseconds: 1000),
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

  /// Get milestone message based on streak
  String _getMilestoneMessage() {
    if (widget.streak >= 365) {
      return 'سنة كاملة من التواصل المستمر!';
    } else if (widget.streak >= 100) {
      return '100 يوم متتالي! إنجاز رائع!';
    } else if (widget.streak >= 30) {
      return 'شهر كامل من التواصل!';
    } else if (widget.streak >= 7) {
      return 'أسبوع متتالي رائع!';
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
              emissionFrequency: 0.03,
              numberOfParticles: 25,
              gravity: 0.2,
              colors: const [
                Color(0xFFFF6B35),
                Color(0xFFFF9E00),
                Color(0xFFFFD60A),
                Color(0xFFFFE55C),
              ],
            ),
          ),

          // Modal content
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF6B35),
                  Color(0xFFFF9E00),
                  Color(0xFFFFD60A),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9E00).withValues(alpha: 0.6),
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

                const SizedBox(height: 32),

                // Close button
                ElevatedButton(
                  onPressed: () {
                    widget.onDismiss?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFFF6B35),
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
                      color: const Color(0xFFFF6B35),
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
    );
  }
}
