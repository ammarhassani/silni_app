import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Analytics service for tracking user events and behavior
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Auth Events
  Future<void> logSignUp(String method) async {
    try {
      if (kDebugMode) print('📊 [Analytics] User signed up via $method');

      await _analytics.logSignUp(signUpMethod: method).timeout(
        const Duration(seconds: 3),  // Short timeout for iOS
        onTimeout: () {
          if (kDebugMode) print('⚠️ [Analytics] Signup logging timeout - continuing');
        },
      );
    } catch (e) {
      if (kDebugMode) print('⚠️ [Analytics] Failed to log signup: $e');
      // Fail silently - don't block user flow
    }
  }

  Future<void> logLogin(String method) async {
    try {
      if (kDebugMode) print('📊 [Analytics] User logged in via $method');

      await _analytics.logLogin(loginMethod: method).timeout(
        const Duration(seconds: 3),  // Short timeout for iOS
        onTimeout: () {
          if (kDebugMode) print('⚠️ [Analytics] Login logging timeout - continuing');
        },
      );
    } catch (e) {
      if (kDebugMode) print('⚠️ [Analytics] Failed to log login: $e');
      // Fail silently - don't block user flow
    }
  }

  // Relative Events
  Future<void> logRelativeAdded(String relationshipType) async {
    if (kDebugMode) print('📊 [Analytics] Relative added: $relationshipType');
    await _analytics.logEvent(
      name: 'relative_added',
      parameters: {'relationship_type': relationshipType},
    );
  }

  Future<void> logRelativeViewed(String relationshipType) async {
    if (kDebugMode) print('📊 [Analytics] Relative viewed: $relationshipType');
    await _analytics.logEvent(
      name: 'relative_viewed',
      parameters: {'relationship_type': relationshipType},
    );
  }

  Future<void> logRelativeDeleted(String relationshipType) async {
    if (kDebugMode) print('📊 [Analytics] Relative deleted: $relationshipType');
    await _analytics.logEvent(
      name: 'relative_deleted',
      parameters: {'relationship_type': relationshipType},
    );
  }

  // Interaction Events
  Future<void> logInteractionRecorded(String interactionType) async {
    if (kDebugMode) print('📊 [Analytics] Interaction recorded: $interactionType');
    await _analytics.logEvent(
      name: 'interaction_recorded',
      parameters: {'interaction_type': interactionType},
    );
  }

  Future<void> logStreakMilestone(int streakDays) async {
    if (kDebugMode) print('📊 [Analytics] Streak milestone: $streakDays days');
    await _analytics.logEvent(
      name: 'streak_milestone',
      parameters: {'streak_days': streakDays},
    );
  }

  // Screen Views
  Future<void> logScreenView(String screenName) async {
    if (kDebugMode) print('📊 [Analytics] Screen view: $screenName');
    await _analytics.logScreenView(screenName: screenName);
  }

  // Gamification Events
  Future<void> logBadgeUnlocked(String badgeName) async {
    if (kDebugMode) print('📊 [Analytics] Badge unlocked: $badgeName');
    await _analytics.logEvent(
      name: 'badge_unlocked',
      parameters: {'badge_name': badgeName},
    );
  }

  Future<void> logLevelUp(int newLevel) async {
    if (kDebugMode) print('📊 [Analytics] Level up: $newLevel');
    await _analytics.logLevelUp(level: newLevel);
  }

  // App Lifecycle
  Future<void> logAppOpen() async {
    if (kDebugMode) print('📊 [Analytics] App opened');
    await _analytics.logAppOpen();
  }

  // Error Tracking (complements Sentry)
  Future<void> logError(String errorMessage, {String? context}) async {
    if (kDebugMode) print('📊 [Analytics] Error: $errorMessage');
    await _analytics.logEvent(
      name: 'app_error',
      parameters: {
        'error_message': errorMessage,
        if (context != null) 'context': context,
      },
    );
  }
}
