import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_themes.dart';
import 'islamic_pattern_background.dart';

/// Pass-through to the static [IslamicPatternBackground].
///
/// Phase 9.X.D.B hot-fix #11 (heat): this widget previously hosted a
/// [PatternAnimationController] driving 3 infinite [AnimationController]s
/// (vertical-flow, pulse, shimmer) which each notified listeners at 60fps.
/// That drove a [CustomPaint] with `willChange: true` (which disables
/// Flutter's GPU raster cache), so every gradient-bg screen sat at full GPU
/// utilization continuously — the iPhone 15 Pro got noticeably warm after
/// ~2 minutes of normal use.
///
/// Hard pass-through to the static pattern. The motion infrastructure
/// ([PatternAnimationController], [PatternAnimationSettings]) lives on
/// untouched in case we add a per-user "background motion" opt-in toggle in
/// settings later, but no caller currently reaches it.
///
/// Kept as a `ConsumerWidget` (not deleted) because dozens of callers
/// import this name; deleting would touch every gradient-bg screen.
class AnimatedIslamicPatternBackground extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    return IslamicPatternBackground(
      themeType: themeType,
      opacity: opacity,
      child: child,
    );
  }
}
