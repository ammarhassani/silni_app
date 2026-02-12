import 'package:uuid/uuid.dart';

/// Edge types in the family graph.
///
/// Directed edges encode the core family relationships:
/// - [parentOf]: fromId is a parent of toId
/// - [siblingOf]: fromId is a sibling of toId (stored bidirectionally)
/// - [spouseOf]: fromId is the spouse of toId (stored bidirectionally)
enum EdgeType {
  parentOf('parent_of'),
  siblingOf('sibling_of'),
  spouseOf('spouse_of');

  final String value;
  const EdgeType(this.value);

  static EdgeType fromString(String value) {
    return EdgeType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EdgeType.parentOf, // Graceful fallback for unknown edge types
    );
  }
}

/// Family side for extended family disambiguation (paternal vs maternal).
///
/// Used when adding uncles/aunts to determine which parent they
/// are siblings of.
enum FamilySide {
  paternal('paternal'),
  maternal('maternal');

  final String value;
  const FamilySide(this.value);
}

/// A directed edge in the family graph.
///
/// Each edge connects two nodes (people) with a typed relationship.
/// Edges are scoped to a [userId] (the user who owns the graph).
///
/// Equality is based on [fromId], [toId], and [type] — not [id] —
/// because the same logical relationship should not be duplicated
/// regardless of the surrogate key.
class FamilyEdge {
  final String id;
  final String userId;
  final String fromId;
  final String toId;
  final EdgeType type;
  final DateTime createdAt;
  final String? familyGroupId;

  const FamilyEdge({
    required this.id,
    required this.userId,
    required this.fromId,
    required this.toId,
    required this.type,
    required this.createdAt,
    this.familyGroupId,
  });

  /// Create a new edge with a generated UUID.
  factory FamilyEdge.create({
    required String userId,
    required String fromId,
    required String toId,
    required EdgeType type,
    String? familyGroupId,
  }) {
    return FamilyEdge(
      id: const Uuid().v4(),
      userId: userId,
      fromId: fromId,
      toId: toId,
      type: type,
      createdAt: DateTime.now(),
      familyGroupId: familyGroupId,
    );
  }

