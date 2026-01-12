"use client";

import { useState, useCallback } from "react";
import { createClient } from "@/lib/supabase/client";
import { toast } from "sonner";

interface UploadOptions {
  bucket?: string;
  folder?: string;
  maxSizeMB?: number;
}

interface UseStorageReturn {
  uploadImage: (file: File, options?: UploadOptions) => Promise<string | null>;
  deleteImage: (url: string, bucket?: string) => Promise<boolean>;
  isUploading: boolean;
  uploadProgress: number;
  error: string | null;
}

const VALID_IMAGE_TYPES = ["image/jpeg", "image/png", "image/gif", "image/webp"];

export function useStorage(): UseStorageReturn {
  const [isUploading, setIsUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [error, setError] = useState<string | null>(null);

  const supabase = createClient();

  const uploadImage = useCallback(
    async (
      file: File,
      options: UploadOptions = {}
    ): Promise<string | null> => {
      const {
        bucket = "message-images",
        folder = "uploads",
        maxSizeMB = 2,
      } = options;

      // Validate file size
      if (file.size > maxSizeMB * 1024 * 1024) {
        const errorMsg = `حجم الملف يجب أن يكون أقل من ${maxSizeMB} ميجابايت`;
        setError(errorMsg);
        toast.error(errorMsg);
        return null;
      }

      // Validate file type
      if (!VALID_IMAGE_TYPES.includes(file.type)) {
        const errorMsg = "نوع الملف غير مدعوم. استخدم JPEG, PNG, GIF, أو WebP";
        setError(errorMsg);
        toast.error(errorMsg);
        return null;
      }

      setIsUploading(true);
      setUploadProgress(0);
      setError(null);

      try {
        // Generate unique filename
        const extension = file.name.split(".").pop() || "jpg";
        const filename = `${folder}/${Date.now()}-${crypto.randomUUID()}.${extension}`;

        // Upload to Supabase Storage
        const { data, error: uploadError } = await supabase.storage
          .from(bucket)
          .upload(filename, file, {
            cacheControl: "3600",
            upsert: false,
          });

        if (uploadError) throw uploadError;

        // Get public URL
        const { data: urlData } = supabase.storage
          .from(bucket)
          .getPublicUrl(data.path);

        setUploadProgress(100);
        toast.success("تم رفع الصورة بنجاح");
        return urlData.publicUrl;
      } catch (err) {
        const errorMsg =
          err instanceof Error ? err.message : "فشل في رفع الصورة";
        setError(errorMsg);
        toast.error(errorMsg);
        return null;
      } finally {
        setIsUploading(false);
      }
    },
    [supabase]
  );

  const deleteImage = useCallback(
    async (url: string, bucket = "message-images"): Promise<boolean> => {
      try {
        // Extract path from URL
        const urlObj = new URL(url);
        const pathMatch = urlObj.pathname.match(
          /\/storage\/v1\/object\/public\/[^/]+\/(.+)/
        );
        if (!pathMatch) return false;

        const { error } = await supabase.storage
          .from(bucket)
          .remove([pathMatch[1]]);

        if (error) throw error;
        toast.success("تم حذف الصورة");
        return true;
      } catch (err) {
        console.error("Failed to delete image:", err);
        toast.error("فشل في حذف الصورة");
        return false;
      }
    },
    [supabase]
  );

  return {
    uploadImage,
    deleteImage,
    isUploading,
    uploadProgress,
    error,
  };
}
