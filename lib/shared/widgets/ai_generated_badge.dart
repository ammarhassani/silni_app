import 'package:flutter/material.dart';

/// Small inline tag that marks visibly AI-generated content.
///
/// Subtle by design — same color as secondary text, smaller font.
/// Goal: honesty about what's AI vs static, no surprise to the user.
class AIGeneratedBadge extends StatelessWidget {
  const AIGeneratedBadge({super.key, this.color});

  /// Optional color override. Defaults to a muted version of the surrounding
  /// text color to stay quiet on glassmorphic backgrounds.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final defaultColor = DefaultTextStyle.of(context).style.color ?? Colors.white;
    final effectiveColor = (color ?? defaultColor).withValues(alpha: 0.55);
    return Text(
      '✨ AI',
      style: TextStyle(
        color: effectiveColor,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
    );
  }
}
