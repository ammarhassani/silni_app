"use client";

import { useQuery } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";

// Types
export interface UserGrowthData {
  date: string;
  count: number;
}

export interface SubscriptionDistribution {
  free: number;
  premium: number;
  trial: number;
}

export interface InteractionStats {
  total: number;
  today: number;
  this_week: number;
  this_month: number;
  by_type: Record<string, number>;
}

export interface GamificationStats {
  total_points: number;
  avg_points: number;
  avg_level: number;
  avg_streak: number;
  max_streak: number;
  users_with_badges: number;
}

export interface SubscriptionEventStats {
  total_events: number;
  purchases: number;
  cancellations: number;
  trials_started: number;
  trials_converted: number;
  total_revenue: number;
}

export interface DashboardOverview {
  total_users: number;
  new_users_today: number;
  new_users_week: number;
  new_users_month: number;
  active_users_today: number;
  active_users_week: number;
  total_interactions: number;
  total_relatives: number;
  premium_users: number;
  free_users: number;
}

// Fetch dashboard overview using admin function (bypasses RLS)
export function useDashboardOverview() {
  const supabase = createClient();

  return useQuery({
    queryKey: ["analytics", "overview"],
    queryFn: async () => {
      // Try admin function first (bypasses RLS)
      const { data, error } = await supabase.rpc("get_admin_dashboard_overview");
      if (!error && data) {
        return data as DashboardOverview;
      }

      // Fallback to direct queries (RLS applies)
      const now = new Date();
      const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString();
      const startOfWeek = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 7).toISOString();
      const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();

      const [
        totalUsersRes,
        newTodayRes,
        newWeekRes,
        newMonthRes,
        activeTodayRes,
        activeWeekRes,
        totalInteractionsRes,
        totalRelativesRes,
        premiumRes,
        freeRes,
      ] = await Promise.all([
        supabase.from("users").select("*", { count: "exact", head: true }),
        supabase.from("users").select("*", { count: "exact", head: true }).gte("created_at", startOfToday),
        supabase.from("users").select("*", { count: "exact", head: true }).gte("created_at", startOfWeek),
        supabase.from("users").select("*", { count: "exact", head: true }).gte("created_at", startOfMonth),
        supabase.from("users").select("*", { count: "exact", head: true }).gte("last_interaction_at", startOfToday),
        supabase.from("users").select("*", { count: "exact", head: true }).gte("last_interaction_at", startOfWeek),
        supabase.from("interactions").select("*", { count: "exact", head: true }),
        supabase.from("relatives").select("*", { count: "exact", head: true }),
        supabase.from("users").select("*", { count: "exact", head: true }).eq("subscription_status", "premium"),
        supabase.from("users").select("*", { count: "exact", head: true }).eq("subscription_status", "free"),
      ]);

      return {
        total_users: totalUsersRes.count || 0,
        new_users_today: newTodayRes.count || 0,
        new_users_week: newWeekRes.count || 0,
        new_users_month: newMonthRes.count || 0,
        active_users_today: activeTodayRes.count || 0,
        active_users_week: activeWeekRes.count || 0,
        total_interactions: totalInteractionsRes.count || 0,
        total_relatives: totalRelativesRes.count || 0,
        premium_users: premiumRes.count || 0,
        free_users: freeRes.count || 0,
      } as DashboardOverview;
    },
    staleTime: 60000, // 1 minute
  });
}

// Fetch user growth over time using admin function
export function useUserGrowth(days: number = 30) {
  const supabase = createClient();

  return useQuery({
    queryKey: ["analytics", "user-growth", days],
    queryFn: async () => {
      // Try admin function first
      const { data: adminData, error: adminError } = await supabase.rpc("get_admin_user_growth", { days_back: days });

      // Build date map from admin data if available
      const grouped: Record<string, number> = {};
      if (!adminError && adminData) {
        adminData.forEach((item: { date: string; count: number }) => {
          grouped[item.date] = item.count;
        });
      } else {
        // Fallback to direct query
        const startDate = new Date();
        startDate.setDate(startDate.getDate() - days);

        const { data, error } = await supabase
          .from("users")
          .select("created_at")
          .gte("created_at", startDate.toISOString())
          .order("created_at", { ascending: true });

        if (!error && data) {
          data.forEach((user) => {
            const date = new Date(user.created_at).toISOString().split("T")[0];
            grouped[date] = (grouped[date] || 0) + 1;
          });
        }
      }

      // Fill in missing dates with 0
      const result: UserGrowthData[] = [];
      for (let i = 0; i < days; i++) {
        const date = new Date();
        date.setDate(date.getDate() - (days - 1 - i));
        const dateStr = date.toISOString().split("T")[0];
        result.push({
          date: dateStr,
          count: grouped[dateStr] || 0,
        });
      }

      return result;
    },
    staleTime: 300000, // 5 minutes
  });
}

// Fetch subscription distribution using admin function
export function useSubscriptionDistribution() {
  const supabase = createClient();

  return useQuery({
    queryKey: ["analytics", "subscription-distribution"],
    queryFn: async () => {
      // Try admin function first
      const { data, error } = await supabase.rpc("get_admin_subscription_distribution");
      if (!error && data) {
        return data as SubscriptionDistribution;
      }

      // Fallback
      const [premiumRes, freeRes, trialRes] = await Promise.all([
        supabase.from("users").select("*", { count: "exact", head: true })
          .eq("subscription_status", "premium")
          .is("trial_started_at", null),
        supabase.from("users").select("*", { count: "exact", head: true })
          .eq("subscription_status", "free"),
        supabase.from("users").select("*", { count: "exact", head: true })
          .eq("subscription_status", "premium")
          .not("trial_started_at", "is", null)
          .eq("trial_used", false),
      ]);

      return {
        premium: premiumRes.count || 0,
        free: freeRes.count || 0,
        trial: trialRes.count || 0,
      } as SubscriptionDistribution;
    },
    staleTime: 60000,
  });
}

