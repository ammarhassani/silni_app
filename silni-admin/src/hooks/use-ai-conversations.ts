"use client";

import { useQuery } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";

// Types
export interface ConversationStats {
  total_conversations: number;
  total_messages: number;
  total_memories: number;
  conversations_today: number;
  messages_today: number;
  conversations_this_week: number;
  avg_messages_per_conversation: number;
  by_mode: Record<string, number>;
}

export interface ConversationSummary {
  id: string;
  user_id: string;
  mode: string;
  title: string | null;
  message_count: number;
  created_at: string;
  updated_at: string;
  is_archived: boolean;
  user_email?: string;
}

export interface MemoryStats {
  total: number;
  by_category: Record<string, number>;
  avg_importance: number;
}

// Mode labels in Arabic
export const modeLabels: Record<string, string> = {
  general: "عام",
  parenting: "تربية",
  elderly_care: "رعاية المسنين",
  distant_relations: "علاقات بعيدة",
  conflict_resolution: "حل النزاعات",
  emotional_support: "دعم عاطفي",
};

// Memory category labels
export const memoryCategoryLabels: Record<string, string> = {
  family_info: "معلومات العائلة",
  relationship: "العلاقات",
  preferences: "التفضيلات",
  challenges: "التحديات",
  goals: "الأهداف",
  context: "السياق",
  other: "أخرى",
};

// Fetch conversation stats
export function useConversationStats() {
  const supabase = createClient();

  return useQuery({
    queryKey: ["ai-conversations", "stats"],
    queryFn: async () => {
      const now = new Date();
      const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString();
      const startOfWeek = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString();

      const [
        totalConvRes,
        totalMsgRes,
        totalMemRes,
        convTodayRes,
        msgTodayRes,
        convWeekRes,
        byModeRes,
      ] = await Promise.all([
        supabase.from("chat_conversations").select("*", { count: "exact", head: true }),
        supabase.from("chat_messages").select("*", { count: "exact", head: true }),
        supabase.from("ai_memories").select("*", { count: "exact", head: true }),
        supabase.from("chat_conversations").select("*", { count: "exact", head: true }).gte("created_at", startOfToday),
        supabase.from("chat_messages").select("*", { count: "exact", head: true }).gte("created_at", startOfToday),
        supabase.from("chat_conversations").select("*", { count: "exact", head: true }).gte("created_at", startOfWeek),
        supabase.from("chat_conversations").select("mode"),
      ]);

      // Count by mode
      const byMode: Record<string, number> = {};
      byModeRes.data?.forEach((conv) => {
        byMode[conv.mode] = (byMode[conv.mode] || 0) + 1;
      });

      const totalConv = totalConvRes.count || 1;
      const totalMsg = totalMsgRes.count || 0;

      return {
        total_conversations: totalConvRes.count || 0,
        total_messages: totalMsgRes.count || 0,
        total_memories: totalMemRes.count || 0,
        conversations_today: convTodayRes.count || 0,
        messages_today: msgTodayRes.count || 0,
        conversations_this_week: convWeekRes.count || 0,
        avg_messages_per_conversation: Math.round((totalMsg / totalConv) * 10) / 10,
        by_mode: byMode,
      } as ConversationStats;
    },
    staleTime: 60000, // 1 minute
  });
}

// Fetch recent conversations (anonymized)
export function useRecentConversations(limit: number = 20) {
  const supabase = createClient();

  return useQuery({
    queryKey: ["ai-conversations", "recent", limit],
    queryFn: async () => {
      // Get conversations with message count
      const { data: conversations, error } = await supabase
        .from("chat_conversations")
        .select(`
          id,
          user_id,
          mode,
          title,
          created_at,
          updated_at,
          is_archived
        `)
        .order("updated_at", { ascending: false })
        .limit(limit);

      if (error) throw error;

      // Get message counts per conversation
      const conversationIds = conversations?.map((c) => c.id) || [];

      const { data: messageCounts } = await supabase
        .from("chat_messages")
        .select("conversation_id")
        .in("conversation_id", conversationIds);

      const countMap: Record<string, number> = {};
      messageCounts?.forEach((msg) => {
        countMap[msg.conversation_id] = (countMap[msg.conversation_id] || 0) + 1;
      });

      return conversations?.map((conv) => ({
        ...conv,
        message_count: countMap[conv.id] || 0,
      })) as ConversationSummary[];
    },
    staleTime: 30000,
  });
}

// Fetch memory stats
export function useMemoryStats() {
  const supabase = createClient();

  return useQuery({
    queryKey: ["ai-memories", "stats"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("ai_memories")
        .select("category, importance")
        .eq("is_active", true);

      if (error) throw error;

      const byCategory: Record<string, number> = {};
      let totalImportance = 0;

      data?.forEach((mem) => {
        byCategory[mem.category] = (byCategory[mem.category] || 0) + 1;
        totalImportance += mem.importance || 5;
      });

      return {
        total: data?.length || 0,
        by_category: byCategory,
        avg_importance: data?.length ? Math.round((totalImportance / data.length) * 10) / 10 : 0,
      } as MemoryStats;
    },
    staleTime: 60000,
  });
}

// Fetch conversation activity over time (last 30 days)
export function useConversationActivity(days: number = 30) {
  const supabase = createClient();

  return useQuery({
    queryKey: ["ai-conversations", "activity", days],
    queryFn: async () => {
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - days);

      const { data, error } = await supabase
        .from("chat_conversations")
        .select("created_at")
        .gte("created_at", startDate.toISOString())
        .order("created_at", { ascending: true });

      if (error) throw error;

      // Group by date
      const grouped: Record<string, number> = {};
      data?.forEach((conv) => {
        const date = new Date(conv.created_at).toISOString().split("T")[0];
        grouped[date] = (grouped[date] || 0) + 1;
      });

      // Fill in missing dates
      const result: { date: string; count: number }[] = [];
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
    staleTime: 300000,
  });
}
