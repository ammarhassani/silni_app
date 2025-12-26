import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_animations.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/theme_provider.dart';

/// A premium loading indicator with glassmorphism and gradient animation
/// Use this instead of plain CircularProgressIndicator for a polished look
class PremiumLoadingIndicator extends ConsumerWidget {
  final double size;
  final Color? color;
  final String? message;

  const PremiumLoadingIndicator({
    super.key,
    this.size = 48,
    this.color,
    this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return Semantics(
      label: message ?? 'جاري التحميل',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GradientSpinner(size: size, color: color),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              style: TextStyle(
                color: themeColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GradientSpinner extends ConsumerWidget {
  final double size;
  final Color? color;

  const _GradientSpinner({required this.size, this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final spinnerColor = color ?? themeColors.primary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow
          Container(
            width: size + 20,
            height: size + 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: spinnerColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
          // Glass background
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
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
                ),
              ),
            ),
          ),
          // Rotating gradient arc
          SizedBox(
            width: size - 8,
            height: size - 8,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: AppAnimations.celebration),
        ],
      ),
    );
  }
}

/// A full-screen premium loading overlay
class PremiumLoadingOverlay extends ConsumerWidget {
  final String? message;
  final bool isVisible;
  final Widget child;

  const PremiumLoadingOverlay({
    super.key,
    this.message,
    required this.isVisible,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return Stack(
      children: [
        child,
        if (isVisible)
          Positioned.fill(
            child: Container(
              color: themeColors.primaryDark.withValues(alpha: 0.6),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Center(
                  child: PremiumLoadingIndicator(message: message),
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: AppAnimations.fast),
      ],
    );
  }
}

/// A compact inline loading indicator
class InlineLoadingIndicator extends ConsumerWidget {
  final double size;
  final Color? color;

  const InlineLoadingIndicator({
    super.key,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return Semantics(
      label: 'جاري التحميل',
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? themeColors.onPrimary.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}

/// Skeleton screen placeholder for full-page loading states
class ScreenLoadingSkeleton extends StatelessWidget {
  final int itemCount;
  final Widget Function(int index)? itemBuilder;

  const ScreenLoadingSkeleton({
    super.key,
    this.itemCount = 5,
    this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'جاري تحميل المحتوى',
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (itemBuilder != null) {
            return itemBuilder!(index);
          }
          return _DefaultSkeletonItem(index: index);
        },
      ),
    );
  }
}

class _DefaultSkeletonItem extends ConsumerWidget {
  final int index;

  const _DefaultSkeletonItem({required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: themeColors.shimmerBase,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: themeColors.shimmerHighlight,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: themeColors.shimmerHighlight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: themeColors.shimmerBase,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 100 * index))
        .shimmer(
          duration: AppAnimations.loop,
          delay: AppAnimations.slow,
          color: themeColors.shimmerHighlight,
        )
        .fadeIn(duration: AppAnimations.normal);
  }
}
