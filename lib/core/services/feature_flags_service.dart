import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_logger_service.dart';

/// Feature flag definitions with default values
class FeatureFlags {
  FeatureFlags._();

  // UI Experiments
  static const String premiumLoadingIndicators = 'premium_loading_indicators';
  static const String glassmorphismCards = 'glassmorphism_cards';
  static const String animatedTransitions = 'animated_transitions';
  static const String hapticFeedback = 'haptic_feedback';

  // Feature Rollouts
  static const String aiAssistant = 'ai_assistant_enabled';
  static const String familyTree = 'family_tree_enabled';
  static const String gamification = 'gamification_enabled';
  static const String smartReminders = 'smart_reminders_enabled';

  // A/B Test Variants
  static const String onboardingVariant = 'onboarding_variant';
  static const String homeScreenLayout = 'home_screen_layout';
  static const String reminderFrequencyOptions = 'reminder_frequency_options';

  // Performance Tuning
  static const String paginationPageSize = 'pagination_page_size';
  static const String cacheTimeoutMinutes = 'cache_timeout_minutes';
  static const String aiPreloadEnabled = 'ai_preload_enabled';

  /// Default values for all feature flags
  static const Map<String, dynamic> defaults = {
    // UI Experiments - default to enabled
    premiumLoadingIndicators: true,
    glassmorphismCards: true,
    animatedTransitions: true,
    hapticFeedback: true,

    // Feature Rollouts - default to enabled
    aiAssistant: true,
    familyTree: true,
    gamification: true,
    smartReminders: true,

    // A/B Test Variants - default variants
    onboardingVariant: 'control',
    homeScreenLayout: 'default',
    reminderFrequencyOptions: 'standard',

    // Performance Tuning
    paginationPageSize: 20,
    cacheTimeoutMinutes: 5,
    aiPreloadEnabled: true,
  };
}

/// Service for managing feature flags and A/B testing
/// Uses SharedPreferences for local storage. Can be extended to use
/// Firebase Remote Config for server-controlled flags.
class FeatureFlagsService {
  static FeatureFlagsService? _instance;
  final AppLoggerService _logger = AppLoggerService();
  bool _isInitialized = false;
  String? _userId;
  SharedPreferences? _prefs;

  // Local cache of flag values
  final Map<String, dynamic> _localCache = {};

  // Experiment assignment cache (persisted)
  final Map<String, String> _experimentAssignments = {};

  FeatureFlagsService._();

  static FeatureFlagsService get instance {
    _instance ??= FeatureFlagsService._();
    return _instance!;
  }

  /// Initialize the feature flags service
  Future<void> initialize({String? userId}) async {
    if (_isInitialized) return;

    _userId = userId;

    try {
      _prefs = await SharedPreferences.getInstance();

      // Load persisted experiment assignments
      await _loadExperimentAssignments();

      // Load any saved flag overrides
      await _loadSavedFlags();

      _isInitialized = true;

      _logger.info(
        'Feature flags initialized',
        category: LogCategory.service,
        tag: 'FeatureFlagsService',
      );
    } catch (e) {
      _logger.warning(
        'Failed to initialize feature flags, using defaults',
        category: LogCategory.service,
        tag: 'FeatureFlagsService',
        metadata: {'error': e.toString()},
      );
      _isInitialized = true; // Still mark as initialized with defaults
    }
  }

  /// Load saved flag values from SharedPreferences
  Future<void> _loadSavedFlags() async {
    if (_prefs == null) return;

    for (final key in FeatureFlags.defaults.keys) {
      final savedKey = 'feature_flag_$key';
      final defaultValue = FeatureFlags.defaults[key];

      if (defaultValue is bool && _prefs!.containsKey(savedKey)) {
        _localCache[key] = _prefs!.getBool(savedKey) ?? defaultValue;
      } else if (defaultValue is String && _prefs!.containsKey(savedKey)) {
        _localCache[key] = _prefs!.getString(savedKey) ?? defaultValue;
      } else if (defaultValue is int && _prefs!.containsKey(savedKey)) {
        _localCache[key] = _prefs!.getInt(savedKey) ?? defaultValue;
      }
    }
  }

  /// Get a boolean feature flag value
  bool getBool(String key) {
    if (_localCache.containsKey(key)) {
      return _localCache[key] as bool;
    }
    return FeatureFlags.defaults[key] as bool? ?? false;
  }

  /// Get a string feature flag value
  String getString(String key) {
    if (_localCache.containsKey(key)) {
      return _localCache[key] as String;
    }
    return FeatureFlags.defaults[key] as String? ?? '';
  }

  /// Get an integer feature flag value
  int getInt(String key) {
    if (_localCache.containsKey(key)) {
      return _localCache[key] as int;
    }
    return FeatureFlags.defaults[key] as int? ?? 0;
  }

