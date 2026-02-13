import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../../core/constants/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/badge_prestige.dart';
import 'share_bottom_sheet.dart';
import 'share_cards/badge_share_card.dart';
import 'shareable_card_generator.dart';

/// Dramatic badge unlock celebration modal
/// Shows when user unlocks a new badge
class BadgeUnlockModal extends StatefulWidget {
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
  State<BadgeUnlockModal> createState() => _BadgeUnlockModalState();

  /// Show the badge unlock modal
  static Future<void> show(
    BuildContext context, {
    required String badgeId,
    required String badgeName,
    required String badgeDescription,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.islamicGreenDark.withValues(alpha: 0.9),
      builder: (context) => BadgeUnlockModal(
        badgeId: badgeId,
        badgeName: badgeName,
        badgeDescription: badgeDescription,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _BadgeUnlockModalState extends State<BadgeUnlockModal>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _shineController;
  late Animation<double> _shineAnimation;

  @override
  void initState() {
    super.initState();

    // Confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Shine animation for the badge
    _shineController = AnimationController(
      vsync: this,
      duration: AppAnimations.loop,
    )..repeat();

    _shineAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shineController, curve: Curves.easeInOut),
    );

    // Trigger haptic feedback
    HapticFeedback.mediumImpact();

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
    _shineController.dispose();
    super.dispose();
  }

  /// Get emoji for badge based on ID (uses centralized BadgePrestige)
  String _getBadgeEmoji(String badgeId) {
    return BadgePrestige.getBadgeInfo(badgeId).emoji;
  }

  /// Get color for badge based on ID (uses centralized BadgePrestige)
  Color _getBadgeColor(String badgeId) {
    return BadgePrestige.getBadgeInfo(badgeId).color;
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getBadgeColor(widget.badgeId);
    final badgeEmoji = _getBadgeEmoji(widget.badgeId);

    return Semantics(
      label: 'تهانينا! حصلت على وسام ${widget.badgeName}',
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
              numberOfParticles: 15,
              gravity: 0.2,
              colors: [
                badgeColor,
                badgeColor.withValues(alpha: 0.7),
                AppColors.premiumGold,
                AppColors.premiumGoldLight,
              ],
            ),
          ),

          // Modal content
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  badgeColor,
                  badgeColor.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.5),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Trophy icon
                const Icon(
                  Icons.military_tech_rounded,
                  size: 60,
                  color: Colors.white,
                )
                    .animate(
                      onPlay: (controller) => controller.repeat(),
                    )
                    .shake(
                      duration: 2000.ms,
                      hz: 2,
                    ),

                const SizedBox(height: 16),

                // "وسام جديد!" text
                Text(
                  'وسام جديد!',
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

                // Badge with shine effect
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Shine effect
                    AnimatedBuilder(
                      animation: _shineAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_shineAnimation.value * 100, 0),
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withValues(alpha: 0.3),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Badge circle
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          badgeEmoji,
                          style: const TextStyle(fontSize: 64),
                        ),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .scale(
                      begin: const Offset(0.3, 0.3),
                      end: const Offset(1.0, 1.0),
                      delay: 200.ms,
                      duration: 800.ms,
                      curve: Curves.elasticOut,
                    ),

                const SizedBox(height: 24),

                // Badge name
                Text(
                  widget.badgeName,
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineSmall.copyWith(
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

                // Badge description
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
                    widget.badgeDescription,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

                const SizedBox(height: 32),

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
                          cardBuilder: (format, {String? aiCopy}) => BadgeShareCard(
                            format: format,
                            badgeEmoji: badgeEmoji,
                            badgeName: widget.badgeName,
                            badgeColor: badgeColor,
                            copyText: aiCopy,
                          ),
                          shareText: ShareableCardData.badge(
                            badgeName: widget.badgeName,
                            badgeEmoji: badgeEmoji,
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
                        backgroundColor: Colors.white,
                        foregroundColor: badgeColor,
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
                          color: badgeColor,
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
