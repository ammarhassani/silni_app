import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../errors/app_errors.dart';
import '../theme/app_themes.dart';
import '../../shared/utils/ui_helpers.dart';

/// Helper class for showing consistent snackbars throughout the app
///
/// All methods accept an optional [ThemeColors] parameter for theme-aware styling.
/// If not provided, falls back to Material defaults.
class SnackBarHelper {
  SnackBarHelper._();

  // Fallback colors when theme is not provided
  static const _fallbackSuccess = Color(0xFF4CAF50);
  static const _fallbackWarning = Color(0xFFFFA726);
  static const _fallbackInfo = Color(0xFF29B6F6);
  static const _fallbackPrimary = Color(0xFF4CAF50);

  /// Show an error snackbar with optional retry action
  static void showError(
    BuildContext context,
    String message, {
    ThemeColors? colors,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onRetry,
    String retryLabel = 'إعادة',
  }) {
    HapticFeedback.mediumImpact();

    UIHelpers.showSnackBar(
      context,
      message,
      colors: colors,
      isError: true,
      duration: duration,
      icon: Icons.error_outline_rounded,
      action: onRetry != null
          ? SnackBarAction(
              label: retryLabel,
              textColor: colors?.onPrimary ?? Colors.white,
              onPressed: onRetry,
            )
          : null,
    );
  }

  /// Show error snackbar from an AppError or any error
  static void showErrorFromException(
    BuildContext context,
    dynamic error, {
    ThemeColors? colors,
    VoidCallback? onRetry,
  }) {
    final appError =
        error is AppError ? error : UnknownError(originalError: error);

    showError(
      context,
      appError.userFriendlyMessage,
      colors: colors,
      onRetry: appError.isRetryable ? onRetry : null,
    );
  }

  /// Show a success snackbar
  static void showSuccess(
    BuildContext context,
    String message, {
    ThemeColors? colors,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    HapticFeedback.lightImpact();

    UIHelpers.showSnackBar(
      context,
      message,
      colors: colors,
      duration: duration,
      icon: Icons.check_circle_outline_rounded,
      backgroundColor: colors?.statusSuccess ?? _fallbackSuccess,
      action: onAction != null && actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: colors?.onPrimary ?? Colors.white,
              onPressed: onAction,
            )
          : null,
    );
  }

  /// Show a warning snackbar
  static void showWarning(
    BuildContext context,
    String message, {
    ThemeColors? colors,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    UIHelpers.showSnackBar(
      context,
      message,
      colors: colors,
      duration: duration,
      icon: Icons.warning_amber_rounded,
      backgroundColor: colors?.statusWarning ?? _fallbackWarning,
      action: onAction != null && actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: colors?.onPrimary ?? Colors.white,
              onPressed: onAction,
            )
          : null,
    );
  }

  /// Show an info snackbar
  static void showInfo(
    BuildContext context,
    String message, {
    ThemeColors? colors,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismiss,
  }) {
    UIHelpers.showSnackBar(
      context,
      message,
      colors: colors,
      duration: duration,
      icon: Icons.info_outline_rounded,
      backgroundColor: colors?.statusInfo ?? _fallbackInfo,
      action: onDismiss != null
          ? SnackBarAction(
              label: 'حسناً',
              textColor: colors?.onPrimary ?? Colors.white,
              onPressed: onDismiss,
            )
          : null,
    );
  }

  /// Show offline snackbar
  static void showOffline(
    BuildContext context, {
    ThemeColors? colors,
    VoidCallback? onRetry,
  }) {
    showError(
      context,
      'لا يوجد اتصال بالإنترنت',
      colors: colors,
      duration: const Duration(seconds: 5),
      onRetry: onRetry,
      retryLabel: 'إعادة المحاولة',
    );
  }

  /// Show loading snackbar (indefinite duration)
  static void showLoading(
    BuildContext context,
    String message, {
    ThemeColors? colors,
  }) {
    if (!context.mounted) return;

    final bgColor = colors?.primary ?? _fallbackPrimary;
    final textColor = colors?.onPrimary ?? Colors.white;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: textColor),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        duration: const Duration(days: 1), // Effectively indefinite
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Hide current snackbar
  static void hide(BuildContext context) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }
}
