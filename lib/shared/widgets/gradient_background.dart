import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';
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

class AnimatedGradientBackground extends StatelessWidget {
  final Widget child;
  final Gradient gradient;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final tween = MultiTween<_GradientProps>()
      ..add(
        _GradientProps.color1,
        (gradient as LinearGradient).colors[0].tweenTo(
              (gradient as LinearGradient).colors[1],
            ),
        const Duration(seconds: 3),
      )
      ..add(
        _GradientProps.color2,
        (gradient as LinearGradient).colors[1].tweenTo(
              (gradient as LinearGradient).colors[2],
            ),
        const Duration(seconds: 3),
      );

    return MirrorAnimationBuilder<MultiTweenValues<_GradientProps>>(
      tween: tween,
      duration: const Duration(seconds: 6),
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                value.get(_GradientProps.color1),
                value.get(_GradientProps.color2),
              ],
            ),
          ),
          child: this.child,
        );
      },
    );
  }
}

enum _GradientProps { color1, color2 }

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
        // Overlay pattern
        Opacity(
          opacity: 0.1,
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/pattern.png'),
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
        ),
        // Content
        child,
      ],
    );
  }
}
