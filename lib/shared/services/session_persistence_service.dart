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
  // Note: We no longer store passwords - biometric unlocks the existing Supabase session

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

      // Consider session valid if less than 7 days old (security best practice)
      return difference.inDays < 7;
    } catch (e) {
      return false;
    }
  }

  /// Enable biometric login for the current session
  /// Note: We no longer store passwords - biometric just unlocks access to the existing Supabase session
  Future<void> enableBiometricLogin() async {
    try {
      if (kIsWeb) {
        // Don't enable biometric on web
        return;
      }
      final storage = FlutterSecureStorage();
      await storage.write(key: _biometricEnabledKey, value: 'true');
      _logger.info(
        'Biometric login enabled',
        category: LogCategory.auth,
        tag: 'SessionPersistenceService',
      );
    } catch (e) {
      _logger.warning(
        'Failed to enable biometric login',
        category: LogCategory.auth,
        tag: 'SessionPersistenceService',
        metadata: {'error': e.toString()},
      );
    }
  }

  /// Disable biometric login
  Future<void> disableBiometricLogin() async {
    try {
      if (kIsWeb) return;

      final storage = FlutterSecureStorage();
      await storage.delete(key: _biometricEnabledKey);
      _logger.info(
        'Biometric login disabled',
        category: LogCategory.auth,
        tag: 'SessionPersistenceService',
      );
    } catch (e) {
      _logger.warning(
        'Failed to disable biometric login',
        category: LogCategory.auth,
        tag: 'SessionPersistenceService',
        metadata: {'error': e.toString()},
      );
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

  /// Clear biometric settings (alias for disableBiometricLogin for backwards compatibility)
  Future<void> clearBiometricCredentials() async {
    await disableBiometricLogin();
  }
}
