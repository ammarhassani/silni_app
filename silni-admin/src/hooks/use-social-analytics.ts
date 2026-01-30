"use client";

import { useQuery } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import type { SocialAnalytics, SocialClickLog } from "@/types/database";

const supabase = createClient();

// Fetch analytics for a specific post
export function useSocialAnalyticsByPost(postId: string) {
  return useQuery({
    queryKey: ["admin", "social-analytics", postId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("social_analytics")
        .select("*")
        .eq("post_id", postId)
        .order("snapshot_at", { ascending: false });

      if (error) throw error;
      return data as SocialAnalytics[];
    },
    enabled: !!postId,
  });
}

// Fetch analytics overview for the last N days
export function useSocialAnalyticsOverview(days: number) {
  return useQuery({
    queryKey: ["admin", "social-analytics", "overview", days],
    queryFn: async () => {
      const since = new Date();
      since.setDate(since.getDate() - days);

      const { data, error } = await supabase
        .from("social_analytics")
        .select("*")
        .gte("snapshot_at", since.toISOString());

      if (error) throw error;
      return data as SocialAnalytics[];
    },
  });
}

// Fetch click logs for a specific post
export function useSocialClicksByPost(postId: string) {
  return useQuery({
    queryKey: ["admin", "social-analytics", "clicks", postId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("social_click_log")
        .select("*")
        .eq("post_id", postId);

      if (error) throw error;
      return data as SocialClickLog[];
    },
    enabled: !!postId,
  });
}

// Fetch click logs for a specific campaign UTM
export function useSocialClicksByCampaign(campaignUtm: string) {
  return useQuery({
    queryKey: ["admin", "social-analytics", "clicks-campaign", campaignUtm],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("social_click_log")
        .select("*")
        .eq("utm_campaign", campaignUtm);

      if (error) throw error;
      return data as SocialClickLog[];
    },
    enabled: !!campaignUtm,
  });
}
