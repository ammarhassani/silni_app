import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/connectivity_provider.dart';
import '../../core/utils/snackbar_helper.dart';

/// Widget that wraps mutation actions and blocks them when offline
///
/// Use this to wrap buttons or other interactive elements that perform
/// write operations (create, update, delete) to prevent failed requests
/// when the device is offline.
class OfflineGuard extends ConsumerWidget {
  final Widget child;
  final VoidCallback onPressed;
  final String offlineMessage;
  final bool showSnackbar;

  const OfflineGuard({
    super.key,
    required this.child,
    required this.onPressed,
    this.offlineMessage = 'لا يوجد اتصال بالإنترنت',
    this.showSnackbar = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (isOnline) {
          onPressed();
        } else if (showSnackbar) {
          SnackBarHelper.showOffline(context);
        }
      },
      child: IgnorePointer(
        ignoring: true, // Prevents child's onTap from firing
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isOnline ? 1.0 : 0.5,
          child: child,
        ),
      ),
    );
  }
}

/// Button wrapper that disables when offline
class OfflineAwareButton extends ConsumerWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String offlineMessage;

  const OfflineAwareButton({
    super.key,
    required this.child,
    this.onPressed,
    this.offlineMessage = 'لا يوجد اتصال بالإنترنت',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isOnline && onPressed != null ? 1.0 : 0.5,
      child: AbsorbPointer(
        absorbing: !isOnline || onPressed == null,
        child: GestureDetector(
          onTap: () {
            if (!isOnline) {
              SnackBarHelper.showOffline(context);
              return;
            }
            onPressed?.call();
          },
          child: child,
        ),
      ),
    );
  }
}

/// Mixin for StatefulWidgets that need offline awareness
mixin OfflineAwareMixin<T extends StatefulWidget> on State<T> {
  bool _lastKnownOnlineState = true;

  /// Override this to handle connectivity changes
  void onConnectivityChanged(bool isOnline) {}

  /// Call this in build method with ref.watch(isOnlineProvider)
  void handleConnectivityState(bool isOnline) {
    if (_lastKnownOnlineState != isOnline) {
      _lastKnownOnlineState = isOnline;
      onConnectivityChanged(isOnline);
    }
  }
}

/// Widget that shows different content based on connectivity
class OfflineAwareContent extends ConsumerWidget {
  final Widget onlineContent;
  final Widget? offlineContent;
  final Widget Function(Widget child, bool isOnline)? wrapper;

  const OfflineAwareContent({
    super.key,
    required this.onlineContent,
    this.offlineContent,
    this.wrapper,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final content = isOnline ? onlineContent : (offlineContent ?? onlineContent);

    if (wrapper != null) {
      return wrapper!(content, isOnline);
    }

    return content;
  }
}

/// Extension for WidgetRef to easily check connectivity
extension ConnectivityRefExtension on WidgetRef {
  /// Check if device is currently online
  bool get isOnline => watch(isOnlineProvider);

  /// Execute action only if online, otherwise show snackbar
  void executeIfOnline(
    BuildContext context,
    VoidCallback action, {
    String? offlineMessage,
  }) {
    if (isOnline) {
      action();
    } else {
      SnackBarHelper.showOffline(context);
    }
  }

  /// Execute async action only if online
  Future<T?> executeIfOnlineAsync<T>(
    BuildContext context,
    Future<T> Function() action, {
    String? offlineMessage,
  }) async {
    if (isOnline) {
      return action();
    } else {
      SnackBarHelper.showOffline(context);
      return null;
    }
  }
}
