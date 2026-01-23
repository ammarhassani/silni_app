import '../services/feature_config_service.dart';

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

  /// Check if this tier has access to a specific feature.
  ///
  /// This is the single source of truth for feature access, using
  /// [FeatureConfigService] to check admin-configured feature permissions.
  ///
  /// Example usage:
  /// ```dart
  /// if (tier.hasFeature(FeatureIds.aiChat)) {
  ///   // Show AI chat
  /// }
  /// ```
  bool hasFeature(String featureId) {
    return FeatureConfigService.instance.hasFeatureAccessSync(featureId, id);
  }

  /// Check if tier is MAX (paid)
  bool get isMax => this == SubscriptionTier.max;

  // =====================================================
  // LIMITS
  // =====================================================

  /// Reminder limit per tier (-1 = unlimited)
  ///
  /// **IMPORTANT**: This is a hardcoded fallback value. For the actual
  /// reminder limit that respects admin configuration, use:
  /// ```dart
  /// final limit = ref.watch(dynamicReminderLimitProvider);
  /// ```
  /// The [dynamicReminderLimitProvider] in `feature_config_provider.dart`
  /// checks `admin_subscription_tiers.reminder_limit` first, falling back
  /// to this value only when admin config is unavailable.
  ///
  /// Do NOT use this getter directly for limit enforcement.
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
  static const String proMonthly = 'silni_pro_monthly';
  static const String proAnnual = 'silni_pro_annual';

  // Entitlement identifiers (must match RevenueCat dashboard exactly)
  static const String entitlementMax = 'Silni MAX';

  /// Get all product IDs
  static Set<String> get allProductIds => {
    maxMonthly,
    maxAnnual,
    proMonthly,
    proAnnual,
  };

  /// Get tier from product ID
  ///
  /// Maps both MAX and PRO products to MAX tier.
  /// PRO is a lower-priced tier but since the app only has FREE and MAX tiers,
  /// PRO subscribers get full MAX access (they paid for premium features).
  static SubscriptionTier tierFromProductId(String productId) {
    if (productId.contains('max') || productId.contains('pro')) {
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
  ///
  /// @deprecated Use [SubscriptionTier.hasFeature] or [FeatureConfigService]
  /// instead. Feature requirements are now configured in the admin panel.
  @Deprecated('Use tier.hasFeature(featureId) instead. Feature access is now dynamic from admin config.')
  static SubscriptionTier requiredTier(String featureId) {
    // Fallback for backward compatibility - returns MAX for premium features
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
