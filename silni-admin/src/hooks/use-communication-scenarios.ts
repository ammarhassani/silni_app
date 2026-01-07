"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import { toast } from "sonner";

export interface CommunicationScenario {
  id: string;
  scenario_key: string;
  title_ar: string;
  title_en: string | null;
  description_ar: string;
  description_en: string | null;
  emoji: string;
  color_hex: string;
  prompt_context: string | null;
  sort_order: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export type CommunicationScenarioInput = Omit<CommunicationScenario, "id" | "created_at" | "updated_at">;

// Emoji options for scenarios
export const scenarioEmojis = [
  { value: "🤝", label: "مصافحة" },
  { value: "🎉", label: "احتفال" },
  { value: "💐", label: "باقة ورد" },
  { value: "🔄", label: "إعادة" },
  { value: "🙏", label: "شكر" },
  { value: "💬", label: "محادثة" },
  { value: "❤️", label: "قلب" },
  { value: "🌟", label: "نجمة" },
  { value: "🕊️", label: "سلام" },
  { value: "🤗", label: "عناق" },
];

// Color presets
export const scenarioColors = [
  { value: "#FF9800", label: "برتقالي" },
  { value: "#4CAF50", label: "أخضر" },
  { value: "#9C27B0", label: "بنفسجي" },
  { value: "#2196F3", label: "أزرق" },
  { value: "#009688", label: "سماوي" },
  { value: "#FFC107", label: "أصفر" },
  { value: "#E91E63", label: "وردي" },
  { value: "#607D8B", label: "رمادي" },
];

// Fetch all scenarios
export function useCommunicationScenarios() {
  const supabase = createClient();

  return useQuery({
    queryKey: ["admin", "communication-scenarios"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_communication_scenarios")
        .select("*")
        .order("sort_order", { ascending: true });

      if (error) throw error;
      return data as CommunicationScenario[];
    },
  });
}

// Fetch single scenario
export function useCommunicationScenarioById(id: string) {
  const supabase = createClient();

  return useQuery({
    queryKey: ["admin", "communication-scenarios", id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_communication_scenarios")
        .select("*")
        .eq("id", id)
        .single();

      if (error) throw error;
      return data as CommunicationScenario;
    },
    enabled: !!id,
  });
}

// Create scenario
export function useCreateCommunicationScenario() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async (scenario: CommunicationScenarioInput) => {
      const { data, error } = await supabase
        .from("admin_communication_scenarios")
        .insert(scenario)
        .select()
        .single();

      if (error) throw error;
      return data as CommunicationScenario;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "communication-scenarios"] });
      toast.success("تم إنشاء السيناريو بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في إنشاء السيناريو: ${error.message}`);
    },
  });
}

// Update scenario
export function useUpdateCommunicationScenario() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async ({ id, ...scenario }: Partial<CommunicationScenario> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_communication_scenarios")
        .update(scenario)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as CommunicationScenario;
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ["admin", "communication-scenarios"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "communication-scenarios", variables.id] });
      toast.success("تم تحديث السيناريو بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في تحديث السيناريو: ${error.message}`);
    },
  });
}

// Delete scenario
export function useDeleteCommunicationScenario() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from("admin_communication_scenarios")
        .delete()
        .eq("id", id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "communication-scenarios"] });
      toast.success("تم حذف السيناريو بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في حذف السيناريو: ${error.message}`);
    },
  });
}

// Toggle scenario active status
export function useToggleCommunicationScenarioActive() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async ({ id, is_active }: { id: string; is_active: boolean }) => {
      const { data, error } = await supabase
        .from("admin_communication_scenarios")
        .update({ is_active })
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as CommunicationScenario;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "communication-scenarios"] });
      toast.success("تم تحديث حالة السيناريو");
    },
    onError: (error) => {
      toast.error(`فشل في تحديث الحالة: ${error.message}`);
    },
  });
}

// Reorder scenarios
export function useReorderCommunicationScenarios() {
  const queryClient = useQueryClient();
  const supabase = createClient();

  return useMutation({
    mutationFn: async (orderedIds: string[]) => {
      const updates = orderedIds.map((id, index) => ({
        id,
        sort_order: index,
      }));

      for (const update of updates) {
        const { error } = await supabase
          .from("admin_communication_scenarios")
          .update({ sort_order: update.sort_order })
          .eq("id", update.id);

        if (error) throw error;
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "communication-scenarios"] });
      toast.success("تم إعادة ترتيب السيناريوهات");
    },
    onError: (error) => {
      toast.error(`فشل في إعادة الترتيب: ${error.message}`);
    },
  });
}
