"use client";

import { useQuery, useMutation, useQueryClient, useInfiniteQuery } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import type { AdminHadith, AdminQuote, AdminMOTD, AdminBanner } from "@/types/database";
import { toast } from "sonner";

const supabase = createClient();
const PAGE_SIZE = 20;

// ============ Hadith ============

export function useHadithList(filters?: { category?: string; grade?: string; search?: string }) {
  return useInfiniteQuery({
    queryKey: ["admin", "hadith", filters],
    queryFn: async ({ pageParam = 0 }) => {
      let query = supabase
        .from("admin_hadith")
        .select("*", { count: "exact" })
        .order("display_priority", { ascending: false })
        .order("created_at", { ascending: false })
        .range(pageParam * PAGE_SIZE, (pageParam + 1) * PAGE_SIZE - 1);

      if (filters?.category) {
        query = query.eq("category", filters.category);
      }
      if (filters?.grade) {
        query = query.eq("grade", filters.grade);
      }
      if (filters?.search) {
        query = query.or(`hadith_text.ilike.%${filters.search}%,source.ilike.%${filters.search}%`);
      }

      const { data, error, count } = await query;
      if (error) throw error;

      return {
        items: data as AdminHadith[],
        totalCount: count || 0,
        nextPage: data.length === PAGE_SIZE ? pageParam + 1 : undefined,
      };
    },
    getNextPageParam: (lastPage) => lastPage.nextPage,
    initialPageParam: 0,
  });
}

export function useHadith(id: string) {
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

export function useUpdateHadith() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...hadith }: Partial<AdminHadith> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_hadith")
        .update({ ...hadith, updated_at: new Date().toISOString() })
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

export function useDeleteHadith() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase.from("admin_hadith").delete().eq("id", id);
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

export function useBulkDeleteHadith() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (ids: string[]) => {
      const { error } = await supabase.from("admin_hadith").delete().in("id", ids);
      if (error) throw error;
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ["admin", "hadith"] });
      toast.success(`تم حذف ${variables.length} حديث بنجاح`);
    },
    onError: (error) => {
      toast.error(`فشل في الحذف: ${error.message}`);
    },
  });
}

// ============ Quotes ============

export function useQuotesList(filters?: { category?: string; search?: string }) {
  return useInfiniteQuery({
    queryKey: ["admin", "quotes", filters],
    queryFn: async ({ pageParam = 0 }) => {
      let query = supabase
        .from("admin_quotes")
        .select("*", { count: "exact" })
        .order("display_priority", { ascending: false })
        .order("created_at", { ascending: false })
        .range(pageParam * PAGE_SIZE, (pageParam + 1) * PAGE_SIZE - 1);

      if (filters?.category) {
        query = query.eq("category", filters.category);
      }
      if (filters?.search) {
        query = query.or(`quote_text.ilike.%${filters.search}%,author.ilike.%${filters.search}%`);
      }

      const { data, error, count } = await query;
      if (error) throw error;

      return {
        items: data as AdminQuote[],
        totalCount: count || 0,
        nextPage: data.length === PAGE_SIZE ? pageParam + 1 : undefined,
      };
    },
    getNextPageParam: (lastPage) => lastPage.nextPage,
    initialPageParam: 0,
  });
}

export function useCreateQuote() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (quote: Omit<AdminQuote, "id" | "created_at" | "updated_at">) => {
      const { data, error } = await supabase
        .from("admin_quotes")
        .insert(quote)
        .select()
        .single();

      if (error) throw error;
      return data as AdminQuote;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "quotes"] });
      toast.success("تم إضافة الاقتباس بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في إضافة الاقتباس: ${error.message}`);
    },
  });
}

export function useUpdateQuote() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...quote }: Partial<AdminQuote> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_quotes")
        .update({ ...quote, updated_at: new Date().toISOString() })
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as AdminQuote;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "quotes"] });
      toast.success("تم تحديث الاقتباس بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في تحديث الاقتباس: ${error.message}`);
    },
  });
}

export function useDeleteQuote() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase.from("admin_quotes").delete().eq("id", id);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "quotes"] });
      toast.success("تم حذف الاقتباس بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في حذف الاقتباس: ${error.message}`);
    },
  });
}

// ============ MOTD (Message of the Day) ============

