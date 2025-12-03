import 'dart:collection';
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Log levels ordered by severity
enum LogLevel {
  debug,    // Development details
  info,     // General information
  warning,  // Warning messages
  error,    // Error messages
  critical, // Critical failures
}

/// Log categories for filtering
enum LogCategory {
  auth,           // Authentication & authorization
  navigation,     // Navigation & routing
  network,        // API calls & network
  database,       // Supabase queries
  ui,            // UI interactions
  analytics,     // Analytics events
  gamification,  // Gamification system
  service,       // Service operations
  lifecycle,     // App lifecycle events
  unknown,       // Uncategorized
}

/// A single log entry
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final LogCategory category;
  final String message;
  final String? tag; // Optional sub-category (e.g., "SignUpScreen")
  final Map<String, dynamic>? metadata; // Additional context
  final StackTrace? stackTrace; // For errors

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.category,
    required this.message,
    this.tag,
    this.metadata,
    this.stackTrace,
  });

  /// Format as readable string
  String format({bool includeMetadata = true}) {
    final buffer = StringBuffer();

    // Timestamp
    final time = '${timestamp.hour.toString().padLeft(2, '0')}:'
                 '${timestamp.minute.toString().padLeft(2, '0')}:'
                 '${timestamp.second.toString().padLeft(2, '0')}.'
                 '${(timestamp.millisecond ~/ 100)}';

    // Level prefix
    final levelStr = level.name.toUpperCase().padRight(8);

    // Category with optional tag
    final categoryStr = tag != null
        ? '${category.name}.$tag'
        : category.name;

    buffer.write('[$time] $levelStr [$categoryStr] $message');

    // Add metadata if present
    if (includeMetadata && metadata != null && metadata!.isNotEmpty) {
      buffer.write('\n  └─ ${metadata.toString()}');
    }

    // Add stack trace for errors
    if (stackTrace != null) {
      final traceLines = stackTrace.toString().split('\n').take(5).join('\n  ');
      buffer.write('\n  StackTrace:\n  $traceLines');
    }

    return buffer.toString();
  }
}

/// Centralized logging service
class AppLoggerService {
  static final AppLoggerService _instance = AppLoggerService._internal();
  factory AppLoggerService() => _instance;
  AppLoggerService._internal();

  // Configuration
  static const int _maxLogEntries = 1000; // Maximum logs to keep in memory
  static const int _rotationThreshold = 800; // Rotate when this many logs

  // Log storage - using Queue for efficient add/remove
  final Queue<LogEntry> _logs = Queue<LogEntry>();

  // Enable/disable logging (for production builds)
  bool _isEnabled = kDebugMode; // Default: only in debug mode

  // Minimum log level to capture
  LogLevel _minLevel = LogLevel.debug;

  // Stream controller for real-time updates
  final _logStreamController = StreamController<LogEntry>.broadcast();

  /// Stream of new log entries (for UI updates)
  Stream<LogEntry> get logStream => _logStreamController.stream;

  /// Get all logs
  UnmodifiableListView<LogEntry> get logs => UnmodifiableListView(_logs);

  /// Get log count
  int get logCount => _logs.length;

  /// Enable or disable logging
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Set minimum log level
  void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// Log a message
  void log({
    required LogLevel level,
    required LogCategory category,
    required String message,
    String? tag,
    Map<String, dynamic>? metadata,
    StackTrace? stackTrace,
  }) {
    if (!_isEnabled) return;
    if (level.index < _minLevel.index) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      category: category,
      message: message,
      tag: tag,
      metadata: metadata,
      stackTrace: stackTrace,
    );

    // Add to queue
    _logs.addLast(entry);

    // Rotate if needed (remove oldest logs)
    if (_logs.length > _maxLogEntries) {
      final toRemove = _logs.length - _rotationThreshold;
      for (int i = 0; i < toRemove; i++) {
        _logs.removeFirst();
      }
    }

    // Emit to stream
    if (!_logStreamController.isClosed) {
      _logStreamController.add(entry);
    }

    // Also print to console (for Xcode when available)
    if (kDebugMode) {
      debugPrint(entry.format(includeMetadata: false));
    }
  }

  // Convenience methods for each level
  void debug(String message, {
    LogCategory category = LogCategory.unknown,
    String? tag,
    Map<String, dynamic>? metadata,
  }) => log(
    level: LogLevel.debug,
    category: category,
    message: message,
    tag: tag,
    metadata: metadata,
  );

  void info(String message, {
    LogCategory category = LogCategory.unknown,
    String? tag,
    Map<String, dynamic>? metadata,
  }) => log(
    level: LogLevel.info,
    category: category,
    message: message,
    tag: tag,
    metadata: metadata,
  );

  void warning(String message, {
    LogCategory category = LogCategory.unknown,
    String? tag,
    Map<String, dynamic>? metadata,
  }) => log(
    level: LogLevel.warning,
    category: category,
    message: message,
    tag: tag,
    metadata: metadata,
  );

  void error(String message, {
    LogCategory category = LogCategory.unknown,
    String? tag,
    Map<String, dynamic>? metadata,
    StackTrace? stackTrace,
  }) => log(
    level: LogLevel.error,
    category: category,
    message: message,
    tag: tag,
    metadata: metadata,
    stackTrace: stackTrace,
  );

  void critical(String message, {
    LogCategory category = LogCategory.unknown,
    String? tag,
    Map<String, dynamic>? metadata,
    StackTrace? stackTrace,
  }) => log(
    level: LogLevel.critical,
    category: category,
    message: message,
    tag: tag,
    metadata: metadata,
    stackTrace: stackTrace,
  );

  /// Clear all logs
  void clear() {
    _logs.clear();
  }

  /// Export logs as string
  String exportLogs({
    LogLevel? minLevel,
    LogCategory? category,
  }) {
    final filtered = _logs.where((entry) {
      if (minLevel != null && entry.level.index < minLevel.index) {
        return false;
      }
      if (category != null && entry.category != category) {
        return false;
      }
      return true;
    });

    return filtered.map((e) => e.format()).join('\n');
  }

  /// Dispose
  void dispose() {
    _logStreamController.close();
  }
}
