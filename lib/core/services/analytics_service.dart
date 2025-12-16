import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Analytics service for tracking user events and behavior
/// Uses Firebase Analytics for production tracking
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Get the NavigatorObserver for automatic screen tracking
  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // =====================================================
  // USER PROPERTIES
  // =====================================================

  /// Set user ID for analytics
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
      if (kDebugMode) print('📊 [Analytics] User ID set: $userId');
    } catch (e) {
      if (kDebugMode) print('📊 [Analytics] Error setting user ID: $e');
    }
  }

  /// Set user properties (level, streak, etc.)
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      if (kDebugMode) print('📊 [Analytics] User property set: $name = $value');
    } catch (e) {
      if (kDebugMode) print('📊 [Analytics] Error setting user property: $e');
    }
  }

  /// Set user level
  Future<void> setUserLevel(int level) async {
    await setUserProperty(name: 'user_level', value: level.toString());
  }

  /// Set user streak
  Future<void> setUserStreak(int streakDays) async {
    await setUserProperty(name: 'streak_days', value: streakDays.toString());
  }

  // =====================================================
  // AUTH EVENTS
  // =====================================================

  Future<void> logSignUp(String method) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
      if (kDebugMode) print('📊 [Analytics] User signed up via $method');
    } catch (e) {
      if (kDebugMode) print('📊 [Analytics] Error logging signup: $e');
    }
  }

  Future<void> logLogin(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
      if (kDebugMode) print('📊 [Analytics] User logged in via $method');
    } catch (e) {
      if (kDebugMode) print('📊 [Analytics] Error logging login: $e');
    }
  }

  // =====================================================
  // RELATIVE EVENTS
  // =====================================================

  Future<void> logRelativeAdded(String relationshipType) async {
    try {
      await _analytics.logEvent(
        name: 'relative_added',
        parameters: {
          'relationship_type': relationshipType,
        },
      );
      if (kDebugMode) print('📊 [Analytics] Relative added: $relationshipType');
    } catch (e) {
      if (kDebugMode) print('📊 [Analytics] Error logging relative added: $e');
    }
  }

  Future<void> logRelativeViewed(String relationshipType) async {
    try {
      await _analytics.logEvent(
        name: 'relative_viewed',
        parameters: {
          'relationship_type': relationshipType,
        },
      );
      if (kDebugMode) print('📊 [Analytics] Relative viewed: $relationshipType');
    } catch (e) {
      if (kDebugMode) print('📊 [Analytics] Error logging relative viewed: $e');
    }
  }

  Future<void> logRelativeDeleted(String relationshipType) async {
    try {
      await _analytics.logEvent(
        name: 'relative_deleted',
        parameters: {
          'relationship_type': relationshipType,
        },
      );
      if (kDebugMode) print('📊 [Analytics] Relative deleted: $relationshipType');
    } catch (e) {
      if (kDebugMode) print('📊 [Analytics] Error logging relative deleted: $e');
    }
  }

  // =====================================================
  // INTERACTION EVENTS
  // =====================================================

  Future<void> logInteractionRecorded(String interactionType) async {
    try {
      await _analytics.logEvent(
        name: 'interaction_recorded',
        parameters: {
          'interaction_type': interactionType,
        },
      );
      if (kDebugMode) {
        print('📊 [Analytics] Interaction recorded: $interactionType');
      }
    } catch (e) {
      if (kDebugMode) print('📊 [Analytics] Error logging interaction: $e');
    }
  }

  Future<void> logStreakMilestone(int streakDays) async {
    try {
      await _analytics.logEvent(
        name: 'streak_milestone',
        parameters: {
          'streak_days': streakDays,
        },
      );
      // Also update user property
      await setUserStreak(streakDays);
      if (kDebugMode) {
        print('📊 [Analytics] Streak milestone: $streakDays days');
      }
    } catch (e) {
      if (kDebugMode) {
        print('📊 [Analytics] Error logging streak milestone: $e');
      }
    }
  }

  // =====================================================
  // SCREEN VIEWS
  // =====================================================

  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenName,
      );
      if (kDebugMode) print('📊 [Analytics] Screen view: $screenName');
    } catch (e) {
      if (kDebugMode) print('📊 [Analytics] Error logging screen view: $e');
    }
  }

  // =====================================================
  // GAMIFICATION EVENTS
  // =====================================================

  Future<void> logBadgeUnlocked(String badgeName) async {
    try {
      await _analytics.logUnlockAchievement(id: badgeName);
      if (kDebugMode) print('📊 [Analytics] Badge unlocked: $badgeName');
    } catch (e) {
      if (kDebugMode) print('📊 [Analytics] Error logging badge unlock: $e');
    }
  }

  Future<void> logLevelUp(int newLevel) async {
    try {
      await _analytics.logLevelUp(level: newLevel);
      // Also update user property
      await setUserLevel(newLevel);
      if (kDebugMode) print('📊 [Analytics] Level up: $newLevel');
    } catch (e) {
      if (kDebugMode) print('📊 [Analytics] Error logging level up: $e');
    }
  }

  // =====================================================
  // APP LIFECYCLE
  // =====================================================

  Future<void> logAppOpen() async {
    try {
      await _analytics.logAppOpen();
      if (kDebugMode) print('📊 [Analytics] App opened');
    } catch (e) {
      if (kDebugMode) print('📊 [Analytics] Error logging app open: $e');
    }
  }

  // =====================================================
  // ERROR TRACKING
  // =====================================================

  Future<void> logError(String errorMessage, {String? context}) async {
    try {
      await _analytics.logEvent(
        name: 'app_error',
        parameters: {
          'error_message': errorMessage.substring(
            0,
            errorMessage.length > 100 ? 100 : errorMessage.length,
          ),
          if (context != null) 'context': context,
        },
      );
      if (kDebugMode) print('📊 [Analytics] Error logged: $errorMessage');
    } catch (e) {
      if (kDebugMode) print('📊 [Analytics] Error logging error event: $e');
    }
  }
}
