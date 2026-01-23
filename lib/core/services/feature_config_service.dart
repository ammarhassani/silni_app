import 'package:supabase_flutter/supabase_flutter.dart';
import 'cache_config_service.dart';

/// Model for feature configuration from admin_features table
class FeatureConfig {
  final String id;
  final String featureId;
  final String displayNameAr;
  final String? displayNameEn;
  final String? descriptionAr;
  final String iconName;
  final String category;
  final String minimumTier;
  final String? lockedMessageAr;
  final bool isActive;
  final int sortOrder;

  FeatureConfig({
    required this.id,
    required this.featureId,
    required this.displayNameAr,
    this.displayNameEn,
    this.descriptionAr,
    required this.iconName,
    required this.category,
    required this.minimumTier,
    this.lockedMessageAr,
    required this.isActive,
    required this.sortOrder,
  });

  factory FeatureConfig.fromJson(Map<String, dynamic> json) {
    return FeatureConfig(
      id: json['id'] as String,
      featureId: json['feature_id'] as String,
      displayNameAr: json['display_name_ar'] as String,
      displayNameEn: json['display_name_en'] as String?,
      descriptionAr: json['description_ar'] as String?,
      iconName: json['icon_name'] as String? ?? 'sparkles',
      category: json['category'] as String? ?? 'utility',
      minimumTier: json['minimum_tier'] as String? ?? 'free',
      lockedMessageAr: json['locked_message_ar'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  /// Check if this feature is accessible for a given tier
  bool isAccessibleFor(String userTier) {
    if (!isActive) return false;

    // Tier hierarchy: free < max
    if (minimumTier == 'free') return true;
    if (minimumTier == 'max' && userTier == 'max') return true;

    return false;
  }
}

/// Model for trial configuration from admin_trial_config table
class TrialConfig {
  final String id;
  final String configKey;
  final int trialDurationDays;
  final String trialTier;
  final List<String>? featuresDuringTrial;
  final int? showTrialPromptAfterDays;
  final List<String>? showTrialPromptOnScreens;
  final bool isTrialEnabled;

  TrialConfig({
    required this.id,
    required this.configKey,
    required this.trialDurationDays,
    required this.trialTier,
    this.featuresDuringTrial,
    this.showTrialPromptAfterDays,
    this.showTrialPromptOnScreens,
    required this.isTrialEnabled,
  });

  factory TrialConfig.fromJson(Map<String, dynamic> json) {
    return TrialConfig(
      id: json['id'] as String,
      configKey: json['config_key'] as String? ?? 'default',
      trialDurationDays: json['trial_duration_days'] as int? ?? 7,
      trialTier: json['trial_tier'] as String? ?? 'max',
      featuresDuringTrial: (json['features_during_trial'] as List<dynamic>?)?.cast<String>(),
      showTrialPromptAfterDays: json['show_trial_prompt_after_days'] as int?,
      showTrialPromptOnScreens: (json['show_trial_prompt_on_screens'] as List<dynamic>?)?.cast<String>(),
      isTrialEnabled: json['is_trial_enabled'] as bool? ?? true,
    );
  }

  /// Fallback trial config when not loaded
  static TrialConfig get fallback => TrialConfig(
    id: 'fallback',
    configKey: 'default',
    trialDurationDays: 7,
    trialTier: 'max',
    featuresDuringTrial: null,
    showTrialPromptAfterDays: 3,
    showTrialPromptOnScreens: ['home', 'ai_chat', 'profile'],
    isTrialEnabled: true,
  );
}

/// Model for tier configuration from admin_subscription_tiers table
class TierConfig {
  final String id;
  final String tierKey;
  final String displayNameAr;
  final String? displayNameEn;
  final String? descriptionAr;
  final int reminderLimit;
  final List<String> features;
  final String iconName;
  final String colorHex;
  final bool isDefault;
  final bool isActive;

  TierConfig({
    required this.id,
    required this.tierKey,
    required this.displayNameAr,
    this.displayNameEn,
    this.descriptionAr,
    required this.reminderLimit,
    required this.features,
    required this.iconName,
    required this.colorHex,
    required this.isDefault,
    required this.isActive,
  });

  factory TierConfig.fromJson(Map<String, dynamic> json) {
    return TierConfig(
      id: json['id'] as String,
      tierKey: json['tier_key'] as String,
      displayNameAr: json['display_name_ar'] as String,
      displayNameEn: json['display_name_en'] as String?,
      descriptionAr: json['description_ar'] as String?,
      reminderLimit: json['reminder_limit'] as int? ?? -1,
      features: (json['features'] as List<dynamic>?)?.cast<String>() ?? [],
      iconName: json['icon_name'] as String? ?? 'star',
      colorHex: json['color_hex'] as String? ?? '#3B82F6',
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Check if this tier has access to a feature
  bool hasFeature(String featureId) {
    return features.contains(featureId);
  }
}

/// Service for fetching and caching feature configurations from Supabase
class FeatureConfigService {
  FeatureConfigService._();
  static final FeatureConfigService instance = FeatureConfigService._();

  final _supabase = Supabase.instance.client;

  // Cached configs
  List<FeatureConfig>? _featuresCache;
  List<TierConfig>? _tiersCache;
  TrialConfig? _trialConfigCache;
  DateTime? _lastFetchTime;

  // Cache duration from remote config
  final CacheConfigService _cacheConfig = CacheConfigService();
  static const String _serviceKey = 'feature_config';

  /// Get all feature configurations
  Future<List<FeatureConfig>> getFeatures({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid && _featuresCache != null) {
      return _featuresCache!;
    }

    try {
      final response = await _supabase
          .from('admin_features')
          .select()
          .order('sort_order', ascending: true);

      _featuresCache = (response as List)
          .map((json) => FeatureConfig.fromJson(json))
          .toList();
      _lastFetchTime = DateTime.now();
      return _featuresCache!;
    } catch (_) {
      // Return cache if available, even if expired
      if (_featuresCache != null) return _featuresCache!;
      // Return empty list with fallback to hardcoded behavior
      return [];
    }
  }

  /// Get all tier configurations
  Future<List<TierConfig>> getTiers({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid && _tiersCache != null) {
      return _tiersCache!;
    }

    try {
      final response = await _supabase
          .from('admin_subscription_tiers')
          .select()
          .order('sort_order', ascending: true);

      _tiersCache = (response as List)
          .map((json) => TierConfig.fromJson(json))
          .toList();
      _lastFetchTime = DateTime.now();
      return _tiersCache!;
    } catch (_) {
      if (_tiersCache != null) return _tiersCache!;
      return [];
    }
  }

  /// Get a specific feature config by ID
  Future<FeatureConfig?> getFeature(String featureId) async {
    final features = await getFeatures();
    return features.cast<FeatureConfig?>().firstWhere(
      (f) => f?.featureId == featureId,
      orElse: () => null,
    );
  }

  /// Get a specific tier config by key
  Future<TierConfig?> getTier(String tierKey) async {
    final tiers = await getTiers();
    return tiers.cast<TierConfig?>().firstWhere(
      (t) => t?.tierKey == tierKey,
      orElse: () => null,
    );
  }

  /// Check if a feature is accessible for a given tier
  /// This is the main method used for feature gating
  Future<bool> hasFeatureAccess(String featureId, String userTier) async {
    // First check if feature exists and is active
    final feature = await getFeature(featureId);
    if (feature == null) {
      // Feature not in config - fallback to allowing access (backwards compatibility)
      return true;
    }

    if (!feature.isActive) {
      return false;
    }

    // Check if user's tier has this feature in their features array
    final tierConfig = await getTier(userTier);
    if (tierConfig != null && tierConfig.hasFeature(featureId)) {
      return true;
    }

    // Fallback to minimum_tier check
    return feature.isAccessibleFor(userTier);
  }

  /// Get reminder limit for a tier
  Future<int> getReminderLimit(String tierKey) async {
    final tier = await getTier(tierKey);
    return tier?.reminderLimit ?? 3; // Default to 3 for free
  }

  /// Get all features for a specific tier
  Future<List<FeatureConfig>> getFeaturesForTier(String tierKey) async {
    final features = await getFeatures();
    final tier = await getTier(tierKey);

    if (tier == null) return [];

    // Get features that are in the tier's feature list
    return features.where((f) => tier.hasFeature(f.featureId) && f.isActive).toList();
  }

  /// Get trial configuration
  Future<TrialConfig> getTrialConfig({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid && _trialConfigCache != null) {
      return _trialConfigCache!;
    }

    try {
      final response = await _supabase
          .from('admin_trial_config')
          .select()
          .eq('config_key', 'default')
          .single();

      _trialConfigCache = TrialConfig.fromJson(response);
      return _trialConfigCache!;
    } catch (_) {
      if (_trialConfigCache != null) return _trialConfigCache!;
      return TrialConfig.fallback;
    }
  }

  /// Get trial config sync (uses cache)
  TrialConfig get trialConfig => _trialConfigCache ?? TrialConfig.fallback;

  /// Check if trial is enabled
  bool get isTrialEnabled => trialConfig.isTrialEnabled;

  /// Get trial duration in days
  int get trialDurationDays => trialConfig.trialDurationDays;

  /// Get the tier users get during trial
  String get trialTier => trialConfig.trialTier;

  /// Check if a screen should show trial prompt
  bool shouldShowTrialPrompt(String screenKey) {
    final screens = trialConfig.showTrialPromptOnScreens;
    if (screens == null || screens.isEmpty) return false;
    return screens.contains(screenKey);
  }

  /// Clear cache and force refresh on next fetch
  void clearCache() {
    _featuresCache = null;
    _tiersCache = null;
    _trialConfigCache = null;
    _lastFetchTime = null;
  }

  /// Refresh all configs
  Future<void> refresh() async {
    await Future.wait([
      getFeatures(forceRefresh: true),
      getTiers(forceRefresh: true),
      getTrialConfig(forceRefresh: true),
    ]);
  }

  bool get _isCacheValid {
    if (_lastFetchTime == null) return false;
    return !_cacheConfig.isCacheExpired(_serviceKey, _lastFetchTime);
  }

  /// Sync method to check feature access (uses cache, for use in providers)
  bool hasFeatureAccessSync(String featureId, String userTier) {
    if (_featuresCache == null || _tiersCache == null) {
      // Cache not loaded yet - fallback to hardcoded behavior
      return _hardcodedFeatureAccess(featureId, userTier);
    }

    final feature = _featuresCache!.cast<FeatureConfig?>().firstWhere(
      (f) => f?.featureId == featureId,
      orElse: () => null,
    );

    if (feature == null) {
      // Feature not in config - use hardcoded fallback
      return _hardcodedFeatureAccess(featureId, userTier);
    }

    if (!feature.isActive) {
      return false;
    }

    // Check tier's feature list
    final tierConfig = _tiersCache!.cast<TierConfig?>().firstWhere(
      (t) => t?.tierKey == userTier,
      orElse: () => null,
    );

    if (tierConfig != null && tierConfig.hasFeature(featureId)) {
      return true;
    }

    return feature.isAccessibleFor(userTier);
  }

  /// Hardcoded fallback for when config isn't loaded
  bool _hardcodedFeatureAccess(String featureId, String userTier) {
    // MAX-only features
    const maxFeatures = {
      'ai_chat',
      'message_composer',
      'communication_scripts',
      'relationship_analysis',
      'smart_reminders_ai',
      'weekly_reports',
      'advanced_analytics',
      'leaderboard',
      'data_export',
      'unlimited_reminders',
    };

    if (maxFeatures.contains(featureId)) {
      return userTier == 'max';
    }

    // Default: allow access (free features)
    return true;
  }
}
