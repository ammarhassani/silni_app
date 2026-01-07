"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import { toast } from "sonner";

export interface ReminderTemplate {
  id: string;
  template_key: string;
  frequency: 'daily' | 'weekly' | 'monthly' | 'friday' | 'custom';
  title_ar: string;
  title_en: string | null;
  description_ar: string;
  description_en: string | null;
  suggested_relationships_ar: string;
  suggested_relationships_en: string | null;
  default_time: string;
  emoji: string;
  sort_order: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export type ReminderTemplateInput = Omit<ReminderTemplate, "id" | "created_at" | "updated_at">;

// Frequency options
export const frequencyOptions = [
  { value: 'daily', label: 'يومي', emoji: '📅' },
  { value: 'weekly', label: 'أسبوعي', emoji: '📆' },
  { value: 'monthly', label: 'شهري', emoji: '📋' },
  { value: 'friday', label: 'جمعة', emoji: '🕌' },
  { value: 'custom', label: 'مخصص', emoji: '⚙️' },
] as const;

// Emoji options
export const templateEmojis = [
  { value: '📅', label: 'تقويم' },
  { value: '📆', label: 'تقويم أسبوعي' },
  { value: '📋', label: 'قائمة' },
  { value: '🕌', label: 'مسجد' },
  { value: '⚙️', label: 'إعدادات' },
  { value: '🔔', label: 'جرس' },
  { value: '⏰', label: 'منبه' },
  { value: '💫', label: 'نجمة' },
  { value: '❤️', label: 'قلب' },
  { value: '🌙', label: 'قمر' },
];

// Time presets
export const timePresets = [
  { value: '06:00', label: '6:00 صباحاً' },
  { value: '07:00', label: '7:00 صباحاً' },
  { value: '08:00', label: '8:00 صباحاً' },
  { value: '09:00', label: '9:00 صباحاً' },
  { value: '10:00', label: '10:00 صباحاً' },
  { value: '11:00', label: '11:00 صباحاً' },
  { value: '12:00', label: '12:00 ظهراً' },
  { value: '13:00', label: '1:00 مساءً' },
  { value: '14:00', label: '2:00 مساءً' },
  { value: '15:00', label: '3:00 مساءً' },
  { value: '16:00', label: '4:00 مساءً' },
  { value: '17:00', label: '5:00 مساءً' },
  { value: '18:00', label: '6:00 مساءً' },
  { value: '19:00', label: '7:00 مساءً' },
  { value: '20:00', label: '8:00 مساءً' },
  { value: '21:00', label: '9:00 مساءً' },
];

// Fetch all templates
export function useReminderTemplates() {
  const supabase = createClient();

  return useQuery({
    queryKey: ["admin", "reminder-templates"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_reminder_templates")
        .select("*")
        .order("sort_order", { ascending: true });

      if (error) throw error;
      return data as ReminderTemplate[];
    },
  });
}

// Create template
export function useCreateReminderTemplate() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async (template: ReminderTemplateInput) => {
      const { data, error } = await supabase
        .from("admin_reminder_templates")
        .insert(template)
        .select()
        .single();

      if (error) throw error;
      return data as ReminderTemplate;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "reminder-templates"] });
      toast.success("تم إنشاء القالب بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في إنشاء القالب: ${error.message}`);
    },
  });
}

// Update template
export function useUpdateReminderTemplate() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async ({ id, ...template }: Partial<ReminderTemplate> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_reminder_templates")
        .update(template)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as ReminderTemplate;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "reminder-templates"] });
      toast.success("تم تحديث القالب بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في تحديث القالب: ${error.message}`);
    },
  });
}

// Delete template
export function useDeleteReminderTemplate() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from("admin_reminder_templates")
        .delete()
        .eq("id", id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "reminder-templates"] });
      toast.success("تم حذف القالب بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في حذف القالب: ${error.message}`);
    },
  });
}

// Toggle template active status
export function useToggleReminderTemplateActive() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async ({ id, is_active }: { id: string; is_active: boolean }) => {
      const { data, error } = await supabase
        .from("admin_reminder_templates")
        .update({ is_active })
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as ReminderTemplate;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "reminder-templates"] });
      toast.success("تم تحديث حالة القالب");
    },
    onError: (error) => {
      toast.error(`فشل في تحديث الحالة: ${error.message}`);
    },
  });
}
