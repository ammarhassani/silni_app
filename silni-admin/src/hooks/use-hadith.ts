"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import type { AdminHadith } from "@/types/database";
import { toast } from "sonner";

const supabase = createClient();

// Fetch all hadith
export function useHadith() {
  return useQuery({
    queryKey: ["admin", "hadith"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_hadith")
        .select("*")
        .order("display_priority", { ascending: false })
        .order("created_at", { ascending: false });

      if (error) throw error;
      return data as AdminHadith[];
    },
  });
}

// Fetch single hadith
export function useHadithById(id: string) {
  return useQuery({
    queryKey: ["admin", "hadith", id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_hadith")
        .select("*")
        .eq("id", id)
        .single();

      if (error) throw error;
      return data as AdminHadith;
    },
    enabled: !!id,
  });
}

// Create hadith
export function useCreateHadith() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (hadith: Omit<AdminHadith, "id" | "created_at" | "updated_at">) => {
      const { data, error } = await supabase
        .from("admin_hadith")
        .insert(hadith)
        .select()
        .single();

      if (error) throw error;
      return data as AdminHadith;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "hadith"] });
      toast.success("تم إضافة الحديث بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في إضافة الحديث: ${error.message}`);
    },
  });
}

// Update hadith
export function useUpdateHadith() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...hadith }: Partial<AdminHadith> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_hadith")
        .update(hadith)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as AdminHadith;
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ["admin", "hadith"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "hadith", variables.id] });
      toast.success("تم تحديث الحديث بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في تحديث الحديث: ${error.message}`);
    },
  });
}

// Delete hadith
export function useDeleteHadith() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from("admin_hadith")
        .delete()
        .eq("id", id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "hadith"] });
      toast.success("تم حذف الحديث بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في حذف الحديث: ${error.message}`);
    },
  });
}

// Toggle hadith active status
export function useToggleHadithActive() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, is_active }: { id: string; is_active: boolean }) => {
      const { data, error } = await supabase
        .from("admin_hadith")
        .update({ is_active })
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as AdminHadith;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "hadith"] });
      toast.success("تم تحديث الحالة بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في تحديث الحالة: ${error.message}`);
    },
  });
}

// Bulk delete hadith
export function useBulkDeleteHadith() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (ids: string[]) => {
      const { error } = await supabase
        .from("admin_hadith")
        .delete()
        .in("id", ids);

      if (error) throw error;
    },
    onSuccess: (_, ids) => {
      queryClient.invalidateQueries({ queryKey: ["admin", "hadith"] });
      toast.success(`تم حذف ${ids.length} حديث بنجاح`);
    },
    onError: (error) => {
      toast.error(`فشل في الحذف: ${error.message}`);
    },
  });
}

// Bulk toggle active status
export function useBulkToggleHadithActive() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ ids, is_active }: { ids: string[]; is_active: boolean }) => {
      const { error } = await supabase
        .from("admin_hadith")
        .update({ is_active })
        .in("id", ids);

      if (error) throw error;
    },
    onSuccess: (_, { ids, is_active }) => {
      queryClient.invalidateQueries({ queryKey: ["admin", "hadith"] });
      toast.success(`تم ${is_active ? "تفعيل" : "تعطيل"} ${ids.length} حديث بنجاح`);
    },
    onError: (error) => {
      toast.error(`فشل في تحديث الحالة: ${error.message}`);
    },
  });
}
