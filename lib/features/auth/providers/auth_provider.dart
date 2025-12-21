import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/session_persistence_service.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/errors/app_errors.dart';
import '../../../core/services/app_logger_service.dart';

// Session persistence service provider
final sessionPersistenceServiceProvider = Provider<SessionPersistenceService>((
  ref,
) {
  return SessionPersistenceService();
});

// Auth service provider with lazy initialization and error handling
final authServiceProvider = Provider<AuthService>((ref) {
  // Check if Supabase is initialized before creating AuthService
  if (!SupabaseConfig.isInitialized) {
    throw const ConfigurationError(
      message: 'Supabase is not initialized. Cannot access authentication services.',
      arabicMessage: 'لم يتم تهيئة الاتصال بالخادم. يرجى إعادة تشغيل التطبيق.',
      component: 'Supabase',
    );
  }

  try {
    return AuthService();
  } catch (e) {
    throw ConfigurationError(
      message: 'AuthService initialization failed: ${e.toString()}',
      arabicMessage: 'فشل تهيئة خدمة المصادقة',
      component: 'AuthService',
      originalError: e,
    );
  }
});

// Session initialization provider
final sessionInitializationProvider = FutureProvider<bool>((ref) async {
  final sessionPersistence = ref.watch(sessionPersistenceServiceProvider);
  await sessionPersistence.initialize();

  final authService = ref.watch(authServiceProvider);
  return await authService.checkPersistentSession();
});

// Auth state provider with error handling
final authStateProvider = StreamProvider<User?>((ref) {
  final logger = AppLoggerService();
  try {
    final authService = ref.watch(authServiceProvider);
    return authService.authStateChanges;
  } catch (e, stackTrace) {
    // Log the error - don't silently swallow auth failures
    logger.error(
      'Auth state provider failed: $e',
      category: LogCategory.auth,
      tag: 'AuthProvider',
      metadata: {'error': e.toString(), 'stackTrace': stackTrace.toString()},
    );
    // Return error stream so UI can show proper error state
    return Stream.error(e, stackTrace);
  }
});

// Current user provider with error handling
final currentUserProvider = Provider<User?>((ref) {
  final logger = AppLoggerService();
  try {
    final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (user) => user,
      loading: () => null,
      error: (error, stackTrace) {
        // Log the error - auth failures should be visible
        logger.error(
          'Current user provider received auth error: $error',
          category: LogCategory.auth,
          tag: 'AuthProvider',
        );
        return null;
      },
    );
  } catch (e) {
    // Log unexpected errors
    logger.error(
      'Current user provider failed: $e',
      category: LogCategory.auth,
      tag: 'AuthProvider',
      metadata: {'error': e.toString()},
    );
    return null;
  }
});

// Is authenticated provider with error handling
final isAuthenticatedProvider = Provider<bool>((ref) {
  final logger = AppLoggerService();
  try {
    final user = ref.watch(currentUserProvider);
    return user != null;
  } catch (e) {
    // Log the error instead of silently assuming not authenticated
    logger.error(
      'Is authenticated provider failed: $e',
      category: LogCategory.auth,
      tag: 'AuthProvider',
    );
    return false;
  }
});
