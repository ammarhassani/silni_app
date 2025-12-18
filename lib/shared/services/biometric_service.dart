import 'dart:io';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/services/app_logger_service.dart';

/// Service for handling biometric authentication (FaceID/TouchID)
class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final AppLoggerService _logger = AppLoggerService();
  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if device supports biometric authentication
  Future<bool> isDeviceSupported() async {
    try {
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      
      _logger.info(
        'Biometric support check',
        category: LogCategory.service,
        tag: 'BiometricService',
        metadata: {
          'canCheckBiometrics': canCheckBiometrics,
          'isDeviceSupported': isDeviceSupported,
          'platform': Platform.operatingSystem,
        },
      );
      
      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      _logger.error(
        'Error checking biometric support: ${e.toString()}',
        category: LogCategory.service,
        tag: 'BiometricService',
      );
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final availableBiometrics = await _auth.getAvailableBiometrics();
      
      _logger.info(
        'Available biometrics retrieved',
        category: LogCategory.service,
        tag: 'BiometricService',
        metadata: {
          'biometrics': availableBiometrics.map((b) => b.toString()).toList(),
        },
      );
      
      return availableBiometrics;
    } catch (e) {
      _logger.error(
        'Error getting available biometrics: ${e.toString()}',
        category: LogCategory.service,
        tag: 'BiometricService',
      );
      return [];
    }
  }

  /// Authenticate with biometrics
  Future<BiometricAuthResult> authenticate({
    String reason = 'التحقق من الهوية للوصول إلى التطبيق',
    bool useErrorDialogs = true,
  }) async {
    try {
      _logger.info(
        'Starting biometric authentication',
        category: LogCategory.service,
        tag: 'BiometricService',
        metadata: {'reason': reason},
      );

      final isAuthenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (isAuthenticated) {
        _logger.info(
          'Biometric authentication successful',
          category: LogCategory.service,
          tag: 'BiometricService',
        );
        return BiometricAuthResult.success();
      } else {
        _logger.warning(
          'Biometric authentication failed',
          category: LogCategory.service,
          tag: 'BiometricService',
        );
        return BiometricAuthResult.failed('Authentication failed');
      }
    } on PlatformException catch (e) {
      _logger.error(
        'Biometric authentication error: ${e.toString()}',
        category: LogCategory.service,
        tag: 'BiometricService',
        metadata: {'code': e.code, 'message': e.message},
      );

      return BiometricAuthResult.error(
        _getErrorMessage(e.code),
        e.code,
      );
    } catch (e) {
      _logger.error(
        'Unexpected biometric authentication error: ${e.toString()}',
        category: LogCategory.service,
        tag: 'BiometricService',
      );
      return BiometricAuthResult.error('Unexpected error occurred', 'unknown');
    }
  }

  /// Get user-friendly error message for biometric errors
  String _getErrorMessage(String? code) {
    switch (code) {
      case 'biometric_not_available':
        return 'التعرف البيومتري غير متاح على هذا الجهاز';
      case 'biometric_not_enrolled':
        return 'لم يتم تسجيل أي بيانات بيومترية على هذا الجهاز';
      case 'biometric_locked_out':
        return 'التعرف البيومتري مقفل. يرجى استخدام كلمة المرور';
      case 'biometric_perm_denied':
        return 'تم رفض إذن التعرف البيومتري';
      case 'other_operation_in_progress':
        return 'عملية أخرى قيد التقدم';
      case 'passcode_not_set':
        return 'لم يتم تعيين رمز مرور على الجهاز';
      case 'user_cancel':
        return 'تم إلغاء المصادقة من قبل المستخدم';
      case 'user_fallback':
        return 'تم اختيار طريقة بديلة';
      case 'system_cancel':
        return 'تم إلغاء المصادقة من قبل النظام';
      default:
        return 'حدث خطأ في المصادقة البيومترية';
    }
  }

  /// Check if biometrics are enrolled
  Future<bool> areBiometricsEnrolled() async {
    try {
      final availableBiometrics = await getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      _logger.error(
        'Error checking if biometrics are enrolled: ${e.toString()}',
        category: LogCategory.service,
        tag: 'BiometricService',
      );
      return false;
    }
  }

  /// Get biometric type name in Arabic
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Touch ID';
      case BiometricType.iris:
        return 'المسح الضوئي للقزحية';
      case BiometricType.strong:
        return 'مصادقة قوية';
      case BiometricType.weak:
        return 'مصادقة ضعيفة';
    }
  }
}

/// Result of biometric authentication
class BiometricAuthResult {
  final bool success;
  final bool error;
  final String? errorMessage;
  final String? errorCode;

  BiometricAuthResult._({
    required this.success,
    required this.error,
    this.errorMessage,
    this.errorCode,
  });

  factory BiometricAuthResult.success() {
    return BiometricAuthResult._(
      success: true,
      error: false,
    );
  }

  factory BiometricAuthResult.failed(String message) {
    return BiometricAuthResult._(
      success: false,
      error: false,
      errorMessage: message,
    );
  }

  factory BiometricAuthResult.error(String message, String code) {
    return BiometricAuthResult._(
      success: false,
      error: true,
      errorMessage: message,
      errorCode: code,
    );
  }
}