  /// Get experiment variant for A/B testing
  /// Assigns user to a variant if not already assigned
  String getExperimentVariant(String experimentKey, List<String> variants) {
    // Check if already assigned
    if (_experimentAssignments.containsKey(experimentKey)) {
      return _experimentAssignments[experimentKey]!;
    }

    // Check for forced variant in local cache
    final forcedVariant = getString(experimentKey);
    if (forcedVariant.isNotEmpty && variants.contains(forcedVariant)) {
      _experimentAssignments[experimentKey] = forcedVariant;
      _saveExperimentAssignments();
      _logExperimentAssignment(experimentKey, forcedVariant);
      return forcedVariant;
    }

    // Randomly assign to a variant (deterministic based on user ID)
    final random = Random(_userId?.hashCode ?? DateTime.now().millisecondsSinceEpoch);
    final variantIndex = random.nextInt(variants.length);
    final assignedVariant = variants[variantIndex];

    _experimentAssignments[experimentKey] = assignedVariant;
    _saveExperimentAssignments();
    _logExperimentAssignment(experimentKey, assignedVariant);

    return assignedVariant;
  }

  /// Check if user is in a specific experiment variant
  bool isInVariant(String experimentKey, String variant) {
    return _experimentAssignments[experimentKey] == variant;
  }

  /// Log experiment assignment
  void _logExperimentAssignment(String experimentKey, String variant) {
    _logger.info(
      'Experiment assigned: $experimentKey -> $variant',
      category: LogCategory.analytics,
      tag: 'FeatureFlagsService',
      metadata: {
        'experiment': experimentKey,
        'variant': variant,
      },
    );
  }

  /// Track experiment conversion (user completed desired action)
  void trackExperimentConversion(String experimentKey, String conversionType) {
    final variant = _experimentAssignments[experimentKey];
    if (variant == null) return;

    _logger.info(
      'Experiment conversion: $experimentKey ($variant) -> $conversionType',
      category: LogCategory.analytics,
      tag: 'FeatureFlagsService',
      metadata: {
        'experiment': experimentKey,
        'variant': variant,
        'conversion_type': conversionType,
      },
    );
  }

  /// Load experiment assignments from persistent storage
  Future<void> _loadExperimentAssignments() async {
    try {
      final assignments = _prefs?.getStringList('experiment_assignments') ?? [];

      for (final assignment in assignments) {
        final parts = assignment.split(':');
        if (parts.length == 2) {
          _experimentAssignments[parts[0]] = parts[1];
        }
      }
    } catch (e) {
      _logger.warning(
        'Failed to load experiment assignments',
        category: LogCategory.service,
        tag: 'FeatureFlagsService',
      );
    }
  }

  /// Save experiment assignments to persistent storage
  Future<void> _saveExperimentAssignments() async {
    try {
      final assignments = _experimentAssignments.entries
          .map((e) => '${e.key}:${e.value}')
          .toList();
      await _prefs?.setStringList('experiment_assignments', assignments);
    } catch (e) {
      _logger.warning(
        'Failed to save experiment assignments',
        category: LogCategory.service,
        tag: 'FeatureFlagsService',
      );
    }
  }

  /// Override a flag locally (for testing or admin controls)
  Future<void> overrideFlag(String key, dynamic value) async {
    _localCache[key] = value;

    // Persist the override
    final savedKey = 'feature_flag_$key';
    if (value is bool) {
      await _prefs?.setBool(savedKey, value);
    } else if (value is String) {
      await _prefs?.setString(savedKey, value);
    } else if (value is int) {
      await _prefs?.setInt(savedKey, value);
    }
  }

  /// Clear local overrides and reset to defaults
  Future<void> clearOverrides() async {
    _localCache.clear();

    // Remove persisted overrides
    for (final key in FeatureFlags.defaults.keys) {
      await _prefs?.remove('feature_flag_$key');
    }
  }

  /// Get all current flag values (for debugging)
  Map<String, dynamic> getAllFlags() {
    final flags = <String, dynamic>{};

    for (final key in FeatureFlags.defaults.keys) {
      final defaultValue = FeatureFlags.defaults[key];
      if (defaultValue is bool) {
        flags[key] = getBool(key);
      } else if (defaultValue is String) {
        flags[key] = getString(key);
      } else if (defaultValue is int) {
        flags[key] = getInt(key);
      }
    }

    return flags;
  }

  /// Get all experiment assignments
  Map<String, String> getExperimentAssignments() {
    return Map.unmodifiable(_experimentAssignments);
  }
}

/// Provider for feature flags service
final featureFlagsServiceProvider = Provider<FeatureFlagsService>((ref) {
  return FeatureFlagsService.instance;
});

/// Provider for checking if a feature is enabled
final featureEnabledProvider = Provider.family<bool, String>((ref, featureKey) {
  final service = ref.watch(featureFlagsServiceProvider);
  return service.getBool(featureKey);
});

/// Provider for getting experiment variant
final experimentVariantProvider = Provider.family<String, ({String key, List<String> variants})>((ref, params) {
  final service = ref.watch(featureFlagsServiceProvider);
  return service.getExperimentVariant(params.key, params.variants);
});
