import 'package:flutter/widgets.dart';
import '../services/performance_monitoring_service.dart';
import '../services/app_logger_service.dart';

/// Navigator observer for automatic screen performance tracking
class PerformanceNavigatorObserver extends NavigatorObserver {
  final PerformanceMonitoringService _perfService =
      PerformanceMonitoringService();
  final AppLoggerService _logger = AppLoggerService();

  final Map<Route<dynamic>, String?> _activeTraces = {};

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _startScreenTrace(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _stopScreenTrace(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null) _stopScreenTrace(oldRoute);
    if (newRoute != null) _startScreenTrace(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _stopScreenTrace(route);
  }

  void _startScreenTrace(Route<dynamic> route) async {
    final screenName = _getScreenName(route);
    final traceId = await _perfService.startScreenTrace(screenName);
    _activeTraces[route] = traceId;

    _logger.debug(
      'Started screen trace: $screenName',
      category: LogCategory.navigation,
      tag: 'PerformanceObserver',
    );
  }

  void _stopScreenTrace(Route<dynamic> route) async {
    final traceId = _activeTraces.remove(route);
    if (traceId != null) {
      await _perfService.stopScreenTrace(traceId);

      _logger.debug(
        'Stopped screen trace: ${_getScreenName(route)}',
        category: LogCategory.navigation,
        tag: 'PerformanceObserver',
      );
    }
  }

  String _getScreenName(Route<dynamic> route) {
    // Try to get the route name, fallback to type
    final name = route.settings.name;
    if (name != null && name.isNotEmpty && name != '/') {
      // Clean up the route name for better readability
      return name.startsWith('/') ? name.substring(1) : name;
    }
    return route.runtimeType.toString();
  }
}
