import 'package:flutter/animation.dart';

/// Standardized animation constants for consistent micro-interactions
/// across the entire app. Use these instead of hardcoded durations/curves.
class AppAnimations {
  AppAnimations._();

  // ============ DURATIONS ============

  /// 100ms - For instant micro-interactions (button press feedback, toggles)
  static const Duration instant = Duration(milliseconds: 100);

  /// 200ms - For fast transitions (hover states, ripples, quick feedback)
  static const Duration fast = Duration(milliseconds: 200);

  /// 300ms - For normal transitions (page transitions, modals, standard animations)
  static const Duration normal = Duration(milliseconds: 300);

  /// 400ms - For modal/sheet transitions
  static const Duration modal = Duration(milliseconds: 400);

  /// 500ms - For slow/emphasized transitions (complex reveals, important changes)
  static const Duration slow = Duration(milliseconds: 500);

  /// 800ms - For dramatic celebrations (level-up, achievements, confetti)
  static const Duration dramatic = Duration(milliseconds: 800);

  /// 1200ms - For extended celebrations (confetti duration, particle effects)
  static const Duration celebration = Duration(milliseconds: 1200);

  /// 2000ms - For looping animations (pulse, shimmer cycles)
  static const Duration loop = Duration(milliseconds: 2000);

  // ============ CURVES ============

  /// Standard entry curve - elements appearing on screen
  static const Curve enterCurve = Curves.easeOut;

  /// Standard exit curve - elements leaving the screen
  static const Curve exitCurve = Curves.easeIn;

  /// Toggle/switch curve - bi-directional state changes
  static const Curve toggleCurve = Curves.easeInOut;

  /// Bounce curve - playful, celebratory animations
  static const Curve bounceCurve = Curves.elasticOut;

  /// Overshoot curve - slight bounce past target then settle
  static const Curve overshootCurve = Curves.easeOutBack;

  /// Decelerate curve - quick start, slow finish (for attention)
  static const Curve decelerateCurve = Curves.decelerate;

  /// Spring curve - natural physics-based feel
  static const Curve springCurve = Curves.fastOutSlowIn;

  // ============ STAGGER DELAYS ============

  /// Delay between staggered list items
  static const Duration staggerDelay = Duration(milliseconds: 50);

  /// Delay between staggered grid items
  static const Duration gridStaggerDelay = Duration(milliseconds: 30);

  /// Delay for sequential animations in celebration modals
  static const Duration celebrationStagger = Duration(milliseconds: 150);

  // ============ SCALE VALUES ============

  /// Button press scale (slightly smaller when pressed)
  static const double pressedScale = 0.95;

  /// Button release scale (normal)
  static const double normalScale = 1.0;

  /// Icon tap pulse scale (slightly larger for emphasis)
  static const double pulseScale = 1.1;

  /// Celebration scale (bigger for impact)
  static const double celebrationScale = 1.2;

  /// Entry scale start (smaller, then grows in)
  static const double entryScaleStart = 0.8;

  // ============ OPACITY VALUES ============

  /// Pressed/disabled opacity
  static const double pressedOpacity = 0.7;

  /// Hover opacity
  static const double hoverOpacity = 0.9;

  /// Disabled element opacity
  static const double disabledOpacity = 0.5;

  /// Glass effect background opacity
  static const double glassOpacity = 0.15;

  // ============ SLIDE OFFSETS ============

  /// Slide up entry offset
  static const double slideUpOffset = 0.1;

  /// Modal slide up offset
  static const double modalSlideOffset = 0.3;

  /// Floating element offset (points, toasts)
  static const double floatOffset = 100.0;

  // ============ HELPER METHODS ============

  /// Get stagger delay for item at index
  static Duration getStaggerDelay(int index, {Duration? baseDelay}) {
    return (baseDelay ?? staggerDelay) * index;
  }

  /// Get animation duration scaled by a factor
  static Duration scaled(Duration base, double factor) {
    return Duration(milliseconds: (base.inMilliseconds * factor).round());
  }
}
