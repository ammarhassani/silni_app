import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cache_service.dart';
import '../../features/ai_assistant/providers/ai_chat_provider.dart';
import '../../features/home/providers/home_providers.dart';
import '../../features/family_tree/providers/family_graph_providers.dart';
import '../../features/family_groups/providers/family_group_providers.dart';
import '../providers/streak_freeze_provider.dart';
import '../providers/relative_streak_provider.dart';
import '../providers/subscription_provider.dart';
import 'app_logger_service.dart';

// =============================================================================
// Per-user device-state cleanup
// =============================================================================
//
// SharedPreferences is a global key/value store on the device. Many of our
// keys carry user-specific state (onboarding gates, content-cache for the
// signed-in user, per-week question rate-limits, etc.). On a shared device
// — or after an account deletion + re-login — those keys leak the previous
// user's state into the new session.
//
// `clearPerUserDeviceState()` is the canonical wipe path. Call from:
//   • the regular signOut flow — fresh content for the next signin
//   • the deleteAccount flow — fresh-account experience for the next signin
//
// Keys NOT cleared are device-global (theme, animation prefs, install
// markers) or intentionally preserved (Phase 5.5 notification preference
// keys, kept for v1.1 topic-subscription readback).
//
// To register a new per-user key: add it to either `_exactPerUserKeys` (for
// fixed names) or `_perUserPrefixes` (for keys with userId/relativeId/period
// suffixes). The lists are the single source of truth.
// =============================================================================

/// Per-user SharedPreferences keys with fixed names. Cleared on logout/delete.
const _exactPerUserKeys = <String>[
  // Onboarding gates — survival = mis-routed fresh account
  'onboarding_completed', // marketing carousel cold-start gate
  'premium_onboarding_state', // premium tip walkthrough state
  'premium_onboarding_dismissed_tips', // premium tip dismissal list
  // Content-enhancer caches — generated per-user, stale at switch
  'weekly_report_insight',
  'weekly_report_tip',
  'weekly_report_ts',
  // Per-week question rate-limit (the asked-questions list is keyed by
  // relativeId — covered by the prefix list below)
  'one_question_week_count',
  'one_question_week_start',
  // Hadith rotation index — per CTO, fresh user gets fresh rotation
  'last_hadith_index',
  // Family-tree migration prompt decision (per-user choice)
  'family_migration_choice',
  // Analytics retention markers (per-user retention, not install date)
  'analytics_first_open_date',
  'analytics_last_active_date',
  // Experiment cohort — avoid cross-user cohort leakage
  'experiment_assignments',
];

/// Per-user prefixes — any key starting with one of these is cleared.
/// Used for keys with embedded userId / relativeId / period suffixes.
const _perUserPrefixes = <String>[
  'wrapped_ai_', // wrapped_ai_{userId}_{year}_{month}_{title|emoji}
  'one_question_asked_', // one_question_asked_{relativeId}
];

/// Clears every per-user SharedPreferences key on the device.
///
/// Device-global keys NOT touched: `app_theme`, `pattern_animation_*`,
/// `notifications_*_enabled` (Phase 5.5 design — preserved for v1.1
/// topic-subscription readback), `_test_key` (transient), `feature_flag_*`
/// (debug overrides).
Future<void> clearPerUserDeviceState() async {
  final logger = AppLoggerService();
  try {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _exactPerUserKeys) {
      await prefs.remove(key);
    }
    final prefixedKeys = prefs.getKeys().where((k) {
      return _perUserPrefixes.any((p) => k.startsWith(p));
    }).toList();
    for (final key in prefixedKeys) {
      await prefs.remove(key);
    }
    logger.debug(
      'Per-user device state cleared',
      category: LogCategory.auth,
      tag: 'clearPerUserDeviceState',
      metadata: {
        'exactKeysCleared': _exactPerUserKeys.length,
        'prefixedKeysCleared': prefixedKeys.length,
      },
    );
  } catch (e) {
    logger.warning(
      'Failed to clear per-user device state (non-critical)',
      category: LogCategory.auth,
      tag: 'clearPerUserDeviceState',
      metadata: {'error': e.toString()},
    );
  }
}

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
