import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/services/realtime_service.dart';
import '../../shared/services/relatives_service.dart';
import '../../core/services/app_logger_service.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/home/providers/home_providers.dart';
import '../../shared/providers/interactions_provider.dart';

/// Provider for the real-time service
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  return RealtimeService();
});

/// Provider to manage real-time subscriptions state
class RealtimeSubscriptionsNotifier
    extends StateNotifier<Map<String, RealtimeChannel>> {
  final RealtimeService _realtimeService;
  final AppLoggerService _logger;
  final Ref _ref;

  RealtimeSubscriptionsNotifier(this._realtimeService, this._logger, this._ref)
    : super({});

  /// Subscribe to all real-time updates for the current user
  Future<void> subscribeToUserUpdates(String userId) async {
    _logger.info(
      'Setting up real-time subscriptions for user',
      category: LogCategory.database,
      tag: 'RealtimeSubscriptionsNotifier',
      metadata: {'userId': userId},
    );

    try {
      // Subscribe to relatives changes
      final relativesChannel = _realtimeService.subscribeToRelatives(userId, (
        payload,
      ) {
        _logger.info(
          '🔄 RELATIVES CHANGE DETECTED - Realtime event received',
          category: LogCategory.database,
          tag: 'RealtimeSubscriptionsNotifier',
          metadata: {
            'userId': userId,
            'eventType': payload.eventType.toString(),
            'oldRecord': payload.oldRecord,
            'newRecord': payload.newRecord,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        // Enhanced logging for delete operations
        if (payload.eventType == PostgresChangeEvent.delete) {
          _logger.warning(
            '🗑️ DELETE EVENT DETECTED - Relative deleted',
            category: LogCategory.database,
            tag: 'RealtimeSubscriptionsNotifier',
            metadata: {
              'userId': userId,
              'deletedRecord': payload.oldRecord,
              'relativeId': payload.oldRecord['id'],
              'relativeName': payload.oldRecord['full_name'],
            },
          );
        }

        // Log before invalidation
        _logger.info(
          '🔄 INVALIDATING PROVIDERS - About to invalidate relatives providers',
          category: LogCategory.database,
          tag: 'RealtimeSubscriptionsNotifier',
          metadata: {
            'userId': userId,
            'providerToInvalidate': 'relativesStreamProvider($userId)',
          },
        );

        // Invalidate all relatives-related providers to trigger UI refresh
        // We need to invalidate the stream provider for the specific user
        _ref.invalidate(relativesStreamProvider(userId));

        // Also invalidate the service provider
        _ref.invalidate(relativesServiceProvider);

        _logger.info(
          '✅ PROVIDERS INVALIDATED - Relatives provider invalidated successfully',
          category: LogCategory.database,
          tag: 'RealtimeSubscriptionsNotifier',
          metadata: {
            'userId': userId,
            'eventType': payload.eventType.toString(),
            'invalidationCompleted': true,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      });

      // Subscribe to interactions changes
      final interactionsChannel = _realtimeService.subscribeToInteractions(
        userId,
        (payload) {
          _logger.info(
            'Interactions change detected, invalidating interactions provider',
            category: LogCategory.database,
            tag: 'RealtimeSubscriptionsNotifier',
            metadata: {'userId': userId, 'eventType': payload.eventType},
          );

          // Invalidate the interactions stream provider to trigger UI refresh
          _ref.invalidate(todayInteractionsStreamProvider(userId));

          // Invalidate today contacted relatives provider for home screen checkmarks
          _ref.invalidate(todayContactedRelativesProvider(userId));

          // Note: todayDueRelativesProvider is a pure derived provider that takes
          // schedules and relatives as parameters. It will automatically update
          // when the parent providers (relativesStreamProvider, reminderSchedulesStreamProvider)
          // are invalidated and widgets re-read fresh data.

          // Also invalidate the service provider
          _ref.invalidate(interactionsServiceProvider);

          _logger.info(
            'Interactions provider invalidated - UI should refresh immediately',
            category: LogCategory.database,
            tag: 'RealtimeSubscriptionsNotifier',
            metadata: {'userId': userId, 'eventType': payload.eventType},
          );
        },
      );

      // Subscribe to user profile changes
      final userProfileChannel = _realtimeService.subscribeToUserProfile(
        userId,
        (payload) {
          _logger.info(
            'User profile change detected, invalidating auth provider',
            category: LogCategory.database,
            tag: 'RealtimeSubscriptionsNotifier',
            metadata: {'userId': userId, 'eventType': payload.eventType},
          );

          // Log the change for debugging - UI will refresh on next rebuild
          _logger.info(
            'User profile changed - UI should refresh on next interaction',
            category: LogCategory.database,
            tag: 'RealtimeSubscriptionsNotifier',
            metadata: {'userId': userId, 'eventType': payload.eventType},
          );
        },
      );

      // Subscribe to reminder schedules changes
      final reminderSchedulesChannel = _realtimeService.subscribeToReminderSchedules(
        userId,
        (payload) {
          _logger.info(
            'Reminder schedules change detected, invalidating reminder provider',
            category: LogCategory.database,
            tag: 'RealtimeSubscriptionsNotifier',
            metadata: {'userId': userId, 'eventType': payload.eventType},
          );

          // Invalidate the reminder schedules service provider to trigger UI refresh
          _ref.invalidate(reminderSchedulesStreamProvider(userId));

          _logger.info(
            'Reminder schedules provider invalidated - UI should refresh immediately',
            category: LogCategory.database,
            tag: 'RealtimeSubscriptionsNotifier',
            metadata: {'userId': userId, 'eventType': payload.eventType},
          );
        },
      );

      // Store all channels in state
      state = {
        'relatives': relativesChannel,
        'interactions': interactionsChannel,
        'userProfile': userProfileChannel,
        'reminderSchedules': reminderSchedulesChannel,
      };

      _logger.info(
        'All real-time subscriptions set up successfully',
        category: LogCategory.database,
        tag: 'RealtimeSubscriptionsNotifier',
        metadata: {'userId': userId, 'subscriptionCount': state.length},
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to set up real-time subscriptions: ${e.toString()}',
        category: LogCategory.database,
        tag: 'RealtimeSubscriptionsNotifier',
        metadata: {
          'userId': userId,
          'error': e.toString(),
          'stackTrace': stackTrace.toString(),
        },
      );
    }
  }

  /// Unsubscribe from all real-time updates
  void unsubscribeFromAll() {
    _logger.info(
      'Unsubscribing from all real-time updates',
      category: LogCategory.database,
      tag: 'RealtimeSubscriptionsNotifier',
      metadata: {'subscriptionCount': state.length},
    );

    // Dispose all subscriptions
    _realtimeService.disposeAll();

    // Clear state
    state = {};
  }

  /// Subscribe to a specific table for the current user
  void subscribeToTable(
    String tableName,
    String userId,
    void Function(PostgresChangePayload) callback,
  ) {
    _logger.info(
      'Setting up real-time subscription to table: $tableName',
      category: LogCategory.database,
      tag: 'RealtimeSubscriptionsNotifier',
      metadata: {'tableName': tableName, 'userId': userId},
    );

    try {
      RealtimeChannel channel;

      switch (tableName) {
        case 'relatives':
          channel = _realtimeService.subscribeToRelatives(userId, callback);
          break;
        case 'interactions':
          channel = _realtimeService.subscribeToInteractions(userId, callback);
          break;
        case 'users':
          channel = _realtimeService.subscribeToUserProfile(userId, callback);
          break;
        case 'reminder_schedules':
          channel = _realtimeService.subscribeToReminderSchedules(
            userId,
            callback,
          );
          break;
        default:
          _logger.warning(
            'Unknown table for real-time subscription: $tableName',
            category: LogCategory.database,
            tag: 'RealtimeSubscriptionsNotifier',
          );
          return;
      }

      // Add channel to state
      state = {...state, tableName: channel};

      _logger.info(
        'Real-time subscription set up successfully',
        category: LogCategory.database,
        tag: 'RealtimeSubscriptionsNotifier',
        metadata: {'tableName': tableName, 'userId': userId},
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to set up real-time subscription to table: $tableName - ${e.toString()}',
        category: LogCategory.database,
        tag: 'RealtimeSubscriptionsNotifier',
        metadata: {
          'tableName': tableName,
          'userId': userId,
          'error': e.toString(),
          'stackTrace': stackTrace.toString(),
        },
      );
    }
  }

  @override
  void dispose() {
    unsubscribeFromAll();
    super.dispose();
  }
}

/// Provider for real-time subscriptions management
final realtimeSubscriptionsProvider =
    StateNotifierProvider<
      RealtimeSubscriptionsNotifier,
      Map<String, RealtimeChannel>
    >((ref) {
      final realtimeService = ref.watch(realtimeServiceProvider);
      final logger = AppLoggerService();

      return RealtimeSubscriptionsNotifier(realtimeService, logger, ref);
    });

/// Provider to automatically manage real-time subscriptions based on auth state
final autoRealtimeSubscriptionsProvider = Provider<void>((ref) {
  final authState = ref.watch(authStateProvider);
  final logger = AppLoggerService();

  logger.info(
    'Auto real-time subscriptions provider checking auth state',
    category: LogCategory.database,
    tag: 'AutoRealtimeSubscriptions',
    metadata: {
      'isAuthenticated': authState.value != null,
      'userId': authState.value?.id,
    },
  );

  // When auth state changes, update subscriptions
  ref.listen(authStateProvider, (previous, next) {
    logger.info(
      'Auth state changed, updating real-time subscriptions',
      category: LogCategory.database,
      tag: 'AutoRealtimeSubscriptions',
      metadata: {
        'previousHasUser': previous?.value != null,
        'nextHasUser': next.value != null,
        'userId': next.value?.id,
      },
    );

    if (next.value != null) {
      // User logged in, set up subscriptions - defer to avoid provider lifecycle violation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final subscriptionsNotifier = ref.read(
          realtimeSubscriptionsProvider.notifier,
        );
        subscriptionsNotifier.subscribeToUserUpdates(next.value!.id);
      });
    } else {
      // User logged out, clean up subscriptions
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final subscriptionsNotifier = ref.read(
          realtimeSubscriptionsProvider.notifier,
        );
        subscriptionsNotifier.unsubscribeFromAll();
      });
    }
  });

  // Initial setup - defer to avoid provider lifecycle violation
  if (authState.value != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subscriptionsNotifier = ref.read(
        realtimeSubscriptionsProvider.notifier,
      );
      subscriptionsNotifier.subscribeToUserUpdates(authState.value!.id);
    });
  }
});
