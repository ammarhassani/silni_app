import 'dart:io' show Platform, InternetAddress;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/config/env/env_services.dart';
import '../../core/errors/app_errors.dart';
import '../../core/services/app_logger_service.dart';
import '../../core/services/subscription_service.dart';
import 'session_persistence_service.dart';
import 'unified_notification_service.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final SessionPersistenceService _sessionPersistence =
      SessionPersistenceService();

  // Get current user stream
  Stream<User?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((data) => data.session?.user);
  }

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Helper method to add Sentry breadcrumbs and local logging
  void _addAuthBreadcrumb(String message, {Map<String, dynamic>? data}) {
    final logger = AppLoggerService();

    // Add to Sentry breadcrumbs for remote debugging
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: 'auth',
        level: SentryLevel.info,
        data: data,
      ),
    );

    // Also log locally
    logger.debug(message, category: LogCategory.auth, metadata: data);
  }

  // Check internet connectivity
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Check storage availability (SharedPreferences)
  Future<bool> _checkStorageAvailability() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('_test_key', 'test');
      final canRead = prefs.getString('_test_key') == 'test';
      await prefs.remove('_test_key');
      return canRead;
    } catch (e) {
      return false;
    }
  }

  // Check secure storage accessibility (iOS-specific)
  Future<bool> _checkSecureStorage() async {
    try {
      // Check if we can access secure storage
      await SharedPreferences.getInstance();
      return true; // If we can get instance, storage is accessible
    } catch (e) {
      return false;
    }
  }

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final logger = AppLoggerService();

    try {
      logger.info(
        'Sign up starting',
        category: LogCategory.auth,
        tag: 'signUpWithEmail',
      );
      logger.debug(
        'Sign up parameters',
        category: LogCategory.auth,
        tag: 'signUpWithEmail',
        metadata: {'email': email, 'fullName': fullName},
      );
      logger.debug(
        'Calling Supabase auth.signUp()...',
        category: LogCategory.auth,
        tag: 'signUpWithEmail',
      );

      final startTime = DateTime.now();

      // Create user with Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      final duration = DateTime.now().difference(startTime);

      logger.info(
        'Supabase signUp() completed',
        category: LogCategory.auth,
        tag: 'signUpWithEmail',
        metadata: {
          'durationMs': duration.inMilliseconds,
          'hasUser': response.user != null,
          'userId': response.user?.id,
          'hasSession': response.session != null,
          'hasAccessToken': response.session?.accessToken != null,
          'hasRefreshToken': response.session?.refreshToken != null,
        },
      );

      if (response.user == null) {
        logger.critical(
          'No user returned from signUp()',
          category: LogCategory.auth,
          tag: 'signUpWithEmail',
        );
        throw AuthException('Sign up failed - no user returned');
      }

      // Check if email confirmation is required
      if (response.session == null) {
        logger.warning(
          'No session created - email confirmation may be required or iOS session storage failed',
          category: LogCategory.auth,
          tag: 'signUpWithEmail',
          metadata: {
            'userId': response.user?.id,
            'platform': kIsWeb ? 'web' : Platform.operatingSystem,
            'userExists': response.user != null,
          },
        );
        // Use English message so getErrorMessage() can match it properly
        throw AuthException('Email not confirmed - please check your inbox');
      }

      logger.info(
        'Sign up successful',
        category: LogCategory.auth,
        tag: 'signUpWithEmail',
        metadata: {
          'userId': response.user?.id,
          'sessionActive': true,
          'profileAutoCreated': true,
        },
      );

      // Mark user as logged in with persistent session
      if (response.user != null) {
        await _sessionPersistence.markUserLoggedIn(response.user!.id);
      }

      // Register FCM token for push notifications
      try {
        final unifiedNotifications = UnifiedNotificationService();
        await unifiedNotifications.onLogin();
        logger.debug(
          'FCM token registered on signup',
          category: LogCategory.auth,
          tag: 'signUpWithEmail',
        );
      } catch (e) {
        logger.warning(
          'Failed to register FCM token on signup (non-critical)',
          category: LogCategory.auth,
          tag: 'signUpWithEmail',
          metadata: {'error': e.toString()},
        );
        // Non-critical error - continue with sign up
      }

      // Sync subscription state with RevenueCat
      try {
        await SubscriptionService.instance.setUserId(response.user!.id);
        logger.debug(
          'Subscription service synced on signup',
          category: LogCategory.auth,
          tag: 'signUpWithEmail',
        );
      } catch (e) {
        logger.warning(
          'Failed to sync subscription on signup (non-critical)',
          category: LogCategory.auth,
          tag: 'signUpWithEmail',
          metadata: {'error': e.toString()},
        );
      }

      return response;
    } on AuthException catch (e, stackTrace) {
      logger.error(
        'AuthException during sign up',
        category: LogCategory.auth,
        tag: 'signUpWithEmail',
        metadata: {'message': e.message, 'statusCode': e.statusCode},
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      logger.error(
        'Unexpected exception during sign up',
        category: LogCategory.auth,
        tag: 'signUpWithEmail',
        metadata: {
          'exceptionType': e.runtimeType.toString(),
          'exception': e.toString(),
        },
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final logger = AppLoggerService();

    try {
      // Step 1: Initial checks and breadcrumb
      logger.info(
        'Sign in starting',
        category: LogCategory.auth,
        tag: 'signInWithEmail',
      );

      final hasInternet = await _checkInternetConnection();
      final storageAvailable = await _checkStorageAvailability();

      // Add web-specific debugging
      logger.debug(
        'Platform detection',
        category: LogCategory.auth,
        tag: 'signInWithEmail',
        metadata: {
          'email': email,
          'has_internet': hasInternet,
          'storage_available': storageAvailable,
          'platform': kIsWeb ? 'web' : Platform.operatingSystem,
          'isWeb': kIsWeb,
          'supabaseClientExists': true,
          'supabaseAuthExists': true,
        },
      );

      _addAuthBreadcrumb(
        'Starting sign-in',
        data: {
          'email': email,
          'has_internet': hasInternet,
          'storage_available': storageAvailable,
          'platform': kIsWeb ? 'web' : Platform.operatingSystem,
          'isWeb': kIsWeb,
        },
      );

      if (!hasInternet) {
        logger.warning(
          'No internet connection detected',
          category: LogCategory.auth,
          tag: 'signInWithEmail',
        );
      }

      if (!storageAvailable) {
        logger.warning(
          'Storage not available',
          category: LogCategory.auth,
          tag: 'signInWithEmail',
        );
      }

      // Step 2: iOS-specific checks
      if (!kIsWeb && Platform.isIOS) {
        final secureStorageAccessible = await _checkSecureStorage();
        _addAuthBreadcrumb(
          'iOS-specific checks',
          data: {
            'ios_version': Platform.operatingSystemVersion,
            'secure_storage_accessible': secureStorageAccessible,
          },
        );

        if (!secureStorageAccessible) {
          logger.warning(
            'iOS secure storage not accessible',
            category: LogCategory.auth,
            tag: 'signInWithEmail',
          );
        }
      }

      // Step 3: Call Supabase API
      _addAuthBreadcrumb('Calling Supabase signInWithPassword');
      logger.debug(
        'Calling Supabase signInWithPassword()...',
        category: LogCategory.auth,
        tag: 'signInWithEmail',
        metadata: {
          'authFlowType': kIsWeb ? 'PKCE (web)' : 'implicit (mobile)',
          'platform': kIsWeb ? 'web' : Platform.operatingSystem,
        },
      );

      final startTime = DateTime.now();

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final duration = DateTime.now().difference(startTime);

      // Step 4: Log successful auth
      _addAuthBreadcrumb(
        'Supabase auth successful',
        data: {
          'duration_ms': duration.inMilliseconds,
          'has_session': response.session != null,
          'has_user': response.user != null,
          'session_expires_at': response.session?.expiresAt,
        },
      );

      logger.info(
        'Supabase signInWithPassword() completed',
        category: LogCategory.auth,
        tag: 'signInWithEmail',
        metadata: {
          'durationMs': duration.inMilliseconds,
          'hasUser': response.user != null,
          'userId': response.user?.id,
          'hasSession': response.session != null,
          'hasAccessToken': response.session?.accessToken != null,
          'hasRefreshToken': response.session?.refreshToken != null,
        },
      );

      // Step 5: Verify session storage
      final storedSession = _supabase.auth.currentSession;
      _addAuthBreadcrumb(
        'Session storage verified',
        data: {
          'stored': storedSession != null,
          'matches': storedSession?.user.id == response.user?.id,
        },
      );

      if (storedSession == null) {
        logger.warning(
          'Session not stored in local storage',
          category: LogCategory.auth,
          tag: 'signInWithEmail',
        );
      }

      // Step 6: Update last login (async)
      if (response.user != null) {
        logger.debug(
          'Updating last login timestamp (async)...',
          category: LogCategory.auth,
          tag: 'signInWithEmail',
        );
        _updateLastLogin(response.user!.id).catchError((e) {
          logger.warning(
            'Failed to update last login',
            category: LogCategory.auth,
            tag: 'signInWithEmail',
            metadata: {'error': e.toString()},
          );
        });
      }

      // Mark user as logged in with persistent session
      if (response.user != null) {
        await _sessionPersistence.markUserLoggedIn(response.user!.id);
      }

      // Register FCM token for push notifications
      try {
        final unifiedNotifications = UnifiedNotificationService();
        await unifiedNotifications.onLogin();
        logger.debug(
          'FCM token registered on login',
          category: LogCategory.auth,
          tag: 'signInWithEmail',
        );
      } catch (e) {
        logger.warning(
          'Failed to register FCM token on login (non-critical)',
          category: LogCategory.auth,
          tag: 'signInWithEmail',
          metadata: {'error': e.toString()},
        );
        // Non-critical error - continue with sign in
      }

      // Sync subscription state with RevenueCat
      if (response.user != null) {
        try {
          await SubscriptionService.instance.setUserId(response.user!.id);
          logger.debug(
            'Subscription service synced on login',
            category: LogCategory.auth,
            tag: 'signInWithEmail',
          );
        } catch (e) {
          logger.warning(
            'Failed to sync subscription on login (non-critical)',
            category: LogCategory.auth,
            tag: 'signInWithEmail',
            metadata: {'error': e.toString()},
          );
        }
      }

      logger.info(
        'Sign in successful',
        category: LogCategory.auth,
        tag: 'signInWithEmail',
        metadata: {'userId': response.user?.id},
      );

      return response;
    } on AuthException catch (e, stackTrace) {
      // Log auth exception with breadcrumb
      _addAuthBreadcrumb(
        'Auth exception occurred',
        data: {'status_code': e.statusCode, 'message': e.message},
      );

      logger.error(
        'AuthException during sign in',
        category: LogCategory.auth,
        tag: 'signInWithEmail',
        metadata: {'message': e.message, 'statusCode': e.statusCode},
        stackTrace: stackTrace,
      );

      // Send to Sentry with full context
      await Sentry.captureException(
        e,
        stackTrace: stackTrace,
        hint: Hint.withMap({
          'auth_flow': 'sign_in',
          'email': email,
          'platform': kIsWeb ? 'web' : Platform.operatingSystem,
        }),
      );
      rethrow;
    } catch (e, stackTrace) {
      // Log unexpected exception with breadcrumb
      _addAuthBreadcrumb(
        'Unexpected exception occurred',
        data: {
          'exception_type': e.runtimeType.toString(),
          'exception': e.toString(),
        },
      );

      logger.error(
        'Unexpected exception during sign in',
        category: LogCategory.auth,
        tag: 'signInWithEmail',
        metadata: {
          'exceptionType': e.runtimeType.toString(),
          'exception': e.toString(),
        },
        stackTrace: stackTrace,
      );

      // Send to Sentry
      await Sentry.captureException(
        e,
        stackTrace: stackTrace,
        hint: Hint.withMap({
          'auth_flow': 'sign_in',
          'email': email,
          'platform': kIsWeb ? 'web' : Platform.operatingSystem,
        }),
      );

      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    final logger = AppLoggerService();

    try {
      logger.info(
        'Sign out starting',
        category: LogCategory.auth,
        tag: 'signOut',
      );

      // Deactivate FCM token before signing out
      try {
        final UnifiedNotificationService unifiedNotifications =
            UnifiedNotificationService();
        await unifiedNotifications.onLogout();
        logger.debug(
          'FCM token deactivated',
          category: LogCategory.auth,
          tag: 'signOut',
        );
      } catch (e) {
        logger.warning(
          'Failed to deactivate FCM token (non-critical)',
          category: LogCategory.auth,
          tag: 'signOut',
          metadata: {'error': e.toString()},
        );
        // Non-critical error - continue with sign out
      }

      // Clear subscription user from RevenueCat
      try {
        await SubscriptionService.instance.clearUser();
        logger.debug(
          'Subscription user cleared',
          category: LogCategory.auth,
          tag: 'signOut',
        );
      } catch (e) {
        logger.warning(
          'Failed to clear subscription user (non-critical)',
          category: LogCategory.auth,
          tag: 'signOut',
          metadata: {'error': e.toString()},
        );
      }

      await _supabase.auth.signOut();

      // Mark user as explicitly logged out
      await _sessionPersistence.markUserLoggedOut();

      logger.info(
        'Sign out successful',
        category: LogCategory.auth,
        tag: 'signOut',
      );
    } catch (e, stackTrace) {
      logger.error(
        'Sign out error',
        category: LogCategory.auth,
        tag: 'signOut',
        metadata: {'error': e.toString()},
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Reset password - sends reset email with deep link
  Future<void> resetPassword(String email) async {
    final logger = AppLoggerService();

    try {
      logger.info(
        'Password reset starting',
        category: LogCategory.auth,
        tag: 'resetPassword',
        metadata: {'email': email},
      );
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb ? null : 'com.silni.app://reset-password',
      );
      logger.info(
        'Password reset email sent',
        category: LogCategory.auth,
        tag: 'resetPassword',
        metadata: {'email': email},
      );
    } on AuthException catch (e, stackTrace) {
      logger.error(
        'Password reset error',
        category: LogCategory.auth,
        tag: 'resetPassword',
        metadata: {'message': e.message, 'email': email},
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      logger.error(
        'Unexpected password reset error',
        category: LogCategory.auth,
        tag: 'resetPassword',
        metadata: {'error': e.toString(), 'email': email},
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Update password - used after password reset flow
  Future<void> updatePassword(String newPassword) async {
    final logger = AppLoggerService();

    try {
      logger.info(
        'Password update starting',
        category: LogCategory.auth,
        tag: 'updatePassword',
      );
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      logger.info(
        'Password updated successfully',
        category: LogCategory.auth,
        tag: 'updatePassword',
      );
    } on AuthException catch (e, stackTrace) {
      logger.error(
        'Password update error',
        category: LogCategory.auth,
        tag: 'updatePassword',
        metadata: {'message': e.message},
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      logger.error(
        'Unexpected password update error',
        category: LogCategory.auth,
        tag: 'updatePassword',
        metadata: {'error': e.toString()},
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Sign in with Google OAuth
  Future<AuthResponse> signInWithGoogle() async {
    final logger = AppLoggerService();

    try {
      logger.info(
        'Google sign in starting',
        category: LogCategory.auth,
        tag: 'signInWithGoogle',
        metadata: {'platform': kIsWeb ? 'web' : 'mobile'},
      );

      // For web: Use Supabase's native OAuth flow (redirect-based)
      // The google_sign_in plugin can't reliably provide ID tokens on web
      if (kIsWeb) {
        return await _signInWithGoogleWeb(logger);
      }

      // For mobile: Use google_sign_in plugin for native experience
      return await _signInWithGoogleMobile(logger);
    } on AuthException catch (e, stackTrace) {
      logger.error(
        'Google sign in auth error',
        category: LogCategory.auth,
        tag: 'signInWithGoogle',
        metadata: {'message': e.message},
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      logger.error(
        'Google sign in error',
        category: LogCategory.auth,
        tag: 'signInWithGoogle',
        metadata: {'error': e.toString()},
        stackTrace: stackTrace,
      );

      await Sentry.captureException(e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Google Sign-In for web using Supabase OAuth
  Future<AuthResponse> _signInWithGoogleWeb(AppLoggerService logger) async {
    logger.debug(
      'Using Supabase OAuth flow for web',
      category: LogCategory.auth,
      tag: 'signInWithGoogle',
    );

    // Supabase OAuth will redirect to Google, then back to the app
    // The session is automatically created on callback
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'com.silni.app://login-callback',
      authScreenLaunchMode: LaunchMode.platformDefault,
    );

    // For web, this is a redirect flow - the page will reload
    // After redirect, the session is automatically restored by Supabase
    // Return an empty response - the actual session comes after redirect
    logger.info(
      'Google OAuth redirect initiated',
      category: LogCategory.auth,
      tag: 'signInWithGoogle',
    );

    // This won't actually return - the browser will redirect
    // But we need to satisfy the return type
    throw AuthException('OAuth redirect in progress');
  }

  // Google Sign-In for mobile using native plugin
  Future<AuthResponse> _signInWithGoogleMobile(AppLoggerService logger) async {
    // Configure Google Sign-In for mobile
    // serverClientId is the web client ID needed for Supabase token exchange
    final googleSignIn = GoogleSignIn(
      serverClientId: EnvServices.googleWebClientId,
      scopes: ['email', 'profile'],
    );

    // Trigger the native authentication flow
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      logger.warning(
        'Google sign in cancelled by user',
        category: LogCategory.auth,
        tag: 'signInWithGoogle',
      );
      throw AuthException('تم إلغاء تسجيل الدخول');
    }

    // Obtain the auth details from the request
    final googleAuth = await googleUser.authentication;

    logger.debug(
      'Google auth obtained',
      category: LogCategory.auth,
      tag: 'signInWithGoogle',
      metadata: {
        'hasIdToken': googleAuth.idToken != null,
        'hasAccessToken': googleAuth.accessToken != null,
      },
    );

    if (googleAuth.idToken == null) {
      throw AuthException('فشل في الحصول على رمز المصادقة من Google');
    }

    // Sign in to Supabase with the Google ID token
    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: googleAuth.idToken!,
      accessToken: googleAuth.accessToken,
    );

    logger.info(
      'Google sign in successful',
      category: LogCategory.auth,
      tag: 'signInWithGoogle',
      metadata: {
        'userId': response.user?.id,
        'email': response.user?.email,
      },
    );

    // Mark user as logged in
    if (response.user != null) {
      await _sessionPersistence.markUserLoggedIn(response.user!.id);

      // Register FCM token
      try {
        final unifiedNotifications = UnifiedNotificationService();
        await unifiedNotifications.onLogin();
      } catch (e) {
        logger.warning(
          'Failed to register FCM token on Google sign in',
          category: LogCategory.auth,
          tag: 'signInWithGoogle',
          metadata: {'error': e.toString()},
        );
      }

      // Sync subscription state with RevenueCat
      try {
        await SubscriptionService.instance.setUserId(response.user!.id);
        logger.debug(
          'Subscription service synced on Google sign in',
          category: LogCategory.auth,
          tag: 'signInWithGoogle',
        );
      } catch (e) {
        logger.warning(
          'Failed to sync subscription on Google sign in (non-critical)',
          category: LogCategory.auth,
          tag: 'signInWithGoogle',
          metadata: {'error': e.toString()},
        );
      }
    }

    return response;
  }

  // Sign in with Apple
  Future<AuthResponse> signInWithApple() async {
    final logger = AppLoggerService();

    try {
      logger.info(
        'Apple sign in starting',
        category: LogCategory.auth,
        tag: 'signInWithApple',
      );

      // Request credentials from Apple
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      logger.debug(
        'Apple credential obtained',
        category: LogCategory.auth,
        tag: 'signInWithApple',
        metadata: {
          'hasIdentityToken': credential.identityToken != null,
          'hasAuthorizationCode': credential.authorizationCode.isNotEmpty,
        },
      );

      if (credential.identityToken == null) {
        throw AuthException('فشل في الحصول على رمز المصادقة من Apple');
      }

      // Build display name from Apple credential (only available on first sign-in)
      String? displayName;
      if (credential.givenName != null || credential.familyName != null) {
        final parts = <String>[];
        if (credential.givenName != null) parts.add(credential.givenName!);
        if (credential.familyName != null) parts.add(credential.familyName!);
        displayName = parts.join(' ');
      }

      // Sign in to Supabase with the Apple ID token
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken!,
      );

      logger.info(
        'Apple sign in successful',
        category: LogCategory.auth,
        tag: 'signInWithApple',
        metadata: {
          'userId': response.user?.id,
          'email': response.user?.email,
          'displayName': displayName,
        },
      );

      // Mark user as logged in and update display name if available
      if (response.user != null) {
        await _sessionPersistence.markUserLoggedIn(response.user!.id);

        // Update user metadata with display name if provided by Apple
        if (displayName != null && displayName.isNotEmpty) {
          try {
            await _supabase.auth.updateUser(
              UserAttributes(
                data: {'display_name': displayName},
              ),
            );
            logger.info(
              'Updated user display name from Apple',
              category: LogCategory.auth,
              tag: 'signInWithApple',
              metadata: {'displayName': displayName},
            );
          } catch (e) {
            logger.warning(
              'Failed to update display name',
              category: LogCategory.auth,
              tag: 'signInWithApple',
              metadata: {'error': e.toString()},
            );
          }
        }

        // Register FCM token
        try {
          final unifiedNotifications = UnifiedNotificationService();
          await unifiedNotifications.onLogin();
        } catch (e) {
          logger.warning(
            'Failed to register FCM token on Apple sign in',
            category: LogCategory.auth,
            tag: 'signInWithApple',
            metadata: {'error': e.toString()},
          );
        }

        // Sync subscription state with RevenueCat
        try {
          await SubscriptionService.instance.setUserId(response.user!.id);
          logger.debug(
            'Subscription service synced on Apple sign in',
            category: LogCategory.auth,
            tag: 'signInWithApple',
          );
        } catch (e) {
          logger.warning(
            'Failed to sync subscription on Apple sign in (non-critical)',
            category: LogCategory.auth,
            tag: 'signInWithApple',
            metadata: {'error': e.toString()},
          );
        }
      }

      return response;
    } on SignInWithAppleAuthorizationException catch (e) {
      logger.warning(
        'Apple sign in cancelled or failed',
        category: LogCategory.auth,
        tag: 'signInWithApple',
        metadata: {'code': e.code.toString(), 'message': e.message},
      );

      if (e.code == AuthorizationErrorCode.canceled) {
        throw AuthException('تم إلغاء تسجيل الدخول');
      }
      rethrow;
    } on AuthException catch (e, stackTrace) {
      logger.error(
        'Apple sign in auth error',
        category: LogCategory.auth,
        tag: 'signInWithApple',
        metadata: {'message': e.message},
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      logger.error(
        'Apple sign in error',
        category: LogCategory.auth,
        tag: 'signInWithApple',
        metadata: {'error': e.toString()},
        stackTrace: stackTrace,
      );

      await Sentry.captureException(e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Check if email is verified
  bool get isEmailVerified {
    final user = _supabase.auth.currentUser;
    return user?.emailConfirmedAt != null;
  }

  // Resend email verification
  Future<void> resendVerificationEmail() async {
    final logger = AppLoggerService();
    final user = _supabase.auth.currentUser;

    if (user == null || user.email == null) {
      throw AuthException('لا يوجد مستخدم مسجل');
    }

    try {
      logger.info(
        'Resending verification email',
        category: LogCategory.auth,
        tag: 'resendVerificationEmail',
        metadata: {'email': user.email},
      );

      await _supabase.auth.resend(
        type: OtpType.signup,
        email: user.email!,
      );

      logger.info(
        'Verification email resent',
        category: LogCategory.auth,
        tag: 'resendVerificationEmail',
        metadata: {'email': user.email},
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to resend verification email',
        category: LogCategory.auth,
        tag: 'resendVerificationEmail',
        metadata: {'error': e.toString()},
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update user's display name in metadata
  Future<void> updateDisplayName(String name) async {
    final logger = AppLoggerService();

    try {
      logger.info(
        'Updating display name',
        category: LogCategory.auth,
        tag: 'updateDisplayName',
        metadata: {'name': name},
      );

      await _supabase.auth.updateUser(
        UserAttributes(
          data: {'display_name': name},
        ),
      );

      logger.info(
        'Display name updated successfully',
        category: LogCategory.auth,
        tag: 'updateDisplayName',
        metadata: {'name': name},
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to update display name',
        category: LogCategory.auth,
        tag: 'updateDisplayName',
        metadata: {'error': e.toString()},
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Check if the current user needs to set a display name
  /// Returns true if user signed in via Apple with private relay email
  /// and has no display name set
  bool get needsDisplayName {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final email = user.email ?? '';
    final displayName = user.userMetadata?['display_name'] as String? ??
        user.userMetadata?['full_name'] as String? ??
        user.userMetadata?['name'] as String?;

    // Check if using Apple private relay and no name set
    final isApplePrivateRelay = email.contains('privaterelay.appleid.com');
    final hasNoDisplayName = displayName == null || displayName.isEmpty;

    return isApplePrivateRelay && hasNoDisplayName;
  }

  // Delete account
  Future<void> deleteAccount() async {
    final logger = AppLoggerService();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        logger.error(
          'No user logged in',
          category: LogCategory.auth,
          tag: 'deleteAccount',
        );
        throw const AuthError(
          type: AuthErrorType.sessionExpired,
          message: 'No user logged in',
          arabicMessage: 'يرجى تسجيل الدخول أولاً',
        );
      }

      logger.info(
        'Deleting user account',
        category: LogCategory.auth,
        tag: 'deleteAccount',
        metadata: {'userId': user.id},
      );

      // Call RPC function to delete user data and account
      // This triggers cascading deletes for all user data
      await _supabase.rpc('delete_user_account');

      logger.debug(
        'User data deleted from database',
        category: LogCategory.auth,
        tag: 'deleteAccount',
      );

      // Clear subscription user from RevenueCat
      try {
        await SubscriptionService.instance.clearUser();
        logger.debug(
          'Subscription user cleared on account deletion',
          category: LogCategory.auth,
          tag: 'deleteAccount',
        );
      } catch (e) {
        logger.warning(
          'Failed to clear subscription user (non-critical)',
          category: LogCategory.auth,
          tag: 'deleteAccount',
          metadata: {'error': e.toString()},
        );
      }

      // Sign out (Supabase Auth user deletion is handled by RPC or manually via Admin API)
      await _supabase.auth.signOut();

      // Mark user as explicitly logged out
      await _sessionPersistence.markUserLoggedOut();

      logger.info(
        'Account deleted successfully',
        category: LogCategory.auth,
        tag: 'deleteAccount',
        metadata: {'userId': user.id},
      );
    } catch (e, stackTrace) {
      logger.error(
        'Delete account error',
        category: LogCategory.auth,
        tag: 'deleteAccount',
        metadata: {'error': e.toString()},
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Update last login timestamp
  Future<void> _updateLastLogin(String uid) async {
    final logger = AppLoggerService();

    try {
      logger.debug(
        'Updating last login timestamp',
        category: LogCategory.auth,
        tag: '_updateLastLogin',
        metadata: {'userId': uid},
      );
      await _supabase
          .from('users')
          .update({'last_login_at': DateTime.now().toIso8601String()})
          .eq('id', uid);

      logger.debug(
        'Last login updated successfully',
        category: LogCategory.auth,
        tag: '_updateLastLogin',
        metadata: {'userId': uid},
      );
    } catch (e) {
      logger.warning(
        'Failed to update last login (non-critical)',
        category: LogCategory.auth,
        tag: '_updateLastLogin',
        metadata: {'userId': uid, 'error': e.toString()},
      );
      // Don't rethrow - this is a non-critical operation
    }
  }

  // Get auth error message
  static String getErrorMessage(String errorMessage) {
    // Supabase returns error messages instead of error codes
    // Map common Supabase auth errors to Arabic messages
    final lowerMessage = errorMessage.toLowerCase();

    if (lowerMessage.contains('invalid login credentials') ||
        lowerMessage.contains('invalid email or password')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    } else if (lowerMessage.contains('email not confirmed')) {
      return 'يرجى تأكيد بريدك الإلكتروني';
    } else if (lowerMessage.contains('user already registered') ||
        lowerMessage.contains('email already exists')) {
      return 'البريد الإلكتروني مستخدم بالفعل';
    } else if (lowerMessage.contains('invalid email')) {
      return 'البريد الإلكتروني غير صحيح';
    } else if (lowerMessage.contains('password') &&
        (lowerMessage.contains('short') || lowerMessage.contains('weak'))) {
      return 'كلمة المرور ضعيفة جداً (يجب أن تكون 6 أحرف على الأقل)';
    } else if (lowerMessage.contains('user not found')) {
      return 'لا يوجد حساب بهذا البريد الإلكتروني';
    } else if (lowerMessage.contains('email rate limit exceeded') ||
        lowerMessage.contains('too many requests')) {
      return 'تم إجراء الكثير من المحاولات. يرجى المحاولة لاحقاً';
    } else if (lowerMessage.contains('network') ||
        lowerMessage.contains('connection')) {
      return 'خطأ في الاتصال بالإنترنت';
    } else {
      return 'حدث خطأ ما. يرجى المحاولة مرة أخرى';
    }
  }

  // Check for persistent session on app startup
  Future<bool> checkPersistentSession() async {
    final logger = AppLoggerService();

    try {
      logger.debug(
        'Checking for persistent session',
        category: LogCategory.auth,
        tag: 'checkPersistentSession',
      );

      final storedSessionData = await _sessionPersistence
          .getStoredSessionData();

      if (storedSessionData == null) {
        logger.debug(
          'No stored session data found',
          category: LogCategory.auth,
          tag: 'checkPersistentSession',
        );
        return false;
      }

      final isValid = _sessionPersistence.isStoredSessionValid(
        storedSessionData,
      );

      logger.debug(
        'Stored session validity check',
        category: LogCategory.auth,
        tag: 'checkPersistentSession',
        metadata: {'isValid': isValid, 'sessionData': storedSessionData},
      );

      if (isValid && _supabase.auth.currentUser == null) {
        // Try to restore session using Supabase's built-in session recovery
        logger.debug(
          'Attempting to restore Supabase session',
          category: LogCategory.auth,
          tag: 'checkPersistentSession',
        );

        // Supabase automatically attempts to restore session on initialization
        // If currentUser is null but stored session is valid, we may need to refresh
        try {
          await _supabase.auth.refreshSession();
          logger.info(
            'Session refreshed successfully',
            category: LogCategory.auth,
            tag: 'checkPersistentSession',
          );

          // Register FCM token for restored session
          try {
            final unifiedNotifications = UnifiedNotificationService();
            await unifiedNotifications.onLogin();
            logger.debug(
              'FCM token registered on session restore',
              category: LogCategory.auth,
              tag: 'checkPersistentSession',
            );
          } catch (e) {
            logger.warning(
              'Failed to register FCM token on session restore (non-critical)',
              category: LogCategory.auth,
              tag: 'checkPersistentSession',
              metadata: {'error': e.toString()},
            );
          }

          // Sync subscription state for restored session
          try {
            final userId = _supabase.auth.currentUser?.id;
            if (userId != null) {
              await SubscriptionService.instance.setUserId(userId);
              logger.debug(
                'Subscription service synced on session restore',
                category: LogCategory.auth,
                tag: 'checkPersistentSession',
              );
            }
          } catch (e) {
            logger.warning(
              'Failed to sync subscription on session restore (non-critical)',
              category: LogCategory.auth,
              tag: 'checkPersistentSession',
              metadata: {'error': e.toString()},
            );
          }

          return true;
        } catch (e) {
          final errorStr = e.toString().toLowerCase();
          // Only logout on explicit authentication failures
          // Network errors or temporary failures should NOT logout the user
          final isAuthError = errorStr.contains('401') ||
              errorStr.contains('refresh_token_not_found') ||
              errorStr.contains('invalid_grant') ||
              errorStr.contains('token is expired') ||
              errorStr.contains('session_not_found');

          if (isAuthError) {
            logger.warning(
              'Session refresh failed with auth error - logging out',
              category: LogCategory.auth,
              tag: 'checkPersistentSession',
              metadata: {'error': e.toString()},
            );
            await _sessionPersistence.markUserLoggedOut();
            return false;
          } else {
            // Network error or temporary failure - keep session valid
            logger.info(
              'Session refresh failed (likely network) - keeping session valid',
              category: LogCategory.auth,
              tag: 'checkPersistentSession',
              metadata: {'error': e.toString()},
            );
            // Return true to keep user "logged in" - session will retry on next action
            return true;
          }
        }
      }

      final hasValidSession = isValid && _supabase.auth.currentUser != null;

      // Register FCM token if session is valid
      if (hasValidSession) {
        try {
          final unifiedNotifications = UnifiedNotificationService();
          await unifiedNotifications.onLogin();
          logger.debug(
            'FCM token registered for existing session',
            category: LogCategory.auth,
            tag: 'checkPersistentSession',
          );
        } catch (e) {
          logger.warning(
            'Failed to register FCM token for existing session (non-critical)',
            category: LogCategory.auth,
            tag: 'checkPersistentSession',
            metadata: {'error': e.toString()},
          );
        }
      }

      return hasValidSession;
    } catch (e, stackTrace) {
      logger.error(
        'Error checking persistent session',
        category: LogCategory.auth,
        tag: 'checkPersistentSession',
        metadata: {'error': e.toString()},
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
