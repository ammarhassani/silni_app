import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/logger_provider.dart';
import 'logger_overlay.dart';
import 'logger_fab.dart';

/// Host widget that wraps the app and shows logger UI
class LoggerHost extends ConsumerWidget {
  final Widget child;
  final bool showFAB;

  const LoggerHost({super.key, required this.child, this.showFAB = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(loggerVisibilityProvider);

    return Stack(
      children: [
        // App content
        child,

        // Logger overlay (when visible and in debug mode)
        if (isVisible && kDebugMode) const LoggerOverlay(),

        // FAB to toggle logger (only in debug mode)
        if (showFAB && kDebugMode) const LoggerFAB(),
      ],
    );
  }
}
