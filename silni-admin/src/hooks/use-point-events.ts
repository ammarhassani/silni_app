"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import { toast } from "sonner";

export interface PointEvent {
  id: string;
  name: string;
  name_ar: string;
  description: string | null;
  description_ar: string | null;
  multiplier: number;
  bonus_points: number;
  start_date: string;
  end_date: string;
  applies_to: string[];
  icon: string;
  color: string;
  banner_image_url: string | null;
  show_banner: boolean;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export type PointEventInput = Omit<PointEvent, "id" | "created_at" | "updated_at">;

// Action type labels
export const actionTypeLabels: Record<string, string> = {
  all: "جميع الإجراءات",
  streak: "المحافظة على السلسلة",
  connection: "تسجيل تواصل",
  first_connection: "أول تواصل مع قريب",
  reminder: "إتمام تذكير",
  badge_earned: "الحصول على شارة",
  level_up: "الترقية لمستوى جديد",
  challenge: "إتمام تحدي",
};

// Icon options
export const iconOptions = [
  { value: "gift", label: "هدية", emoji: "🎁" },
  { value: "moon", label: "قمر", emoji: "🌙" },
  { value: "star", label: "نجمة", emoji: "⭐" },
  { value: "fire", label: "نار", emoji: "🔥" },
  { value: "zap", label: "برق", emoji: "⚡" },
  { value: "trophy", label: "كأس", emoji: "🏆" },
  { value: "heart", label: "قلب", emoji: "❤️" },
  { value: "sparkles", label: "بريق", emoji: "✨" },
];

// Color presets
export const colorPresets = [
  { value: "#FFD700", label: "ذهبي" },
  { value: "#C9A227", label: "برونزي" },
  { value: "#4CAF50", label: "أخضر" },
  { value: "#2196F3", label: "أزرق" },
  { value: "#9C27B0", label: "بنفسجي" },
  { value: "#FF9800", label: "برتقالي" },
  { value: "#E91E63", label: "وردي" },
  { value: "#00BCD4", label: "سماوي" },
];

// Fetch all point events
export function usePointEvents() {
  const supabase = createClient();

  return useQuery({
    queryKey: ["admin", "point-events"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_point_events")
        .select("*")
        .order("start_date", { ascending: false });

      if (error) throw error;
      return data as PointEvent[];
    },
  });
}

// Fetch single point event
export function usePointEventById(id: string) {
  const supabase = createClient();

  return useQuery({
    queryKey: ["admin", "point-events", id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_point_events")
        .select("*")
        .eq("id", id)
        .single();

      if (error) throw error;
      return data as PointEvent;
    },
    enabled: !!id,
  });
}

// Fetch currently active event
export function useActivePointEvent() {
  const supabase = createClient();

  return useQuery({
    queryKey: ["admin", "point-events", "active"],
    queryFn: async () => {
      const now = new Date().toISOString();
      const { data, error } = await supabase
        .from("admin_point_events")
        .select("*")
        .eq("is_active", true)
        .lte("start_date", now)
        .gte("end_date", now)
        .order("multiplier", { ascending: false })
        .limit(1)
        .maybeSingle();

      if (error) throw error;
      return data as PointEvent | null;
    },
    refetchInterval: 60000, // Refresh every minute
  });
}

// Create point event
export function useCreatePointEvent() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async (event: PointEventInput) => {
      const { data, error } = await supabase
        .from("admin_point_events")
        .insert(event)
        .select()
        .single();

      if (error) throw error;
      return data as PointEvent;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "point-events"] });
      toast.success("تم إنشاء الحدث بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في إنشاء الحدث: ${error.message}`);
    },
  });
}

// Update point event
export function useUpdatePointEvent() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async ({
      id,
      ...event
    }: Partial<PointEvent> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_point_events")
        .update(event)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as PointEvent;
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ["admin", "point-events"] });
      queryClient.invalidateQueries({
        queryKey: ["admin", "point-events", variables.id],
      });
      toast.success("تم تحديث الحدث بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في تحديث الحدث: ${error.message}`);
    },
  });
}

// Delete point event
export function useDeletePointEvent() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from("admin_point_events")
        .delete()
        .eq("id", id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "point-events"] });
      toast.success("تم حذف الحدث بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في حذف الحدث: ${error.message}`);
    },
  });
}

// Toggle event active status
export function useTogglePointEventActive() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async ({ id, is_active }: { id: string; is_active: boolean }) => {
      const { data, error } = await supabase
        .from("admin_point_events")
        .update({ is_active })
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as PointEvent;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "point-events"] });
      toast.success("تم تحديث حالة الحدث");
    },
    onError: (error) => {
      toast.error(`فشل في تحديث الحالة: ${error.message}`);
    },
  });
}

// Utility functions
export function isEventActive(event: PointEvent): boolean {
  if (!event.is_active) return false;
  const now = new Date();
  const start = new Date(event.start_date);
  const end = new Date(event.end_date);
  return now >= start && now <= end;
}

export function isEventUpcoming(event: PointEvent): boolean {
  const now = new Date();
  const start = new Date(event.start_date);
  return now < start;
}

export function isEventPast(event: PointEvent): boolean {
  const now = new Date();
  const end = new Date(event.end_date);
  return now > end;
}

export function getEventStatus(event: PointEvent): "active" | "upcoming" | "past" | "disabled" {
  if (!event.is_active) return "disabled";
  if (isEventActive(event)) return "active";
  if (isEventUpcoming(event)) return "upcoming";
  return "past";
}

export function formatMultiplier(multiplier: number): string {
  return `×${multiplier.toFixed(1)}`;
}
