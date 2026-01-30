"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import type { SocialAccount } from "@/types/database";
import { toast } from "sonner";

const supabase = createClient();

// Fetch all social accounts
export function useSocialAccounts() {
  return useQuery({
    queryKey: ["admin", "social-accounts"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("social_accounts")
        .select("*")
        .order("created_at", { ascending: false });

      if (error) throw error;
      return data as SocialAccount[];
    },
  });
}

// Update social account
export function useUpdateSocialAccount() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...account }: Partial<SocialAccount> & { id: string }) => {
      const { data, error } = await supabase
        .from("social_accounts")
        .update(account)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as SocialAccount;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "social-accounts"] });
      toast.success("تم تحديث الحساب بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في تحديث الحساب: ${error.message}`);
    },
  });
}

// Disconnect social account (set status to 'disconnected')
export function useDisconnectSocialAccount() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { data, error } = await supabase
        .from("social_accounts")
        .update({ status: "disconnected" })
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as SocialAccount;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "social-accounts"] });
      toast.success("تم فصل الحساب بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في فصل الحساب: ${error.message}`);
    },
  });
}
