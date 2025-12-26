import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_animations.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/theme_provider.dart';

class GradientButton extends ConsumerStatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Gradient? gradient;
  final double? width;
  final double? height;
  final bool isLoading;
  final IconData? icon;
  final bool dramatic;
  final bool enabled;
  final String? semanticsHint;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.gradient,
    this.width,
    this.height,
    this.isLoading = false,
    this.icon,
    this.dramatic = false,
    this.enabled = true,
    this.semanticsHint,
  });

  @override
  ConsumerState<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends ConsumerState<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.instant,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isEnabled => widget.enabled && !widget.isLoading;

  void _onTapDown(TapDownDetails details) {
    if (!_isEnabled) return;
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (!_isEnabled) return;
    HapticFeedback.mediumImpact();
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);
    final gradient = widget.gradient ?? themeColors.primaryGradient;
    final height = widget.height ?? AppSpacing.buttonHeight;
    final textColor = themeColors.onPrimary;

    return Semantics(
      label: widget.text,
      button: true,
      enabled: _isEnabled,
      hint: widget.isLoading
          ? 'جاري التحميل'
          : (widget.semanticsHint ?? (widget.enabled ? null : 'غير مفعل')),
      child: GestureDetector(
        onTapDown: _isEnabled ? _onTapDown : null,
        onTapUp: _isEnabled ? _onTapUp : null,
        onTapCancel: _isEnabled ? _onTapCancel : null,
        child: AnimatedOpacity(
          duration: AppAnimations.fast,
          opacity: _isEnabled ? 1.0 : AppAnimations.disabledOpacity,
          child: AnimatedContainer(
            duration: AppAnimations.instant,
            curve: AppAnimations.toggleCurve,
            width: widget.width ?? double.infinity,
            height: height,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(
                widget.dramatic
                    ? AppSpacing.dramaticRadius
                    : AppSpacing.buttonRadius,
              ),
              boxShadow: [
                BoxShadow(
                  color: themeColors.primary.withValues(
                    alpha: _isPressed ? 0.3 : 0.5,
                  ),
                  blurRadius: _isPressed ? 10 : 20,
                  offset: Offset(0, _isPressed ? 5 : 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(
                  widget.dramatic
                      ? AppSpacing.dramaticRadius
                      : AppSpacing.buttonRadius,
                ),
                splashColor: themeColors.onPrimary.withValues(alpha: 0.2),
                highlightColor: themeColors.onPrimary.withValues(alpha: 0.1),
                onTap: _isEnabled ? widget.onPressed : null,
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(textColor),
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                color: textColor,
                                size: AppSpacing.iconMd,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                            ],
                            Flexible(
                              child: Text(
                                widget.text,
                                style: widget.dramatic
                                    ? AppTypography.dramatic.copyWith(
                                        color: textColor,
                                        fontSize: 18,
                                      )
                                    : AppTypography.buttonLarge.copyWith(
                                        color: textColor,
                                      ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ).animate(
        onPlay: (controller) => controller.repeat(reverse: true),
      ).shimmer(
        duration: AppAnimations.loop,
        color: themeColors.onPrimary.withValues(alpha: 0.3),
      ),
    );
  }
}

/// Outlined Gradient Button with glass effect, glow, and animation
class OutlinedGradientButton extends ConsumerWidget {
  final String text;
  final VoidCallback onPressed;
  final Gradient? gradient;
  final double? width;
  final double? height;
  final IconData? icon;
  final bool enabled;

  const OutlinedGradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.gradient,
    this.width,
    this.height,
    this.icon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final buttonGradient = gradient ?? themeColors.primaryGradient;
    final textColor = themeColors.onPrimary;

    return Semantics(
      label: text,
      button: true,
      enabled: enabled,
      child: AnimatedOpacity(
        duration: AppAnimations.fast,
        opacity: enabled ? 1.0 : AppAnimations.disabledOpacity,
        child: Container(
          width: width ?? double.infinity,
          height: height ?? AppSpacing.buttonHeight,
          decoration: BoxDecoration(
            gradient: buttonGradient,
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            boxShadow: [
              BoxShadow(
                color: themeColors.primary.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: themeColors.primaryLight.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: themeColors.glassBackground,
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius - 2),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  themeColors.glassHighlight,
                  themeColors.glassBackground,
                ],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius - 2),
                splashColor: themeColors.onPrimary.withValues(alpha: 0.2),
                highlightColor: themeColors.onPrimary.withValues(alpha: 0.1),
                onTap: enabled
                    ? () {
                        HapticFeedback.mediumImpact();
                        onPressed();
                      }
                    : null,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          color: textColor,
                          size: AppSpacing.iconMd,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Flexible(
                        child: Text(
                          text,
                          style: AppTypography.buttonLarge.copyWith(
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ).animate(
        onPlay: (controller) => controller.repeat(reverse: true),
      ).shimmer(
        duration: AppAnimations.loop,
        color: themeColors.onPrimary.withValues(alpha: 0.3),
      ),
    );
  }
}
