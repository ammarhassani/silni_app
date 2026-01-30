"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import type { SocialCampaign } from "@/types/database";
import { toast } from "sonner";

const supabase = createClient();

// Fetch all social campaigns
export function useSocialCampaigns() {
  return useQuery({
    queryKey: ["admin", "social-campaigns"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("social_campaigns")
        .select("*")
        .order("created_at", { ascending: false });

      if (error) throw error;
      return data as SocialCampaign[];
    },
  });
}

// Create social campaign
export function useCreateSocialCampaign() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (campaign: Omit<SocialCampaign, "id" | "created_at" | "updated_at">) => {
      const { data, error } = await supabase
        .from("social_campaigns")
        .insert(campaign)
        .select()
        .single();

      if (error) throw error;
      return data as SocialCampaign;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "social-campaigns"] });
      toast.success("تم إنشاء الحملة بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في إنشاء الحملة: ${error.message}`);
    },
  });
}

// Update social campaign
export function useUpdateSocialCampaign() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...campaign }: Partial<SocialCampaign> & { id: string }) => {
      const { data, error } = await supabase
        .from("social_campaigns")
        .update(campaign)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as SocialCampaign;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "social-campaigns"] });
      toast.success("تم تحديث الحملة بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في تحديث الحملة: ${error.message}`);
    },
  });
}

// Delete social campaign
export function useDeleteSocialCampaign() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from("social_campaigns")
        .delete()
        .eq("id", id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "social-campaigns"] });
      toast.success("تم حذف الحملة بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في حذف الحملة: ${error.message}`);
    },
  });
}
