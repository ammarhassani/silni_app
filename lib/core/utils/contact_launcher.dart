import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن إجراء المكالمة')),
        );
      }
      return false;
    }
  }

  /// Open WhatsApp
  static Future<bool> openWhatsApp(
    String phoneNumber, {
    required BuildContext context,
  }) async {
    HapticFeedback.mediumImpact();

    // Remove any non-digit characters
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$cleanNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن فتح واتساب')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن إرسال رسالة')),
        );
      }
      return false;
    }
  }
}
