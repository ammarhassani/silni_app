import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../models/family_group_model.dart';
import '../services/family_group_service.dart';

/// Cache duration for group providers (same pattern as familyEdgesStreamProvider).
const _cacheTimeout = Duration(minutes: 5);

/// Slot-state snapshot from the `get_my_membership_slots` RPC.
///
/// The DB enforces per-user quotas:
///   - 1 admin role across all groups
///   - 2 member roles across all groups
///   - personal scope is always available
///
/// UI surfaces use these flags to hide/disable CTAs when a slot is full;
/// the actual "replace" flow (leave + join, or delete + create) is a
/// separate task.
class MembershipSlots {
  final FamilyGroup? admin;
  final List<FamilyGroup> members;
  final bool adminSlotFull;
  final bool memberSlotFull;

  const MembershipSlots({
    required this.admin,
    required this.members,
    required this.adminSlotFull,
    required this.memberSlotFull,
  });

  factory MembershipSlots.fromJson(Map<String, dynamic> json) {
    final adminJson = json['admin'] as Map<String, dynamic>?;
    final membersJson = (json['members'] as List<dynamic>?) ?? const [];
    return MembershipSlots(
      admin: adminJson != null ? FamilyGroup.fromJson(adminJson) : null,
      members: membersJson
          .map((m) => FamilyGroup.fromJson(m as Map<String, dynamic>))
          .toList(),
      adminSlotFull: json['admin_slot_full'] as bool? ?? false,
      memberSlotFull: json['member_slot_full'] as bool? ?? false,
    );
  }
}

/// Watches the current user's membership slot state. Invalidate this
/// after any group create/join/leave/kick to refresh the UI gates.
///
/// `autoDispose` so each new screen visit re-fetches; combined with
/// explicit `ref.invalidate` calls in write paths this keeps the slot
/// state correct without needing a long-lived stream.
final myMembershipSlotsProvider =
    FutureProvider.autoDispose<MembershipSlots>((ref) async {
  final result = await SupabaseConfig.client
      .rpc('get_my_membership_slots')
      .timeout(const Duration(seconds: 10));
  return MembershipSlots.fromJson(result as Map<String, dynamic>);
});

/// Provider for the current user's family groups.
///
/// Accepts a userId and returns a list of [FamilyGroup] objects.
/// Uses autoDispose with timed cache to balance freshness and performance.
final userGroupsProvider =
    FutureProvider.autoDispose.family<List<FamilyGroup>, String>(
  (ref, userId) {
    final link = ref.keepAlive();
    Timer? timer;

    ref.onDispose(() => timer?.cancel());
    ref.onCancel(() {
      timer = Timer(_cacheTimeout, () => link.close());
    });
    ref.onResume(() => timer?.cancel());

    return FamilyGroupService.getUserGroups(userId);
  },
);

/// Realtime stream provider for members of a specific group.
///
/// Accepts a groupId and returns a list of [FamilyGroupMember] objects.
/// Uses Supabase `.stream()` so the member list updates automatically
/// when someone joins or leaves.
final groupMembersProvider =
    StreamProvider.autoDispose.family<List<FamilyGroupMember>, String>(
  (ref, groupId) {
    final link = ref.keepAlive();
    Timer? timer;

    ref.onDispose(() => timer?.cancel());
    ref.onCancel(() {
      timer = Timer(_cacheTimeout, () => link.close());
    });
    ref.onResume(() => timer?.cancel());

    return SupabaseConfig.client
        .from('family_group_members')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .order('joined_at', ascending: true)
        .asyncMap((rows) async {
          final members = rows
              .map((json) => FamilyGroupMember.fromJson(json))
              .toList();

          // Batch-fetch display names for members with relative_id_in_tree.
          // Wrapped in try/catch so a name-lookup failure doesn't kill the
          // entire stream — members are still shown without display names.
          try {
            final relativeIds = members
                .where((m) => m.relativeIdInTree != null)
                .map((m) => m.relativeIdInTree!)
                .toList();

            if (relativeIds.isEmpty) return members;

            final relativesData = await SupabaseConfig.client
                .from('relatives')
                .select('id, full_name')
                .inFilter('id', relativeIds);

            final nameMap = <String, String>{
              for (final r in relativesData)
                r['id'] as String: r['full_name'] as String,
            };

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
          } catch (_) {
            // Name enrichment failed — return members without display names
            return members;
          }
        });
  },
);
