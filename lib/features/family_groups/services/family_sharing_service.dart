import 'package:uuid/uuid.dart';
import '../../../core/config/supabase_config.dart';
import '../../../shared/models/relative_model.dart';
import '../../family_tree/models/family_graph.dart';
import '../../family_tree/services/family_graph_service.dart';
import '../../relatives/services/relationship_inference_service.dart';
import '../models/family_group_model.dart';
import 'family_group_service.dart';

/// Orchestrates the full family sharing flow:
/// auto-create group, self node, migrate relatives, generate edges.
class FamilySharingService {
  FamilySharingService._();

  /// Initialize a shared tree from the user's personal relatives.
  ///
  /// 1. Creates family group with [familyName]
  /// 2. Creates a self-node relative for the user
  /// 3. Sets family_group_id on all user's personal relatives
  /// 4. Generates and persists shared edges
  static Future<FamilyGroup> initializeSharedTree({
    required String userId,
    required String familyName,
    required String userDisplayName,
    required Gender? userGender,
  }) async {
    final client = SupabaseConfig.client;

    // 1. Create family group
    final group = await FamilyGroupService.createGroup(
      name: familyName,
      userId: userId,
    );

    // 2. Find or create the self-node for this group.
    //
    // The self_node_on_signup trigger (migration 20260428620000) auto-creates
    // a personal self-node (is_self=true, family_group_id=NULL) when a user
    // signs up. If we blindly INSERT a brand-new shared self-node here AND
    // then migrate all personal relatives into the group in step 5, the
    // existing personal self-node also gets family_group_id=group.id — and
    // that collides with the new one on idx_relatives_self_per_user_group
    // (UNIQUE on (user_id, family_group_id) WHERE is_self=true AND
    // family_group_id IS NOT NULL).
    //
    // Promote the existing personal self-node into the group if one exists.
    // Fall back to INSERT for legacy accounts that pre-date the trigger.
    final existingSelfRows = await client
        .from('relatives')
        .select('id')
        .eq('user_id', userId)
        .eq('is_self', true)
        .isFilter('family_group_id', null)
        .limit(1);

    final String selfNodeId;
    if (existingSelfRows.isNotEmpty) {
      selfNodeId = existingSelfRows.first['id'] as String;
      // Backfill gender on promotion if the trigger left it NULL — the
      // perspective engine and side-of-family layout rely on it.
      // Don't touch full_name: the user may have curated it.
      await client
          .from('relatives')
          .update({
            'family_group_id': group.id,
            if (userGender != null) 'gender': userGender.value,
          })
          .eq('id', selfNodeId);
    } else {
      selfNodeId = const Uuid().v4();
      await client.from('relatives').insert({
        'id': selfNodeId,
        'user_id': userId,
        'full_name': userDisplayName,
        'relationship_type': 'other',
        'gender': userGender?.value ?? 'male',
        'priority': 1,
        'avatar_type': userGender == Gender.female ? 'adult_woman' : 'adult_man',
        'is_self': true,
        'family_group_id': group.id,
        'added_by': userId,
      });
    }

    // 3. Link user to their self node in group membership
    await client
        .from('family_group_members')
        .update({'relative_id_in_tree': selfNodeId})
        .eq('group_id', group.id)
        .eq('user_id', userId);

    // 4. Fetch all personal relatives and migrate to shared
    final personalRelatives = await client
        .from('relatives')
        .select()
        .eq('user_id', userId)
        .isFilter('family_group_id', null)
        .eq('is_archived', false);

    final relatives = personalRelatives
        .map((json) => Relative.fromJson(json))
        .toList();

    if (relatives.isNotEmpty) {
      final ids = relatives.map((r) => r.id).toList();
      await client
          .from('relatives')
          .update({
            'family_group_id': group.id,
            'added_by': userId,
          })
          .inFilter('id', ids);
    }

    // 5. Generate and persist shared edges
    final edges = generateSharedEdges(
      authUserId: userId,
      selfNodeId: selfNodeId,
      relatives: relatives,
      groupId: group.id,
    );

    if (edges.isNotEmpty) {
      await client.from('family_edges').upsert(
        edges.map((e) => e.toJson()).toList(),
        onConflict: 'user_id,from_id,to_id,edge_type',
      );
    }

    return group;
  }

