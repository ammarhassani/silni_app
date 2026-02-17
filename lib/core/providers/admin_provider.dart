import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Fetches the user's role from the profiles table.
final userRoleProvider = FutureProvider<String>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 'user';
  final response = await Supabase.instance.client
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single();
  return (response['role'] as String?) ?? 'user';
});

/// Whether the current user is an admin. Fail-closed: false on any error.
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(userRoleProvider).valueOrNull == 'admin';
});
