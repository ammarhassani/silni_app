import 'package:flutter/material.dart';

/// Icon that explicitly mirrors itself in RTL, bypassing the [IconData]
/// `matchTextDirection` metadata.
///
/// Why this widget exists: Flutter's [Icon] widget already auto-mirrors any
/// [IconData] with `matchTextDirection: true` (which includes
/// `arrow_back_ios_rounded`, `arrow_forward_ios_rounded`, `chevron_*_rounded`,
/// etc.) when ambient `Directionality` is RTL. In theory this should "just
/// work" for an Arabic-locale app like Silni.
///
/// In practice, the founder reported back/forward chevrons rendering in the
/// wrong direction in some screens. Whether the cause is a Flutter
/// version-specific glitch, a subtle `Directionality` override, or a custom
/// theme-icon shim, the deterministic fix is to handle the mirror ourselves:
/// disable the icon-level auto-mirror by passing `textDirection: ltr`, then
/// apply our own [Transform.flip] when ambient is RTL.
///
/// Pass the icon as you would for LTR (e.g. `Icons.arrow_back_ios_rounded`
/// for a back button); the widget mirrors it in RTL automatically.
class DirectionalIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double? size;
  final String? semanticLabel;

  const DirectionalIcon(
    this.icon, {
    super.key,
    this.color,
    this.size,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final iconWidget = Icon(
      icon,
      color: color,
      size: size,
      semanticLabel: semanticLabel,
      // Suppress matchTextDirection auto-mirror — we own the flip below so
      // the behavior is predictable and uniform across the app.
      textDirection: TextDirection.ltr,
    );
    if (!isRtl) return iconWidget;
    return Transform.flip(flipX: true, child: iconWidget);
  }
}
