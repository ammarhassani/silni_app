import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:universal_html/html.dart' as html;
import '../../core/services/app_logger_service.dart';

/// Simple session persistence service for managing login sessions
class SessionPersistenceService {
  static final SessionPersistenceService _instance =
      SessionPersistenceService._internal();
  factory SessionPersistenceService() => _instance;
  SessionPersistenceService._internal();

  final AppLoggerService _logger = AppLoggerService();

  // Session persistence keys
  static const String _sessionActiveKey = 'session_active';
  static const String _sessionTimestampKey = 'session_timestamp';
  static const String _userIdKey = 'user_id';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _storedEmailKey = 'stored_email';
  static const String _storedPasswordKey = 'stored_password';

  /// Initialize session persistence service
  Future<void> initialize() async {
    // Service initialized
  }

  /// Mark user as logged in with persistent session
  Future<void> markUserLoggedIn(String userId) async {
    try {
      await _saveSessionData(
        isActive: true,
        timestamp: DateTime.now().toIso8601String(),
        userId: userId,
      );
    } catch (e) {
      _logger.warning(
        'Failed to mark user logged in',
        category: LogCategory.auth,
        tag: 'SessionPersistenceService',
        metadata: {'userId': userId, 'error': e.toString()},
      );
    }
  }

  /// Mark user as explicitly logged out
  Future<void> markUserLoggedOut() async {
    try {
      await _clearSessionData();
    } catch (e) {
      _logger.warning(
        'Failed to mark user logged out',
        category: LogCategory.auth,
        tag: 'SessionPersistenceService',
        metadata: {'error': e.toString()},
      );
    }
  }

  /// Save session data to persistent storage
  Future<void> _saveSessionData({
    required bool isActive,
    required String timestamp,
    required String userId,
  }) async {
    if (kIsWeb) {
      // Use web storage
      html.window.localStorage[_sessionActiveKey] = isActive.toString();
      html.window.localStorage[_sessionTimestampKey] = timestamp;
      html.window.localStorage[_userIdKey] = userId;
    } else {
      // Use secure storage for mobile
      final storage = FlutterSecureStorage();
      await storage.write(key: _sessionActiveKey, value: isActive.toString());
      await storage.write(key: _sessionTimestampKey, value: timestamp);
      await storage.write(key: _userIdKey, value: userId);
    }
  }

  /// Clear session data from persistent storage
  Future<void> _clearSessionData() async {
    if (kIsWeb) {
      html.window.localStorage.remove(_sessionActiveKey);
      html.window.localStorage.remove(_sessionTimestampKey);
      html.window.localStorage.remove(_userIdKey);
    } else {
      final storage = FlutterSecureStorage();
      await storage.delete(key: _sessionActiveKey);
      await storage.delete(key: _sessionTimestampKey);
      await storage.delete(key: _userIdKey);
    }
  }

  /// Get stored session data
  Future<Map<String, String?>?> getStoredSessionData() async {
    try {
      if (kIsWeb) {
        return {
          _sessionActiveKey: html.window.localStorage[_sessionActiveKey],
          _sessionTimestampKey: html.window.localStorage[_sessionTimestampKey],
          _userIdKey: html.window.localStorage[_userIdKey],
        };
      } else {
        final storage = FlutterSecureStorage();
        return {
          _sessionActiveKey: await storage.read(key: _sessionActiveKey),
          _sessionTimestampKey: await storage.read(key: _sessionTimestampKey),
          _userIdKey: await storage.read(key: _userIdKey),
        };
      }
    } catch (e) {
      _logger.warning(
        'Failed to get stored session data',
        category: LogCategory.auth,
        tag: 'SessionPersistenceService',
        metadata: {'error': e.toString()},
      );
      return null;
    }
  }

  /// Check if stored session is still valid
  bool isStoredSessionValid(Map<String, String?>? sessionData) {
    if (sessionData == null) return false;

    final isActive = sessionData[_sessionActiveKey] == 'true';
    final timestamp = sessionData[_sessionTimestampKey];

    if (!isActive || timestamp == null) return false;

    try {
      final sessionTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(sessionTime);

      // Consider session valid if less than 30 days old
      return difference.inDays < 30;
    } catch (e) {
      return false;
    }
  }

  /// Save credentials for biometric login
  Future<void> saveBiometricCredentials({
    required String email,
    required String password,
  }) async {
    try {
      if (kIsWeb) {
        // Don't store credentials on web for security
        return;
      }
      final storage = FlutterSecureStorage();
      await storage.write(key: _storedEmailKey, value: email);
      await storage.write(key: _storedPasswordKey, value: password);
      await storage.write(key: _biometricEnabledKey, value: 'true');
    } catch (e) {
      _logger.warning(
        'Failed to save biometric credentials',
        category: LogCategory.auth,
        tag: 'SessionPersistenceService',
        metadata: {'error': e.toString()},
      );
    }
  }

  /// Get stored biometric credentials
  Future<Map<String, String?>?> getBiometricCredentials() async {
    try {
      if (kIsWeb) return null;

      final storage = FlutterSecureStorage();
      final enabled = await storage.read(key: _biometricEnabledKey);

      if (enabled != 'true') return null;

      final email = await storage.read(key: _storedEmailKey);
      final password = await storage.read(key: _storedPasswordKey);

      if (email == null || password == null) return null;

      return {'email': email, 'password': password};
    } catch (e) {
      _logger.warning(
        'Failed to get biometric credentials',
        category: LogCategory.auth,
        tag: 'SessionPersistenceService',
        metadata: {'error': e.toString()},
      );
      return null;
    }
  }

  /// Check if biometric login is enabled
  Future<bool> isBiometricLoginEnabled() async {
    try {
      if (kIsWeb) return false;

      final storage = FlutterSecureStorage();
      final enabled = await storage.read(key: _biometricEnabledKey);
      return enabled == 'true';
    } catch (e) {
      _logger.warning(
        'Failed to check if biometric login is enabled',
        category: LogCategory.auth,
        tag: 'SessionPersistenceService',
        metadata: {'error': e.toString()},
      );
      return false;
    }
  }

  /// Clear biometric credentials
  Future<void> clearBiometricCredentials() async {
    try {
      if (kIsWeb) return;

      final storage = FlutterSecureStorage();
      await storage.delete(key: _storedEmailKey);
      await storage.delete(key: _storedPasswordKey);
      await storage.delete(key: _biometricEnabledKey);
    } catch (e) {
      _logger.warning(
        'Failed to clear biometric credentials',
        category: LogCategory.auth,
        tag: 'SessionPersistenceService',
        metadata: {'error': e.toString()},
      );
    }
  }
}
