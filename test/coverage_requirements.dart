/// Coverage Requirements for Silni App
///
/// This file documents our test coverage targets and tracks progress.
/// Run `make coverage` to see current coverage.
///
/// CURRENT STATE (as of 2026-01-25):
/// - Unit tests: ~14% coverage
/// - Widget tests: Basic screens covered
/// - Integration tests: 6 flows (not automated in CI)
///
/// TARGET STATE - TORTURE MODE:
/// - Unit tests: 80% minimum, 95% target, 100% nuclear
/// - Widget tests: Every screen, every interaction, every gesture
/// - Integration tests: All flows, all failures, all edge cases
/// - E2E tests: Happy path + adversarial + monkey chaos
/// - Golden tests: All components + RTL + accessibility + all sizes
/// - Adversarial tests: 100% fuzzing, all boundaries, state chaos
/// - Mutation tests: 70% kill rate minimum, 90% target
/// - Memory tests: ZERO leaks tolerance
/// - Performance tests: 60fps always, 10k items smooth
library;

// =============================================================================
// SERVICES THAT MUST HAVE TESTS (critical paths)
// =============================================================================

/// Services with existing unit tests
const testedServices = [
  'AuthService', // test/unit/services/auth_service_test.dart
  'RelativesService', // test/unit/services/relatives_service_test.dart
  'InteractionsService', // test/unit/services/interactions_service_test.dart
  'GamificationService', // test/unit/services/gamification_service_test.dart
  'ReminderSchedulesService', // test/unit/services/reminder_schedules_service_test.dart
  'ErrorHandlerService', // test/unit/services/error_handler_service_test.dart
  'ConnectivityService', // test/unit/services/connectivity_service_test.dart
  'HadithService', // test/unit/services/hadith_service_test.dart
  'NotificationHistoryService', // test/unit/services/notification_history_service_test.dart
];

/// Critical services that NEED tests
const untestedCriticalServices = [
  'OfflineQueueService', // Critical for offline functionality
  'SyncService', // Critical for data synchronization
  'CacheService', // Critical for performance
  'SubscriptionService', // Critical for monetization
  'AIService', // Critical for AI features
  'DeepseekAIService', // AI backend service
  'BiometricService', // Security critical
  'ContactsImportService', // Data import critical
  'ChatHistoryService', // AI chat persistence
  'DataExportService', // User data export (GDPR)
  'RealtimeService', // Real-time updates
  'AnalyticsService', // Usage tracking
  'FeatureFlagsService', // Feature toggles
];

// =============================================================================
// SCREENS THAT MUST HAVE WIDGET TESTS
// =============================================================================

/// Screens with existing widget tests
const testedScreens = [
  'HomeScreen', // test/widget/home/home_screen_test.dart
  'LoginScreen', // test/widget/auth/login_screen_test.dart
  'SignupScreen', // test/widget/auth/signup_screen_test.dart
  'ProfileScreen', // test/widget/profile/profile_screen_test.dart
  'RelativesScreen', // test/widget/relatives/relatives_screen_test.dart
  'RemindersScreen', // test/widget/reminders/reminders_screen_test.dart
  'SettingsScreen', // test/widget/settings/settings_screen_test.dart
  'StatisticsScreen', // test/widget/statistics/statistics_screen_test.dart
  'FamilyTreeScreen', // test/widget/family_tree/family_tree_screen_test.dart
];

/// Critical screens that NEED widget tests
const untestedCriticalScreens = [
  'BadgesScreen', // Gamification display
  'ContactImportScreen', // Contact import UI
  'AIChatScreen', // AI chat interface
  'AIHubScreen', // AI features hub
  'PaywallScreen', // Subscription paywall
  'OnboardingScreen', // User onboarding
  'RelativeDetailScreen', // Individual relative view
  'AddRelativeScreen', // Add new relative
  'EditRelativeScreen', // Edit relative
  'NotificationsScreen', // Notifications list
  'LeaderboardScreen', // Gamification leaderboard
  'ChallengesScreen', // Gamification challenges
  'WeeklyReportScreen', // AI weekly report
  'MessageComposerScreen', // AI message composer
];

// =============================================================================
// INTEGRATION FLOWS THAT MUST BE AUTOMATED
// =============================================================================

/// Integration flows with existing tests
const testedFlows = [
  'auth_flow', // integration_test/auth_flow_test.dart
  'relatives_crud', // integration_test/relatives_crud_test.dart
  'interactions_flow', // integration_test/interactions_flow_test.dart
  'gamification_flow', // integration_test/gamification_flow_test.dart
  'settings_flow', // integration_test/settings_flow_test.dart
  'reminders_flow', // integration_test/reminders_flow_test.dart
];

/// Critical flows that NEED integration tests
const untestedCriticalFlows = [
  'offline_sync_flow', // Offline mode and sync
  'subscription_flow', // Purchase and subscription
  'data_export_flow', // Export user data
  'contact_import_flow', // Import contacts
  'ai_chat_flow', // AI conversation flow
  'onboarding_flow', // New user onboarding
  'notification_flow', // Notification handling
  'family_tree_flow', // Family tree interactions
];

// =============================================================================
// ADDITIONAL TEST ARTIFACTS
// =============================================================================

/// Model tests
const testedModels = [
  'ReminderScheduleModel', // test/unit/models/reminder_schedule_model_test.dart
  'GamificationEvent', // test/unit/models/gamification_event_test.dart
  'HadithModel', // test/unit/models/hadith_model_test.dart
  'InteractionModel', // test/unit/models/interaction_model_test.dart
  'RelativeModel', // test/unit/models/relative_model_test.dart
];

/// Cache/offline tests
const testedCacheComponents = [
  'CacheAdapters', // test/unit/cache/adapters_test.dart
  'OfflineOperation', // test/unit/cache/offline_operation_test.dart
];

/// Utility tests
const testedUtils = [
  'RetryHelper', // test/unit/utils/retry_helper_test.dart
];

/// Test helpers available
const testHelpers = [
  'test_helpers.dart', // test/helpers/test_helpers.dart
  'model_factories.dart', // test/helpers/model_factories.dart
  'widget_test_helpers.dart', // test/helpers/widget_test_helpers.dart
];

// =============================================================================
// COVERAGE SUMMARY
// =============================================================================
//
// TESTED:
// - Services: 9 tested
// - Screens: 9 tested
// - Integration flows: 6 tested
// - Models: 5 tested
// - Cache components: 2 tested
// - Utils: 1 tested
//
// NEEDS TESTS:
// - Critical services: 13 untested
// - Critical screens: 14 untested
// - Critical flows: 8 untested
//
// PRIORITY ORDER FOR NEW TESTS:
// 1. OfflineQueueService, SyncService, CacheService (offline critical)
// 2. SubscriptionService (monetization critical)
// 3. AIService, DeepseekAIService (core feature)
// 4. DataExportService (GDPR compliance)
// 5. BadgesScreen, ContactImportScreen (user-facing gaps)
// 6. offline_sync_flow, subscription_flow (integration gaps)
// =============================================================================
