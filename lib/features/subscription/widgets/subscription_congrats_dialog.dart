import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';

/// Congratulations dialog shown after successful MAX subscription purchase
class SubscriptionCongratsDialog extends ConsumerStatefulWidget {
  /// Whether this is an annual subscription
  final bool isAnnual;

  const SubscriptionCongratsDialog({
    super.key,
    required this.isAnnual,
  });

  /// Show the dialog with confetti celebration
  static Future<void> show(BuildContext context, {required bool isAnnual}) async {
    // Haptic feedback for celebration
    HapticFeedback.heavyImpact();

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SubscriptionCongratsDialog(isAnnual: isAnnual);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  @override
  ConsumerState<SubscriptionCongratsDialog> createState() =>
      _SubscriptionCongratsDialogState();
}

class _SubscriptionCongratsDialogState
    extends ConsumerState<SubscriptionCongratsDialog> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    // Start confetti immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap in Material to prevent text underline decoration issue
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Dialog content
          Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: GlassCard(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.premiumGold.withValues(alpha: 0.3),
                  AppColors.premiumGoldDark.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
              border: Border.all(
                color: AppColors.premiumGold.withValues(alpha: 0.5),
                width: 2,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Crown/Star icon with glow
                  _buildCrownIcon()
                      .animate()
                      .scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      )
                      .then()
                      .shimmer(
                        duration: 2000.ms,
                        color: AppColors.premiumGold.withValues(alpha: 0.3),
                      ),

                  const SizedBox(height: AppSpacing.md),

                  // Welcome text
                  Text(
                    'مرحباً بك في عائلة MAX! 🎉',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.premiumGold,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),

                  const SizedBox(height: AppSpacing.sm),

                  // Subtitle
                  Text(
                    'أنت الآن من أعضاء صلني المميزين',
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: AppSpacing.lg),

                  // Features unlocked
                  _buildUnlockedFeatures()
                      .animate()
                      .fadeIn(delay: 600.ms)
                      .slideY(begin: 0.2),

                  const SizedBox(height: AppSpacing.lg),

                  // Subscription type badge
                  _buildSubscriptionBadge()
                      .animate()
                      .fadeIn(delay: 800.ms)
                      .scale(begin: const Offset(0.8, 0.8)),

                  const SizedBox(height: AppSpacing.lg),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.premiumGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                        shadowColor: AppColors.premiumGold.withValues(alpha: 0.5),
                      ),
                      child: Text(
                        'ابدأ الآن',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.3),
                ],
              ),
            ),
          ),
        ),

        // Confetti from top center
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 30,
            maxBlastForce: 30,
            minBlastForce: 10,
            emissionFrequency: 0.05,
            gravity: 0.2,
            colors: const [
              AppColors.premiumGold,
              AppColors.premiumGoldDark,
              Colors.white,
              Colors.amber,
              Colors.orange,
            ],
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildCrownIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.premiumGold,
            AppColors.premiumGoldDark,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.premiumGold.withValues(alpha: 0.6),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Icon(
        Icons.workspace_premium_rounded,
        size: 56,
        color: Colors.white,
      ),
    );
  }

  Widget _buildUnlockedFeatures() {
    final features = [
      ('مساعد الذكاء الاصطناعي', Icons.psychology_rounded),
      ('كتابة الرسائل الذكية', Icons.edit_note_rounded),
      ('تذكيرات غير محدودة', Icons.notifications_active_rounded),
      ('إحصائيات متقدمة', Icons.analytics_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.premiumGold.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الميزات المفعّلة:',
            style: AppTypography.labelMedium.copyWith(
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: features
                .asMap()
                .entries
                .map((entry) => _buildFeatureChip(
                      entry.value.$1,
                      entry.value.$2,
                      entry.key,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.premiumGold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.premiumGold.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.premiumGold),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: 700 + (index * 100))).fadeIn().scale(
          begin: const Offset(0.8, 0.8),
        );
  }

  Widget _buildSubscriptionBadge() {
    final period = widget.isAnnual ? 'سنوي' : 'شهري';
    final duration = widget.isAnnual ? '12 شهر' : 'شهر واحد';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.premiumGold.withValues(alpha: 0.2),
            AppColors.premiumGoldDark.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.premiumGold.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.premiumGold,
            ),
            child: const Icon(
              Icons.check,
              size: 14,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اشتراك MAX $period',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.premiumGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'صالح لمدة $duration',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
