import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/services/app_logger_service.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Get current user stream
  Stream<User?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((data) => data.session?.user);
  }

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final logger = AppLoggerService();

    try {
      logger.info('Sign up starting', category: LogCategory.auth, tag: 'signUpWithEmail');
      logger.debug(
        'Sign up parameters',
        category: LogCategory.auth,
        tag: 'signUpWithEmail',
        metadata: {
          'email': email,
          'fullName': fullName,
        },
      );
      logger.debug('Calling Supabase auth.signUp()...', category: LogCategory.auth, tag: 'signUpWithEmail');

      final startTime = DateTime.now();

      // Create user with Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
        },
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
        logger.critical('No user returned from signUp()', category: LogCategory.auth, tag: 'signUpWithEmail');
        throw AuthException('Sign up failed - no user returned');
      }

      // Check if email confirmation is required
      if (response.session == null) {
        logger.warning(
          'No session created - email confirmation required',
          category: LogCategory.auth,
          tag: 'signUpWithEmail',
          metadata: {'userId': response.user?.id},
        );
        throw AuthException('يرجى تأكيد بريدك الإلكتروني. تحقق من صندوق الوارد الخاص بك.');
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

      return response;
    } on AuthException catch (e, stackTrace) {
      logger.error(
        'AuthException during sign up',
        category: LogCategory.auth,
        tag: 'signUpWithEmail',
        metadata: {
          'message': e.message,
          'statusCode': e.statusCode,
        },
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
      logger.info('Sign in starting', category: LogCategory.auth, tag: 'signInWithEmail');
      logger.debug(
        'Sign in parameters',
        category: LogCategory.auth,
        tag: 'signInWithEmail',
        metadata: {'email': email},
      );
      logger.debug('Calling Supabase signInWithPassword()...', category: LogCategory.auth, tag: 'signInWithEmail');

      final startTime = DateTime.now();

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final duration = DateTime.now().difference(startTime);

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

      if (response.user != null) {
        // Update last login asynchronously (don't block login)
        logger.debug('Updating last login timestamp (async)...', category: LogCategory.auth, tag: 'signInWithEmail');
        _updateLastLogin(response.user!.id).catchError((e) {
          logger.warning(
            'Failed to update last login',
            category: LogCategory.auth,
            tag: 'signInWithEmail',
            metadata: {'error': e.toString()},
          );
        });
      }

      logger.info(
        'Sign in successful',
        category: LogCategory.auth,
        tag: 'signInWithEmail',
        metadata: {'userId': response.user?.id},
      );

      return response;
    } on AuthException catch (e, stackTrace) {
      logger.error(
        'AuthException during sign in',
        category: LogCategory.auth,
        tag: 'signInWithEmail',
        metadata: {
          'message': e.message,
          'statusCode': e.statusCode,
        },
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
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
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    final logger = AppLoggerService();

    try {
      logger.info('Sign out starting', category: LogCategory.auth, tag: 'signOut');
      await _supabase.auth.signOut();
      logger.info('Sign out successful', category: LogCategory.auth, tag: 'signOut');
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
      logger.info('Password reset starting', category: LogCategory.auth, tag: 'resetPassword', metadata: {'email': email});
      await _supabase.auth.resetPasswordForEmail(email);
      logger.info('Password reset email sent', category: LogCategory.auth, tag: 'resetPassword', metadata: {'email': email});
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
        logger.error('No user logged in', category: LogCategory.auth, tag: 'deleteAccount');
        throw Exception('No user logged in');
      }

      logger.info('Deleting user account', category: LogCategory.auth, tag: 'deleteAccount', metadata: {'userId': user.id});

      // Call RPC function to delete user data and account
      // This triggers cascading deletes for all user data
      await _supabase.rpc('delete_user_account');

      logger.debug('User data deleted from database', category: LogCategory.auth, tag: 'deleteAccount');

      // Sign out (Supabase Auth user deletion is handled by RPC or manually via Admin API)
      await _supabase.auth.signOut();

      logger.info('Account deleted successfully', category: LogCategory.auth, tag: 'deleteAccount', metadata: {'userId': user.id});
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
      logger.debug('Updating last login timestamp', category: LogCategory.auth, tag: '_updateLastLogin', metadata: {'userId': uid});
      await _supabase.from('users').update({
        'last_login_at': DateTime.now().toIso8601String(),
      }).eq('id', uid);

      logger.debug('Last login updated successfully', category: LogCategory.auth, tag: '_updateLastLogin', metadata: {'userId': uid});
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
}
