import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_config.dart';
import '../../features/family_tree/providers/family_graph_providers.dart';

/// User context with family group awareness.
///
/// Provides centralized access to userId, familyGroupId, and selfNodeId.
/// All providers that need to distinguish between personal and shared data
/// should depend on this provider.
class UserContext {
  final String userId;
  final String? familyGroupId;
  final String? selfNodeId;

  const UserContext({
    required this.userId,
    this.familyGroupId,
    this.selfNodeId,
  });

  /// Whether the user is in a family group.
  bool get isInGroup => familyGroupId != null;

  @override
  String toString() =>
      'UserContext(userId: $userId, familyGroupId: $familyGroupId, selfNodeId: $selfNodeId, isInGroup: $isInGroup)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserContext &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          familyGroupId == other.familyGroupId &&
          selfNodeId == other.selfNodeId;

  @override
  int get hashCode =>
      userId.hashCode ^ familyGroupId.hashCode ^ selfNodeId.hashCode;
}

/// Central provider for family-aware user context.
///
/// All providers that need to know whether to use personal or shared data
/// should depend on this provider. Returns the current user's ID along with
/// their family group membership info (if any).
///
/// Usage:
/// ```dart
/// final userCtx = ref.watch(userContextProvider).valueOrNull;
/// if (userCtx?.isInGroup == true) {
///   // Use group-aware queries
///   ref.watch(groupRelativesStreamProvider(userCtx!.familyGroupId!));
/// } else {
///   // Use personal queries
///   ref.watch(relativesStreamProvider(userCtx?.userId ?? ''));
/// }
/// ```
final userContextProvider = FutureProvider.autoDispose<UserContext?>((ref) async {
  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) return null;

  // Watch family group info - this will update when membership changes
  final groupInfo = await ref.watch(userFamilyGroupProvider.future);

  return UserContext(
    userId: user.id,
    familyGroupId: groupInfo?.groupId,
    selfNodeId: groupInfo?.nodeId,
  );
});

/// Synchronous provider that returns the cached UserContext.
///
/// Use this when you need synchronous access and can tolerate null during
/// initial load. For most cases, prefer [userContextProvider].
final userContextSyncProvider = Provider.autoDispose<UserContext?>((ref) {
  return ref.watch(userContextProvider).valueOrNull;
});
