"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import { toast } from "sonner";

// Types matching database enums
export type AuditActionType =
  | "create"
  | "update"
  | "delete"
  | "view"
  | "export"
  | "send"
  | "login"
  | "logout"
  | "other";

export type AuditResourceType =
  | "hadith"
  | "quote"
  | "motd"
  | "banner"
  | "ai_identity"
  | "ai_personality"
  | "ai_mode"
  | "ai_parameter"
  | "ai_memory"
  | "ai_occasion"
  | "ai_tone"
  | "ai_prompt"
  | "ai_streaming"
  | "ai_error"
  | "ai_scenario"
  | "badge"
  | "level"
  | "challenge"
  | "points_config"
  | "streak_config"
  | "subscription_tier"
  | "subscription_product"
  | "feature"
  | "trial_config"
  | "notification_template"
  | "reminder_slot"
  | "announcement"
  | "color"
  | "theme"
  | "animation"
  | "pattern_animation"
  | "app_route"
  | "route_category"
  | "api_key"
  | "user"
  | "admin"
  | "system"
  | "other";

export interface AuditLogEntry {
  id: string;
  admin_id: string;
  admin_email: string;
  action: AuditActionType;
  resource_type: AuditResourceType;
  resource_id: string | null;
  resource_name: string | null;
  description: string | null;
  changes: Record<string, unknown> | null;
  metadata: Record<string, unknown> | null;
  ip_address: string | null;
  user_agent: string | null;
  created_at: string;
}

export interface AuditLogFilters {
  action?: AuditActionType;
  resource_type?: AuditResourceType;
  admin_email?: string;
  from_date?: string;
  to_date?: string;
  search?: string;
  limit?: number;
  offset?: number;
}

// Labels for display
export const actionLabels: Record<AuditActionType, string> = {
  create: "إنشاء",
  update: "تحديث",
  delete: "حذف",
  view: "عرض",
  export: "تصدير",
  send: "إرسال",
  login: "تسجيل دخول",
  logout: "تسجيل خروج",
  other: "أخرى",
};

export const actionColors: Record<AuditActionType, string> = {
  create: "bg-green-500/10 text-green-600 border-green-500/20",
  update: "bg-blue-500/10 text-blue-600 border-blue-500/20",
  delete: "bg-red-500/10 text-red-600 border-red-500/20",
  view: "bg-gray-500/10 text-gray-600 border-gray-500/20",
  export: "bg-purple-500/10 text-purple-600 border-purple-500/20",
  send: "bg-orange-500/10 text-orange-600 border-orange-500/20",
  login: "bg-emerald-500/10 text-emerald-600 border-emerald-500/20",
  logout: "bg-slate-500/10 text-slate-600 border-slate-500/20",
  other: "bg-gray-500/10 text-gray-600 border-gray-500/20",
};

export const resourceLabels: Record<AuditResourceType, string> = {
  hadith: "حديث",
  quote: "اقتباس",
  motd: "رسالة اليوم",
  banner: "بانر",
  ai_identity: "هوية الذكاء",
  ai_personality: "شخصية الذكاء",
  ai_mode: "وضع الذكاء",
  ai_parameter: "معلمات الذكاء",
  ai_memory: "ذاكرة الذكاء",
  ai_occasion: "مناسبة",
  ai_tone: "نبرة",
  ai_prompt: "موجه",
  ai_streaming: "البث",
  ai_error: "رسالة خطأ",
  ai_scenario: "سيناريو",
  badge: "وسام",
  level: "مستوى",
  challenge: "تحدي",
  points_config: "إعدادات النقاط",
  streak_config: "إعدادات السلسلة",
  subscription_tier: "باقة اشتراك",
  subscription_product: "منتج اشتراك",
  feature: "ميزة",
  trial_config: "إعدادات التجربة",
  notification_template: "قالب إشعار",
  reminder_slot: "فترة تذكير",
  announcement: "إعلان",
  color: "لون",
  theme: "ثيم",
  animation: "حركة",
  pattern_animation: "نمط حركي",
  app_route: "مسار",
  route_category: "تصنيف مسار",
  api_key: "مفتاح API",
  user: "مستخدم",
  admin: "مشرف",
  system: "النظام",
  other: "أخرى",
};

