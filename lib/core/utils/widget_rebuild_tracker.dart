import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../services/app_logger_service.dart';

/// Tracks widget rebuilds in debug mode for optimization
class WidgetRebuildTracker {
  static final WidgetRebuildTracker _instance = WidgetRebuildTracker._internal();
  factory WidgetRebuildTracker() => _instance;
  WidgetRebuildTracker._internal();

  final AppLoggerService _logger = AppLoggerService();
  final Map<String, int> _rebuildCounts = {};
  final Map<String, DateTime> _lastRebuild = {};
  final Map<String, int> _windowCounts = {};

  bool _isEnabled = kDebugMode;
  static const int _warnThreshold = 10; // Warn if rebuilt more than 10 times in 1 second
  static const Duration _trackingWindow = Duration(seconds: 1);

  /// Enable/disable tracking
  void setEnabled(bool enabled) {
    _isEnabled = enabled && kDebugMode;
  }

  /// Check if tracking is enabled
  bool get isEnabled => _isEnabled;

  /// Track a widget rebuild
  void trackRebuild(String widgetName) {
    if (!_isEnabled) return;

    final now = DateTime.now();
    final lastTime = _lastRebuild[widgetName];

    // Reset window count if outside tracking window
    if (lastTime != null && now.difference(lastTime) > _trackingWindow) {
      _windowCounts[widgetName] = 0;
    }

    // Increment counts
    _rebuildCounts[widgetName] = (_rebuildCounts[widgetName] ?? 0) + 1;
    _windowCounts[widgetName] = (_windowCounts[widgetName] ?? 0) + 1;
    _lastRebuild[widgetName] = now;

    // Warn about excessive rebuilds
    final windowCount = _windowCounts[widgetName]!;
    if (windowCount == _warnThreshold) {
      _logger.warning(
        'Excessive rebuilds: $widgetName rebuilt $windowCount times in 1 second',
        category: LogCategory.ui,
        tag: 'RebuildTracker',
        metadata: {
          'widget': widgetName,
          'window_count': windowCount,
          'total_count': _rebuildCounts[widgetName],
        },
      );
    }
  }

  /// Get total rebuild count for a widget
  int getRebuildCount(String widgetName) {
    return _rebuildCounts[widgetName] ?? 0;
  }

  /// Get rebuild statistics
  Map<String, int> getRebuildStats() {
    return Map.from(_rebuildCounts);
  }

  /// Get widgets with most rebuilds
  List<MapEntry<String, int>> getTopRebuilders({int limit = 10}) {
    final sorted = _rebuildCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  /// Get widgets that exceeded threshold
  List<String> getProblematicWidgets() {
    return _rebuildCounts.entries
        .where((e) => e.value > _warnThreshold * 10) // 100+ rebuilds
        .map((e) => e.key)
        .toList();
  }

  /// Reset all tracking data
  void reset() {
    _rebuildCounts.clear();
    _lastRebuild.clear();
    _windowCounts.clear();
  }

  /// Log current statistics
  void logStats() {
    if (!_isEnabled) return;

    final topRebuilders = getTopRebuilders(limit: 5);
    if (topRebuilders.isEmpty) return;

    _logger.debug(
      'Widget rebuild stats',
      category: LogCategory.ui,
      tag: 'RebuildTracker',
      metadata: {
        'top_rebuilders': topRebuilders.map((e) => '${e.key}: ${e.value}').toList(),
        'total_tracked': _rebuildCounts.length,
      },
    );
  }
}

/// Global instance for easy access
final rebuildTracker = WidgetRebuildTracker();

/// Mixin for StatefulWidgets that want rebuild tracking
mixin RebuildTrackingMixin<T extends StatefulWidget> on State<T> {
  @override
  Widget build(BuildContext context) {
    rebuildTracker.trackRebuild(widget.runtimeType.toString());
    return buildWithTracking(context);
  }

  /// Override this instead of build() when using the mixin
  Widget buildWithTracking(BuildContext context);
}

/// A wrapper widget for tracking rebuilds of any widget
class RebuildTracker extends StatelessWidget {
  final String name;
  final Widget child;

  const RebuildTracker({
    super.key,
    required this.name,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    rebuildTracker.trackRebuild(name);
    return child;
  }
}