  /// Create from Supabase JSON row.
  factory FamilyEdge.fromJson(Map<String, dynamic> json) {
    return FamilyEdge(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fromId: json['from_id'] as String,
      toId: json['to_id'] as String,
      type: EdgeType.fromString(json['edge_type'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      familyGroupId: json['family_group_id'] as String?,
    );
  }

  /// Convert to Supabase-compatible JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'from_id': fromId,
      'to_id': toId,
      'edge_type': type.value,
      'created_at': createdAt.toUtc().toIso8601String(),
      if (familyGroupId != null) 'family_group_id': familyGroupId,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FamilyEdge &&
        other.fromId == fromId &&
        other.toId == toId &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(fromId, toId, type);

  @override
  String toString() =>
      'FamilyEdge(${type.value}: $fromId -> $toId)';
}

/// The in-memory family graph built from a list of [FamilyEdge]s.
///
/// Provides O(1) lookups through forward and reverse adjacency maps.
/// All fields are final — the graph is immutable once constructed.
/// Use [FamilyGraphService.buildGraph] to create instances.
class FamilyGraph {
  /// The user who owns this graph. Generation levels are relative to this user.
  final String userId;

  /// Forward adjacency: fromId -> list of outgoing edges.
  final Map<String, List<FamilyEdge>> _adjacency;

  /// Reverse adjacency: toId -> list of incoming edges.
  final Map<String, List<FamilyEdge>> _reverseAdjacency;

  /// All edges in the graph (for iteration / serialisation).
  final List<FamilyEdge> edges;

  const FamilyGraph({
    required this.userId,
    required Map<String, List<FamilyEdge>> adjacency,
    required Map<String, List<FamilyEdge>> reverseAdjacency,
    required this.edges,
  })  : _adjacency = adjacency,
        _reverseAdjacency = reverseAdjacency;

  // ---------------------------------------------------------------------------
  // Query helpers
  // ---------------------------------------------------------------------------

  /// Get the parent IDs of [nodeId].
  ///
  /// A parent is someone who has a `parentOf` edge pointing **to** [nodeId].
  List<String> getParents(String nodeId) {
    final incoming = _reverseAdjacency[nodeId] ?? [];
    return incoming
        .where((e) => e.type == EdgeType.parentOf)
        .map((e) => e.fromId)
        .toList();
  }

  /// Get the child IDs of [nodeId].
  ///
  /// A child is someone that [nodeId] has a `parentOf` edge pointing **to**.
  List<String> getChildren(String nodeId) {
    final outgoing = _adjacency[nodeId] ?? [];
    return outgoing
        .where((e) => e.type == EdgeType.parentOf)
        .map((e) => e.toId)
        .toList();
  }

  /// Get the sibling IDs of [nodeId].
  ///
  /// Siblings are connected via `siblingOf` edges in either direction.
  List<String> getSiblings(String nodeId) {
    final siblings = <String>{};

    // Outgoing sibling edges
    final outgoing = _adjacency[nodeId] ?? [];
    for (final edge in outgoing) {
      if (edge.type == EdgeType.siblingOf) {
        siblings.add(edge.toId);
      }
    }

    // Incoming sibling edges
    final incoming = _reverseAdjacency[nodeId] ?? [];
    for (final edge in incoming) {
      if (edge.type == EdgeType.siblingOf) {
        siblings.add(edge.fromId);
      }
    }

    return siblings.toList();
  }

  /// Get the spouse ID of [nodeId], or `null` if none.
  ///
  /// Looks for `spouseOf` edges in either direction.
  String? getSpouse(String nodeId) {
    // Outgoing spouse edge
    final outgoing = _adjacency[nodeId] ?? [];
    for (final edge in outgoing) {
      if (edge.type == EdgeType.spouseOf) return edge.toId;
    }

    // Incoming spouse edge
    final incoming = _reverseAdjacency[nodeId] ?? [];
    for (final edge in incoming) {
      if (edge.type == EdgeType.spouseOf) return edge.fromId;
    }

    return null;
  }

  /// Compute the generation level of [nodeId] relative to [userId].
  ///
  /// - The user is generation 0.
  /// - Parents are -1, grandparents -2, etc.
  /// - Children are +1, grandchildren +2, etc.
  /// - Siblings share the same generation as the user (0).
  ///
  /// Uses BFS from [userId] to avoid infinite loops in malformed graphs.
  /// Returns 0 for unreachable nodes (defensive fallback).
  int getGeneration(String nodeId) {
    if (nodeId == userId) return 0;

    // BFS from userId
    final visited = <String>{};
    final queue = <_GenerationEntry>[_GenerationEntry(userId, 0)];
    visited.add(userId);

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);

      if (current.nodeId == nodeId) return current.generation;

      // Traverse parent edges: parent is generation - 1
      for (final parentId in getParents(current.nodeId)) {
        if (!visited.contains(parentId)) {
          visited.add(parentId);
          queue.add(_GenerationEntry(parentId, current.generation - 1));
        }
      }

      // Traverse child edges: child is generation + 1
      for (final childId in getChildren(current.nodeId)) {
        if (!visited.contains(childId)) {
          visited.add(childId);
          queue.add(_GenerationEntry(childId, current.generation + 1));
        }
      }

      // Traverse sibling edges: same generation
      for (final siblingId in getSiblings(current.nodeId)) {
        if (!visited.contains(siblingId)) {
          visited.add(siblingId);
          queue.add(_GenerationEntry(siblingId, current.generation));
        }
      }

      // Traverse spouse edges: same generation
      final spouseId = getSpouse(current.nodeId);
      if (spouseId != null && !visited.contains(spouseId)) {
        visited.add(spouseId);
        queue.add(_GenerationEntry(spouseId, current.generation));
      }
    }

    // Unreachable node — defensive fallback
    return 0;
  }

  /// Check whether a node exists in the graph (as either end of any edge).
  bool containsNode(String nodeId) {
    return _adjacency.containsKey(nodeId) ||
        _reverseAdjacency.containsKey(nodeId);
  }
}

/// Internal helper for BFS generation calculation.
class _GenerationEntry {
  final String nodeId;
  final int generation;

  const _GenerationEntry(this.nodeId, this.generation);
}
