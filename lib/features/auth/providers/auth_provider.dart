import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/session_persistence_service.dart';
import '../../../core/config/supabase_config.dart';

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
    throw Exception(
      'Supabase is not initialized. Cannot access authentication services.\n'
      'This usually happens when:\n'
      '1. Supabase credentials are missing or invalid\n'
      '2. Network connection failed during initialization\n'
      '3. Environment variables are not properly configured\n\n'
      'Please check console logs for detailed initialization errors.',
    );
  }

  try {
    return AuthService();
  } catch (e) {
    throw Exception(
      'AuthService initialization failed: ${e.toString()}\n'
      'Make sure SupabaseConfig.initialize() completed successfully.',
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
      error: (_, __) => null,
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
