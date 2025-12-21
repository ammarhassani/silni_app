import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/services/gamification_service.dart';
import '../../core/services/app_logger_service.dart';
import '../models/interaction_model.dart';

class InteractionsService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final GamificationService? _gamificationService;
  final AppLoggerService _logger = AppLoggerService();
  static const String _table = 'interactions';

  InteractionsService({GamificationService? gamificationService})
    : _gamificationService = gamificationService;

  /// Create a new interaction
  /// Uses RPC function to atomically create interaction and update relative
  Future<String> createInteraction(Interaction interaction) async {
    try {
      // Insert interaction directly
      final response = await _supabase
          .from(_table)
          .insert(interaction.toJson())
          .select('id')
          .single();

      final id = response['id'] as String;

      // Update the relative's interaction count and last contact date
      await _supabase.rpc(
        'record_interaction_and_update_relative',
        params: {
          'p_relative_id': interaction.relativeId,
          'p_user_id': interaction.userId,
        },
      );

      // Process gamification (points, streaks, badges, levels)
      if (_gamificationService != null) {
        try {
          await _gamificationService.processInteractionGamification(
            userId: interaction.userId,
            interaction: interaction.copyWith(id: id),
          );
        } catch (e) {
          // Don't fail interaction creation if gamification fails, but log it
          _logger.warning(
            'Gamification processing failed',
            category: LogCategory.gamification,
            tag: 'InteractionsService',
            metadata: {'userId': interaction.userId, 'error': e.toString()},
          );
        }
      }

      return id;
    } catch (e) {
      _logger.error(
        'Error creating interaction: $e',
        category: LogCategory.database,
        tag: 'InteractionsService',
      );
      rethrow;
    }
  }

  /// Get all interactions for a user
  Stream<List<Interaction>> getInteractionsStream(String userId) {
    return _supabase.from(_table).stream(primaryKey: ['id']).map((data) {
      // Filter for this user's interactions
      final filtered = data
          .where((json) => json['user_id'] == userId)
          .map((json) => Interaction.fromJson(json))
          .toList();

      // Sort by date descending (most recent first)
      filtered.sort((a, b) => b.date.compareTo(a.date));

      return filtered;
    });
  }

  /// Get interactions for a specific relative
  Stream<List<Interaction>> getRelativeInteractionsStream(String relativeId) {
    return _supabase.from(_table).stream(primaryKey: ['id']).map((data) {
      // Filter for this relative's interactions
      final filtered = data
          .where((json) => json['relative_id'] == relativeId)
          .map((json) => Interaction.fromJson(json))
          .toList();

      // Sort by date descending (most recent first)
      filtered.sort((a, b) => b.date.compareTo(a.date));

      return filtered;
    });
  }

  /// Get recent interactions (last N)
  Future<List<Interaction>> getRecentInteractions(
    String userId, {
    int limit = 10,
  }) async {
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
      return [];
    }
  }

  /// Get interactions for today
  Stream<List<Interaction>> getTodayInteractionsStream(String userId) {
    return _supabase.from(_table).stream(primaryKey: ['id']).map((data) {
      // Filter for today's interactions for this user
      final filtered = data
          .where((json) {
            if (json['user_id'] != userId) return false;

            // Parse the date and convert to local timezone
            final utcDate = DateTime.parse(json['date'] as String);
            final localDate = utcDate.toLocal();

            // Get today's date in local timezone
            final now = DateTime.now();
            final localToday = DateTime(now.year, now.month, now.day);
            final startOfLocalToday = localToday;
            final endOfLocalToday = localToday.add(const Duration(days: 1));

            // Check if the interaction date is within today's local date range
            return localDate.isAfter(startOfLocalToday) &&
                localDate.isBefore(endOfLocalToday);
          })
          .map((json) {
            // Create Interaction with proper local timezone handling
            final interactionJson = Map<String, dynamic>.from(json);
            final utcDate = DateTime.parse(json['date'] as String);
            final localDate = utcDate.toLocal();

            // Update the date in the JSON to local time
            interactionJson['date'] = localDate.toIso8601String();

            return Interaction.fromJson(interactionJson);
          })
          .toList();

      // Sort by date descending (most recent first)
      filtered.sort((a, b) => b.date.compareTo(a.date));

      return filtered;
    });
  }

  /// Get interactions count for a date range
  Future<int> getInteractionsCount(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase
          .from(_table)
          .select('id')
          .eq('user_id', userId)
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String());

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Get interactions count by type for a user
  Future<Map<InteractionType, int>> getInteractionCountsByType(
    String userId,
  ) async {
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
      return {};
    }
  }

  /// Update an interaction
  Future<void> updateInteraction(
    String interactionId,
    Map<String, dynamic> updates,
  ) async {
    try {
      // Note: updated_at is automatically set by database trigger
      await _supabase.from(_table).update(updates).eq('id', interactionId);
    } catch (e) {
      _logger.error(
        'Error updating interaction: $e',
        category: LogCategory.database,
        tag: 'InteractionsService',
        metadata: {'interactionId': interactionId},
      );
      rethrow;
    }
  }

  /// Delete an interaction
  Future<void> deleteInteraction(String interactionId) async {
    try {
      await _supabase.from(_table).delete().eq('id', interactionId);
    } catch (e) {
      _logger.error(
        'Error deleting interaction: $e',
        category: LogCategory.database,
        tag: 'InteractionsService',
        metadata: {'interactionId': interactionId},
      );
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
      return 0;
    }
  }
}
