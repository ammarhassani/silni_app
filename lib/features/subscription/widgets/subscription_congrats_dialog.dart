import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_provider.dart';
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
  static Future<void> show(BuildContext context,
      {required bool isAnnual}) async {
    HapticFeedback.heavyImpact();

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SubscriptionCongratsDialog(isAnnual: isAnnual);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
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
    final colors = ref.watch(themeColorsProvider);
    final accent = colors.primary;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Dialog content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: AppSpacing.md),

                    // Checkmark badge
                    _buildBadge(accent, colors.primaryGradient)
                        .animate()
                        .scale(
                          begin: const Offset(0, 0),
                          end: const Offset(1, 1),
                          duration: 500.ms,
                          curve: Curves.easeOutBack,
                        ),

                    const SizedBox(height: AppSpacing.lg),

                    // Title
                    Text(
                      'مرحباً بك في عائلة MAX!',
                      style: AppTypography.headlineMedium.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                    const SizedBox(height: AppSpacing.xs),

                    // Subtitle
                    Text(
                      'أنت الآن من أعضاء صلني المميزين',
                      style: AppTypography.bodyLarge.copyWith(
                        color: colors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 350.ms),

                    const SizedBox(height: AppSpacing.lg),

                    // Features
                    _buildFeatures(accent, colors)
                        .animate()
                        .fadeIn(delay: 500.ms)
                        .slideY(begin: 0.15),

                    const SizedBox(height: AppSpacing.md),

                    // Subscription badge
                    _buildSubscriptionBadge(accent, colors)
                        .animate()
                        .fadeIn(delay: 700.ms)
                        .scale(begin: const Offset(0.9, 0.9)),

                    const SizedBox(height: AppSpacing.lg),

                    // CTA button
                    _buildButton(accent, colors)
                        .animate()
                        .fadeIn(delay: 900.ms)
                        .slideY(begin: 0.2),

                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ),
          ),

          // Confetti
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
              colors: [
                ...colors.primaryGradient.colors,
                Colors.white,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(Color accent, LinearGradient gradient) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.4),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Icon(
        Icons.check_rounded,
        size: 48,
        color: Colors.white,
      ),
    );
  }

  Widget _buildFeatures(Color accent, ThemeColors colors) {
    final features = [
      ('مساعد الذكاء الاصطناعي', Icons.psychology_rounded),
      ('كتابة الرسائل الذكية', Icons.edit_note_rounded),
      ('تذكيرات غير محدودة', Icons.notifications_active_rounded),
      ('إحصائيات متقدمة', Icons.analytics_rounded),
    ];

    return Column(
      children: features.asMap().entries.map((entry) {
        final (label, icon) = entry.value;
        final delay = Duration(milliseconds: 550 + entry.key * 80);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: accent,
              ),
            ],
          ).animate(delay: delay).fadeIn().slideX(begin: 0.05),
        );
      }).toList(),
    );
  }

  Widget _buildSubscriptionBadge(Color accent, ThemeColors colors) {
    final period = widget.isAnnual ? 'سنوي' : 'شهري';
    final duration = widget.isAnnual ? '12 شهر' : 'شهر واحد';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent,
            ),
            child: const Icon(Icons.check, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اشتراك MAX $period',
                style: AppTypography.labelMedium.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'صالح لمدة $duration',
                style: AppTypography.labelSmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton(Color accent, ThemeColors colors) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          'ابدأ الآن',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
