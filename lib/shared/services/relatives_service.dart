import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/services/app_logger_service.dart';
import '../../core/services/performance_monitoring_service.dart';
import '../../core/utils/retry_helper.dart';
import '../models/relative_model.dart';

/// Provider for the Relatives service
final relativesServiceProvider = Provider<RelativesService>((ref) {
  return RelativesService();
});

/// Result of a paginated relatives query
class PaginatedRelativesResult {
  final List<Relative> relatives;
  final int totalCount;
  final bool hasMore;
  final int currentOffset;

  const PaginatedRelativesResult({
    required this.relatives,
    required this.totalCount,
    required this.hasMore,
    required this.currentOffset,
  });

  /// Next offset for pagination
  int get nextOffset => currentOffset + relatives.length;
}

class RelativesService {
  // Use lazy initialization to avoid accessing Supabase before it's initialized
  SupabaseClient get _supabase => SupabaseConfig.client;
  final AppLoggerService _logger = AppLoggerService();
  final PerformanceMonitoringService _perfService = PerformanceMonitoringService();
  static const String _table = 'relatives';

  /// Check if an error is retryable
  bool _isRetryable(Exception e) {
    return e is SocketException ||
        e is TimeoutException ||
        e.toString().contains('network') ||
        e.toString().contains('connection') ||
        e.toString().contains('timeout');
  }

  /// Create a new relative
  Future<String> createRelative(Relative relative) async {
    return _perfService.measureDatabaseOperation(
      'insert',
      _table,
      () => RetryHelper.withExponentialBackoff(
        operation: () async {
          final response = await _supabase
              .from(_table)
              .insert(relative.toJson())
              .select('id')
              .single();

          _logger.info(
            'Created relative successfully',
            category: LogCategory.database,
            tag: 'RelativesService',
            metadata: {'relativeId': response['id']},
          );

          return response['id'] as String;
        },
        maxAttempts: 3,
        shouldRetry: _isRetryable,
        onRetry: (attempt, delay, error) {
          _logger.warning(
            'Retrying createRelative (attempt $attempt)',
            category: LogCategory.database,
            tag: 'RelativesService',
            metadata: {'error': error.toString()},
          );
        },
      ),
    );
  }

  /// Get all relatives for a user
  Stream<List<Relative>> getRelativesStream(String userId) {
    try {
      return _supabase.from(_table).stream(primaryKey: ['id']).map((data) {
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

        return filtered;
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get paginated relatives for a user
  /// Returns a page of relatives with cursor-based pagination for 10K+ scale
  Future<PaginatedRelativesResult> getRelativesPaginated({
    required String userId,
    int pageSize = 20,
    int offset = 0,
    String? searchQuery,
  }) async {
    return _perfService.measureDatabaseOperation(
      'select_paginated',
      _table,
      () async {
        try {
          var query = _supabase
              .from(_table)
              .select()
              .eq('user_id', userId)
              .eq('is_archived', false);

          // Add search filter if provided
          if (searchQuery != null && searchQuery.isNotEmpty) {
            query = query.ilike('full_name', '%$searchQuery%');
          }

          // Get total count for pagination info
          final countResponse = await _supabase
              .from(_table)
              .select()
              .eq('user_id', userId)
              .eq('is_archived', false)
              .count();

          final totalCount = countResponse.count;

          // Get paginated data with sorting
          final response = await query
              .order('priority', ascending: true)
              .order('full_name', ascending: true)
              .range(offset, offset + pageSize - 1);

          final relatives = (response as List)
              .map((json) => Relative.fromJson(json))
              .toList();

          final hasMore = offset + relatives.length < totalCount;

          _logger.debug(
            'Fetched paginated relatives',
            category: LogCategory.database,
            tag: 'RelativesService',
            metadata: {
              'offset': offset,
              'pageSize': pageSize,
              'fetched': relatives.length,
              'totalCount': totalCount,
              'hasMore': hasMore,
            },
          );

          return PaginatedRelativesResult(
            relatives: relatives,
            totalCount: totalCount,
            hasMore: hasMore,
            currentOffset: offset,
          );
        } catch (e) {
          _logger.error(
            'Failed to fetch paginated relatives',
            category: LogCategory.database,
            tag: 'RelativesService',
            metadata: {'error': e.toString()},
          );
          rethrow;
        }
      },
    );
  }

  /// Get a single relative by ID
  Future<Relative?> getRelative(String relativeId) async {
    return _perfService.measureDatabaseOperation(
      'select',
      _table,
      () async {
        try {
          final response = await _supabase
              .from(_table)
              .select()
              .eq('id', relativeId)
              .maybeSingle();

          if (response == null) {
            return null;
          }

          return Relative.fromJson(response);
        } catch (e) {
          rethrow;
        }
      },
    );
  }

  /// Get a single relative by ID as stream (for real-time updates)
  Stream<Relative?> getRelativeStream(String relativeId) {
    try {
      return _supabase
          .from(_table)
          .stream(primaryKey: ['id'])
          .eq('id', relativeId)
          .map((data) {
            if (data.isEmpty) {
              return null;
            }
            return Relative.fromJson(data.first);
          });
    } catch (e) {
      rethrow;
    }
  }

  /// Update a relative
  Future<void> updateRelative(
    String relativeId,
    Map<String, dynamic> updates,
  ) async {
    return _perfService.measureDatabaseOperation(
      'update',
      _table,
      () => RetryHelper.withExponentialBackoff(
        operation: () async {
          // Note: updated_at is automatically set by database trigger
          await _supabase.from(_table).update(updates).eq('id', relativeId);

          _logger.info(
            'Updated relative successfully',
            category: LogCategory.database,
            tag: 'RelativesService',
            metadata: {'relativeId': relativeId, 'updates': updates.keys.toList()},
          );
        },
        maxAttempts: 3,
        shouldRetry: _isRetryable,
        onRetry: (attempt, delay, error) {
          _logger.warning(
            'Retrying updateRelative (attempt $attempt)',
            category: LogCategory.database,
            tag: 'RelativesService',
            metadata: {'relativeId': relativeId, 'error': error.toString()},
          );
        },
      ),
    );
  }

  /// Delete (archive) a relative
  Future<void> deleteRelative(String relativeId) async {
    return RetryHelper.withExponentialBackoff(
      operation: () async {
        await _supabase
            .from(_table)
            .update({
              'is_archived': true,
              // updated_at handled by trigger
            })
            .eq('id', relativeId);

        _logger.info(
          'Archived relative successfully',
          category: LogCategory.database,
          tag: 'RelativesService',
          metadata: {'relativeId': relativeId},
        );
      },
      maxAttempts: 3,
      shouldRetry: _isRetryable,
      onRetry: (attempt, delay, error) {
        _logger.warning(
          'Retrying deleteRelative (attempt $attempt)',
          category: LogCategory.database,
          tag: 'RelativesService',
          metadata: {'relativeId': relativeId, 'error': error.toString()},
        );
      },
    );
  }

  /// Permanently delete a relative
  Future<void> permanentlyDeleteRelative(String relativeId) async {
    try {
      // First, delete all interactions for this relative
      await _supabase
          .from('interactions')
          .delete()
          .eq('relative_id', relativeId);

      // Then delete the relative
      await _supabase.from(_table).delete().eq('id', relativeId);
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
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
      return 0;
    }
  }
}
