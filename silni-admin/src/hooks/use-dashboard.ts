"use client";

import { useQuery } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";

const supabase = createClient();

interface DashboardStats {
  content: {
    hadithCount: number;
    quotesCount: number;
    activeMOTD: number;
    activeBanners: number;
  };
  gamification: {
    badgesCount: number;
    levelsCount: number;
    challengesCount: number;
    activeStreakConfig: boolean;
  };
  subscriptions: {
    tiersCount: number;
    productsCount: number;
    featuresCount: number;
  };
  notifications: {
    templatesCount: number;
    timeSlotsCount: number;
  };
  design: {
    colorsCount: number;
    themesCount: number;
    animationsCount: number;
  };
  ai: {
    hasIdentity: boolean;
    personalitySections: number;
    counselingModes: number;
    aiParameters: number;
    occasionsCount: number;
    tonesCount: number;
  };
}

export function useDashboardStats() {
  return useQuery({
    queryKey: ["admin", "dashboard-stats"],
    queryFn: async (): Promise<DashboardStats> => {
      // Fetch all stats in parallel
      const [
        // Content
        hadithRes,
        quotesRes,
        motdRes,
        bannersRes,
        // Gamification
        badgesRes,
        levelsRes,
        challengesRes,
        streakRes,
        // Subscriptions
        tiersRes,
        productsRes,
        featuresRes,
        // Notifications
        templatesRes,
        timeSlotsRes,
        // Design
        colorsRes,
        themesRes,
        animationsRes,
        // AI
        identityRes,
        personalityRes,
        modesRes,
        parametersRes,
        occasionsRes,
        tonesRes,
      ] = await Promise.all([
        // Content
        supabase.from("admin_hadith").select("*", { count: "exact", head: true }),
        supabase.from("admin_quotes").select("*", { count: "exact", head: true }),
        supabase.from("admin_motd").select("*", { count: "exact", head: true }).eq("is_active", true),
        supabase.from("admin_banners").select("*", { count: "exact", head: true }).eq("is_active", true),
        // Gamification
        supabase.from("admin_badges").select("*", { count: "exact", head: true }),
        supabase.from("admin_levels").select("*", { count: "exact", head: true }),
        supabase.from("admin_challenges").select("*", { count: "exact", head: true }).eq("is_active", true),
        supabase.from("admin_streak_config").select("*", { count: "exact", head: true }).eq("is_active", true),
        // Subscriptions
        supabase.from("admin_subscription_tiers").select("*", { count: "exact", head: true }),
        supabase.from("admin_subscription_products").select("*", { count: "exact", head: true }),
        supabase.from("admin_features").select("*", { count: "exact", head: true }),
        // Notifications
        supabase.from("admin_notification_templates").select("*", { count: "exact", head: true }),
        supabase.from("admin_reminder_time_slots").select("*", { count: "exact", head: true }),
        // Design
        supabase.from("admin_colors").select("*", { count: "exact", head: true }),
        supabase.from("admin_themes").select("*", { count: "exact", head: true }),
        supabase.from("admin_pattern_animations").select("*", { count: "exact", head: true }),
        // AI
        supabase.from("admin_ai_identity").select("*", { count: "exact", head: true }).eq("is_active", true),
        supabase.from("admin_ai_personality").select("*", { count: "exact", head: true }).eq("is_active", true),
        supabase.from("admin_counseling_modes").select("*", { count: "exact", head: true }).eq("is_active", true),
        supabase.from("admin_ai_parameters").select("*", { count: "exact", head: true }),
        supabase.from("admin_message_occasions").select("*", { count: "exact", head: true }).eq("is_active", true),
        supabase.from("admin_message_tones").select("*", { count: "exact", head: true }).eq("is_active", true),
      ]);

      return {
        content: {
          hadithCount: hadithRes.count || 0,
          quotesCount: quotesRes.count || 0,
          activeMOTD: motdRes.count || 0,
          activeBanners: bannersRes.count || 0,
        },
        gamification: {
          badgesCount: badgesRes.count || 0,
          levelsCount: levelsRes.count || 0,
          challengesCount: challengesRes.count || 0,
          activeStreakConfig: (streakRes.count || 0) > 0,
        },
        subscriptions: {
          tiersCount: tiersRes.count || 0,
          productsCount: productsRes.count || 0,
          featuresCount: featuresRes.count || 0,
        },
        notifications: {
          templatesCount: templatesRes.count || 0,
          timeSlotsCount: timeSlotsRes.count || 0,
        },
        design: {
          colorsCount: colorsRes.count || 0,
          themesCount: themesRes.count || 0,
          animationsCount: animationsRes.count || 0,
        },
        ai: {
          hasIdentity: (identityRes.count || 0) > 0,
          personalitySections: personalityRes.count || 0,
          counselingModes: modesRes.count || 0,
          aiParameters: parametersRes.count || 0,
          occasionsCount: occasionsRes.count || 0,
          tonesCount: tonesRes.count || 0,
        },
      };
    },
    staleTime: 60000, // 1 minute
    refetchOnWindowFocus: false,
  });
}

