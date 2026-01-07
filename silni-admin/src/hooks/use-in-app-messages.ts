"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import { toast } from "sonner";

export interface InAppMessage {
  id: string;
  name: string;
  name_ar: string | null;
  message_type: "banner" | "modal" | "bottom_sheet" | "tooltip" | "full_screen" | "motd";
  title_ar: string;
  title_en: string | null;
  body_ar: string | null;
  body_en: string | null;
  cta_text_ar: string | null;
  cta_text_en: string | null;
  cta_action: string | null;
  cta_action_type: "route" | "url" | "action" | "none" | null;
  image_url: string | null;
  icon_name: string | null;
  // Enhanced graphics system
  graphic_type: "icon" | "lottie" | "illustration" | "emoji";
  lottie_name: string | null;
  illustration_url: string | null;
  icon_style: "default" | "filled" | "outlined" | "gradient";
  // Color mode: theme = adapts to user's theme, custom = uses configured colors
  color_mode: "theme" | "custom";
  background_color: string;
  text_color: string;
  accent_color: string | null;
  background_gradient: { start: string; end: string } | null;
  trigger_type: "screen_view" | "event" | "app_open" | "scheduled" | "segment" | "position";
  trigger_value: string | null;
  display_frequency: "once" | "once_per_session" | "daily" | "weekly" | "always";
  max_impressions: number | null;
  delay_seconds: number;
  start_date: string | null;
  end_date: string | null;
  target_tiers: string[];
  target_platforms: string[];
  target_user_segment: string | null;
  min_app_version: string | null;
  priority: number;
  is_active: boolean;
  is_dismissible: boolean;
  impressions: number;
  clicks: number;
  created_at: string;
  updated_at: string;
}

export interface MessageStats {
  total_impressions: number;
  unique_users: number;
  clicks: number;
  dismissals: number;
  click_rate: number;
}

export type InAppMessageInput = Omit<InAppMessage, "id" | "created_at" | "updated_at"> & {
  impressions?: number;
  clicks?: number;
};

// Message type labels
export const messageTypeLabels: Record<string, string> = {
  banner: "بانر",
  modal: "نافذة منبثقة",
  bottom_sheet: "شريط سفلي",
  tooltip: "تلميح",
  full_screen: "ملء الشاشة",
  motd: "رسالة اليوم",
};

// Trigger type labels
export const triggerTypeLabels: Record<string, string> = {
  screen_view: "عرض شاشة",
  event: "حدث",
  app_open: "فتح التطبيق",
  scheduled: "مجدول",
  segment: "شريحة مستخدمين",
  position: "موضع في الشاشة",
};

// Position labels for banner positions
export const positionLabels: Record<string, string> = {
  home_top: "أعلى الرئيسية",
  home_bottom: "أسفل الرئيسية",
  profile: "الملف الشخصي",
  reminders: "التذكيرات",
};

// CTA action type labels
export const ctaActionTypeLabels: Record<string, string> = {
  route: "مسار داخلي",
  url: "رابط خارجي",
  action: "إجراء خاص",
  none: "بدون إجراء",
};

// Display frequency labels
export const frequencyLabels: Record<string, string> = {
  once: "مرة واحدة",
  once_per_session: "مرة لكل جلسة",
  daily: "يومياً",
  weekly: "أسبوعياً",
  always: "دائماً",
};

// Segment labels
export const segmentLabels: Record<string, string> = {
  new: "مستخدمون جدد",
  active: "مستخدمون نشطون",
  inactive: "مستخدمون غير نشطين",
  churned: "مستخدمون متراجعون",
  streak_at_risk: "سلسلة في خطر",
};

// Graphic type labels
export const graphicTypeLabels: Record<string, string> = {
  icon: "أيقونة SVG",
  lottie: "رسوم متحركة",
  illustration: "صورة توضيحية",
  emoji: "إيموجي (قديم)",
};

// Icon style labels
export const iconStyleLabels: Record<string, string> = {
  default: "افتراضي",
  filled: "معبأ",
  outlined: "محاط",
  gradient: "متدرج",
};

