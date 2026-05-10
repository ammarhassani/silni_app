import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/theme_provider.dart';
import 'glass_card.dart';

/// A distinctive glass dialog that mirrors the app's premium-tile visual
/// language — gradient background, decorative orbs, accent-tinted icon
/// header, and glass content surface. Use this in place of [AlertDialog]
/// across the app so dialogs feel hand-crafted rather than Material-stock.
///
/// Wrap in [showDialog] like any standard dialog; the widget handles its
/// own [Dialog] backing and inset padding.
class GlassDialog extends ConsumerWidget {
  const GlassDialog({
    super.key,
    required this.title,
    required this.content,
    this.subtitle,
    this.icon,
    this.iconAccent,
    this.actions = const [],
    this.actionsAxis = Axis.horizontal,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconAccent;
  final Widget content;
  final List<Widget> actions;
  final Axis actionsAxis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final accent = iconAccent ?? themeColors.primary;
    final width = MediaQuery.of(context).size.width - (AppSpacing.md * 2);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: GlassCard(
        width: width,
        padding: EdgeInsets.zero,
        borderRadius: AppSpacing.radiusLg,
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            accent.withValues(alpha: 0.22),
            themeColors.primary.withValues(alpha: 0.18),
            themeColors.primaryDark.withValues(alpha: 0.12),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Stack(
            children: [
              // Radial glow (top-right)
              Positioned(
                top: -32,
                right: -32,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accent.withValues(alpha: 0.35),
                        accent.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Orb (bottom-left)
              Positioned(
                left: -20,
                bottom: -28,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.14),
                  ),
                ),
              ),
              // Small accent orb
              Positioned(
                left: 60,
                top: 12,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.18),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (icon != null) ...[
                      Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withValues(alpha: 0.22),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.55),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(icon, color: accent, size: 28),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Text(
                      title,
                      style: AppTypography.titleLarge.copyWith(
                        color: themeColors.textOnGradient,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: themeColors.textOnGradient
                              .withValues(alpha: 0.75),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    content,
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _buildActions(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    if (actionsAxis == Axis.vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            actions[i],
          ],
        ],
      );
    }
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(child: actions[i]),
        ],
      ],
    );
  }
}

/// A circular glass icon button — tinted glass fill, soft border, theme
/// accent icon. Replacement for stock Material [IconButton] in transparent
/// app bars and overlays where ripple-on-bar visual is unwanted.
class GlassIconButton extends ConsumerWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 40,
    this.iconSize = 20,
  });

  final Widget icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: themeColors.textOnGradient.withValues(alpha: 0.1),
            border: Border.all(
              color: themeColors.textOnGradient.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Center(child: icon),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// A glass-styled secondary action button for use inside [GlassDialog]
/// (and anywhere else a non-primary tappable action is needed). Subtle
/// gradient fill, glass border, theme-aware text color.
class GlassActionButton extends ConsumerWidget {
  const GlassActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isDestructive = false,
  });

  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isDestructive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final color = isDestructive
        ? themeColors.statusError
        : themeColors.textOnGradient;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          height: AppSpacing.buttonHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: color, size: 18),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                text,
                style: AppTypography.buttonMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
