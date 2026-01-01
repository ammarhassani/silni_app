"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import { toast } from "sonner";

export type AnnouncementStatus = "draft" | "scheduled" | "sending" | "sent" | "failed";
export type AnnouncementTarget = "all" | "active" | "premium" | "inactive" | "custom";

export interface Announcement {
  id: string;
  title_ar: string;
  title_en: string | null;
  body_ar: string;
  body_en: string | null;
  deep_link: string | null;
  deep_link_params: Record<string, unknown>;
  target_users: AnnouncementTarget;  // Note: DB column is target_users
  custom_user_ids: string[];
  status: AnnouncementStatus;
  scheduled_for: string | null;
  notification_icon: string;
  notification_sound: string;
  priority: string;
  total_recipients: number;
  successful_sends: number;
  failed_sends: number;
  sent_at: string | null;
  sent_by: string | null;
  created_at: string;
  updated_at: string;
  created_by: string | null;
}

export type CreateAnnouncementInput = {
  title_ar: string;
  title_en?: string;
  body_ar: string;
  body_en?: string;
  deep_link?: string;
  deep_link_params?: Record<string, unknown>;
  target_users?: AnnouncementTarget;  // Note: DB column is target_users
  custom_user_ids?: string[];
  scheduled_for?: string;
  notification_icon?: string;
  notification_sound?: string;
  priority?: string;
};

export type UpdateAnnouncementInput = Partial<CreateAnnouncementInput> & {
  status?: AnnouncementStatus;
};

// Fetch all announcements
export function useAnnouncements() {
  const supabase = createClient();

  return useQuery({
    queryKey: ["announcements"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_announcements")
        .select("*")
        .order("created_at", { ascending: false });

      if (error) throw error;
      return data as Announcement[];
    },
  });
}

// Create announcement
export function useCreateAnnouncement() {
  const supabase = createClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: CreateAnnouncementInput) => {
      const { data: { user } } = await supabase.auth.getUser();

      const { data, error } = await supabase
        .from("admin_announcements")
        .insert({
          ...input,
          status: input.scheduled_for ? "scheduled" : "draft",
          created_by: user?.id,
        })
        .select()
        .single();

      if (error) throw error;
      return data as Announcement;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["announcements"] });
      toast.success("تم إنشاء الإشعار بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في إنشاء الإشعار: ${error.message}`);
    },
  });
}

// Update announcement
export function useUpdateAnnouncement() {
  const supabase = createClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...input }: UpdateAnnouncementInput & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_announcements")
        .update(input)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as Announcement;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["announcements"] });
      toast.success("تم تحديث الإشعار بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في تحديث الإشعار: ${error.message}`);
    },
  });
}

// Delete announcement
export function useDeleteAnnouncement() {
  const supabase = createClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from("admin_announcements")
        .delete()
        .eq("id", id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["announcements"] });
      toast.success("تم حذف الإشعار بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في حذف الإشعار: ${error.message}`);
    },
  });
}

// Send announcement immediately
export function useSendAnnouncement() {
  const supabase = createClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      // Call the edge function to send
      const { data, error } = await supabase.functions.invoke("send-announcement", {
        body: { announcementId: id },
      });

      if (error) throw error;
      return data;
    },
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: ["announcements"] });
      if (data?.success) {
        toast.success(`تم إرسال الإشعار إلى ${data.successCount} مستخدم`);
      } else {
        toast.warning(data?.message || "تم إرسال الإشعار مع بعض الأخطاء");
      }
    },
    onError: (error) => {
      toast.error(`فشل في إرسال الإشعار: ${error.message}`);
    },
  });
}

// Get announcement stats
export function useAnnouncementStats() {
  const supabase = createClient();

  return useQuery({
    queryKey: ["announcement-stats"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_announcements")
        .select("status, total_recipients, successful_sends, failed_sends");

      if (error) throw error;

      const stats = {
        total: data.length,
        draft: data.filter((a) => a.status === "draft").length,
        scheduled: data.filter((a) => a.status === "scheduled").length,
        sent: data.filter((a) => a.status === "sent").length,
        failed: data.filter((a) => a.status === "failed").length,
        totalRecipients: data.reduce((sum, a) => sum + (a.total_recipients || 0), 0),
        totalSuccessful: data.reduce((sum, a) => sum + (a.successful_sends || 0), 0),
      };

      return stats;
    },
  });
}

// Helper functions
export const STATUS_LABELS: Record<AnnouncementStatus, string> = {
  draft: "مسودة",
  scheduled: "مجدول",
  sending: "جاري الإرسال",
  sent: "تم الإرسال",
  failed: "فشل",
};

export const TARGET_LABELS: Record<AnnouncementTarget, string> = {
  all: "جميع المستخدمين",
  active: "المستخدمين النشطين",
  premium: "المشتركين المميزين",
  inactive: "المستخدمين غير النشطين",
  custom: "مستخدمين محددين",
};

export const STATUS_COLORS: Record<AnnouncementStatus, string> = {
  draft: "bg-gray-100 text-gray-700",
  scheduled: "bg-blue-100 text-blue-700",
  sending: "bg-yellow-100 text-yellow-700",
  sent: "bg-green-100 text-green-700",
  failed: "bg-red-100 text-red-700",
};
