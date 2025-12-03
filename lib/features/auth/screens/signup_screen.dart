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

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    debugPrint('');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📝 [SIGNUP FLOW] STARTED');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (!_formKey.currentState!.validate()) {
      debugPrint('⚠️ [SIGNUP FLOW] Form validation failed');
      return;
    }

    debugPrint('✅ [SIGNUP FLOW] Form validation passed');
    debugPrint('📊 [SIGNUP FLOW] Setting loading state to true');

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      debugPrint('✅ [SIGNUP FLOW] AuthService retrieved from provider');

      debugPrint('👤 [SIGNUP FLOW] User data:');
      debugPrint('   - Name: ${_nameController.text.trim()}');
      debugPrint('   - Email: ${_emailController.text.trim()}');
      debugPrint('');

      debugPrint('🔄 [SIGNUP FLOW] Calling authService.signUpWithEmail() with 30s timeout...');
      final startTime = DateTime.now();

      // Add timeout to prevent infinite hanging (increased for iOS networks)
      final credential = await authService
          .signUpWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
          )
          .timeout(
            const Duration(seconds: 30),  // Increased from 15s for iOS
            onTimeout: () {
              debugPrint('⏱️ [SIGNUP FLOW] TIMEOUT after 30 seconds');
              throw Exception(
                'Signup is taking longer than expected. This may indicate a '
                'network issue or service problem. Please try again.'
              );
            },
          );

      final duration = DateTime.now().difference(startTime);
      debugPrint('✅ [SIGNUP FLOW] Supabase auth completed in ${duration.inMilliseconds}ms');
      debugPrint('👤 [SIGNUP FLOW] User created successfully:');
      debugPrint('   - User ID: ${credential.user?.id}');
      debugPrint('   - Email: ${credential.user?.email}');
      debugPrint('   - Session exists: ${credential.session != null}');
      debugPrint('   - Session token: ${credential.session?.accessToken != null ? '(present)' : '(null)'}');
      debugPrint('');

      // Track signup event (fire and forget - don't block auth flow)
      debugPrint('📊 [SIGNUP FLOW] Triggering analytics (fire-and-forget)...');
      final analytics = ref.read(analyticsServiceProvider);
      analytics.logSignUp('email').catchError((e) {
        debugPrint('⚠️ [SIGNUP FLOW] Analytics failed (non-blocking): $e');
      });
      debugPrint('✅ [SIGNUP FLOW] Analytics call initiated (not waiting for completion)');
      debugPrint('');

      if (!mounted) {
        debugPrint('🔴 [SIGNUP FLOW] Widget unmounted, aborting navigation');
        debugPrint('🔴 [SIGNUP FLOW] FLOW ABORTED');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('');
        return;
      }

      debugPrint('✅ [SIGNUP FLOW] Widget still mounted');
      debugPrint('🚀 [SIGNUP FLOW] Attempting navigation to home screen...');
      debugPrint('   - Target route: ${AppRoutes.home}');
      debugPrint('   - Navigation method: context.go()');

      // Navigate to home
      context.go(AppRoutes.home);

      debugPrint('✅ [SIGNUP FLOW] context.go() executed successfully');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('✅ [SIGNUP FLOW] COMPLETED SUCCESSFULLY');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('');

      // Don't reset loading state on success - let the new screen take over
    } on AuthException catch (e, stackTrace) {
      // Handle Supabase auth errors specifically
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔴 [SIGNUP FLOW] AuthException caught');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('❌ [SIGNUP FLOW] Error message: ${e.message}');
      debugPrint('❌ [SIGNUP FLOW] Status code: ${e.statusCode}');
      debugPrint('📍 [SIGNUP FLOW] Stack trace:');
      debugPrint(stackTrace.toString());
      debugPrint('');

      if (!mounted) {
        debugPrint('⚠️ [SIGNUP FLOW] Widget unmounted, cannot show error');
        return;
      }

      setState(() => _isLoading = false);
      debugPrint('📊 [SIGNUP FLOW] Loading state reset to false');

      String errorMessage = AuthService.getErrorMessage(e.message);
      debugPrint('💬 [SIGNUP FLOW] User error message: $errorMessage');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
      debugPrint('📢 [SIGNUP FLOW] Error shown to user via SnackBar');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔴 [SIGNUP FLOW] FAILED WITH AUTH ERROR');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('');
    } catch (e, stackTrace) {
      // Handle other errors
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔴 [SIGNUP FLOW] Unexpected exception caught');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('❌ [SIGNUP FLOW] Exception type: ${e.runtimeType}');
      debugPrint('❌ [SIGNUP FLOW] Exception: $e');
      debugPrint('📍 [SIGNUP FLOW] Stack trace:');
      debugPrint(stackTrace.toString());
      debugPrint('');

      if (!mounted) {
        debugPrint('⚠️ [SIGNUP FLOW] Widget unmounted, cannot show error');
        return;
      }

      setState(() => _isLoading = false);
      debugPrint('📊 [SIGNUP FLOW] Loading state reset to false');

      // For non-auth errors, pass the string to getErrorMessage
      String errorMessage = AuthService.getErrorMessage(e.toString());
      debugPrint('💬 [SIGNUP FLOW] User error message: $errorMessage');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
      debugPrint('📢 [SIGNUP FLOW] Error shown to user via SnackBar');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔴 [SIGNUP FLOW] FAILED WITH UNEXPECTED ERROR');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('');
    }
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
                        gradient: AppColors.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.islamicGreenPrimary.withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person_add_rounded,
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
                      'انضم إلينا',
                      style: AppTypography.dramatic.copyWith(
                        color: Colors.white,
                      ),
                    )
                        .animate(delay: const Duration(milliseconds: 200))
                        .fadeIn(duration: const Duration(milliseconds: 600))
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      'ابدأ رحلتك في صلة الرحم',
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    )
                        .animate(delay: const Duration(milliseconds: 400))
                        .fadeIn(duration: const Duration(milliseconds: 600))
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: AppSpacing.xl),

                    // Sign up form in glass card
                    DramaticGlassCard(
                      child: Column(
                        children: [
                          // Name field
                          _buildTextField(
                            controller: _nameController,
                            label: 'الاسم الكامل',
                            hint: 'أدخل اسمك الكامل',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'الرجاء إدخال الاسم';
                              }
                              if (value.length < 2) {
                                return 'الاسم يجب أن يكون حرفين على الأقل';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // Email field
                          _buildTextField(
                            controller: _emailController,
                            label: 'البريد الإلكتروني',
                            hint: 'example@email.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textDirection: TextDirection.ltr,
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
                          _buildTextField(
                            controller: _passwordController,
                            label: 'كلمة المرور',
                            hint: '••••••••',
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            textDirection: TextDirection.ltr,
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

                          const SizedBox(height: AppSpacing.md),

                          // Confirm password field
                          _buildTextField(
                            controller: _confirmPasswordController,
                            label: 'تأكيد كلمة المرور',
                            hint: '••••••••',
                            icon: Icons.lock_outline,
                            obscureText: _obscureConfirmPassword,
                            textDirection: TextDirection.ltr,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
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

                          // Sign up button
                          GradientButton(
                            text: 'إنشاء حساب',
                            onPressed: _signUp,
                            isLoading: _isLoading,
                            icon: Icons.rocket_launch_rounded,
                          ),
                        ],
                      ),
                    )
                        .animate(delay: const Duration(milliseconds: 600))
                        .fadeIn(duration: const Duration(milliseconds: 800))
                        .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

                    const SizedBox(height: AppSpacing.xl),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'لديك حساب بالفعل؟',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.go(AppRoutes.login);
                          },
                          child: Text(
                            'سجّل الدخول',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    TextDirection? textDirection,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textDirection: textDirection,
      style: AppTypography.bodyMedium.copyWith(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: Colors.white.withOpacity(0.8),
        ),
        hintText: hint,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: Colors.white.withOpacity(0.5),
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.white.withOpacity(0.7),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: const BorderSide(
            color: Colors.white,
            width: 2,
          ),
        ),
      ),
      validator: validator,
    );
  }
}
