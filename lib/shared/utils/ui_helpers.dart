import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/theme_provider.dart';
import '../widgets/persistent_bottom_nav.dart';

/// Utility helpers for UI components
class UIHelpers {
  /// Convert withOpacity to withValues for better precision
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  /// Common border radius values
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;

  /// Common spacing values
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;

  /// Common animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  /// Create consistent glass effect
  static BoxDecoration glassDecoration({
    Color? color,
    double borderRadius = radiusMedium,
    double opacity = 0.1,
    Border? border,
  }) {
    return BoxDecoration(
      color:
          color?.withValues(alpha: opacity) ??
          Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border:
          border ??
          Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
    );
  }

  /// Create consistent shadow
  static List<BoxShadow> softShadow({
    Color color = Colors.black,
    double blurRadius = 10.0,
    double spreadRadius = 0.0,
    double opacity = 0.1,
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
        offset: const Offset(0, 2),
      ),
    ];
  }

  /// Create consistent input decoration
  static InputDecoration inputDecoration({
    required String labelText,
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
    );

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.1),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
    );
  }

  /// Try to pull theme colors from the provider container without requiring
  /// a WidgetRef. Returns null if context is not under a ProviderScope.
  static ThemeColors? _readThemeFromContext(BuildContext context) {
    try {
      return ProviderScope.containerOf(context, listen: false)
          .read(themeColorsProvider);
    } catch (_) {
      return null;
    }
  }

  /// Show a consistent app-themed glass snackbar.
  ///
  /// Theme is auto-pulled from the provider container — callers don't need
  /// to pass [colors] unless overriding. The snackbar floats above the
  /// persistent bottom nav and uses a backdrop blur with a tinted gradient
  /// instead of the flat Material fill.
  static void showSnackBar(
    BuildContext context,
    String message, {
    ThemeColors? colors,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    SnackBarAction? action,
    IconData? icon,
  }) {
    if (!context.mounted) return;

    final effectiveColors = colors ?? _readThemeFromContext(context);

    // Pick the accent: explicit override > error/success status > primary > fallback.
    final accent = backgroundColor ??
        (isError
            ? (effectiveColors?.statusError ?? const Color(0xFFE53935))
            : (effectiveColors?.statusSuccess ??
                effectiveColors?.primary ??
                const Color(0xFF2D7A3E)));

    final inferredIcon = icon ??
        (isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // The SnackBar shell is invisible — we render the entire pill
        // in `content` so we get full control over shape, blur, gradient,
        // border, and shadow.
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        duration: duration,
        // Float above the persistent bottom nav (~107 px tall) with a
        // small breathing gap. AppSpacing.sm = 8.
        margin: const EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: PersistentBottomNav.totalHeight + AppSpacing.sm,
        ),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withValues(alpha: 0.85),
                    accent.withValues(alpha: 0.65),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.lg,
              ),
              child: Row(
                children: [
                  Icon(inferredIcon, color: Colors.white, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      message,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    TextButton(
                      onPressed: action.onPressed,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        action.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Show an app-themed glass dialog. Wraps the given [child] in a
  /// glassmorphic container instead of Flutter's flat Material AlertDialog.
  ///
  /// Use this for confirmations, info, and small forms. Theme is auto-pulled.
  ///
  /// Returns whatever the [child] pops with via Navigator.pop(context, value).
  static Future<T?> showGlassDialog<T>(
    BuildContext context, {
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) {
        final colors = _readThemeFromContext(dialogContext);
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          (colors?.background1 ?? const Color(0xFF1E1E2E))
                              .withValues(alpha: 0.85),
                          (colors?.background2 ?? const Color(0xFF14141E))
                              .withValues(alpha: 0.85),
                        ],
                      ),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                      border: Border.all(
                        color: (colors?.primary ?? Colors.white)
                            .withValues(alpha: 0.25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Material(
                      type: MaterialType.transparency,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