  /// Generate shared edges from personal relatives (pure, testable).
  ///
  /// Uses [FamilyGraphService.inferEdges] for each relative, using
  /// [selfNodeId] as the graph anchor (node representing "me").
  /// [authUserId] is the actual auth user ID for the DB `user_id` column
  /// (FK to auth.users). All edges get [groupId] set for shared visibility.
  static List<FamilyEdge> generateSharedEdges({
    required String authUserId,
    required String selfNodeId,
    required List<Relative> relatives,
    required String groupId,
  }) {
    final allEdges = <FamilyEdge>[];

    for (final relative in relatives) {
      final inferred = FamilyGraphService.inferEdges(
        userId: selfNodeId,
        newRelativeId: relative.id,
        relationshipType: relative.relationshipType,
        side: relative.familySide,
        existingEdges: allEdges,
        existingRelatives: relatives,
      );

      for (final edge in inferred) {
        allEdges.add(FamilyEdge(
          id: edge.id,
          userId: authUserId,
          fromId: edge.fromId,
          toId: edge.toId,
          type: edge.type,
          createdAt: edge.createdAt,
          familyGroupId: groupId,
        ));
      }
    }

    return allEdges;
  }

  /// Verify and fill any missing edges in the shared graph.
  ///
  /// Re-infers edges for every non-self relative in the group and upserts
  /// any that are missing. This is called after a new member joins to ensure
  /// the graph is complete from every perspective.
  ///
  /// If no self-node exists yet (e.g. `initializeSharedTree` failed partially),
  /// looks up the admin member and creates a self-node for them so edge
  /// generation can proceed.
  ///
  /// The method is idempotent — running it multiple times produces no
  /// duplicate edges thanks to the upsert on the unique constraint.
  static Future<void> verifySharedEdges({
    required String groupId,
  }) async {
    final client = SupabaseConfig.client;

    // 1. Fetch all shared relatives in the group
    final relativesData = await client
        .from('relatives')
        .select()
        .eq('family_group_id', groupId)
        .eq('is_archived', false);

    final allRelatives =
        relativesData.map((json) => Relative.fromJson(json)).toList();

    if (allRelatives.isEmpty) return;

    // 2. Find the self-node (anchor for edge inference).
    //    Prefer the admin's node for deterministic behaviour.
    Relative? selfNode;

    // First try: find admin's linked node among self-nodes
    final adminData = await client
        .from('family_group_members')
        .select('user_id, relative_id_in_tree')
        .eq('group_id', groupId)
        .eq('role', 'admin')
        .limit(1)
        .maybeSingle();

    final adminNodeId = adminData?['relative_id_in_tree'] as String?;
    final adminUserId = adminData?['user_id'] as String?;

    if (adminNodeId != null) {
      selfNode = allRelatives.firstWhereOrNull((r) => r.id == adminNodeId);
    }

    // Fallback: any self-node
    selfNode ??= allRelatives.firstWhereOrNull((r) => r.isSelf);

    // Last resort: no self-node exists — create one for the admin.
    // Fetch admin's profile from users table (not client.auth.currentUser,
    // which is the joiner, not necessarily the admin).
    if (selfNode == null && adminUserId != null) {
      final adminProfile = await client
          .from('users')
          .select('full_name')
          .eq('id', adminUserId)
          .maybeSingle();
      final displayName =
          adminProfile?['full_name'] as String? ?? 'أنا';
      var inferredGender = RelationshipInferenceService.inferGender(displayName);
      inferredGender ??= await RelationshipInferenceService.inferGenderWithAI(displayName);
      final gender = inferredGender?.value ?? 'male';
      final avatarType = inferredGender == Gender.female ? 'adult_woman' : 'adult_man';

      final newNodeId = const Uuid().v4();
      await client.from('relatives').insert({
        'id': newNodeId,
        'user_id': adminUserId,
        'full_name': displayName,
        'relationship_type': 'other',
        'gender': gender,
        'priority': 1,
        'avatar_type': avatarType,
        'is_self': true,
        'family_group_id': groupId,
        'added_by': adminUserId,
      });

      // Link admin to their new self-node
      await client
          .from('family_group_members')
          .update({'relative_id_in_tree': newNodeId})
          .eq('group_id', groupId)
          .eq('user_id', adminUserId);

      // Re-fetch to include the new node
      final refreshed = await client
          .from('relatives')
          .select()
          .eq('family_group_id', groupId)
          .eq('is_archived', false);

      allRelatives
        ..clear()
        ..addAll(refreshed.map((json) => Relative.fromJson(json)));

      selfNode = allRelatives.firstWhereOrNull((r) => r.id == newNodeId);
      if (selfNode == null) return; // INSERT failed (RLS?) — nothing we can do
    }

    if (selfNode == null) return;

    // 3. Fetch existing shared edges
    final edgesData = await client
        .from('family_edges')
        .select()
        .eq('family_group_id', groupId);

    final existingEdges =
        edgesData.map((json) => FamilyEdge.fromJson(json)).toList();

    if (existingEdges.isEmpty) return;

    // 4. Enrich edges via graph topology only.
    //    We do NOT re-infer edges from relationship_type because in a shared
    //    tree each relative's type is stored from the ADDER's perspective.
    //    Re-inferring from the admin's anchor would create wrong edges for
    //    relatives added by non-admin members (e.g. uncle's "father" would
    //    be treated as admin's father).
    //    Instead, propagate parentOf edges across sibling pairs — the only
    //    safe enrichment that doesn't depend on perspective.
    final graph = FamilyGraphService.buildGraph(
      userId: selfNode.id,
      edges: existingEdges,
    );
    final enriched = FamilyGraphService.enrichAllSiblingEdges(graph);

    // 5. Find newly inferred edges from enrichment
    final existingKeys = <String>{};
    for (final e in existingEdges) {
      existingKeys.add('${e.fromId}|${e.toId}|${e.type.name}');
    }

    final currentUserId = client.auth.currentUser!.id;
    final missingEdges = enriched.edges.where((e) {
      return !existingKeys.contains('${e.fromId}|${e.toId}|${e.type.name}');
    }).map((e) => FamilyEdge(
      id: e.id,
      userId: currentUserId,
      fromId: e.fromId,
      toId: e.toId,
      type: e.type,
      createdAt: e.createdAt,
      familyGroupId: groupId,
    )).toList();

    // 6. Insert missing enrichment edges. Wrapped in try-catch because the
    //    group-level unique index (family_group_id,from_id,to_id,edge_type)
    //    may block inserts if another member already created the same edge
    //    with a different user_id. Safe to ignore — the edge exists.
    if (missingEdges.isNotEmpty) {
      try {
        await client.from('family_edges').upsert(
          missingEdges.map((e) => e.toJson()).toList(),
          onConflict: 'user_id,from_id,to_id,edge_type',
          ignoreDuplicates: true,
        );
      } catch (_) {
        // Group-level unique constraint conflict — edges already exist.
      }
    }
  }