// Fetch audit logs with filters
export function useAuditLogs(filters: AuditLogFilters = {}) {
  const supabase = createClient();

  return useQuery({
    queryKey: ["audit-logs", filters],
    queryFn: async () => {
      let query = supabase
        .from("admin_audit_log")
        .select("*")
        .order("created_at", { ascending: false });

      if (filters.action) {
        query = query.eq("action", filters.action);
      }
      if (filters.resource_type) {
        query = query.eq("resource_type", filters.resource_type);
      }
      if (filters.admin_email) {
        query = query.ilike("admin_email", `%${filters.admin_email}%`);
      }
      if (filters.from_date) {
        query = query.gte("created_at", filters.from_date);
      }
      if (filters.to_date) {
        query = query.lte("created_at", filters.to_date);
      }
      if (filters.search) {
        query = query.or(
          `description.ilike.%${filters.search}%,resource_name.ilike.%${filters.search}%`
        );
      }
      if (filters.limit) {
        query = query.limit(filters.limit);
      }
      if (filters.offset) {
        query = query.range(filters.offset, filters.offset + (filters.limit || 50) - 1);
      } else {
        query = query.limit(filters.limit || 100);
      }

      const { data, error } = await query;
      if (error) throw error;
      return data as AuditLogEntry[];
    },
    staleTime: 30 * 1000, // 30 seconds
    refetchInterval: 60 * 1000, // Refresh every minute
  });
}

// Get audit stats
export function useAuditStats() {
  const supabase = createClient();

  return useQuery({
    queryKey: ["audit-stats"],
    queryFn: async () => {
      const now = new Date();
      const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString();
      const weekStart = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString();

      // Get counts
      const [totalResult, todayResult, weekResult, byActionResult] = await Promise.all([
        supabase.from("admin_audit_log").select("id", { count: "exact", head: true }),
        supabase
          .from("admin_audit_log")
          .select("id", { count: "exact", head: true })
          .gte("created_at", todayStart),
        supabase
          .from("admin_audit_log")
          .select("id", { count: "exact", head: true })
          .gte("created_at", weekStart),
        supabase
          .from("admin_audit_log")
          .select("action")
          .gte("created_at", weekStart),
      ]);

      // Count by action type
      const actionCounts: Record<string, number> = {};
      byActionResult.data?.forEach((row) => {
        actionCounts[row.action] = (actionCounts[row.action] || 0) + 1;
      });

      return {
        total: totalResult.count || 0,
        today: todayResult.count || 0,
        thisWeek: weekResult.count || 0,
        byAction: actionCounts,
      };
    },
    staleTime: 60 * 1000,
  });
}

// Log an action
export function useLogAction() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async (params: {
      action: AuditActionType;
      resource_type: AuditResourceType;
      resource_id?: string;
      resource_name?: string;
      description?: string;
      changes?: Record<string, unknown>;
      metadata?: Record<string, unknown>;
    }) => {
      const { data, error } = await supabase.rpc("log_admin_action", {
        p_action: params.action,
        p_resource_type: params.resource_type,
        p_resource_id: params.resource_id || null,
        p_resource_name: params.resource_name || null,
        p_description: params.description || null,
        p_changes: params.changes || null,
        p_metadata: params.metadata || null,
      });

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["audit-logs"] });
      queryClient.invalidateQueries({ queryKey: ["audit-stats"] });
    },
    onError: (error) => {
      console.error("Failed to log action:", error);
      // Don't show error to user - audit logging should be silent
    },
  });
}

// Get recent activity for a specific resource
export function useResourceActivity(resourceType: AuditResourceType, resourceId: string) {
  const supabase = createClient();

  return useQuery({
    queryKey: ["resource-activity", resourceType, resourceId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_audit_log")
        .select("*")
        .eq("resource_type", resourceType)
        .eq("resource_id", resourceId)
        .order("created_at", { ascending: false })
        .limit(20);

      if (error) throw error;
      return data as AuditLogEntry[];
    },
    enabled: !!resourceId,
  });
}

// Get recent activity for an admin
export function useAdminActivity(adminEmail: string) {
  const supabase = createClient();

  return useQuery({
    queryKey: ["admin-activity", adminEmail],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_audit_log")
        .select("*")
        .eq("admin_email", adminEmail)
        .order("created_at", { ascending: false })
        .limit(50);

      if (error) throw error;
      return data as AuditLogEntry[];
    },
    enabled: !!adminEmail,
  });
}
