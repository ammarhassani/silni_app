import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:silni_app/core/config/supabase_config.dart';
import 'package:silni_app/features/family_groups/models/node_invitation_model.dart';

final nodeInvitationServiceProvider = Provider<NodeInvitationService>(
  (ref) => NodeInvitationService(),
);

class NodeInvitationService {
  SupabaseClient get _supabase => SupabaseConfig.client;

  /// Create an invitation for a specific node (admin only)
  Future<NodeInvitation> createInvitation({
    required String groupId,
    required String relativeId,
    required String phoneNumber,
  }) async {
    final result = await _supabase.rpc('create_node_invitation', params: {
      'p_group_id': groupId,
      'p_relative_id': relativeId,
      'p_phone': phoneNumber,
    });
    return NodeInvitation.fromJson(result as Map<String, dynamic>);
  }

  /// Accept a pending invitation (invitee)
  Future<Map<String, dynamic>> acceptInvitation(String invitationId) async {
    final result = await _supabase.rpc('accept_node_invitation', params: {
      'p_invitation_id': invitationId,
    });
    return result as Map<String, dynamic>;
  }

  /// Cancel a pending invitation (admin)
  Future<void> cancelInvitation(String invitationId) async {
    await _supabase.rpc('cancel_node_invitation', params: {
      'p_invitation_id': invitationId,
    });
  }

  /// Get pending invitations for current user's verified phone
  Future<List<NodeInvitation>> getMyPendingInvitations() async {
    final result = await _supabase.rpc('get_my_pending_invitations');
    final list = result as List<dynamic>;
    return list
        .map((e) => NodeInvitation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get all invitations for a group (admin view)
  Future<List<NodeInvitation>> getGroupInvitations(String groupId) async {
    final result = await _supabase
        .from('node_invitations')
        .select('*, relatives!inner(full_name, relationship_type)')
        .eq('group_id', groupId)
        .order('created_at', ascending: false);

    return (result as List<dynamic>).map((e) {
      final json = e as Map<String, dynamic>;
      final relative = json['relatives'] as Map<String, dynamic>?;
      return NodeInvitation.fromJson({
        ...json,
        'relative_name': relative?['full_name'],
        'relationship_type': relative?['relationship_type'],
      });
    }).toList();
  }

  /// Get invitation status for a specific relative
  Future<NodeInvitation?> getInvitationForRelative({
    required String groupId,
    required String relativeId,
  }) async {
    final result = await _supabase
        .from('node_invitations')
        .select()
        .eq('group_id', groupId)
        .eq('relative_id', relativeId)
        .eq('status', 'pending')
        .maybeSingle();

    if (result == null) return null;
    return NodeInvitation.fromJson(result);
  }
}
