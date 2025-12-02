import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

/// Animated counter widget that rolls digits when value changes
/// Shows a glow effect and scale animation when increasing
class AnimatedCounter extends StatefulWidget {
  final int value;
  final TextStyle? style;
  final Color? glowColor;
  final bool showGlow;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.glowColor,
    this.showGlow = true,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late int _previousValue;
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isIncreasing = false;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(
      begin: _previousValue.toDouble(),
      end: widget.value.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _previousValue = oldWidget.value;
      _isIncreasing = widget.value > _previousValue;

      _animation = Tween<double>(
        begin: _previousValue.toDouble(),
        end: widget.value.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));

      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = widget.style ?? AppTypography.numberMedium;
    final glowColor = widget.glowColor ?? AppColors.premiumGold;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentValue = _animation.value.round();

        Widget counterText = Text(
          currentValue.toString(),
          style: textStyle,
        );

        // Add glow effect when increasing
        if (widget.showGlow && _isIncreasing && _controller.isAnimating) {
          counterText = Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: counterText,
          );
        }

        // Add scale animation when increasing
        if (_isIncreasing && _controller.isAnimating) {
          counterText = counterText
              .animate(
                autoPlay: true,
              )
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.2, 1.2),
                duration: 150.ms,
                curve: Curves.easeOut,
              )
              .then()
              .scale(
                begin: const Offset(1.2, 1.2),
                end: const Offset(1.0, 1.0),
                duration: 150.ms,
                curve: Curves.easeIn,
              );
        }

        return counterText;
      },
    );
  }
}

/// Simple animated counter without glow effects
/// Useful for displaying counts in compact spaces
class SimpleAnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;

  const SimpleAnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: value, end: value),
      duration: duration,
      builder: (context, value, child) {
        return Text(
          value.toString(),
          style: style ?? AppTypography.numberSmall,
        );
      },
    );
  }
}
