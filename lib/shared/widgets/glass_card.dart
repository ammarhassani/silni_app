import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/theme_provider.dart';
import '../utils/ui_helpers.dart';

class GlassCard extends ConsumerStatefulWidget {
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
  final String? semanticsLabel;
  final bool enablePressAnimation;

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
    this.semanticsLabel,
    this.enablePressAnimation = true,
  });

  @override
  ConsumerState<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends ConsumerState<GlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: AppAnimations.instant,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: AppAnimations.normalScale,
      end: AppAnimations.pressedScale,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: AppAnimations.toggleCurve,
    ));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null && widget.enablePressAnimation) {
      setState(() => _isPressed = true);
      _pressController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null && widget.enablePressAnimation) {
      setState(() => _isPressed = false);
      _pressController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null && widget.enablePressAnimation) {
      setState(() => _isPressed = false);
      _pressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);

    Widget card = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.enablePressAnimation ? _scaleAnimation.value : 1.0,
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.blurStrength,
            sigmaY: widget.blurStrength,
          ),
          child: AnimatedContainer(
            duration: AppAnimations.fast,
            curve: AppAnimations.toggleCurve,
            width: widget.width,
            height: widget.height,
            padding: widget.padding ?? const EdgeInsets.all(AppSpacing.md),
            margin: widget.margin,
            decoration: BoxDecoration(
              color: widget.gradient == null
                  ? (widget.color ?? themeColors.glassBackground)
                  : null,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: widget.border ??
                  Border.all(
                    color: _isPressed
                        ? themeColors.glassHighlight
                        : themeColors.glassBorder,
                    width: 1.5,
                  ),
              gradient: widget.gradient ??
                  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      themeColors.glassHighlight,
                      themeColors.glassBackground,
                    ],
                  ),
              boxShadow: [
                BoxShadow(
                  color: UIHelpers.withOpacity(
                    themeColors.primaryDark,
                    _isPressed ? 0.15 : 0.1,
                  ),
                  blurRadius: _isPressed ? 15 : 20,
                  offset: Offset(0, _isPressed ? 4 : 8),
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.onTap != null) {
      card = Semantics(
        label: widget.semanticsLabel,
        button: true,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            widget.onTap?.call();
          },
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: card,
        ),
      );
    } else if (widget.semanticsLabel != null) {
      card = Semantics(
        label: widget.semanticsLabel,
        child: card,
      );
    }

    return card;
  }
}

/// Dramatic Glass Card with stronger effects
class DramaticGlassCard extends ConsumerStatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final String? semanticsLabel;
  final bool enablePressAnimation;

  const DramaticGlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.gradient,
    this.onTap,
    this.semanticsLabel,
    this.enablePressAnimation = true,
  });

  @override
  ConsumerState<DramaticGlassCard> createState() => _DramaticGlassCardState();
}

class _DramaticGlassCardState extends ConsumerState<DramaticGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: AppAnimations.instant,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: AppAnimations.normalScale,
      end: AppAnimations.pressedScale,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: AppAnimations.toggleCurve,
    ));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null && widget.enablePressAnimation) {
      setState(() => _isPressed = true);
      _pressController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null && widget.enablePressAnimation) {
      setState(() => _isPressed = false);
      _pressController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null && widget.enablePressAnimation) {
      setState(() => _isPressed = false);
      _pressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);

    Widget card = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.enablePressAnimation ? _scaleAnimation.value : 1.0,
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.dramaticRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: AnimatedContainer(
            duration: AppAnimations.fast,
            curve: AppAnimations.toggleCurve,
            width: widget.width,
            height: widget.height,
            padding: widget.padding ?? const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: widget.gradient ??
                  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      UIHelpers.withOpacity(themeColors.glassHighlight, 1.5),
                      themeColors.glassBackground,
                    ],
                  ),
              borderRadius: BorderRadius.circular(AppSpacing.dramaticRadius),
              border: Border.all(
                color: _isPressed
                    ? themeColors.glassHighlight
                    : themeColors.glassBorder,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: UIHelpers.withOpacity(
                    themeColors.primaryDark,
                    _isPressed ? 0.25 : 0.2,
                  ),
                  blurRadius: _isPressed ? 30 : 40,
                  offset: Offset(0, _isPressed ? 15 : 20),
                ),
                BoxShadow(
                  color: UIHelpers.withOpacity(
                    themeColors.primary,
                    _isPressed ? 0.15 : 0.1,
                  ),
                  blurRadius: _isPressed ? 50 : 60,
                  offset: Offset(0, _isPressed ? 25 : 30),
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.onTap != null) {
      card = Semantics(
        label: widget.semanticsLabel,
        button: true,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            widget.onTap?.call();
          },
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: card,
        ),
      );
    } else if (widget.semanticsLabel != null) {
      card = Semantics(
        label: widget.semanticsLabel,
        child: card,
      );
    }

    return card;
  }
}
