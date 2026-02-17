import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';

/// Service for handling image uploads to Supabase Storage
/// Replaces Cloudinary for consistent storage solution
class SupabaseStorageService {
  static const String _profileBucket = 'profile-pictures';
  static const String _relativeBucket = 'relative-photos';
  static const String _voiceNotesBucket = 'voice-notes';

  /// Upload user profile picture
  /// Returns the public URL of the uploaded image
  Future<String> uploadUserProfilePicture(XFile imageFile, String userId) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.name.split('.').last.toLowerCase();
      final fileName = 'profile.$fileExt';
      final filePath = '$userId/$fileName';

      // Upload to Supabase Storage (upsert to replace existing)
      await SupabaseConfig.client.storage.from(_profileBucket).uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$fileExt',
          upsert: true,
        ),
      );

      // Get public URL
      final publicUrl = SupabaseConfig.client.storage
          .from(_profileBucket)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      rethrow;
    }
  }

  /// Upload relative photo
  /// Returns the public URL of the uploaded image
  Future<String> uploadRelativePhoto(
    XFile imageFile,
    String userId,
    String relativeId,
  ) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.name.split('.').last.toLowerCase();
      final fileName = '$relativeId.$fileExt';
      final filePath = '$userId/$fileName';

      // Upload to Supabase Storage (upsert to replace existing)
      await SupabaseConfig.client.storage.from(_relativeBucket).uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$fileExt',
          upsert: true,
        ),
      );

      // Get public URL
      final publicUrl = SupabaseConfig.client.storage
          .from(_relativeBucket)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete user profile picture
  Future<void> deleteUserProfilePicture(String userId) async {
    try {
      // List files in user folder to find the profile picture
      final files = await SupabaseConfig.client.storage
          .from(_profileBucket)
          .list(path: userId);

      for (final file in files) {
        if (file.name.startsWith('profile.')) {
          await SupabaseConfig.client.storage
              .from(_profileBucket)
              .remove(['$userId/${file.name}']);
          break;
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete relative photo
  Future<void> deleteRelativePhoto(String userId, String relativeId) async {
    try {
      // List files in user folder to find the relative photo
      final files = await SupabaseConfig.client.storage
          .from(_relativeBucket)
          .list(path: userId);

      for (final file in files) {
        if (file.name.startsWith('$relativeId.')) {
          await SupabaseConfig.client.storage
              .from(_relativeBucket)
              .remove(['$userId/${file.name}']);
          break;
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Upload voice note audio file.
  /// Returns the public URL of the uploaded audio.
  Future<String> uploadVoiceNote(
    String localFilePath,
    String userId,
    String interactionId,
  ) async {
    try {
      final bytes = await File(localFilePath).readAsBytes();
      final filePath = '$userId/$interactionId.m4a';

      await SupabaseConfig.client.storage.from(_voiceNotesBucket).uploadBinary(
        filePath,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'audio/mp4',
          upsert: true,
        ),
      );

      return SupabaseConfig.client.storage
          .from(_voiceNotesBucket)
          .getPublicUrl(filePath);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a voice note from storage.
  Future<void> deleteVoiceNote(String userId, String interactionId) async {
    try {
      await SupabaseConfig.client.storage
          .from(_voiceNotesBucket)
          .remove(['$userId/$interactionId.m4a']);
    } catch (e) {
      rethrow;
    }
  }

  /// Pick image from gallery or camera
  /// Applies compression: max 1920px, 85% quality
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      return image;
    } catch (e) {
      return null;
    }
  }

  /// Pick image with platform-aware handling
  /// On web, only gallery is available
  Future<XFile?> pickImageWithDialog() async {
    return pickImage(source: ImageSource.gallery);
  }
}
