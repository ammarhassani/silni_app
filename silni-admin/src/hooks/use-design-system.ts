"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import type { AdminColor, AdminTheme, AdminPatternAnimation } from "@/types/database";
import { toast } from "sonner";

const supabase = createClient();

// ============ Colors ============

export function useColors() {
  return useQuery({
    queryKey: ["admin", "colors"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_colors")
        .select("*")
        .order("sort_order");

      if (error) throw error;
      return data as AdminColor[];
    },
  });
}

export function useCreateColor() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (color: Omit<AdminColor, "id" | "created_at" | "updated_at">) => {
      const { data, error } = await supabase
        .from("admin_colors")
        .insert(color)
        .select()
        .single();

      if (error) throw error;
      return data as AdminColor;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "colors"] });
      toast.success("تم إضافة اللون");
    },
    onError: (error) => {
      toast.error(`فشل الإضافة: ${error.message}`);
    },
  });
}

export function useUpdateColor() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...color }: Partial<AdminColor> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_colors")
        .update(color)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as AdminColor;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "colors"] });
      toast.success("تم تحديث اللون");
    },
    onError: (error) => {
      toast.error(`فشل التحديث: ${error.message}`);
    },
  });
}

export function useDeleteColor() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase.from("admin_colors").delete().eq("id", id);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "colors"] });
      toast.success("تم حذف اللون");
    },
    onError: (error) => {
      toast.error(`فشل الحذف: ${error.message}`);
    },
  });
}

// ============ Themes ============

export function useThemes() {
  return useQuery({
    queryKey: ["admin", "themes"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_themes")
        .select("*")
        .order("sort_order");

      if (error) throw error;
      return data as AdminTheme[];
    },
  });
}

export function useCreateTheme() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (theme: Omit<AdminTheme, "id" | "created_at" | "updated_at">) => {
      const { data, error } = await supabase
        .from("admin_themes")
        .insert(theme)
        .select()
        .single();

      if (error) throw error;
      return data as AdminTheme;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "themes"] });
      toast.success("تم إضافة الثيم");
    },
    onError: (error) => {
      toast.error(`فشل الإضافة: ${error.message}`);
    },
  });
}

export function useUpdateTheme() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...theme }: Partial<AdminTheme> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_themes")
        .update(theme)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as AdminTheme;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "themes"] });
      toast.success("تم تحديث الثيم");
    },
    onError: (error) => {
      toast.error(`فشل التحديث: ${error.message}`);
    },
  });
}

export function useDeleteTheme() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase.from("admin_themes").delete().eq("id", id);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "themes"] });
      toast.success("تم حذف الثيم");
    },
    onError: (error) => {
      toast.error(`فشل الحذف: ${error.message}`);
    },
  });
}

// ============ Pattern Animations ============

export function usePatternAnimations() {
  return useQuery({
    queryKey: ["admin", "pattern-animations"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_pattern_animations")
        .select("*")
        .order("sort_order");

      if (error) throw error;
      return data as AdminPatternAnimation[];
    },
  });
}

export function useUpdatePatternAnimation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      id,
      ...animation
    }: Partial<AdminPatternAnimation> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_pattern_animations")
        .update(animation)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as AdminPatternAnimation;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "pattern-animations"] });
      toast.success("تم تحديث التأثير");
    },
    onError: (error) => {
      toast.error(`فشل التحديث: ${error.message}`);
    },
  });
}

export function useCreatePatternAnimation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (
      animation: Omit<AdminPatternAnimation, "id" | "created_at" | "updated_at">
    ) => {
      const { data, error } = await supabase
        .from("admin_pattern_animations")
        .insert(animation)
        .select()
        .single();

      if (error) throw error;
      return data as AdminPatternAnimation;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "pattern-animations"] });
      toast.success("تم إضافة التأثير");
    },
    onError: (error) => {
      toast.error(`فشل الإضافة: ${error.message}`);
    },
  });
}
