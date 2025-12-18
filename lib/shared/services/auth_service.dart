import 'dart:io' show Platform, InternetAddress;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/errors/app_errors.dart';
import '../../core/services/app_logger_service.dart';
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

  // Reset password
  Future<void> resetPassword(String email) async {
    final logger = AppLoggerService();

    try {
      logger.info(
        'Password reset starting',
        category: LogCategory.auth,
        tag: 'resetPassword',
        metadata: {'email': email},
      );
      await _supabase.auth.resetPasswordForEmail(email);
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
