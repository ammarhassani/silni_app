import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/pattern_animation_constants.dart';
import '../../core/providers/pattern_animation_provider.dart';
import 'islamic_pattern_background.dart';

/// Internal class for managing individual ripple animations
class _RippleAnimation {
  final Offset center;
  final AnimationController controller;

  _RippleAnimation({required this.center, required this.controller});
}

/// Orchestrates multiple animation effects for pattern backgrounds.
///
/// Manages vertical flow, pulse, shimmer animations along with touch ripples
/// and parallax effects. Extends ChangeNotifier to trigger repaints.
class PatternAnimationController extends ChangeNotifier {
  final TickerProvider vsync;
  PatternAnimationSettings _settings;

  // Animation controllers
  late AnimationController _flowController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  // Touch ripple management
  final List<_RippleAnimation> _ripples = [];
  Offset? _currentTouchPosition;

  // Parallax state (from scroll or gyroscope)
  Offset _parallaxOffset = Offset.zero;

  // Track if controllers are initialized
  bool _isDisposed = false;

  PatternAnimationController({
    required this.vsync,
    required PatternAnimationSettings settings,
  }) : _settings = settings {
    _initializeControllers();
  }

  PatternAnimationSettings get settings => _settings;

  void _initializeControllers() {
    // Vertical flow animation - slow upward drift
    _flowController = AnimationController(
      vsync: vsync,
      duration: PatternAnimationConstants.verticalFlowCycle,
    );
    if (_settings.rotationEnabled) {
      _flowController.repeat();
    }

    // Pulse/breathing animation
    _pulseController = AnimationController(
      vsync: vsync,
      duration: PatternAnimationConstants.pulseCycle,
    );
    if (_settings.pulseEnabled) {
      _pulseController.repeat(reverse: true);
    }

    // Shimmer wave animation
    _shimmerController = AnimationController(
      vsync: vsync,
      duration: PatternAnimationConstants.shimmerCycle,
    );
    if (_settings.shimmerEnabled) {
      _shimmerController.repeat();
    }

    // Listen to all controllers to trigger repaints
    _flowController.addListener(_notifyIfNotDisposed);
    _pulseController.addListener(_notifyIfNotDisposed);
    _shimmerController.addListener(_notifyIfNotDisposed);
  }

  void _notifyIfNotDisposed() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // ============ COMPUTED VALUES FOR PAINTERS ============

  /// Current vertical flow offset (patterns drift upward)
  Offset get verticalFlowOffset {
    if (!_settings.rotationEnabled) return Offset.zero;

    // Create smooth continuous upward drift
    final flowDistance = PatternAnimationConstants.verticalFlowDistance;
    final offset = -_flowController.value * flowDistance * _settings.animationIntensity;

    return Offset(0, offset);
  }

  /// Current pulse opacity multiplier
  double get pulseMultiplier {
    if (!_settings.pulseEnabled) return 1.0;

    // Simple smooth oscillation between min and max
    final minMult = 0.6;  // 60% of base opacity at minimum
    final maxMult = 1.4;  // 140% of base opacity at maximum

    // Smooth sine wave (0 to 1 to 0)
    final t = _pulseController.value;
    final wave = math.sin(t * math.pi);

    // Interpolate based on intensity
    final multiplier = minMult + (maxMult - minMult) * wave;
    return 1.0 + (multiplier - 1.0) * _settings.animationIntensity;
  }

  /// Current shimmer position (0.0 to 1.0)
  double get shimmerPosition {
    if (!_settings.shimmerEnabled) return -1.0; // Off-screen when disabled
    return _shimmerController.value;
  }

  /// Current parallax offset (combined scroll + gyro + flow)
  Offset get parallaxOffset {
    var offset = verticalFlowOffset;

    if (_settings.parallaxEnabled || _settings.gyroscopeEnabled) {
      offset += _parallaxOffset * _settings.animationIntensity;
    }

    return offset;
  }

  /// List of active touch ripples
  List<TouchRipple> get ripples {
    if (!_settings.touchRippleEnabled) return const [];
    return _ripples
        .map((r) => TouchRipple(
              center: r.center,
              progress: r.controller.value,
            ))
        .toList();
  }

