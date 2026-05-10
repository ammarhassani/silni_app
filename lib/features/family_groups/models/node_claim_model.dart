/// A joiner-initiated identity-claim record for a family-group tree node.
///
/// Counterpart to [NodeInvitation]: invitations are admin → invitee
/// (phone-keyed), claims are joiner → admin (role-based).
///
/// See docs/plans/2026-05-08-family-sharing-identity-claim-design.md
class NodeClaim {
  final String id;
  final String groupId;
  final String claimantUserId;

  /// Tree node being claimed. NULL means "I'm not in the tree, add me"
  /// (the joiner supplied [proposedFullName] et al instead).
  final String? claimedRelativeId;

  /// The relationship the joiner declared to the anchor person.
  /// Matches the admin_relationship_labels schema:
  /// [declaredEdgePath] in {parent, child, spouse, sibling, grandparent,
  /// grandchild, uncle_aunt, nephew_niece, cousin}
  /// [declaredParentSide] in {paternal, maternal, null}
  /// [declaredGender] in {male, female}
  final String declaredAnchorRelativeId;
  final String declaredEdgePath;
  final String? declaredParentSide;
  final String declaredGender;

  // "Add me to the tree" form data (NULL when claiming an existing node).
  final String? proposedFullName;
  final String? proposedGender;
  final int? proposedBirthYear;
  final String? proposedCity;
  final String? proposedPhotoUrl;

  final String status; // pending | approved | rejected | cancelled
  final String? rejectionReason;
  final String? decidedBy;
  final DateTime? decidedAt;
  final DateTime? snoozedUntil;

  final DateTime createdAt;

  // Joined fields (populated by get_my_pending_claims / get_group_pending_claims).
  final String? groupName;
  final String? claimedRelativeName;
  final String? declaredAnchorName;
  final String? claimantName;

  const NodeClaim({
    required this.id,
    required this.groupId,
    required this.claimantUserId,
    this.claimedRelativeId,
    required this.declaredAnchorRelativeId,
    required this.declaredEdgePath,
    this.declaredParentSide,
    required this.declaredGender,
    this.proposedFullName,
    this.proposedGender,
    this.proposedBirthYear,
    this.proposedCity,
    this.proposedPhotoUrl,
    required this.status,
    this.rejectionReason,
    this.decidedBy,
    this.decidedAt,
    this.snoozedUntil,
    required this.createdAt,
    this.groupName,
    this.claimedRelativeName,
    this.declaredAnchorName,
    this.claimantName,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';
  bool get isAddMePath => claimedRelativeId == null;

  factory NodeClaim.fromJson(Map<String, dynamic> json) {
    return NodeClaim(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      claimantUserId: json['claimant_user_id'] as String? ?? '',
      claimedRelativeId: json['claimed_relative_id'] as String?,
      declaredAnchorRelativeId: json['declared_anchor_relative_id'] as String,
      declaredEdgePath: json['declared_edge_path'] as String,
      declaredParentSide: json['declared_parent_side'] as String?,
      declaredGender: json['declared_gender'] as String,
      proposedFullName: json['proposed_full_name'] as String?,
      proposedGender: json['proposed_gender'] as String?,
      proposedBirthYear: json['proposed_birth_year'] as int?,
      proposedCity: json['proposed_city'] as String?,
      proposedPhotoUrl: json['proposed_photo_url'] as String?,
      status: json['status'] as String? ?? 'pending',
      rejectionReason: json['rejection_reason'] as String?,
      decidedBy: json['decided_by'] as String?,
      decidedAt: json['decided_at'] != null
          ? DateTime.parse(json['decided_at'] as String)
          : null,
      snoozedUntil: json['snoozed_until'] != null
          ? DateTime.parse(json['snoozed_until'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      groupName: json['group_name'] as String?,
      claimedRelativeName: json['claimed_relative_name'] as String?,
      declaredAnchorName: json['declared_anchor_name'] as String?,
      claimantName: json['claimant_name'] as String?,
    );
  }
}

/// Reason categories the admin can pick when rejecting a claim.
/// Stored as free text in [NodeClaim.rejectionReason]; these constants are
/// the canonical set surfaced in the UI.
class ClaimRejectionReason {
  static const String wrongRelationship = 'wrong_relationship';
  static const String unknownPerson = 'unknown_person';
  static const String other = 'other';
}
