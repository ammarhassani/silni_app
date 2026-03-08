import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../providers/auth_provider.dart';

class PhoneVerificationScreen extends ConsumerStatefulWidget {
  const PhoneVerificationScreen({super.key, this.returnRoute});

  final String? returnRoute;

  @override
  ConsumerState<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends ConsumerState<PhoneVerificationScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;
  bool _canResend = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startResendCooldown() {
    setState(() {
      _canResend = false;
      _resendCooldown = 60;
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

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.updateUserPhone(phone);

      if (mounted) {
        setState(() {
          _otpSent = true;
          _isLoading = false;
        });
        _startResendCooldown();
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        UIHelpers.showSnackBar(context, e.message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        UIHelpers.showSnackBar(context, e.toString(), isError: true);
      }
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.verifyPhoneUpdate(
        phone: _phoneController.text.trim(),
        token: otp,
      );

      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          '\u062a\u0645 \u062a\u0623\u0643\u064a\u062f \u0631\u0642\u0645 \u0627\u0644\u062c\u0648\u0627\u0644 \u0628\u0646\u062c\u0627\u062d', // تم تأكيد رقم الجوال بنجاح
          backgroundColor: ref.read(themeColorsProvider).statusSuccess,
        );

        if (widget.returnRoute != null) {
          context.go(widget.returnRoute!);
        } else {
          context.pop();
        }
      }
    } on AuthException catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        UIHelpers.showSnackBar(
          context,
          '\u0631\u0645\u0632 \u0627\u0644\u062a\u062d\u0642\u0642 \u063a\u064a\u0631 \u0635\u062d\u064a\u062d', // رمز التحقق غير صحيح
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        UIHelpers.showSnackBar(
          context,
          '\u0631\u0645\u0632 \u0627\u0644\u062a\u062d\u0642\u0642 \u063a\u064a\u0631 \u0635\u062d\u064a\u062d', // رمز التحقق غير صحيح
          isError: true,
        );
      }
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    await _sendOtp();
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);

