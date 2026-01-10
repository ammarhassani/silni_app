"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import { toast } from "sonner";

export interface AITouchPoint {
  id: string;
  screen_key: string;
  touch_point_key: string;
  name_ar: string;
  name_en: string | null;
  description_ar: string | null;
  is_enabled: boolean;
  prompt_template: string;
  context_fields: string[];
  display_config: Record<string, unknown>;
  cache_duration_seconds: number;
  priority: number;
  temperature: number;
  max_tokens: number;
  created_at: string;
  updated_at: string;
}

export type AITouchPointInput = Omit<AITouchPoint, "id" | "created_at" | "updated_at">;

// Screen options
export const screenOptions = [
  { value: "home", label: "الرئيسية", labelEn: "Home" },
  { value: "relative_detail", label: "تفاصيل القريب", labelEn: "Relative Detail" },
  { value: "reminders", label: "التذكيرات", labelEn: "Reminders" },
  { value: "gamification", label: "النقاط والإنجازات", labelEn: "Gamification" },
  { value: "interactions", label: "التفاعلات", labelEn: "Interactions" },
];

// Context field options
export const contextFieldOptions = [
  { value: "time", label: "الوقت" },
  { value: "streaks", label: "الشعلات" },
  { value: "health", label: "صحة العلاقات" },
  { value: "occasions", label: "المناسبات" },
  { value: "relatives", label: "الأقارب" },
  { value: "interactions", label: "التفاعلات" },
  { value: "memories", label: "الذكريات" },
  { value: "relative", label: "القريب المحدد" },
  { value: "patterns", label: "الأنماط" },
];

// Icon options
export const iconOptions = [
  { value: "hand-wave", label: "👋 تحية" },
  { value: "users", label: "👥 مستخدمين" },
  { value: "lightbulb", label: "💡 فكرة" },
  { value: "message-circle", label: "💬 رسالة" },
  { value: "heart-pulse", label: "❤️ صحة" },
  { value: "clock", label: "🕐 وقت" },
  { value: "repeat", label: "🔄 تكرار" },
  { value: "sparkles", label: "✨ سحر" },
  { value: "star", label: "⭐ نجمة" },
  { value: "zap", label: "⚡ سرعة" },
];

// Fetch all touch points
export function useAITouchPoints() {
  const supabase = createClient();

  return useQuery({
    queryKey: ["admin", "ai-touch-points"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_ai_touch_points")
        .select("*")
        .order("screen_key")
        .order("priority");

      if (error) throw error;
      return data as AITouchPoint[];
    },
  });
}

// Fetch touch points by screen
export function useAITouchPointsByScreen(screenKey: string) {
  const supabase = createClient();

  return useQuery({
    queryKey: ["admin", "ai-touch-points", "screen", screenKey],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_ai_touch_points")
        .select("*")
        .eq("screen_key", screenKey)
        .order("priority");

      if (error) throw error;
      return data as AITouchPoint[];
    },
    enabled: !!screenKey,
  });
}

// Create touch point
export function useCreateAITouchPoint() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async (input: AITouchPointInput) => {
      const { data, error } = await supabase
        .from("admin_ai_touch_points")
        .insert(input)
        .select()
        .single();

      if (error) throw error;
      return data as AITouchPoint;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "ai-touch-points"] });
      toast.success("تم إنشاء نقطة الذكاء الاصطناعي بنجاح");
    },
    onError: (error: Error) => {
      toast.error(`فشل في الإنشاء: ${error.message}`);
    },
  });
}

// Update touch point
export function useUpdateAITouchPoint() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async ({ id, ...input }: Partial<AITouchPointInput> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_ai_touch_points")
        .update(input)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as AITouchPoint;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "ai-touch-points"] });
      toast.success("تم تحديث نقطة الذكاء الاصطناعي بنجاح");
    },
    onError: (error: Error) => {
      toast.error(`فشل في التحديث: ${error.message}`);
    },
  });
}

// Delete touch point
export function useDeleteAITouchPoint() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from("admin_ai_touch_points")
        .delete()
        .eq("id", id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "ai-touch-points"] });
      toast.success("تم حذف نقطة الذكاء الاصطناعي بنجاح");
    },
    onError: (error: Error) => {
      toast.error(`فشل في الحذف: ${error.message}`);
    },
  });
}

// Toggle enabled status
export function useToggleAITouchPointEnabled() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async ({ id, is_enabled }: { id: string; is_enabled: boolean }) => {
      const { error } = await supabase
        .from("admin_ai_touch_points")
        .update({ is_enabled })
        .eq("id", id);

      if (error) throw error;
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ["admin", "ai-touch-points"] });
      toast.success(variables.is_enabled ? "تم تفعيل نقطة الذكاء الاصطناعي" : "تم تعطيل نقطة الذكاء الاصطناعي");
    },
    onError: (error: Error) => {
      toast.error(`فشل في التبديل: ${error.message}`);
    },
  });
}

// AI generation stats
export interface AIGenerationStats {
  total_generations: number;
  today_generations: number;
  top_touch_points: { touch_point_key: string; count: number }[];
  avg_latency_ms: number;
}

export function useAIGenerationStats() {
  const supabase = createClient();

  return useQuery({
    queryKey: ["admin", "ai-generation-stats"],
    queryFn: async () => {
      // Get total count
      const { count: total } = await supabase
        .from("ai_generations")
        .select("*", { count: "exact", head: true });

      // Get today's count
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const { count: todayCount } = await supabase
        .from("ai_generations")
        .select("*", { count: "exact", head: true })
        .gte("created_at", today.toISOString());

      // Get top touch points
      const { data: topData } = await supabase
        .from("ai_generations")
        .select("touch_point_key")
        .limit(1000);

      const touchPointCounts: Record<string, number> = {};
      topData?.forEach((row) => {
        touchPointCounts[row.touch_point_key] = (touchPointCounts[row.touch_point_key] || 0) + 1;
      });

      const top_touch_points = Object.entries(touchPointCounts)
        .map(([key, count]) => ({ touch_point_key: key, count }))
        .sort((a, b) => b.count - a.count)
        .slice(0, 5);

      // Get average latency
      const { data: latencyData } = await supabase
        .from("ai_generations")
        .select("latency_ms")
        .not("latency_ms", "is", null)
        .limit(100);

      const avgLatency = latencyData?.length
        ? latencyData.reduce((sum, row) => sum + (row.latency_ms || 0), 0) / latencyData.length
        : 0;

      return {
        total_generations: total || 0,
        today_generations: todayCount || 0,
        top_touch_points,
        avg_latency_ms: Math.round(avgLatency),
      } as AIGenerationStats;
    },
  });
}
