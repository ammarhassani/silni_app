import 'package:flutter/foundation.dart';

/// Analytics service for tracking user events and behavior
/// NOTE: Firebase Analytics has been disabled due to iOS configuration issues.
/// This is a no-op implementation that logs to console in debug mode only.
/// Re-enable Firebase Analytics when GoogleService-Info.plist is properly configured.
class AnalyticsService {
  // Auth Events
  Future<void> logSignUp(String method) async {
    if (kDebugMode) print('📊 [Analytics] User signed up via $method (no-op)');
    // No-op: Firebase Analytics disabled
  }

  Future<void> logLogin(String method) async {
    if (kDebugMode) print('📊 [Analytics] User logged in via $method (no-op)');
    // No-op: Firebase Analytics disabled
  }

  // Relative Events
  Future<void> logRelativeAdded(String relationshipType) async {
    if (kDebugMode) print('📊 [Analytics] Relative added: $relationshipType (no-op)');
    // No-op: Firebase Analytics disabled
  }

  Future<void> logRelativeViewed(String relationshipType) async {
    if (kDebugMode) print('📊 [Analytics] Relative viewed: $relationshipType (no-op)');
    // No-op: Firebase Analytics disabled
  }

  Future<void> logRelativeDeleted(String relationshipType) async {
    if (kDebugMode) print('📊 [Analytics] Relative deleted: $relationshipType (no-op)');
    // No-op: Firebase Analytics disabled
  }

  // Interaction Events
  Future<void> logInteractionRecorded(String interactionType) async {
    if (kDebugMode) print('📊 [Analytics] Interaction recorded: $interactionType (no-op)');
    // No-op: Firebase Analytics disabled
  }

  Future<void> logStreakMilestone(int streakDays) async {
    if (kDebugMode) print('📊 [Analytics] Streak milestone: $streakDays days (no-op)');
    // No-op: Firebase Analytics disabled
  }

  // Screen Views
  Future<void> logScreenView(String screenName) async {
    if (kDebugMode) print('📊 [Analytics] Screen view: $screenName (no-op)');
    // No-op: Firebase Analytics disabled
  }

  // Gamification Events
  Future<void> logBadgeUnlocked(String badgeName) async {
    if (kDebugMode) print('📊 [Analytics] Badge unlocked: $badgeName (no-op)');
    // No-op: Firebase Analytics disabled
  }

  Future<void> logLevelUp(int newLevel) async {
    if (kDebugMode) print('📊 [Analytics] Level up: $newLevel (no-op)');
    // No-op: Firebase Analytics disabled
  }

  // App Lifecycle
  Future<void> logAppOpen() async {
    if (kDebugMode) print('📊 [Analytics] App opened (no-op)');
    // No-op: Firebase Analytics disabled
  }

  // Error Tracking (complements Sentry)
  Future<void> logError(String errorMessage, {String? context}) async {
    if (kDebugMode) print('📊 [Analytics] Error: $errorMessage (no-op)');
    // No-op: Firebase Analytics disabled
  }
}
