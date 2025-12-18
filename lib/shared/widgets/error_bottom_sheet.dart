import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/errors/app_errors.dart';
import '../utils/ui_helpers.dart';
import 'gradient_button.dart';

/// Error bottom sheet for displaying critical errors
class ErrorBottomSheet {
  ErrorBottomSheet._();

  /// Show error bottom sheet
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
    bool isDismissible = true,
    IconData icon = Icons.error_outline_rounded,
  }) async {
    HapticFeedback.mediumImpact();

    await showModalBottomSheet(
      context: context,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ErrorBottomSheetContent(
        title: title,
        message: message,
        onRetry: onRetry,
        onDismiss: onDismiss,
        icon: icon,
      ),
    );
  }

  /// Show error from AppError or any error
  static Future<void> showFromError(
    BuildContext context,
    dynamic error, {
    String title = 'حدث خطأ',
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
    bool isDismissible = true,
  }) async {
    final appError = error is AppError
        ? error
        : UnknownError(originalError: error);

    await show(
      context,
      title: title,
      message: appError.userFriendlyMessage,
      onRetry: appError.isRetryable ? onRetry : null,
      onDismiss: onDismiss,
      isDismissible: isDismissible,
      icon: _getIconForError(appError),
    );
  }

  static IconData _getIconForError(AppError error) {
    if (error is NetworkError || error is OfflineError) {
      return Icons.wifi_off_rounded;
    }
    if (error is TimeoutError) {
      return Icons.timer_off_rounded;
    }
    if (error is AuthError) {
      return Icons.lock_outline_rounded;
    }
    if (error is DatabaseError) {
      return Icons.storage_rounded;
    }
    return Icons.error_outline_rounded;
  }

  /// Show offline error
  static Future<void> showOffline(
    BuildContext context, {
    VoidCallback? onRetry,
  }) async {
    await show(
      context,
      title: 'لا يوجد اتصال',
      message: 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.',
      onRetry: onRetry,
      icon: Icons.wifi_off_rounded,
    );
  }

  /// Show session expired error
  static Future<void> showSessionExpired(
    BuildContext context, {
    VoidCallback? onLogin,
  }) async {
    await show(
      context,
      title: 'انتهت صلاحية الجلسة',
      message: 'انتهت صلاحية جلستك. يرجى تسجيل الدخول مرة أخرى.',
      onRetry: onLogin,
      icon: Icons.lock_outline_rounded,
      isDismissible: false,
    );
  }
}

class _ErrorBottomSheetContent extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final IconData icon;

  const _ErrorBottomSheetContent({
    required this.title,
    required this.message,
    this.onRetry,
    this.onDismiss,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadiusLarge),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      UIHelpers.withValues(alpha: Colors.white, 0.15),
                      UIHelpers.withValues(alpha: Colors.white, 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadiusLarge),
                  border: Border.all(
                    color: UIHelpers.withValues(alpha: Colors.white, 0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Error icon
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: AppSpacing.iconXl,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Title
                    Text(
                      title,
                      style: AppTypography.headlineSmall.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Message
                    Text(
                      message,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Actions
                    if (onRetry != null)
                      GradientButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onRetry!();
                        },
                        text: 'إعادة المحاولة',
                        icon: Icons.refresh_rounded,
                      ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onDismiss?.call();
                      },
                      child: Text(
                        onRetry != null ? 'إلغاء' : 'حسناً',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
