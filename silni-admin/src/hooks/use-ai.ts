"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import type {
  AdminAIIdentity,
  AdminAIPersonality,
  AdminCounselingMode,
  AdminAIParameters,
  AdminMessageOccasion,
  AdminMessageTone,
} from "@/types/database";
import { toast } from "sonner";

const supabase = createClient();

// ============ AI Identity ============

export function useAIIdentity() {
  return useQuery({
    queryKey: ["admin", "ai-identity"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_ai_identity")
        .select("*")
        .single();

      if (error) throw error;
      return data as AdminAIIdentity;
    },
  });
}

export function useUpdateAIIdentity() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (identity: Partial<AdminAIIdentity>) => {
      const { data, error } = await supabase
        .from("admin_ai_identity")
        .update(identity)
        .eq("is_active", true)
        .select()
        .single();

      if (error) throw error;
      return data as AdminAIIdentity;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "ai-identity"] });
      toast.success("تم تحديث هوية الذكاء الاصطناعي");
    },
    onError: (error) => {
      toast.error(`فشل التحديث: ${error.message}`);
    },
  });
}

// ============ AI Personality ============

export function useAIPersonality() {
  return useQuery({
    queryKey: ["admin", "ai-personality"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_ai_personality")
        .select("*")
        .order("priority");

      if (error) throw error;
      return data as AdminAIPersonality[];
    },
  });
}

export function useUpdateAIPersonality() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...personality }: Partial<AdminAIPersonality> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_ai_personality")
        .update(personality)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as AdminAIPersonality;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "ai-personality"] });
      toast.success("تم تحديث الشخصية");
    },
    onError: (error) => {
      toast.error(`فشل التحديث: ${error.message}`);
    },
  });
}

// ============ Counseling Modes ============

export function useCounselingModes() {
  return useQuery({
    queryKey: ["admin", "counseling-modes"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_counseling_modes")
        .select("*")
        .order("sort_order");

      if (error) throw error;
      return data as AdminCounselingMode[];
    },
  });
}

export function useUpdateCounselingMode() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...mode }: Partial<AdminCounselingMode> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_counseling_modes")
        .update(mode)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as AdminCounselingMode;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "counseling-modes"] });
      toast.success("تم تحديث وضع الاستشارة");
    },
    onError: (error) => {
      toast.error(`فشل التحديث: ${error.message}`);
    },
  });
}

// ============ AI Parameters ============

export function useAIParameters() {
  return useQuery({
    queryKey: ["admin", "ai-parameters"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_ai_parameters")
        .select("*")
        .order("feature_key");

      if (error) throw error;
      return data as AdminAIParameters[];
    },
  });
}

export function useUpdateAIParameters() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...params }: Partial<AdminAIParameters> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_ai_parameters")
        .update(params)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as AdminAIParameters;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "ai-parameters"] });
      toast.success("تم تحديث المعاملات");
    },
    onError: (error) => {
      toast.error(`فشل التحديث: ${error.message}`);
    },
  });
}

// ============ Message Occasions ============

export function useMessageOccasions() {
  return useQuery({
    queryKey: ["admin", "message-occasions"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_message_occasions")
        .select("*")
        .order("sort_order");

      if (error) throw error;
      return data as AdminMessageOccasion[];
    },
  });
}

export function useUpdateMessageOccasion() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...occasion }: Partial<AdminMessageOccasion> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_message_occasions")
        .update(occasion)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as AdminMessageOccasion;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "message-occasions"] });
      toast.success("تم تحديث المناسبة");
    },
    onError: (error) => {
      toast.error(`فشل التحديث: ${error.message}`);
    },
  });
}

// ============ Message Tones ============

export function useMessageTones() {
  return useQuery({
    queryKey: ["admin", "message-tones"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_message_tones")
        .select("*")
        .order("sort_order");

      if (error) throw error;
      return data as AdminMessageTone[];
    },
  });
}

export function useUpdateMessageTone() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...tone }: Partial<AdminMessageTone> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_message_tones")
        .update(tone)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as AdminMessageTone;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "message-tones"] });
      toast.success("تم تحديث النبرة");
    },
    onError: (error) => {
      toast.error(`فشل التحديث: ${error.message}`);
    },
  });
}