  /// Current touch position for glow effect
  Offset? get touchPosition {
    if (!_settings.followTouchEnabled) return null;
    return _currentTouchPosition;
  }

  // ============ TOUCH HANDLING ============

  /// Add a touch ripple at the given position
  void addRipple(Offset position) {
    if (!_settings.touchRippleEnabled || _isDisposed) return;

    // Remove oldest ripple if at limit
    if (_ripples.length >= PatternAnimationConstants.maxActiveRipples) {
      final oldest = _ripples.removeAt(0);
      oldest.controller.dispose();
    }

    final controller = AnimationController(
      vsync: vsync,
      duration: PatternAnimationConstants.rippleDuration,
    );

    controller.addListener(_notifyIfNotDisposed);
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _removeRipple(controller);
      }
    });

    _ripples.add(_RippleAnimation(center: position, controller: controller));
    controller.forward();
  }

  void _removeRipple(AnimationController controller) {
    _ripples.removeWhere((r) {
      if (r.controller == controller) {
        r.controller.dispose();
        return true;
      }
      return false;
    });
    _notifyIfNotDisposed();
  }

  /// Update touch position for glow effect
  void updateTouchPosition(Offset? position) {
    if (!_settings.followTouchEnabled) return;
    _currentTouchPosition = position;
    notifyListeners();
  }

  // ============ PARALLAX HANDLING ============

  /// Update parallax offset from scroll position
  void updateScrollParallax(double scrollOffset) {
    if (!_settings.parallaxEnabled || _isDisposed) return;

    final maxOffset = PatternAnimationConstants.parallaxMaxOffset;
    final multiplier = PatternAnimationConstants.parallaxScrollMultiplier;

    _parallaxOffset = Offset(
      0,
      (-scrollOffset * multiplier).clamp(-maxOffset, maxOffset),
    );
    notifyListeners();
  }

  /// Update parallax offset from gyroscope data
  void updateGyroscopeParallax(double x, double y) {
    if (!_settings.gyroscopeEnabled || _isDisposed) return;

    final maxOffset = PatternAnimationConstants.gyroscopeMaxOffset;

    _parallaxOffset = Offset(
      (x * maxOffset).clamp(-maxOffset, maxOffset),
      (y * maxOffset).clamp(-maxOffset, maxOffset),
    );
    notifyListeners();
  }

  // ============ LIFECYCLE MANAGEMENT ============

  /// Pause all animations (for battery saving when app is backgrounded)
  void pause() {
    if (_isDisposed) return;
    _flowController.stop();
    _pulseController.stop();
    _shimmerController.stop();
  }

  /// Resume animations
  void resume() {
    if (_isDisposed) return;
    if (_settings.rotationEnabled) _flowController.repeat();
    if (_settings.pulseEnabled) _pulseController.repeat(reverse: true);
    if (_settings.shimmerEnabled) _shimmerController.repeat();
  }

  /// Update settings and restart appropriate animations
  void updateSettings(PatternAnimationSettings newSettings) {
    if (_isDisposed) return;

    _settings = newSettings;

    // Handle vertical flow (was rotation)
    if (newSettings.rotationEnabled && !_flowController.isAnimating) {
      _flowController.repeat();
    } else if (!newSettings.rotationEnabled && _flowController.isAnimating) {
      _flowController.stop();
      _flowController.reset();
    }

    // Handle pulse
    if (newSettings.pulseEnabled && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!newSettings.pulseEnabled && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }

    // Handle shimmer
    if (newSettings.shimmerEnabled && !_shimmerController.isAnimating) {
      _shimmerController.repeat();
    } else if (!newSettings.shimmerEnabled && _shimmerController.isAnimating) {
      _shimmerController.stop();
      _shimmerController.reset();
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;

    _flowController.removeListener(_notifyIfNotDisposed);
    _pulseController.removeListener(_notifyIfNotDisposed);
    _shimmerController.removeListener(_notifyIfNotDisposed);

    _flowController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();

    for (final ripple in _ripples) {
      ripple.controller.dispose();
    }
    _ripples.clear();

    super.dispose();
  }
}
