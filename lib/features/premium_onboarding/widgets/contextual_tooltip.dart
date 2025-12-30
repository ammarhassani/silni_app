import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../constants/onboarding_content.dart';
import '../models/contextual_tip.dart';
import '../providers/contextual_tips_provider.dart';

/// Overlay widget that shows contextual tips with spotlight effect
class ContextualTooltipOverlay extends ConsumerStatefulWidget {
  final ContextualTip tip;
  final GlobalKey targetKey;
  final VoidCallback onDismiss;

  const ContextualTooltipOverlay({
    super.key,
    required this.tip,
    required this.targetKey,
    required this.onDismiss,
  });

  @override
  ConsumerState<ContextualTooltipOverlay> createState() =>
      _ContextualTooltipOverlayState();
}

class _ContextualTooltipOverlayState
    extends ConsumerState<ContextualTooltipOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Offset? _targetPosition;
  Size? _targetSize;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: AppAnimations.loop,
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateTargetPosition();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _calculateTargetPosition() {
    final renderBox =
        widget.targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      setState(() {
        _targetPosition = renderBox.localToGlobal(Offset.zero);
        _targetSize = renderBox.size;
      });
    }
  }

  Offset _calculateTooltipPosition(Size screenSize) {
    if (_targetPosition == null || _targetSize == null) {
      return Offset(screenSize.width / 2 - 140, screenSize.height / 2);
    }

    const tooltipWidth = 280.0;
    const tooltipPadding = 16.0;
    const arrowSpace = 12.0;

    double left = _targetPosition!.dx + (_targetSize!.width / 2) - (tooltipWidth / 2);
    double top;

    // Clamp horizontal position
    left = left.clamp(tooltipPadding, screenSize.width - tooltipWidth - tooltipPadding);

    switch (widget.tip.position) {
      case TooltipPosition.above:
        top = _targetPosition!.dy - arrowSpace - 150; // Estimate tooltip height
        break;
      case TooltipPosition.below:
        top = _targetPosition!.dy + _targetSize!.height + arrowSpace;
        break;
      case TooltipPosition.left:
        left = _targetPosition!.dx - tooltipWidth - arrowSpace;
        top = _targetPosition!.dy + (_targetSize!.height / 2) - 75;
        break;
      case TooltipPosition.right:
        left = _targetPosition!.dx + _targetSize!.width + arrowSpace;
        top = _targetPosition!.dy + (_targetSize!.height / 2) - 75;
        break;
      case TooltipPosition.center:
        top = screenSize.height / 2 - 75;
        left = screenSize.width / 2 - tooltipWidth / 2;
        break;
    }

    // Clamp vertical position
    top = top.clamp(tooltipPadding + 50, screenSize.height - 200);

    return Offset(left, top);
  }

  void _handleDismiss() {
    HapticFeedback.lightImpact();
    widget.onDismiss();
  }

  void _handleAction() {
    HapticFeedback.mediumImpact();
    widget.onDismiss();
    if (widget.tip.actionRoute != null) {
      context.push(widget.tip.actionRoute!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final themeColors = ref.watch(themeColorsProvider);

    if (_targetPosition == null && widget.tip.showSpotlight) {
      return const SizedBox.shrink();
    }

    final tooltipPosition = _calculateTooltipPosition(screenSize);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Semi-transparent overlay with spotlight cutout
          if (widget.tip.showSpotlight && _targetPosition != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: _handleDismiss,
                child: CustomPaint(
                  painter: _SpotlightPainter(
                    targetRect: Rect.fromLTWH(
                      _targetPosition!.dx - 8,
                      _targetPosition!.dy - 8,
                      _targetSize!.width + 16,
                      _targetSize!.height + 16,
                    ),
                    overlayColor: Colors.black.withValues(alpha: 0.75),
                  ),
                ),
              ),
            )
          else
            // Just semi-transparent overlay without spotlight
            Positioned.fill(
              child: GestureDetector(
                onTap: _handleDismiss,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
            ),

          // Pulsing highlight around target
          if (widget.tip.showSpotlight && _targetPosition != null)
            Positioned(
              left: _targetPosition!.dx - 4,
              top: _targetPosition!.dy - 4,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: _targetSize!.width + 8,
                    height: _targetSize!.height + 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: AppColors.premiumGold.withValues(
                          alpha: 0.5 + (_pulseController.value * 0.5),
                        ),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.premiumGold.withValues(
                            alpha: 0.3 * _pulseController.value,
                          ),
                          blurRadius: 20 * _pulseController.value,
                          spreadRadius: 4 * _pulseController.value,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // Tooltip card
          Positioned(
            left: tooltipPosition.dx,
            top: tooltipPosition.dy,
            child: _TooltipCard(
              tip: widget.tip,
              onDismiss: _handleDismiss,
              onAction: widget.tip.actionLabel != null ? _handleAction : null,
              themeColors: themeColors,
            )
                .animate()
                .fadeIn(duration: AppAnimations.normal)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutBack,
                  duration: AppAnimations.normal,
                ),
          ),
        ],
      ),
    );
  }
}

