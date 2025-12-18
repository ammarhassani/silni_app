import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:silni_app/core/config/supabase_config.dart';

/// Export status enum for tracking progress
enum ExportStatus {
  idle,
  fetchingProfile,
  fetchingRelatives,
  fetchingInteractions,
  fetchingReminders,
  fetchingNotifications,
  compiling,
  writingFile,
  complete,
  error,
}

/// Progress callback data class
class ExportProgress {
  final ExportStatus status;
  final String currentStepAr;
  final String currentStepEn;
  final double progress;
  final String? error;

  const ExportProgress({
    required this.status,
    required this.currentStepAr,
    required this.currentStepEn,
    this.progress = 0.0,
    this.error,
  });

  factory ExportProgress.idle() => const ExportProgress(
        status: ExportStatus.idle,
        currentStepAr: '',
        currentStepEn: '',
        progress: 0.0,
      );

  factory ExportProgress.fetchingProfile() => const ExportProgress(
        status: ExportStatus.fetchingProfile,
        currentStepAr: 'جاري تحميل بيانات الملف الشخصي...',
        currentStepEn: 'Loading profile data...',
        progress: 0.1,
      );

  factory ExportProgress.fetchingRelatives() => const ExportProgress(
        status: ExportStatus.fetchingRelatives,
        currentStepAr: 'جاري تحميل بيانات الأقارب...',
        currentStepEn: 'Loading relatives data...',
        progress: 0.3,
      );

  factory ExportProgress.fetchingInteractions() => const ExportProgress(
        status: ExportStatus.fetchingInteractions,
        currentStepAr: 'جاري تحميل سجل التفاعلات...',
        currentStepEn: 'Loading interactions history...',
        progress: 0.5,
      );

  factory ExportProgress.fetchingReminders() => const ExportProgress(
        status: ExportStatus.fetchingReminders,
        currentStepAr: 'جاري تحميل جداول التذكير...',
        currentStepEn: 'Loading reminder schedules...',
        progress: 0.6,
      );

  factory ExportProgress.fetchingNotifications() => const ExportProgress(
        status: ExportStatus.fetchingNotifications,
        currentStepAr: 'جاري تحميل سجل الإشعارات...',
        currentStepEn: 'Loading notification history...',
        progress: 0.7,
      );

  factory ExportProgress.compiling() => const ExportProgress(
        status: ExportStatus.compiling,
        currentStepAr: 'جاري تجميع البيانات...',
        currentStepEn: 'Compiling data...',
        progress: 0.85,
      );

  factory ExportProgress.writingFile() => const ExportProgress(
        status: ExportStatus.writingFile,
        currentStepAr: 'جاري حفظ الملف...',
        currentStepEn: 'Saving file...',
        progress: 0.95,
      );

  factory ExportProgress.complete() => const ExportProgress(
        status: ExportStatus.complete,
        currentStepAr: 'تم التصدير بنجاح!',
        currentStepEn: 'Export complete!',
        progress: 1.0,
      );

  factory ExportProgress.withError(String errorMessage) => ExportProgress(
        status: ExportStatus.error,
        currentStepAr: 'حدث خطأ أثناء التصدير',
        currentStepEn: 'Error during export',
        progress: 0.0,
        error: errorMessage,
      );
}

/// Result of a successful export
class ExportResult {
  final String filePath;
  final int totalRecords;
  final DateTime exportDate;

  const ExportResult({
    required this.filePath,
    required this.totalRecords,
    required this.exportDate,
  });
}

/// Service for exporting user data (GDPR + Saudi PDPL compliant)
class DataExportService {
  final SupabaseClient _client;

