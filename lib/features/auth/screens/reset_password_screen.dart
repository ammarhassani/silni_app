import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_animations.dart';
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

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final logger = AppLoggerService();
    logger.info('Password update flow started', category: LogCategory.auth, tag: 'ResetPasswordScreen');

    if (!_formKey.currentState!.validate()) {
      logger.warning('Form validation failed', category: LogCategory.auth, tag: 'ResetPasswordScreen');
      return;
    }

    logger.debug('Form validation passed', category: LogCategory.auth, tag: 'ResetPasswordScreen');
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      logger.debug('AuthService retrieved from provider', category: LogCategory.auth, tag: 'ResetPasswordScreen');

      logger.info('Calling updatePassword...', category: LogCategory.auth, tag: 'ResetPasswordScreen');

      await authService.updatePassword(_passwordController.text);

      logger.info('Password updated successfully', category: LogCategory.auth, tag: 'ResetPasswordScreen');

      if (!mounted) {
        logger.warning('Widget unmounted, aborting navigation', category: LogCategory.auth, tag: 'ResetPasswordScreen');
        return;
      }

      // Show success message
      UIHelpers.showSnackBar(
        context,
        'تم تحديث كلمة المرور بنجاح',
        isError: false,
      );

      // Sign out and redirect to login
      await authService.signOut();

      if (!mounted) return;
      context.go(AppRoutes.login);

      logger.info('Navigation to login executed - Password reset flow completed', category: LogCategory.auth, tag: 'ResetPasswordScreen');
    } on AuthException catch (e, stackTrace) {
      logger.error(
        'AuthException during password update',
        category: LogCategory.auth,
        tag: 'ResetPasswordScreen',
        metadata: {
          'message': e.message,
          'statusCode': e.statusCode,
        },
        stackTrace: stackTrace,
      );

      if (!mounted) {
        logger.warning('Widget unmounted, cannot show error', category: LogCategory.auth, tag: 'ResetPasswordScreen');
        return;
      }

      setState(() => _isLoading = false);

      String errorMessage = AuthService.getErrorMessage(e.message);
      logger.debug('Showing error to user', category: LogCategory.auth, tag: 'ResetPasswordScreen', metadata: {'errorMessage': errorMessage});

      UIHelpers.showSnackBar(
        context,
        errorMessage,
        isError: true,
      );

      logger.error('Password update failed with auth error', category: LogCategory.auth, tag: 'ResetPasswordScreen');
    } catch (e, stackTrace) {
      logger.error(
        'Unexpected exception during password update',
        category: LogCategory.auth,
        tag: 'ResetPasswordScreen',
        metadata: {
          'exceptionType': e.runtimeType.toString(),
          'exception': e.toString(),
        },
        stackTrace: stackTrace,
      );

      if (!mounted) {
        logger.warning('Widget unmounted, cannot show error', category: LogCategory.auth, tag: 'ResetPasswordScreen');
        return;
      }

      setState(() => _isLoading = false);

      String errorMessage = AuthService.getErrorMessage(e.toString());
      logger.debug('Showing error to user', category: LogCategory.auth, tag: 'ResetPasswordScreen', metadata: {'errorMessage': errorMessage});

      UIHelpers.showSnackBar(
        context,
        errorMessage,
        isError: true,
      );

      logger.error('Password update failed with unexpected error', category: LogCategory.auth, tag: 'ResetPasswordScreen');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);

    return Scaffold(
      body: Semantics(
        label: 'شاشة إعادة تعيين كلمة المرور',
        child: GradientBackground(
          animated: true,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: themeColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: themeColors.primary.withValues(alpha: 0.5),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.lock_reset_rounded,
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

                      // Title text
                      Text(
                        'كلمة مرور جديدة',
                        style: AppTypography.dramatic.copyWith(
                          color: themeColors.textOnGradient,
                        ),
                      )
                          .animate(delay: AppAnimations.fast)
                          .fadeIn(duration: AppAnimations.dramatic)
                          .slideY(begin: 0.3, end: 0),

                      const SizedBox(height: AppSpacing.sm),

                      Text(
                        'أدخل كلمة المرور الجديدة',
                        style: AppTypography.bodyLarge.copyWith(
                          color: themeColors.textOnGradient.withValues(alpha: 0.8),
                        ),
                      )
                          .animate(delay: AppAnimations.normal)
                          .fadeIn(duration: AppAnimations.dramatic)
                          .slideY(begin: 0.3, end: 0),

                      const SizedBox(height: AppSpacing.xl),

                      // Password form in glass card
                      DramaticGlassCard(
                        child: Column(
                          children: [
                            // Password field
                            _buildTextField(
                              controller: _passwordController,
                              label: 'كلمة المرور الجديدة',
                              hint: '••••••••',
                              icon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              textDirection: TextDirection.ltr,
                              themeColors: themeColors,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: themeColors.textOnGradient.withValues(alpha: 0.7),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'الرجاء إدخال كلمة المرور';
                                }
                                if (value.length < 8) {
                                  return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
                                }
                                if (!RegExp(r'[A-Z]').hasMatch(value)) {
                                  return 'يجب أن تحتوي على حرف كبير واحد على الأقل';
                                }
                                if (!RegExp(r'[a-z]').hasMatch(value)) {
                                  return 'يجب أن تحتوي على حرف صغير واحد على الأقل';
                                }
                                if (!RegExp(r'[0-9]').hasMatch(value)) {
                                  return 'يجب أن تحتوي على رقم واحد على الأقل';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: AppSpacing.md),

                            // Confirm password field
                            _buildTextField(
                              controller: _confirmPasswordController,
                              label: 'تأكيد كلمة المرور',
                              hint: '••••••••',
                              icon: Icons.lock_outline,
                              obscureText: _obscureConfirmPassword,
                              textDirection: TextDirection.ltr,
                              themeColors: themeColors,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: themeColors.textOnGradient.withValues(alpha: 0.7),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'الرجاء تأكيد كلمة المرور';
                                }
                                if (value != _passwordController.text) {
                                  return 'كلمة المرور غير متطابقة';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: AppSpacing.xl),

                            // Update password button
                            GradientButton(
                              text: 'تحديث كلمة المرور',
                              onPressed: _updatePassword,
                              isLoading: _isLoading,
                              icon: Icons.check_circle_outline_rounded,
                            ),
                          ],
                        ),
                      )
                          .animate(delay: AppAnimations.dramatic)
                          .fadeIn(duration: AppAnimations.slow)
                          .slideY(begin: 0.3, end: 0, curve: AppAnimations.enterCurve),

                      const SizedBox(height: AppSpacing.xl),

                      // Back to login link
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'تذكرت كلمة المرور؟',
                            style: AppTypography.bodyMedium.copyWith(
                              color: themeColors.textOnGradient.withValues(alpha: 0.8),
                            ),
                          ),
                          Semantics(
                            label: 'العودة لتسجيل الدخول',
                            button: true,
                            child: TextButton(
                              onPressed: () {
                                context.go(AppRoutes.login);
                              },
                              child: Text(
                                'تسجيل الدخول',
                                style: AppTypography.labelLarge.copyWith(
                                  color: themeColors.textOnGradient,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                          .animate(delay: AppAnimations.slow)
                          .fadeIn(duration: AppAnimations.dramatic),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required dynamic themeColors,
    TextInputType? keyboardType,
    bool obscureText = false,
    TextDirection? textDirection,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Semantics(
      label: label,
      textField: true,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        textDirection: textDirection,
        style: AppTypography.bodyMedium.copyWith(
          color: themeColors.textOnGradient,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTypography.bodyMedium.copyWith(
            color: themeColors.textOnGradient.withValues(alpha: 0.8),
          ),
          hintText: hint,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: themeColors.textOnGradient.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            icon,
            color: themeColors.textOnGradient.withValues(alpha: 0.7),
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: themeColors.textOnGradient.withValues(alpha: 0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            borderSide: BorderSide(
              color: themeColors.textOnGradient.withValues(alpha: 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            borderSide: BorderSide(
              color: themeColors.textOnGradient.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            borderSide: BorderSide(
              color: themeColors.textOnGradient,
              width: 2,
            ),
          ),
        ),
        validator: validator,
      ),
    );
  }
}