// Color mode labels
export const colorModeLabels: Record<string, string> = {
  theme: "متوافق مع الثيم",
  custom: "ألوان مخصصة",
};

// Available Lucide icons for messages
export const availableIcons = [
  { value: "bell", label: "جرس", category: "notification" },
  { value: "megaphone", label: "مكبر صوت", category: "notification" },
  { value: "alert", label: "تنبيه", category: "notification" },
  { value: "info", label: "معلومات", category: "notification" },
  { value: "star", label: "نجمة", category: "celebration" },
  { value: "sparkles", label: "بريق", category: "celebration" },
  { value: "party", label: "احتفال", category: "celebration" },
  { value: "gift", label: "هدية", category: "celebration" },
  { value: "trophy", label: "كأس", category: "celebration" },
  { value: "crown", label: "تاج", category: "action" },
  { value: "rocket", label: "صاروخ", category: "action" },
  { value: "zap", label: "برق", category: "action" },
  { value: "fire", label: "نار", category: "action" },
  { value: "heart", label: "قلب", category: "engagement" },
  { value: "users", label: "مستخدمين", category: "engagement" },
  { value: "tree", label: "شجرة", category: "engagement" },
  { value: "check", label: "صح", category: "system" },
  { value: "warning", label: "تحذير", category: "system" },
  { value: "tip", label: "نصيحة", category: "system" },
  { value: "moon", label: "قمر", category: "time" },
  { value: "sun", label: "شمس", category: "time" },
];

// Available Lottie animations
export const availableLotties = [
  { value: "celebration", label: "احتفال (كونفيتي)" },
  { value: "success", label: "نجاح (علامة صح)" },
  { value: "gift", label: "هدية (فتح)" },
  { value: "levelup", label: "ارتقاء مستوى" },
  { value: "moon", label: "قمر متوهج" },
  { value: "sparkle", label: "بريق لامع" },
];

// Fetch all messages with optional filters
export function useInAppMessages(filters?: {
  messageType?: string;
  triggerType?: string;
  isActive?: boolean;
}) {
  const supabase = createClient();

  return useQuery({
    queryKey: ["admin", "in-app-messages", filters],
    queryFn: async () => {
      let query = supabase
        .from("admin_in_app_messages")
        .select("*")
        .order("priority", { ascending: false });

      if (filters?.messageType && filters.messageType !== "all") {
        query = query.eq("message_type", filters.messageType);
      }
      if (filters?.triggerType && filters.triggerType !== "all") {
        query = query.eq("trigger_type", filters.triggerType);
      }
      if (filters?.isActive !== undefined) {
        query = query.eq("is_active", filters.isActive);
      }

      const { data, error } = await query;

      if (error) throw error;
      return data as InAppMessage[];
    },
  });
}

// Fetch message stats
export function useMessageStats(messageId: string) {
  const supabase = createClient();

  return useQuery({
    queryKey: ["admin", "in-app-messages", "stats", messageId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("user_message_impressions")
        .select("*")
        .eq("message_id", messageId);

      if (error) throw error;

      const impressions = data || [];
      const totalImpressions = impressions.reduce((sum, i) => sum + i.impression_count, 0);
      const clicks = impressions.filter((i) => i.clicked).length;
      const dismissals = impressions.filter((i) => i.dismissed).length;

      return {
        total_impressions: totalImpressions,
        unique_users: impressions.length,
        clicks,
        dismissals,
        click_rate: impressions.length > 0 ? (clicks / impressions.length) * 100 : 0,
      } as MessageStats;
    },
    enabled: !!messageId,
  });
}

// Create message
export function useCreateInAppMessage() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async (message: InAppMessageInput) => {
      const { data, error } = await supabase
        .from("admin_in_app_messages")
        .insert(message)
        .select()
        .single();

      if (error) throw error;
      return data as InAppMessage;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "in-app-messages"] });
      toast.success("تم إنشاء الرسالة بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في الإنشاء: ${error.message}`);
    },
  });
}

