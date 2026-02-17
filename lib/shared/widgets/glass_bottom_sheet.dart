import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/theme_provider.dart';

/// Reusable glassmorphic bottom sheet shell.
///
/// Provides the shared chrome: backdrop blur, gradient background, drag handle,
/// optional icon + title header. Used by all reminders bottom sheets.
class GlassBottomSheet extends ConsumerWidget {
  final Widget child;
  final String? title;
  final IconData? icon;
  final Color? iconAccentColor;
  final bool useSafeArea;

  const GlassBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.iconAccentColor,
    this.useSafeArea = true,
  });

  /// Show this bottom sheet with standard glassmorphic configuration.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    double maxHeightFraction = 0.85,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * maxHeightFraction,
      ),
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final bottomPadding =
        useSafeArea ? MediaQuery.of(context).viewPadding.bottom : 0.0;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                themeColors.background1.withValues(alpha: 0.95),
                themeColors.background2.withValues(alpha: 0.98),
              ],
            ),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Optional header with icon + title
              if (title != null || icon != null)
                _buildHeader(themeColors),

              // Content — Flexible so scrollable children can shrink
              Flexible(child: child),

              // Safe area bottom padding
              SizedBox(height: bottomPadding + AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors themeColors) {
    final accentColor = iconAccentColor ?? themeColors.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.15),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(icon, color: Colors.white, size: 28),
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                  duration: 400.ms,
                  curve: Curves.easeOut,
                ),

          if (icon != null && title != null)
            const SizedBox(height: AppSpacing.md),

          if (title != null)
            Text(
              title!,
              style: AppTypography.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 100.ms, duration: 300.ms)
                .slideY(begin: 0.05, end: 0, delay: 100.ms, duration: 300.ms),
        ],
      ),
    );
  }
}
