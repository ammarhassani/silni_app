import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/relative_model.dart';

/// Provider for the Relatives service
final relativesServiceProvider = Provider<RelativesService>((ref) {
  return RelativesService();
});

class RelativesService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  static const String _table = 'relatives';

  /// Create a new relative
  Future<String> createRelative(Relative relative) async {
    try {
      if (kDebugMode) {
        print('📝 [RELATIVES] Creating relative: ${relative.fullName}');
      }

      final response = await _supabase
          .from(_table)
          .insert(relative.toJson())
          .select('id')
          .single();

      final id = response['id'] as String;

      if (kDebugMode) {
        print('✅ [RELATIVES] Created relative with ID: $id');
      }

      return id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [RELATIVES] Error creating relative: $e');
      }
      rethrow;
    }
  }

  /// Get all relatives for a user
  Stream<List<Relative>> getRelativesStream(String userId) {
    try {
      if (kDebugMode) {
        print('📡 [RELATIVES] Streaming relatives for user: $userId');
        print(
          '📡 [RELATIVES] Stream created at: ${DateTime.now().toIso8601String()}',
        );
      }

      return _supabase.from(_table).stream(primaryKey: ['id']).map((data) {
        if (kDebugMode) {
          print(
            '📊 [RELATIVES] Raw data received: ${data.length} total records from Supabase',
          );
          print(
            '📊 [RELATIVES] Stream update timestamp: ${DateTime.now().toIso8601String()}',
          );

          // Log all record IDs for debugging
          final allIds = data
              .map((json) => json['id'] as String?)
              .where((id) => id != null)
              .toList();
          print('📊 [RELATIVES] All record IDs in stream: $allIds');

          // Log archived status
          final archivedCount = data
              .where((json) => json['is_archived'] == true)
              .length;
          final userCount = data
              .where((json) => json['user_id'] == userId)
              .length;
          print(
            '📊 [RELATIVES] Archived records: $archivedCount, User records: $userCount',
          );
        }

        // Filter for this user's non-archived relatives
        final filtered = data
            .where(
              (json) =>
                  json['user_id'] == userId && json['is_archived'] == false,
            )
            .map((json) => Relative.fromJson(json))
            .toList();

        // Sort by priority (ascending), then by full_name (ascending)
        filtered.sort((a, b) {
          final priorityCompare = a.priority.compareTo(b.priority);
          if (priorityCompare != 0) return priorityCompare;
          return a.fullName.compareTo(b.fullName);
        });

        if (kDebugMode) {
          print(
            '📊 [RELATIVES] Filtered to ${filtered.length} active relatives for user $userId',
          );

          // Log filtered relative names and IDs
          final filteredInfo = filtered
              .map((r) => '${r.fullName} (${r.id})')
              .toList();
          print('📊 [RELATIVES] Filtered relatives: $filteredInfo');

          print(
            '📊 [RELATIVES] Stream processing completed at: ${DateTime.now().toIso8601String()}',
          );
        }

        return filtered;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [RELATIVES] Error streaming relatives: $e');
        print(
          '❌ [RELATIVES] Error timestamp: ${DateTime.now().toIso8601String()}',
        );
      }
      rethrow;
    }
  }

  /// Get a single relative by ID
  Future<Relative?> getRelative(String relativeId) async {
    try {
      if (kDebugMode) {
        print('📖 [RELATIVES] Fetching relative: $relativeId');
      }

      final response = await _supabase
          .from(_table)
          .select()
          .eq('id', relativeId)
          .maybeSingle();

      if (response == null) {
        if (kDebugMode) {
          print('⚠️ [RELATIVES] Relative not found: $relativeId');
        }
        return null;
      }

      return Relative.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ [RELATIVES] Error fetching relative: $e');
      }
      rethrow;
    }
  }

  /// Get a single relative by ID as stream (for real-time updates)
  Stream<Relative?> getRelativeStream(String relativeId) {
    try {
      if (kDebugMode) {
        print('📡 [RELATIVES] Streaming relative: $relativeId');
      }

      return _supabase
          .from(_table)
          .stream(primaryKey: ['id'])
          .eq('id', relativeId)
          .map((data) {
            if (data.isEmpty) {
              if (kDebugMode) {
                print('⚠️ [RELATIVES] Relative not found: $relativeId');
              }
              return null;
            }
            return Relative.fromJson(data.first);
          });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [RELATIVES] Error streaming relative: $e');
      }
      rethrow;
    }
  }

  /// Update a relative
  Future<void> updateRelative(
    String relativeId,
    Map<String, dynamic> updates,
  ) async {
    try {
      if (kDebugMode) {
        print('📝 [RELATIVES] Updating relative: $relativeId');
      }

      // Note: updated_at is automatically set by database trigger
      await _supabase.from(_table).update(updates).eq('id', relativeId);

      if (kDebugMode) {
        print('✅ [RELATIVES] Updated relative: $relativeId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [RELATIVES] Error updating relative: $e');
      }
      rethrow;
    }
  }

  /// Delete (archive) a relative
  Future<void> deleteRelative(String relativeId) async {
    try {
      if (kDebugMode) {
        print('🗑️ [RELATIVES] Archiving relative: $relativeId');
      }

      await _supabase
          .from(_table)
          .update({
            'is_archived': true,
            // updated_at handled by trigger
          })
          .eq('id', relativeId);

      if (kDebugMode) {
        print('✅ [RELATIVES] Archived relative: $relativeId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [RELATIVES] Error archiving relative: $e');
      }
      rethrow;
    }
  }

  /// Permanently delete a relative
  Future<void> permanentlyDeleteRelative(String relativeId) async {
    try {
      if (kDebugMode) {
        print('🗑️ [RELATIVES] Permanently deleting relative: $relativeId');
        print(
          '🗑️ [RELATIVES] Delete operation started at: ${DateTime.now().toIso8601String()}',
        );
      }

      // First, get the relative info before deletion for logging
      final relativeInfo = await getRelative(relativeId);
      if (kDebugMode && relativeInfo != null) {
        print(
          '🗑️ [RELATIVES] Deleting relative: ${relativeInfo.fullName} (${relativeInfo.id})',
        );
      }

      // First, delete all interactions for this relative
      if (kDebugMode) {
        print(
          '🗑️ [RELATIVES] Deleting interactions for relative: $relativeId',
        );
      }
      await _supabase
          .from('interactions')
          .delete()
          .eq('relative_id', relativeId);

      // Then delete the relative
      if (kDebugMode) {
        print('🗑️ [RELATIVES] Deleting relative record: $relativeId');
      }
      await _supabase.from(_table).delete().eq('id', relativeId);

      if (kDebugMode) {
        print('✅ [RELATIVES] Permanently deleted relative: $relativeId');
        print(
          '✅ [RELATIVES] Delete operation completed at: ${DateTime.now().toIso8601String()}',
        );
        print('✅ [RELATIVES] Real-time update should trigger automatically');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [RELATIVES] Error permanently deleting relative: $e');
        print(
          '❌ [RELATIVES] Error timestamp: ${DateTime.now().toIso8601String()}',
        );
      }
      rethrow;
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String relativeId, bool isFavorite) async {
    try {
      await _supabase
          .from(_table)
          .update({
            'is_favorite': isFavorite,
            // updated_at handled by trigger
          })
          .eq('id', relativeId);

      if (kDebugMode) {
        print('⭐ [RELATIVES] Toggled favorite for $relativeId: $isFavorite');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [RELATIVES] Error toggling favorite: $e');
      }
      rethrow;
    }
  }

  /// Increment interaction count and update last contact date
  /// Uses the database RPC function for atomic increment
  Future<void> recordInteraction(String relativeId) async {
    try {
      await _supabase.rpc(
        'record_interaction_and_update_relative',
        params: {
          'p_relative_id': relativeId,
          'p_interaction_data':
              null, // null means only update relative, no interaction record
        },
      );

      if (kDebugMode) {
        print('📊 [RELATIVES] Recorded interaction for: $relativeId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [RELATIVES] Error recording interaction: $e');
      }
      rethrow;
    }
  }

  /// Get relatives that need contact (based on priority)
  Stream<List<Relative>> getRelativesNeedingContact(String userId) {
    return getRelativesStream(userId).map((relatives) {
      return relatives.where((relative) => relative.needsContact).toList();
    });
  }

  /// Get favorite relatives
  Stream<List<Relative>> getFavoriteRelatives(String userId) {
    return _supabase.from(_table).stream(primaryKey: ['id']).map((data) {
      // Filter for this user's favorite non-archived relatives
      return data
          .where(
            (json) =>
                json['user_id'] == userId &&
                json['is_favorite'] == true &&
                json['is_archived'] == false,
          )
          .map((json) => Relative.fromJson(json))
          .toList();
    });
  }

  /// Search relatives by name
  Stream<List<Relative>> searchRelatives(String userId, String query) {
    return getRelativesStream(userId).map((relatives) {
      if (query.isEmpty) return relatives;
      return relatives.where((relative) {
        return relative.fullName.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  /// Get relatives count
  Future<int> getRelativesCount(String userId) async {
    try {
      final response = await _supabase
          .from(_table)
          .select('id')
          .eq('user_id', userId)
          .eq('is_archived', false);

      return (response as List).length;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [RELATIVES] Error counting relatives: $e');
      }
      return 0;
    }
  }
}
