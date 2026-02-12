/// A family group that members can join to share a family tree.
///
/// Groups are identified by a unique [inviteCode] that can be shared
/// via deep links. The creator is automatically added as an admin.
class FamilyGroup {
  final String id;
  final String name;
  final String createdBy;
  final String inviteCode;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const FamilyGroup({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.inviteCode,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create from Supabase JSON row.
  factory FamilyGroup.fromJson(Map<String, dynamic> json) {
    return FamilyGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      createdBy: json['created_by'] as String,
      inviteCode: json['invite_code'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to Supabase-compatible JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_by': createdBy,
      'invite_code': inviteCode,
      'created_at': createdAt.toUtc().toIso8601String(),
      if (updatedAt != null)
        'updated_at': updatedAt!.toUtc().toIso8601String(),
    };
  }

  /// Create a copy with optional field overrides.
  FamilyGroup copyWith({
    String? id,
    String? name,
    String? createdBy,
    String? inviteCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FamilyGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FamilyGroup && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'FamilyGroup(id: $id, name: $name, inviteCode: $inviteCode)';
}

/// A member of a [FamilyGroup].
///
/// Each member has a [role] (admin or member) and an optional
/// [relativeIdInTree] linking them to a node in the family tree.
class FamilyGroupMember {
  final String id;
  final String groupId;
  final String userId;
  final String? relativeIdInTree;
  final String role;
  final DateTime joinedAt;
  final String? displayName;

  const FamilyGroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    this.relativeIdInTree,
    required this.role,
    required this.joinedAt,
    this.displayName,
  });

  /// Whether this member is a group admin.
  bool get isAdmin => role == 'admin';

  /// Create from Supabase JSON row.
  factory FamilyGroupMember.fromJson(Map<String, dynamic> json) {
    return FamilyGroupMember(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      relativeIdInTree: json['relative_id_in_tree'] as String?,
      role: json['role'] as String? ?? 'member',
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  /// Convert to Supabase-compatible JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      if (relativeIdInTree != null) 'relative_id_in_tree': relativeIdInTree,
      'role': role,
      'joined_at': joinedAt.toUtc().toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FamilyGroupMember && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'FamilyGroupMember(id: $id, groupId: $groupId, userId: $userId, role: $role)';
}
