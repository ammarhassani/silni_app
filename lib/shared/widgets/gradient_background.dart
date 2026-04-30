import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';
import 'islamic_pattern_background.dart';

/// Static gradient background with the Islamic star pattern overlay.
///
/// `animated: true` was historically a flag that routed through an
/// `AnimatedGradientBackground` (6s color tween at 60fps) — that path was
/// removed in the iPhone 15 Pro heat fix and the orphaned class has been
/// dropped entirely. The flag is kept on the API for backward compat with
/// existing callers but is now a no-op.
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
    final defaultGradient = themeColors.backgroundGradient;

    Widget backgroundChild = child;
    if (showPattern) {
      backgroundChild = IslamicPatternBackground(
        themeType: themeType,
        opacity: patternOpacity,
        child: child,
      );
    }

    return Container(
      decoration: BoxDecoration(gradient: gradient ?? defaultGradient),
      child: backgroundChild,
    );
  }
}
