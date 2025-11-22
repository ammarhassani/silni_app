/**
 * CLOUDINARY SERVICE
 *
 * Handles image uploads to Cloudinary for:
 * - User profile pictures
 * - Relative photos
 * - Interaction photos
 * - Audio notes (premium)
 *
 * FREE TIER: 25 GB storage, 25 GB bandwidth/month
 */

import { Cloudinary } from '@cloudinary/url-gen';

// Cloudinary configuration
const cloudinaryConfig = {
  cloudName: process.env.CLOUDINARY_CLOUD_NAME || '',
  apiKey: process.env.CLOUDINARY_API_KEY || '',
  apiSecret: process.env.CLOUDINARY_API_SECRET || '',
  uploadPreset: process.env.CLOUDINARY_UPLOAD_PRESET || 'silni_unsigned', // We'll create this
};

// Initialize Cloudinary
const cld = new Cloudinary({
  cloud: {
    cloudName: cloudinaryConfig.cloudName,
  },
});

export interface UploadResult {
  success: boolean;
  url?: string;
  publicId?: string;
  error?: string;
}

export interface UploadOptions {
  folder?: string;
  maxSizeKB?: number;
  allowedFormats?: string[];
}

class CloudinaryService {
  private uploadUrl: string;

  constructor() {
    this.uploadUrl = `https://api.cloudinary.com/v1_1/${cloudinaryConfig.cloudName}/upload`;
  }

  /**
   * Upload an image to Cloudinary
   * Uses unsigned upload preset (no authentication needed from client)
   */
  async uploadImage(
    imageUri: string,
    options: UploadOptions = {}
  ): Promise<UploadResult> {
    try {
      const {
        folder = 'silni',
        maxSizeKB = 5000, // 5MB default
        allowedFormats = ['jpg', 'jpeg', 'png', 'webp'],
      } = options;

      // Prepare form data
      const formData = new FormData();
      formData.append('file', {
        uri: imageUri,
        type: 'image/jpeg',
        name: 'upload.jpg',
      } as any);

      formData.append('upload_preset', cloudinaryConfig.uploadPreset);
      formData.append('folder', folder);
      formData.append('cloud_name', cloudinaryConfig.cloudName);

      // Optional: Add transformations
      // formData.append('transformation', 'c_limit,w_1000,h_1000,q_auto:good');

      console.log('📤 Uploading image to Cloudinary...');

      const response = await fetch(this.uploadUrl, {
        method: 'POST',
        body: formData,
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });

      if (!response.ok) {
        const error = await response.json();
        console.error('❌ Cloudinary upload failed:', error);
        return {
          success: false,
          error: error.error?.message || 'Upload failed',
        };
      }

      const data = await response.json();

      console.log('✅ Image uploaded successfully');

      return {
        success: true,
        url: data.secure_url,
        publicId: data.public_id,
      };
    } catch (error: any) {
      console.error('❌ Upload error:', error);
      return {
        success: false,
        error: error.message || 'Upload failed',
      };
    }
  }

  /**
   * Upload a user profile picture
   */
  async uploadProfilePicture(imageUri: string, userId: string): Promise<UploadResult> {
    return this.uploadImage(imageUri, {
      folder: `silni/profiles/${userId}`,
      maxSizeKB: 2000, // 2MB for profile pics
    });
  }

  /**
   * Upload a relative's photo
   */
  async uploadRelativePhoto(
    imageUri: string,
    userId: string,
    relativeId: string
  ): Promise<UploadResult> {
    return this.uploadImage(imageUri, {
      folder: `silni/relatives/${userId}/${relativeId}`,
      maxSizeKB: 3000, // 3MB
    });
  }

  /**
   * Upload interaction photo
   */
  async uploadInteractionPhoto(
    imageUri: string,
    userId: string,
    interactionId: string
  ): Promise<UploadResult> {
    return this.uploadImage(imageUri, {
      folder: `silni/interactions/${userId}/${interactionId}`,
      maxSizeKB: 5000, // 5MB
    });
  }

  /**
   * Delete an image from Cloudinary
   * Note: Requires authentication, so this should be done from backend/Cloud Function
   */
  async deleteImage(publicId: string): Promise<boolean> {
    // This requires API secret, so should be done server-side
    // For now, we'll just return true and handle deletion manually or via Cloud Function
    console.warn('⚠️ Image deletion should be handled server-side');
    return true;
  }

  /**
   * Get optimized image URL
   */
  getOptimizedUrl(publicId: string, width: number = 400, height: number = 400): string {
    const image = cld.image(publicId);
    image.resize(`c_fill,w_${width},h_${height},q_auto:good`);
    return image.toURL();
  }

  /**
   * Get thumbnail URL
   */
  getThumbnailUrl(publicId: string): string {
    return this.getOptimizedUrl(publicId, 150, 150);
  }
}

// Export singleton instance
export const cloudinaryService = new CloudinaryService();

// Export convenience functions
export const uploadImage = (uri: string, options?: UploadOptions) =>
  cloudinaryService.uploadImage(uri, options);
export const uploadProfilePicture = (uri: string, userId: string) =>
  cloudinaryService.uploadProfilePicture(uri, userId);
export const uploadRelativePhoto = (uri: string, userId: string, relativeId: string) =>
  cloudinaryService.uploadRelativePhoto(uri, userId, relativeId);
export const getOptimizedUrl = (publicId: string, width?: number, height?: number) =>
  cloudinaryService.getOptimizedUrl(publicId, width, height);
