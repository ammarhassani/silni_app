import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/app_errors.dart';
import '../../shared/widgets/error_widgets.dart';

/// Extensions for AsyncValue to provide consistent error handling
extension AsyncValueErrorHandling<T> on AsyncValue<T> {
  /// Build widget with proper error handling
  ///
  /// Instead of using `when()` with `error: (_, __) => SizedBox.shrink()`,
  /// use this method for consistent error UI.
  Widget buildWithError({
    required Widget Function(T data) data,
    Widget Function()? loading,
    Widget Function(Object error, StackTrace? stack)? error,
    VoidCallback? onRetry,
    String defaultErrorMessage = 'حدث خطأ في تحميل البيانات',
    bool showErrorInline = true,
  }) {
    return when(
      data: data,
      loading: loading ?? () => const Center(child: CircularProgressIndicator()),
      error: error ??
          (e, s) {
            final message = e is AppError
                ? e.userFriendlyMessage
                : defaultErrorMessage;

            if (showErrorInline) {
              return InlineErrorWidget(
                message: message,
                onRetry: onRetry,
              );
            }

            return FullScreenErrorWidget(
              message: message,
              onRetry: onRetry,
            );
          },
    );
  }

  /// Build with custom loading widget (e.g., skeleton loader)
  Widget buildWithSkeleton({
    required Widget Function(T data) data,
    required Widget skeleton,
    Widget Function(Object error, StackTrace? stack)? error,
    VoidCallback? onRetry,
    String defaultErrorMessage = 'حدث خطأ في تحميل البيانات',
  }) {
    return when(
      data: data,
      loading: () => skeleton,
      error: error ??
          (e, s) {
            final message = e is AppError
                ? e.userFriendlyMessage
                : defaultErrorMessage;
            return LoadingErrorWidget(
              message: message,
              onRetry: onRetry,
              skeleton: skeleton,
            );
          },
    );
  }

  /// Build with data only - hide on loading/error
  Widget buildDataOnly({
    required Widget Function(T data) data,
    Widget Function()? loading,
    bool hideOnError = true,
  }) {
    return when(
      data: data,
      loading: loading ?? () => const SizedBox.shrink(),
      error: (e, s) => hideOnError ? const SizedBox.shrink() : data(value as T),
    );
  }

  /// Get data or return default value
  T dataOrDefault(T defaultValue) {
    return maybeWhen(
      data: (d) => d,
      orElse: () => defaultValue,
    );
  }

  /// Get data as list or empty list (for collection types)
  List<E> toListOrEmpty<E>() {
    return maybeWhen(
      data: (d) => d as List<E>,
      orElse: () => <E>[],
    );
  }

  // Note: hasData, isLoading, hasError are provided by Riverpod's AsyncValueX

  /// Get error message if in error state
  String? get errorMessage {
    return maybeWhen(
      error: (e, _) {
        if (e is AppError) return e.userFriendlyMessage;
        return e.toString();
      },
      orElse: () => null,
    );
  }

  /// Get error as AppError if in error state
  AppError? get appError {
    return maybeWhen(
      error: (e, st) {
        if (e is AppError) return e;
        return UnknownError(
          message: e.toString(),
          originalError: e,
          stackTrace: st,
        );
      },
      orElse: () => null,
    );
  }

  /// Check if error is retryable
  bool get isRetryable {
    return maybeWhen(
      error: (e, _) => e is AppError ? e.isRetryable : false,
      orElse: () => false,
    );
  }

  /// Map data or return null
  R? mapDataOrNull<R>(R Function(T data) mapper) {
    return maybeWhen(
      data: mapper,
      orElse: () => null,
    );
  }

  /// When with fallback data (useful for showing stale data)
  Widget whenWithFallback({
    required Widget Function(T data, bool isLoading, bool hasError) builder,
    required T fallback,
    Widget Function()? loadingWithNoData,
    Widget Function(Object error, StackTrace? stack)? errorWithNoData,
  }) {
    final currentData = maybeWhen(data: (d) => d, orElse: () => null);

    if (currentData != null) {
      return builder(currentData, isLoading, hasError);
    }

    return when(
      data: (d) => builder(d, false, false),
      loading: loadingWithNoData ?? () => builder(fallback, true, false),
      error: errorWithNoData ?? (e, s) => builder(fallback, false, true),
    );
  }
}

/// Extensions for watching multiple AsyncValues
extension AsyncValueListExtensions on List<AsyncValue<dynamic>> {
  /// Check if any is loading
  bool get anyLoading => any((v) => v.isLoading);

  /// Check if any has error
  bool get anyHasError => any((v) => v.hasError);

  /// Check if all have value
  bool get allHaveValue => every((v) => v.hasValue);

  /// Get first error if any
  Object? get firstError {
    for (final value in this) {
      final error = value.maybeWhen(error: (e, _) => e, orElse: () => null);
      if (error != null) return error;
    }
    return null;
  }
}
