import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/interaction_model.dart';

/// Service for verifying call completion and duration
class CallVerificationService {
  static const Duration _minimumCallDuration = Duration(
    seconds: 30,
  ); // 30 seconds minimum
  static const Duration _callCheckDelay = Duration(
    seconds: 5,
  ); // Check 5 seconds after call ends

  /// Show post-call confirmation dialog
  static Future<CallVerificationResult?> showPostCallConfirmation({
    required BuildContext context,
    required String phoneNumber,
    required DateTime callStartTime,
  }) async {
    final callDuration = DateTime.now().difference(callStartTime);
    final wasLongEnough = callDuration >= _minimumCallDuration;

    if (kDebugMode) {
      print('📞 [CALL_VERIFICATION] Call duration: ${callDuration.inSeconds}s');
    }

    return showDialog<CallVerificationResult>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.black87,
            title: Row(
              children: [
                Icon(
                  wasLongEnough ? Icons.check_circle : Icons.timer,
                  color: wasLongEnough ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 12),
                Text(
                  wasLongEnough ? 'تأكيد المكالمة' : 'المكالمة قصيرة',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الرقم: $phoneNumber',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'المدة: ${callDuration.inMinutes} دقيقة ${callDuration.inSeconds % 60} ثانية',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (wasLongEnough ? Colors.green : Colors.orange)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: wasLongEnough ? Colors.green : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    wasLongEnough
                        ? 'المكالمة استمرت للمدة المطلوبة وسيتم احتساب النقاط'
                        : 'المكالمة لم تستمر للمدة المطلوبة (30 ثانية على الأقل). هل تريد تأكيد المكالمة على أي حال؟',
                    style: TextStyle(
                      color: wasLongEnough ? Colors.green : Colors.orange,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (!wasLongEnough) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(
                            CallVerificationResult(
                              status: CallVerificationStatus.tooShort,
                              duration: callDuration,
                              phoneNumber: phoneNumber,
                              timestamp: callStartTime,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('لا، مكالمة قصيرة'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(
                            CallVerificationResult(
                              status: CallVerificationStatus.verified,
                              duration: callDuration,
                              phoneNumber: phoneNumber,
                              timestamp: callStartTime,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('نعم، أكد المكالمة'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              if (wasLongEnough)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(
                    CallVerificationResult(
                      status: CallVerificationStatus.verified,
                      duration: callDuration,
                      phoneNumber: phoneNumber,
                      timestamp: callStartTime,
                    ),
                  ),
                  child: const Text(
                    'موافق',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
            ],
          ),
        ) ??
        CallVerificationResult(
          status: CallVerificationStatus.cancelled,
          duration: callDuration,
          phoneNumber: phoneNumber,
          timestamp: callStartTime,
        );
  }

  /// Create a verified interaction from a successful call
  static Interaction createVerifiedInteraction({
    required String userId,
    required String relativeId,
    required CallVerificationResult verificationResult,
  }) {
    return Interaction(
      id: '',
      userId: userId,
      relativeId: relativeId,
      type: InteractionType.call,
      date: verificationResult.timestamp ?? DateTime.now(),
      duration: verificationResult
          .duration
          .inSeconds, // Convert Duration to seconds (int)
      notes: 'مكالمة موثقة (${verificationResult.duration.inMinutes} دقيقة)',
      createdAt: DateTime.now(),
    );
  }

  /// Get user-friendly duration text
  static String getDurationText(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes دقيقة $seconds ثانية';
  }

  /// Check if duration meets minimum requirement
  static bool meetsMinimumDuration(Duration duration) {
    return duration >= _minimumCallDuration;
  }
}

/// Result of call verification
class CallVerificationResult {
  final CallVerificationStatus status;
  final Duration duration;
  final String phoneNumber;
  final DateTime? timestamp;
  final Duration? minimumRequired;
  final String? errorMessage;

  CallVerificationResult({
    required this.status,
    required this.duration,
    required this.phoneNumber,
    this.timestamp,
    this.minimumRequired,
    this.errorMessage,
  });

  bool get isVerified => status == CallVerificationStatus.verified;
  bool get isTooShort => status == CallVerificationStatus.tooShort;
  bool get hasError => status == CallVerificationStatus.error;
  bool get wasCancelled => status == CallVerificationStatus.cancelled;

  @override
  String toString() {
    return 'CallVerificationResult(status: $status, duration: $duration, phone: $phoneNumber)';
  }
}

/// Status of call verification
enum CallVerificationStatus {
  verified,
  tooShort,
  noCallFound,
  error,
  permissionDenied,
  cancelled;

  String get arabicMessage {
    switch (this) {
      case CallVerificationStatus.verified:
        return 'تم التحقق من المكالمة بنجاح';
      case CallVerificationStatus.tooShort:
        return 'المكالمة قصيرة جداً';
      case CallVerificationStatus.noCallFound:
        return 'لم يتم العثور على مكالمة';
      case CallVerificationStatus.error:
        return 'خطأ في التحقق';
      case CallVerificationStatus.permissionDenied:
        return 'إذن الوصول إلى سجل المكالمات مطلوب';
      case CallVerificationStatus.cancelled:
        return 'تم إلغاء التحقق';
    }
  }

  String get arabicDescription {
    switch (this) {
      case CallVerificationStatus.verified:
        return 'تم التحقق من أن المكالمة استمرت للمدة المطلوبة';
      case CallVerificationStatus.tooShort:
        return 'المكالمة لم تستمر للمدة المطلوبة (30 ثانية على الأقل)';
      case CallVerificationStatus.noCallFound:
        return 'لم يتم العثور على مكالمة مسجلة للرقم المحدد';
      case CallVerificationStatus.error:
        return 'حدث خطأ أثناء التحقق من المكالمة';
      case CallVerificationStatus.permissionDenied:
        return 'نحتاج إلى إذن للوصول إلى سجل المكالمات للتحقق من المكالمات';
      case CallVerificationStatus.cancelled:
        return 'قام المستخدم بإلغاء عملية التحقق';
    }
  }
}
