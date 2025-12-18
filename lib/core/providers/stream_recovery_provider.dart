import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_logger_service.dart';
import '../services/connectivity_service.dart';
import 'connectivity_provider.dart';
import 'realtime_provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/home/screens/home_screen.dart';

/// Provider that monitors connectivity and triggers stream recovery
/// when the device comes back online after being offline.
final streamRecoveryProvider = Provider<void>((ref) {
  final logger = AppLoggerService();

  // Listen to connectivity status changes
  ref.listen<AsyncValue<ConnectivityStatus>>(
    connectivityStatusProvider,
    (previous, next) {
      final previousStatus = previous?.valueOrNull;
      final currentStatus = next.valueOrNull;

      // Check if we're coming back online from offline
      if (previousStatus == ConnectivityStatus.offline &&
          currentStatus == ConnectivityStatus.online) {
        logger.info(
          'Device came back online - triggering stream recovery',
          category: LogCategory.network,
          tag: 'StreamRecovery',
        );

        _recoverStreams(ref, logger);
      }
    },
  );

  logger.info(
    'Stream recovery provider initialized',
    category: LogCategory.network,
    tag: 'StreamRecovery',
  );
});

/// Recover all streams by invalidating providers
void _recoverStreams(Ref ref, AppLoggerService logger) {
  final user = ref.read(currentUserProvider);

  if (user == null) {
    logger.debug(
      'No user logged in - skipping stream recovery',
      category: LogCategory.network,
      tag: 'StreamRecovery',
    );
    return;
  }

  final userId = user.id;

  logger.info(
    'Recovering streams for user',
    category: LogCategory.network,
    tag: 'StreamRecovery',
    metadata: {'userId': userId},
  );

  // Use post frame callback to avoid provider lifecycle issues
  WidgetsBinding.instance.addPostFrameCallback((_) {
    try {
      // Invalidate stream providers to force reconnection
      ref.invalidate(relativesStreamProvider(userId));
      ref.invalidate(todayInteractionsStreamProvider(userId));
      ref.invalidate(reminderSchedulesStreamProvider(userId));

      // Re-establish realtime subscriptions
      final subscriptionsNotifier = ref.read(
        realtimeSubscriptionsProvider.notifier,
      );

      // Unsubscribe first to clean up stale connections
      subscriptionsNotifier.unsubscribeFromAll();

      // Re-subscribe
      subscriptionsNotifier.subscribeToUserUpdates(userId);

      logger.info(
        'Stream recovery completed successfully',
        category: LogCategory.network,
        tag: 'StreamRecovery',
        metadata: {'userId': userId},
      );
    } catch (e, st) {
      logger.error(
        'Stream recovery failed: $e',
        category: LogCategory.network,
        tag: 'StreamRecovery',
        stackTrace: st,
        metadata: {'userId': userId, 'error': e.toString()},
      );
    }
  });
}

/// Mixin for widgets that need stream recovery awareness
mixin StreamRecoveryMixin {
  /// Call this in your widget's build method to enable stream recovery
  void enableStreamRecovery(WidgetRef ref) {
    // Watch the stream recovery provider to activate it
    ref.watch(streamRecoveryProvider);
  }
}

/// Extension to easily trigger manual stream recovery
extension StreamRecoveryExtension on WidgetRef {
  /// Manually trigger stream recovery (useful for pull-to-refresh)
  void recoverStreams() {
    final logger = AppLoggerService();
    final user = read(currentUserProvider);
    if (user != null) {
      logger.info(
        'Manual stream recovery triggered',
        category: LogCategory.network,
        tag: 'StreamRecovery',
        metadata: {'userId': user.id},
      );

      // Invalidate stream providers
      invalidate(relativesStreamProvider(user.id));
      invalidate(todayInteractionsStreamProvider(user.id));
      invalidate(reminderSchedulesStreamProvider(user.id));
    }
  }
}