// admin_ai_memory_config + admin_memory_categories tables were dropped on
// 2026-04-26 (Wave 2 Task 1B). The hooks that queried them were removed in
// Phase δ.A; the corresponding admin UI page (`/ai/memory`) was deleted at
// the same time.

// ============ Suggested Prompts ============

export interface AdminSuggestedPrompt {
  id: string;
  mode_key: string;
  prompt_ar: string;
  prompt_en: string | null;
  is_active: boolean;
  sort_order: number;
  created_at: string;
  updated_at: string;
}

export function useSuggestedPrompts(modeKey?: string) {
  return useQuery({
    queryKey: ["admin", "suggested-prompts", modeKey],
    queryFn: async () => {
      let query = supabase
        .from("admin_suggested_prompts")
        .select("*")
        .order("sort_order");

      if (modeKey) {
        query = query.eq("mode_key", modeKey);
      }

      const { data, error } = await query;

      if (error) throw error;
      return data as AdminSuggestedPrompt[];
    },
  });
}

export function useCreateSuggestedPrompt() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (prompt: Omit<AdminSuggestedPrompt, "id" | "created_at" | "updated_at">) => {
      const { data, error } = await supabase
        .from("admin_suggested_prompts")
        .insert(prompt)
        .select()
        .single();

      if (error) throw error;
      return data as AdminSuggestedPrompt;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "suggested-prompts"] });
      toast.success("تم إضافة الاقتراح");
    },
    onError: (error) => {
      toast.error(`فشل الإضافة: ${error.message}`);
    },
  });
}

export function useUpdateSuggestedPrompt() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...prompt }: Partial<AdminSuggestedPrompt> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_suggested_prompts")
        .update(prompt)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as AdminSuggestedPrompt;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "suggested-prompts"] });
      toast.success("تم تحديث الاقتراح");
    },
    onError: (error) => {
      toast.error(`فشل التحديث: ${error.message}`);
    },
  });
}

export function useDeleteSuggestedPrompt() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from("admin_suggested_prompts")
        .delete()
        .eq("id", id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "suggested-prompts"] });
      toast.success("تم حذف الاقتراح");
    },
    onError: (error) => {
      toast.error(`فشل الحذف: ${error.message}`);
    },
  });
}

// ============ AI Streaming Config ============

export interface AdminAIStreamingConfig {
  id: string;
  config_key: string;
  sentence_end_delay_ms: number;
  comma_delay_ms: number;
  newline_delay_ms: number;
  space_delay_ms: number;
  word_min_delay_ms: number;
  word_max_delay_ms: number;
  is_streaming_enabled: boolean;
  created_at: string;
  updated_at: string;
}

export function useAIStreamingConfig() {
  return useQuery({
    queryKey: ["admin", "ai-streaming-config"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_ai_streaming_config")
        .select("*")
        .single();

      if (error) throw error;
      return data as AdminAIStreamingConfig;
    },
  });
}

export function useUpdateAIStreamingConfig() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (config: Partial<AdminAIStreamingConfig>) => {
      const { data, error } = await supabase
        .from("admin_ai_streaming_config")
        .update(config)
        .eq("config_key", "default")
        .select()
        .single();

      if (error) throw error;
      return data as AdminAIStreamingConfig;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "ai-streaming-config"] });
      toast.success("تم تحديث إعدادات البث");
    },
    onError: (error) => {
      toast.error(`فشل التحديث: ${error.message}`);
    },
  });
}

// ============ AI Error Messages ============

export interface AdminAIErrorMessage {
  id: string;
  error_code: number;
  message_ar: string;
  message_en: string | null;
  show_retry_button: boolean;
  created_at: string;
  updated_at: string;
}

export function useAIErrorMessages() {
  return useQuery({
    queryKey: ["admin", "ai-error-messages"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_ai_error_messages")
        .select("*")
        .order("error_code");

      if (error) throw error;
      return data as AdminAIErrorMessage[];
    },
  });
}

export function useUpdateAIErrorMessage() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...errorMsg }: Partial<AdminAIErrorMessage> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_ai_error_messages")
        .update(errorMsg)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as AdminAIErrorMessage;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "ai-error-messages"] });
      toast.success("تم تحديث رسالة الخطأ");
    },
    onError: (error) => {
      toast.error(`فشل التحديث: ${error.message}`);
    },
  });
}
