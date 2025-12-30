/// Subscription tiers for Silni app monetization
///
/// Tier hierarchy:
/// - free: Basic features + Family tree + Custom themes + 3 reminders
/// - max: MAX tier - All AI features + unlimited reminders
enum SubscriptionTier {
  free,
  max,  // Display name: MAX
}

/// Extension methods for subscription tier feature access
extension SubscriptionTierExtension on SubscriptionTier {
  /// Tier identifier for database/analytics
  String get id => switch (this) {
    SubscriptionTier.free => 'free',
    SubscriptionTier.max => 'max',
  };

  /// Arabic display name
  String get arabicName => switch (this) {
    SubscriptionTier.free => 'مجاني',
    SubscriptionTier.max => 'ماكس',
  };

  /// English display name (user-facing)
  String get englishName => switch (this) {
    SubscriptionTier.free => 'Free',
    SubscriptionTier.max => 'MAX',
  };

  /// Short badge label
  String get badgeLabel => switch (this) {
    SubscriptionTier.free => '',
    SubscriptionTier.max => 'MAX',
  };

  /// Description in Arabic
  String get arabicDescription => switch (this) {
    SubscriptionTier.free => 'الميزات الأساسية + شجرة العائلة',
    SubscriptionTier.max => 'جميع الميزات + الذكاء الاصطناعي',
  };

  /// Check if this tier can upgrade to a higher tier
  bool get canUpgrade => this != SubscriptionTier.max;

  // =====================================================
  // FEATURE ACCESS CHECKS
  // =====================================================

  /// AI Chat (Counselor) - MAX only
  bool get hasAIChat => this == SubscriptionTier.max;

  /// Message Composer - MAX only
  bool get hasMessageComposer => this == SubscriptionTier.max;

  /// Communication Scripts - MAX only
  bool get hasCommunicationScripts => this == SubscriptionTier.max;

  /// Relationship Analysis - MAX only
  bool get hasRelationshipAnalysis => this == SubscriptionTier.max;

  /// Smart Reminders AI - MAX only
  bool get hasSmartRemindersAI => this == SubscriptionTier.max;

  /// Weekly Reports - MAX only
  bool get hasWeeklyReports => this == SubscriptionTier.max;

  /// Advanced Analytics - MAX only
  bool get hasAdvancedAnalytics => this == SubscriptionTier.max;

  /// Leaderboard access - MAX only
  bool get hasLeaderboard => this == SubscriptionTier.max;

  /// Data export - MAX only
  bool get hasDataExport => this == SubscriptionTier.max;

  /// Unlimited reminders - MAX only
  bool get hasUnlimitedReminders => this == SubscriptionTier.max;

  /// Custom themes - FREE for all
  bool get hasCustomThemes => true;

  /// Family tree view - FREE for all
  bool get hasFamilyTree => true;

  /// Check if tier is MAX (paid)
  bool get isMax => this == SubscriptionTier.max;

  // =====================================================
  // LIMITS
  // =====================================================

  /// Reminder limit per tier (-1 = unlimited)
  int get reminderLimit => switch (this) {
    SubscriptionTier.free => 3,
    SubscriptionTier.max => -1, // Unlimited
  };

  /// Parse tier from string
  static SubscriptionTier fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'max' => SubscriptionTier.max,
      _ => SubscriptionTier.free,
    };
  }
}

/// RevenueCat Product IDs
class SubscriptionProducts {
  SubscriptionProducts._();

  // Product identifiers (must match App Store Connect / Google Play)
  static const String maxMonthly = 'silni_max_monthly';
  static const String maxAnnual = 'silni_max_annual';

  // Entitlement identifiers (must match RevenueCat dashboard exactly)
  static const String entitlementMax = 'Silni MAX';

  /// Get all product IDs
  static Set<String> get allProductIds => {
    maxMonthly,
    maxAnnual,
  };

  /// Get tier from product ID
  static SubscriptionTier tierFromProductId(String productId) {
    if (productId.contains('max')) {
      return SubscriptionTier.max;
    }
    return SubscriptionTier.free;
  }

  /// Check if product is annual
  static bool isAnnual(String productId) => productId.contains('annual');
}

/// Feature IDs for gating
class FeatureIds {
  FeatureIds._();

  // AI Features (MAX only)
  static const String aiChat = 'ai_chat';
  static const String messageComposer = 'message_composer';
  static const String communicationScripts = 'communication_scripts';
  static const String relationshipAnalysis = 'relationship_analysis';
  static const String smartRemindersAI = 'smart_reminders_ai';
  static const String weeklyReports = 'weekly_reports';

  // Other MAX Features
  static const String advancedAnalytics = 'advanced_analytics';
  static const String leaderboard = 'leaderboard';
  static const String dataExport = 'data_export';
  static const String unlimitedReminders = 'unlimited_reminders';

  // Free Features (previously PRO)
  static const String customThemes = 'custom_themes';
  static const String familyTree = 'family_tree';

  /// Get required tier for a feature
  static SubscriptionTier requiredTier(String featureId) {
    return switch (featureId) {
      // MAX tier features - All AI features
      aiChat => SubscriptionTier.max,
      messageComposer => SubscriptionTier.max,
      communicationScripts => SubscriptionTier.max,
      relationshipAnalysis => SubscriptionTier.max,
      smartRemindersAI => SubscriptionTier.max,
      weeklyReports => SubscriptionTier.max,
      advancedAnalytics => SubscriptionTier.max,
      leaderboard => SubscriptionTier.max,
      dataExport => SubscriptionTier.max,
      unlimitedReminders => SubscriptionTier.max,
      // Default is free (includes customThemes, familyTree)
      _ => SubscriptionTier.free,
    };
  }
}