interface SystemHealth {
  database: "connected" | "error" | "checking";
  ai: "connected" | "error" | "checking";
  storage: "connected" | "error" | "checking";
}

export function useSystemHealth() {
  return useQuery({
    queryKey: ["admin", "system-health"],
    queryFn: async (): Promise<SystemHealth> => {
      // Check database by running a simple query
      let database: SystemHealth["database"] = "checking";
      try {
        const { error } = await supabase.from("admin_hadith").select("id").limit(1);
        database = error ? "error" : "connected";
      } catch {
        database = "error";
      }

      // Check storage
      let storage: SystemHealth["storage"] = "checking";
      try {
        const { error } = await supabase.storage.listBuckets();
        storage = error ? "error" : "connected";
      } catch {
        storage = "error";
      }

      // AI check - we assume it's connected if the parameters are configured
      let ai: SystemHealth["ai"] = "checking";
      try {
        const { data, error } = await supabase
          .from("admin_ai_parameters")
          .select("id")
          .limit(1);
        ai = error ? "error" : data && data.length > 0 ? "connected" : "error";
      } catch {
        ai = "error";
      }

      return { database, ai, storage };
    },
    staleTime: 30000, // 30 seconds
    refetchInterval: 60000, // Refetch every minute
  });
}

interface RecentActivity {
  type: "content" | "gamification" | "subscription" | "ai";
  action: "created" | "updated" | "deleted";
  item: string;
  timestamp: string;
}

export function useRecentActivity() {
  return useQuery({
    queryKey: ["admin", "recent-activity"],
    queryFn: async (): Promise<RecentActivity[]> => {
      // Fetch recent items from various tables
      const [hadith, quotes, badges, challenges] = await Promise.all([
        supabase
          .from("admin_hadith")
          .select("id, hadith_text, created_at, updated_at")
          .order("updated_at", { ascending: false })
          .limit(3),
        supabase
          .from("admin_quotes")
          .select("id, quote_text, created_at, updated_at")
          .order("updated_at", { ascending: false })
          .limit(3),
        supabase
          .from("admin_badges")
          .select("id, display_name_ar, created_at, updated_at")
          .order("updated_at", { ascending: false })
          .limit(2),
        supabase
          .from("admin_challenges")
          .select("id, title_ar, created_at, updated_at")
          .order("updated_at", { ascending: false })
          .limit(2),
      ]);

      const activities: RecentActivity[] = [];

      hadith.data?.forEach((h) => {
        const isNew = h.created_at === h.updated_at;
        activities.push({
          type: "content",
          action: isNew ? "created" : "updated",
          item: `حديث: ${h.hadith_text.substring(0, 30)}...`,
          timestamp: h.updated_at,
        });
      });

      quotes.data?.forEach((q) => {
        const isNew = q.created_at === q.updated_at;
        activities.push({
          type: "content",
          action: isNew ? "created" : "updated",
          item: `اقتباس: ${q.quote_text.substring(0, 30)}...`,
          timestamp: q.updated_at,
        });
      });

      badges.data?.forEach((b) => {
        const isNew = b.created_at === b.updated_at;
        activities.push({
          type: "gamification",
          action: isNew ? "created" : "updated",
          item: `وسام: ${b.display_name_ar}`,
          timestamp: b.updated_at,
        });
      });

      challenges.data?.forEach((c) => {
        const isNew = c.created_at === c.updated_at;
        activities.push({
          type: "gamification",
          action: isNew ? "created" : "updated",
          item: `تحدي: ${c.title_ar}`,
          timestamp: c.updated_at,
        });
      });

      // Sort by timestamp
      return activities.sort(
        (a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
      ).slice(0, 10);
    },
    staleTime: 30000,
  });
}