// Update message
export function useUpdateInAppMessage() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async ({
      id,
      ...message
    }: Partial<InAppMessage> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_in_app_messages")
        .update(message)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as InAppMessage;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "in-app-messages"] });
      toast.success("تم تحديث الرسالة بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في التحديث: ${error.message}`);
    },
  });
}

// Delete message
export function useDeleteInAppMessage() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from("admin_in_app_messages")
        .delete()
        .eq("id", id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "in-app-messages"] });
      toast.success("تم حذف الرسالة بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في الحذف: ${error.message}`);
    },
  });
}

// Toggle active status
export function useToggleInAppMessageActive() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async ({ id, is_active }: { id: string; is_active: boolean }) => {
      const { data, error } = await supabase
        .from("admin_in_app_messages")
        .update({ is_active })
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as InAppMessage;
    },
    onSuccess: (_, { is_active }) => {
      queryClient.invalidateQueries({ queryKey: ["admin", "in-app-messages"] });
      toast.success(is_active ? "تم تفعيل الرسالة" : "تم تعطيل الرسالة");
    },
    onError: (error) => {
      toast.error(`فشل في التحديث: ${error.message}`);
    },
  });
}

// Reset message impressions - useful for testing
export function useResetMessageImpressions() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async (id: string) => {
      // Reset counters on the message
      const { error: updateError } = await supabase
        .from("admin_in_app_messages")
        .update({ impressions: 0, clicks: 0 })
        .eq("id", id);

      if (updateError) throw updateError;

      // Delete impression records for this message
      const { error: deleteError } = await supabase
        .from("user_message_impressions")
        .delete()
        .eq("message_id", id);

      // Ignore delete error if table doesn't exist or no records
      if (deleteError && !deleteError.message.includes("does not exist")) {
        console.warn("Could not delete impressions:", deleteError.message);
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "in-app-messages"] });
      toast.success("تم إعادة تعيين الانطباعات");
    },
    onError: (error) => {
      toast.error(`فشل في إعادة التعيين: ${error.message}`);
    },
  });
}

// Duplicate message
export function useDuplicateInAppMessage() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async (message: InAppMessage) => {
      // Get current datetime and 30 days from now
      const now = new Date().toISOString();
      const endDate = new Date();
      endDate.setDate(endDate.getDate() + 30);

      const newMessage: InAppMessageInput = {
        name: `${message.name} (copy)`,
        name_ar: message.name_ar ? `${message.name_ar} (نسخة)` : null,
        message_type: message.message_type,
        title_ar: message.title_ar,
        title_en: message.title_en,
        body_ar: message.body_ar,
        body_en: message.body_en,
        cta_text_ar: message.cta_text_ar,
        cta_text_en: message.cta_text_en,
        cta_action: message.cta_action,
        cta_action_type: message.cta_action_type,
        image_url: message.image_url,
        icon_name: message.icon_name,
        // Enhanced graphics
        graphic_type: message.graphic_type,
        lottie_name: message.lottie_name,
        illustration_url: message.illustration_url,
        icon_style: message.icon_style,
        // Color mode
        color_mode: message.color_mode,
        background_color: message.background_color,
        text_color: message.text_color,
        accent_color: message.accent_color,
        background_gradient: message.background_gradient,
        trigger_type: message.trigger_type,
        trigger_value: message.trigger_value,
        display_frequency: message.display_frequency,
        max_impressions: message.max_impressions,
        delay_seconds: message.delay_seconds,
        start_date: now,
        end_date: endDate.toISOString(),
        target_tiers: message.target_tiers,
        target_platforms: message.target_platforms,
        target_user_segment: message.target_user_segment,
        min_app_version: message.min_app_version,
        priority: message.priority,
        is_active: false,
        is_dismissible: message.is_dismissible,
        impressions: 0,
        clicks: 0,
      };

      const { data, error } = await supabase
        .from("admin_in_app_messages")
        .insert(newMessage)
        .select()
        .single();

      if (error) throw error;
      return data as InAppMessage;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "in-app-messages"] });
      toast.success("تم نسخ الرسالة بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في النسخ: ${error.message}`);
    },
  });
}
