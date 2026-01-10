import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/errors/app_errors.dart';
import '../utils/ui_helpers.dart';
import 'gradient_button.dart';

// Fallback error colors for widgets that don't have theme context
const _kErrorColor = Color(0xFFE53935);
const _kWarningColor = Color(0xFFFFA726);

/// Inline error widget for displaying errors within lists or cards
class InlineErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  const InlineErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.compact = false,
  });

  factory InlineErrorWidget.fromError(
    dynamic error, {
    VoidCallback? onRetry,
    bool compact = false,
  }) {
    final appError = error is AppError
        ? error
        : UnknownError(originalError: error);
    return InlineErrorWidget(
      message: appError.userFriendlyMessage,
      onRetry: appError.isRetryable ? onRetry : null,
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact(context);
    }
    return _buildStandard(context);
  }

  Widget _buildCompact(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _kErrorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: _kErrorColor,
            size: AppSpacing.iconSm,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: _kErrorColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: AppSpacing.xs),
            GestureDetector(
              onTap: onRetry,
              child: Icon(
                Icons.refresh_rounded,
                color: _kErrorColor,
                size: AppSpacing.iconSm,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStandard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _kErrorColor.withValues(alpha: 0.2),
                _kErrorColor.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: _kErrorColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _kErrorColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: AppSpacing.iconMd,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              if (onRetry != null)
                IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                  ),
                  onPressed: onRetry,
                  tooltip: 'إعادة المحاولة',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full screen error widget for critical errors
class FullScreenErrorWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;
  final IconData icon;

  const FullScreenErrorWidget({
    super.key,
    this.title = 'حدث خطأ',
    required this.message,
    this.onRetry,
    this.onBack,
    this.icon = Icons.error_outline_rounded,
  });

  factory FullScreenErrorWidget.fromError(
    dynamic error, {
    String title = 'حدث خطأ',
    VoidCallback? onRetry,
    VoidCallback? onBack,
  }) {
    final appError = error is AppError
        ? error
        : UnknownError(originalError: error);
    return FullScreenErrorWidget(
      title: title,
      message: appError.userFriendlyMessage,
      onRetry: appError.isRetryable ? onRetry : null,
      onBack: onBack,
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

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadiusLarge),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    UIHelpers.withOpacity(Colors.white, 0.2),
                    UIHelpers.withOpacity(Colors.white, 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadiusLarge),
                border: Border.all(
                  color: UIHelpers.withOpacity(Colors.white, 0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Error icon with glow
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: _kErrorColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _kErrorColor.withValues(alpha: 0.3),
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
                    style: AppTypography.headlineMedium.copyWith(
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
                      onPressed: onRetry!,
                      text: 'إعادة المحاولة',
                      icon: Icons.refresh_rounded,
                    ),
                  if (onRetry != null && onBack != null)
                    const SizedBox(height: AppSpacing.md),
                  if (onBack != null)
                    TextButton(
                      onPressed: onBack,
                      child: Text(
                        'العودة',
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
    );
  }
}

/// Offline banner widget to display at the top of the screen
class OfflineBanner extends StatelessWidget {
  final VoidCallback? onTap;

  const OfflineBanner({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _kWarningColor.withValues(alpha: 0.9),
              _kWarningColor,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: _kWarningColor.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: Colors.white,
                size: AppSpacing.iconSm,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'لا يوجد اتصال بالإنترنت',
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: AppSpacing.iconSm,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated offline banner that slides in/out
class AnimatedOfflineBanner extends StatefulWidget {
  final bool isOffline;
  final VoidCallback? onTap;

  const AnimatedOfflineBanner({
    super.key,
    required this.isOffline,
    this.onTap,
  });

  @override
  State<AnimatedOfflineBanner> createState() => _AnimatedOfflineBannerState();
}

class _AnimatedOfflineBannerState extends State<AnimatedOfflineBanner>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    // Use AnimatedSize to collapse the space when hidden
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: widget.isOffline
          ? OfflineBanner(onTap: widget.onTap)
          : const SizedBox.shrink(),
    );
  }
}

/// Empty state widget with retry option
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_rounded,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppSpacing.iconXl,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedGradientButton(
                onPressed: onAction!,
                text: actionLabel!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading error state that shows a skeleton with error overlay
class LoadingErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final Widget? skeleton;

  const LoadingErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.skeleton,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (skeleton != null)
          Opacity(
            opacity: 0.3,
            child: skeleton,
          ),
        Positioned.fill(
          child: Center(
            child: InlineErrorWidget(
              message: message,
              onRetry: onRetry,
            ),
          ),
        ),
      ],
    );
  }
}
