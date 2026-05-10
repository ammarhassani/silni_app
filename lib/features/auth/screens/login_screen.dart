import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/router/app_router.dart' as router;
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../core/providers/analytics_provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/biometric_service.dart';
import '../../../shared/services/session_persistence_service.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../providers/auth_provider.dart';
import '../../../core/services/app_logger_service.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/errors/app_errors.dart';
import '../../../core/services/error_reporter.dart';
import '../widgets/social_login_button.dart';
import '../widgets/name_prompt_dialog.dart';
import '../../../shared/widgets/theme_aware_dialog.dart';
import '../../../shared/widgets/glass_dialog.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:io' show Platform;


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
  bool _biometricAvailable = false;
  bool _hasSavedCredentials = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  String? _cachedProfilePictureUrl;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _loadCachedProfilePicture();
  }

  Future<void> _loadCachedProfilePicture() async {
    final url = await SessionPersistenceService().getSavedProfilePictureUrl();
    if (mounted && url != null) {
      setState(() => _cachedProfilePictureUrl = url);
    }
  }

  /// Cache the current user's profile picture URL for next login screen visit.
  void _cacheProfilePicture(User? user) {
    final url = user?.userMetadata?['profile_picture_url'] as String?;
    SessionPersistenceService().saveProfilePictureUrl(url);
  }

  /// Navigate after successful login, honoring ?redirect= query param.
  ///
  /// Phase 9.X.D.B Track B3: explicitly hydrates the setupComplete cache
  /// BEFORE navigating, closing the race between the auth listener's
  /// fire-and-forget DB roundtrip and the navigation. New users (no
  /// setupComplete in metadata) land on the wizard; existing users (or
  /// those with completed setup) land on home.
  Future<void> _navigateAfterLogin() async {
    // Honor explicit redirect query param FIRST (deep-link join flows
    // bypass the wizard — joining a group implicitly completes setup).
    final redirect = GoRouterState.of(context).uri.queryParameters['redirect'];
    if (redirect != null && redirect.isNotEmpty) {
      final decodedPath = Uri.decodeComponent(redirect);
      if (decodedPath.startsWith('/join') ||
          decodedPath.startsWith('/join-family-group')) {
        if (!mounted) return;
        context.go(decodedPath);
        return;
      }
    }

    // Inline hydrate setup_complete from DB → SharedPreferences → router cache.
    // Mirrors main.dart#_hydrateSetupCompleteFromDb but is awaited here so the
    // immediately-following navigation reads the freshly-written cache.
    final user = SupabaseConfig.client.auth.currentUser;
    bool isComplete = true; // default to "go home" if anything fails
    if (user != null) {
      try {
        final row = await SupabaseConfig.client
            .from('users')
            .select('onboarding_metadata')
            .eq('id', user.id)
            .maybeSingle();
        final meta =
            (row?['onboarding_metadata'] as Map<String, dynamic>?) ?? const {};
        isComplete = meta['setupComplete'] == true ||
            meta['setupComplete'] == 'true';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('setup_complete', isComplete);
        router.setCachedSetupComplete(isComplete);
      } catch (_) {
        // Network failure → fall through to home, treat as complete.
        // Worst case: user reaches home without seeing wizard. They can
        // re-run via Settings → "إعادة الإعداد".
      }
    }
    if (!mounted) return;
    context.go(isComplete ? AppRoutes.home : AppRoutes.onboardingWizard);
  }

  Future<void> _checkBiometricAvailability() async {
    final biometricService = BiometricService();
    final sessionService = SessionPersistenceService();

    final isSupported = await biometricService.isDeviceSupported();
    final isEnrolled = await biometricService.areBiometricsEnrolled();
    final hasCreds = await sessionService.isBiometricLoginEnabled();

    if (mounted) {
      setState(() {
        _biometricAvailable = isSupported && isEnrolled;
        _hasSavedCredentials = hasCreds;
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    final biometricService = BiometricService();
    final logger = AppLoggerService();

    logger.info(
      'Biometric login flow started',
      category: LogCategory.auth,
      tag: 'LoginScreen',
    );

    // First verify biometrics (Face ID / Touch ID)
    final result = await biometricService.authenticate();

    if (result.success) {
      setState(() => _isLoading = true);

      try {
        // Biometric verified - use saved credentials to re-authenticate
        final authService = ref.read(authServiceProvider);
        final response = await authService.authenticateWithSavedCredentials();

        if (response?.user != null) {
          logger.info(
            'Biometric login successful',
            category: LogCategory.auth,
            tag: 'LoginScreen',
            metadata: {'userId': response!.user!.id},
          );

          // Cache profile picture for next login screen visit
          _cacheProfilePicture(response.user);

          // Track login and set user ID
          final analytics = ref.read(analyticsServiceProvider);
          analytics.logLogin('biometric').catchError((e) {
            logger.warning('Analytics logLogin failed: $e', category: LogCategory.analytics, tag: 'LoginScreen');
          });
          analytics.setUserId(response.user!.id).catchError((e) {
            logger.warning('Analytics setUserId failed: $e', category: LogCategory.analytics, tag: 'LoginScreen');
          });

          if (!mounted) return;
          _navigateAfterLogin();
        } else {
          // No saved credentials available
          if (mounted) {
            setState(() => _isLoading = false);
            _showSessionExpiredError();
          }
        }
      } on AuthException catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);

        logger.warning(
          'Biometric login failed - auth error',
          category: LogCategory.auth,
          tag: 'LoginScreen',
          metadata: {'error': e.message},
        );

        _showSessionExpiredError();
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);

        logger.warning(
          'Biometric login failed - unexpected error',
          category: LogCategory.auth,
          tag: 'LoginScreen',
          metadata: {'error': e.toString()},
        );

        _showSessionExpiredError();
      }
    } else if (result.error) {
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          result.errorMessage ?? 'فشل المصادقة البيومترية',
          isError: true,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  void _showSessionExpiredError() {
    UIHelpers.showSnackBar(
      context,
      'انتهت صلاحية الجلسة. يرجى تسجيل الدخول بكلمة المرور',
      isError: true,
      duration: const Duration(seconds: 3),
    );
    // Also refresh the biometric availability check since credentials may have been cleared
    _checkBiometricAvailability();
  }

  Future<void> _login() async {
    final logger = AppLoggerService();
    logger.info(
      'Login flow started',
      category: LogCategory.auth,
      tag: 'LoginScreen',
    );

    // Add platform detection for debugging
    logger.debug(
      'Platform info',
      category: LogCategory.auth,
      tag: 'LoginScreen',
      metadata: {
        'isWeb': kIsWeb,
        'platform': Theme.of(context).platform.toString(),
      },
    );

    if (!_formKey.currentState!.validate()) {
      logger.warning(
        'Form validation failed',
        category: LogCategory.auth,
        tag: 'LoginScreen',
      );
      return;
    }

    logger.debug(
      'Form validation passed',
      category: LogCategory.auth,
      tag: 'LoginScreen',
    );
    setState(() => _isLoading = true);

    try {
      // Add detailed logging for provider access
      logger.debug(
        'Attempting to access authServiceProvider...',
        category: LogCategory.auth,
        tag: 'LoginScreen',
      );

      // Check if Supabase is initialized before proceeding
      if (!SupabaseConfig.isInitialized) {
        logger.error(
          'Supabase not initialized - cannot proceed with login',
          category: LogCategory.auth,
          tag: 'LoginScreen',
        );

        if (!mounted) return;
        setState(() => _isLoading = false);

        UIHelpers.showSnackBar(
          context,
          'فشل تهيئة الاتصال بالخادم. يرجى إعادة تشغيل التطبيق والمحاولة مرة أخرى.\n'
          'Server connection failed to initialize. Please restart the app and try again.',
          isError: true,
          duration: const Duration(seconds: 5),
        );
        return;
      }

      final authService = ref.read(authServiceProvider);
      logger.debug(
        'AuthService retrieved successfully from provider',
        category: LogCategory.auth,
        tag: 'LoginScreen',
        metadata: {'authServiceType': authService.runtimeType.toString()},
      );

      logger.debug(
        'Login attempt',
        category: LogCategory.auth,
        tag: 'LoginScreen',
        metadata: {'email': _emailController.text.trim()},
      );

      logger.info(
        'Calling Supabase signInWithEmail (30s timeout)...',
        category: LogCategory.auth,
        tag: 'LoginScreen',
      );
      final startTime = DateTime.now();

      // Add timeout to prevent infinite hanging
      final credential = await authService
          .signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              logger.error(
                'Login timeout after 30 seconds',
                category: LogCategory.auth,
                tag: 'LoginScreen',
              );
              throw const TimeoutError(
                message: 'Login timeout - Supabase took too long to respond',
                arabicMessage: 'انتهت مهلة تسجيل الدخول، يرجى المحاولة مرة أخرى',
                timeout: Duration(seconds: 30),
              );
            },
          );

      final duration = DateTime.now().difference(startTime);
      logger.info(
        'Supabase auth completed successfully',
        category: LogCategory.auth,
        tag: 'LoginScreen',
        metadata: {
          'durationMs': duration.inMilliseconds,
          'userId': credential.user?.id,
          'email': credential.user?.email,
          'hasSession': credential.session != null,
          'hasToken': credential.session?.accessToken != null,
        },
      );

      // Enable biometric login for this session (fire and forget)
      // Note: We no longer store passwords - biometric unlocks the existing Supabase session
      SessionPersistenceService().enableBiometricLogin();

      // Cache profile picture for next login screen visit
      _cacheProfilePicture(credential.user);

      // Track login event and set user ID (fire and forget - don't block auth flow)
      logger.debug(
        'Triggering analytics (fire-and-forget)...',
        category: LogCategory.analytics,
        tag: 'LoginScreen',
      );
      final analytics = ref.read(analyticsServiceProvider);
      analytics.logLogin('email').catchError((e) {
        logger.warning(
          'Analytics failed (non-blocking)',
          category: LogCategory.analytics,
          tag: 'LoginScreen',
          metadata: {'error': e.toString()},
        );
      });
      if (credential.user != null) {
        analytics.setUserId(credential.user!.id).catchError((e) {
          logger.warning('Analytics setUserId failed: $e', category: LogCategory.analytics, tag: 'LoginScreen');
        });
      }

      if (!mounted) {
        logger.warning(
          'Widget unmounted, aborting navigation',
          category: LogCategory.auth,
          tag: 'LoginScreen',
        );
        return;
      }

      logger.info(
        'Widget still mounted, attempting navigation to home screen',
        category: LogCategory.auth,
        tag: 'LoginScreen',
        metadata: {'targetRoute': AppRoutes.home},
      );

      // Navigate — honor ?redirect= param (e.g. from join link)
      _navigateAfterLogin();

      logger.info(
        'Navigation executed successfully - Login flow completed',
        category: LogCategory.auth,
        tag: 'LoginScreen',
      );

      // Don't reset loading state on success - let the new screen take over
    } on AuthException catch (e, stackTrace) {
      // Handle Supabase auth errors specifically
      logger.error(
        'AuthException during login',
        category: LogCategory.auth,
        tag: 'LoginScreen',
        metadata: {'message': e.message, 'statusCode': e.statusCode},
        stackTrace: stackTrace,
      );

      if (!mounted) {
        logger.warning(
          'Widget unmounted, cannot show error',
          category: LogCategory.auth,
          tag: 'LoginScreen',
        );
        return;
      }

      setState(() => _isLoading = false);

      String errorMessage = AuthService.getErrorMessage(e.message);
      logger.debug(
        'Showing error to user',
        category: LogCategory.auth,
        tag: 'LoginScreen',
        metadata: {'errorMessage': errorMessage},
      );

      final errorColor = ref.read(themeColorsProvider).statusError;
      UIHelpers.showSnackBar(
        context,
        errorMessage,
        backgroundColor: errorColor,
        duration: const Duration(seconds: 3),
      );

      logger.error(
        'Login failed with auth error',
        category: LogCategory.auth,
        tag: 'LoginScreen',
      );
    } catch (e, stackTrace) {
      // Handle other errors
      logger.error(
        'Unexpected exception during login',
        category: LogCategory.auth,
        tag: 'LoginScreen',
        metadata: {
          'exceptionType': e.runtimeType.toString(),
          'exception': e.toString(),
        },
        stackTrace: stackTrace,
      );

      if (!mounted) {
        logger.warning(
          'Widget unmounted, cannot show error',
          category: LogCategory.auth,
          tag: 'LoginScreen',
        );
        return;
      }

      setState(() => _isLoading = false);

      // For non-auth errors, pass the string to getErrorMessage
      String errorMessage = AuthService.getErrorMessage(e.toString());
      logger.debug(
        'Showing error to user',
        category: LogCategory.auth,
        tag: 'LoginScreen',
        metadata: {'errorMessage': errorMessage},
      );

      final unexpectedErrorColor = ref.read(themeColorsProvider).statusError;
      UIHelpers.showSnackBar(
        context,
        errorMessage,
        backgroundColor: unexpectedErrorColor,
        duration: const Duration(seconds: 3),
      );

      logger.error(
        'Login failed with unexpected error',
        category: LogCategory.auth,
        tag: 'LoginScreen',
      );
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => GlassDialog(
        icon: Icons.lock_reset_rounded,
        title: 'إعادة تعيين كلمة المرور',
        subtitle: 'سنرسل لك رابط لإعادة تعيين كلمة المرور',
        content: Form(
          key: formKey,
          child: ThemeAwareTextField(
            controller: emailController,
            label: 'البريد الإلكتروني',
            hintText: 'بريدك الإلكتروني',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال البريد الإلكتروني';
              }
              final emailRegex = RegExp(
                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
              );
              if (!emailRegex.hasMatch(value)) {
                return 'يرجى إدخال بريد إلكتروني صحيح';
              }
              return null;
            },
          ),
        ),
        actions: [
          GlassActionButton(
            text: 'إلغاء',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          GradientButton(
            text: 'إرسال',
            icon: Icons.send_rounded,
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(dialogContext).pop(true);
              }
            },
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final authService = ref.read(authServiceProvider);
        await authService.resetPassword(emailController.text.trim());

        if (mounted) {
          UIHelpers.showSnackBar(
            context,
            'تم إرسال رابط إعادة التعيين إلى بريدك الإلكتروني',
            duration: const Duration(seconds: 4),
          );
        }
      } catch (e) {
        if (mounted) {
          UIHelpers.showSnackBar(
            context,
            errorHandler.getArabicMessage(e),
            isError: true,
            duration: const Duration(seconds: 3),
          );
        }
      }
    }

  }

  // Sign in with Google
  Future<void> _signInWithGoogle() async {
    final logger = AppLoggerService();

    setState(() => _isGoogleLoading = true);

    try {
      logger.info(
        'Starting Google sign in from LoginScreen',
        category: LogCategory.auth,
        tag: 'LoginScreen',
      );

      // Preserve redirect param across OAuth page redirect (web only)
      if (kIsWeb) {
        final redirect = GoRouterState.of(context).uri.queryParameters['redirect'];
        if (redirect != null && redirect.isNotEmpty) {
          // ignore: avoid_web_libraries_in_flutter
          html.window.sessionStorage['post_oauth_redirect'] = redirect;
        }
      }

      final authService = ref.read(authServiceProvider);
      final credential = await authService.signInWithGoogle();

      if (!mounted) return;

      // Cache profile picture for next login screen visit
      _cacheProfilePicture(credential.user);

      // Track login event
      final analytics = ref.read(analyticsServiceProvider);
      analytics.logLogin('google').catchError((e) {
        logger.warning('Analytics logLogin failed: $e', category: LogCategory.analytics, tag: 'LoginScreen');
      });
      if (credential.user != null) {
        analytics.setUserId(credential.user!.id).catchError((e) {
          logger.warning('Analytics setUserId failed: $e', category: LogCategory.analytics, tag: 'LoginScreen');
        });
      }

      logger.info(
        'Google sign in successful, navigating after login',
        category: LogCategory.auth,
        tag: 'LoginScreen',
      );

      _navigateAfterLogin();
    } on AuthException catch (e) {
      if (!mounted) return;

      // For web OAuth, a redirect is expected - don't show error
      if (e.message.contains('OAuth redirect in progress')) {
        // Keep loading state - page will redirect to Google
        return;
      }

      setState(() => _isGoogleLoading = false);

      UIHelpers.showSnackBar(
        context,
        AuthService.getErrorMessage(e.message),
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);

      UIHelpers.showSnackBar(
        context,
        AuthService.getErrorMessage(e.toString()),
        isError: true,
      );
    }
  }

  // Sign in with Apple
  Future<void> _signInWithApple() async {
    final logger = AppLoggerService();

    setState(() => _isAppleLoading = true);

    try {
      logger.info(
        'Starting Apple sign in from LoginScreen',
        category: LogCategory.auth,
        tag: 'LoginScreen',
      );

      // Preserve redirect param across OAuth page redirect (web only)
      if (kIsWeb) {
        final redirect = GoRouterState.of(context).uri.queryParameters['redirect'];
        if (redirect != null && redirect.isNotEmpty) {
          // ignore: avoid_web_libraries_in_flutter
          html.window.sessionStorage['post_oauth_redirect'] = redirect;
        }
      }

      final authService = ref.read(authServiceProvider);
      final credential = await authService.signInWithApple();

      if (!mounted) return;

      // Cache profile picture for next login screen visit
      _cacheProfilePicture(credential.user);

      // Track login event
      final analytics = ref.read(analyticsServiceProvider);
      analytics.logLogin('apple').catchError((e) {
        logger.warning('Analytics logLogin failed: $e', category: LogCategory.analytics, tag: 'LoginScreen');
      });
      if (credential.user != null) {
        analytics.setUserId(credential.user!.id).catchError((e) {
          logger.warning('Analytics setUserId failed: $e', category: LogCategory.analytics, tag: 'LoginScreen');
        });
      }

      logger.info(
        'Apple sign in successful',
        category: LogCategory.auth,
        tag: 'LoginScreen',
      );

      // Check if user needs to set a display name (Apple private relay email)
      if (authService.needsDisplayName) {
        logger.info(
          'User needs display name, showing prompt',
          category: LogCategory.auth,
          tag: 'LoginScreen',
        );

        await NamePromptDialog.show(
          context,
          onSubmit: (name) async {
            await authService.updateDisplayName(name);
          },
        );
      }

      if (!mounted) return;
      _navigateAfterLogin();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isAppleLoading = false);

      UIHelpers.showSnackBar(
        context,
        AuthService.getErrorMessage(e.message),
        isError: true,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAppleLoading = false);

      UIHelpers.showSnackBar(
        context,
        AuthService.getErrorMessage(e.toString()),
        isError: true,
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);

    // GradientBackground OUTSIDE the Scaffold so the gradient + Islamic
    // pattern persist across the full screen — including behind the
    // keyboard when a TextField opens it. Without this, body resize for
    // keyboard inset reveals the Scaffold's default backgroundColor (off-
    // white in light theme) as a strip behind the keyboard. Same pattern
    // ai_chat_screen and the onboarding wizard use.
    return GradientBackground(
      animated: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - (AppSpacing.lg * 2),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      // Logo
                      Container(
                            width: 120,
                            height: 120,
                            constraints: const BoxConstraints(
                              maxWidth: 150,
                              maxHeight: 150,
                            ),
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
                            child: _cachedProfilePictureUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      _cachedProfilePictureUrl!,
                                      fit: BoxFit.cover,
                                      width: 120,
                                      height: 120,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Icon(
                                            Icons.people_alt_rounded,
                                            size: 60,
                                            color: themeColors.textOnGradient,
                                          ),
                                    ),
                                  )
                                : Icon(
                                    Icons.people_alt_rounded,
                                    size: 60,
                                    color: themeColors.textOnGradient,
                                  ),
                          )
                          .animate()
                          .scale(
                            duration: AppAnimations.dramatic,
                            curve: Curves.elasticOut,
                          )

                          .fadeIn(),

                      const SizedBox(height: AppSpacing.lg),

                      // Welcome text
                      Text(
                            'مرحباً بعودتك',
                            style: AppTypography.dramatic.copyWith(
                              color: themeColors.textOnGradient,
                            ),
                          )
                          .animate(delay: AppAnimations.fast)
                          .fadeIn(duration: AppAnimations.dramatic)
                          .slideY(begin: 0.3, end: 0),

                      const SizedBox(height: AppSpacing.sm),

                      Text(
                            'سجّل الدخول للمتابعة',
                            style: AppTypography.bodyLarge.copyWith(
                              color: themeColors.textOnGradient.withValues(alpha: 0.8),
                            ),
                          )
                          .animate(delay: AppAnimations.normal)
                          .fadeIn(duration: AppAnimations.dramatic)
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
                                  keyboardAppearance: Brightness.dark,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: themeColors.textOnGradient,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'البريد الإلكتروني',
                                    labelStyle: AppTypography.bodyMedium.copyWith(
                                      color: themeColors.textOnGradient.withValues(alpha: 0.8),
                                    ),
                                    hintText: 'بريدك الإلكتروني',
                                    hintStyle: AppTypography.bodyMedium.copyWith(
                                      color: themeColors.textOnGradient.withValues(alpha: 0.55),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: themeColors.textOnGradient.withValues(alpha: 0.7),
                                    ),
                                    filled: true,
                                    fillColor: themeColors.textOnGradient.withValues(alpha: 0.15),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusLg,
                                      ),
                                      borderSide: BorderSide(
                                        color: themeColors.textOnGradient.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusLg,
                                      ),
                                      borderSide: BorderSide(
                                        color: themeColors.textOnGradient.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusLg,
                                      ),
                                      borderSide: BorderSide(
                                        color: themeColors.textOnGradient,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'الرجاء إدخال البريد الإلكتروني';
                                    }
                                    // Email regex validation
                                    final emailRegex = RegExp(
                                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                    );
                                    if (!emailRegex.hasMatch(value)) {
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
                                  keyboardAppearance: Brightness.dark,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: themeColors.textOnGradient,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'كلمة المرور',
                                    labelStyle: AppTypography.bodyMedium.copyWith(
                                      color: themeColors.textOnGradient.withValues(alpha: 0.8),
                                    ),
                                    hintText: '••••••••',
                                    hintStyle: AppTypography.bodyMedium.copyWith(
                                      color: themeColors.textOnGradient.withValues(alpha: 0.55),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: themeColors.textOnGradient.withValues(alpha: 0.7),
                                    ),
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
                                    filled: true,
                                    fillColor: themeColors.textOnGradient.withValues(alpha: 0.15),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusLg,
                                      ),
                                      borderSide: BorderSide(
                                        color: themeColors.textOnGradient.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusLg,
                                      ),
                                      borderSide: BorderSide(
                                        color: themeColors.textOnGradient.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusLg,
                                      ),
                                      borderSide: BorderSide(
                                        color: themeColors.textOnGradient,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'الرجاء إدخال كلمة المرور';
                                    }
                                    // Note: Don't validate password rules on login
                                    // Old users may have passwords that don't meet current requirements
                                    // Supabase will validate the actual password
                                    return null;
                                  },
                              ),

                              const SizedBox(height: AppSpacing.sm),

                              // Forgot password & Sign up row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: TextButton(
                                        onPressed: () {
                                          final redirect = GoRouterState.of(context).uri.queryParameters['redirect'];
                                          if (redirect != null && redirect.isNotEmpty) {
                                            context.go('${AppRoutes.signup}?redirect=${Uri.encodeComponent(redirect)}');
                                          } else {
                                            context.go(AppRoutes.signup);
                                          }
                                        },
                                        child: Text(
                                          'إنشاء حساب جديد',
                                          style: AppTypography.labelMedium.copyWith(
                                            color: themeColors.textOnGradient,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ),
                                  ),
                                  Flexible(
                                    child: TextButton(
                                        onPressed: _showForgotPasswordDialog,
                                        child: Text(
                                          'نسيت كلمة المرور؟',
                                          style: AppTypography.labelMedium.copyWith(
                                            color: themeColors.textOnGradient.withValues(alpha: 0.8),
                                          ),
                                        ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: AppSpacing.md),

                              // Login button
                              GradientButton(
                                text: 'تسجيل الدخول',
                                onPressed: _login,
                                isLoading: _isLoading,
                                icon: Icons.login_rounded,
                              ),

                              // Face ID / Biometric button
                              if (_biometricAvailable && _hasSavedCredentials) ...[
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: themeColors.textOnGradient.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                      ),
                                      child: Text(
                                        'أو',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: themeColors.textOnGradient.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: themeColors.textOnGradient.withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                GlassActionButton(
                                  text: 'تسجيل الدخول بـ Face ID',
                                  icon: Icons.face_rounded,
                                  onPressed: _isLoading ? () {} : _authenticateWithBiometrics,
                                ),
                              ],
                            ],
                          ),
                        )
                        .animate(delay: AppAnimations.dramatic)
                        .fadeIn(duration: AppAnimations.slow)
                        .slideY(begin: 0.3, end: 0, curve: AppAnimations.enterCurve),

                    const SizedBox(height: AppSpacing.lg),

                    // Social login section
                    Column(
                      children: [
                        const OrDivider(text: 'أو سجّل / ادخل بـ'),
                        const SizedBox(height: AppSpacing.md),

                        // Google Sign-In button
                        SocialLoginButton(
                            provider: SocialProvider.google,
                            onPressed: _signInWithGoogle,
                            isLoading: _isGoogleLoading,
                        ),

                        // Apple Sign-In button (iOS only)
                        if (!kIsWeb && Platform.isIOS) ...[
                          const SizedBox(height: AppSpacing.sm),
                          SocialLoginButton(
                              provider: SocialProvider.apple,
                              onPressed: _signInWithApple,
                              isLoading: _isAppleLoading,
                          ),
                        ],
                      ],
                    )
                        .animate(delay: AppAnimations.celebration)
                        .fadeIn(duration: AppAnimations.dramatic),

                    const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
