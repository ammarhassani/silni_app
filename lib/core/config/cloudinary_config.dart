import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryConfig {
  CloudinaryConfig._();

  static String get cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME']!;
  static String get apiKey => dotenv.env['CLOUDINARY_API_KEY']!;
  static String get apiSecret => dotenv.env['CLOUDINARY_API_SECRET']!;
  static String get uploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET']!;

  /// Get Cloudinary upload URL
  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/upload';

  /// Get Cloudinary image URL with transformations
  static String getImageUrl(
    String publicId, {
    int? width,
    int? height,
    String? gravity,
    String? crop,
    String? quality,
  }) {
    final transformations = <String>[];

    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    if (gravity != null) transformations.add('g_$gravity');
    if (crop != null) transformations.add('c_$crop');
    if (quality != null) transformations.add('q_$quality');

    final transformation = transformations.isEmpty
        ? ''
        : '${transformations.join(',')}/';

    return 'https://res.cloudinary.com/$cloudName/image/upload/$transformation$publicId';
  }

  /// Get optimized thumbnail URL
  static String getThumbnailUrl(String publicId, {int size = 200}) {
    return getImageUrl(
      publicId,
      width: size,
      height: size,
      crop: 'fill',
      gravity: 'face',
      quality: 'auto',
    );
  }

  /// Get optimized full image URL
  static String getOptimizedUrl(String publicId) {
    return getImageUrl(
      publicId,
      width: 1200,
      quality: 'auto:good',
    );
  }
}