  DataExportService({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  /// Export all user data to a JSON file
  ///
  /// Returns the path to the exported file
  /// Calls [onProgress] with updates during the export process
  Future<ExportResult> exportUserData({
    required String userId,
    void Function(ExportProgress)? onProgress,
  }) async {
    try {
      // Step 1: Fetch user profile
      onProgress?.call(ExportProgress.fetchingProfile());
      final userProfile = await _fetchUserProfile(userId);

      // Step 2: Fetch all relatives (including archived)
      onProgress?.call(ExportProgress.fetchingRelatives());
      final relatives = await _fetchAllRelatives(userId);

      // Step 3: Fetch all interactions
      onProgress?.call(ExportProgress.fetchingInteractions());
      final interactions = await _fetchAllInteractions(userId);

      // Step 4: Fetch all reminder schedules
      onProgress?.call(ExportProgress.fetchingReminders());
      final reminderSchedules = await _fetchAllReminderSchedules(userId);

      // Step 5: Fetch notification history
      onProgress?.call(ExportProgress.fetchingNotifications());
      final notifications = await _fetchNotificationHistory(userId);

      // Step 6: Compile export data
      onProgress?.call(ExportProgress.compiling());
      final exportData = await _compileExportData(
        userId: userId,
        userProfile: userProfile,
        relatives: relatives,
        interactions: interactions,
        reminderSchedules: reminderSchedules,
        notifications: notifications,
      );

      // Step 7: Write to file
      onProgress?.call(ExportProgress.writingFile());
      final filePath = await _writeExportFile(exportData);

      // Calculate total records
      final totalRecords = 1 + // user profile
          relatives.length +
          interactions.length +
          reminderSchedules.length +
          notifications.length;

      onProgress?.call(ExportProgress.complete());

      return ExportResult(
        filePath: filePath,
        totalRecords: totalRecords,
        exportDate: DateTime.now(),
      );
    } catch (e) {
      onProgress?.call(ExportProgress.withError(e.toString()));
      rethrow;
    }
  }

  /// Fetch user profile from users table
  Future<Map<String, dynamic>> _fetchUserProfile(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        // Return basic profile from auth if no user record exists
        final user = _client.auth.currentUser;
        return {
          'id': userId,
          'email': user?.email,
          'full_name': user?.userMetadata?['full_name'],
          'created_at': user?.createdAt,
        };
      }

      return response;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      // Return basic profile on error
      final user = _client.auth.currentUser;
      return {
        'id': userId,
        'email': user?.email,
        'full_name': user?.userMetadata?['full_name'],
        'created_at': user?.createdAt,
      };
    }
  }

  /// Fetch all relatives (including archived)
  Future<List<Map<String, dynamic>>> _fetchAllRelatives(String userId) async {
    try {
      final response = await _client
          .from('relatives')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching relatives: $e');
      return [];
    }
  }

  /// Fetch all interactions
  Future<List<Map<String, dynamic>>> _fetchAllInteractions(
      String userId) async {
    try {
      final response = await _client
          .from('interactions')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching interactions: $e');
      return [];
    }
  }

  /// Fetch all reminder schedules
  Future<List<Map<String, dynamic>>> _fetchAllReminderSchedules(
      String userId) async {
    try {
      final response = await _client
          .from('reminder_schedules')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching reminder schedules: $e');
      return [];
    }
  }

