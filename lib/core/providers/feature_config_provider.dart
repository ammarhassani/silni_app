import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/subscription_tier.dart';
import '../services/feature_config_service.dart';
import 'subscription_provider.dart';

/// Provider for the feature config service singleton
final featureConfigServiceProvider = Provider<FeatureConfigService>((ref) {
  return FeatureConfigService.instance;
});

/// State for feature configs
class FeatureConfigState {
  final List<FeatureConfig> features;
  final List<TierConfig> tiers;
  final bool isLoading;
  final String? error;
  final DateTime? lastFetchTime;

  FeatureConfigState({
    this.features = const [],
    this.tiers = const [],
    this.isLoading = false,
    this.error,
    this.lastFetchTime,
  });

  FeatureConfigState copyWith({
    List<FeatureConfig>? features,
    List<TierConfig>? tiers,
    bool? isLoading,
    String? error,
    DateTime? lastFetchTime,
  }) {
    return FeatureConfigState(
      features: features ?? this.features,
      tiers: tiers ?? this.tiers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastFetchTime: lastFetchTime ?? this.lastFetchTime,
    );
  }

  /// Check if a feature is accessible for a given tier
  bool hasFeatureAccess(String featureId, String userTier) {
    // Find the feature
    final feature = features.cast<FeatureConfig?>().firstWhere(
      (f) => f?.featureId == featureId,
      orElse: () => null,
    );

    if (feature == null) {
      // Feature not found - fallback to hardcoded behavior
      return _hardcodedFeatureAccess(featureId, userTier);
    }

    // Check if feature is active
    if (!feature.isActive) {
      debugPrint('[FeatureConfigState] Feature $featureId is disabled in admin');
      return false;
    }

    // Check if tier has this feature in their feature list
    final tierConfig = tiers.cast<TierConfig?>().firstWhere(
      (t) => t?.tierKey == userTier,
      orElse: () => null,
    );

    if (tierConfig != null && tierConfig.hasFeature(featureId)) {
      return true;
    }

    // Fallback to minimum_tier check
    return feature.isAccessibleFor(userTier);
  }

  /// Hardcoded fallback for when config isn't loaded
  bool _hardcodedFeatureAccess(String featureId, String userTier) {
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
    return true;
  }
}

/// Notifier for managing feature config state
class FeatureConfigNotifier extends StateNotifier<FeatureConfigState> {
  final FeatureConfigService _service;

  FeatureConfigNotifier(this._service) : super(FeatureConfigState()) {
    // Load configs on initialization
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await Future.wait([
        _service.getFeatures(),
        _service.getTiers(),
      ]);

      state = state.copyWith(
        features: results[0] as List<FeatureConfig>,
        tiers: results[1] as List<TierConfig>,
        isLoading: false,
        lastFetchTime: DateTime.now(),
      );

      debugPrint('[FeatureConfigNotifier] Loaded ${state.features.length} features, ${state.tiers.length} tiers');
    } catch (e) {
      debugPrint('[FeatureConfigNotifier] Error loading configs: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh feature configs from server
  Future<void> refresh() async {
    _service.clearCache();
    await _loadConfigs();
  }

  /// Check if a feature is accessible (uses cached state)
  bool hasFeatureAccess(String featureId, String userTier) {
    return state.hasFeatureAccess(featureId, userTier);
  }
}

/// Provider for feature config state
final featureConfigProvider =
    StateNotifierProvider<FeatureConfigNotifier, FeatureConfigState>((ref) {
  final service = ref.watch(featureConfigServiceProvider);
  return FeatureConfigNotifier(service);
});

/// Provider for checking feature access (replaces hardcoded featureAccessProvider)
/// Usage: ref.watch(dynamicFeatureAccessProvider('ai_chat'))
final dynamicFeatureAccessProvider = Provider.family<bool, String>((ref, featureId) {
  final configState = ref.watch(featureConfigProvider);
  final tier = ref.watch(subscriptionTierProvider);
  final userTier = tier.id; // 'free' or 'max'

  // Use the config state to check access
  return configState.hasFeatureAccess(featureId, userTier);
});

/// Provider to get a specific feature's config
final featureConfigByIdProvider = Provider.family<FeatureConfig?, String>((ref, featureId) {
  final configState = ref.watch(featureConfigProvider);
  return configState.features.cast<FeatureConfig?>().firstWhere(
    (f) => f?.featureId == featureId,
    orElse: () => null,
  );
});

/// Provider to get a specific tier's config
final tierConfigByKeyProvider = Provider.family<TierConfig?, String>((ref, tierKey) {
  final configState = ref.watch(featureConfigProvider);
  return configState.tiers.cast<TierConfig?>().firstWhere(
    (t) => t?.tierKey == tierKey,
    orElse: () => null,
  );
});

/// Provider for all active features
final activeFeatures = Provider<List<FeatureConfig>>((ref) {
  final configState = ref.watch(featureConfigProvider);
  return configState.features.where((f) => f.isActive).toList();
});

/// Provider for features grouped by category
final featuresByCategory = Provider<Map<String, List<FeatureConfig>>>((ref) {
  final features = ref.watch(activeFeatures);
  final grouped = <String, List<FeatureConfig>>{};

  for (final feature in features) {
    if (!grouped.containsKey(feature.category)) {
      grouped[feature.category] = [];
    }
    grouped[feature.category]!.add(feature);
  }

  return grouped;
});

/// Provider for reminder limit based on dynamic tier config
final dynamicReminderLimitProvider = Provider<int>((ref) {
  final tier = ref.watch(subscriptionTierProvider);
  final tierConfig = ref.watch(tierConfigByKeyProvider(tier.id));

  // Use dynamic config if available, otherwise fallback to hardcoded
  return tierConfig?.reminderLimit ?? tier.reminderLimit;
});
