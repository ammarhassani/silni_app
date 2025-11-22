/**
 * STORAGE SERVICE
 *
 * Unified storage service that uses Cloudinary for all image uploads.
 * This service provides a consistent interface for uploading and managing images.
 *
 * Features:
 * - Profile pictures
 * - Relative photos
 * - Interaction photos
 * - Image optimization and transformations
 */

import { cloudinaryService, UploadResult, UploadOptions } from './cloudinaryService';

export interface StorageUploadResult {
  success: boolean;
  url?: string;
  publicId?: string;
  error?: string;
}

class StorageService {
  /**
   * Upload a user profile picture
   */
  async uploadProfilePicture(
    imageUri: string,
    userId: string
  ): Promise<StorageUploadResult> {
    try {
      console.log('📤 Uploading profile picture...');
      const result = await cloudinaryService.uploadProfilePicture(
        imageUri,
        userId
      );

      if (!result.success) {
        return {
          success: false,
          error: result.error || 'Upload failed',
        };
      }

      return {
        success: true,
        url: result.url,
        publicId: result.publicId,
      };
    } catch (error: any) {
      console.error('❌ Profile picture upload error:', error);
      return {
        success: false,
        error: error.message || 'Upload failed',
      };
    }
  }

  /**
   * Upload a relative's photo
   */
  async uploadRelativePhoto(
    imageUri: string,
    userId: string,
    relativeId: string
  ): Promise<StorageUploadResult> {
    try {
      console.log('📤 Uploading relative photo...');
      const result = await cloudinaryService.uploadRelativePhoto(
        imageUri,
        userId,
        relativeId
      );

      if (!result.success) {
        return {
          success: false,
          error: result.error || 'Upload failed',
        };
      }

      return {
        success: true,
        url: result.url,
        publicId: result.publicId,
      };
    } catch (error: any) {
      console.error('❌ Relative photo upload error:', error);
      return {
        success: false,
        error: error.message || 'Upload failed',
      };
    }
  }

  /**
   * Upload an interaction photo
   */
  async uploadInteractionPhoto(
    imageUri: string,
    userId: string,
    interactionId: string
  ): Promise<StorageUploadResult> {
    try {
      console.log('📤 Uploading interaction photo...');
      const result = await cloudinaryService.uploadInteractionPhoto(
        imageUri,
        userId,
        interactionId
      );

      if (!result.success) {
        return {
          success: false,
          error: result.error || 'Upload failed',
        };
      }

      return {
        success: true,
        url: result.url,
        publicId: result.publicId,
      };
    } catch (error: any) {
      console.error('❌ Interaction photo upload error:', error);
      return {
        success: false,
        error: error.message || 'Upload failed',
      };
    }
  }

  /**
   * Upload a generic image
   */
  async uploadImage(
    imageUri: string,
    options?: UploadOptions
  ): Promise<StorageUploadResult> {
    try {
      console.log('📤 Uploading image...');
      const result = await cloudinaryService.uploadImage(imageUri, options);

      if (!result.success) {
        return {
          success: false,
          error: result.error || 'Upload failed',
        };
      }

      return {
        success: true,
        url: result.url,
        publicId: result.publicId,
      };
    } catch (error: any) {
      console.error('❌ Image upload error:', error);
      return {
        success: false,
        error: error.message || 'Upload failed',
      };
    }
  }

  /**
   * Get optimized image URL
   */
  getOptimizedUrl(
    publicId: string,
    width: number = 400,
    height: number = 400
  ): string {
    return cloudinaryService.getOptimizedUrl(publicId, width, height);
  }

  /**
   * Get thumbnail URL
   */
  getThumbnailUrl(publicId: string): string {
    return cloudinaryService.getThumbnailUrl(publicId);
  }

  /**
   * Delete an image
   * Note: This requires server-side implementation
   */
  async deleteImage(publicId: string): Promise<boolean> {
    console.warn('⚠️ Image deletion should be handled server-side');
    // In production, this should call a Cloud Function
    return true;
  }

  /**
   * Validate image before upload
   */
  validateImage(fileSize: number, maxSizeKB: number = 5000): boolean {
    const fileSizeKB = fileSize / 1024;
    if (fileSizeKB > maxSizeKB) {
      console.error(
        `❌ File size (${fileSizeKB.toFixed(0)}KB) exceeds limit (${maxSizeKB}KB)`
      );
      return false;
    }
    return true;
  }
}

// Export singleton instance
export const storageService = new StorageService();

// Export convenience functions
export const uploadProfilePicture = (imageUri: string, userId: string) =>
  storageService.uploadProfilePicture(imageUri, userId);
export const uploadRelativePhoto = (
  imageUri: string,
  userId: string,
  relativeId: string
) => storageService.uploadRelativePhoto(imageUri, userId, relativeId);
export const uploadInteractionPhoto = (
  imageUri: string,
  userId: string,
  interactionId: string
) => storageService.uploadInteractionPhoto(imageUri, userId, interactionId);
export const getOptimizedUrl = (
  publicId: string,
  width?: number,
  height?: number
) => storageService.getOptimizedUrl(publicId, width, height);
export const getThumbnailUrl = (publicId: string) =>
  storageService.getThumbnailUrl(publicId);
