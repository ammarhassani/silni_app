import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../core/providers/analytics_provider.dart';
import '../../../shared/services/auth_service.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);

      print('🔐 [LOGIN] Starting login process...');
      print('📧 [LOGIN] Email: ${_emailController.text.trim()}');

      // Add timeout to prevent infinite hanging
      final credential = await authService
          .signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Login timeout - Firebase took too long to respond');
            },
          );

      print('✅ [LOGIN] Supabase authentication successful!');
      print('👤 [LOGIN] User ID: ${credential.user?.id}');
      print('📧 [LOGIN] Email: ${credential.user?.email}');

      // Track login event (fire and forget - don't block auth flow)
      final analytics = ref.read(analyticsServiceProvider);
      analytics.logLogin('email').catchError((e) {
        if (kDebugMode) print('⚠️ [LOGIN] Analytics failed: $e');
      });

      if (!mounted) {
        print('⚠️ [LOGIN] Widget unmounted, aborting navigation');
        return;
      }

      print('🚀 [LOGIN] Navigating to home screen...');

      // Navigate to home - use go instead of pushReplacement
      context.go(AppRoutes.home);

      print('✅ [LOGIN] Navigation initiated successfully!');

      // Don't reset loading state on success - let the new screen take over
    } on AuthException catch (e) {
      // Handle Supabase auth errors specifically
      print('❌ [LOGIN] AuthException: ${e.message}');

      if (!mounted) return;

      setState(() => _isLoading = false);

      String errorMessage = AuthService.getErrorMessage(e.message);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Handle other errors
      print('❌ [LOGIN] Unexpected error: ${e.runtimeType} - $e');

      if (!mounted) return;

      setState(() => _isLoading = false);

      // For non-auth errors, pass the string to getErrorMessage
      String errorMessage = AuthService.getErrorMessage(e.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'إعادة تعيين كلمة المرور',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'سنرسل لك رابط لإعادة تعيين كلمة المرور',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  prefixIcon: const Icon(Icons.email, color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال البريد الإلكتروني';
                  }
                  if (!value.contains('@')) {
                    return 'يرجى إدخال بريد إلكتروني صحيح';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final authService = ref.read(authServiceProvider);
        await authService.resetPassword(emailController.text.trim());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إرسال رابط إعادة التعيين إلى بريدك الإلكتروني'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ: ${e.toString()}'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }

    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
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
                        gradient: AppColors.goldenGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.premiumGold.withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.people_alt_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    )
                        .animate()
                        .scale(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.elasticOut,
                        )
                        .fadeIn(),

                    const SizedBox(height: AppSpacing.lg),

                    // Welcome text
                    Text(
                      'مرحباً بعودتك',
                      style: AppTypography.dramatic.copyWith(
                        color: Colors.white,
                      ),
                    )
                        .animate(delay: const Duration(milliseconds: 200))
                        .fadeIn(duration: const Duration(milliseconds: 600))
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      'سجّل الدخول للمتابعة',
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    )
                        .animate(delay: const Duration(milliseconds: 400))
                        .fadeIn(duration: const Duration(milliseconds: 600))
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: AppSpacing.xxxl),

                    // Login form in glass card
                    DramaticGlassCard(
                      child: Column(
                        children: [
                          // Email field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textDirection: TextDirection.ltr,
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              labelText: 'البريد الإلكتروني',
                              labelStyle: AppTypography.bodyMedium.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                              hintText: 'example@email.com',
                              hintStyle: AppTypography.bodyMedium.copyWith(
                                color: Colors.white.withOpacity(0.5),
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusLg,
                                ),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusLg,
                                ),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusLg,
                                ),
                                borderSide: const BorderSide(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'الرجاء إدخال البريد الإلكتروني';
                              }
                              if (!value.contains('@')) {
                                return 'البريد الإلكتروني غير صحيح';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textDirection: TextDirection.ltr,
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              labelText: 'كلمة المرور',
                              labelStyle: AppTypography.bodyMedium.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                              hintText: '••••••••',
                              hintStyle: AppTypography.bodyMedium.copyWith(
                                color: Colors.white.withOpacity(0.5),
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusLg,
                                ),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusLg,
                                ),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusLg,
                                ),
                                borderSide: const BorderSide(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'الرجاء إدخال كلمة المرور';
                              }
                              if (value.length < 6) {
                                return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: AppSpacing.sm),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              child: Text(
                                'نسيت كلمة المرور؟',
                                style: AppTypography.labelMedium.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // Login button
                          GradientButton(
                            text: 'تسجيل الدخول',
                            onPressed: _login,
                            isLoading: _isLoading,
                            icon: Icons.login_rounded,
                          ),
                        ],
                      ),
                    )
                        .animate(delay: const Duration(milliseconds: 600))
                        .fadeIn(duration: const Duration(milliseconds: 800))
                        .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

                    const SizedBox(height: AppSpacing.xl),

                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'ليس لديك حساب؟',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.go(AppRoutes.signup);
                          },
                          child: Text(
                            'سجّل الآن',
                            style: AppTypography.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    )
                        .animate(delay: const Duration(milliseconds: 800))
                        .fadeIn(duration: const Duration(milliseconds: 600)),
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
