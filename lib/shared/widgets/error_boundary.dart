import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/app_logger_service.dart';
import 'gradient_button.dart';

// Fallback error color for widgets that don't have theme context
const _kErrorColor = Color(0xFFE53935);

/// Error boundary widget that catches errors in child widgets
/// and displays a user-friendly error UI instead of crashing
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? errorBuilder;
  final void Function(FlutterErrorDetails)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _error;

  @override
  void initState() {
    super.initState();
  }

  void _resetError() {
    setState(() {
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!);
      }
      return ErrorBoundaryFallback(
        error: _error!,
        onRetry: _resetError,
      );
    }

    return widget.child;
  }
}

/// Default fallback widget shown when an error occurs
class ErrorBoundaryFallback extends StatelessWidget {
  final FlutterErrorDetails error;
  final VoidCallback? onRetry;

  const ErrorBoundaryFallback({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1A2E),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error icon
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: _kErrorColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Title
                Text(
                  'حدث خطأ غير متوقع',
                  style: AppTypography.headlineMedium.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),

                // Message
                Text(
                  'نعتذر عن هذا الخطأ. يرجى المحاولة مرة أخرى.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Debug info in debug mode
                if (kDebugMode) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      error.exceptionAsString(),
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white54,
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),

                // Retry button
                if (onRetry != null)
                  GradientButton(
                    onPressed: onRetry!,
                    text: 'إعادة المحاولة',
                    icon: Icons.refresh_rounded,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Configure global error widget builder for graceful error display
void setupErrorWidgetBuilder() {
  final logger = AppLoggerService();

  ErrorWidget.builder = (FlutterErrorDetails details) {
    // Log the error
    logger.error(
      'Widget build error: ${details.exceptionAsString()}',
      category: LogCategory.ui,
      tag: 'ErrorWidget',
      metadata: {
        'library': details.library ?? 'unknown',
        'context': details.context?.toString() ?? 'no context',
      },
      stackTrace: details.stack,
    );

    // Report to Sentry
    Sentry.captureException(
      details.exception,
      stackTrace: details.stack,
    );

    // In debug mode, show more details
    if (kDebugMode) {
      return _DebugErrorWidget(details: details);
    }

    // In release mode, show user-friendly error
    return _ReleaseErrorWidget(details: details);
  };
}

/// Debug error widget with full details
class _DebugErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;

  const _DebugErrorWidget({required this.details});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: const Color(0xFF1A1A2E),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _kErrorColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.bug_report_rounded,
                        color: _kErrorColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Debug Error View',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Error type
                _buildSection(
                  'Exception',
                  details.exception.runtimeType.toString(),
                  _kErrorColor,
                ),

                // Error message
                _buildSection(
                  'Message',
                  details.exceptionAsString(),
                  Colors.orange,
                ),

                // Library
                if (details.library != null)
                  _buildSection(
                    'Library',
                    details.library!,
                    Colors.blue,
                  ),

                // Context
                if (details.context != null)
                  _buildSection(
                    'Context',
                    details.context.toString(),
                    Colors.purple,
                  ),

                // Stack trace (truncated)
                if (details.stack != null)
                  _buildSection(
                    'Stack Trace',
                    details.stack.toString().split('\n').take(10).join('\n'),
                    Colors.grey,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

/// Release error widget - minimal, user-friendly
class _ReleaseErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;

  const _ReleaseErrorWidget({required this.details});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: const Color(0xFF1A1A2E),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sentiment_dissatisfied_rounded,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'حدث خطأ',
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'يرجى إعادة تشغيل التطبيق',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
