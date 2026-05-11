import '../../../core/config/supabase_config.dart';
import '../models/family_group_model.dart';

/// Static service for family group CRUD operations.
///
/// Follows the project convention of private constructor + static methods.
/// Wraps Supabase calls for creating, joining, and managing family groups.
class FamilyGroupService {
  FamilyGroupService._();

  // ---------------------------------------------------------------------------
  // Group management
  // ---------------------------------------------------------------------------

  /// Create a new family group and add the creator as admin.
  ///
  /// Uses the `create_group_atomic` SECURITY DEFINER RPC to perform both
  /// the group INSERT and the admin membership INSERT in a single transaction.
  /// Returns the newly created [FamilyGroup] with its generated invite code.
  static Future<FamilyGroup> createGroup({
    required String name,
    required String userId,
  }) async {
    final client = SupabaseConfig.client;

    final result = await client.rpc('create_group_atomic', params: {
      'p_name': name,
      'p_user_id': userId,
    });

    if (result == null) {
      throw Exception('Failed to create group');
    }

    final groupData = result is Map<String, dynamic>
        ? result
        : (result as Map).cast<String, dynamic>();

    return FamilyGroup.fromJson(groupData);
  }

  /// Web domain used for shareable invite links.
  ///
  /// The Flutter web app is deployed here and serves as a fallback
  /// for users who don't have the app installed.
  static const webDomain = 'silniapp.com';

  /// Generate a shareable invite deep link for a group.
  ///
  /// Uses an HTTPS link so it works in browsers for users without the app.
  /// For users with the app, universal links / App Links intercept the URL.
  static String generateInviteLink(String inviteCode) {
    return 'https://$webDomain/join/$inviteCode';
  }

  /// Update the name of a family group.
  static Future<void> updateGroupName({
    required String groupId,
    required String name,
  }) async {
    await SupabaseConfig.client
        .from('family_groups')
        .update({'name': name})
        .eq('id', groupId);
  }

  /// Validate an invite code and return the group it belongs to.
  /// **Does NOT create a family_group_members row** — that happens
  /// atomically inside approve_node_claim when an admin confirms the
  /// joiner's identity-claim. Callers should follow this with a
  /// navigation into the identity-claim wizard.
  static Future<FamilyGroup> acceptInvite({
    required String inviteCode,
  }) async {
    final client = SupabaseConfig.client;
    final groupData = await client.rpc(
      'join_group_by_invite_code',
      params: {'code': inviteCode},
    );
    final results = groupData is List<dynamic>
        ? groupData
        : (groupData != null ? [groupData] : <dynamic>[]);
    if (results.isEmpty) {
      throw Exception('رمز الدعوة غير صالح');
    }
    return FamilyGroup.fromJson(results.first as Map<String, dynamic>);
  }

  @Deprecated('Use acceptInvite. joinGroup created a phantom membership row '
              'before identity was verified — fixed 2026-05-11.')
  static Future<FamilyGroup> joinGroup({
    required String inviteCode,
    required String userId,
  }) => acceptInvite(inviteCode: inviteCode);

  // ---------------------------------------------------------------------------
  // Query methods
  // ---------------------------------------------------------------------------

  /// Get all groups the user belongs to.
  ///
  /// Queries through the members table to ensure only the user's groups are
  /// returned, regardless of RLS configuration.
  static Future<List<FamilyGroup>> getUserGroups(String userId) async {
    final client = SupabaseConfig.client;
    final data = await client
        .from('family_group_members')
        .select('family_groups(*)')
        .eq('user_id', userId)
        .order('joined_at', ascending: false);

    return data
        .where((row) => row['family_groups'] != null)
        .map((row) =>
            FamilyGroup.fromJson(row['family_groups'] as Map<String, dynamic>))
        .toList();
  }

