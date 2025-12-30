import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_logger_service.dart';

/// Immutable settings for pattern background animations.
@immutable
class PatternAnimationSettings {
  /// Enable slow rotation animation
  final bool rotationEnabled;

  /// Enable pulsing/breathing opacity animation
  final bool pulseEnabled;

  /// Enable parallax effect on scroll
  final bool parallaxEnabled;

  /// Enable shimmer/wave effect
  final bool shimmerEnabled;

  /// Enable touch ripple effect
  final bool touchRippleEnabled;

  /// Enable gyroscope-based parallax
  final bool gyroscopeEnabled;

  /// Enable touch follow glow effect
  final bool followTouchEnabled;

  /// Master intensity multiplier (0.0-1.0)
  final double animationIntensity;

  const PatternAnimationSettings({
    this.rotationEnabled = true,
    this.pulseEnabled = true,
    this.parallaxEnabled = true,
    this.shimmerEnabled = false, // Off by default (battery consideration)
    this.touchRippleEnabled = true,
    this.gyroscopeEnabled = false, // Off by default (requires sensor)
    this.followTouchEnabled = true,
    this.animationIntensity = 0.7,
  });

  /// Check if any animation effect is enabled
  bool get hasAnyAnimationEnabled =>
      rotationEnabled || pulseEnabled || parallaxEnabled || shimmerEnabled;

  /// Check if any touch effect is enabled
  bool get hasTouchEffectsEnabled =>
      touchRippleEnabled || followTouchEnabled;

  /// Check if master animations are enabled (for fallback to static)
  bool get isAnimationEnabled =>
      hasAnyAnimationEnabled || hasTouchEffectsEnabled || gyroscopeEnabled;

  PatternAnimationSettings copyWith({
    bool? rotationEnabled,
    bool? pulseEnabled,
    bool? parallaxEnabled,
    bool? shimmerEnabled,
    bool? touchRippleEnabled,
    bool? gyroscopeEnabled,
    bool? followTouchEnabled,
    double? animationIntensity,
  }) {
    return PatternAnimationSettings(
      rotationEnabled: rotationEnabled ?? this.rotationEnabled,
      pulseEnabled: pulseEnabled ?? this.pulseEnabled,
      parallaxEnabled: parallaxEnabled ?? this.parallaxEnabled,
      shimmerEnabled: shimmerEnabled ?? this.shimmerEnabled,
      touchRippleEnabled: touchRippleEnabled ?? this.touchRippleEnabled,
      gyroscopeEnabled: gyroscopeEnabled ?? this.gyroscopeEnabled,
      followTouchEnabled: followTouchEnabled ?? this.followTouchEnabled,
      animationIntensity: animationIntensity ?? this.animationIntensity,
    );
  }

  /// Convert to JSON map for persistence
  Map<String, dynamic> toJson() => {
        'rotationEnabled': rotationEnabled,
        'pulseEnabled': pulseEnabled,
        'parallaxEnabled': parallaxEnabled,
        'shimmerEnabled': shimmerEnabled,
        'touchRippleEnabled': touchRippleEnabled,
        'gyroscopeEnabled': gyroscopeEnabled,
        'followTouchEnabled': followTouchEnabled,
        'animationIntensity': animationIntensity,
      };

