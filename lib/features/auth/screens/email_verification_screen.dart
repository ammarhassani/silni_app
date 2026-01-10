import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../../../core/services/app_logger_service.dart';
import '../../../shared/utils/ui_helpers.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _isResending = false;
  bool _canResend = true;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    // Periodically check if email has been verified
    _startVerificationCheck();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _checkTimer?.cancel();
    super.dispose();
  }

  bool _isChecking = false;

  void _startVerificationCheck() {
    // Check every 3 seconds if email has been verified
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      // Prevent overlapping checks
      if (_isChecking || !mounted) return;
      _isChecking = true;
      try {
        await _checkEmailVerification();
      } finally {
        _isChecking = false;
      }
    });
  }

  Future<void> _checkEmailVerification() async {
    final logger = AppLoggerService();
    final authService = ref.read(authServiceProvider);

    try {
      // Refresh session to get updated email verification status
      await Supabase.instance.client.auth.refreshSession();

      if (authService.isEmailVerified) {
        logger.info(
          'Email verified, navigating to home',
          category: LogCategory.auth,
          tag: 'EmailVerificationScreen',
        );

        _checkTimer?.cancel();

        if (mounted) {
          context.go(AppRoutes.home);
        }
      }
    } catch (e) {
      logger.warning(
        'Failed to check email verification',
        category: LogCategory.auth,
        tag: 'EmailVerificationScreen',
        metadata: {'error': e.toString()},
      );
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResend) return;

    final logger = AppLoggerService();
    setState(() {
      _isResending = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.resendVerificationEmail();

      logger.info(
        'Verification email resent',
        category: LogCategory.auth,
        tag: 'EmailVerificationScreen',
      );

      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          'تم إرسال رابط التحقق إلى بريدك الإلكتروني',
          backgroundColor: ref.read(themeColorsProvider).statusSuccess,
        );

        // Start cooldown
        _startResendCooldown();
      }
    } on AuthException catch (e) {
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          AuthService.getErrorMessage(e.message),
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showSnackBar(
           context,
          AuthService.getErrorMessage(e.toString()),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _startResendCooldown() {
    setState(() {
      _canResend = false;
      _resendCooldown = 60; // 60 seconds cooldown
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _resendCooldown--;
          if (_resendCooldown <= 0) {
            _canResend = true;
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _signOut() async {
    final authService = ref.read(authServiceProvider);
    await authService.signOut();

    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '';

    return Scaffold(
      body: Semantics(
        label: 'شاشة التحقق من البريد الإلكتروني',
        child: GradientBackground(
          animated: true,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Email icon
                    Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.goldenGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.premiumGold.withValues(alpha: 0.5),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.mark_email_unread_rounded,
                              size: 50,
                              color: themeColors.textOnGradient,
                            ),
                          ),
                        )
                        .animate()
                        .scale(
                          duration: AppAnimations.dramatic,
                          curve: Curves.elasticOut,
                        )
                        .fadeIn(),

                    const SizedBox(height: AppSpacing.lg),

                    // Title
                    Text(
                          'تحقق من بريدك الإلكتروني',
                          style: AppTypography.dramatic.copyWith(
                            color: themeColors.textOnGradient,
                          ),
                          textAlign: TextAlign.center,
                        )
                        .animate(delay: AppAnimations.fast)
                        .fadeIn(duration: AppAnimations.dramatic)
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: AppSpacing.sm),

                    Text(
                          'أرسلنا رابط التحقق إلى',
                          style: AppTypography.bodyLarge.copyWith(
                            color: themeColors.textOnGradient.withValues(alpha: 0.8),
                          ),
                          textAlign: TextAlign.center,
                        )
                        .animate(delay: AppAnimations.normal)
                        .fadeIn(duration: AppAnimations.dramatic),

                    const SizedBox(height: AppSpacing.xs),

                    Text(
                          email,
                          style: AppTypography.labelLarge.copyWith(
                            color: themeColors.textOnGradient,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.ltr,
                        )
                        .animate(delay: AppAnimations.normal)
                        .fadeIn(duration: AppAnimations.dramatic),

                    const SizedBox(height: AppSpacing.xxxl),

                    // Instructions card
                    DramaticGlassCard(
                          child: Column(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: themeColors.textOnGradient.withValues(alpha: 0.8),
                                size: 32,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'افتح بريدك الإلكتروني واضغط على رابط التحقق للمتابعة',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: themeColors.textOnGradient.withValues(alpha: 0.9),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              // Resend button
                              if (_canResend)
                                Semantics(
                                  label: 'إعادة إرسال رابط التحقق',
                                  button: true,
                                  child: GradientButton(
                                    text: 'إعادة إرسال الرابط',
                                    onPressed: _resendVerificationEmail,
                                    isLoading: _isResending,
                                    icon: Icons.refresh_rounded,
                                  ),
                                )
                              else
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: null,
                                    icon: Icon(
                                      Icons.timer_outlined,
                                      color: themeColors.textOnGradient.withValues(alpha: 0.5),
                                    ),
                                    label: Text(
                                      'انتظر $_resendCooldown ثانية',
                                      style: AppTypography.labelLarge.copyWith(
                                        color: themeColors.textOnGradient.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: themeColors.textOnGradient.withValues(alpha: 0.3),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: AppSpacing.md,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusLg,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              const SizedBox(height: AppSpacing.md),

                              // Check manually button
                              Semantics(
                                label: 'تحقق من حالة البريد الإلكتروني',
                                button: true,
                                child: TextButton.icon(
                                  onPressed: _checkEmailVerification,
                                  icon: Icon(
                                    Icons.check_circle_outline,
                                    color: themeColors.textOnGradient.withValues(alpha: 0.8),
                                  ),
                                  label: Text(
                                    'لقد تحققت بالفعل',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: themeColors.textOnGradient.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate(delay: AppAnimations.slow)
                        .fadeIn(duration: AppAnimations.slow)
                        .slideY(begin: 0.3, end: 0, curve: AppAnimations.enterCurve),

                    const SizedBox(height: AppSpacing.xl),

                    // Back to login
                    Semantics(
                      label: 'العودة لتسجيل الدخول',
                      button: true,
                      child: TextButton(
                            onPressed: _signOut,
                            child: Text(
                              'العودة لتسجيل الدخول',
                              style: AppTypography.labelMedium.copyWith(
                                color: themeColors.textOnGradient.withValues(alpha: 0.8),
                              ),
                            ),
                          )
                          .animate(delay: AppAnimations.celebration)
                          .fadeIn(duration: AppAnimations.dramatic),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
