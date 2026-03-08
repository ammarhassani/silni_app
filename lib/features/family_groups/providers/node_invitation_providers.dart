import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silni_app/features/family_groups/models/node_invitation_model.dart';
import 'package:silni_app/features/family_groups/services/node_invitation_service.dart';

/// Pending invitations for the current user (matched by phone)
final myPendingInvitationsProvider =
    FutureProvider<List<NodeInvitation>>((ref) async {
  final service = ref.read(nodeInvitationServiceProvider);
  return service.getMyPendingInvitations();
});

/// All invitations for a specific group (admin view)
final groupInvitationsProvider =
    FutureProvider.family<List<NodeInvitation>, String>((ref, groupId) async {
  final service = ref.read(nodeInvitationServiceProvider);
  return service.getGroupInvitations(groupId);
});

/// Invitation status for a specific relative node
final relativeInvitationProvider = FutureProvider.family<NodeInvitation?,
    ({String groupId, String relativeId})>((ref, params) async {
  final service = ref.read(nodeInvitationServiceProvider);
  return service.getInvitationForRelative(
    groupId: params.groupId,
    relativeId: params.relativeId,
  );
});

/// Count of pending invitations (for bell badge)
final pendingInvitationCountProvider = FutureProvider<int>((ref) async {
  final invitations = await ref.watch(myPendingInvitationsProvider.future);
  return invitations.length;
});