  /// Create from JSON map
  factory PatternAnimationSettings.fromJson(Map<String, dynamic> json) {
    return PatternAnimationSettings(
      rotationEnabled: json['rotationEnabled'] as bool? ?? true,
      pulseEnabled: json['pulseEnabled'] as bool? ?? true,
      parallaxEnabled: json['parallaxEnabled'] as bool? ?? true,
      shimmerEnabled: json['shimmerEnabled'] as bool? ?? false,
      touchRippleEnabled: json['touchRippleEnabled'] as bool? ?? true,
      gyroscopeEnabled: json['gyroscopeEnabled'] as bool? ?? false,
      followTouchEnabled: json['followTouchEnabled'] as bool? ?? true,
      animationIntensity: (json['animationIntensity'] as num?)?.toDouble() ?? 0.7,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatternAnimationSettings &&
          runtimeType == other.runtimeType &&
          rotationEnabled == other.rotationEnabled &&
          pulseEnabled == other.pulseEnabled &&
          parallaxEnabled == other.parallaxEnabled &&
          shimmerEnabled == other.shimmerEnabled &&
          touchRippleEnabled == other.touchRippleEnabled &&
          gyroscopeEnabled == other.gyroscopeEnabled &&
          followTouchEnabled == other.followTouchEnabled &&
          animationIntensity == other.animationIntensity;

  @override
  int get hashCode => Object.hash(
        rotationEnabled,
        pulseEnabled,
        parallaxEnabled,
        shimmerEnabled,
        touchRippleEnabled,
        gyroscopeEnabled,
        followTouchEnabled,
        animationIntensity,
      );
}

/// State notifier for pattern animation settings with persistence.
class PatternAnimationNotifier extends StateNotifier<PatternAnimationSettings> {
  static const String _prefsKey = 'pattern_animation_settings';
  final AppLoggerService _logger = AppLoggerService();

  PatternAnimationNotifier() : super(const PatternAnimationSettings()) {
    _loadSettings();
  }

  /// Load saved settings from shared preferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      if (jsonString != null) {
        // Parse individual values from stored keys
        state = PatternAnimationSettings(
          rotationEnabled: prefs.getBool('${_prefsKey}_rotation') ?? true,
          pulseEnabled: prefs.getBool('${_prefsKey}_pulse') ?? true,
          parallaxEnabled: prefs.getBool('${_prefsKey}_parallax') ?? true,
          shimmerEnabled: prefs.getBool('${_prefsKey}_shimmer') ?? false,
          touchRippleEnabled: prefs.getBool('${_prefsKey}_touchRipple') ?? true,
          gyroscopeEnabled: prefs.getBool('${_prefsKey}_gyroscope') ?? false,
          followTouchEnabled: prefs.getBool('${_prefsKey}_followTouch') ?? true,
          animationIntensity: prefs.getDouble('${_prefsKey}_intensity') ?? 0.7,
        );
      }
    } catch (e) {
      _logger.warning(
        'Failed to load pattern animation settings, using defaults',
        category: LogCategory.service,
        tag: 'PatternAnimationNotifier',
        metadata: {'error': e.toString()},
      );
    }
  }

  /// Save current settings to shared preferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, 'saved'); // Marker
      await prefs.setBool('${_prefsKey}_rotation', state.rotationEnabled);
      await prefs.setBool('${_prefsKey}_pulse', state.pulseEnabled);
      await prefs.setBool('${_prefsKey}_parallax', state.parallaxEnabled);
      await prefs.setBool('${_prefsKey}_shimmer', state.shimmerEnabled);
      await prefs.setBool('${_prefsKey}_touchRipple', state.touchRippleEnabled);
      await prefs.setBool('${_prefsKey}_gyroscope', state.gyroscopeEnabled);
      await prefs.setBool('${_prefsKey}_followTouch', state.followTouchEnabled);
      await prefs.setDouble('${_prefsKey}_intensity', state.animationIntensity);
    } catch (e) {
      _logger.warning(
        'Failed to save pattern animation settings',
        category: LogCategory.service,
        tag: 'PatternAnimationNotifier',
        metadata: {'error': e.toString()},
      );
    }
  }

  /// Update settings with new values
  void updateSettings(PatternAnimationSettings newSettings) {
    state = newSettings;
    _saveSettings();
  }

  /// Toggle rotation animation
  void toggleRotation() {
    state = state.copyWith(rotationEnabled: !state.rotationEnabled);
    _saveSettings();
  }

  /// Toggle pulse animation
  void togglePulse() {
    state = state.copyWith(pulseEnabled: !state.pulseEnabled);
    _saveSettings();
  }

  /// Toggle parallax effect
  void toggleParallax() {
    state = state.copyWith(parallaxEnabled: !state.parallaxEnabled);
    _saveSettings();
  }

  /// Toggle shimmer effect
  void toggleShimmer() {
    state = state.copyWith(shimmerEnabled: !state.shimmerEnabled);
    _saveSettings();
  }

  /// Toggle touch ripple effect
  void toggleTouchRipple() {
    state = state.copyWith(touchRippleEnabled: !state.touchRippleEnabled);
    _saveSettings();
  }

  /// Toggle gyroscope parallax
  void toggleGyroscope() {
    state = state.copyWith(gyroscopeEnabled: !state.gyroscopeEnabled);
    _saveSettings();
  }

  /// Toggle follow touch glow
  void toggleFollowTouch() {
    state = state.copyWith(followTouchEnabled: !state.followTouchEnabled);
    _saveSettings();
  }

  /// Set animation intensity (0.0-1.0)
  void setIntensity(double intensity) {
    state = state.copyWith(animationIntensity: intensity.clamp(0.0, 1.0));
    _saveSettings();
  }

  /// Enable all animations
  void enableAll() {
    state = const PatternAnimationSettings(
      rotationEnabled: true,
      pulseEnabled: true,
      parallaxEnabled: true,
      shimmerEnabled: true,
      touchRippleEnabled: true,
      gyroscopeEnabled: true,
      followTouchEnabled: true,
      animationIntensity: 0.7,
    );
    _saveSettings();
  }

  /// Disable all animations (use static patterns)
  void disableAll() {
    state = const PatternAnimationSettings(
      rotationEnabled: false,
      pulseEnabled: false,
      parallaxEnabled: false,
      shimmerEnabled: false,
      touchRippleEnabled: false,
      gyroscopeEnabled: false,
      followTouchEnabled: false,
      animationIntensity: 0.7,
    );
    _saveSettings();
  }
}

/// Provider for pattern animation settings management
final patternAnimationProvider =
    StateNotifierProvider<PatternAnimationNotifier, PatternAnimationSettings>(
  (ref) => PatternAnimationNotifier(),
);

/// Convenience provider to check if any pattern animation is enabled
final isPatternAnimationEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(patternAnimationProvider);
  return settings.isAnimationEnabled;
});

/// Convenience provider for touch effects enabled state
final isTouchEffectsEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(patternAnimationProvider);
  return settings.hasTouchEffectsEnabled;
});
