import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/theme_provider.dart';
import '../utils/ui_helpers.dart';

/// A pill-shaped glassmorphism container for page titles.
///
/// Wraps text in a frosted glass pill that adapts to the current theme.
/// Supports optional [leading] and [trailing] widgets alongside the title.
class GlassPillTitle extends ConsumerWidget {
  final String text;
  final TextStyle? style;
  final Widget? leading;
  final Widget? trailing;
  final Widget? subtitle;

  const GlassPillTitle({
    super.key,
    required this.text,
    this.style,
    this.leading,
    this.trailing,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    final titleStyle = style ??
        AppTypography.headlineMedium.copyWith(
          color: themeColors.textOnGradient,
          fontWeight: FontWeight.bold,
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeColors.glassHighlight,
            themeColors.glassBackground,
          ],
        ),
        border: Border.all(
          color: themeColors.glassBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: UIHelpers.withOpacity(themeColors.primaryDark, 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: subtitle != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(text, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      subtitle!,
                    ],
                  )
                : Text(text, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}
