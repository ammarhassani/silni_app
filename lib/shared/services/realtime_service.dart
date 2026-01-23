import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/services/app_logger_service.dart';

/// Real-time service for handling Supabase real-time subscriptions
/// This service manages subscriptions to database tables and provides
/// callbacks for when data changes occur
class RealtimeService {
  // Use lazy initialization to avoid accessing Supabase before it's initialized
  SupabaseClient get _supabase => SupabaseConfig.client;
  final AppLoggerService _logger = AppLoggerService();

  /// Subscribe to relatives table changes for a specific user
  RealtimeChannel subscribeToRelatives(
    String userId,
    void Function(PostgresChangePayload) callback,
  ) {
    _logger.info(
      'Setting up real-time subscription to relatives table',
      category: LogCategory.database,
      tag: 'RealtimeService',
      metadata: {'userId': userId},
    );

    final channel = _supabase
        .channel('relatives_changes_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'relatives',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            _logger.info(
              '🔄 REALTIME EVENT RECEIVED - Relatives table change',
              category: LogCategory.database,
              tag: 'RealtimeService',
              metadata: {
                'userId': userId,
                'eventType': payload.eventType.toString(),
                'oldRecord': payload.oldRecord,
                'newRecord': payload.newRecord,
                'timestamp': DateTime.now().toIso8601String(),
              },
            );

            // Enhanced logging for delete events
            if (payload.eventType == PostgresChangeEvent.delete) {
              _logger.warning(
                '🗑️ DELETE EVENT DETECTED - Realtime delete received',
                category: LogCategory.database,
                tag: 'RealtimeService',
                metadata: {
                  'userId': userId,
                  'deletedRecord': payload.oldRecord,
                  'deletedRelativeId': payload.oldRecord['id'],
                  'deletedRelativeName': payload.oldRecord['full_name'],
                  'timestamp': DateTime.now().toIso8601String(),
                },
              );
            }

            callback(payload);
          },
        );

    // Subscribe to the channel to establish connection
    _logger.info(
      '📡 SUBSCRIBING to real-time channel',
      category: LogCategory.database,
      tag: 'RealtimeService',
      metadata: {
        'channelName': 'relatives_changes_$userId',
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    channel.subscribe((status, [Object? error]) {
      _logger.info(
        '📡 REALTIME SUBSCRIPTION STATUS: $status',
        category: LogCategory.database,
        tag: 'RealtimeService',
        metadata: {
          'channelName': 'relatives_changes_$userId',
          'status': status.toString(),
          'userId': userId,
          'timestamp': DateTime.now().toIso8601String(),
          'error': error?.toString(),
        },
      );
    });

    return channel;
  }

  /// Subscribe to interactions table changes for a specific user
  RealtimeChannel subscribeToInteractions(
    String userId,
    void Function(PostgresChangePayload) callback,
  ) {
    _logger.info(
      'Setting up real-time subscription to interactions table',
      category: LogCategory.database,
      tag: 'RealtimeService',
      metadata: {'userId': userId},
    );

    final interactionsChannel = _supabase
        .channel('interactions_changes_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'interactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            _logger.debug(
              'Interactions table change received',
              category: LogCategory.database,
              tag: 'RealtimeService',
              metadata: {
                'userId': userId,
                'eventType': payload.eventType,
                'oldRecord': payload.oldRecord,
                'newRecord': payload.newRecord,
              },
            );
            callback(payload);
          },
        );

    // Subscribe to the channel to establish connection
    interactionsChannel.subscribe();

    return interactionsChannel;
  }

  /// Subscribe to user profile changes
  RealtimeChannel subscribeToUserProfile(
    String userId,
    void Function(PostgresChangePayload) callback,
  ) {
    _logger.info(
      'Setting up real-time subscription to user profile',
      category: LogCategory.database,
      tag: 'RealtimeService',
      metadata: {'userId': userId},
    );

    final userProfileChannel = _supabase
        .channel('user_profile_changes_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            _logger.debug(
              'User profile change received',
              category: LogCategory.database,
              tag: 'RealtimeService',
              metadata: {
                'userId': userId,
                'eventType': payload.eventType,
                'oldRecord': payload.oldRecord,
                'newRecord': payload.newRecord,
              },
            );
            callback(payload);
          },
        );

    // Subscribe to the channel to establish connection
    userProfileChannel.subscribe();

    return userProfileChannel;
  }

  /// Subscribe to reminder schedules changes for a specific user
  RealtimeChannel subscribeToReminderSchedules(
    String userId,
    void Function(PostgresChangePayload) callback,
  ) {
    _logger.info(
      'Setting up real-time subscription to reminder schedules table',
      category: LogCategory.database,
      tag: 'RealtimeService',
      metadata: {'userId': userId},
    );

    final reminderSchedulesChannel = _supabase
        .channel('reminder_schedules_changes_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'reminder_schedules',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            _logger.debug(
              'Reminder schedules table change received',
              category: LogCategory.database,
              tag: 'RealtimeService',
              metadata: {
                'userId': userId,
                'eventType': payload.eventType,
                'oldRecord': payload.oldRecord,
                'newRecord': payload.newRecord,
              },
            );
            callback(payload);
          },
        );

    // Subscribe to the channel to establish connection
    reminderSchedulesChannel.subscribe();

    return reminderSchedulesChannel;
  }

  /// Dispose all subscriptions
  void disposeAll() {
    _logger.info(
      'Disposing all real-time subscriptions',
      category: LogCategory.database,
      tag: 'RealtimeService',
    );

    // Unsubscribe from all channels
    _supabase.getChannels().forEach((channel) {
      _supabase.removeChannel(channel);
    });
  }

  /// Subscribe to a specific channel
  RealtimeChannel subscribe(String channelName) {
    _logger.info(
      'Subscribing to channel: $channelName',
      category: LogCategory.database,
      tag: 'RealtimeService',
    );

    return _supabase.channel(channelName);
  }

  /// Unsubscribe from a specific channel
  void unsubscribe(String channelName) {
    _logger.info(
      'Unsubscribing from channel: $channelName',
      category: LogCategory.database,
      tag: 'RealtimeService',
    );

    final channel = _supabase.channel(channelName);
    _supabase.removeChannel(channel);
  }
}
