import 'package:flutter/animation.dart';

/// Animation constants for Islamic pattern background effects.
/// Controls durations, intensities, and limits for pattern animations.
class PatternAnimationConstants {
  PatternAnimationConstants._();

  // ============ ANIMATION DURATIONS ============

  /// Vertical flow cycle - slow upward drift
  static const Duration verticalFlowCycle = Duration(seconds: 30);

  /// Breathing/pulse cycle - subtle opacity oscillation
  static const Duration pulseCycle = Duration(seconds: 3);

  /// Shimmer wave pass duration
  static const Duration shimmerCycle = Duration(seconds: 6);

  /// Touch ripple expansion duration
  static const Duration rippleDuration = Duration(milliseconds: 600);

  /// Touch glow fade out duration
  static const Duration touchGlowFade = Duration(milliseconds: 300);

  // ============ VERTICAL FLOW SETTINGS ============

  /// Maximum vertical drift distance in pixels
  static const double verticalFlowDistance = 100.0;

  // ============ PULSE/BREATHING SETTINGS ============

  /// Minimum opacity during pulse (dimmer state)
  static const double pulseMinOpacity = 0.06;

  /// Maximum opacity during pulse (brighter state)
  static const double pulseMaxOpacity = 0.14;

  // ============ PARALLAX SETTINGS ============

  /// Maximum pixel offset for scroll-based parallax
  static const double parallaxMaxOffset = 20.0;

  /// Maximum pixel offset for gyroscope-based parallax
  static const double gyroscopeMaxOffset = 15.0;

  /// Parallax scroll multiplier (offset = scroll * multiplier)
  static const double parallaxScrollMultiplier = 0.1;

  // ============ SHIMMER SETTINGS ============

  /// Width of shimmer highlight as fraction of canvas (0.0-1.0)
  static const double shimmerWidth = 0.3;

  /// Shimmer highlight opacity boost
  static const double shimmerOpacityBoost = 0.08;

  // ============ TOUCH RIPPLE SETTINGS ============

  /// Maximum ripple expansion radius
  static const double rippleMaxRadius = 150.0;

  /// Maximum concurrent ripples (for performance)
  static const int maxActiveRipples = 3;

  /// Ripple start opacity
  static const double rippleStartOpacity = 0.3;

  // ============ TOUCH GLOW SETTINGS ============

  /// Radius of touch follow glow effect
  static const double touchGlowRadius = 80.0;

  /// Touch glow opacity
  static const double touchGlowOpacity = 0.15;

  // ============ PERFORMANCE SETTINGS ============

  /// Reduced opacity when app is backgrounded or in low power mode
  static const double lowPowerOpacity = 0.05;

  /// Gyroscope sampling period (20Hz for smooth parallax)
  static const Duration gyroscopeSamplingPeriod = Duration(milliseconds: 50);

  // ============ CURVES ============

  /// Curve for ripple expansion
  static const Curve rippleCurve = Curves.easeOut;

  /// Curve for glow fade
  static const Curve glowFadeCurve = Curves.easeInOut;

  /// Curve for pulse breathing
  static const Curve pulseCurve = Curves.easeInOut;
}
