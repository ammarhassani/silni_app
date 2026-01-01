"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import type {
  AdminPointsConfig,
  AdminBadge,
  AdminLevel,
  AdminChallenge,
  AdminStreakConfig,
} from "@/types/database";
import { toast } from "sonner";

const supabase = createClient();

// ============ Points Config ============

export function usePointsConfig() {
  return useQuery({
    queryKey: ["admin", "points-config"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_points_config")
        .select("*")
        .order("interaction_type");

      if (error) throw error;
      return data as AdminPointsConfig[];
    },
  });
}

export function useUpdatePointsConfig() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...config }: Partial<AdminPointsConfig> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_points_config")
        .update(config)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as AdminPointsConfig;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "points-config"] });
      toast.success("تم تحديث إعدادات النقاط");
    },
    onError: (error) => {
      toast.error(`فشل التحديث: ${error.message}`);
    },
  });
}

// ============ Badges ============

export function useBadges() {
  return useQuery({
    queryKey: ["admin", "badges"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_badges")
        .select("*")
        .order("sort_order");

      if (error) throw error;
      return data as AdminBadge[];
    },
  });
}

export function useCreateBadge() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (badge: Omit<AdminBadge, "id" | "created_at" | "updated_at">) => {
      const { data, error } = await supabase
        .from("admin_badges")
        .insert(badge)
        .select()
        .single();

      if (error) throw error;
      return data as AdminBadge;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "badges"] });
      toast.success("تم إضافة الوسام");
    },
    onError: (error) => {
      toast.error(`فشل الإضافة: ${error.message}`);
    },
  });
}

export function useUpdateBadge() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...badge }: Partial<AdminBadge> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_badges")
        .update(badge)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as AdminBadge;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "badges"] });
      toast.success("تم تحديث الوسام");
    },
    onError: (error) => {
      toast.error(`فشل التحديث: ${error.message}`);
    },
  });
}

export function useDeleteBadge() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase.from("admin_badges").delete().eq("id", id);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "badges"] });
      toast.success("تم حذف الوسام");
    },
    onError: (error) => {
      toast.error(`فشل الحذف: ${error.message}`);
    },
  });
}

// ============ Levels ============

export function useLevels() {
  return useQuery({
    queryKey: ["admin", "levels"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_levels")
        .select("*")
        .order("level");

      if (error) throw error;
      return data as AdminLevel[];
    },
  });
}

export function useUpdateLevel() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...level }: Partial<AdminLevel> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_levels")
        .update(level)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as AdminLevel;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "levels"] });
      toast.success("تم تحديث المستوى");
    },
    onError: (error) => {
      toast.error(`فشل التحديث: ${error.message}`);
    },
  });
}

// ============ Challenges ============

export function useChallenges() {
  return useQuery({
    queryKey: ["admin", "challenges"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_challenges")
        .select("*")
        .order("sort_order");

      if (error) throw error;
      return data as AdminChallenge[];
    },
  });
}

export function useCreateChallenge() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (challenge: Omit<AdminChallenge, "id" | "created_at" | "updated_at">) => {
      const { data, error } = await supabase
        .from("admin_challenges")
        .insert(challenge)
        .select()
        .single();

      if (error) throw error;
      return data as AdminChallenge;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "challenges"] });
      toast.success("تم إضافة التحدي");
    },
    onError: (error) => {
      toast.error(`فشل الإضافة: ${error.message}`);
    },
  });
}

export function useUpdateChallenge() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...challenge }: Partial<AdminChallenge> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_challenges")
        .update(challenge)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as AdminChallenge;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "challenges"] });
      toast.success("تم تحديث التحدي");
    },
    onError: (error) => {
      toast.error(`فشل التحديث: ${error.message}`);
    },
  });
}

// ============ Streak Config ============

export function useStreakConfig() {
  return useQuery({
    queryKey: ["admin", "streak-config"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_streak_config")
        .select("*")
        .single();

      if (error) throw error;
      return data as AdminStreakConfig;
    },
  });
}

export function useUpdateStreakConfig() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (config: Partial<AdminStreakConfig>) => {
      const { data, error } = await supabase
        .from("admin_streak_config")
        .update(config)
        .eq("config_key", "default")
        .select()
        .single();

      if (error) throw error;
      return data as AdminStreakConfig;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "streak-config"] });
      toast.success("تم تحديث إعدادات السلسلة");
    },
    onError: (error) => {
      toast.error(`فشل التحديث: ${error.message}`);
    },
  });
}
