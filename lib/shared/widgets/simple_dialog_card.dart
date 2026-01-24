import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/theme_provider.dart';
import '../utils/ui_helpers.dart';

/// A simple card for use in dialogs - no animations to avoid layout issues
class SimpleDialogCard extends ConsumerWidget {
  final Widget child;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const SimpleDialogCard({
    super.key,
    required this.child,
    this.width,
    this.padding,
    this.borderRadius = AppSpacing.radiusLg,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return Container(
      width: width,
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: themeColors.glassBorder,
          width: 1.5,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeColors.glassHighlight,
            themeColors.glassBackground,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: UIHelpers.withOpacity(themeColors.primaryDark, 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