export function useMOTDList(filters?: { type?: string; active?: boolean }) {
  return useQuery({
    queryKey: ["admin", "motd", filters],
    queryFn: async () => {
      let query = supabase
        .from("admin_motd")
        .select("*")
        .order("display_priority", { ascending: false })
        .order("created_at", { ascending: false });

      if (filters?.type) {
        query = query.eq("type", filters.type);
      }
      if (filters?.active !== undefined) {
        query = query.eq("is_active", filters.active);
      }

      const { data, error } = await query;
      if (error) throw error;
      return data as AdminMOTD[];
    },
  });
}

export function useCreateMOTD() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (motd: Omit<AdminMOTD, "id" | "created_at" | "updated_at">) => {
      const { data, error } = await supabase
        .from("admin_motd")
        .insert(motd)
        .select()
        .single();

      if (error) throw error;
      return data as AdminMOTD;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "motd"] });
      toast.success("تم إضافة الرسالة بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في إضافة الرسالة: ${error.message}`);
    },
  });
}

export function useUpdateMOTD() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...motd }: Partial<AdminMOTD> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_motd")
        .update({ ...motd, updated_at: new Date().toISOString() })
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as AdminMOTD;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "motd"] });
      toast.success("تم تحديث الرسالة بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في تحديث الرسالة: ${error.message}`);
    },
  });
}

export function useDeleteMOTD() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase.from("admin_motd").delete().eq("id", id);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "motd"] });
      toast.success("تم حذف الرسالة بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في حذف الرسالة: ${error.message}`);
    },
  });
}

// ============ Banners ============

export function useBannersList(filters?: { position?: string; active?: boolean }) {
  return useQuery({
    queryKey: ["admin", "banners", filters],
    queryFn: async () => {
      let query = supabase
        .from("admin_banners")
        .select("*")
        .order("display_priority", { ascending: false })
        .order("created_at", { ascending: false });

      if (filters?.position) {
        query = query.eq("position", filters.position);
      }
      if (filters?.active !== undefined) {
        query = query.eq("is_active", filters.active);
      }

      const { data, error } = await query;
      if (error) throw error;
      return data as AdminBanner[];
    },
  });
}

export function useCreateBanner() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (banner: Omit<AdminBanner, "id" | "created_at" | "updated_at" | "impressions" | "clicks">) => {
      const { data, error } = await supabase
        .from("admin_banners")
        .insert({ ...banner, impressions: 0, clicks: 0 })
        .select()
        .single();

      if (error) throw error;
      return data as AdminBanner;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "banners"] });
      toast.success("تم إضافة البانر بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في إضافة البانر: ${error.message}`);
    },
  });
}

export function useUpdateBanner() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...banner }: Partial<AdminBanner> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_banners")
        .update({ ...banner, updated_at: new Date().toISOString() })
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as AdminBanner;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "banners"] });
      toast.success("تم تحديث البانر بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في تحديث البانر: ${error.message}`);
    },
  });
}

export function useDeleteBanner() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase.from("admin_banners").delete().eq("id", id);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "banners"] });
      toast.success("تم حذف البانر بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في حذف البانر: ${error.message}`);
    },
  });
}

// ============ Content Stats ============

export function useContentStats() {
  return useQuery({
    queryKey: ["admin", "content-stats"],
    queryFn: async () => {
      const [hadithRes, quotesRes, motdRes, bannersRes] = await Promise.all([
        supabase.from("admin_hadith").select("*", { count: "exact", head: true }),
        supabase.from("admin_quotes").select("*", { count: "exact", head: true }),
        supabase.from("admin_motd").select("*", { count: "exact", head: true }).eq("is_active", true),
        supabase.from("admin_banners").select("*", { count: "exact", head: true }).eq("is_active", true),
      ]);

      return {
        hadithCount: hadithRes.count || 0,
        quotesCount: quotesRes.count || 0,
        activeMOTD: motdRes.count || 0,
        activeBanners: bannersRes.count || 0,
      };
    },
    staleTime: 30000, // 30 seconds
  });
}

// ============ Categories ============

export function useHadithCategories() {
  return useQuery({
    queryKey: ["admin", "hadith-categories"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_hadith")
        .select("category")
        .order("category");

      if (error) throw error;
      const categories = [...new Set(data.map((d) => d.category))];
      return categories;
    },
    staleTime: 60000, // 1 minute
  });
}

export function useQuoteCategories() {
  return useQuery({
    queryKey: ["admin", "quote-categories"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_quotes")
        .select("category")
        .order("category");

      if (error) throw error;
      const categories = [...new Set(data.map((d) => d.category))];
      return categories;
    },
    staleTime: 60000, // 1 minute
  });
}
