import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../utils/ui_helpers.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurStrength;
  final Color? color;
  final Border? border;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = AppSpacing.cardRadius,
    this.blurStrength = AppColors.blurStrength,
    this.color,
    this.border,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark
        ? UIHelpers.withOpacity(AppColors.glassWhite, 0.1)
        : UIHelpers.withOpacity(AppColors.glassWhite, 0.3);

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(AppSpacing.md),
          margin: margin,
          decoration: BoxDecoration(
            color: gradient == null ? (color ?? defaultColor) : null,
            borderRadius: BorderRadius.circular(borderRadius),
            border:
                border ??
                Border.all(
                  color: UIHelpers.withOpacity(Colors.white, 0.2),
                  width: 1.5,
                ),
            gradient:
                gradient ??
                LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    UIHelpers.withOpacity(Colors.white, 0.2),
                    UIHelpers.withOpacity(Colors.white, 0.05),
                  ],
                ),
            boxShadow: UIHelpers.softShadow(opacity: 0.1, blurRadius: 20),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      card = Semantics(
        button: true,
        child: GestureDetector(onTap: onTap, child: card),
      );
    }

    return card;
  }
}

/// Dramatic Glass Card with stronger effects
class DramaticGlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const DramaticGlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.dramaticRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient:
                gradient ??
                LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    UIHelpers.withOpacity(Colors.white, 0.25),
                    UIHelpers.withOpacity(Colors.white, 0.1),
                  ],
                ),
            borderRadius: BorderRadius.circular(AppSpacing.dramaticRadius),
            border: Border.all(
              color: UIHelpers.withOpacity(Colors.white, 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: UIHelpers.withOpacity(Colors.black, 0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: UIHelpers.withOpacity(
                  AppColors.islamicGreenPrimary,
                  0.1,
                ),
                blurRadius: 60,
                offset: const Offset(0, 30),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      card = Semantics(
        button: true,
        child: GestureDetector(onTap: onTap, child: card),
      );
    }

    return card;
  }
}
