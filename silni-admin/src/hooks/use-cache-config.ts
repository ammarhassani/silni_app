"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import { toast } from "sonner";

export interface CacheConfig {
  id: string;
  service_key: string;
  cache_duration_seconds: number;
  description: string | null;
  description_ar: string | null;
  min_duration_seconds: number;
  max_duration_seconds: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

// Service display names
export const serviceLabels: Record<string, string> = {
  feature_config: "الميزات والاشتراكات",
  ai_config: "الذكاء الاصطناعي",
  gamification_config: "نظام النقاط",
  notification_config: "الإشعارات",
  design_config: "التصميم",
  content_config: "المحتوى",
  app_routes_config: "مسارات التطبيق",
};

// Fetch all cache configs
export function useCacheConfigs() {
  const supabase = createClient();

  return useQuery({
    queryKey: ["admin", "cache-config"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_cache_config")
        .select("*")
        .order("service_key");

      if (error) throw error;
      return data as CacheConfig[];
    },
  });
}

// Update cache config
export function useUpdateCacheConfig() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async ({
      id,
      cache_duration_seconds,
      is_active,
    }: {
      id: string;
      cache_duration_seconds?: number;
      is_active?: boolean;
    }) => {
      const updates: Partial<CacheConfig> = {};
      if (cache_duration_seconds !== undefined) {
        updates.cache_duration_seconds = cache_duration_seconds;
      }
      if (is_active !== undefined) {
        updates.is_active = is_active;
      }

      const { data, error } = await supabase
        .from("admin_cache_config")
        .update(updates)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as CacheConfig;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "cache-config"] });
      toast.success("تم تحديث إعدادات التخزين المؤقت");
    },
    onError: (error) => {
      toast.error(`فشل في التحديث: ${error.message}`);
    },
  });
}

// Bulk update cache configs
export function useBulkUpdateCacheConfig() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async (
      updates: Array<{ id: string; cache_duration_seconds: number }>
    ) => {
      const results = await Promise.all(
        updates.map(async ({ id, cache_duration_seconds }) => {
          const { data, error } = await supabase
            .from("admin_cache_config")
            .update({ cache_duration_seconds })
            .eq("id", id)
            .select()
            .single();

          if (error) throw error;
          return data;
        })
      );
      return results;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "cache-config"] });
      toast.success("تم تحديث جميع إعدادات التخزين المؤقت");
    },
    onError: (error) => {
      toast.error(`فشل في التحديث: ${error.message}`);
    },
  });
}

// Reset to defaults
export function useResetCacheDefaults() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  const defaults: Record<string, number> = {
    feature_config: 300,
    ai_config: 300,
    gamification_config: 300,
    notification_config: 600,
    design_config: 600,
    content_config: 600,
    app_routes_config: 600,
  };

  return useMutation({
    mutationFn: async () => {
      const updates = Object.entries(defaults).map(async ([key, duration]) => {
        const { error } = await supabase
          .from("admin_cache_config")
          .update({ cache_duration_seconds: duration })
          .eq("service_key", key);

        if (error) throw error;
      });

      await Promise.all(updates);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "cache-config"] });
      toast.success("تم إعادة الضبط للقيم الافتراضية");
    },
    onError: (error) => {
      toast.error(`فشل في إعادة الضبط: ${error.message}`);
    },
  });
}

// Format duration for display
export function formatDuration(seconds: number): string {
  if (seconds < 60) {
    return `${seconds} ثانية`;
  } else if (seconds < 3600) {
    const minutes = Math.floor(seconds / 60);
    return `${minutes} دقيقة`;
  } else {
    const hours = Math.floor(seconds / 3600);
    return `${hours} ساعة`;
  }
}
