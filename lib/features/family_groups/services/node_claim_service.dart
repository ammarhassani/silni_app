import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:silni_app/core/config/supabase_config.dart';
import 'package:silni_app/features/family_groups/models/candidate_relative_model.dart';
import 'package:silni_app/features/family_groups/models/node_claim_model.dart';
import 'package:silni_app/features/family_groups/services/family_sharing_service.dart';

final nodeClaimServiceProvider = Provider<NodeClaimService>(
  (ref) => NodeClaimService(),
);

/// Wraps the node-claim lifecycle RPCs introduced by migrations
/// 20260508100000–20260508130000 for the family-sharing identity-claim flow.
///
/// Discovery flow on the joiner side:
///   1. [findCandidates] — show the candidate list for a declared role
///   2. [createClaim] — submit a claim (existing-node OR add-me)
///   3. [getMyPendingClaims] — surface the "waiting for admin" banner
///   4. [cancelClaim] — joiner withdraws
///
/// Admin side:
///   1. [getGroupPendingClaims] — claim queue
///   2. [approveClaim] — confirm; follows up with verifySharedEdges
///   3. [rejectClaim], [snoozeClaim]
class NodeClaimService {
  SupabaseClient get _supabase => SupabaseConfig.client;

  // ---------------------------------------------------------------- Joiner

  /// Submit a claim. Returns the created [NodeClaim].
  ///
  /// For "claim existing node": pass [claimedRelativeId], leave proposed_*
  /// fields null. For "add me to the tree": pass [proposedFullName] (and
  /// optionals), leave [claimedRelativeId] null. Edge_path must be one of
  /// parent/child/spouse/sibling for the add-me path (RPC enforces).
  Future<NodeClaim> createClaim({
    required String groupId,
    String? claimedRelativeId,
    required String anchorRelativeId,
    required String edgePath,
    String? parentSide,
    required String gender,
    String? proposedFullName,
    String? proposedGender,
    int? proposedBirthYear,
    String? proposedCity,
    String? proposedPhotoUrl,
    String? proposedPhoneNumber,
  }) async {
    final result = await _supabase.rpc('create_node_claim', params: {
      'p_group_id': groupId,
      'p_claimed_relative_id': claimedRelativeId,
      'p_anchor_relative_id': anchorRelativeId,
      'p_edge_path': edgePath,
      'p_parent_side': parentSide,
      'p_gender': gender,
      'p_proposed_full_name': proposedFullName,
      'p_proposed_gender': proposedGender,
      'p_proposed_birth_year': proposedBirthYear,
      'p_proposed_city': proposedCity,
      'p_proposed_photo_url': proposedPhotoUrl,
      'p_proposed_phone_number': proposedPhoneNumber,
    });
    return NodeClaim.fromJson(result as Map<String, dynamic>);
  }

  /// Joiner-side: pending claims for the current user across all groups.
  Future<List<NodeClaim>> getMyPendingClaims() async {
    final result = await _supabase.rpc('get_my_pending_claims');
    final list = result as List<dynamic>;
    return list
        .map((e) => NodeClaim.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Joiner-side: withdraw a pending claim.
  Future<void> cancelClaim(String claimId) async {
    await _supabase.rpc('cancel_node_claim', params: {
      'p_claim_id': claimId,
    });
  }

  /// Compute the candidate list for a declared role (the picker step in
  /// the discovery wizard). Returns [] when the graph yields nothing —
  /// the UI should fall through to the "add me" path.
  ///
  /// Hard timeout of 12s — if the RPC hangs (network blip, auth issue,
  /// Supabase outage), surface that as a clear TimeoutException instead
  /// of an infinite spinner.
  Future<List<CandidateRelative>> findCandidates({
    required String groupId,
    required String anchorRelativeId,
    required String edgePath,
    String? parentSide,
    required String gender,
  }) async {
    debugPrint(
      '[NodeClaimService.findCandidates] → group=$groupId anchor=$anchorRelativeId '
      'edge=$edgePath side=$parentSide gender=$gender',
    );
    try {
      final result = await _supabase.rpc(
        'get_candidate_relatives',
        params: {
          'p_group_id': groupId,
          'p_anchor_relative_id': anchorRelativeId,
          'p_edge_path': edgePath,
          'p_parent_side': parentSide,
          'p_gender': gender,
        },
      ).timeout(const Duration(seconds: 12));

      debugPrint(
        '[NodeClaimService.findCandidates] ← raw runtimeType=${result.runtimeType} '
        'value=$result',
      );

      if (result == null) return const [];
      final list = result as List<dynamic>;
      final parsed = list
          .map((e) => CandidateRelative.fromJson(e as Map<String, dynamic>))
          .where((c) => !c.isSelf && !c.isAlreadyClaimed)
          .toList();
      debugPrint(
        '[NodeClaimService.findCandidates] parsed ${parsed.length} candidates',
      );
      return parsed;
    } catch (e, st) {
      debugPrint('[NodeClaimService.findCandidates] ✗ $e\n$st');
      rethrow;
    }
  }

  // ----------------------------------------------------------------- Admin

  /// Admin-side: pending claims awaiting decision in a group.
  /// Excludes snoozed-into-the-future claims (RPC handles that).
  Future<List<NodeClaim>> getGroupPendingClaims(String groupId) async {
    final result = await _supabase.rpc('get_group_pending_claims', params: {
      'p_group_id': groupId,
    });
    final list = result as List<dynamic>;
    return list
        .map((e) => NodeClaim.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Admin confirms a claim. Returns the relative_id the claimant was
  /// linked to (existing or newly-created).
  ///
  /// After success, the caller MUST invoke [FamilySharingService.verifySharedEdges]
  /// for the group so the new node's family_edges are inferred & persisted.
  Future<ApproveClaimResult> approveClaim(String claimId) async {
    final result = await _supabase.rpc('approve_node_claim', params: {
      'p_claim_id': claimId,
    });
    return ApproveClaimResult.fromJson(result as Map<String, dynamic>);
  }

  /// Admin denies a claim with optional reason text.
  Future<void> rejectClaim({
    required String claimId,
    String? reason,
  }) async {
    await _supabase.rpc('reject_node_claim', params: {
      'p_claim_id': claimId,
      'p_reason': reason,
    });
  }

  /// Admin defers decision until [until]. Claim stays pending; just hidden
  /// from the queue until the snooze passes.
  Future<void> snoozeClaim({
    required String claimId,
    required DateTime until,
  }) async {
    await _supabase.rpc('snooze_node_claim', params: {
      'p_claim_id': claimId,
      'p_until': until.toUtc().toIso8601String(),
    });
  }
}

/// Result of [NodeClaimService.approveClaim].
class ApproveClaimResult {
  final String claimId;
  final String groupId;
  final String claimantUserId;
  final String relativeId;
  final bool createdNewNode;

  const ApproveClaimResult({
    required this.claimId,
    required this.groupId,
    required this.claimantUserId,
    required this.relativeId,
    required this.createdNewNode,
  });

  factory ApproveClaimResult.fromJson(Map<String, dynamic> json) {
    return ApproveClaimResult(
      claimId: json['claim_id'] as String,
      groupId: json['group_id'] as String,
      claimantUserId: json['claimant_user_id'] as String,
      relativeId: json['relative_id'] as String,
      createdNewNode: json['created_new_node'] as bool? ?? false,
    );
  }
}
