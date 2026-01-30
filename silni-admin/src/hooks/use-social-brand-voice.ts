"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import type { SocialBrandVoice } from "@/types/database";
import { toast } from "sonner";

const supabase = createClient();

// Fetch active brand voice config
export function useSocialBrandVoice() {
  return useQuery({
    queryKey: ["admin", "social-brand-voice"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("social_brand_voice")
        .select("*")
        .eq("is_active", true)
        .single();

      if (error) throw error;
      return data as SocialBrandVoice;
    },
  });
}

// Update brand voice config
export function useUpdateSocialBrandVoice() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...brandVoice }: Partial<SocialBrandVoice> & { id: string }) => {
      const { data, error } = await supabase
        .from("social_brand_voice")
        .update(brandVoice)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as SocialBrandVoice;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "social-brand-voice"] });
      toast.success("تم تحديث إعدادات الصوت بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في تحديث إعدادات الصوت: ${error.message}`);
    },
  });
}
