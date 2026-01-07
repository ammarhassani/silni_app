"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import { toast } from "sonner";

export interface FeatureFlag {
  id: string;
  flag_key: string;
  name: string;
  name_ar: string;
  description: string | null;
  description_ar: string | null;
  flag_type: "boolean" | "string" | "number" | "json";
  default_value: unknown;
  enabled_value: unknown;
  rollout_percentage: number;
  target_tiers: string[];
  target_platforms: string[];
  category: "feature" | "ui" | "experiment" | "performance";
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export type FeatureFlagInput = Omit<FeatureFlag, "id" | "created_at" | "updated_at">;

// Category labels
export const categoryLabels: Record<string, string> = {
  feature: "ميزات",
  ui: "واجهة المستخدم",
  experiment: "تجارب A/B",
  performance: "الأداء",
};

// Category colors
export const categoryColors: Record<string, string> = {
  feature: "bg-blue-500",
  ui: "bg-purple-500",
  experiment: "bg-amber-500",
  performance: "bg-green-500",
};

// Tier labels
export const tierLabels: Record<string, string> = {
  free: "مجاني",
  basic: "أساسي",
  pro: "احترافي",
  max: "ماكس",
};

// Platform labels
export const platformLabels: Record<string, string> = {
  ios: "iOS",
  android: "Android",
  web: "Web",
};

// Fetch all feature flags
export function useFeatureFlags() {
  const supabase = createClient();

  return useQuery({
    queryKey: ["admin", "feature-flags"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_feature_flags")
        .select("*")
        .order("category")
        .order("name");

      if (error) throw error;
      return data as FeatureFlag[];
    },
  });
}

// Fetch flags by category
export function useFeatureFlagsByCategory(category: string) {
  const supabase = createClient();

  return useQuery({
    queryKey: ["admin", "feature-flags", "category", category],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_feature_flags")
        .select("*")
        .eq("category", category)
        .order("name");

      if (error) throw error;
      return data as FeatureFlag[];
    },
    enabled: !!category,
  });
}

// Create feature flag
export function useCreateFeatureFlag() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async (flag: FeatureFlagInput) => {
      const { data, error } = await supabase
        .from("admin_feature_flags")
        .insert(flag)
        .select()
        .single();

      if (error) throw error;
      return data as FeatureFlag;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "feature-flags"] });
      toast.success("تم إنشاء العلم بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في إنشاء العلم: ${error.message}`);
    },
  });
}

// Update feature flag
export function useUpdateFeatureFlag() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async ({
      id,
      ...flag
    }: Partial<FeatureFlag> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_feature_flags")
        .update(flag)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as FeatureFlag;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "feature-flags"] });
      toast.success("تم تحديث العلم بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في تحديث العلم: ${error.message}`);
    },
  });
}

// Delete feature flag
export function useDeleteFeatureFlag() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from("admin_feature_flags")
        .delete()
        .eq("id", id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "feature-flags"] });
      toast.success("تم حذف العلم بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في حذف العلم: ${error.message}`);
    },
  });
}

// Toggle flag active status
export function useToggleFeatureFlag() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async ({ id, is_active }: { id: string; is_active: boolean }) => {
      const { data, error } = await supabase
        .from("admin_feature_flags")
        .update({ is_active })
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as FeatureFlag;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "feature-flags"] });
      toast.success("تم تحديث حالة العلم");
    },
    onError: (error) => {
      toast.error(`فشل في تحديث الحالة: ${error.message}`);
    },
  });
}

// Update rollout percentage
export function useUpdateRollout() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async ({
      id,
      rollout_percentage,
    }: {
      id: string;
      rollout_percentage: number;
    }) => {
      const { data, error } = await supabase
        .from("admin_feature_flags")
        .update({ rollout_percentage })
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as FeatureFlag;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "feature-flags"] });
      toast.success("تم تحديث نسبة الإطلاق");
    },
    onError: (error) => {
      toast.error(`فشل في التحديث: ${error.message}`);
    },
  });
}

// Utility to format flag value for display
export function formatFlagValue(value: unknown, type: string): string {
  if (type === "boolean") {
    return value === true || value === "true" ? "مفعّل" : "معطّل";
  }
  if (typeof value === "object") {
    return JSON.stringify(value);
  }
  return String(value);
}
