"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import type { AdminNotificationTemplate, AdminReminderTimeSlot } from "@/types/database";
import { toast } from "sonner";

const supabase = createClient();

// ============ Notification Templates ============

export function useNotificationTemplates() {
  return useQuery({
    queryKey: ["admin", "notification-templates"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_notification_templates")
        .select("*")
        .order("category", { ascending: true })
        .order("template_key", { ascending: true });

      if (error) throw error;
      return data as AdminNotificationTemplate[];
    },
  });
}

export function useCreateNotificationTemplate() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (
      template: Omit<AdminNotificationTemplate, "id" | "created_at" | "updated_at">
    ) => {
      const { data, error } = await supabase
        .from("admin_notification_templates")
        .insert(template)
        .select()
        .single();

      if (error) throw error;
      return data as AdminNotificationTemplate;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "notification-templates"] });
      toast.success("تم إضافة القالب");
    },
    onError: (error) => {
      toast.error(`فشل الإضافة: ${error.message}`);
    },
  });
}

export function useUpdateNotificationTemplate() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      id,
      ...template
    }: Partial<AdminNotificationTemplate> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_notification_templates")
        .update(template)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as AdminNotificationTemplate;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "notification-templates"] });
      toast.success("تم تحديث القالب");
    },
    onError: (error) => {
      toast.error(`فشل التحديث: ${error.message}`);
    },
  });
}

export function useDeleteNotificationTemplate() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from("admin_notification_templates")
        .delete()
        .eq("id", id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "notification-templates"] });
      toast.success("تم حذف القالب");
    },
    onError: (error) => {
      toast.error(`فشل الحذف: ${error.message}`);
    },
  });
}

// ============ Reminder Time Slots ============

export function useReminderTimeSlots() {
  return useQuery({
    queryKey: ["admin", "reminder-time-slots"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_reminder_time_slots")
        .select("*")
        .order("sort_order");

      if (error) throw error;
      return data as AdminReminderTimeSlot[];
    },
  });
}

export function useCreateReminderTimeSlot() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (
      slot: Omit<AdminReminderTimeSlot, "id" | "created_at" | "updated_at">
    ) => {
      const { data, error } = await supabase
        .from("admin_reminder_time_slots")
        .insert(slot)
        .select()
        .single();

      if (error) throw error;
      return data as AdminReminderTimeSlot;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "reminder-time-slots"] });
      toast.success("تم إضافة الفترة الزمنية");
    },
    onError: (error) => {
      toast.error(`فشل الإضافة: ${error.message}`);
    },
  });
}

export function useUpdateReminderTimeSlot() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      id,
      ...slot
    }: Partial<AdminReminderTimeSlot> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_reminder_time_slots")
        .update(slot)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as AdminReminderTimeSlot;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "reminder-time-slots"] });
      toast.success("تم تحديث الفترة الزمنية");
    },
    onError: (error) => {
      toast.error(`فشل التحديث: ${error.message}`);
    },
  });
}

export function useDeleteReminderTimeSlot() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from("admin_reminder_time_slots")
        .delete()
        .eq("id", id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "reminder-time-slots"] });
      toast.success("تم حذف الفترة الزمنية");
    },
    onError: (error) => {
      toast.error(`فشل الحذف: ${error.message}`);
    },
  });
}
