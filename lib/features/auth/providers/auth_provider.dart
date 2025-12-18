import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/session_persistence_service.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/errors/app_errors.dart';

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
  try {
    final authService = ref.watch(authServiceProvider);
    return authService.authStateChanges;
  } catch (e) {
    // If auth service fails, return empty stream
    return Stream.value(null);
  }
});

// Current user provider with error handling
final currentUserProvider = Provider<User?>((ref) {
  try {
    final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (user) => user,
      loading: () => null,
      error: (_,_) => null,
    );
  } catch (e) {
    // If provider fails, return null
    return null;
  }
});

// Is authenticated provider with error handling
final isAuthenticatedProvider = Provider<bool>((ref) {
  try {
    final user = ref.watch(currentUserProvider);
    return user != null;
  } catch (e) {
    // If anything fails, assume not authenticated
    return false;
  }
});