// Fetch interaction stats using admin function
export function useInteractionStats() {
  const supabase = createClient();

  return useQuery({
    queryKey: ["analytics", "interaction-stats"],
    queryFn: async () => {
      // Try admin function first
      const { data, error } = await supabase.rpc("get_admin_interaction_stats");
      if (!error && data) {
        return data as InteractionStats;
      }

      // Fallback
      const now = new Date();
      const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString();
      const startOfWeek = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 7).toISOString();
      const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();

      const [totalRes, todayRes, weekRes, monthRes, byTypeRes] = await Promise.all([
        supabase.from("interactions").select("*", { count: "exact", head: true }),
        supabase.from("interactions").select("*", { count: "exact", head: true }).gte("created_at", startOfToday),
        supabase.from("interactions").select("*", { count: "exact", head: true }).gte("created_at", startOfWeek),
        supabase.from("interactions").select("*", { count: "exact", head: true }).gte("created_at", startOfMonth),
        supabase.from("interactions").select("type"),
      ]);

      const byType: Record<string, number> = {};
      byTypeRes.data?.forEach((interaction) => {
        byType[interaction.type] = (byType[interaction.type] || 0) + 1;
      });

      return {
        total: totalRes.count || 0,
        today: todayRes.count || 0,
        this_week: weekRes.count || 0,
        this_month: monthRes.count || 0,
        by_type: byType,
      } as InteractionStats;
    },
    staleTime: 60000,
  });
}

// Fetch gamification stats using admin function
export function useGamificationStats() {
  const supabase = createClient();

  return useQuery({
    queryKey: ["analytics", "gamification-stats"],
    queryFn: async () => {
      // Try admin function first
      const { data, error } = await supabase.rpc("get_admin_gamification_stats");
      if (!error && data) {
        return data as GamificationStats;
      }

      // Fallback
      const { data: users, error: usersError } = await supabase
        .from("users")
        .select("points, level, current_streak, longest_streak, badges");

      if (usersError) throw usersError;

      const userData = users || [];
      const totalUsers = userData.length || 1;

      const totalPoints = userData.reduce((sum, u) => sum + (u.points || 0), 0);
      const avgPoints = Math.round(totalPoints / totalUsers);
      const avgLevel = userData.reduce((sum, u) => sum + (u.level || 1), 0) / totalUsers;
      const avgStreak = userData.reduce((sum, u) => sum + (u.current_streak || 0), 0) / totalUsers;
      const maxStreak = Math.max(...userData.map((u) => u.longest_streak || 0), 0);
      const usersWithBadges = userData.filter((u) => (u.badges?.length || 0) > 0).length;

      return {
        total_points: totalPoints,
        avg_points: avgPoints,
        avg_level: Math.round(avgLevel * 10) / 10,
        avg_streak: Math.round(avgStreak * 10) / 10,
        max_streak: maxStreak,
        users_with_badges: usersWithBadges,
      } as GamificationStats;
    },
    staleTime: 300000,
  });
}

// Fetch subscription event stats
export function useSubscriptionEventStats() {
  const supabase = createClient();

  return useQuery({
    queryKey: ["analytics", "subscription-events"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("subscription_events")
        .select("event_type, revenue_amount");

      if (error) {
        // Table might not exist or no access
        return {
          total_events: 0,
          purchases: 0,
          cancellations: 0,
          trials_started: 0,
          trials_converted: 0,
          total_revenue: 0,
        } as SubscriptionEventStats;
      }

      const events = data || [];

      return {
        total_events: events.length,
        purchases: events.filter((e) => e.event_type === "purchase").length,
        cancellations: events.filter((e) => e.event_type === "cancellation").length,
        trials_started: events.filter((e) => e.event_type === "trial_start").length,
        trials_converted: events.filter((e) => e.event_type === "purchase" && events.some((t) => t.event_type === "trial_end")).length,
        total_revenue: events.reduce((sum, e) => sum + (Number(e.revenue_amount) || 0), 0),
      } as SubscriptionEventStats;
    },
    staleTime: 300000,
  });
}

// Top user type
export interface TopUser {
  id: string;
  email: string | null;
  full_name: string | null;
  total_interactions: number | null;
  current_streak: number | null;
  level: number | null;
  points: number | null;
  subscription_status: string | null;
}

// Fetch top active users using admin function
export function useTopActiveUsers(limit: number = 10) {
  const supabase = createClient();

  return useQuery({
    queryKey: ["analytics", "top-users", limit],
    queryFn: async (): Promise<TopUser[]> => {
      // Try admin function first
      const { data, error } = await supabase.rpc("get_admin_top_users", { user_limit: limit });
      if (!error && data) {
        return data as TopUser[];
      }

      // Fallback
      const { data: fallbackData, error: fallbackError } = await supabase
        .from("users")
        .select("id, email, full_name, total_interactions, current_streak, level, points, subscription_status")
        .order("total_interactions", { ascending: false })
        .limit(limit);

      if (fallbackError) throw fallbackError;
      return (fallbackData || []) as TopUser[];
    },
    staleTime: 300000,
  });
}
