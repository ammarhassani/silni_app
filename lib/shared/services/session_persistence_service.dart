import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:universal_html/html.dart' as html;

/// Simple session persistence service for managing login sessions
class SessionPersistenceService {
  static final SessionPersistenceService _instance =
      SessionPersistenceService._internal();
  factory SessionPersistenceService() => _instance;
  SessionPersistenceService._internal();

  // Session persistence keys
  static const String _sessionActiveKey = 'session_active';
  static const String _sessionTimestampKey = 'session_timestamp';
  static const String _userIdKey = 'user_id';

  /// Initialize session persistence service
  Future<void> initialize() async {
    print('Session persistence service initialized');
  }

  /// Mark user as logged in with persistent session
  Future<void> markUserLoggedIn(String userId) async {
    try {
      await _saveSessionData(
        isActive: true,
        timestamp: DateTime.now().toIso8601String(),
        userId: userId,
      );

      print('User marked as logged in with persistent session');
    } catch (e) {
      print('Failed to mark user as logged in: $e');
    }
  }

  /// Mark user as explicitly logged out
  Future<void> markUserLoggedOut() async {
    try {
      await _clearSessionData();
      print('User marked as logged out');
    } catch (e) {
      print('Failed to mark user as logged out: $e');
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
      print('Error reading stored session data: $e');
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
}
