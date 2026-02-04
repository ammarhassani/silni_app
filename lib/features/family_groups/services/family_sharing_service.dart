import 'package:uuid/uuid.dart';
import '../../../core/config/supabase_config.dart';
import '../../../shared/models/relative_model.dart';
import '../../family_tree/models/family_graph.dart';
import '../../family_tree/services/family_graph_service.dart';
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

    // 2. Create self node
    final selfNodeId = const Uuid().v4();
    await client.from('relatives').insert({
      'id': selfNodeId,
      'user_id': userId,
      'full_name': userDisplayName,
      'relationship_type': 'other',
      'gender': userGender?.value ?? 'male',
      'priority': 1,
      'avatar_type': userGender == Gender.female ? 'adult_woman' : 'adult_man',
      'current_streak': 0,
      'longest_streak': 0,
      'is_self': true,
      'family_group_id': group.id,
      'added_by': userId,
    });

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
      selfNodeId: selfNodeId,
      relatives: relatives,
      groupId: group.id,
    );

    if (edges.isNotEmpty) {
      await client.from('family_edges').insert(
        edges.map((e) => e.toJson()).toList(),
      );
    }

    return group;
  }

  /// Generate shared edges from personal relatives (pure, testable).
  ///
  /// Uses [FamilyGraphService.inferEdges] for each relative, using
  /// [selfNodeId] as the anchor instead of the auth user ID.
  /// All edges get [groupId] set for shared visibility.
  static List<FamilyEdge> generateSharedEdges({
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
          userId: edge.userId,
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

  /// Get the user's first family group (if any).
  static Future<FamilyGroup?> getUserGroup(String userId) async {
    final groups = await FamilyGroupService.getUserGroups(userId);
    return groups.isEmpty ? null : groups.first;
  }

  /// Generate an invite link for a specific relative.
  static String generateInviteLink({
    required String inviteCode,
    required String relativeId,
  }) {
    return 'https://silni.app/join/$inviteCode?rid=$relativeId';
  }
}
