import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';

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
    try {
      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📝 [AuthService.signUpWithEmail] STARTING');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📧 [AuthService] Email: $email');
        print('👤 [AuthService] Full name: $fullName');
        print('🔄 [AuthService] Calling _supabase.auth.signUp()...');
      }

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

      if (kDebugMode) {
        print('✅ [AuthService] signUp() completed in ${duration.inMilliseconds}ms');
        print('📊 [AuthService] Response details:');
        print('   - User object: ${response.user != null ? 'present' : 'NULL'}');
        print('   - User ID: ${response.user?.id ?? '(null)'}');
        print('   - Session object: ${response.session != null ? 'present' : 'NULL'}');
        print('   - Access token: ${response.session?.accessToken != null ? 'present' : '(null)'}');
        print('   - Refresh token: ${response.session?.refreshToken != null ? 'present' : '(null)'}');
      }

      if (response.user == null) {
        if (kDebugMode) {
          print('🔴 [AuthService] CRITICAL: No user returned from signUp()');
        }
        throw AuthException('Sign up failed - no user returned');
      }

      // Check if email confirmation is required
      if (response.session == null) {
        if (kDebugMode) {
          print('⚠️ [AuthService] No session created - email confirmation may be required');
          print('🔴 [AuthService] User created but cannot authenticate without session');
        }
        throw AuthException('يرجى تأكيد بريدك الإلكتروني. تحقق من صندوق الوارد الخاص بك.');
      }

      if (kDebugMode) {
        print('✅ [AuthService] User created successfully: ${response.user?.id}');
        print('✅ [AuthService] Session active - user can authenticate');
        print('✅ [AuthService] User profile auto-created by database trigger');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('✅ [AuthService.signUpWithEmail] SUCCESS');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }

      return response;
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('🔴 [AuthService.signUpWithEmail] AuthException');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('❌ [AuthService] Error message: ${e.message}');
        print('❌ [AuthService] Status code: ${e.statusCode}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('🔴 [AuthService.signUpWithEmail] Unexpected exception');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('❌ [AuthService] Exception type: ${e.runtimeType}');
        print('❌ [AuthService] Exception: $e');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('🔐 [AuthService.signInWithEmail] STARTING');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📧 [AuthService] Email: $email');
        print('🔄 [AuthService] Calling _supabase.auth.signInWithPassword()...');
      }

      final startTime = DateTime.now();

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final duration = DateTime.now().difference(startTime);

      if (kDebugMode) {
        print('✅ [AuthService] signInWithPassword() completed in ${duration.inMilliseconds}ms');
        print('📊 [AuthService] Response details:');
        print('   - User object: ${response.user != null ? 'present' : 'NULL'}');
        print('   - User ID: ${response.user?.id ?? '(null)'}');
        print('   - Session object: ${response.session != null ? 'present' : 'NULL'}');
        print('   - Access token: ${response.session?.accessToken != null ? 'present' : '(null)'}');
        print('   - Refresh token: ${response.session?.refreshToken != null ? 'present' : '(null)'}');
      }

      if (response.user != null) {
        // Update last login asynchronously (don't block login)
        if (kDebugMode) {
          print('🔄 [AuthService] Updating last login timestamp (async)...');
        }
        _updateLastLogin(response.user!.id).catchError((e) {
          if (kDebugMode) {
            print('⚠️ [AuthService] Failed to update last login: $e');
          }
        });
      }

      if (kDebugMode) {
        print('✅ [AuthService] User signed in successfully: ${response.user?.id}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('✅ [AuthService.signInWithEmail] SUCCESS');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }

      return response;
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('🔴 [AuthService.signInWithEmail] AuthException');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('❌ [AuthService] Error message: ${e.message}');
        print('❌ [AuthService] Status code: ${e.statusCode}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('🔴 [AuthService.signInWithEmail] Unexpected exception');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('❌ [AuthService] Exception type: ${e.runtimeType}');
        print('❌ [AuthService] Exception: $e');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      if (kDebugMode) {
        print('✅ User signed out');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Sign out error: $e');
      }
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      if (kDebugMode) {
        print('✅ Password reset email sent to: $email');
      }
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('❌ Password reset error: ${e.message}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected password reset error: $e');
      }
      rethrow;
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      if (kDebugMode) {
        print('🗑️ Deleting user account: ${user.id}');
      }

      // Call RPC function to delete user data and account
      // This triggers cascading deletes for all user data
      await _supabase.rpc('delete_user_account');

      if (kDebugMode) {
        print('✅ User data deleted from database');
      }

      // Sign out (Supabase Auth user deletion is handled by RPC or manually via Admin API)
      await _supabase.auth.signOut();

      if (kDebugMode) {
        print('✅ Account deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Delete account error: $e');
      }
      rethrow;
    }
  }

  // Update last login timestamp
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _supabase.from('users').update({
        'last_login_at': DateTime.now().toIso8601String(),
      }).eq('id', uid);

      if (kDebugMode) {
        print('✅ Last login updated for user: $uid');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to update last login: $e');
      }
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
