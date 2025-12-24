/// Analytics Event Constants
/// Centralized event names to prevent typos and ensure consistency
/// across the entire app for Firebase Analytics tracking.
library;

class AnalyticsEvents {
  AnalyticsEvents._();

  // =====================================================
  // AUTH EVENTS
  // =====================================================
  static const signUp = 'sign_up';
  static const login = 'login';
  static const logout = 'logout';
  static const sessionStart = 'session_start';
  static const sessionEnd = 'session_end';

  // =====================================================
  // RELATIVE FUNNEL EVENTS
  // =====================================================
  static const relativeAdded = 'relative_added';
  static const relativeViewed = 'relative_viewed';
  static const relativeEdited = 'relative_edited';
  static const relativeDeleted = 'relative_deleted';
  static const relativeContactImported = 'relative_contact_imported';

  // =====================================================
  // INTERACTION EVENTS
  // =====================================================
  static const interactionRecorded = 'interaction_recorded';
  static const interactionViewed = 'interaction_viewed';
  static const interactionDeleted = 'interaction_deleted';
  static const quickInteractionUsed = 'quick_interaction_used';

  // =====================================================
  // REMINDER EVENTS
  // =====================================================
  static const reminderCreated = 'reminder_created';
  static const reminderEdited = 'reminder_edited';
  static const reminderDeleted = 'reminder_deleted';
  static const reminderCompleted = 'reminder_completed';
  static const reminderSnoozed = 'reminder_snoozed';
  static const reminderDismissed = 'reminder_dismissed';
  static const smartSuggestionAccepted = 'smart_suggestion_accepted';
  static const smartSuggestionDismissed = 'smart_suggestion_dismissed';

  // =====================================================
  // AI ASSISTANT EVENTS
  // =====================================================
  static const aiChatStarted = 'ai_chat_started';
  static const aiChatMessageSent = 'ai_chat_message_sent';
  static const aiChatResponseReceived = 'ai_chat_response_received';
  static const aiChatEnded = 'ai_chat_ended';
  static const aiScriptGenerated = 'ai_script_generated';
  static const aiScriptCopied = 'ai_script_copied';
  static const aiGiftSuggestionViewed = 'ai_gift_suggestion_viewed';
  static const aiGiftSelected = 'ai_gift_selected';
  static const aiAnalysisViewed = 'ai_analysis_viewed';

  // =====================================================
  // GAMIFICATION EVENTS
  // =====================================================
  static const streakAchieved = 'streak_achieved';
  static const streakMilestone = 'streak_milestone';
  static const streakLost = 'streak_lost';
  static const streakRecovered = 'streak_recovered';
  static const badgeUnlocked = 'badge_unlocked';
  static const badgeViewed = 'badge_viewed';
  static const levelUp = 'level_up';
  static const pointsEarned = 'points_earned';
  static const challengeStarted = 'challenge_started';
  static const challengeCompleted = 'challenge_completed';

  // =====================================================
  // FAMILY TREE EVENTS
  // =====================================================
  static const familyTreeViewed = 'family_tree_viewed';
  static const familyTreeNodeAdded = 'family_tree_node_added';
  static const familyTreeExported = 'family_tree_exported';
  static const familyTreeShared = 'family_tree_shared';

  // =====================================================
  // SETTINGS & PREFERENCES
  // =====================================================
  static const themeChanged = 'theme_changed';
  static const languageChanged = 'language_changed';
  static const notificationToggled = 'notification_toggled';
  static const biometricToggled = 'biometric_toggled';

  // =====================================================
  // RETENTION & ENGAGEMENT
  // =====================================================
  static const userRetention = 'user_retention';
  static const dailyActive = 'daily_active';
  static const weeklyActive = 'weekly_active';
  static const monthlyActive = 'monthly_active';
  static const coreActionCompleted = 'core_action_completed';
  static const onboardingStarted = 'onboarding_started';
  static const onboardingCompleted = 'onboarding_completed';
  static const onboardingSkipped = 'onboarding_skipped';

  // =====================================================
  // ERROR & PERFORMANCE
  // =====================================================
  static const appError = 'app_error';
  static const networkError = 'network_error';
  static const syncError = 'sync_error';
  static const slowLoad = 'slow_load';

  // =====================================================
  // SCREEN VIEWS
  // =====================================================
  static const screenView = 'screen_view';
  static const screenTimeSpent = 'screen_time_spent';
}

/// Analytics Parameter Keys
/// Consistent parameter names for event tracking
class AnalyticsParams {
  AnalyticsParams._();

  // Common Parameters
  static const userId = 'user_id';
  static const timestamp = 'timestamp';
  static const screenName = 'screen_name';
  static const source = 'source';

  // Relative Parameters
  static const relativeId = 'relative_id';
  static const relationshipType = 'relationship_type';
  static const healthScore = 'health_score';

  // Interaction Parameters
  static const interactionType = 'interaction_type';
  static const interactionQuality = 'interaction_quality';

  // Reminder Parameters
  static const reminderId = 'reminder_id';
  static const reminderType = 'reminder_type';
  static const frequency = 'frequency';

  // AI Parameters
  static const chatId = 'chat_id';
  static const messageCount = 'message_count';
  static const responseTime = 'response_time_ms';
  static const tokenCount = 'token_count';
  static const scriptType = 'script_type';
  static const giftCategory = 'gift_category';

  // Gamification Parameters
  static const streakDays = 'streak_days';
  static const badgeName = 'badge_name';
  static const level = 'level';
  static const points = 'points';
  static const challengeId = 'challenge_id';

  // Retention Parameters
  static const dayNumber = 'day_number';
  static const sessionDuration = 'session_duration_ms';
  static const actionsCompleted = 'actions_completed';

  // Error Parameters
  static const errorMessage = 'error_message';
  static const errorCode = 'error_code';
  static const errorContext = 'error_context';
  static const stackTrace = 'stack_trace';

  // Performance Parameters
  static const loadTime = 'load_time_ms';
  static const itemCount = 'item_count';
  static const memoryUsage = 'memory_usage_mb';
}

/// User Property Keys
/// Properties set on users for segmentation
class AnalyticsUserProps {
  AnalyticsUserProps._();

  static const userLevel = 'user_level';
  static const streakDays = 'streak_days';
  static const relativesCount = 'relatives_count';
  static const aiUsageCount = 'ai_usage_count';
  static const themePreference = 'theme_preference';
  static const notificationsEnabled = 'notifications_enabled';
  static const accountAge = 'account_age_days';
  static const isPremium = 'is_premium';
  static const lastActiveDate = 'last_active_date';
  static const totalInteractions = 'total_interactions';
}
