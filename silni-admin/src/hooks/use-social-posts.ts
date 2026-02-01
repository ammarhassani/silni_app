"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import type { SocialPost, SocialPostStatus } from "@/types/database";
import { toast } from "sonner";

const supabase = createClient();

// Fetch all social posts, optionally filtered by status
export function useSocialPosts(statusFilter?: SocialPostStatus) {
  return useQuery({
    queryKey: ["admin", "social-posts", statusFilter],
    queryFn: async () => {
      let query = supabase
        .from("social_posts")
        .select("*")
        .order("created_at", { ascending: false });

      if (statusFilter) {
        query = query.eq("status", statusFilter);
      }

      const { data, error } = await query;
      if (error) throw error;
      return data as SocialPost[];
    },
  });
}

// Fetch single social post by id
export function useSocialPostById(id: string) {
  return useQuery({
    queryKey: ["admin", "social-posts", id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("social_posts")
        .select("*")
        .eq("id", id)
        .single();

      if (error) throw error;
      return data as SocialPost;
    },
    enabled: !!id,
  });
}

// Create a single social post
export function useCreateSocialPost() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (post: Omit<SocialPost, "id" | "created_at" | "updated_at">) => {
      const { data, error } = await supabase
        .from("social_posts")
        .insert(post)
        .select()
        .single();

      if (error) throw error;
      return data as SocialPost;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "social-posts"] });
      toast.success("تم إنشاء المنشور بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في إنشاء المنشور: ${error.message}`);
    },
  });
}

// Create a batch of social posts
export function useCreateSocialPostsBatch() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (posts: Omit<SocialPost, "id" | "created_at" | "updated_at">[]) => {
      const { data, error } = await supabase
        .from("social_posts")
        .insert(posts)
        .select();

      if (error) throw error;
      return data as SocialPost[];
    },
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: ["admin", "social-posts"] });
      toast.success(`تم إنشاء ${data.length} منشور بنجاح`);
    },
    onError: (error) => {
      toast.error(`فشل في إنشاء المنشورات: ${error.message}`);
    },
  });
}

// Update a social post
export function useUpdateSocialPost() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...post }: Partial<SocialPost> & { id: string }) => {
      const { data, error } = await supabase
        .from("social_posts")
        .update(post)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as SocialPost;
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ["admin", "social-posts"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "social-posts", variables.id] });
      toast.success("تم تحديث المنشور بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في تحديث المنشور: ${error.message}`);
    },
  });
}

// Delete a social post
export function useDeleteSocialPost() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from("social_posts")
        .delete()
        .eq("id", id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "social-posts"] });
      toast.success("تم حذف المنشور بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في حذف المنشور: ${error.message}`);
    },
  });
}

// Bulk update status (and optionally account_id) for multiple posts
export function useBulkUpdatePostStatus() {
  const queryClient = useQueryClient();

  const statusLabels: Record<string, string> = {
    approved: "قبول",
    rejected: "رفض",
    scheduled: "جدولة",
  };

  return useMutation({
    mutationFn: async ({ ids, status, account_id }: { ids: string[]; status: SocialPostStatus; account_id?: string }) => {
      const updates: Record<string, unknown> = { status };
      if (account_id) updates.account_id = account_id;

      const { error } = await supabase
        .from("social_posts")
        .update(updates)
        .in("id", ids);

      if (error) throw error;
    },
    onSuccess: (_, { ids, status }) => {
      queryClient.invalidateQueries({ queryKey: ["admin", "social-posts"] });
      const label = statusLabels[status] || status;
      toast.success(`تم ${label} ${ids.length} منشور بنجاح`);
    },
    onError: (error) => {
      toast.error(`فشل في تحديث الحالة: ${error.message}`);
    },
  });
}

// Fetch scheduled/published/failed posts ordered by scheduled_at
export function useScheduledPosts() {
  return useQuery({
    queryKey: ["admin", "social-posts", "scheduled"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("social_posts")
        .select("*")
        .in("status", ["scheduled", "published", "failed"])
        .order("scheduled_at", { ascending: true });

      if (error) throw error;
      return data as SocialPost[];
    },
  });
}
