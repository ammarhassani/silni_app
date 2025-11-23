import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  // Use lazy getters to safely access dotenv with fallbacks for web
  String get _cloudName {
    try {
      return dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? 'dli79vqgg';
    } catch (e) {
      // If dotenv is not initialized (web), use hardcoded value
      return 'dli79vqgg';
    }
  }

  String get _uploadPreset {
    try {
      return dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? 'silni_unsigned';
    } catch (e) {
      // If dotenv is not initialized (web), use hardcoded value
      return 'silni_unsigned';
    }
  }

  final Dio _dio = Dio();

  /// Upload image to Cloudinary
  /// Returns the secure URL of the uploaded image
  Future<String> uploadImage(XFile imageFile) async {
    try {
      if (kDebugMode) {
        print('☁️ [CLOUDINARY] Starting upload...');
      }

      // Prepare form data
      FormData formData;

      if (kIsWeb) {
        // For web, use bytes
        final bytes = await imageFile.readAsBytes();
        formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            bytes,
            filename: imageFile.name,
          ),
          'upload_preset': _uploadPreset,
          'folder': 'silni/relatives',
        });
      } else {
        // For mobile, use file path
        formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.name,
          ),
          'upload_preset': _uploadPreset,
          'folder': 'silni/relatives',
        });
      }

      // Upload to Cloudinary
      final response = await _dio.post(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        final secureUrl = response.data['secure_url'] as String;

        if (kDebugMode) {
          print('✅ [CLOUDINARY] Upload successful!');
          print('📷 [CLOUDINARY] URL: $secureUrl');
        }

        return secureUrl;
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [CLOUDINARY] Upload error: $e');
      }
      rethrow;
    }
  }

  /// Upload profile picture with transformation
  Future<String> uploadProfilePicture(XFile imageFile) async {
    try {
      if (kDebugMode) {
        print('☁️ [CLOUDINARY] Uploading profile picture...');
      }

      // Prepare form data with transformation
      FormData formData;

      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            bytes,
            filename: imageFile.name,
          ),
          'upload_preset': _uploadPreset,
          'folder': 'silni/profiles',
          'transformation': 'c_fill,g_face,h_400,w_400',
        });
      } else {
        formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.name,
          ),
          'upload_preset': _uploadPreset,
          'folder': 'silni/profiles',
          'transformation': 'c_fill,g_face,h_400,w_400',
        });
      }

      final response = await _dio.post(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
        data: formData,
      );

      if (response.statusCode == 200) {
        final secureUrl = response.data['secure_url'] as String;

        if (kDebugMode) {
          print('✅ [CLOUDINARY] Profile picture uploaded!');
        }

        return secureUrl;
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [CLOUDINARY] Profile upload error: $e');
      }
      rethrow;
    }
  }

  /// Pick image from gallery or camera
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null && kDebugMode) {
        print('📸 [IMAGE_PICKER] Image selected: ${image.name}');
      }

      return image;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [IMAGE_PICKER] Error: $e');
      }
      return null;
    }
  }

  /// Show image source selection dialog
  Future<XFile?> pickImageWithDialog() async {
    // For web, only gallery is available
    if (kIsWeb) {
      return pickImage(source: ImageSource.gallery);
    }

    // For mobile, user can choose between camera and gallery
    // This would typically be shown in a dialog in the UI
    return pickImage(source: ImageSource.gallery);
  }
}