  /// Fetch notification history
  Future<List<Map<String, dynamic>>> _fetchNotificationHistory(
      String userId) async {
    try {
      final response = await _client
          .from('notification_history')
          .select()
          .eq('user_id', userId)
          .order('sent_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Table might not exist - return empty list
      debugPrint('Error fetching notification history: $e');
      return [];
    }
  }

  /// Compile all data into GDPR/PDPL compliant export format
  Future<Map<String, dynamic>> _compileExportData({
    required String userId,
    required Map<String, dynamic> userProfile,
    required List<Map<String, dynamic>> relatives,
    required List<Map<String, dynamic>> interactions,
    required List<Map<String, dynamic>> reminderSchedules,
    required List<Map<String, dynamic>> notifications,
  }) async {
    // Get app version
    final packageInfo = await PackageInfo.fromPlatform();

    // Collect all media URLs
    final mediaUrls = _collectMediaUrls(
      userProfile: userProfile,
      relatives: relatives,
      interactions: interactions,
    );

    return {
      'export_metadata': {
        'export_date': DateTime.now().toUtc().toIso8601String(),
        'app_name': 'Silni',
        'app_version': packageInfo.version,
        'build_number': packageInfo.buildNumber,
        'user_id': userId,
        'compliance': {
          'gdpr': true,
          'saudi_pdpl': true,
          'export_format': 'JSON (machine-readable)',
        },
      },
      'data_categories': {
        'user_profile': {
          'description_ar': 'بيانات الملف الشخصي',
          'description_en': 'Profile data',
          'purpose_ar': 'إدارة حسابك وتخصيص التطبيق',
          'purpose_en': 'Account management and app personalization',
          'legal_basis': 'Consent / Contract performance',
          'retention': 'Until account deletion',
          'record_count': 1,
        },
        'relatives': {
          'description_ar': 'بيانات الأقارب والعائلة',
          'description_en': 'Family and relatives data',
          'purpose_ar': 'تتبع صلة الرحم والتذكير بالتواصل',
          'purpose_en': 'Family connection tracking and communication reminders',
          'legal_basis': 'Consent',
          'retention': 'Until account deletion or manual removal',
          'record_count': relatives.length,
        },
        'interactions': {
          'description_ar': 'سجل التفاعلات مع الأقارب',
          'description_en': 'Interaction history with relatives',
          'purpose_ar': 'تتبع التواصل والإحصائيات',
          'purpose_en': 'Communication tracking and statistics',
          'legal_basis': 'Consent',
          'retention': 'Until account deletion',
          'record_count': interactions.length,
        },
        'reminders': {
          'description_ar': 'إعدادات التذكير',
          'description_en': 'Reminder settings',
          'purpose_ar': 'إرسال تذكيرات للتواصل',
          'purpose_en': 'Sending communication reminders',
          'legal_basis': 'Consent',
          'retention': 'Until disabled or account deletion',
          'record_count': reminderSchedules.length,
        },
        'notifications': {
          'description_ar': 'سجل الإشعارات المرسلة',
          'description_en': 'Sent notification history',
          'purpose_ar': 'تتبع الإشعارات المرسلة',
          'purpose_en': 'Track sent notifications',
          'legal_basis': 'Consent',
          'retention': 'Until account deletion',
          'record_count': notifications.length,
        },
      },
      'user_profile': userProfile,
      'relatives': relatives,
      'interactions': interactions,
      'reminder_schedules': reminderSchedules,
      'notification_history': notifications,
      'media_urls': mediaUrls,
    };
  }

  /// Collect all media URLs from the data
  Map<String, dynamic> _collectMediaUrls({
    required Map<String, dynamic> userProfile,
    required List<Map<String, dynamic>> relatives,
    required List<Map<String, dynamic>> interactions,
  }) {
    final profilePicture = userProfile['profile_picture_url'] as String?;

    final relativePhotos = <String, String>{};
    for (final relative in relatives) {
      final photoUrl = relative['photo_url'] as String?;
      if (photoUrl != null && photoUrl.isNotEmpty) {
        relativePhotos[relative['id'] as String] = photoUrl;
      }
    }

    final interactionMedia = <String, Map<String, dynamic>>{};
    for (final interaction in interactions) {
      final photoUrls = interaction['photo_urls'] as List?;
      final audioUrl = interaction['audio_note_url'] as String?;

      if ((photoUrls != null && photoUrls.isNotEmpty) ||
          (audioUrl != null && audioUrl.isNotEmpty)) {
        interactionMedia[interaction['id'] as String] = {
          'photos': photoUrls ?? [],
          'audio': audioUrl,
        };
      }
    }

    return {
      'profile_picture': profilePicture,
      'relative_photos': relativePhotos,
      'interaction_media': interactionMedia,
    };
  }

  /// Write export data to a JSON file
  Future<String> _writeExportFile(Map<String, dynamic> exportData) async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${directory.path}/exports');

    // Create exports directory if it doesn't exist
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    // Generate filename with timestamp
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final filename = 'silni_data_export_$timestamp.json';
    final filePath = '${exportDir.path}/$filename';

    // Write JSON with pretty formatting
    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
    final file = File(filePath);
    await file.writeAsString(jsonString, flush: true);

    return filePath;
  }
}
