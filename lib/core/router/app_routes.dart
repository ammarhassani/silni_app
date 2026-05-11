class AppRoutes {
  AppRoutes._();

  // Auth routes (public - no authentication required)
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String emailVerification = '/email-verification';

  // First-run setup wizard (Phase 9.X.D.B). Authenticated route — only shown
  // to users whose users.onboarding_metadata->>'setupComplete' != 'true'.
  static const String onboardingWizard = '/onboarding-wizard';

  /// Routes that don't require authentication
  static const Set<String> publicRoutes = {
    splash,
    login,
    signup,
    emailVerification,
    joinFamilyGroup,
    joinShortLink,
  };

  /// Check if a route is public (doesn't require auth)
  static bool isPublicRoute(String path) {
    return publicRoutes.any((route) => path == route || path.startsWith('$route/'));
  }

  /// Routes that require MAX subscription
  static const Set<String> premiumRoutes = {
    aiChat,
    aiScripts,
    aiReport,
  };

  /// Check if a route requires premium subscription
  static bool isPremiumRoute(String path) {
    return premiumRoutes.any((route) => path == route || path.startsWith('$route/'));
  }

  // Main routes
  static const String home = '/home';
  static const String relatives = '/relatives';
  static const String relativeDetail = '/relative';
  static const String statistics = '/statistics';
  static const String settings = '/settings';

  // Sub-routes
  static const String addRelative = '/add-relative';
  static const String editRelative = '/edit-relative';
  static const String reminders = '/reminders';
  static const String remindersDue = '/reminders-due';
  static const String familyTree = '/family-tree';
  static const String profile = '/profile';
  static const String importContacts = '/import-contacts';
  static const String notifications = '/notifications';
  static const String notificationHistory = '/notification-history';

  // Wrapped routes
  static const String monthlyWrapped = '/monthly-wrapped';

  // Family group routes
  static const String familyGroupDetail = '/family-group';
  static const String createFamilyGroup = '/create-family-group';
  static const String joinFamilyGroup = '/join-family-group';
  static const String joinShortLink = '/join';

  // AI routes
  static const String aiHub = '/ai-hub';
  static const String aiChat = '/ai-chat';
  static const String aiScripts = '/ai-scripts';
  static const String aiReport = '/ai-report';

  // Invitation routes
  static const String invitationDetail = '/invitation';

  // Identity claim wizard (post-join discovery flow)
  static const String identityClaim = '/identity-claim';

  // Admin's claim review screen
  static const String reviewClaim = '/review-claim';

  // Joiner's pending-claim screen (shown after submit, while admin reviews)
  static const String claimPending = '/claim-pending';

  // Occasion messages
  static const String occasionMessages = '/occasion-messages';
}
