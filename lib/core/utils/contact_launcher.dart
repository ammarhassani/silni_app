import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/utils/ui_helpers.dart';

/// Utility class for launching contact-related URLs
class ContactLauncher {
  const ContactLauncher._();

  /// Make a phone call
  static Future<bool> makeCall(
    String phoneNumber, {
    required BuildContext context,
  }) async {
    HapticFeedback.mediumImpact();

    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return true;
    } else {
      if (context.mounted) {
        UIHelpers.showSnackBar(
          context,
          'لا يمكن إجراء المكالمة',
          isError: true,
        );
      }
      return false;
    }
  }

  /// Open WhatsApp
  ///
  /// wa.me requires full international format without leading zero or '+'.
  /// Converts Saudi local numbers (05x) to international (9665x).
  static Future<bool> openWhatsApp(
    String phoneNumber, {
    required BuildContext context,
    String? message,
  }) async {
    HapticFeedback.mediumImpact();

    // Remove any non-digit characters except +
    var cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    // Strip leading + (wa.me uses digits only)
    cleanNumber = cleanNumber.replaceFirst(RegExp(r'^\+'), '');
    // Convert Saudi local format (05x...) to international (9665x...)
    if (cleanNumber.startsWith('05')) {
      cleanNumber = '966${cleanNumber.substring(1)}';
    } else if (cleanNumber.startsWith('5') && cleanNumber.length == 9) {
      cleanNumber = '966$cleanNumber';
    }
    final textParam = message != null ? '?text=${Uri.encodeComponent(message)}' : '';
    final uri = Uri.parse('https://wa.me/$cleanNumber$textParam');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    } else {
      if (context.mounted) {
        UIHelpers.showSnackBar(
           context,
          'لا يمكن فتح واتساب',
          isError: true,
        );
      }
      return false;
    }
  }

  /// Send SMS
  static Future<bool> sendSms(
    String phoneNumber, {
    required BuildContext context,
  }) async {
    final uri = Uri.parse('sms:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return true;
    } else {
      if (context.mounted) {
        UIHelpers.showSnackBar(
          context,
          'لا يمكن إرسال رسالة',
          isError: true,
        );
      }
      return false;
    }
  }
}
