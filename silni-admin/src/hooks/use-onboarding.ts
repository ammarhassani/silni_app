"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import { toast } from "sonner";

export interface OnboardingScreen {
  id: string;
  screen_order: number;
  title_ar: string;
  title_en: string | null;
  subtitle_ar: string | null;
  subtitle_en: string | null;
  image_url: string | null;
  animation_name: string | null;
  background_color: string;
  background_gradient_start: string | null;
  background_gradient_end: string | null;
  text_color: string;
  accent_color: string | null;
  button_text_ar: string;
  button_text_en: string | null;
  button_color: string | null;
  skip_enabled: boolean;
  auto_advance_seconds: number | null;
  show_for_tiers: string[];
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export type OnboardingScreenInput = Omit<
  OnboardingScreen,
  "id" | "created_at" | "updated_at"
>;

// Lottie animation options (must match assets in Flutter app)
export const animationOptions = [
  { value: "onboarding_welcome", label: "ترحيب" },
  { value: "onboarding_reminders", label: "التذكيرات" },
  { value: "onboarding_ai", label: "الذكاء الاصطناعي" },
  { value: "onboarding_gamification", label: "التلعيب" },
  { value: "onboarding_start", label: "البدء" },
  { value: "connection", label: "التواصل" },
  { value: "family", label: "العائلة" },
  { value: "notification", label: "الإشعارات" },
  { value: "celebration", label: "الاحتفال" },
];

// Tier options
export const tierOptions = [
  { value: "free", label: "مجاني" },
  { value: "max", label: "ماكس" },
];

// Fetch all onboarding screens
export function useOnboardingScreens() {
  const supabase = createClient();

  return useQuery({
    queryKey: ["admin", "onboarding"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_onboarding_screens")
        .select("*")
        .order("screen_order");

      if (error) throw error;
      return data as OnboardingScreen[];
    },
  });
}

// Create onboarding screen
export function useCreateOnboardingScreen() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async (screen: OnboardingScreenInput) => {
      const { data, error } = await supabase
        .from("admin_onboarding_screens")
        .insert(screen)
        .select()
        .single();

      if (error) throw error;
      return data as OnboardingScreen;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "onboarding"] });
      toast.success("تم إضافة الشاشة بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في الإضافة: ${error.message}`);
    },
  });
}

// Update onboarding screen
export function useUpdateOnboardingScreen() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async ({
      id,
      ...screen
    }: Partial<OnboardingScreen> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_onboarding_screens")
        .update(screen)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as OnboardingScreen;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "onboarding"] });
      toast.success("تم تحديث الشاشة بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في التحديث: ${error.message}`);
    },
  });
}

// Delete onboarding screen
export function useDeleteOnboardingScreen() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from("admin_onboarding_screens")
        .delete()
        .eq("id", id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "onboarding"] });
      toast.success("تم حذف الشاشة بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في الحذف: ${error.message}`);
    },
  });
}

// Reorder screens
export function useReorderOnboardingScreens() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async ({
      screenId,
      newOrder,
    }: {
      screenId: string;
      newOrder: number;
    }) => {
      const { error } = await supabase.rpc("reorder_onboarding_screens", {
        p_screen_id: screenId,
        p_new_order: newOrder,
      });

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "onboarding"] });
      toast.success("تم إعادة الترتيب بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في إعادة الترتيب: ${error.message}`);
    },
  });
}

// Toggle active status
export function useToggleOnboardingActive() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async ({ id, is_active }: { id: string; is_active: boolean }) => {
      const { data, error } = await supabase
        .from("admin_onboarding_screens")
        .update({ is_active })
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as OnboardingScreen;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "onboarding"] });
      toast.success("تم تحديث الحالة");
    },
    onError: (error) => {
      toast.error(`فشل في التحديث: ${error.message}`);
    },
  });
}

// Duplicate screen
export function useDuplicateOnboardingScreen() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async (screen: OnboardingScreen) => {
      // Get max order
      const { data: screens } = await supabase
        .from("admin_onboarding_screens")
        .select("screen_order")
        .order("screen_order", { ascending: false })
        .limit(1);

      const nextOrder = (screens?.[0]?.screen_order || 0) + 1;

      const newScreen: OnboardingScreenInput = {
        screen_order: nextOrder,
        title_ar: `${screen.title_ar} (نسخة)`,
        title_en: screen.title_en ? `${screen.title_en} (copy)` : null,
        subtitle_ar: screen.subtitle_ar,
        subtitle_en: screen.subtitle_en,
        image_url: screen.image_url,
        animation_name: screen.animation_name,
        background_color: screen.background_color,
        background_gradient_start: screen.background_gradient_start,
        background_gradient_end: screen.background_gradient_end,
        text_color: screen.text_color,
        accent_color: screen.accent_color,
        button_text_ar: screen.button_text_ar,
        button_text_en: screen.button_text_en,
        button_color: screen.button_color,
        skip_enabled: screen.skip_enabled,
        auto_advance_seconds: screen.auto_advance_seconds,
        show_for_tiers: screen.show_for_tiers,
        is_active: false, // Start as inactive
      };

      const { data, error } = await supabase
        .from("admin_onboarding_screens")
        .insert(newScreen)
        .select()
        .single();

      if (error) throw error;
      return data as OnboardingScreen;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "onboarding"] });
      toast.success("تم نسخ الشاشة بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في النسخ: ${error.message}`);
    },
  });
}
