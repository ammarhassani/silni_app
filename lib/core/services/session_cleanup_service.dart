import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/cache_service.dart';
import '../../features/ai_assistant/providers/ai_chat_provider.dart';
import '../../features/home/providers/home_providers.dart';
import '../../features/family_tree/providers/family_graph_providers.dart';
import '../../features/family_groups/providers/family_group_providers.dart';
import '../providers/streak_freeze_provider.dart';
import '../providers/relative_streak_provider.dart';
import '../providers/subscription_provider.dart';
import 'app_logger_service.dart';

/// Clears all user-dependent state when a user signs out or switches accounts.
///
/// Invalidates Riverpod providers (both autoDispose+keepAlive and
/// non-autoDispose) and clears the Hive disk cache so the next user
/// never sees stale data from the previous session.
void clearUserSession(Ref ref, {String? previousUserId}) {
  final logger = AppLoggerService();
  logger.info(
    'Clearing user session data',
    category: LogCategory.auth,
    tag: 'SessionCleanup',
    metadata: {'previousUserId': previousUserId},
  );

  // ── Non-autoDispose providers (persist forever unless invalidated) ──

  ref.invalidate(aiRelativesProvider);
  ref.invalidate(aiMemoriesProvider);
  ref.invalidate(subscriptionStateProvider);

  // Family providers keyed by userId
  if (previousUserId != null) {
    ref.invalidate(freezeInventoryProvider(previousUserId));
    ref.invalidate(freezeInventoryStreamProvider(previousUserId));
    ref.invalidate(freezeHistoryProvider(previousUserId));
    ref.invalidate(autoFreezeEnabledProvider(previousUserId));
    ref.invalidate(allRelativeStreaksProvider(previousUserId));
    ref.invalidate(allRelativeStreaksStreamProvider(previousUserId));
    ref.invalidate(endangeredStreaksProvider(previousUserId));
  }

  // ── AutoDispose + keepAlive providers (stale for up to 5 min) ──

  ref.invalidate(userFamilyGroupProvider);

  if (previousUserId != null) {
    ref.invalidate(relativesStreamProvider(previousUserId));
    ref.invalidate(todayInteractionsStreamProvider(previousUserId));
    ref.invalidate(recentInteractionsStreamProvider(previousUserId));
    ref.invalidate(reminderSchedulesStreamProvider(previousUserId));
    ref.invalidate(userGamificationDataProvider(previousUserId));
    ref.invalidate(familyEdgesStreamProvider(previousUserId));
    ref.invalidate(userGroupsProvider(previousUserId));
  }

  // ── Hive disk cache ──

  CacheService.instance.clearAll();

  logger.info(
    'User session data cleared',
    category: LogCategory.auth,
    tag: 'SessionCleanup',
  );
}

/// Same as [clearUserSession] but accepts a [WidgetRef] for use in widgets.
void clearUserSessionFromWidget(WidgetRef ref, {String? previousUserId}) {
  final logger = AppLoggerService();
  logger.info(
    'Clearing user session data (widget)',
    category: LogCategory.auth,
    tag: 'SessionCleanup',
    metadata: {'previousUserId': previousUserId},
  );

  ref.invalidate(aiRelativesProvider);
  ref.invalidate(aiMemoriesProvider);
  ref.invalidate(subscriptionStateProvider);

  if (previousUserId != null) {
    ref.invalidate(freezeInventoryProvider(previousUserId));
    ref.invalidate(freezeInventoryStreamProvider(previousUserId));
    ref.invalidate(freezeHistoryProvider(previousUserId));
    ref.invalidate(autoFreezeEnabledProvider(previousUserId));
    ref.invalidate(allRelativeStreaksProvider(previousUserId));
    ref.invalidate(allRelativeStreaksStreamProvider(previousUserId));
    ref.invalidate(endangeredStreaksProvider(previousUserId));
  }

  ref.invalidate(userFamilyGroupProvider);

  if (previousUserId != null) {
    ref.invalidate(relativesStreamProvider(previousUserId));
    ref.invalidate(todayInteractionsStreamProvider(previousUserId));
    ref.invalidate(recentInteractionsStreamProvider(previousUserId));
    ref.invalidate(reminderSchedulesStreamProvider(previousUserId));
    ref.invalidate(userGamificationDataProvider(previousUserId));
    ref.invalidate(familyEdgesStreamProvider(previousUserId));
    ref.invalidate(userGroupsProvider(previousUserId));
  }

  CacheService.instance.clearAll();

  logger.info(
    'User session data cleared (widget)',
    category: LogCategory.auth,
    tag: 'SessionCleanup',
  );
}
