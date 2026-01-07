"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import { toast } from "sonner";

export interface UIString {
  id: string;
  string_key: string;
  category: string;
  value_ar: string;
  value_en: string | null;
  description: string | null;
  screen: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export type UIStringInput = Omit<UIString, "id" | "created_at" | "updated_at">;

// Category labels
export const categoryLabels: Record<string, string> = {
  general: "عام",
  buttons: "الأزرار",
  labels: "التسميات",
  messages: "الرسائل",
  errors: "الأخطاء",
  titles: "العناوين",
  placeholders: "النصوص التوضيحية",
  dialogs: "الحوارات",
  notifications: "الإشعارات",
  gamification: "التلعيب",
};

// Category colors
export const categoryColors: Record<string, string> = {
  general: "bg-gray-500",
  buttons: "bg-blue-500",
  labels: "bg-green-500",
  messages: "bg-amber-500",
  errors: "bg-red-500",
  titles: "bg-purple-500",
  placeholders: "bg-cyan-500",
  dialogs: "bg-indigo-500",
  notifications: "bg-orange-500",
  gamification: "bg-pink-500",
};

// Fetch all UI strings
export function useUIStrings() {
  const supabase = createClient();

  return useQuery({
    queryKey: ["admin", "ui-strings"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_ui_strings")
        .select("*")
        .order("category")
        .order("string_key");

      if (error) throw error;
      return data as UIString[];
    },
  });
}

// Fetch strings by category
export function useUIStringsByCategory(category: string) {
  const supabase = createClient();

  return useQuery({
    queryKey: ["admin", "ui-strings", "category", category],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_ui_strings")
        .select("*")
        .eq("category", category)
        .order("string_key");

      if (error) throw error;
      return data as UIString[];
    },
    enabled: !!category && category !== "all",
  });
}

// Create UI string
export function useCreateUIString() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async (str: UIStringInput) => {
      const { data, error } = await supabase
        .from("admin_ui_strings")
        .insert(str)
        .select()
        .single();

      if (error) throw error;
      return data as UIString;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "ui-strings"] });
      toast.success("تم إضافة النص بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في الإضافة: ${error.message}`);
    },
  });
}

// Update UI string
export function useUpdateUIString() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async ({
      id,
      ...str
    }: Partial<UIString> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_ui_strings")
        .update(str)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as UIString;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "ui-strings"] });
      toast.success("تم تحديث النص بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في التحديث: ${error.message}`);
    },
  });
}

// Delete UI string
export function useDeleteUIString() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from("admin_ui_strings")
        .delete()
        .eq("id", id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "ui-strings"] });
      toast.success("تم حذف النص بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في الحذف: ${error.message}`);
    },
  });
}

// Bulk update strings (for inline editing)
export function useBulkUpdateUIStrings() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async (
      updates: Array<{ id: string; value_ar: string; value_en?: string }>
    ) => {
      const results = await Promise.all(
        updates.map(async ({ id, value_ar, value_en }) => {
          const { data, error } = await supabase
            .from("admin_ui_strings")
            .update({ value_ar, value_en })
            .eq("id", id)
            .select()
            .single();

          if (error) throw error;
          return data;
        })
      );
      return results;
    },
    onSuccess: (_, updates) => {
      queryClient.invalidateQueries({ queryKey: ["admin", "ui-strings"] });
      toast.success(`تم تحديث ${updates.length} نص بنجاح`);
    },
    onError: (error) => {
      toast.error(`فشل في التحديث: ${error.message}`);
    },
  });
}

// Toggle active status
export function useToggleUIStringActive() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async ({ id, is_active }: { id: string; is_active: boolean }) => {
      const { data, error } = await supabase
        .from("admin_ui_strings")
        .update({ is_active })
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as UIString;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "ui-strings"] });
      toast.success("تم تحديث الحالة");
    },
    onError: (error) => {
      toast.error(`فشل في التحديث: ${error.message}`);
    },
  });
}

// Search strings
export function useSearchUIStrings(query: string) {
  const supabase = createClient();

  return useQuery({
    queryKey: ["admin", "ui-strings", "search", query],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_ui_strings")
        .select("*")
        .or(`string_key.ilike.%${query}%,value_ar.ilike.%${query}%,value_en.ilike.%${query}%`)
        .order("category")
        .order("string_key");

      if (error) throw error;
      return data as UIString[];
    },
    enabled: query.length >= 2,
  });
}
