"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import type { SocialTemplate } from "@/types/database";
import { toast } from "sonner";

const supabase = createClient();

// Fetch all social templates
export function useSocialTemplates() {
  return useQuery({
    queryKey: ["admin", "social-templates"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("social_templates")
        .select("*")
        .order("created_at", { ascending: false });

      if (error) throw error;
      return data as SocialTemplate[];
    },
  });
}

// Create social template
export function useCreateSocialTemplate() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (template: Omit<SocialTemplate, "id" | "created_at" | "updated_at">) => {
      const { data, error } = await supabase
        .from("social_templates")
        .insert(template)
        .select()
        .single();

      if (error) throw error;
      return data as SocialTemplate;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "social-templates"] });
      toast.success("تم إنشاء القالب بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في إنشاء القالب: ${error.message}`);
    },
  });
}

// Update social template
export function useUpdateSocialTemplate() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...template }: Partial<SocialTemplate> & { id: string }) => {
      const { data, error } = await supabase
        .from("social_templates")
        .update(template)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as SocialTemplate;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "social-templates"] });
      toast.success("تم تحديث القالب بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في تحديث القالب: ${error.message}`);
    },
  });
}

// Delete social template
export function useDeleteSocialTemplate() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from("social_templates")
        .delete()
        .eq("id", id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "social-templates"] });
      toast.success("تم حذف القالب بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في حذف القالب: ${error.message}`);
    },
  });
}

// Duplicate social template
export function useDuplicateSocialTemplate() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      // Fetch the original template
      const { data: original, error: fetchError } = await supabase
        .from("social_templates")
        .select("*")
        .eq("id", id)
        .single();

      if (fetchError) throw fetchError;

      const { id: _id, created_at: _createdAt, updated_at: _updatedAt, ...rest } = original as SocialTemplate;

      // Insert copy with modified name
      const { data, error } = await supabase
        .from("social_templates")
        .insert({ ...rest, name: rest.name + " (نسخة)" })
        .select()
        .single();

      if (error) throw error;
      return data as SocialTemplate;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "social-templates"] });
      toast.success("تم نسخ القالب بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في نسخ القالب: ${error.message}`);
    },
  });
}
