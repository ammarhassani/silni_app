import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import 'islamic_pattern_background.dart';

class GradientBackground extends ConsumerWidget {
  final Widget child;
  final Gradient? gradient;
  final bool animated;
  final bool showPattern;
  final double patternOpacity;

  const GradientBackground({
    super.key,
    required this.child,
    this.gradient,
    this.animated = false,
    this.showPattern = true,
    this.patternOpacity = 0.08,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeType = ref.watch(themeProvider);
    final themeColors = ref.watch(themeColorsProvider);

    // Use theme-aware gradient
    final defaultGradient = themeColors.backgroundGradient;

    Widget backgroundChild = child;

    // Wrap with Islamic pattern if enabled
    if (showPattern) {
      backgroundChild = IslamicPatternBackground(
        themeType: themeType,
        opacity: patternOpacity,
        child: child,
      );
    }

    if (animated) {
      return AnimatedGradientBackground(
        gradient: gradient ?? defaultGradient,
        child: backgroundChild,
      );
    }

    return Container(
      decoration: BoxDecoration(gradient: gradient ?? defaultGradient),
      child: backgroundChild,
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

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
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

    _updateAnimations();
  }

  @override
  void didUpdateWidget(AnimatedGradientBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update animations when gradient changes (theme change)
    if (oldWidget.gradient != widget.gradient) {
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    if (widget.gradient is! LinearGradient) return;

    final colors = (widget.gradient as LinearGradient).colors;
    if (colors.isEmpty) return;

    final color1 = colors[0];
    final color2 = colors.length > 1 ? colors[1] : color1;
    final color3 = colors.length > 2 ? colors[2] : color2;

    _colorAnimation1 = ColorTween(
      begin: color1,
      end: color2,
    ).animate(_controller);

    _colorAnimation2 = ColorTween(
      begin: color2,
      end: color3,
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

  const DramaticBackground({super.key, required this.child, this.colors});

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
