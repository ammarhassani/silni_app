import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/relative_model.dart';

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
      }

      return _supabase
          .from(_table)
          .stream(primaryKey: ['id'])
          .map((data) {
        if (kDebugMode) {
          print('📊 [RELATIVES] Received ${data.length} total relatives from Supabase');
        }

        // Filter for this user's non-archived relatives
        final filtered = data
            .where((json) =>
                json['user_id'] == userId &&
                json['is_archived'] == false)
            .map((json) => Relative.fromJson(json))
            .toList();

        // Sort by priority (ascending), then by full_name (ascending)
        filtered.sort((a, b) {
          final priorityCompare = a.priority.compareTo(b.priority);
          if (priorityCompare != 0) return priorityCompare;
          return a.fullName.compareTo(b.fullName);
        });

        if (kDebugMode) {
          print('📊 [RELATIVES] Filtered to ${filtered.length} relatives for user');
        }

        return filtered;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [RELATIVES] Error streaming relatives: $e');
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
  Future<void> updateRelative(String relativeId, Map<String, dynamic> updates) async {
    try {
      if (kDebugMode) {
        print('📝 [RELATIVES] Updating relative: $relativeId');
      }

      // Note: updated_at is automatically set by database trigger
      await _supabase
          .from(_table)
          .update(updates)
          .eq('id', relativeId);

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
      await _supabase.rpc('record_interaction_and_update_relative', params: {
        'p_relative_id': relativeId,
        'p_interaction_data': null, // null means only update relative, no interaction record
      });

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
    return _supabase
        .from(_table)
        .stream(primaryKey: ['id'])
        .map((data) {
      // Filter for this user's favorite non-archived relatives
      return data
          .where((json) =>
              json['user_id'] == userId &&
              json['is_favorite'] == true &&
              json['is_archived'] == false)
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
