"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import type {
  AdminSubscriptionTier,
  AdminSubscriptionProduct,
  AdminFeature,
} from "@/types/database";
import { toast } from "sonner";

const supabase = createClient();

// ============ Subscription Tiers ============

export function useSubscriptionTiers() {
  return useQuery({
    queryKey: ["admin", "subscription-tiers"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_subscription_tiers")
        .select("*")
        .order("sort_order");

      if (error) throw error;
      return data as AdminSubscriptionTier[];
    },
  });
}

export function useUpdateSubscriptionTier() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...tier }: Partial<AdminSubscriptionTier> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_subscription_tiers")
        .update(tier)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as AdminSubscriptionTier;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "subscription-tiers"] });
      toast.success("تم تحديث الباقة");
    },
    onError: (error) => {
      toast.error(`فشل التحديث: ${error.message}`);
    },
  });
}

export function useCreateSubscriptionTier() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (tier: Omit<AdminSubscriptionTier, "id" | "created_at" | "updated_at">) => {
      const { data, error } = await supabase
        .from("admin_subscription_tiers")
        .insert(tier)
        .select()
        .single();

      if (error) throw error;
      return data as AdminSubscriptionTier;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "subscription-tiers"] });
      toast.success("تم إضافة الباقة");
    },
    onError: (error) => {
      toast.error(`فشل الإضافة: ${error.message}`);
    },
  });
}

// ============ Subscription Products ============

export function useSubscriptionProducts() {
  return useQuery({
    queryKey: ["admin", "subscription-products"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_subscription_products")
        .select("*")
        .order("sort_order");

      if (error) throw error;
      return data as AdminSubscriptionProduct[];
    },
  });
}

export function useUpdateSubscriptionProduct() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...product }: Partial<AdminSubscriptionProduct> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_subscription_products")
        .update(product)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as AdminSubscriptionProduct;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "subscription-products"] });
      toast.success("تم تحديث المنتج");
    },
    onError: (error) => {
      toast.error(`فشل التحديث: ${error.message}`);
    },
  });
}

export function useCreateSubscriptionProduct() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (product: Omit<AdminSubscriptionProduct, "id" | "created_at" | "updated_at">) => {
      const { data, error } = await supabase
        .from("admin_subscription_products")
        .insert(product)
        .select()
        .single();

      if (error) throw error;
      return data as AdminSubscriptionProduct;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "subscription-products"] });
      toast.success("تم إضافة المنتج");
    },
    onError: (error) => {
      toast.error(`فشل الإضافة: ${error.message}`);
    },
  });
}

export function useDeleteSubscriptionProduct() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from("admin_subscription_products")
        .delete()
        .eq("id", id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "subscription-products"] });
      toast.success("تم حذف المنتج");
    },
    onError: (error) => {
      toast.error(`فشل الحذف: ${error.message}`);
    },
  });
}

// ============ Features ============

export function useFeatures() {
  return useQuery({
    queryKey: ["admin", "features"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_features")
        .select("*")
        .order("sort_order");

      if (error) throw error;
      return data as AdminFeature[];
    },
  });
}

export function useUpdateFeature() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...feature }: Partial<AdminFeature> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_features")
        .update(feature)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as AdminFeature;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "features"] });
      toast.success("تم تحديث الميزة");
    },
    onError: (error) => {
      toast.error(`فشل التحديث: ${error.message}`);
    },
  });
}

export function useCreateFeature() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (feature: Omit<AdminFeature, "id" | "created_at" | "updated_at">) => {
      const { data, error } = await supabase
        .from("admin_features")
        .insert(feature)
        .select()
        .single();

      if (error) throw error;
      return data as AdminFeature;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "features"] });
      toast.success("تم إضافة الميزة");
    },
    onError: (error) => {
      toast.error(`فشل الإضافة: ${error.message}`);
    },
  });
}

export function useDeleteFeature() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from("admin_features")
        .delete()
        .eq("id", id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "features"] });
      toast.success("تم حذف الميزة");
    },
    onError: (error) => {
      toast.error(`فشل الحذف: ${error.message}`);
    },
  });
}
