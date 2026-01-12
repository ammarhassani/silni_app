"use client";

import * as React from "react";
import { useState, useRef, useCallback, useEffect } from "react";
import { Upload, Link, X, ImageIcon, Loader2 } from "lucide-react";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { cn } from "@/lib/utils";
import { useStorage } from "@/hooks/use-storage";

interface ImageUploaderProps {
  value: string | null;
  onChange: (url: string | null) => void;
  width?: number | null;
  height?: number | null;
  onDimensionChange?: (width: number | null, height: number | null) => void;
  label?: string;
  description?: string;
  folder?: string;
  disabled?: boolean;
  className?: string;
}

export function ImageUploader({
  value,
  onChange,
  width,
  height,
  onDimensionChange,
  label,
  description,
  folder = "uploads",
  disabled = false,
  className,
}: ImageUploaderProps) {
  const [urlInput, setUrlInput] = useState("");
  const [isDragOver, setIsDragOver] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const { uploadImage, isUploading } = useStorage();

  // Sync URL input with value
  useEffect(() => {
    if (value && !value.includes("supabase")) {
      setUrlInput(value);
    }
  }, [value]);

  const detectDimensions = useCallback(
    (url: string) => {
      if (!onDimensionChange) return;

      const img = new Image();
      img.onload = () => {
        onDimensionChange(img.naturalWidth, img.naturalHeight);
      };
      img.onerror = () => {
        // Keep existing dimensions on error
      };
      img.src = url;
    },
    [onDimensionChange]
  );

  const handleFileSelect = useCallback(
    async (file: File) => {
      if (disabled) return;

      // Detect dimensions from file before upload
      const objectUrl = URL.createObjectURL(file);
      detectDimensions(objectUrl);

      const url = await uploadImage(file, { folder });
      if (url) {
        onChange(url);
      }

      URL.revokeObjectURL(objectUrl);
    },
    [disabled, uploadImage, folder, onChange, detectDimensions]
  );

  const handleDrop = useCallback(
    (e: React.DragEvent) => {
      e.preventDefault();
      setIsDragOver(false);

      const file = e.dataTransfer.files[0];
      if (file && file.type.startsWith("image/")) {
        handleFileSelect(file);
      }
    },
    [handleFileSelect]
  );

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(true);
  }, []);

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(false);
  }, []);

  const handleFileInputChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const file = e.target.files?.[0];
      if (file) {
        handleFileSelect(file);
      }
    },
    [handleFileSelect]
  );

  const handleUrlSubmit = useCallback(() => {
    if (urlInput.trim()) {
      onChange(urlInput.trim());
      detectDimensions(urlInput.trim());
    }
  }, [urlInput, onChange, detectDimensions]);

  const handleClear = useCallback(() => {
    onChange(null);
    setUrlInput("");
    if (onDimensionChange) {
      onDimensionChange(null, null);
    }
    if (fileInputRef.current) {
      fileInputRef.current.value = "";
    }
  }, [onChange, onDimensionChange]);

  const handleDimensionChange = useCallback(
    (type: "width" | "height", val: string) => {
      if (!onDimensionChange) return;
      const num = val === "" ? null : parseInt(val, 10);
      if (type === "width") {
        onDimensionChange(num, height ?? null);
      } else {
        onDimensionChange(width ?? null, num);
      }
    },
    [onDimensionChange, width, height]
  );

  return (
    <div className={cn("space-y-2", className)}>
      {label && <Label className="text-sm">{label}</Label>}

      {value ? (
        // Image preview
        <div className="space-y-2">
          <div className="relative w-full h-32 bg-muted rounded-lg overflow-hidden border">
            <img
              src={value}
              alt=""
              className="w-full h-full object-contain"
            />
            <button
              type="button"
              className="absolute top-2 right-2 h-8 w-8 z-10 bg-red-500 hover:bg-red-600 rounded-full flex items-center justify-center shadow-md"
              onClick={(e) => {
                e.preventDefault();
                e.stopPropagation();
                handleClear();
              }}
              disabled={disabled}
            >
              <X className="h-4 w-4 text-white" />
            </button>
          </div>

          {/* Dimension inputs */}
          {onDimensionChange && (
            <div className="flex gap-2 items-center">
              <div className="flex-1 space-y-1">
                <Label className="text-xs text-muted-foreground">العرض</Label>
                <Input
                  type="number"
                  value={width ?? ""}
                  onChange={(e) => handleDimensionChange("width", e.target.value)}
                  placeholder="auto"
                  className="h-8"
                  disabled={disabled}
                />
              </div>
              <span className="text-muted-foreground mt-5">×</span>
              <div className="flex-1 space-y-1">
                <Label className="text-xs text-muted-foreground">الارتفاع</Label>
                <Input
                  type="number"
                  value={height ?? ""}
                  onChange={(e) => handleDimensionChange("height", e.target.value)}
                  placeholder="auto"
                  className="h-8"
                  disabled={disabled}
                />
              </div>
            </div>
          )}
        </div>
      ) : (
        // Upload/URL tabs
        <Tabs defaultValue="upload" className="w-full">
          <TabsList className="w-full">
            <TabsTrigger value="upload" className="flex-1 gap-1">
              <Upload className="h-3 w-3" />
              رفع
            </TabsTrigger>
            <TabsTrigger value="url" className="flex-1 gap-1">
              <Link className="h-3 w-3" />
              رابط
            </TabsTrigger>
          </TabsList>

          <TabsContent value="upload">
            <div
              className={cn(
                "border-2 border-dashed rounded-lg p-4 text-center cursor-pointer transition-colors",
                isDragOver
                  ? "border-primary bg-primary/5"
                  : "border-muted-foreground/25 hover:border-primary/50",
                disabled && "opacity-50 cursor-not-allowed"
              )}
              onDrop={handleDrop}
              onDragOver={handleDragOver}
              onDragLeave={handleDragLeave}
              onClick={() => !disabled && fileInputRef.current?.click()}
            >
              <input
                ref={fileInputRef}
                type="file"
                accept="image/jpeg,image/png,image/gif,image/webp"
                className="hidden"
                onChange={handleFileInputChange}
                disabled={disabled}
              />

              {isUploading ? (
                <div className="flex flex-col items-center gap-2 py-2">
                  <Loader2 className="h-6 w-6 animate-spin text-primary" />
                  <span className="text-sm text-muted-foreground">
                    جاري الرفع...
                  </span>
                </div>
              ) : (
                <div className="flex flex-col items-center gap-2 py-2">
                  <ImageIcon className="h-6 w-6 text-muted-foreground" />
                  <span className="text-sm text-muted-foreground">
                    اسحب صورة أو انقر للاختيار
                  </span>
                </div>
              )}
            </div>
          </TabsContent>

          <TabsContent value="url">
            <div className="flex gap-2">
              <Input
                value={urlInput}
                onChange={(e) => setUrlInput(e.target.value)}
                placeholder="https://..."
                disabled={disabled}
                onKeyDown={(e) => e.key === "Enter" && handleUrlSubmit()}
              />
              <Button
                type="button"
                size="sm"
                onClick={handleUrlSubmit}
                disabled={disabled || !urlInput.trim()}
              >
                إضافة
              </Button>
            </div>
          </TabsContent>
        </Tabs>
      )}

      {description && (
        <p className="text-xs text-muted-foreground">{description}</p>
      )}
    </div>
  );
}
