import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:silni_app/features/family_groups/models/node_claim_model.dart';
import 'package:silni_app/features/family_groups/services/node_claim_service.dart';

/// Pending claims for the current user (across all groups). Drives the
/// "في انتظار تأكيد المسؤول" banner on the joiner's home/tree.
final myPendingClaimsProvider =
    FutureProvider<List<NodeClaim>>((ref) async {
  final service = ref.read(nodeClaimServiceProvider);
  return service.getMyPendingClaims();
});

/// Pending claims for a specific group (admin queue). Excludes snoozed.
final groupPendingClaimsProvider =
    FutureProvider.family<List<NodeClaim>, String>((ref, groupId) async {
  final service = ref.read(nodeClaimServiceProvider);
  return service.getGroupPendingClaims(groupId);
});

/// Counter for the badge on the family-group "الدعوات" tab.
final groupPendingClaimsCountProvider =
    FutureProvider.family<int, String>((ref, groupId) async {
  final claims = await ref.watch(groupPendingClaimsProvider(groupId).future);
  return claims.length;
});

/// Counter for any badge on home/profile when the joiner has at least
/// one pending claim of their own.
final myPendingClaimsCountProvider = FutureProvider<int>((ref) async {
  final claims = await ref.watch(myPendingClaimsProvider.future);
  return claims.length;
});