  /// Get the user's first family group (if any).
  static Future<FamilyGroup?> getUserGroup(String userId) async {
    final groups = await FamilyGroupService.getUserGroups(userId);
    return groups.isEmpty ? null : groups.first;
  }

  /// Migrate user's personal relatives to a group.
  ///
  /// Call this to fix cases where a user is in a group but their relatives
  /// weren't migrated (e.g., group created before migration logic existed).
  /// Returns the number of relatives migrated.
  static Future<int> migrateRelativesToGroup({
    required String userId,
    required String groupId,
  }) async {
    final client = SupabaseConfig.client;

    // Find personal relatives not yet in this group
    final personalRelatives = await client
        .from('relatives')
        .select('id')
        .eq('user_id', userId)
        .isFilter('family_group_id', null)
        .eq('is_archived', false);

    if (personalRelatives.isEmpty) return 0;

    final ids = personalRelatives.map((r) => r['id'] as String).toList();

    // Update to set family_group_id
    await client
        .from('relatives')
        .update({
          'family_group_id': groupId,
          'added_by': userId,
        })
        .inFilter('id', ids);

    return ids.length;
  }

  /// Ensure user's relatives are in their group.
  ///
  /// On first-time setup (no self-node yet), creates a self-node and optionally
  /// migrates personal relatives into the group. On subsequent calls, only
  /// ensures edges are up-to-date — personal relatives are NOT re-migrated
  /// to prevent cleaned-up duplicates from reappearing.
  ///
  /// [migrateRelatives] gates the personal-relatives migration step. When
  /// false, the self-node is created but personal relatives stay separate.
  /// Defaults to true to preserve historical behavior for callers that don't
  /// surface a choice (e.g., admin first-create flow inside `initializeSharedTree`).
  static Future<void> ensureRelativesInGroup({
    required String userId,
    required String groupId,
    String? userDisplayName,
    Gender? userGender,
    bool migrateRelatives = true,
  }) async {
    final client = SupabaseConfig.client;

    // 1. Check if user already has a self-node (signals migration is done)
    var memberData = await client
        .from('family_group_members')
        .select('relative_id_in_tree')
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .maybeSingle();

    var selfNodeId = memberData?['relative_id_in_tree'] as String?;

    // 2. If self-node already exists, migration + edge generation are done.
    //    Return early to avoid re-generating edges that could conflict with
    //    edges created by other group members (different user_id on the
    //    same from_id/to_id/edge_type triggers group-level unique index).
    if (selfNodeId != null) return;

    // 3. First-time setup: optionally migrate personal relatives into the group.
    if (migrateRelatives) {
      await migrateRelativesToGroup(
        userId: userId,
        groupId: groupId,
      );
    }

    // 4. Create user's self-node in the group
    {
      final user = SupabaseConfig.client.auth.currentUser;
      final displayName = userDisplayName ??
          user?.userMetadata?['full_name'] as String? ??
          'أنا';
      final gender = userGender ?? Gender.male;

      selfNodeId = const Uuid().v4();
      await client.from('relatives').insert({
        'id': selfNodeId,
        'user_id': userId,
        'full_name': displayName,
        'relationship_type': 'other',
        'gender': gender.value,
        'priority': 1,
        'avatar_type': gender == Gender.female ? 'adult_woman' : 'adult_man',
        'is_self': true,
        'family_group_id': groupId,
        'added_by': userId,
      });

      // Link user to their self node
      await client
          .from('family_group_members')
          .update({'relative_id_in_tree': selfNodeId})
          .eq('group_id', groupId)
          .eq('user_id', userId);
    }

    // 5. Fetch all user's relatives in this group
    final relativesData = await client
        .from('relatives')
        .select()
        .eq('family_group_id', groupId)
        .eq('user_id', userId)
        .eq('is_archived', false);

    final relatives = relativesData
        .map((json) => Relative.fromJson(json))
        .where((r) => r.id != selfNodeId) // Exclude self-node
        .toList();

    if (relatives.isEmpty) return;

    // 6. Generate and persist shared edges for migrated relatives.
    //    Use the current user's ID so the RLS INSERT policy is satisfied.
    final edges = generateSharedEdges(
      authUserId: userId,
      selfNodeId: selfNodeId,
      relatives: relatives,
      groupId: groupId,
    );

    if (edges.isNotEmpty) {
      await client.from('family_edges').upsert(
        edges.map((e) => e.toJson()).toList(),
        onConflict: 'user_id,from_id,to_id,edge_type',
        ignoreDuplicates: true,
      );
    }
  }

}

/// Extension to add `firstWhereOrNull` without requiring collection package.
extension _IterableExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
