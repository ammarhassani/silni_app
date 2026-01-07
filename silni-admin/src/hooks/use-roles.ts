"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import { toast } from "sonner";

// Types
export type AdminRoleType =
  | "super_admin"
  | "content_admin"
  | "ai_admin"
  | "marketing"
  | "support"
  | "viewer";

export interface AdminPermission {
  id: string;
  permission_key: string;
  display_name_ar: string;
  display_name_en: string | null;
  description_ar: string | null;
  category: string;
}

export interface RolePermission {
  id: string;
  role: AdminRoleType;
  permission_key: string;
}

export interface AdminUser {
  id: string;
  email: string;
  display_name: string | null;
  role: string;
  admin_role: AdminRoleType | null;
  created_at: string;
}

// Role labels in Arabic
export const roleLabels: Record<AdminRoleType, string> = {
  super_admin: "مسؤول كامل",
  content_admin: "مسؤول المحتوى",
  ai_admin: "مسؤول الذكاء الاصطناعي",
  marketing: "تسويق",
  support: "دعم",
  viewer: "مشاهد",
};

// Role descriptions
export const roleDescriptions: Record<AdminRoleType, string> = {
  super_admin: "صلاحيات كاملة على جميع أقسام لوحة التحكم",
  content_admin: "إدارة المحتوى (الأحاديث، الاقتباسات، رسالة اليوم، البانرات)",
  ai_admin: "إدارة إعدادات الذكاء الاصطناعي",
  marketing: "عرض التحليلات وإدارة الإشعارات والبانرات",
  support: "عرض المستخدمين ومحدودية في الإجراءات",
  viewer: "قراءة فقط في جميع الأقسام",
};

// Role colors for badges
export const roleColors: Record<AdminRoleType, string> = {
  super_admin: "destructive",
  content_admin: "default",
  ai_admin: "secondary",
  marketing: "default",
  support: "secondary",
  viewer: "outline",
};

// Permission category labels
export const categoryLabels: Record<string, string> = {
  content: "المحتوى",
  ai: "الذكاء الاصطناعي",
  users: "المستخدمون",
  notifications: "الإشعارات",
  design: "التصميم",
  subscriptions: "الاشتراكات",
  gamification: "التلعيب",
  analytics: "التحليلات",
  settings: "الإعدادات",
  admin: "إدارة النظام",
};

// Fetch all permissions
export function usePermissions() {
  const supabase = createClient();

  return useQuery({
    queryKey: ["permissions"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_permissions")
        .select("*")
        .order("category");

      if (error) throw error;
      return data as AdminPermission[];
    },
  });
}

// Fetch role permissions mapping
export function useRolePermissions() {
  const supabase = createClient();

  return useQuery({
    queryKey: ["role-permissions"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_role_permissions")
        .select("*");

      if (error) throw error;
      return data as RolePermission[];
    },
  });
}

// Fetch current user's permissions
export function useCurrentUserPermissions() {
  const supabase = createClient();

  return useQuery({
    queryKey: ["current-user-permissions"],
    queryFn: async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return [];

      const { data, error } = await supabase.rpc("get_user_permissions", {
        p_user_id: user.id,
      });

      if (error) {
        console.error("Error fetching permissions:", error);
        return [];
      }

      return (data as { permission_key: string }[]).map((p) => p.permission_key);
    },
    staleTime: 300000, // 5 minutes
  });
}

// Check if current user has permission
export function useHasPermission(permission: string) {
  const { data: permissions, isLoading } = useCurrentUserPermissions();
  return {
    hasPermission: permissions?.includes(permission) || false,
    isLoading,
  };
}

// Hook to check multiple permissions
export function useCanAccess(requiredPermissions: string[]) {
  const { data: permissions, isLoading } = useCurrentUserPermissions();

  if (isLoading || !permissions) {
    return { canAccess: false, isLoading: true };
  }

  const canAccess = requiredPermissions.every((p) => permissions.includes(p));
  return { canAccess, isLoading: false };
}

// Fetch admins with their roles
export function useAdmins() {
  const supabase = createClient();

  return useQuery({
    queryKey: ["admins"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("profiles")
        .select("id, email, display_name, role, admin_role, created_at")
        .eq("role", "admin")
        .order("created_at", { ascending: false });

      if (error) throw error;
      return data as AdminUser[];
    },
  });
}

// Update admin role
export function useUpdateAdminRole() {
  const supabase = createClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      userId,
      adminRole,
    }: {
      userId: string;
      adminRole: AdminRoleType;
    }) => {
      const { data, error } = await supabase
        .from("profiles")
        .update({ admin_role: adminRole })
        .eq("id", userId)
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admins"] });
      toast.success("تم تحديث صلاحية المسؤول");
    },
    onError: (error) => {
      toast.error("حدث خطأ أثناء تحديث الصلاحية");
      console.error(error);
    },
  });
}

// Promote user to admin
export function usePromoteToAdmin() {
  const supabase = createClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      userId,
      adminRole,
    }: {
      userId: string;
      adminRole: AdminRoleType;
    }) => {
      const { data, error } = await supabase
        .from("profiles")
        .update({ role: "admin", admin_role: adminRole })
        .eq("id", userId)
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admins"] });
      queryClient.invalidateQueries({ queryKey: ["users"] });
      toast.success("تم ترقية المستخدم إلى مسؤول");
    },
    onError: (error) => {
      toast.error("حدث خطأ أثناء الترقية");
      console.error(error);
    },
  });
}

// Demote admin to user
export function useDemoteAdmin() {
  const supabase = createClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (userId: string) => {
      const { data, error } = await supabase
        .from("profiles")
        .update({ role: "user", admin_role: null })
        .eq("id", userId)
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admins"] });
      queryClient.invalidateQueries({ queryKey: ["users"] });
      toast.success("تم إلغاء صلاحيات المسؤول");
    },
    onError: (error) => {
      toast.error("حدث خطأ أثناء إلغاء الصلاحيات");
      console.error(error);
    },
  });
}

// Get permissions for a role
export function useRolePermissionsList(role: AdminRoleType) {
  const supabase = createClient();

  return useQuery({
    queryKey: ["role-permissions", role],
    queryFn: async () => {
      const { data, error } = await supabase.rpc("get_role_permissions", {
        p_role: role,
      });

      if (error) throw error;
      return (data as { permission_key: string }[]).map((p) => p.permission_key);
    },
    enabled: !!role,
  });
}
