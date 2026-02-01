import 'package:silni_app/core/config/supabase_config.dart';
import 'package:silni_app/shared/models/relative_model.dart';

/// Service for shared family tree operations.
///
/// When a family group member adds a relative to the shared tree,
/// it becomes visible to all group members. Follows the project
/// convention of private constructor + static methods.
class SharedTreeService {
  SharedTreeService._();

  /// Add a relative to a shared family tree.
  ///
  /// Sets [familyGroupId] and [addedBy] on the relative so it
  /// appears for every member in the group.
  static Future<String> addSharedRelative({
    required Relative relative,
    required String familyGroupId,
    required String userId,
  }) async {
    final client = SupabaseConfig.client;
    final json = relative.toJson();
    json['family_group_id'] = familyGroupId;
    json['added_by'] = userId;

    final response = await client
        .from('relatives')
        .insert(json)
        .select('id')
        .single();

    return response['id'] as String;
  }

  /// Get all shared relatives for a family group.
  static Future<List<Relative>> getSharedRelatives(String groupId) async {
    final client = SupabaseConfig.client;
    final data = await client
        .from('relatives')
        .select()
        .eq('family_group_id', groupId)
        .eq('is_archived', false)
        .order('full_name');

    return data.map((json) => Relative.fromJson(json)).toList();
  }

  /// Stream shared relatives for real-time updates.
  ///
  /// Supabase stream API only supports a single `.eq()` filter,
  /// so `is_archived` is filtered client-side.
  static Stream<List<Relative>> watchSharedRelatives(String groupId) {
    return SupabaseConfig.client
        .from('relatives')
        .stream(primaryKey: ['id'])
        .eq('family_group_id', groupId)
        .map((data) => data
            .where((json) => json['is_archived'] == false)
            .map((json) => Relative.fromJson(json))
            .toList()
          ..sort((a, b) => a.fullName.compareTo(b.fullName)));
  }
}
