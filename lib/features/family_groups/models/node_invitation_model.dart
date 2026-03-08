class NodeInvitation {
  final String id;
  final String groupId;
  final String relativeId;
  final String phoneNumber;
  final String invitedBy;
  final String status; // pending, accepted, cancelled
  final String? acceptedBy;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? cancelledAt;

  // Joined fields (from get_my_pending_invitations RPC)
  final String? groupName;
  final String? relativeName;
  final String? relationshipType;
  final String? invitedByName;

  const NodeInvitation({
    required this.id,
    required this.groupId,
    required this.relativeId,
    required this.phoneNumber,
    required this.invitedBy,
    required this.status,
    this.acceptedBy,
    required this.createdAt,
    this.acceptedAt,
    this.cancelledAt,
    this.groupName,
    this.relativeName,
    this.relationshipType,
    this.invitedByName,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isCancelled => status == 'cancelled';

  /// Masked phone for display: +966 **** 5678
  String get maskedPhone {
    if (phoneNumber.length < 8) return phoneNumber;
    final prefix = phoneNumber.substring(0, 4);
    final suffix = phoneNumber.substring(phoneNumber.length - 4);
    final middleLength = phoneNumber.length - 8;
    final masked = '*' * middleLength;
    return '$prefix $masked $suffix';
  }

  factory NodeInvitation.fromJson(Map<String, dynamic> json) {
    return NodeInvitation(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      relativeId: json['relative_id'] as String,
      phoneNumber: json['phone_number'] as String,
      invitedBy: json['invited_by'] as String,
      status: json['status'] as String,
      acceptedBy: json['accepted_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      groupName: json['group_name'] as String?,
      relativeName: json['relative_name'] as String?,
      relationshipType: json['relationship_type'] as String?,
      invitedByName: json['invited_by_name'] as String?,
    );
  }
}
