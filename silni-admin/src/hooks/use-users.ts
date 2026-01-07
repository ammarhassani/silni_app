"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";

// Types
export type UserRole = "user" | "admin" | "moderator";

export interface UserProfile {
  id: string;
  email: string | null;
  display_name: string | null;
  avatar_url: string | null;
  role: UserRole;
  created_at: string;
  updated_at: string;
}

export interface UserFilters {
  search?: string;
  role?: UserRole | "all";
  sortBy?: "created_at" | "updated_at" | "email" | "display_name";
  sortOrder?: "asc" | "desc";
  page?: number;
  pageSize?: number;
}

export interface UserStats {
  total_users: number;
  admins: number;
  moderators: number;
  users: number;
  new_today: number;
  new_this_week: number;
  new_this_month: number;
}

// Role labels in Arabic
export const roleLabels: Record<UserRole, string> = {
  user: "مستخدم",
  admin: "مسؤول",
  moderator: "مشرف",
};

// Role colors for badges
export const roleColors: Record<UserRole, string> = {
  user: "secondary",
  admin: "destructive",
  moderator: "default",
};

// Fetch users with filters
export function useUsers(filters: UserFilters = {}) {
  const supabase = createClient();
  const {
    search = "",
    role = "all",
    sortBy = "created_at",
    sortOrder = "desc",
    page = 1,
    pageSize = 20
  } = filters;

  return useQuery({
    queryKey: ["users", filters],
    queryFn: async () => {
      let query = supabase
        .from("profiles")
        .select("*", { count: "exact" });

      // Search filter
      if (search) {
        query = query.or(`email.ilike.%${search}%,display_name.ilike.%${search}%`);
      }

      // Role filter
      if (role !== "all") {
        query = query.eq("role", role);
      }

      // Sorting
      query = query.order(sortBy, { ascending: sortOrder === "asc" });

      // Pagination
      const from = (page - 1) * pageSize;
      const to = from + pageSize - 1;
      query = query.range(from, to);

      const { data, error, count } = await query;

      if (error) throw error;

      return {
        users: data as UserProfile[],
        total: count || 0,
        page,
        pageSize,
        totalPages: Math.ceil((count || 0) / pageSize),
      };
    },
  });
}

// Fetch single user
export function useUser(userId: string) {
  const supabase = createClient();

  return useQuery({
    queryKey: ["user", userId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("profiles")
        .select("*")
        .eq("id", userId)
        .single();

      if (error) throw error;
      return data as UserProfile;
    },
    enabled: !!userId,
  });
}

// Fetch user stats using admin function (bypasses RLS)
export function useUserStats() {
  const supabase = createClient();

  return useQuery({
    queryKey: ["user-stats"],
    queryFn: async () => {
      // First try the admin stats function (bypasses RLS)
      const { data: adminStats, error: adminError } = await supabase.rpc("get_admin_user_stats");

      if (!adminError && adminStats) {
        // Get time-based stats separately (these still need RLS-compatible queries)
        const now = new Date();
        const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString();
        const startOfWeek = new Date(now.getFullYear(), now.getMonth(), now.getDate() - now.getDay()).toISOString();
        const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();

        const [todayResult, weekResult, monthResult] = await Promise.all([
          supabase.from("profiles").select("*", { count: "exact", head: true }).gte("created_at", startOfToday),
          supabase.from("profiles").select("*", { count: "exact", head: true }).gte("created_at", startOfWeek),
          supabase.from("profiles").select("*", { count: "exact", head: true }).gte("created_at", startOfMonth),
        ]);

        return {
          total_users: adminStats.profiles || 0,
          admins: adminStats.admins || 0,
          moderators: adminStats.moderators || 0,
          users: adminStats.regular_users || 0,
          new_today: todayResult.count || 0,
          new_this_week: weekResult.count || 0,
          new_this_month: monthResult.count || 0,
          // Debug info
          auth_users: adminStats.auth_users || 0,
          auth_without_profile: adminStats.auth_without_profile || 0,
        } as UserStats & { auth_users?: number; auth_without_profile?: number };
      }

      // Fallback to direct queries (RLS applies)
      const now = new Date();
      const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString();
      const startOfWeek = new Date(now.getFullYear(), now.getMonth(), now.getDate() - now.getDay()).toISOString();
      const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();

      const [
        totalResult,
        adminsResult,
        moderatorsResult,
        usersResult,
        todayResult,
        weekResult,
        monthResult,
      ] = await Promise.all([
        supabase.from("profiles").select("*", { count: "exact", head: true }),
        supabase.from("profiles").select("*", { count: "exact", head: true }).eq("role", "admin"),
        supabase.from("profiles").select("*", { count: "exact", head: true }).eq("role", "moderator"),
        supabase.from("profiles").select("*", { count: "exact", head: true }).eq("role", "user"),
        supabase.from("profiles").select("*", { count: "exact", head: true }).gte("created_at", startOfToday),
        supabase.from("profiles").select("*", { count: "exact", head: true }).gte("created_at", startOfWeek),
        supabase.from("profiles").select("*", { count: "exact", head: true }).gte("created_at", startOfMonth),
      ]);

      return {
        total_users: totalResult.count || 0,
        admins: adminsResult.count || 0,
        moderators: moderatorsResult.count || 0,
        users: usersResult.count || 0,
        new_today: todayResult.count || 0,
        new_this_week: weekResult.count || 0,
        new_this_month: monthResult.count || 0,
      } as UserStats;
    },
  });
}

// Update user role
export function useUpdateUserRole() {
  const supabase = createClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ userId, role }: { userId: string; role: UserRole }) => {
      const { data, error } = await supabase
        .from("profiles")
        .update({ role, updated_at: new Date().toISOString() })
        .eq("id", userId)
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["users"] });
      queryClient.invalidateQueries({ queryKey: ["user-stats"] });
    },
  });
}
