import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

/// Analytics service for tracking user events and behavior
/// Uses Firebase Analytics for production tracking
class AnalyticsService {
  static FirebaseAnalytics? _analytics;
  static bool _initialized = false;

  /// Safely get analytics instance, returns null if Firebase not initialized
  static FirebaseAnalytics? get _safeAnalytics {
    if (!_initialized) {
      try {
        // Check if Firebase is initialized
        Firebase.app();
        _analytics = FirebaseAnalytics.instance;
        _initialized = true;
      } catch (e) {
        // Firebase not initialized (e.g., web without config)
        return null;
      }
    }
    return _analytics;
  }

  /// Get the NavigatorObserver for automatic screen tracking
  /// Returns a no-op observer if Firebase isn't available
  static NavigatorObserver get observer {
    final analytics = _safeAnalytics;
    if (analytics != null) {
      return FirebaseAnalyticsObserver(analytics: analytics);
    }
    // Return a no-op observer when Firebase isn't available
    return NavigatorObserver();
  }

  // =====================================================
  // USER PROPERTIES
  // =====================================================

  /// Set user ID for analytics
  Future<void> setUserId(String? userId) async {
    try {
      await _safeAnalytics?.setUserId(id: userId);
    } catch (e) {
      // Silently fail - analytics is not critical
    }
  }

  /// Set user properties (level, streak, etc.)
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _safeAnalytics?.setUserProperty(name: name, value: value);
    } catch (e) {
      // Silently fail - analytics is not critical
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
      await _safeAnalytics?.logSignUp(signUpMethod: method);
    } catch (e) {
      // Silently fail - analytics is not critical
    }
  }

  Future<void> logLogin(String method) async {
    try {
      await _safeAnalytics?.logLogin(loginMethod: method);
    } catch (e) {
      // Silently fail - analytics is not critical
    }
  }

  // =====================================================
  // RELATIVE EVENTS
  // =====================================================

  Future<void> logRelativeAdded(String relationshipType) async {
    try {
      await _safeAnalytics?.logEvent(
        name: 'relative_added',
        parameters: {
          'relationship_type': relationshipType,
        },
      );
    } catch (e) {
      // Silently fail - analytics is not critical
    }
  }

  Future<void> logRelativeViewed(String relationshipType) async {
    try {
      await _safeAnalytics?.logEvent(
        name: 'relative_viewed',
        parameters: {
          'relationship_type': relationshipType,
        },
      );
    } catch (e) {
      // Silently fail - analytics is not critical
    }
  }

  Future<void> logRelativeDeleted(String relationshipType) async {
    try {
      await _safeAnalytics?.logEvent(
        name: 'relative_deleted',
        parameters: {
          'relationship_type': relationshipType,
        },
      );
    } catch (e) {
      // Silently fail - analytics is not critical
    }
  }

  // =====================================================
  // INTERACTION EVENTS
  // =====================================================

  Future<void> logInteractionRecorded(String interactionType) async {
    try {
      await _safeAnalytics?.logEvent(
        name: 'interaction_recorded',
        parameters: {
          'interaction_type': interactionType,
        },
      );
    } catch (e) {
      // Silently fail - analytics is not critical
    }
  }

  Future<void> logStreakMilestone(int streakDays) async {
    try {
      await _safeAnalytics?.logEvent(
        name: 'streak_milestone',
        parameters: {
          'streak_days': streakDays,
        },
      );
      // Also update user property
      await setUserStreak(streakDays);
    } catch (e) {
      // Silently fail - analytics is not critical
    }
  }

  // =====================================================
  // SCREEN VIEWS
  // =====================================================

  Future<void> logScreenView(String screenName) async {
    try {
      await _safeAnalytics?.logScreenView(
        screenName: screenName,
        screenClass: screenName,
      );
    } catch (e) {
      // Silently fail - analytics is not critical
    }
  }

  // =====================================================
  // GAMIFICATION EVENTS
  // =====================================================

  Future<void> logBadgeUnlocked(String badgeName) async {
    try {
      await _safeAnalytics?.logUnlockAchievement(id: badgeName);
    } catch (e) {
      // Silently fail - analytics is not critical
    }
  }

  Future<void> logLevelUp(int newLevel) async {
    try {
      await _safeAnalytics?.logLevelUp(level: newLevel);
      // Also update user property
      await setUserLevel(newLevel);
    } catch (e) {
      // Silently fail - analytics is not critical
    }
  }

  // =====================================================
  // APP LIFECYCLE
  // =====================================================

  Future<void> logAppOpen() async {
    try {
      await _safeAnalytics?.logAppOpen();
    } catch (e) {
      // Silently fail - analytics is not critical
    }
  }

  // =====================================================
  // ERROR TRACKING
  // =====================================================

  Future<void> logError(String errorMessage, {String? context}) async {
    try {
      await _safeAnalytics?.logEvent(
        name: 'app_error',
        parameters: {
          'error_message': errorMessage.substring(
            0,
            errorMessage.length > 100 ? 100 : errorMessage.length,
          ),
          if (context != null) 'context': context,
        },
      );
    } catch (e) {
      // Silently fail - analytics is not critical
    }
  }
}
