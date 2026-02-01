import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/family_group_model.dart';
import '../services/family_group_service.dart';

/// Cache duration for group providers (same pattern as familyEdgesStreamProvider).
const _cacheTimeout = Duration(minutes: 5);

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

/// Provider for members of a specific group.
///
/// Accepts a groupId and returns a list of [FamilyGroupMember] objects.
final groupMembersProvider =
    FutureProvider.autoDispose.family<List<FamilyGroupMember>, String>(
  (ref, groupId) {
    final link = ref.keepAlive();
    Timer? timer;

    ref.onDispose(() => timer?.cancel());
    ref.onCancel(() {
      timer = Timer(_cacheTimeout, () => link.close());
    });
    ref.onResume(() => timer?.cancel());

    return FamilyGroupService.getGroupMembers(groupId);
  },
);
