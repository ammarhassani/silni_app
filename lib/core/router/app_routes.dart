class AppRoutes {
  AppRoutes._();

  // Auth routes (public - no authentication required)
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String emailVerification = '/email-verification';
  static const String resetPassword = '/reset-password';

  /// Routes that don't require authentication
  static const Set<String> publicRoutes = {
    splash,
    onboarding,
    login,
    signup,
    emailVerification,
    resetPassword,
  };

  /// Check if a route is public (doesn't require auth)
  static bool isPublicRoute(String path) {
    return publicRoutes.any((route) => path == route || path.startsWith('$route/'));
  }

  // Main routes
  static const String home = '/home';
  static const String relatives = '/relatives';
  static const String relativeDetail = '/relative';
  static const String achievements = '/achievements';
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

  // Gamification routes
  static const String badges = '/badges';
  static const String detailedStats = '/detailed-stats';
  static const String leaderboard = '/leaderboard';
  static const String challenges = '/challenges';

  // AI routes
  static const String aiHub = '/ai-hub';
  static const String aiChat = '/ai-chat';
  static const String aiMemories = '/ai-memories';
  static const String aiMessages = '/ai-messages';
  static const String aiAnalysis = '/ai-analysis';
  static const String aiScripts = '/ai-scripts';
  static const String aiReport = '/ai-report';
}
