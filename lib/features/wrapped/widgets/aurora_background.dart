import 'package:flutter/material.dart';
import 'package:mesh_gradient/mesh_gradient.dart';

/// Fluid shader-based mesh gradient background that smoothly transitions
/// between per-page color palettes.
///
/// Uses [AnimatedMeshGradient] (GPU shader + vertices) for premium fluid
/// motion. Colors are interpolated via [TweenAnimationBuilder] so page
/// transitions feel smooth rather than snapping.
class AuroraBackground extends StatelessWidget {
  final List<Color> colors;
  final double speed;
  final double grain;

  const AuroraBackground({
    super.key,
    required this.colors,
    this.speed = 1.5,
    this.grain = 0.35,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<List<Color>>(
      tween: _ColorListTween(end: colors),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, animatedColors, _) {
        return SizedBox.expand(
          child: AnimatedMeshGradient(
            colors: animatedColors,
            options: AnimatedMeshGradientOptions(
              speed: speed,
              frequency: 2,
              amplitude: 35,
              grain: grain,
            ),
          ),
        );
      },
    );
  }
}

/// Interpolates a list of 4 [Color] values for smooth page transitions.
class _ColorListTween extends Tween<List<Color>> {
  _ColorListTween({required List<Color> super.end});

  @override
  List<Color> lerp(double t) {
    final b = begin ?? end!;
    final e = end!;
    return [
      for (var i = 0; i < e.length; i++)
        Color.lerp(b.length > i ? b[i] : e[i], e[i], t)!,
    ];
  }
}
