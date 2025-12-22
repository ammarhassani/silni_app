import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

import 'app_logger_service.dart';

/// Connectivity status
enum ConnectivityStatus {
  online,
  offline,
  checking,
}

/// Service for monitoring network connectivity
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final AppLoggerService _logger = AppLoggerService();

  // Stream controller for connectivity status changes
  final _statusController = StreamController<ConnectivityStatus>.broadcast();

  // Current status
  ConnectivityStatus _currentStatus = ConnectivityStatus.checking;

  // Timer for periodic checks
  Timer? _checkTimer;

  // Web event subscriptions
  StreamSubscription<html.Event>? _onlineSubscription;
  StreamSubscription<html.Event>? _offlineSubscription;

  // Last check timestamp
  DateTime? _lastCheck;

  // Minimum interval between checks
  static const Duration _minCheckInterval = Duration(seconds: 5);

  /// Stream of connectivity status changes
  Stream<ConnectivityStatus> get onStatusChange => _statusController.stream;

  /// Current connectivity status
  ConnectivityStatus get currentStatus => _currentStatus;

  /// Whether device is currently online
  bool get isOnline => _currentStatus == ConnectivityStatus.online;

  /// Initialize the service and start monitoring
  void initialize() {
    // Do initial check
    checkConnectivity();

    // For web: Listen to browser online/offline events for instant updates
    if (kIsWeb) {
      _onlineSubscription = html.window.onOnline.listen((_) {
        _updateStatus(ConnectivityStatus.online);
      });
      _offlineSubscription = html.window.onOffline.listen((_) {
        _updateStatus(ConnectivityStatus.offline);
      });
    }

    // Start periodic monitoring (every 30 seconds)
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      checkConnectivity();
    });

    _logger.info(
      'Connectivity service initialized',
      category: LogCategory.network,
    );
  }

  /// Update connectivity status and notify listeners
  void _updateStatus(ConnectivityStatus newStatus) {
    if (_currentStatus != newStatus) {
      _logger.info(
        'Connectivity changed: ${_currentStatus.name} -> ${newStatus.name}',
        category: LogCategory.network,
      );
      _currentStatus = newStatus;
      _statusController.add(newStatus);
    }
  }

  /// Dispose the service
  void dispose() {
    _checkTimer?.cancel();
    _onlineSubscription?.cancel();
    _offlineSubscription?.cancel();
    _statusController.close();
  }

  /// Check current connectivity
  Future<bool> checkConnectivity({bool force = false}) async {
    // Throttle checks unless forced
    if (!force && _lastCheck != null) {
      final elapsed = DateTime.now().difference(_lastCheck!);
      if (elapsed < _minCheckInterval) {
        return _currentStatus == ConnectivityStatus.online;
      }
    }

    _lastCheck = DateTime.now();
    final previousStatus = _currentStatus;

    try {
      // Try multiple hosts for reliability
      final isOnline = await _checkInternetConnection();

      _currentStatus =
          isOnline ? ConnectivityStatus.online : ConnectivityStatus.offline;

      // Notify if status changed
      if (previousStatus != _currentStatus) {
        _logger.info(
          'Connectivity changed: ${previousStatus.name} -> ${_currentStatus.name}',
          category: LogCategory.network,
        );
        _statusController.add(_currentStatus);
      }

      return isOnline;
    } catch (e) {
      _currentStatus = ConnectivityStatus.offline;

      if (previousStatus != _currentStatus) {
        _logger.warning(
          'Connectivity check failed: $e',
          category: LogCategory.network,
        );
        _statusController.add(_currentStatus);
      }

      return false;
    }
  }

  /// Internal connectivity check
  /// Uses HTTP HEAD request for web, DNS lookup for mobile
  Future<bool> _checkInternetConnection() async {
    if (kIsWeb) {
      return _checkInternetConnectionWeb();
    }
    return _checkInternetConnectionMobile();
  }

  /// Web: Use browser's navigator.onLine API
  /// HTTP requests to external domains are blocked by CORS
  Future<bool> _checkInternetConnectionWeb() async {
    // Use browser's native navigator.onLine API
    // This is instant, doesn't require network requests, and has no CORS issues
    return html.window.navigator.onLine ?? true;
  }

  /// Mobile: Use DNS lookup for connectivity check
  Future<bool> _checkInternetConnectionMobile() async {
    final hosts = ['google.com', 'cloudflare.com', 'apple.com'];

    for (final host in hosts) {
      try {
        final result = await InternetAddress.lookup(host)
            .timeout(const Duration(seconds: 5));

        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (e) {
        // Try next host
        continue;
      }
    }

    return false;
  }

  /// Wait for connectivity with timeout
  ///
  /// Returns true if online, false if timeout reached
  Future<bool> waitForConnection({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    // Already online
    if (await checkConnectivity(force: true)) {
      return true;
    }

    // Wait for status change
    try {
      await _statusController.stream
          .firstWhere((status) => status == ConnectivityStatus.online)
          .timeout(timeout);
      return true;
    } on TimeoutException {
      return false;
    }
  }

  /// Execute operation when online, or throw if offline
  Future<T> requireConnection<T>(Future<T> Function() operation) async {
    if (!await checkConnectivity()) {
      throw const SocketException('No internet connection');
    }
    return operation();
  }

  /// Force a connectivity check and update status
  Future<void> refresh() async {
    await checkConnectivity(force: true);
  }
}

/// Global connectivity service instance
final connectivityService = ConnectivityService();
