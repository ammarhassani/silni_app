/// A tree-node candidate returned by `get_candidate_relatives` for the
/// joiner's identity-claim picker. Represents one possible match given
/// the declared (edge_path, parent_side, gender) tuple.
class CandidateRelative {
  final String id;
  final String fullName;
  final String? gender;
  final DateTime? dateOfBirth;

  /// Disambiguator shown as subtitle: usually the parent's name (for
  /// uncle/cousin/grandchild paths) or null (for direct relationships
  /// where parent context isn't useful).
  final String? parentFullName;

  final bool isSelf;

  /// True if a different group member's `relative_id_in_tree` already
  /// points at this candidate (defensive — `is_self=true` should already
  /// filter most of these). UI uses this to gray-out / hide such rows.
  final bool isAlreadyClaimed;

  const CandidateRelative({
    required this.id,
    required this.fullName,
    this.gender,
    this.dateOfBirth,
    this.parentFullName,
    required this.isSelf,
    required this.isAlreadyClaimed,
  });

  factory CandidateRelative.fromJson(Map<String, dynamic> json) {
    return CandidateRelative(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      gender: json['gender'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      parentFullName: json['parent_full_name'] as String?,
      isSelf: json['is_self'] as bool? ?? false,
      isAlreadyClaimed: json['is_already_claimed'] as bool? ?? false,
    );
  }
}
