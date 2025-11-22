import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  final bool animated;

  const GradientBackground({
    super.key,
    required this.child,
    this.gradient,
    this.animated = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultGradient = isDark
        ? AppColors.backgroundGradientDark
        : AppColors.backgroundGradientLight;

    if (animated) {
      return AnimatedGradientBackground(
        gradient: gradient ?? defaultGradient,
        child: child,
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? defaultGradient,
      ),
      child: child,
    );
  }
}

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final Gradient gradient;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
    required this.gradient,
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState
    extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation1;
  late Animation<Color?> _colorAnimation2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    final colors = (widget.gradient as LinearGradient).colors;

    _colorAnimation1 = ColorTween(
      begin: colors[0],
      end: colors[1],
    ).animate(_controller);

    _colorAnimation2 = ColorTween(
      begin: colors[1],
      end: colors.length > 2 ? colors[2] : colors[1],
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _colorAnimation1.value ?? Colors.transparent,
                _colorAnimation2.value ?? Colors.transparent,
              ],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Dramatic Background with Particles Effect
class DramaticBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;

  const DramaticBackground({
    super.key,
    required this.child,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColors = [
      AppColors.islamicGreenDark,
      AppColors.islamicGreenPrimary,
      AppColors.islamicGreenLight,
    ];

    return Stack(
      children: [
        // Base gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors ?? defaultColors,
            ),
          ),
        ),
        // Content (removed overlay pattern since assets/images/pattern.png doesn't exist)
        child,
      ],
    );
  }
}