  /// Get members of a specific group with display names.
  ///
  /// Does two queries: one for members, one for linked relatives' names.
  /// No FK exists between family_group_members.relative_id_in_tree and
  /// relatives.id, so a manual join is needed.
  static Future<List<FamilyGroupMember>> getGroupMembers(
    String groupId,
  ) async {
    final client = SupabaseConfig.client;

    // 1. Get all members
    final membersData = await client
        .from('family_group_members')
        .select()
        .eq('group_id', groupId)
        .order('joined_at', ascending: true);

    final members = membersData
        .map((json) => FamilyGroupMember.fromJson(json))
        .toList();

    // 2. Batch-fetch display names for members with relative_id_in_tree
    final relativeIds = members
        .where((m) => m.relativeIdInTree != null)
        .map((m) => m.relativeIdInTree!)
        .toList();

    if (relativeIds.isEmpty) return members;

    final relativesData = await client
        .from('relatives')
        .select('id, full_name')
        .inFilter('id', relativeIds);

    final nameMap = <String, String>{
      for (final r in relativesData)
        r['id'] as String: r['full_name'] as String,
    };

    // 3. Merge names into members
    return members.map((m) {
      final name = m.relativeIdInTree != null
          ? nameMap[m.relativeIdInTree]
          : null;
      return name != null
          ? FamilyGroupMember(
              id: m.id,
              groupId: m.groupId,
              userId: m.userId,
              relativeIdInTree: m.relativeIdInTree,
              role: m.role,
              joinedAt: m.joinedAt,
              displayName: name,
            )
          : m;
    }).toList();
  }

  /// Look up a group by its invite code without joining.
  ///
  /// Uses a SECURITY DEFINER function to bypass RLS for invite code lookup.
  /// Returns `null` if no group with the given code exists.
  static Future<FamilyGroup?> lookupGroupByInviteCode(
    String inviteCode,
  ) async {
    final client = SupabaseConfig.client;
    final data = await client
        .rpc('lookup_group_by_invite_code', params: {'code': inviteCode});

    final results = data is List<dynamic>
        ? data
        : (data != null ? [data] : <dynamic>[]);
    if (results.isEmpty) return null;
    return FamilyGroup.fromJson(results.first as Map<String, dynamic>);
  }

  /// Check if a user is already a member of a group.
  static Future<bool> isMember({
    required String groupId,
    required String userId,
  }) async {
    final client = SupabaseConfig.client;
    final data = await client
        .from('family_group_members')
        .select('id')
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .maybeSingle();

    return data != null;
  }

  // ---------------------------------------------------------------------------
  // Member management
  // ---------------------------------------------------------------------------

  /// Leave a group atomically.
  ///
  /// Uses the `leave_group_atomic` SECURITY DEFINER RPC to perform all steps
  /// in a single transaction:
  /// 1. If the leaver is the only admin, promotes the oldest remaining member.
  /// 2. Cleans up the user's self-node (deletes if joiner-created, unmarks if claimed).
  /// 3. Removes the membership row.
  /// 4. If no members remain, deletes the ghost group.
  ///
  /// Idempotent: calling when not a member is a no-op.
  static Future<void> leaveGroup({
    required String groupId,
    required String userId,
  }) async {
    await SupabaseConfig.client.rpc('leave_group_atomic', params: {
      'p_group_id': groupId,
      'p_user_id': userId,
    });
  }

  /// Rotate the invite code for a group (admin only).
  ///
  /// Calls the SECURITY DEFINER RPC which verifies admin role and generates
  /// a new random code, invalidating the old one.
  static Future<String> rotateInviteCode(String groupId) async {
    final result = await SupabaseConfig.client
        .rpc('rotate_invite_code', params: {'target_group_id': groupId});
    if (result is! String) {
      throw Exception('Failed to rotate invite code');
    }
    return result;
  }

  /// Remove a member from a group (admin action).
  ///
  /// Uses the `remove_member_atomic` SECURITY DEFINER RPC to verify the
  /// caller is admin, clean up self-nodes, and remove membership — all in
  /// a single transaction to prevent partial state.
  static Future<void> removeMember({
    required String groupId,
    required String memberId,
  }) async {
    await SupabaseConfig.client.rpc('remove_member_atomic', params: {
      'p_group_id': groupId,
      'p_member_id': memberId,
    });
  }

  /// Transfer admin role to another member.
  ///
  /// Uses the `transfer_admin_atomic` SECURITY DEFINER RPC to verify the
  /// caller is admin, verify the target exists, promote the target, and demote
  /// the caller — all in a single transaction to prevent zero-admin state.
  static Future<void> transferAdmin({
    required String groupId,
    required String currentUserId,
    required String newAdminMemberId,
  }) async {
    final client = SupabaseConfig.client;

    await client.rpc('transfer_admin_atomic', params: {
      'p_group_id': groupId,
      'p_current_user_id': currentUserId,
      'p_new_admin_member_id': newAdminMemberId,
    });
  }

  /// Delete a group (admin only — enforced by RLS).
  static Future<void> deleteGroup(String groupId) async {
    await SupabaseConfig.client
        .from('family_groups')
        .delete()
        .eq('id', groupId);
  }
}
