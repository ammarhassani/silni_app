import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../core/config/supabase_config.dart';
import '../../../shared/models/relative_model.dart';
import '../../relatives/services/relationship_inference_service.dart';
import '../models/family_group_model.dart';
import 'family_sharing_service.dart';

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

  /// Join a group by invite code.
  ///
  /// Uses the `join_group_by_invite_code` SECURITY DEFINER RPC to validate
  /// the invite code and insert membership atomically. Then resolves the
  /// tree node (via [relativeIdInTree], name auto-match, or new self-node)
  /// and updates the membership row.
  ///
  /// This ordering is critical: membership must exist BEFORE creating/claiming
  /// a tree node, because RLS on `relatives` requires group membership.
  ///
  /// Throws if the invite code is invalid.
  static Future<FamilyGroup> joinGroup({
    required String inviteCode,
    required String userId,
    String? relativeIdInTree,
    String? joinerDisplayName,
  }) async {
    final client = SupabaseConfig.client;

    // Step 1: Validate invite code + insert membership via SECURITY DEFINER RPC.
    // The RPC inserts membership with relative_id_in_tree = NULL.
    // If already a member, it returns the group without re-inserting.
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
    final group =
        FamilyGroup.fromJson(results.first as Map<String, dynamic>);

    // Step 2: Check if membership already had a tree node (re-join / already member)
    final membership = await client
        .from('family_group_members')
        .select('id, relative_id_in_tree')
        .eq('group_id', group.id)
        .eq('user_id', userId)
        .maybeSingle();

    if (membership == null) return group; // Should not happen after RPC

    final existingNodeId = membership['relative_id_in_tree'] as String?;
    if (existingNodeId != null) {
      // Already has a node — just re-verify edges
      try {
        await FamilySharingService.verifySharedEdges(groupId: group.id);
      } catch (e) {
        debugPrint('Edge verification failed (existing node): $e');
      }
      return group;
    }

    // Step 3: Resolve tree node (membership exists now, so RLS allows writes)
    String? nodeId = relativeIdInTree;

    // Validate rid if provided: must belong to this group and not be claimed
    if (nodeId != null) {
      final ridRelative = await client
          .from('relatives')
          .select('id, family_group_id')
          .eq('id', nodeId)
          .eq('family_group_id', group.id)
          .maybeSingle();

      if (ridRelative == null) {
        nodeId = null; // Invalid rid — fall through to auto-match
      } else {
        // Check if already claimed by another member
        final claimedBy = await client
            .from('family_group_members')
            .select('id')
            .eq('group_id', group.id)
            .eq('relative_id_in_tree', nodeId)
            .maybeSingle();
        if (claimedBy != null) {
          nodeId = null; // Already claimed — fall through
        }
      }
    }

    if (nodeId == null && relativeIdInTree == null) {
      // Try to auto-match by display name (only when no rid was provided)
      final displayName = joinerDisplayName ??
          client.auth.currentUser?.userMetadata?['full_name'] as String?;

      if (displayName != null && displayName.isNotEmpty) {
        // Look for an unclaimed, non-self relative with matching name
        final claimedIds = await client
            .from('family_group_members')
            .select('relative_id_in_tree')
            .eq('group_id', group.id)
            .not('relative_id_in_tree', 'is', null);

        final excludeIds = claimedIds
            .map((m) => m['relative_id_in_tree'] as String)
            .toList();

        var query = client
            .from('relatives')
            .select('id')
            .eq('family_group_id', group.id)
            .eq('is_archived', false)
            .eq('is_self', false)
            .ilike('full_name', displayName);

        if (excludeIds.isNotEmpty) {
          query = query.not('id', 'in', '(${excludeIds.join(",")})');
        }

        final matchingRelative =
            await query.limit(1).maybeSingle();

        if (matchingRelative != null) {
          nodeId = matchingRelative['id'] as String;
        }
      }
    }

    // If still no node, create a self-node for the joiner
    nodeId ??= await _createJoinerSelfNode(
      userId: userId,
      groupId: group.id,
      displayName: joinerDisplayName,
    );

    // Claim the node atomically via SECURITY DEFINER RPC.
    // This sets is_self=true and links membership → node in one call,
    // bypassing RLS (joiners don't own the node the admin created).
    await client.rpc('claim_tree_node', params: {
      'p_group_id': group.id,
      'p_node_id': nodeId,
    });

    // Step 5: Verify and fill any missing edges in the shared graph
    try {
      await FamilySharingService.verifySharedEdges(groupId: group.id);
    } catch (e) {
      // Best-effort — don't fail the join if edge verification fails.
      debugPrint('Edge verification failed (post-join): $e');
    }

    // Fire-and-forget join notification to existing members
    _sendJoinNotification(
      groupId: group.id,
      newUserId: userId,
      familyName: group.name,
    );

    return group;
  }

  /// Create a self-node for a joiner who doesn't have a matching relative.
  static Future<String> _createJoinerSelfNode({
    required String userId,
    required String groupId,
    String? displayName,
  }) async {
    final client = SupabaseConfig.client;
    final user = client.auth.currentUser;
    final name = displayName ??
        user?.userMetadata?['full_name'] as String? ??
        'عضو جديد';

    // Infer gender using dictionary + AI fallback
    var inferredGender = RelationshipInferenceService.inferGender(name);
    inferredGender ??= await RelationshipInferenceService.inferGenderWithAI(name);
    final gender = inferredGender?.value ?? 'male';
    final avatarType = inferredGender == Gender.female ? 'adult_woman' : 'adult_man';

    final nodeId = const Uuid().v4();
    await client.from('relatives').insert({
      'id': nodeId,
      'user_id': userId,
      'full_name': name,
      'relationship_type': 'other',
      'gender': gender,
      'priority': 1,
      'avatar_type': avatarType,
      'is_self': true,
      'family_group_id': groupId,
      'added_by': userId,
    });

    return nodeId;
  }

  /// Fire-and-forget join notification to group members.
  static Future<void> _sendJoinNotification({
    required String groupId,
    required String newUserId,
    required String familyName,
  }) async {
    try {
      final client = SupabaseConfig.client;

      // Get all OTHER members to notify
      final members = await client
          .from('family_group_members')
          .select('user_id')
          .eq('group_id', groupId)
          .neq('user_id', newUserId);

      // Fetch the join notification template from admin panel
      final template = await client
          .from('admin_notification_templates')
          .select()
          .eq('template_key', 'family_join_1')
          .eq('is_active', true)
          .maybeSingle();

      if (template == null) return;

      final body = (template['body_ar'] as String)
          .replaceAll('{{member_name}}', 'عضو جديد')
          .replaceAll('{{family_name}}', familyName);
      final title = template['title_ar'] as String;

      // Send to each member via the existing push function
      for (final member in members) {
        await client.functions.invoke('send-push-notification', body: {
          'userId': member['user_id'],
          'notificationType': 'system',
          'title': title,
          'body': body,
          'data': {'type': 'family_join', 'group_id': groupId},
        });
      }
    } catch (_) {
      // Fire-and-forget — don't block join flow on notification failure
    }
  }

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
        .order('joined_at');

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
