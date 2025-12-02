class AppRoutes {
  AppRoutes._();

  // Auth routes
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';

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
  static const String addInteraction = '/add-interaction';
  static const String reminders = '/reminders';
  static const String familyTree = '/family-tree';
  static const String profile = '/profile';
  static const String importContacts = '/import-contacts';
  static const String notifications = '/notifications';

  // Gamification routes
  static const String badges = '/badges';
  static const String detailedStats = '/detailed-stats';
  static const String leaderboard = '/leaderboard';
}
