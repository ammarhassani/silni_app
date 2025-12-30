import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/pattern_animation_provider.dart';
import '../../core/services/gyroscope_service.dart';
import '../../core/theme/app_themes.dart';
import 'islamic_pattern_background.dart';
import 'pattern_animation_controller.dart';

/// Animated Islamic pattern background with touch interactivity.
///
/// Replaces [IslamicPatternBackground] when animations are enabled.
/// Automatically falls back to static version when animations disabled.
class AnimatedIslamicPatternBackground extends ConsumerStatefulWidget {
  final AppThemeType themeType;
  final Widget child;
  final double opacity;
  final ScrollController? scrollController;

  const AnimatedIslamicPatternBackground({
    super.key,
    required this.themeType,
    required this.child,
    this.opacity = 0.1,
    this.scrollController,
  });

  @override
  ConsumerState<AnimatedIslamicPatternBackground> createState() =>
      _AnimatedIslamicPatternBackgroundState();
}

class _AnimatedIslamicPatternBackgroundState
    extends ConsumerState<AnimatedIslamicPatternBackground>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  PatternAnimationController? _animationController;
  StreamSubscription<GyroscopeData>? _gyroscopeSubscription;
  PatternAnimationSettings? _lastSettings;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _setupScrollListener();
  }

  void _initializeAnimations() {
    final settings = ref.read(patternAnimationProvider);
    _lastSettings = settings;

    if (settings.isAnimationEnabled) {
      _animationController = PatternAnimationController(
        vsync: this,
        settings: settings,
      );
      _setupGyroscope(settings);
    }
  }

  void _setupScrollListener() {
    widget.scrollController?.addListener(_onScroll);
  }

  void _onScroll() {
    if (widget.scrollController == null || _animationController == null) return;
    _animationController!.updateScrollParallax(widget.scrollController!.offset);
  }

  void _setupGyroscope(PatternAnimationSettings settings) {
    if (!settings.gyroscopeEnabled) return;

    final gyroService = GyroscopeService.instance;
    if (!gyroService.isAvailable) return;

    gyroService.startListening();
    _gyroscopeSubscription = gyroService.stream?.listen((data) {
      _animationController?.updateGyroscopeParallax(data.x, data.y);
    });
  }

  void _stopGyroscope() {
    _gyroscopeSubscription?.cancel();
    _gyroscopeSubscription = null;
    GyroscopeService.instance.stopListening();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Battery efficiency: pause when backgrounded
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _animationController?.pause();
      _stopGyroscope();
    } else if (state == AppLifecycleState.resumed) {
      _animationController?.resume();
      final settings = ref.read(patternAnimationProvider);
      if (settings.gyroscopeEnabled) {
        _setupGyroscope(settings);
      }
    }
  }

  @override
  void didUpdateWidget(AnimatedIslamicPatternBackground oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle scroll controller changes
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_onScroll);
      widget.scrollController?.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.scrollController?.removeListener(_onScroll);
    _stopGyroscope();
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(patternAnimationProvider);

    // Handle settings changes
    if (_lastSettings != settings) {
      _handleSettingsChange(settings);
      _lastSettings = settings;
    }

    // Fall back to static version if animations disabled
    if (!settings.isAnimationEnabled || _animationController == null) {
      return IslamicPatternBackground(
        themeType: widget.themeType,
        opacity: widget.opacity,
        child: widget.child,
      );
    }

    return Stack(
      children: [
        // Animated pattern layer with touch detection
        Positioned.fill(
          child: RepaintBoundary(
            child: GestureDetector(
              onTapDown: (details) {
                _animationController?.addRipple(details.localPosition);
              },
              onPanStart: (details) {
                _animationController?.updateTouchPosition(details.localPosition);
              },
              onPanUpdate: (details) {
                _animationController?.updateTouchPosition(details.localPosition);
              },
              onPanEnd: (_) {
                _animationController?.updateTouchPosition(null);
              },
              onPanCancel: () {
                _animationController?.updateTouchPosition(null);
              },
              behavior: HitTestBehavior.translucent,
              child: AnimatedBuilder(
                animation: _animationController!,
                builder: (context, _) {
                  return CustomPaint(
                    painter: getAnimatedPatternPainter(
                      themeType: widget.themeType,
                      opacity: widget.opacity,
                      pulseMultiplier: _animationController!.pulseMultiplier,
                      parallaxOffset: _animationController!.parallaxOffset,
                      shimmerPosition: _animationController!.shimmerPosition,
                      ripples: _animationController!.ripples,
                      touchPosition: _animationController!.touchPosition,
                    ),
                    willChange: true,
                  );
                },
              ),
            ),
          ),
        ),
        // Content on top
        widget.child,
      ],
    );
  }

  void _handleSettingsChange(PatternAnimationSettings newSettings) {
    // Initialize controller if needed
    if (newSettings.isAnimationEnabled && _animationController == null) {
      _animationController = PatternAnimationController(
        vsync: this,
        settings: newSettings,
      );
    }

    // Update existing controller
    if (_animationController != null) {
      _animationController!.updateSettings(newSettings);
    }

    // Handle gyroscope toggle
    if (newSettings.gyroscopeEnabled && !(_lastSettings?.gyroscopeEnabled ?? false)) {
      _setupGyroscope(newSettings);
    } else if (!newSettings.gyroscopeEnabled && (_lastSettings?.gyroscopeEnabled ?? false)) {
      _stopGyroscope();
    }

    // Dispose controller if no longer needed
    if (!newSettings.isAnimationEnabled && _animationController != null) {
      _animationController?.dispose();
      _animationController = null;
    }
  }
}
