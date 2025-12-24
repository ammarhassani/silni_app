import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/analytics_events.dart';

/// Analytics service for tracking user events and behavior
/// Uses Firebase Analytics for production tracking with comprehensive
/// funnel tracking, user properties, and retention measurement.
class AnalyticsService {
  static FirebaseAnalytics? _analytics;
  static bool _initialized = false;
  static DateTime? _sessionStartTime;
  static int _sessionActionCount = 0;

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
        name: AnalyticsEvents.appError,
        parameters: {
          AnalyticsParams.errorMessage: errorMessage.substring(
            0,
            errorMessage.length > 100 ? 100 : errorMessage.length,
          ),
          if (context != null) AnalyticsParams.errorContext: context,
        },
      );
    } catch (e) {
      // Silently fail - analytics is not critical
    }
  }

  // =====================================================
  // SESSION TRACKING
  // =====================================================

  /// Start a new session - call when app opens or resumes
  Future<void> startSession() async {
    _sessionStartTime = DateTime.now();
    _sessionActionCount = 0;
    try {
      await _safeAnalytics?.logEvent(
        name: AnalyticsEvents.sessionStart,
        parameters: {
          AnalyticsParams.timestamp: _sessionStartTime!.toIso8601String(),
        },
      );
    } catch (e) {
      // Silently fail
    }
  }

  /// End session - call when app goes to background
  Future<void> endSession() async {
    if (_sessionStartTime == null) return;
    final duration = DateTime.now().difference(_sessionStartTime!);
    try {
      await _safeAnalytics?.logEvent(
        name: AnalyticsEvents.sessionEnd,
        parameters: {
          AnalyticsParams.sessionDuration: duration.inMilliseconds,
          AnalyticsParams.actionsCompleted: _sessionActionCount,
        },
      );
    } catch (e) {
      // Silently fail
    }
    _sessionStartTime = null;
    _sessionActionCount = 0;
  }

  /// Track an action in the current session
  void trackAction() {
    _sessionActionCount++;
  }

  // =====================================================
  // RETENTION TRACKING
  // =====================================================

  static const String _firstOpenKey = 'analytics_first_open_date';
  static const String _lastActiveKey = 'analytics_last_active_date';

  /// Track user retention - call on app open
  Future<void> trackRetention() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Get first open date
      final firstOpenStr = prefs.getString(_firstOpenKey);
      DateTime firstOpen;
      if (firstOpenStr == null) {
        firstOpen = today;
        await prefs.setString(_firstOpenKey, today.toIso8601String());
      } else {
        firstOpen = DateTime.parse(firstOpenStr);
      }

      // Calculate days since first open
      final daysSinceFirstOpen = today.difference(firstOpen).inDays;

      // Track retention milestones (Day 1, 7, 30)
      if (daysSinceFirstOpen == 1 ||
          daysSinceFirstOpen == 7 ||
          daysSinceFirstOpen == 30) {
        await _safeAnalytics?.logEvent(
          name: AnalyticsEvents.userRetention,
          parameters: {
            AnalyticsParams.dayNumber: daysSinceFirstOpen,
          },
        );
      }

      // Update last active
      await prefs.setString(_lastActiveKey, today.toIso8601String());

      // Update user property
      await setUserProperty(
        name: AnalyticsUserProps.accountAge,
        value: daysSinceFirstOpen.toString(),
      );
    } catch (e) {
      // Silently fail
    }
  }

  /// Log daily active user
  Future<void> logDailyActive() async {
    try {
      await _safeAnalytics?.logEvent(name: AnalyticsEvents.dailyActive);
    } catch (e) {
      // Silently fail
    }
  }

  // =====================================================
  // AI ASSISTANT EVENTS
  // =====================================================

  Future<void> logAIChatStarted({String? relativeId}) async {
    trackAction();
    try {
      await _safeAnalytics?.logEvent(
        name: AnalyticsEvents.aiChatStarted,
        parameters: {
          if (relativeId != null) AnalyticsParams.relativeId: relativeId,
        },
      );
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> logAIChatMessageSent({
    required String chatId,
    int? messageCount,
  }) async {
    trackAction();
    try {
      await _safeAnalytics?.logEvent(
        name: AnalyticsEvents.aiChatMessageSent,
        parameters: {
          AnalyticsParams.chatId: chatId,
          if (messageCount != null) AnalyticsParams.messageCount: messageCount,
        },
      );
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> logAIResponseReceived({
    required int responseTimeMs,
    int? tokenCount,
  }) async {
    try {
      await _safeAnalytics?.logEvent(
        name: AnalyticsEvents.aiChatResponseReceived,
        parameters: {
          AnalyticsParams.responseTime: responseTimeMs,
          if (tokenCount != null) AnalyticsParams.tokenCount: tokenCount,
        },
      );
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> logAIScriptGenerated(String scriptType) async {
    trackAction();
    try {
      await _safeAnalytics?.logEvent(
        name: AnalyticsEvents.aiScriptGenerated,
        parameters: {
          AnalyticsParams.scriptType: scriptType,
        },
      );
    } catch (e) {
      // Silently fail
    }
  }

  // =====================================================
  // REMINDER EVENTS
  // =====================================================

  Future<void> logReminderCreated({
    required String reminderType,
    required String frequency,
  }) async {
    trackAction();
    try {
      await _safeAnalytics?.logEvent(
        name: AnalyticsEvents.reminderCreated,
        parameters: {
          AnalyticsParams.reminderType: reminderType,
          AnalyticsParams.frequency: frequency,
        },
      );
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> logReminderCompleted(String reminderId) async {
    trackAction();
    try {
      await _safeAnalytics?.logEvent(
        name: AnalyticsEvents.reminderCompleted,
        parameters: {
          AnalyticsParams.reminderId: reminderId,
        },
      );
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> logSmartSuggestionAccepted() async {
    trackAction();
    try {
      await _safeAnalytics?.logEvent(
        name: AnalyticsEvents.smartSuggestionAccepted,
      );
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> logSmartSuggestionDismissed() async {
    try {
      await _safeAnalytics?.logEvent(
        name: AnalyticsEvents.smartSuggestionDismissed,
      );
    } catch (e) {
      // Silently fail
    }
  }

  // =====================================================
  // USER PROPERTIES - EXTENDED
  // =====================================================

  /// Update all user properties at once
  Future<void> updateUserProperties({
    int? relativesCount,
    int? aiUsageCount,
    String? themePreference,
    bool? notificationsEnabled,
    int? totalInteractions,
  }) async {
    try {
      if (relativesCount != null) {
        await setUserProperty(
          name: AnalyticsUserProps.relativesCount,
          value: relativesCount.toString(),
        );
      }
      if (aiUsageCount != null) {
        await setUserProperty(
          name: AnalyticsUserProps.aiUsageCount,
          value: aiUsageCount.toString(),
        );
      }
      if (themePreference != null) {
        await setUserProperty(
          name: AnalyticsUserProps.themePreference,
          value: themePreference,
        );
      }
      if (notificationsEnabled != null) {
        await setUserProperty(
          name: AnalyticsUserProps.notificationsEnabled,
          value: notificationsEnabled.toString(),
        );
      }
      if (totalInteractions != null) {
        await setUserProperty(
          name: AnalyticsUserProps.totalInteractions,
          value: totalInteractions.toString(),
        );
      }
    } catch (e) {
      // Silently fail
    }
  }

  // =====================================================
  // PERFORMANCE EVENTS
  // =====================================================

  /// Log slow load time for performance monitoring
  Future<void> logSlowLoad({
    required String screenName,
    required int loadTimeMs,
    int? itemCount,
  }) async {
    try {
      await _safeAnalytics?.logEvent(
        name: AnalyticsEvents.slowLoad,
        parameters: {
          AnalyticsParams.screenName: screenName,
          AnalyticsParams.loadTime: loadTimeMs,
          if (itemCount != null) AnalyticsParams.itemCount: itemCount,
        },
      );
    } catch (e) {
      // Silently fail
    }
  }

  // =====================================================
  // ONBOARDING EVENTS
  // =====================================================

  Future<void> logOnboardingStarted() async {
    try {
      await _safeAnalytics?.logEvent(name: AnalyticsEvents.onboardingStarted);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> logOnboardingCompleted() async {
    trackAction();
    try {
      await _safeAnalytics?.logEvent(name: AnalyticsEvents.onboardingCompleted);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> logOnboardingSkipped() async {
    try {
      await _safeAnalytics?.logEvent(name: AnalyticsEvents.onboardingSkipped);
    } catch (e) {
      // Silently fail
    }
  }

  // =====================================================
  // THEME EVENTS
  // =====================================================

  Future<void> logThemeChanged(String themeName) async {
    try {
      await _safeAnalytics?.logEvent(
        name: AnalyticsEvents.themeChanged,
        parameters: {
          'theme_name': themeName,
        },
      );
      await setUserProperty(
        name: AnalyticsUserProps.themePreference,
        value: themeName,
      );
    } catch (e) {
      // Silently fail
    }
  }

  // =====================================================
  // CORE ACTION TRACKING
  // =====================================================

  /// Track core actions for retention measurement
  /// Core actions: adding relative, logging interaction, sending AI message
  Future<void> logCoreActionCompleted(String actionType) async {
    trackAction();
    try {
      await _safeAnalytics?.logEvent(
        name: AnalyticsEvents.coreActionCompleted,
        parameters: {
          'action_type': actionType,
        },
      );
    } catch (e) {
      // Silently fail
    }
  }
}