/// The tooltip card content
class _TooltipCard extends StatelessWidget {
  final ContextualTip tip;
  final VoidCallback onDismiss;
  final VoidCallback? onAction;
  final dynamic themeColors;

  const _TooltipCard({
    required this.tip,
    required this.onDismiss,
    this.onAction,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    return DramaticGlassCard(
      width: 280,
      gradient: LinearGradient(
        colors: [
          AppColors.premiumGold.withValues(alpha: 0.25),
          AppColors.premiumGoldDark.withValues(alpha: 0.15),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon and close button
            Row(
              children: [
                // Lightbulb icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    gradient: AppColors.goldenGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lightbulb_rounded,
                    size: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Title
                Expanded(
                  child: Text(
                    tip.titleArabic,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.premiumGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Close button
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: Colors.white54,
                  onPressed: onDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // Body text
            Text(
              tip.bodyArabic,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white,
                height: 1.6,
              ),
            ),

            // Action button (if provided)
            if (tip.actionLabel != null) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  text: tip.actionLabel!,
                  onPressed: onAction ?? onDismiss,
                  height: 40,
                ),
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.sm),
              // Got it button
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: onDismiss,
                  child: Text(
                    OnboardingContent.gotItButton,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.premiumGold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the spotlight overlay effect
class _SpotlightPainter extends CustomPainter {
  final Rect targetRect;
  final Color overlayColor;

  _SpotlightPainter({
    required this.targetRect,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;

    // Create a path for the overlay with a cutout
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          targetRect,
          const Radius.circular(12),
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.overlayColor != overlayColor;
  }
}

/// Wrapper widget that can be used to mark a widget as a tooltip target
class TooltipTarget extends StatelessWidget {
  final GlobalKey tooltipKey;
  final Widget child;

  const TooltipTarget({
    super.key,
    required this.tooltipKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: tooltipKey,
      child: child,
    );
  }
}

/// Helper widget that automatically shows contextual tips for a screen
class ContextualTipsWrapper extends ConsumerWidget {
  final String screenRoute;
  final Widget child;
  final Map<String, GlobalKey> targetKeys;

  const ContextualTipsWrapper({
    super.key,
    required this.screenRoute,
    required this.child,
    required this.targetKeys,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipsNotifier = ref.watch(contextualTipsProvider.notifier);
    final tipsState = ref.watch(contextualTipsProvider);

    // Get next tip for this screen
    final nextTip = tipsNotifier.getNextTipForScreen(screenRoute);

    return Stack(
      children: [
        child,

        // Show tooltip if there's a tip and we have a target key for it
        if (nextTip != null &&
            targetKeys.containsKey(nextTip.targetKey) &&
            !tipsState.isLoading)
          ContextualTooltipOverlay(
            tip: nextTip,
            targetKey: targetKeys[nextTip.targetKey]!,
            onDismiss: () {
              ref.read(contextualTipsProvider.notifier).dismissTip(nextTip.id);
            },
          ),
      ],
    );
  }
}