    return Scaffold(
      body: Semantics(
        label: '\u0634\u0627\u0634\u0629 \u062a\u0623\u0643\u064a\u062f \u0631\u0642\u0645 \u0627\u0644\u062c\u0648\u0627\u0644', // شاشة تأكيد رقم الجوال
        child: GradientBackground(
          animated: true,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Phone icon
                    Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.goldenGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.premiumGold
                                    .withValues(alpha: 0.5),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              _otpSent
                                  ? Icons.sms_rounded
                                  : Icons.phone_android_rounded,
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
                          '\u062a\u0623\u0643\u064a\u062f \u0631\u0642\u0645 \u0627\u0644\u062c\u0648\u0627\u0644', // تأكيد رقم الجوال
                          style: AppTypography.dramatic.copyWith(
                            color: themeColors.textOnGradient,
                          ),
                          textAlign: TextAlign.center,
                        )
                        .animate(delay: AppAnimations.fast)
                        .fadeIn(duration: AppAnimations.dramatic)
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: AppSpacing.xxxl),

                    // Input card
                    DramaticGlassCard(
                          child: Column(
                            children: [
                              if (!_otpSent) ...[
                                // Phone entry state
                                Text(
                                  '\u0623\u062f\u062e\u0644 \u0631\u0642\u0645 \u062c\u0648\u0627\u0644\u0643', // أدخل رقم جوالك
                                  style: AppTypography.bodyLarge.copyWith(
                                    color: themeColors.textOnGradient
                                        .withValues(alpha: 0.9),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: TextField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.headlineSmall.copyWith(
                                      color: themeColors.textOnGradient,
                                      letterSpacing: 1.5,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '+966 5XX XXX XXXX',
                                      hintStyle:
                                          AppTypography.bodyLarge.copyWith(
                                        color: themeColors.textOnGradient
                                            .withValues(alpha: 0.4),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusMd,
                                        ),
                                        borderSide: BorderSide(
                                          color: themeColors.textOnGradient
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusMd,
                                        ),
                                        borderSide: BorderSide(
                                          color: themeColors.textOnGradient
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusMd,
                                        ),
                                        borderSide: BorderSide(
                                          color: AppColors.premiumGold,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.md,
                                      ),
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9+\s]'),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Semantics(
                                  label:
                                      '\u0625\u0631\u0633\u0627\u0644 \u0631\u0645\u0632 \u0627\u0644\u062a\u062d\u0642\u0642', // إرسال رمز التحقق
                                  button: true,
                                  child: GradientButton(
                                    text:
                                        '\u0625\u0631\u0633\u0627\u0644 \u0631\u0645\u0632 \u0627\u0644\u062a\u062d\u0642\u0642', // إرسال رمز التحقق
                                    onPressed: _sendOtp,
                                    isLoading: _isLoading,
                                    icon: Icons.send_rounded,
                                  ),
                                ),
                              ] else ...[
                                // OTP entry state
                                Text(
                                  '\u0623\u062f\u062e\u0644 \u0631\u0645\u0632 \u0627\u0644\u062a\u062d\u0642\u0642', // أدخل رمز التحقق
                                  style: AppTypography.bodyLarge.copyWith(
                                    color: themeColors.textOnGradient
                                        .withValues(alpha: 0.9),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '\u062a\u0645 \u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u0631\u0645\u0632 \u0625\u0644\u0649 ${_phoneController.text.trim()}', // تم إرسال الرمز إلى
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: themeColors.textOnGradient
                                        .withValues(alpha: 0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.rtl,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: TextField(
                                    controller: _otpController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    maxLength: 6,
                                    style: AppTypography.headlineMedium.copyWith(
                                      color: themeColors.textOnGradient,
                                      letterSpacing: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: InputDecoration(
                                      counterText: '',
                                      hintText: '------',
                                      hintStyle: AppTypography.headlineMedium
                                          .copyWith(
                                        color: themeColors.textOnGradient
                                            .withValues(alpha: 0.3),
                                        letterSpacing: 12,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusMd,
                                        ),
                                        borderSide: BorderSide(
                                          color: themeColors.textOnGradient
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusMd,
                                        ),
                                        borderSide: BorderSide(
                                          color: themeColors.textOnGradient
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusMd,
                                        ),
                                        borderSide: BorderSide(
                                          color: AppColors.premiumGold,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.md,
                                      ),
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(6),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Semantics(
                                  label:
                                      '\u062a\u0623\u0643\u064a\u062f', // تأكيد
                                  button: true,
                                  child: GradientButton(
                                    text:
                                        '\u062a\u0623\u0643\u064a\u062f', // تأكيد
                                    onPressed: _verifyOtp,
                                    isLoading: _isLoading,
                                    icon: Icons.check_rounded,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                // Resend OTP
                                if (_canResend)
                                  Semantics(
                                    label:
                                        '\u0625\u0639\u0627\u062f\u0629 \u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u0631\u0645\u0632', // إعادة إرسال الرمز
                                    button: true,
                                    child: TextButton.icon(
                                      onPressed: _resendOtp,
                                      icon: Icon(
                                        Icons.refresh_rounded,
                                        color: themeColors.textOnGradient
                                            .withValues(alpha: 0.8),
                                      ),
                                      label: Text(
                                        '\u0625\u0639\u0627\u062f\u0629 \u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u0631\u0645\u0632', // إعادة إرسال الرمز
                                        style:
                                            AppTypography.labelMedium.copyWith(
                                          color: themeColors.textOnGradient
                                              .withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Text(
                                    '\u0627\u0646\u062a\u0638\u0631 $_resendCooldown \u062b\u0627\u0646\u064a\u0629', // انتظر N ثانية
                                    style: AppTypography.labelMedium.copyWith(
                                      color: themeColors.textOnGradient
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        )
                        .animate(delay: AppAnimations.slow)
                        .fadeIn(duration: AppAnimations.slow)
                        .slideY(
                          begin: 0.3,
                          end: 0,
                          curve: AppAnimations.enterCurve,
                        ),

                    const SizedBox(height: AppSpacing.xl),

                    // Back button
                    Semantics(
                      label: '\u0631\u062c\u0648\u0639', // رجوع
                      button: true,
                      child: TextButton(
                            onPressed: () => context.pop(),
                            child: Text(
                              '\u0631\u062c\u0648\u0639', // رجوع
                              style: AppTypography.labelMedium.copyWith(
                                color: themeColors.textOnGradient
                                    .withValues(alpha: 0.8),
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
