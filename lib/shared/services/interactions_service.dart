import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/services/gamification_service.dart';
import '../models/interaction_model.dart';

class InteractionsService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final GamificationService? _gamificationService;
  static const String _table = 'interactions';

  InteractionsService({GamificationService? gamificationService})
      : _gamificationService = gamificationService;

  /// Create a new interaction
  /// Uses RPC function to atomically create interaction and update relative
  Future<String> createInteraction(Interaction interaction) async {
    try {
      if (kDebugMode) {
        print('📝 [INTERACTIONS] Creating ${interaction.type.arabicName} interaction');
      }

      // Insert interaction directly
      final response = await _supabase
          .from(_table)
          .insert(interaction.toJson())
          .select('id')
          .single();

      final id = response['id'] as String;

      // Update the relative's interaction count and last contact date
      await _supabase.rpc('record_interaction_and_update_relative', params: {
        'p_relative_id': interaction.relativeId,
        'p_user_id': interaction.userId,
      });

      if (kDebugMode) {
        print('✅ [INTERACTIONS] Created interaction with ID: $id');
      }

      // Process gamification (points, streaks, badges, levels)
      if (_gamificationService != null) {
        try {
          final gamificationResult = await _gamificationService.processInteractionGamification(
            userId: interaction.userId,
            interaction: interaction.copyWith(id: id),
          );

          if (kDebugMode) {
            print('🎮 [INTERACTIONS] Gamification processed: $gamificationResult');
          }
        } catch (e) {
          // Don't fail interaction creation if gamification fails
          if (kDebugMode) {
            print('⚠️ [INTERACTIONS] Gamification processing failed (non-critical): $e');
          }
        }
      }

      return id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [INTERACTIONS] Error creating interaction: $e');
      }
      rethrow;
    }
  }

  /// Get all interactions for a user
  Stream<List<Interaction>> getInteractionsStream(String userId) {
    try {
      if (kDebugMode) {
        print('📡 [INTERACTIONS] Streaming interactions for user: $userId');
      }

      return _supabase
          .from(_table)
          .stream(primaryKey: ['id'])
          .map((data) {
        // Filter for this user's interactions
        final filtered = data
            .where((json) => json['user_id'] == userId)
            .map((json) => Interaction.fromJson(json))
            .toList();

        // Sort by date descending (most recent first)
        filtered.sort((a, b) => b.date.compareTo(a.date));

        return filtered;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [INTERACTIONS] Error streaming interactions: $e');
      }
      rethrow;
    }
  }

  /// Get interactions for a specific relative
  Stream<List<Interaction>> getRelativeInteractionsStream(String relativeId) {
    try {
      return _supabase
          .from(_table)
          .stream(primaryKey: ['id'])
          .map((data) {
        // Filter for this relative's interactions
        final filtered = data
            .where((json) => json['relative_id'] == relativeId)
            .map((json) => Interaction.fromJson(json))
            .toList();

        // Sort by date descending (most recent first)
        filtered.sort((a, b) => b.date.compareTo(a.date));

        return filtered;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [INTERACTIONS] Error streaming relative interactions: $e');
      }
      rethrow;
    }
  }

  /// Get recent interactions (last N)
  Future<List<Interaction>> getRecentInteractions(String userId, {int limit = 10}) async {
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => Interaction.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ [INTERACTIONS] Error getting recent interactions: $e');
      }
      return [];
    }
  }

  /// Get interactions for today
  Stream<List<Interaction>> getTodayInteractionsStream(String userId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _supabase
        .from(_table)
        .stream(primaryKey: ['id'])
        .map((data) {
      // Filter for today's interactions for this user
      final filtered = data
          .where((json) {
            if (json['user_id'] != userId) return false;
            // Convert to local time for accurate comparison
            final date = DateTime.parse(json['date'] as String).toLocal();
            return date.isAfter(startOfDay) && date.isBefore(endOfDay);
          })
          .map((json) => Interaction.fromJson(json))
          .toList();

      // Sort by date descending (most recent first)
      filtered.sort((a, b) => b.date.compareTo(a.date));

      return filtered;
    });
  }

  /// Get interactions count for a date range
  Future<int> getInteractionsCount(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final response = await _supabase
          .from(_table)
          .select('id')
          .eq('user_id', userId)
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String());

      return (response as List).length;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [INTERACTIONS] Error counting interactions: $e');
      }
      return 0;
    }
  }

  /// Get interactions count by type for a user
  Future<Map<InteractionType, int>> getInteractionCountsByType(String userId) async {
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .eq('user_id', userId);

      final Map<InteractionType, int> counts = {};

      for (final json in (response as List)) {
        final interaction = Interaction.fromJson(json);
        counts[interaction.type] = (counts[interaction.type] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [INTERACTIONS] Error counting by type: $e');
      }
      return {};
    }
  }

  /// Update an interaction
  Future<void> updateInteraction(String interactionId, Map<String, dynamic> updates) async {
    try {
      if (kDebugMode) {
        print('📝 [INTERACTIONS] Updating interaction: $interactionId');
      }

      // Note: updated_at is automatically set by database trigger
      await _supabase
          .from(_table)
          .update(updates)
          .eq('id', interactionId);

      if (kDebugMode) {
        print('✅ [INTERACTIONS] Updated interaction: $interactionId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [INTERACTIONS] Error updating interaction: $e');
      }
      rethrow;
    }
  }

  /// Delete an interaction
  Future<void> deleteInteraction(String interactionId) async {
    try {
      if (kDebugMode) {
        print('🗑️ [INTERACTIONS] Deleting interaction: $interactionId');
      }

      await _supabase
          .from(_table)
          .delete()
          .eq('id', interactionId);

      if (kDebugMode) {
        print('✅ [INTERACTIONS] Deleted interaction: $interactionId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [INTERACTIONS] Error deleting interaction: $e');
      }
      rethrow;
    }
  }

  /// Check if user has interacted today (for streak calculation)
  Future<bool> hasInteractedToday(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final response = await _supabase
          .from(_table)
          .select('id')
          .eq('user_id', userId)
          .gte('date', startOfDay.toIso8601String())
          .lt('date', endOfDay.toIso8601String())
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [INTERACTIONS] Error checking today interaction: $e');
      }
      return false;
    }
  }

  /// Get total interactions count for a user
  Future<int> getTotalInteractionsCount(String userId) async {
    try {
      final response = await _supabase
          .from(_table)
          .select('id')
          .eq('user_id', userId);

      return (response as List).length;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [INTERACTIONS] Error getting total count: $e');
      }
      return 0;
    }
  }
}
