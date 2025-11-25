import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Global navigation service for handling navigation from services
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Navigate to a route using GoRouter
  static void navigateTo(String path, {Map<String, String>? pathParameters}) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    if (pathParameters != null && pathParameters.isNotEmpty) {
      // Build path with parameters
      String fullPath = path;
      pathParameters.forEach((key, value) {
        fullPath = fullPath.replaceAll(':$key', value);
      });
      context.go(fullPath);
    } else {
      context.go(path);
    }
  }

  /// Push a named route
  static void pushNamed(String name, {Map<String, String>? pathParameters}) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    if (pathParameters != null) {
      context.pushNamed(name, pathParameters: pathParameters);
    } else {
      context.pushNamed(name);
    }
  }

  /// Navigate back
  static void goBack() {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    context.pop();
  }

  /// Get current context
  static BuildContext? get currentContext => navigatorKey.currentContext;
}
