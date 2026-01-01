"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import { toast } from "sonner";

const supabase = createClient();

// Types
export type KeyCategory = 'backend' | 'auth' | 'payments' | 'messaging' | 'ai' | 'monitoring' | 'storage' | 'signing' | 'other';
export type KeyEnvironment = 'all' | 'production' | 'staging' | 'development';
export type KeyUsageLocation = 'flutter_app' | 'admin_panel' | 'edge_functions' | 'ci_cd' | 'multiple';

export interface ApiKeyRecord {
  id: string;
  service_name: string;
  key_name: string;
  key_identifier: string | null;
  category: KeyCategory;
  environment: KeyEnvironment;
  usage_location: KeyUsageLocation;
  description_ar: string | null;
  description_en: string | null;
  purpose: string | null;
  config_file_path: string | null;
  config_variable_name: string | null;
  is_secret: boolean;
  is_obfuscated: boolean;
  exposure_level: string;
  source_url: string | null;
  source_path: string | null;
  rotation_guide: string | null;
  rotation_frequency: string | null;
  last_rotated_at: string | null;
  next_rotation_at: string | null;
  notes: string | null;
  dependencies: string[] | null;
  is_active: boolean;
  sort_order: number;
  created_at: string;
  updated_at: string;
}

// Fetch all API keys
export function useApiKeys() {
  return useQuery({
    queryKey: ["admin", "api-keys"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_api_keys_registry")
        .select("*")
        .order("sort_order");

      if (error) throw error;
      return data as ApiKeyRecord[];
    },
  });
}

// Fetch keys by category
export function useApiKeysByCategory(category: KeyCategory) {
  return useQuery({
    queryKey: ["admin", "api-keys", "category", category],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_api_keys_registry")
        .select("*")
        .eq("category", category)
        .order("sort_order");

      if (error) throw error;
      return data as ApiKeyRecord[];
    },
  });
}

// Fetch keys by service
export function useApiKeysByService(serviceName: string) {
  return useQuery({
    queryKey: ["admin", "api-keys", "service", serviceName],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_api_keys_registry")
        .select("*")
        .eq("service_name", serviceName)
        .order("sort_order");

      if (error) throw error;
      return data as ApiKeyRecord[];
    },
  });
}

// Fetch keys due for rotation
export function useKeysDueForRotation() {
  return useQuery({
    queryKey: ["admin", "api-keys", "due-rotation"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_api_keys_registry")
        .select("*")
        .not("next_rotation_at", "is", null)
        .lte("next_rotation_at", new Date().toISOString())
        .order("next_rotation_at");

      if (error) throw error;
      return data as ApiKeyRecord[];
    },
  });
}

// Create new API key record
export function useCreateApiKey() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (key: Omit<ApiKeyRecord, "id" | "created_at" | "updated_at">) => {
      const { data, error } = await supabase
        .from("admin_api_keys_registry")
        .insert(key)
        .select()
        .single();

      if (error) throw error;
      return data as ApiKeyRecord;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "api-keys"] });
      toast.success("تم إضافة المفتاح");
    },
    onError: (error) => {
      toast.error(`فشل الإضافة: ${error.message}`);
    },
  });
}

// Update API key record
export function useUpdateApiKey() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...key }: Partial<ApiKeyRecord> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_api_keys_registry")
        .update(key)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as ApiKeyRecord;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "api-keys"] });
      toast.success("تم تحديث المفتاح");
    },
    onError: (error) => {
      toast.error(`فشل التحديث: ${error.message}`);
    },
  });
}

// Mark key as rotated
export function useMarkKeyRotated() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, nextRotationDays }: { id: string; nextRotationDays?: number }) => {
      const now = new Date();
      const nextRotation = nextRotationDays
        ? new Date(now.getTime() + nextRotationDays * 24 * 60 * 60 * 1000)
        : null;

      const { data, error } = await supabase
        .from("admin_api_keys_registry")
        .update({
          last_rotated_at: now.toISOString(),
          next_rotation_at: nextRotation?.toISOString() || null,
        })
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as ApiKeyRecord;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "api-keys"] });
      toast.success("تم تسجيل تدوير المفتاح");
    },
    onError: (error) => {
      toast.error(`فشل التحديث: ${error.message}`);
    },
  });
}

// Delete API key record
export function useDeleteApiKey() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from("admin_api_keys_registry")
        .delete()
        .eq("id", id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "api-keys"] });
      toast.success("تم حذف المفتاح");
    },
    onError: (error) => {
      toast.error(`فشل الحذف: ${error.message}`);
    },
  });
}

// Helper: Get category label
export function getCategoryLabel(category: KeyCategory): string {
  const labels: Record<KeyCategory, string> = {
    backend: "البنية التحتية",
    auth: "المصادقة",
    payments: "المدفوعات",
    messaging: "الرسائل والإشعارات",
    ai: "الذكاء الاصطناعي",
    monitoring: "المراقبة",
    storage: "التخزين",
    signing: "توقيع التطبيقات",
    other: "أخرى",
  };
  return labels[category];
}

// Helper: Get category icon
export function getCategoryIcon(category: KeyCategory): string {
  const icons: Record<KeyCategory, string> = {
    backend: "🗄️",
    auth: "🔐",
    payments: "💳",
    messaging: "📱",
    ai: "🤖",
    monitoring: "📊",
    storage: "☁️",
    signing: "🔏",
    other: "🔑",
  };
  return icons[category];
}

// Helper: Get environment label
export function getEnvironmentLabel(env: KeyEnvironment): string {
  const labels: Record<KeyEnvironment, string> = {
    all: "جميع البيئات",
    production: "الإنتاج",
    staging: "التجربة",
    development: "التطوير",
  };
  return labels[env];
}

// Helper: Get usage location label
export function getUsageLocationLabel(location: KeyUsageLocation): string {
  const labels: Record<KeyUsageLocation, string> = {
    flutter_app: "تطبيق Flutter",
    admin_panel: "لوحة الإدارة",
    edge_functions: "Edge Functions",
    ci_cd: "CI/CD",
    multiple: "متعدد",
  };
  return labels[location];
}
