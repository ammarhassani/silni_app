import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../errors/app_errors.dart';
import '../../shared/utils/ui_helpers.dart';

/// Helper class for showing consistent snackbars throughout the app
class SnackBarHelper {
  SnackBarHelper._();

  /// Show an error snackbar with optional retry action
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onRetry,
    String retryLabel = 'إعادة',
  }) {
    HapticFeedback.mediumImpact();

    UIHelpers.showSnackBar(
      context,
      message,
      isError: true,
      duration: duration,
      icon: Icons.error_outline_rounded,
      action: onRetry != null
          ? SnackBarAction(
              label: retryLabel,
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
    );
  }

  /// Show error snackbar from an AppError or any error
  static void showErrorFromException(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
  }) {
    final appError =
        error is AppError ? error : UnknownError(originalError: error);

    showError(
      context,
      appError.userFriendlyMessage,
      onRetry: appError.isRetryable ? onRetry : null,
    );
  }

  /// Show a success snackbar
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    HapticFeedback.lightImpact();

    UIHelpers.showSnackBar(
      context,
      message,
      duration: duration,
      icon: Icons.check_circle_outline_rounded,
      backgroundColor: AppColors.success,
      action: onAction != null && actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction,
            )
          : null,
    );
  }

  /// Show a warning snackbar
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    UIHelpers.showSnackBar(
      context,
      message,
      duration: duration,
      icon: Icons.warning_amber_rounded,
      backgroundColor: AppColors.warning,
      action: onAction != null && actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction,
            )
          : null,
    );
  }

  /// Show an info snackbar
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismiss,
  }) {
    UIHelpers.showSnackBar(
      context,
      message,
      duration: duration,
      icon: Icons.info_outline_rounded,
      backgroundColor: AppColors.info,
      action: onDismiss != null
          ? SnackBarAction(
              label: 'حسناً',
              textColor: Colors.white,
              onPressed: onDismiss,
            )
          : null,
    );
  }

  /// Show offline snackbar
  static void showOffline(BuildContext context, {VoidCallback? onRetry}) {
    showError(
      context,
      'لا يوجد اتصال بالإنترنت',
      duration: const Duration(seconds: 5),
      onRetry: onRetry,
      retryLabel: 'إعادة المحاولة',
    );
  }

  /// Show loading snackbar (indefinite duration)
  static void showLoading(
    BuildContext context,
    String message,
  ) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.islamicGreenPrimary,
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
